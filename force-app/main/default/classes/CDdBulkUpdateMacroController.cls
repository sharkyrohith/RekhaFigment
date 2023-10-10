/****************
* Class Name   : CDdBulkUpdateMacroController
* Created Date : Nov 29th 2022
* Author       : Sugan Karthik
* Description  : Controller for Macro Update Tool - we use the controller to parse the CSV and also initiate a batch job to update the Macros,
                 the test code for this class exists in CDdupdateMacroInstructionsBatchTest
****************/
public with sharing class CDdBulkUpdateMacroController {
    static final String MACRO_TARGET_PREFIX = 'Field.';
    @TestVisible
    static final String CSV_HEADER_ERROR = 'Error occurred: Please ensure that the CSV headers match the ones provided in the template';
    @AuraEnabled
    public static string runMacroUpdateBatchJob(String ticketNum, String parentPicklist, String childPicklist, String csvData){
        try {
            parentPicklist = MACRO_TARGET_PREFIX+parentPicklist;
            childPicklist = (childPicklist != null)? MACRO_TARGET_PREFIX+childPicklist : null;
            List<CDdupdateMacroInstructionsContext.oldToNewValueMapping> picklistMapping;
            if(String.isNotBlank(csvData)){
               picklistMapping = (List<CDdupdateMacroInstructionsContext.oldToNewValueMapping>)JSON.deserialize(csvData, List<CDdupdateMacroInstructionsContext.oldToNewValueMapping>.class);
            }
            List<CDdupdateMacroInstructionsContext> lstCnt = new List<CDdupdateMacroInstructionsContext>();
            for(CDdupdateMacroInstructionsContext.oldToNewValueMapping rec : picklistMapping){
                if(String.isNotBlank(rec.oldParentValue) && String.isNotBlank(rec.newParentValue) && String.isNotBlank(rec.oldChildValue) && String.isNotBlank(rec.newChildValue)){
                    //we escape the old parent and child values alone as they are being used in SOQL, the new values need to be assigned without any escaping
                    lstCnt.add(new CDdupdateMacroInstructionsContext(parentPicklist,childPicklist,String.escapeSingleQuotes(rec.OldParentValue),rec.newParentValue,String.escapeSingleQuotes(rec.oldChildValue),rec.newChildValue));
                }
            }
            //if there is input csv data but no parsed data - then the column names are mismatched
            if(String.isNotBlank(csvData) && lstCnt.isEmpty()){
                return CSV_HEADER_ERROR;
            }
            CDdupdateMacroInstructionsBatchV2 macroUpdate = new CDdupdateMacroInstructionsBatchV2(ticketNum,lstCnt);
            ID batchprocessid = Database.executeBatch(macroUpdate,1);
            return batchprocessid;
        } catch (Exception e) {
           return 'Error occurred: '+e.getMessage();
        }
    }
}