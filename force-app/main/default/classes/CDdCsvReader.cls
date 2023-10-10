/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 1/27/2020.
 *
 * An object that represents a CSV file and instantiates the corresponding SObjects:
 *    Header [ ColumnMeta, ... ]
 *    Rows [ Row : Cells [Cell -> ColumnMeta, ...], ... ]
 */
public with sharing class CDdCsvReader {
    public Context ctx;
    public Header header;
    public List<Row> rows = new List<Row>();
    public List<String> tableErrors = new List<String>();
    public Map<String, RowError> rowErrors = new Map<String, RowError>();
    public Integer numErrors = 0;
    public Integer numRows = 0;
    public Integer numColumns = 0;
    public Map<String, Map<Id, CDdCSVReader.Cell>> idsByObject = new Map<String, Map<Id, CDdCSVReader.Cell>>();
    public List<SObject> objects = new List<SObject>();
    private final Map<String, Schema.SObjectType> typeMap = Schema.getGlobalDescribe();

    public class Context {
        public CDdCSVReader reader;
        public String objectName;
        public List<Id> ids = new List<Id>();
        public Map<String, DescribeFieldResult> describeMap = new Map<String, DescribeFieldResult>();


        // Single-object CSV
        Context(CDdCSVReader reader, String objectType) {
            this.reader = reader;
            this.objectName = objectType;

            Type type = Type.forName(objectType);
            Map<String, SObjectField> fieldMap = ((SObject)type.newInstance()).getSObjectType().getDescribe().fields.getMap();
            for (SObjectField field : fieldMap.values()) {
                describeMap.put(field.getDescribe().getName().toLowerCase(), field.getDescribe());
                System.debug('CDdCSVReader.Context, field: ' + field.getDescribe());
            }
        }
    }

    // Single-object CSV
    public CDdCSVReader(String csv, String objectType) {
        this.ctx = new Context(this, objectType);

        List<List<String>> data = CDdUploaderParser.read(csv);

        //Construct the Header including Column Metadata
        header = new Header(ctx, data[0]);
        this.numColumns = this.header.columnNames.size();

        //Construct the rows including Cells
        for(Integer i = 1; i < data.size(); i++) {
            Row row = new Row(ctx, data[i]);
            rows.add(row);
            objects.add(createObject(row, objectType));
        }
    }

    public SObject createObject(Row row, String objectType) {
        SObject obj = typeMap.get(objectType).newSObject();
        for(Cell cell : row.cells) {
            if(cell.meta.isUpdateable || 'realzip__realcountry__c'.equals(cell.meta.fieldNameLower)) {
                bindValue(cell, obj);
            }
        }
        return obj;
    }

    public void addTableError(String error) {
        this.tableErrors.add(error);
        this.numErrors += 1;
    }

    public void addRowError(Row row, Cell cell, String message) {
        message = 'R' + cell.rowNum + ':C' + cell.colNum + ', ' + cell.meta.objectFieldName + ': ' + message;
        if(this.rowErrors.get(row.rowKey) == null) {
            rowErrors.put(row.rowKey, new RowError(cell.meta.objectFieldName, message));
        } else {
            RowError rowError = rowErrors.get(row.rowKey);
            rowError.fieldNames.add(cell.meta.objectFieldName);
            rowError.messages.add(message);
        }
        this.numErrors += 1;
    }

    /**
     * Identify the cell's data type, convert it, and assign it to the object
     *
     * @param cell - which cell to bind the value to, including it's metadata (object, field, SF type)
     * @param obj - the Salesforce SObject for this cell
     */
    public void bindValue(Cell cell, SObject obj) {
        String fieldName = cell.meta.fieldName;


        //Nullify the value if requested
        if(''.equals(cell.value.toLowerCase()) || 'null'.equals(cell.value.toLowerCase())) {
            obj.put(fieldName, null);
            return;
        }

        //Otherwise convert the value to the appropriate data type
        switch on cell.meta.displayTypeSf {
            when COMBOBOX, ENCRYPTEDSTRING, EMAIL, ID, JSON, MULTIPICKLIST, PHONE, PICKLIST, REFERENCE, STRING, TEXTAREA, URL {
                obj.put(fieldName, cell.value);
                if('Id'.equals(fieldName)) {
                    String actualType = Id.valueOf(cell.value).getSobjectType().getDescribe().name;
                    if(!cell.meta.objectName.equals(actualType)) {
                        throw new System.TypeException('Id does not map to the object indicated. Indicated: ' + cell.meta.objectName + ', Actual: ' + actualType);
                    }
                }
            }
            when TIME {
                String[] parts = cell.value.split(':');
                if(parts.size() != 3) throw new System.TypeException('Time must be in the format hh:mm:ss');
                Time value =  Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), Integer.valueOf(parts[2]), 0);
                obj.put(fieldName, value);
            }
            when BOOLEAN {
                //Boolean.valueOf defaults to false when not some form of the string "True" or "False", e.g. 0 and 1 are both false
                String strValue = cell.value.toLowerCase();
                if(!(new String[] { '', '0', '1', 'true', 'false' }).contains(strValue) ) {
                    throw new System.TypeException();
                }

                strValue = '0'.equals(strValue) ? 'false' : strValue;
                strValue = '1'.equals(strValue) ? 'true'  : strValue;

                Boolean value = Boolean.valueOf(strValue);
                obj.put(fieldName, value);
            }
            when INTEGER            { obj.put(fieldName, Integer.valueOf(cell.value)); }
            when LONG               { obj.put(fieldName, Long.valueOf(cell.value)); }
            when CURRENCY, DOUBLE   { obj.put(fieldName, Double.valueOf(cell.value)); }
            when PERCENT            { obj.put(fieldName, Double.valueOf(cell.value)); }
            when DATE               { obj.put(fieldName, Date.valueOf(cell.value)); }
            when DATETIME           { obj.put(fieldName, Datetime.valueOf(cell.value)); }
            when else {
                //The following are currently unsupported: ADDRESS, ANYTPE, BASE64, COMPLEXVALUE, DATACATEGORYGROUPREFERENCE, LOCATION, SOBJECT
                throw new System.TypeException('Data type not supported: ' + cell.meta.displayTypeSf.name());
            }
        }
    }

    /**
     * An object that provides different strategies for looking up objects and fields contained in the CSV
     */
    public class Header {
        public List<String> columnNames = new List<String>();                        //an ordered list of fully-qualified field names
        public List<String> fieldNames = new List<String>();                         //the Salesforce field API names
        public Map<String, ColumnMeta> columnMap = new Map<String, ColumnMeta>();    //a Map of ColumnMeta keyed by fieldName
        public Map<String, ColumnMeta> objectMap = new Map<String, ColumnMeta>();    //a Map of ColumnMeta keyed by objectName

        public Header(Context ctx, List<String> values) {
            Integer colNum = 1;
            for (String column : values) {
                ColumnMeta cm = new ColumnMeta(ctx, column, colNum++);
                columnMap.put(cm.objectFieldName, cm);
                columnNames.add(cm.objectFieldName);
                fieldNames.add(cm.fieldName);
                objectMap.put(cm.objectName, cm);
            }
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
        public final String fieldNameLower;
        public final String objectFieldName;
        public final Schema.DisplayType displayTypeSf;
        public final String fieldNameUI;
        public final Integer colNum;
        public Boolean isUpdateable = true;

        public ColumnMeta(Context ctx, String fieldName, Integer colNum) {
            //TODO: This does not currently support relationship fields, e.g. Opportunity.Decision_Maker__r.DM_Email
            String[] parts;
            if(fieldName.contains('.')) {
                parts = fieldName.split('\\.');
                System.assertEquals(2, parts.size(), System.Label.Csv_Reader_Error_Object_Pattern + ' "Object.Field": ' + fieldName);
            } else {
                parts = new List<String>{ctx.objectName, fieldName};
            }

            this.objectFieldName = fieldName;
            this.objectName = parts[0];
            this.fieldName = parts[1];
            this.fieldNameLower = parts[1].toLowerCase();
            this.fieldNameUI = parts[0].toLowerCase() + parts[1];
            this.colNum = colNum;

            /*
            DescribeFieldResult describe;
            try {
                Type type = Type.forName(objectName);
                describe = ((SObject)type.newInstance()).getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
                this.displayTypeSf = describe.getType();
            } catch (Exception e) {
                e.setMessage('The Object.Field was not found. Column headers are case-sensitive and must reference the field\'s API name: ' + fieldName);
                throw e;
            }
            */

            // TODO: handle multiple object types
            System.debug('CDdCSVReader.ColumnMeta, fieldNameLower: ' + fieldNameLower);
            DescribeFieldResult describe = ctx.describeMap.get(this.fieldNameLower);
            this.displayTypeSf = describe.getType();

            if(!describe.isUpdateable()) {
                if(!'Id'.equals(this.fieldName)) {
                    isUpdateable = false;
                    ctx.reader.addTableError('Unable to import field (field level security): ' + fieldName);
                }
            }

            if(describe.isCalculated()) {
                isUpdateable = false;
                ctx.reader.addTableError('Unable to import field (custom formula): ' + fieldName);
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

        public Row(Context ctx, List<String> values) {
            rowNum = ++ctx.reader.numRows;

            //A rowKey must be assigned first.
            String rowKey = '';
            Integer colNum = 0;
            for (String value : values) {
                ColumnMeta meta = ctx.reader.header.getColumnByPosition(colNum++);
                if('Id'.equals(meta.fieldName)) {
                    rowKey += value == '' ? 'null' : value;
                }
            }
            this.rowKey = rowKey;

            colNum = 0;
            for (String value : values) {
                ColumnMeta meta = ctx.reader.header.getColumnByPosition(colNum++);
                Cell cell = new Cell(ctx, meta, value, this);
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
        private Context ctx;

        public Cell(ColumnMeta meta, String value) {
            this.meta = meta;
            this.value = value;
        }

        public Cell (Context ctx, ColumnMeta meta, String value, Row row) {
            this.row = row;
            this.meta = meta;
            this.value = value;
            this.rowNum = row.rowNum;
            this.colNum = meta.colNum;
            this.ctx = ctx;
            this.addToIdMap();

            if ('id'.equals(meta.fieldNameLower)) {
                ctx.ids.add(value);
            }
        }

        /**
         * If this is an Id field, add the cell to the idsByObject map. This will help
         * validate objects by type in bulk and assign the results back to each cell
         * individually.
         */
        private void addToIdMap() {
            Map<String, Map<Id, CDdCSVReader.Cell>> idsByObject = ctx.reader.idsByObject;

            if('id'.equals(this.meta.fieldNameLower)) {
                if(!idsByObject.keySet().contains(meta.objectName)) {
                    idsByObject.put(meta.objectName, new Map<Id, Cell>());
                }
                try {
                    idsByObject.get(meta.objectName).put(Id.valueOf(this.value), this);
                } catch (Exception e) {
                    String message = 'Invalid Id: ' + (this.value == '' ? '[null]' : this.value);
                    ctx.reader.addRowError(this.row, this, message);
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
    
    /**
     * @author      Mahesh Chouhan
     * @date        March 2023
     * @decription  Parse CSV Row and return cell data. It handles cell data with mutliple ','
     * @param       String row
     * @return      List<String> cell
    */
    public static List<String> parseCSVRow(String row)
    {
        List<String> cells = new List<String>();
        Integer startIndex;
        Integer endIndex;

        // Traverse through row and replace ',' inside cell with ':comma:' and '"' with ':quote:'
        // 'first cell,"Second cell, with comma", third cell' will be changed to
        // 'first cell,:quote:Second cell:comma: with comma, third cell'
        while(row.indexOf(CDdCoreConstants.QUOTE) > -1){
            if(startIndex == null){
                startIndex = row.indexOf(CDdCoreConstants.QUOTE);
                row = row.substring(0, startIndex) + ':quote:' + row.substring(startIndex+1, row.length());
            }else{
                if(endIndex == null){
                    endIndex = row.indexOf(CDdCoreConstants.QUOTE);
                    row = row.substring(0, endIndex) + ':quote:' + row.substring(endIndex+1, row.length());
                }
            }

            //Cell with multiple ',' found
            if(startIndex != null && endIndex != null){
                String sub = row.substring(startIndex, endIndex);
                sub = sub.replaceAll(CDdCoreConstants.DELIMITER_COMMA, ':comma:');
                row = row.substring(0, startIndex) + sub + row.substring(endIndex, row.length());
                startIndex = null;
                endIndex = null;
            }
        }

        for(String column : row.split(CDdCoreConstants.DELIMITER_COMMA)){
            column = column.replaceAll(':quote:', CDdCoreConstants.BLANK_STRING)
                .replaceAll(':comma:', CDdCoreConstants.DELIMITER_COMMA);
            cells.add(column);
        }

        return cells;
    }
}