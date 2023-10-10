/*
 * @author: Jeegar
 * @date : 2019-05
 * @description: Utilities class to put functionalities that are common to the org.
 */
public with sharing class CDdErrorUtilities {
    /*****************************************************************************************************************************
    *
    * Constants & Private Variables
    *
    *****************************************************************************************************************************/
    public static final String PAYLOAD = 'Payload: ';
    /**
    * @description Create an Apex Log record for error messages
    * @params List<String>  errorMessages   List of strings with error messages.
              String        className       Name of the batch that had errors in it.
    */
    public Static List<Apex_Log__c> createApexLogs (List<String> messages, String className ){
        return createApexLogs(messages, className, null, LoggingLevel.ERROR);
    }
    /**
    * @description Create an Apex Log record for error messages
    * @params
     		  String 		request			HTTP request body
			  String 		response 		HTTP response body
			  String		recordId		id of the record
     		  List<String>  errorMessages   List of strings with error messages.
              String        className       Name of the batch that had errors in it.
              String        methodName      Name of the method where this log was generated from.
              String        logLevel        Type of log: Debug, Error, Warning.
    */
    public Static List<Apex_Log__c> createHTTPApexLogs(String request, String response, String recordId, List<String> messages, String className,
                                                       String methodName, System.LoggingLevel logLevel)
    {
        List<Apex_Log__c> logsToInsert = new List<Apex_Log__c>();
        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getInstance();
        Apex_Log__c apexLog;
        if(loggerSettings.Enable_Logging__c){
            for(String message : messages ) {
                apexLog = new Apex_Log__c();
                apexLog.Class_Name__c = classname;
                apexLog.Log__c = message;
                apexLog.Method_Name__c = methodName;
                apexLog.Log_Level__c = String.valueOf(logLevel);
                apexLog.Callout_Request__c  = request;
                apexLog.Callout_Response__c = response;
                apexLog.Record_ID__c = recordId;
                logsToInsert.add(apexLog);
            }
            if(!logsToInsert.isEmpty()) {
                Database.insert(logsToInsert, false);
            }
        }
        return logsToInsert;
    }


    // /**
    // * @description Convert Save Results list to a list of strings if there the save result is not successful.
    // */
    public Static List<String> processSaveResults(List<Database.SaveResult> sResults, List<String> errorMessages) {

        for(Database.SaveResult sr : sResults) {
            if(!sr.isSuccess()){
                for(Database.Error err : sr.getErrors()) {
                    errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields());
                }
            }
        }
        return errorMessages;
    }
    public Static List<String> processSaveResults(List<Database.SaveResult> sResults) {
        List<String> errorMessages = new List<String>();
        for(Database.SaveResult sr : sResults) {
            if(sr.isSuccess()){
                continue;
            }
            for(Database.Error err : sr.getErrors()) {
                errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields());
            }
        }
        return errorMessages;
    }
    // /**
    // * @description Convert Upsert Results list to a list of strings if there the upsert result is not successful.
    // */
    public Static List<String> processUpsertResults(List<Database.UpsertResult> uResults, List<String> errorMessages){
        for(Database.UpsertResult ur : uResults) {
            if(ur.isSuccess()){
                continue;
            }
            for(Database.Error err : ur.getErrors()) {
                errorMessages.add(ur.isCreated() + ':' + err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields());
            }
        }
        return errorMessages;
    }
    public Static List<String> processUpsertResults(List<Database.UpsertResult> uResults) {
        List<String> errorMessages = new List<String>();
        for(Database.UpsertResult ur : uResults) {
            if(ur.isSuccess()){
                continue;
            }
            for(Database.Error err : ur.getErrors()) {
                errorMessages.add(ur.isCreated() + ':' +err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields());
            }
        }
        return errorMessages;
    }
    /**
     * @description Create Apex Log records for error messages
     * @param errorMessages (List<String>);  List of strings with error messages.
     * @param className (String); Name of the batch that had errors in it.
     * @param methodName (String) Name of the method where this log was generated from.
     * @param logLevel (System.LoggingLevel); Type of log: Debug, Error, Warning.
     * @return List<Apex_Log__c>
     */
    public static List<Apex_Log__c> createApexLogs(List<String> messages, String className, String methodName, System.LoggingLevel logLevel) {
        return createApexLogs(messages,className,methodName,logLevel,true);
    }


    /**
     * @description Create Apex Log records for error messages
     * @param errorMessages (List<String>);  List of strings with error messages.
     * @param className (String); Name of the batch that had errors in it.
     * @param methodName (String) Name of the method where this log was generated from.
     * @param logLevel (System.LoggingLevel); Type of log: Debug, Error, Warning.
     * @param doInsert (Boolean); Where or not these apex logs should be inserted or just returned to the caller.
     * @return List<Apex_Log__c>
     */
    public static List<Apex_Log__c> createApexLogs(
        List<String> messages,
        String className,
        String methodName,
        System.LoggingLevel logLevel,
        Boolean doInsert
    ) {
        Apex_Log__c apexLog;
        List<Apex_Log__c> logsToInsert = new List<Apex_Log__c>();
        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getInstance();
        if(loggerSettings.Enable_Logging__c){
            for(String message : messages ) {
                logsToInsert.add(
                    createApexLog(message,className,methodName,null,null,logLevel)
                );
            }
            if(doInsert == true && !logsToInsert.isEmpty()) {
                Database.insert(logsToInsert, false);
            }
        }
        return logsToInsert;
    }

    /**
     * @description Create (but do not insert) an Apex_Log__c record.
     * @param message (String); the message to log.
     * @param className (String); Name of the batch that had errors in it.
     * @param methodName (String) Name of the method where this log was generated from.
     * @param logLevel (System.LoggingLevel); Type of log: Debug, Error, Warning.
     * @param recordId (Id); an Id relevant to this log.
     * @param referenceId (String); an external Id to record on the Apex_Log__c record.
     * @return Apex_Log__c
     */
    public static Apex_Log__c createApexLog(
        String message,
        String className,
        String methodName,
        Id recordId,
        String referenceId,
        System.LoggingLevel logLevel
    ){
        return new Apex_Log__c(
            Class_Name__c = className,
            Log__c = message,
            Method_Name__c = methodName,
            Record_ID__c = recordId,
            Reference_Id__c = referenceId,
            Log_Level__c = String.valueOf(logLevel)
        );
    }

    public class MyException extends Exception {}
    @InvocableMethod(label='Invoke ExceptionUtil')
    public static void throwcustomException(List<String> excmessage){

            throw new MyException('An internal exception happened during current operation.'+
                                  'Please contact system administrator with this exception details:'+excmessage[0]);
    }

     /**
    * @description Create an Apex Log record for error messages coming from platform events
    * @params List<String>  errorMessages   List of platform events with error messages.
    * @author - Sahil
    */
    public static void createLogFromPE(List<Exception_Log__e> exFromPEList) {
        List<Apex_Log__c> logsToInsert = new List<Apex_Log__c>();
        Apex_Log__c apexLog;
        for(Exception_Log__e ex : exFromPEList) {
            apexLog = new Apex_Log__c();
            apexLog.Object__c = ex.Object__c;
            apexLog.Operation__c = ex.Operation__c;
            apexLog.Record_ID__c = ex.Record_ID__c;
            apexLog.Log__c = ex.Exception_Details__c;
            apexLog.System_Context__c = ex.System_Context__c;
            apexLog.User_in_Context__c = ex.User_Id__c;
            logsToInsert.add(apexLog);
        }
        if(logsToInsert.size()>0) insert logsToInsert;
    }

    /*
    * Create PublishException
    * @param   objname          String  ObjectName
    * @param   processname      String  Process Name
    * @param   recordID         String  recordId
    * @param   exceptiondetails String  ErrorMessage/ExceptionMessage
    * @return  None
    -- Usage
        CDdErrorUtilities.publishException('errorMessage', 'CDdErrorUtilities', 'RecordId', 'ErrorMessage');
    */
    public  static void publishException(String objname, String processname, String recordID, String exceptiondetails){
        Exception_Log__e pe     = new Exception_Log__e();
        pe.Object__c            = objname;
        pe.Operation__c         = processname;
        pe.Exception_Details__c = exceptiondetails;
        pe.Record_ID__c         = recordID;
        pe.system_context__c    = getSystemContext();
        pe.User_Id__c           = String.valueOf(UserInfo.getUserId());
        //eventBus.publish(pe);
        publishPlatformEvent(new List<Exception_Log__e>{pe});
    }
    /*
    * Create PublishException
    * @param   objname          String  ObjectName
    * @param   processname      String  Process Name
    * @param   recordID         String  recordId
    * @param   ex               Exception  ExceptionMessage
    * @return  None
    -- Usage
        CDdErrorUtilities.publishException('errorMessage', 'CDdErrorUtilities', Exception);
    */
    public  static void publishException(String objname, String processname, String recordID, Exception exMessage){
        Exception_Log__e pe     = new Exception_Log__e();
        pe.Object__c            = objname;
        pe.Operation__c         = processname;
        pe.Exception_Details__c = getFormattedException(exMessage);
        pe.Record_ID__c         = recordID;
        pe.system_context__c    = getSystemContext();
        pe.User_Id__c           = String.valueOf(UserInfo.getUserId());
        publishPlatformEvent(new List<Exception_Log__e>{pe});
    }
    /*
    * Create PublishException
    * @param   objname          String  ObjectName
    * @param   processname      String  Process Name
    * @param   ex               Exception  ExceptionMessage
    * @return  None
    -- Usage
        CDdErrorUtilities.publishException('errorMessage', 'CDdErrorUtilities', Exception);
    */
    public  static void publishException(String objname, String processname, Exception exMessage){
        Exception_Log__e pe     = new Exception_Log__e();
        pe.Object__c            = objname;
        pe.Operation__c         = processname;
        pe.Exception_Details__c = getFormattedException(exMessage);
        pe.system_context__c    = getSystemContext();
        pe.User_Id__c           = String.valueOf(UserInfo.getUserId());
        publishPlatformEvent(new List<Exception_Log__e>{pe});
    }

    /*
    * Create PublishException
    * @param   objname          String  ObjectName
    * @param   processname      String  Process Name
    * @param   ex               Exception  ExceptionMessage
    * @param   payload          String
    * @return  None
    -- Usage
        CDdErrorUtilities.publishException('errorMessage', 'CDdErrorUtilities', Exception);
    */
    public static void publishException(Exception exMessage, String objname, String processname,  String payload){
        Exception_Log__e pe     = new Exception_Log__e();
        pe.Object__c            = objname;
        pe.Operation__c         = processname;
        pe.Exception_Details__c = getFormattedException(exMessage)+CDdCoreConstants.NEW_LINE+PAYLOAD+CDdCoreConstants.NEW_LINE+payload;
        pe.system_context__c    = getSystemContext();
        pe.User_Id__c           = String.valueOf(UserInfo.getUserId());
        publishPlatformEvent(new List<Exception_Log__e>{pe});
    }

    /*
    * Publish Exception for Save Result
    * @param   objname          String                      ObjectName
    * @param   processname      String                      Process Name
    * @param   listSaveResult   List<Database.SaveResult>   SaveResult
    * @return  None
    -- Usage
        CDdErrorUtilities.publishException('ObjectName', 'UpdateSomething', SaveResult);
    * @change Log
        03/2023     Jeegar      Added truncating of Exception Details after max Lenght.
    */
    public static void publishException(String objname, String processname, List<Database.SaveResult> listSaveResult){
       List<Exception_Log__e> pelist = new List<Exception_Log__e>();
        Exception_Log__e pe;
        for(Database.SaveResult res : listSaveResult){
            if(res.isSuccess()==false){
                pe = new Exception_Log__e();
                pe.Object__c    = objname;
        		pe.Operation__c = processname;
                String excdetail;
                if(res.getErrors().size() > 0 ) {
                    // getStackTrace gets you a stack trace till this line.
                    excdetail = getexceptionDetails(res.getErrors(), new dmlException().getStackTraceString());
                }

                pe.Exception_Details__c = excdetail;
                if(String.isNotBlank(res.getId())){
                    pe.Record_ID__c         = res.getId();
                }
                pelist.add(pe);
            }
        }
        /*
        if(pelist.size()>0){
            eventBus.publish(pelist);
        }
        */
        publishPlatformEvent(pelist);
    }
    /*
    * Publish Exception for Upsert result
    * @param   objname          String                      ObjectName
    * @param   processname      String                      Process Name
    * @param   listSaveResult   List<Database.UpsertResult>   SaveResult
    * @return  None
    */
    public static void publishException(String objname, String processname, List<Database.UpsertResult> listupsertResult){
        List<Exception_Log__e> pelist = new List<Exception_Log__e>();
        Exception_Log__e pe;
        for(Database.UpsertResult res : listupsertResult){
            if(res.isSuccess()==false){
                pe = new Exception_Log__e();
                pe.Object__c       = objname;
                pe.Operation__c    = processname;
                String excdetail;

                if(res.getErrors().size() > 0 ) {
                    // getStackTrace gets you a stack trace till this line.
                    excdetail = getexceptionDetails(res.getErrors(), new dmlException().getStackTraceString());
                }
                pe.Exception_Details__c = excdetail;
                if(String.isNotBlank(res.getId())){
                    pe.Record_ID__c = res.getId();
                }
                pelist.add(pe);
            }
        }
        // publish
        publishPlatformEvent(pelist);
     }

    /*
     * Publish Exception for Delete result
     * @param   objname          String                      ObjectName
     * @param   processname      String                      Process Name
     * @param   listSaveResult   List<Database.UpsertResult>   SaveResult
     * @return  None
     */
    public static void publishException(String objname, String processname, List<Database.DeleteResult> listDeleteResult){
        List<Exception_Log__e> pelist = new List<Exception_Log__e>();
        Exception_Log__e pe;
        for(Database.DeleteResult res : listDeleteResult){
            if(res.isSuccess()==false){
                pe = new Exception_Log__e();
                pe.Object__c       = objname;
                pe.Operation__c    = processname;
                String excdetail;
                if(res.getErrors().size() > 0 ) {
                    // getStackTrace gets you a stack trace till this line.
                    excdetail = getexceptionDetails(res.getErrors(), new dmlException().getStackTraceString());
                }
                pe.Exception_Details__c = excdetail;
                System.debug(excdetail);
                if(String.isNotBlank(res.getId())){
                    pe.Record_ID__c = res.getId();
                }
                pelist.add(pe);
            }
        }
        // publish
        publishPlatformEvent(pelist);
    }

    /*
    * Generic method for publish List of Platform Event.
    * @param   errorLogList      List<Exception_Log__e>
    * @return  None
    * */
    @TestVisible
    private static void publishPlatformEvent(List<Exception_Log__e> errorLogList)
    {
        if(!errorLogList.isEmpty()){
            // we need to try to insert
            try{
                EventBus.publish(errorLogList);
            } catch(Exception ex) {
                // No need to handle ..
            }
        }
    }
    /**
     * Retrieves System Context and formats it into string for logging
     *
     * @return  String
     */
    @TestVisible
    private  static String getSystemContext()
    {
        String strSystemContext = CddCoreConstants.BLANK_STRING;
        if (System.isQueueable()) strSystemContext += 'isQueueable' + CddCoreConstants.DELIMITER_SEMICOLON;
        if (System.isFuture()) strSystemContext += 'isFuture' + CddCoreConstants.DELIMITER_SEMICOLON;
        if (System.isBatch()) strSystemContext += 'isBatch' + CddCoreConstants.DELIMITER_SEMICOLON;
        if (System.isScheduled()) strSystemContext += 'isScheduled' + CddCoreConstants.DELIMITER_SEMICOLON;

        if (Trigger.isExecuting == true){
            if (Trigger.isInsert) strSystemContext += 'Trigger.isInsert' + CddCoreConstants.DELIMITER_SEMICOLON;
            if (Trigger.isUpdate) strSystemContext += 'Trigger.isUpdate' + CddCoreConstants.DELIMITER_SEMICOLON;
            if (Trigger.isDelete) strSystemContext += 'Trigger.isDelete' + CddCoreConstants.DELIMITER_SEMICOLON;
            if (Trigger.isUndelete) strSystemContext += 'Trigger.isUndelete' + CddCoreConstants.DELIMITER_SEMICOLON;
            if (Trigger.isAfter) strSystemContext += 'Trigger.isAfter' + CddCoreConstants.DELIMITER_SEMICOLON;
            if (Trigger.isBefore) strSystemContext += 'Trigger.isBefore' + CddCoreConstants.DELIMITER_SEMICOLON;
        }
        return strSystemContext;
    }
    /**
     * Formats exception message for the
     * @param   ex  Exception   ExceptionMessage
     * @return  String
     */
    @TestVisible
    private static String getFormattedException(Exception ex) {
        String strExceptionMessage = CddCoreConstants.BLANK_STRING;
        if (ex != null) {
            if (String.isNotBlank(ex.getMessage())) strExceptionMessage += 'getMessage() = ' + ex.getMessage();
            if (String.isNotBlank(String.valueOf(ex.getLineNumber()))) strExceptionMessage += 'getLineNumber() = ' + String.valueOf(ex.getLineNumber());
            String stacktrace = ex.getStackTraceString() +new DmlException().getStackTraceString().substringAfter('\n');
            if (String.isNotBlank(stacktrace)) strExceptionMessage += CddCoreConstants.DELIMITER_SEMICOLON + 'getStackTraceString() = ' + stacktrace;
        }
        return strExceptionMessage;
    }

    /**
     * Formats exception message for the
     * @param   information String - something to add before the formatted exception string.
     * @param   ex  Exception   ExceptionMessage
     * @return  String
     */
    public static String getFormattedException(String msg,Exception ex) {
        return ('Message = ' + msg + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE + getFormattedException(ex));
    }

    /**
     * Construct feature log with user and time stamp
     * @param featureName String - Name of feature to identify source of the log, Ex: MISSION_CONTROL
     * @param message String - content of the log
     * @return String - Fully constructed feature log statememnt
     */
    public static String constructFeatureLog(String featureName, String message, Boolean firstLogEver){
        String featureLogStatement = '';
        //add a header if it is the first log ever
        if(firstLogEver){
            featureLogStatement += '*** User || Time || Feature || Log ***' + '\n';
        }
        featureLogStatement += '\n***'+ UserInfo.getName() + ' || '+Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')+' || '+featureName+' || '+message+'***';
        return featureLogStatement;
    }

    /**
     * Extracts details from error results and converts it to a string
     * @param   errorsToProcess List<Database.Error>    Errors returned by save , delete, or upsert result
     * @return  String
     * @author  Jeegar
     * @date    3/23
     *
     */
    private static String getexceptionDetails(List<Database.Error> errorsToProcess , String stackTrace) {
        String exceptionDetails = '';
        for(Database.Error err : errorsToProcess) {
            exceptionDetails += 'Status Code : ' + err.getStatusCode();
            exceptionDetails += ': Message : ' + err.getMessage();
            if(err.getFields() != null) {
                exceptionDetails += ': Fields : ' + err.getFields();
            }
            exceptionDetails += exceptionDetails + stackTrace;

            if(exceptionDetails.length() > CDdCoreConstants.TEXTAREA_SIZE_MAX - 72) {
                exceptionDetails = exceptionDetails.substring(0, CDdCoreConstants.TEXTAREA_SIZE_MAX);
            }

        }
        return exceptionDetails;
    }
}