/**
 * @author			Jose Vega <jose.vega@doordash.com>
 * @created			04 / 01 / 2021
 * @description		Class responsible with processing the parsed CSV data
 * into a Header/Row/Cell/Meta object.
 *
*/
public with sharing class CDdS2NBypassToolUploaderCSV {
    @AuraEnabled public Header header;
    @AuraEnabled public Boolean isImportable = true;
    @AuraEnabled public Integer numCols = 0;
    @AuraEnabled public Integer numErrors = 0;
    @AuraEnabled public Integer numRows = 0;
    @AuraEnabled public List<Row> rows = new List<Row>();
    @AuraEnabled public Map<Integer, RowError> rowErrors = new Map<Integer, RowError>();
    @AuraEnabled public List<String> csvErrors = new List<String>();
    @AuraEnabled public Map<String, String> accountStore = new Map<String, String>();
    @AuraEnabled public List<Map<String, String>> nimdaFields;


    public CDdS2NBypassToolUploaderCSV(String csv) {
        List<List<String>> data = CDdUploaderParser.read(csv);
        this.nimdaFields = !Test.isRunningTest() ? CDdNimdaByPassGroupHelper.getNimdaFields() : (List<Map<String,String>>)JSON.deserialize(CDdS2NBypassToolUploaderCSVTest.NIMDA_FIELDS_TEST_STR, List<Map<String,String>>.class);

        header = new Header(this, data[0]);
        this.numCols = this.header.columnNames.size();

        System.debug(header);

        for (Integer i = 1; i < data.size(); i++) {
            rows.add(new Row(this, data[i]));
        }

        validateAccountStoreMapping();
    }

    private void validateAccountStoreMapping() {
        Set<String> accountSet = accountStore.keySet();
        List<Account> lstAccount = [SELECT Id, Restaurant_ID__c FROM Account WHERE Id IN :accountSet];
        for(Account acc : lstAccount) {
            String storeId = accountStore.get(String.valueOf(acc.Id));
            if (storeId != String.valueOf(acc.Restaurant_ID__c)) {
                addTableError('Account Id('+ acc.Id + ') does not match Store Id(' + storeId +').');
            }
        }
    }

    /**
     * An object that provides different strategies for looking up objects and
     * fields contained in the CSV
     */
    public class Header {
        // An ordered list of fully-qualified field names
        public List<String> columnNames = new List<String>();
        // A Map of ColumnMeta keyed by fieldName
        public Map<String, ColumnMeta> columnMap = new Map<String, ColumnMeta>();    

        public Header(CDdS2NBypassToolUploaderCSV csv, List<String> values) {
            Integer colNum = 1;
            for (String columnName : values) {
                ColumnMeta cm = new ColumnMeta(csv, columnName, colNum++);
                columnNames.add(columnName);
                columnMap.put(columnName, cm);
            }
        }

        public ColumnMeta getColumnByPosition(Integer i) {
            return columnMap.get(columnNames.get(i));
        }
    }

    public class ColumnMeta {
        public final String columnName;
        public final Integer colNum;
        public final Boolean isId;

        public ColumnMeta(CDdS2NBypassToolUploaderCSV csv, String columnName, Integer colNum) {
            this.colNum = colNum;
            this.columnName = columnName;

            if ('Id'.equalsIgnoreCase(columnName)) {
                isId = true;
            } else {
                isId = false;
            }
            validateColumn(csv);
        }

        private void validateColumn(CDdS2NBypassToolUploaderCSV csv) {
            Map<String, Map<String, String>> modifiedAvailableFields = new Map<String, Map<String, String>>();
            // Manually add accountId to list of fields.
            modifiedAvailableFields.put('ACCOUNTID', new Map<String,String> {
                'apiType' => 'String',
                'displayType' => 'String',
                'displayName' => 'accountId'
            });

            for (Map<String,String> field : csv.nimdaFields) {
                // Overwrite the field id to store_id in the UI
                String property = field.get('property');
                if (property.equalsIgnoreCase('id')) {
                    property = 'store_id';
                }
                modifiedAvailableFields.put(property.toUppercase(), new Map<String,String> {
                    'apiType' => field.get('apiType'),
                    'displayType' => field.get('displayType'),
                    'displayName' => field.get('displayName')
                });
            }

            if (!modifiedAvailableFields.containsKey(this.columnName.toUppercase())) {
                csv.addTableError('Unable to import field: ' + this.columnName);
            }
        }
    }

    public class Row {
        public final List<Cell> cells = new List<Cell>();
        public final Integer rowNum;

        public Row(CDdS2NBypassToolUploaderCSV csv, List<String> values) {
            rowNum = ++csv.numRows;
            Integer columnNum = 0;
            for (String value : values) {
                ColumnMeta meta = csv.header.getColumnByPosition(columnNum);
                Cell cell = new Cell(csv, meta, value, columnNum, this);
                cells.add(cell);
                columnNum++;
            }
            
            validateRow(csv);
        }
        
        private void validateRow(CDdS2NBypassToolUploaderCSV csv) {
            String accountId = '';
            String storeId = '';

            for(Cell a: cells) {
                if (a.meta.columnName.equalsIgnoreCase('accountid')) {
                    accountId = a.value;
                }
                if (a.meta.columnName.equalsIgnoreCase('store_id')) {
                    storeId = a.value;
                }
            }

            if (String.isBlank(accountId) || String.isBlank(storeId)) {
                csv.addTableError('Account Id and Store Id are required fields.');
            }

            csv.accountStore.put(standardizedId(accountId), storeId);
        }

        @TestVisible
        private String standardizedId(String accountId) {
            try {
                Id idval = accountId;
                accountId = idVal;
            } catch(Exception e) {
                System.debug(String.format('Account Id {0} is invalid', new List<String> {accountId}));
            }
            return accountId;
        }
    }

    public class Cell {
        public final ColumnMeta meta;
        public final String value;
        public final Integer rowNum;
        public final Integer colNum;
        public final Row row;
        private CDdS2NBypassToolUploaderCSV csv;

        @TestVisible
        private Cell(String value) {
            this.value = value;
        }

        public Cell (CDdS2NBypassToolUploaderCSV csv, ColumnMeta meta, String value, Integer colNum, Row row) {
            this.row = row;
            this.value = value;
            this.colNum = colNum;
            this.rowNum = row.rowNum;
            this.csv = csv;
            this.meta = meta;
            validateCell(csv);
        }

        private void validateCell(CDdS2NBypassToolUploaderCSV csv) {
            Map<String, Map<String, String>> modifiedAvailableFields = new Map<String, Map<String, String>>();
            Boolean validDisplayType = true;

            for (Map<String,String> field : csv.nimdaFields) {
                modifiedAvailableFields.put(field.get('property'), new Map<String,String> {
                    'apiType' => field.get('apiType'),
                    'displayType' => field.get('displayType'),
                    'displayName' => field.get('displayName')
                });
            }

            if (modifiedAvailableFields.containsKey(this.meta.columnName)) {
                switch on modifiedAvailableFields.get(this.meta.columnName).get('displayType') {
                    when 'Boolean' {
                        validDisplayType = isBoolean(this.value) || String.isBlank(this.value);
                        if (!validDisplayType) {
                            csv.addRowError(this.row, this, 'acceptable value true/false');
                        }
                    }
                    when 'Percent', 'Double', 'Integer', 'Currency' {
                        validDisplayType = isNumeric(this.value) || String.isBlank(this.value);
                        if (!validDisplayType) {
                            csv.addRowError(this.row, this, 'acceptable value numeric');
                        }
                    }
                    // No specific logic to validate below fields types
                    when 'String','address', 'Email', 'MultiPicklist', 'Phone' {}
                }
            }

            if (this.meta.columnName.equalsIgnoreCase('accountId')) {
                System.debug('This is account id');
                if (!isValid(this.value, Account.sObjectType)) {
                    System.debug('isValid not valud');
                    csv.addRowError(this.row, this, 'Invalid Id');
                } else {
                    System.debug('isValid');
                }
            }
        }

        @TestVisible
        private Boolean isBoolean(String s) {
            return s.equalsIgnoreCase('true') || s.equalsIgnoreCase('false');
        }

        @TestVisible
        private Boolean isNumeric(String s){
            Boolean ReturnValue;
            try{
                Decimal.valueOf(s);
                ReturnValue = TRUE; 
            } catch (Exception e) {
                ReturnValue = FALSE;
            }
            return ReturnValue;
        }

        public Boolean isValid(String stringValue, Schema.SObjectType sObjectType) {
            Id sObjectId;
            if(isId(stringValue)) sObjectId = (Id)stringValue;
            return isValid(sObjectId, sObjectType);
        }
         
        public Boolean isValid(Id sObjectId, Schema.SObjectType sObjectType) {
            return !(sObjectId==null || sObjectId.getSObjectType()!=sObjectType);
        }
         
        public Boolean isId(String stringValue) {
            return stringValue InstanceOf Id;
        }

    }

    public void addTableError(String message) {
        System.debug('CDdS2NBypassToolUploaderCSV.addTableError, error: ' + message);
        this.csvErrors.add(message);
        this.numErrors += 1;
        this.isImportable = false;
    }

    public void addRowError(Row row, Cell cell, String message) {
        System.debug('CDdS2NBypassToolUploaderCSV.addRowError, error: ' + message);

        message = 'R' + cell.rowNum + ':C' + cell.colNum + ', ' + cell.meta.columnName + ': ' + message;
        if (this.rowErrors.get(row.rowNum) == null) {
            rowErrors.put(row.rowNum, new RowError(cell.meta.columnName, message));
        } else {
            RowError rowError = rowErrors.get(row.rowNum);
            rowError.fieldNames.add(cell.meta.columnName);
            rowError.messages.add(message);
        }
        this.numErrors += 1;
        this.isImportable = false;
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