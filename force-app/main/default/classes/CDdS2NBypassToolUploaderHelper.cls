/**
 * @author			Jose Vega <jose.vega@doordash.com>
 * @created			04 / 01 / 2021
 * @description		General helper class used by the Bypass Tool.
 */
public with sharing class CDdS2NBypassToolUploaderHelper {

    private static final String FILENAME_DELIMITER = '|';
    private static final String LIBRARY_NAME;
    static {
        if (Test.isRunningTest()) {
    		LIBRARY_NAME = 'TEST_Library';
        } else {
            LIBRARY_NAME = Label.Bulk_Uploader_Content_Library_Name;
        }
    }

    public CDdS2NBypassToolUploaderContext uploadCsv(CDdS2NBypassToolUploaderContext ctx) {
        ctx.csv = new CDdS2NBypassToolUploaderCSV(ctx.csvRaw);
        ctx.columns = ctx.csv.header.columnNames;

        for (CDdS2NBypassToolUploaderCSV.Row row : ctx.csv.rows) {
            Map<String, Object> dataTableRow = new Map<String, Object>();
            dataTableRow.put('rowKey', row.rowNum);
            for (CDdS2NBypassToolUploaderCSV.Cell cell : row.cells) {
                CDdS2NBypassToolUploaderCSV.ColumnMeta cm =  ctx.csv.header.getColumnByPosition(cell.colNum);
                dataTableRow.put(cm.columnName, cell.value);
            }

            ctx.dataTable.add(dataTableRow);
        }

        return ctx;
    }

    public static void saveCsv(CDdS2NBypassToolUploaderContext ctx) {
        String title = getContentVersionFilename(ctx.msSyncStageStr);
        String filename = ctx.filename;

        CDdBulkUploadFileRetention fileRetention = new CDdBulkUploadFileRetention();
        
        Id contentDocumentId = fileRetention.retainFile(filename, title, ctx.msSyncStageStr, ctx.csvRaw);
        Id contentLibraryId = fileRetention.getLibraryIdByDeveloperName(LIBRARY_NAME);
        
        if (contentDocumentId != null && contentLibraryId != null) {
            fileRetention.linkFileToLibrary(contentDocumentId, contentLibraryId);
        } else {
            throw new AuraHandledException('Insufficient privileges to ' + LIBRARY_NAME + ' library.');
        }
    }

    private static String getContentVersionFilename(String stage) {
        return stage.replace(' ', '_') + FILENAME_DELIMITER + 
            UserInfo.getUserName() + FILENAME_DELIMITER +
            String.ValueOf(System.Now()).replace(' ', '_') + '.csv';
    }

    public static Object convertToObject(String columnName, String cellValue, List<Map<String, String>> avaiableFields) {
        Map<String, Map<String, String>> modifiedAvailableFields = new Map<String, Map<String, String>>();
        
        for (Map<String,String> field : avaiableFields) {
            modifiedAvailableFields.put(field.get('property'), new Map<String,String> {
                'apiType' => field.get('apiType'),
                'displayType' => field.get('displayType'),
                'displayName' => field.get('displayName')
            });
        }

        if (modifiedAvailableFields.containsKey(columnName)) {
            String apiType = modifiedAvailableFields.get(columnName).get('apiType');

            switch on apiType {
                when 'String', 'Percent' {
                    return String.valueOf(cellValue);
                }
                when 'Boolean' {
                    return Boolean.valueOf(cellValue);
                }
                when else {
                    return String.valueOf(cellValue);
                }
            }
        }

        return cellValue;
    }
}