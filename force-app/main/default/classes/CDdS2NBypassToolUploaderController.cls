/**
 * @author			Jose Vega <jose.vega@doordash.com>
 * @created			22 / 12 / 2020
 * @description		Controller for LWC Bypass Tool
 *
 */
public with sharing class CDdS2NBypassToolUploaderController {
    private static final String BATCH_SIZE = Label.Bypass_Bulk_Store_Update_Batch_Size;
    private static String csvData = '';

    /**
     * @name			uploadCsv
     * @created			22 / 12 / 2020
     * @description		Description of your code
     * @param			String csv : comma separated values to be used in the Bypass
     * @param           String userId : The Id of the current user
     * @param           String reason : reason to perform the bypass
     * @param           String fileName : 
     * @return			CDdS2NBypassToolUploaderContext
    */
    @AuraEnabled
    public static CDdS2NBypassToolUploaderContext uploadCsv(String csv, String userId, String msSyncStage, String reason, Boolean overwrite, String filename) {
        CDdS2NBypassToolUploaderHelper helper = new CDdS2NBypassToolUploaderHelper();
        CDdS2NBypassToolUploaderContext ctx = new CDdS2NBypassToolUploaderContext(csv, userId, msSyncStage, reason, overwrite, filename);
        helper.uploadCsv(ctx);

        //Minimize what's cached. Maximum size of a single cached item (for put() methods) is 100KB
        CDdS2NBypassToolUploaderContext ctxMinimized = ctx.clone();
        ctxMinimized.csvRaw = null;
        Cache.Org.put(ctxMinimized.partitionKey(), ctxMinimized);

        return ctx;
    }

    /**
     * @created			23 / 12 / 2020
     * @description		import handler
     * @param			String userId : We use the userId to retrieve data from
     * cache
     * @return			batch Id associated with the import.
    */
    @AuraEnabled
    public static String importCsv(String userId) {
        CDdS2NBypassToolUploaderContext ctx = (CDdS2NBypassToolUploaderContext) Cache.Org.get(CDdS2NBypassToolUploaderContext.PARTITION_PREFIX + userId);
        return importCsv(userId, ctx);
    }

    private static String importCsv(String userId, CDdS2NBypassToolUploaderContext ctx) {
        List<Map<String, Object>> preparedBatchData = prepareBatchData(ctx);
        CDdS2NBypassToolUploaderHelper.saveCsv(ctx);
        ctx.batchId = Database.executeBatch(new CDdBypassBulkStoreUpdateBatch(preparedBatchData, ctx.reason), Integer.valueOf(BATCH_SIZE));
        Cache.Org.put(ctx.partitionKey(), ctx);
        return ctx.batchId;
    }

    /**
     * @created			04 / 01 / 2021
     * @description		Helper function that converts the uploaded CSV data into 
     * the approriate data type that can be used to import into mulesoft.
    */
    private static List<Map<String, Object>> prepareBatchData(CDdS2NBypassToolUploaderContext ctx) {
        List<Map<String, Object>> data = new List<Map<String,Object>>();
        List<Map<String, String>> avaiableFields = CDdNimdaByPassGroupHelper.getNimdaFields();
        List<String> lHeader = new List<String>();
        List<String> lRow = new List<String>();

        Integer iteration = 0;
        for (CDdS2NBypassToolUploaderCSV.Row row : ctx.csv.rows) {
            Map<String, Object> keyValue = new Map<String, Object>();
            String columnName = '';
            Object columnValue = '';
            lRow.clear();
            for (CDdS2NBypassToolUploaderCSV.Cell cell : row.cells) {
                CDdS2NBypassToolUploaderCSV.ColumnMeta cm = ctx.csv.header.getColumnByPosition(cell.colNum);
                if (iteration == 0) {
                    lHeader.add(cm.columnName);
                }
                columnName = standardizeColumnName(cm.columnName);
                columnValue = CDdS2NBypassToolUploaderHelper.convertToObject(columnName,cell.value, avaiableFields);
                if (!String.isBlank(cell.value)) {
                    keyValue.put(columnName, columnValue);
                }
                lRow.add(cell.value);
            }

            if (iteration == 0) {
                csvData += String.join(lHeader, ',') + '\n';
            }
            csvData += String.join(lRow, ',') + '\n';
            
            // Manually add overwrite_partnership_values
            keyValue.put('overwrite_partnership_values', ctx.overwrite);
            data.add(keyValue);
            iteration++;
        }

        ctx.csvRaw = csvData;

        return data;
    }

    /**
     * @author			Jose Vega <jose.vega@doordash.com>
     * @created			15 / 02 / 2021
     * @description		We want to change the name of some fields into valeus that
     *                  mulesoft understand.
     * @param			String param : column name
     * @return			Converts the following:
     *                      store_id to id
     *                      accountid to accountId
    **/
    @TestVisible
    private static String standardizeColumnName(String columnName) {
        switch on columnName.toLowercase() {
            when 'store_id' {
                return 'id';
            }
            when 'accountid' {
                return 'accountId';
            }
            when else {
                return columnName;
            }
        }
    }

    @AuraEnabled
    public static AsyncApexJob getProgress(String batchId) {
        AsyncApexJob apj =  [
            SELECT
                Id, Status, NumberOfErrors, JobItemsProcessed,
                TotalJobItems, CompletedDate, ExtendedStatus
            FROM AsyncApexJob
            WHERE Id = :batchId LIMIT 1];
        return apj;
    }

    @AuraEnabled
    public static List<String> getImportMessages() {
        List<String> batchErrors = new List<String>();
        String batchId = '';
        String userId = UserInfo.getUserId();
        List<Apex_Log__c> apexLogs = new List<Apex_Log__c>();
        CDdS2NBypassToolUploaderContext uploaderCtx = 
            (CDdS2NBypassToolUploaderContext) Cache.Org.get(CDdS2NBypassToolUploaderContext.PARTITION_PREFIX + userId);

        if (uploaderCtx != null) {
            batchId = uploaderCtx.batchId;
        }
        
        if (!String.isBlank(batchId)) {
            apexLogs = [
                SELECT Log__c FROM Apex_Log__c WHERE Reference_Id__c = :batchId];
        }

        for (Apex_Log__c log: apexLogs) {
            batchErrors.add(log.Log__c);
        }
        
        return batchErrors;
    }

    /**
     * @author			Jose Vega <jose.vega@doordash.com>
     * @created			12 / 01 / 2021
     * @description		returns the string value of the warning label for overwrite partnership
    */
    @AuraEnabled(cacheable=true)
    public static String getWarningLabel(){
        Bypass_Bulk_Uploader__c mc = Bypass_Bulk_Uploader__c.getOrgDefaults();
        return mc.Warning_Label__c;
    }
}