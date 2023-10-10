/********************************************************************************************************************
* @author Sriram
* @date 11/07/2021
*
* @group Merchant Services
*
* @description Custom Apex Exception for Merchant Services
**************************************************************************************************************************************/
public class CDdMxSxException extends Exception {
    public static final String DML_OPERATION_INSERT = 'insert';
    public static final String DML_OPERATION_UPDATE = 'update';
    public static final String SYSTEM_CONTEXT = 'MxSx';
    /**
     * Log the errors to apex log
     * @param String dmlOperation - insert, update etc.
     * @param String class name
     * @param String method name
     * @param String event name - name of MxSx Event (if applicable)
     * @param System.LoggingLevel log level
     * @param String sObject Type
     * @param String reference field - a property on the sObject to extract the record Id
     * @param List<String> error messages
     * @param List<Sobject> Collection of sObject records to report errors on
     * @return
     */    
    public static void logDmlErrors(String dmlOperation, String className, String methodName, String eventName, LoggingLevel logLevel, String sObjectType, String referenceField, List<String> errorMessages, List<Sobject> sobjs) {
        if (sobjs.isEmpty() || errorMessages.isEmpty()){ return; }
        List<Apex_Log__c> logs = new List<Apex_Log__c>();
        List<Sobject> errorObjs = new List<Sobject>();
        for (Sobject o : sobjs){
            if ( (DML_OPERATION_INSERT.equals(dmlOperation) && String.isBlank(o.Id)) || (DML_OPERATION_UPDATE.equals(dmlOperation) && String.isNotBlank(o.Id)) ){ errorObjs.add(o); }
        }
        for (Sobject o : errorObjs){
            Id recordId = null;
            try { recordId = (o.isSet(referenceField) ? (Id)o.get(referenceField) : null ); } catch (Exception e) { }
            logs.add(createErrorLog(className, methodName, eventName, logLevel, sObjectType, recordId, String.join(errorMessages, ';')));
        }
        Database.insert(logs, false);
    } 
    /**
     * Log the errors to apex log
     * @param String class name
     * @param String method name
     * @param System.LoggingLevel log level
     * @param String sObject Type
     * @param Id record Id (reference id)
     * @param String error message
     * @return
     */    
    public static Apex_Log__c createErrorLog(String className, String methodName, String eventName, LoggingLevel logLevel, String sObjectType, Id recordId, String errorMessage) {
        return new Apex_Log__c(
            Class_Name__c = className,
            Method_Name__c = methodName,
            Object__c = sObjectType,            
            Operation__c = eventName,
            Log_Level__c = String.valueOf(logLevel),
            System_Context__c = SYSTEM_CONTEXT,
            User_in_Context__c = UserInfo.getUserId(),
            Record_ID__c = recordId,
            Reference_Id__c = recordId,
            Log__c = errorMessage
        );
    }
    /**
     * Return the sObject records that encountered an error or success during dml update
     * If hasError == true, process results that encountered an error
     * If hasError == false, process results that are successful
     * @param List<Database.SaveResult> sResults
     * @param List<Sobject> dmlSobjs - sObjects on which dml update is performed
     * @param Boolean hasError 
     * @return List<Sobject> - Return a Collection of sObjects
     */     
    public static List<Sobject> getSObjectsAfterUpdate(List<Database.SaveResult> sResults, List<Sobject> dmlSobjs, Boolean hasError){
        Map<Id, Sobject> dmlSobjsById = new Map<id, Sobject>();
        for (Sobject sObj : dmlSobjs){
            dmlSobjsById.put(sObj.Id, sObj);
        }
        List<Sobject> retSobjs = new List<Sobject>();
        for (Database.SaveResult sr : sResults){
            if ( (hasError && !sr.isSuccess()) || (!hasError && sr.isSuccess()) ) { retSobjs.add(dmlSobjsById.get(sr.getId())); }
        }
        return retSobjs; 
    }    
}