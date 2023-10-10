/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 1/27/2020.
 *
 * An object that represents a CSV file:
 *    Header [ ColumnMeta, ... ]
 *    Rows [ Row : Cells [Cell -> ColumnMeta, ...], ... ]
 */
public with sharing class CDdUploaderCSV {
    @AuraEnabled public Boolean isCompositeObject = false;
    @AuraEnabled public Boolean isImportable = true;
    @AuraEnabled public Boolean isUpdate = false;
    @AuraEnabled public Header header;
    @AuraEnabled public Integer numCols = 0;
    @AuraEnabled public Integer numErrors = 0;
    @AuraEnabled public Integer numRows = 0;
    @AuraEnabled public List<Row> rows = new List<Row>();
    @AuraEnabled public List<String> csvErrors = new List<String>();
    @AuraEnabled public Map<String, Map<Id, CDdUploaderCSV.Cell>> idsByObject = new Map<String, Map<Id, CDdUploaderCSV.Cell>>();
    @AuraEnabled public Map<String, RowError> rowErrors = new Map<String, RowError>();

    public CDdUploaderCSV(String csv) {
        List<List<String>> data = CDdUploaderParser.read(csv);

        //Construct the Header including Column Metadata
        header = new Header(this, data[0]);
        this.numCols = this.header.columnNames.size();

        //Construct the rows including Cells
        for (Integer i = 1; i < data.size(); i++) {
            rows.add(new Row(this, data[i]));
        }
    }

    public void addTableError(String message) {
        System.debug('CDdUploaderCSV.addTableError, error: ' + message);
        this.csvErrors.add(message);
        this.numErrors += 1;
        this.isImportable = false;
    }

    public void addRowError(Row row, Cell cell, String message) {
        System.debug('CDdUploaderCSV.addRowError, error: ' + message);
        message = 'R' + cell.rowNum + ':C' + cell.colNum + ', ' + cell.meta.objectFieldName + ': ' + message;
        if (this.rowErrors.get(row.rowKey) == null) {
            rowErrors.put(row.rowKey, new RowError(cell.meta.objectFieldName, message));
        } else {
            RowError rowError = rowErrors.get(row.rowKey);
            rowError.fieldNames.add(cell.meta.objectFieldName);
            rowError.messages.add(message);
        }
        this.numErrors += 1;
        this.isImportable = false;
    }

    /**
     * An object that provides different strategies for looking up objects and fields contained in the CSV
     */
    public class Header {
        public List<String> columnNames = new List<String>();                        //an ordered list of fully-qualified field names
        public List<String> fieldNames = new List<String>();                         //the Salesforce field API names
        public Map<String, ColumnMeta> columnMap = new Map<String, ColumnMeta>();    //a Map of ColumnMeta keyed by fieldName
        public Map<String, List<ColumnMeta>> objectMap = new Map<String, List<ColumnMeta>>();    //a Map of ColumnMeta keyed by objectName

        public Header(CDdUploaderCSV csv, List<String> values) {
            Integer colNum = 1;
            for (String column : values) {
                ColumnMeta cm = new ColumnMeta(csv, column, colNum++);
                columnMap.put(cm.objectFieldName, cm);
                columnNames.add(cm.objectFieldName);
                fieldNames.add(cm.fieldName);

                if (objectMap.containsKey(cm.objectName)) {
                    objectMap.get(cm.objectName).add(cm);
                } else {
                    objectMap.put(cm.objectName, new List<ColumnMeta> { cm });
                }
            }

            csv.isCompositeObject = objectMap.keySet().size() > 1;
        }

        public ColumnMeta getColumnByPosition(Integer i) {
            return columnMap.get(columnNames.get(i));
        }
    }

    /**
     * An object containing meta data about the column (field), including it's name parts and
     * Salesforce data type. Each cell has a reference to ColumnMeta.
     */
    public class ColumnMeta {
        public final String objectName;
        public final String fieldName;
        public final String objectFieldName;
        public final Schema.DisplayType displayTypeSf;
        public final String fieldNameUI;
        public final Integer colNum;
        public final Boolean isId;
        public List<String> picklistEntries = new List<String>();

        @TestVisible
        private ColumnMeta(String objectName, String fieldName, DisplayType type, List<String> picklistEntries) {
            this.fieldName = fieldName;
            this.objectFieldName = objectName + '.' + fieldName;
            this.fieldNameUI = objectName + '.' + fieldName;
            this.displayTypeSf = type;
            this.objectName = objectName;
            this.picklistEntries = picklistEntries;
            this.isId = false;
        }

        public ColumnMeta(CDdUploaderCSV csv, String objectFieldName, Integer colNum) {
            //TODO: This does not currently support relationship fields, e.g. Opportunity.Decision_Maker__r.DM_Email
            String[] parts = objectFieldName.trim().split('\\.');
            //System.assertEquals(2, parts.size(), 'Column name must follow the pattern "Object.Field": ' + objectFieldName);
            if (parts.size()!=2){
                csv.addTableError('Column name must follow the pattern "Object.Field": ' + objectFieldName);
                return;
            }

            this.objectFieldName = objectFieldName;
            this.objectName = parts[0];
            this.fieldName = parts[1];
            this.fieldNameUI = parts[0].toLowerCase() + parts[1];
            this.colNum = colNum;

            if ('Id'.equals(fieldName)) {
                isId = true;
            } else {
                isId = false;
                csv.isUpdate = true;
            }

            DescribeFieldResult describe;
            SObject sObj;
            try {
                Type type = Type.forName(objectName);
                sObj = (SObject)type.newInstance();
            } catch (Exception e) {
                csv.addTableError('Object name set incorrectly <Object>.<field> : ' + objectFieldName);
            }

            if (sObj!=null){
                Map<String, SObjectField> sObjectFieldMap = sObj.getSObjectType().getDescribe().fields.getMap(); 
                if (sObjectFieldMap.containsKey(fieldName)){
                    describe = sObjectFieldMap.get(fieldName).getDescribe();
                    this.displayTypeSf = describe.getType();
                    for (PicklistEntry pe : describe.getPicklistValues()) {
                        picklistEntries.add(pe.getValue());
                    }
                    if (!describe.isUpdateable()) {
                        if (!'Id'.equals(fieldName)) {
                            csv.addTableError('Unable to import field (field level security): ' + objectFieldName);
                        }
                    }
                    if (describe.isCalculated()) {
                        csv.addTableError('Unable to import field (custom formula): ' + objectFieldName);
                    }
                } else {
                    csv.addTableError('The Object.Field was not found. Column headers are case-sensitive and must reference the field\'s API name: ' + objectFieldName);
                }
            }
        }
    }

    /**
     * An object that represents a row in the CSV containing a list of cells
     */
    public class Row {
        public final String rowKey; //a concatenation of Id fields
        public final List<Cell> cells = new List<Cell>();
        public final Integer rowNum;

        public Row(CDdUploaderCSV csv, List<String> values) {
            rowNum = ++csv.numRows;

            //A rowKey must be assigned first.
            String rowKey = '';
            Integer colNum = 0;
            for (String value : values) {
                ColumnMeta meta = csv.header.getColumnByPosition(colNum++);
                if ('Id'.equals(meta.fieldName)) {
                    rowKey += value == '' ? 'null' : value;
                }
            }
            this.rowKey = rowKey;

            colNum = 0;
            for (String value : values) {
                ColumnMeta meta = csv.header.getColumnByPosition(colNum++);
                Cell cell = new Cell(csv, meta, value, this);
                cells.add(cell);
            }
        }
    }

    /**
     * An object that represents a cell (field in a row), including its value and meta data
     */
    public class Cell {
        public final ColumnMeta meta;
        public final String value;
        public final Integer rowNum;
        public final Integer colNum;
        public final Row row;
        private CDdUploaderCSV csv;

        @TestVisible
        private Cell(ColumnMeta meta, String value) {
            this.meta = meta;
            this.value = value;
        }

        public Cell (CDdUploaderCSV csv, ColumnMeta meta, String value, Row row) {
            this.row = row;
            this.meta = meta;
            this.value = value;
            this.rowNum = row.rowNum;
            this.colNum = meta.colNum;
            this.csv = csv;
            this.addToIdMap();
        }

        /**
         * If this is an Id field, add the cell to the idsByObject map. This will help
         * validate objects by type in bulk and assign the results back to each cell
         * individually.
         */
        @TestVisible
        private void addToIdMap() {
            Map<String, Map<Id, CDdUploaderCSV.Cell>> idsByObject = csv.idsByObject;

            if ('Id'.equals(this.meta.fieldName)) {
                if (!idsByObject.keySet().contains(meta.objectName)) {
                    idsByObject.put(meta.objectName, new Map<Id, Cell>());
                }
                try {
                    idsByObject.get(meta.objectName).put(Id.valueOf(this.value), this);
                } catch (Exception e) {
                    String message = 'Invalid Id: ' + (this.value == '' ? '[null]' : this.value);
                    csv.addRowError(this.row, this, message);
                }
            }
        }
    }

    /**
     * A model to represent row-level errors to the UI
     */
    public class RowError {
        @AuraEnabled public List<String> messages = new List<String>();
        @AuraEnabled public List<String> fieldNames = new List<String>();
        RowError(String fieldName, String message) {
            this.fieldNames.add(fieldName);
            this.messages.add(message);
        }
    }
}