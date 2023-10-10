/**
 * 
 * @author: Tia Xuan
 * @date: 2020-02
 * @description Handler class for Neverbounce
 * 
 */
public with sharing class CDdNeverbounceHandler {
    public class NeverbounceException extends Exception {}

    /**
    * @description setting for Neverbounce
    */
    public static Neverbounce_Setting__mdt setting = [ select   MasterLabel, 
                                                                Lead_Record_Type_IDs__c,
                                                                Batch_Size__c,
                                                                Batch_Total_Records__c,
                                                                Emails_Invalid__c,
                                                                Email_Verification_Status_Invalid__c,
                                                                Enabled_Single_Check_Verify_Email__c,
                                                                Platform_Event_Verify_Email_Size__c,
                                                                Named_Credential__c,
                                                                Api_Version__c,
                                                                URL_Path_Job_Create__c,
                                                                URL_Path_Job_Status__c,
                                                                URL_Path_Job_Download__c,
                                                                URL_Path_Verify_Email__c
                                                        from Neverbounce_Setting__mdt
                                                        where MasterLabel = 'Default'];

    public static final Set<String> leadRecordTypeIds;
    public static final Integer TOTAL_SIZE;
    public static final Integer BATCH_SIZE;    
    public static final Set<String> EMAILS_INVALID;
    public static final String EMAIL_VERIFICATION_STATUS_INVALID;
    public static final Boolean ENABLED_SINGLE_CHECK_VERIFY_EMAIL;
    public static final Integer PLATFORM_EVENT_VERIFY_EMAIL_SIZE;
    public static final String SOBJECT_TYPE_LEAD = 'Lead';
    public static final String NEVERBOUNCE_JOB_STATUS_CREATED = 'created';
    public static final Set<String> NEVERBOUNCE_JOB_CLEANUP_STATUSES = new Set<String>{'complete','failed'};
    public static final String NEVERBOUNCE_ENDPOINT;
    public static final String NEVERBOUNCE_API_VERSION;
    public static final String NEVERBOUNCE_URL_PREFIX;
    public static final String NEVERBOUNCE_URL_JOB_CREATE;
    public static final String NEVERBOUNCE_URL_JOB_STATUS;
    public static final String NEVERBOUNCE_URL_JOB_DOWNLOAD;
    public static final String NEVERBOUNCE_URL_VERIFY_EMAIL;
    public static final String NEVERBOUNCE_TOKEN_KEY = '{!$Credential.Password}';   

    static {
        leadRecordTypeIds = new Set<String>(setting.Lead_Record_Type_IDs__c.split(';'));
        TOTAL_SIZE = Integer.valueOf(CDdNeverbounceHandler.setting.Batch_Total_Records__c);
        BATCH_SIZE = Integer.valueOf(CDdNeverbounceHandler.setting.Batch_Size__c);        
        EMAILS_INVALID = new Set<String>();
        for (String emailInvalid : setting.Emails_Invalid__c.split(';')){
            EMAILS_INVALID.add(emailInvalid.toLowerCase());
        }
        EMAIL_VERIFICATION_STATUS_INVALID = setting.Email_Verification_Status_Invalid__c;
        ENABLED_SINGLE_CHECK_VERIFY_EMAIL = setting.Enabled_Single_Check_Verify_Email__c || Test.isRunningTest();
        PLATFORM_EVENT_VERIFY_EMAIL_SIZE = Integer.valueOf(setting.Platform_Event_Verify_Email_Size__c);
        NEVERBOUNCE_ENDPOINT = 'callout:' + setting.Named_Credential__c;
        NEVERBOUNCE_API_VERSION = setting.Api_Version__c;
        NEVERBOUNCE_URL_PREFIX = NEVERBOUNCE_ENDPOINT + '/' + NEVERBOUNCE_API_VERSION + '/';
        NEVERBOUNCE_URL_JOB_CREATE = NEVERBOUNCE_URL_PREFIX + setting.URL_Path_Job_Create__c;
        NEVERBOUNCE_URL_JOB_STATUS = NEVERBOUNCE_URL_PREFIX + setting.URL_Path_Job_Status__c;
        NEVERBOUNCE_URL_JOB_DOWNLOAD = NEVERBOUNCE_URL_PREFIX + setting.URL_Path_Job_Download__c;
        NEVERBOUNCE_URL_VERIFY_EMAIL = NEVERBOUNCE_URL_PREFIX + setting.URL_Path_Verify_Email__c;
    }
    
    public static String createJob(Map<String, String> emailsMap){ 
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String callURL = NEVERBOUNCE_URL_JOB_CREATE;

        String data = ' {';
        data += ' "key":"' + NEVERBOUNCE_TOKEN_KEY + '",';
        data += ' "input_location":"supplied",';
        data += ' "filename":"sample.csv",';
        data += ' "auto_start":1,';
        data += ' "auto_parse":1,';
        data += ' "input":[ ';
        Integer emailsCount = 0;
        for (String key : emailsMap.keySet()){
            if (emailsCount > 0){
                data += ',';
            }
            data += '[ "' + key + '",';
            data += ' "' + emailsMap.get(key) + '"]';
            emailsCount++;
        }
        data += ' ] ';
        data += ' } ';
        System.debug('data:' + data);

        request.setEndpoint(callURL);
        request.setHeader('content-type', 'application/json');
        request.setMethod('POST');
        request.setBody(data);
        request.setTimeout(60000);

        HttpResponse response = http.send(request);
        System.debug('Body:' + response.getBody());

        if (response.getStatusCode() > 400){
            throw new NeverbounceException(response.getBody());
        } else {
            CDdNeverbounceCreateJobResponse wrp = (CDdNeverbounceCreateJobResponse) JSON.deserialize(response.getBody(), CDdNeverbounceCreateJobResponse.class);
            if (String.isNotBlank(wrp.job_id)){
                return wrp.job_id;
            } else {
                throw new NeverbounceException(wrp.message);
            }
        }
    }

    public static String verifyEmail(String email){ 
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NEVERBOUNCE_URL_VERIFY_EMAIL);
        request.setHeader('content-type', 'application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(new Map<String, String>{'key'=>NEVERBOUNCE_TOKEN_KEY,'email'=>email}));
        request.setTimeout(60000);

        HttpResponse response = http.send(request);
        System.debug('Body:' + response.getBody());

        if (response.getStatusCode() > 400){
            throw new NeverbounceException(response.getBody());
        } else {
            CDdNeverbounceVerifyEmailResponse wrp = (CDdNeverbounceVerifyEmailResponse) JSON.deserialize(response.getBody(), CDdNeverbounceVerifyEmailResponse.class);
            if (String.isNotBlank(wrp.status) && 'success'.equals(wrp.status)){
                return wrp.result;
            } else {
                throw new NeverbounceException(wrp.message);
            }
        }
    }    

    public static String getJobStatus(String jobId){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NEVERBOUNCE_URL_JOB_STATUS);
        request.setHeader('content-type', 'application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(new Map<String, String>{'key'=>NEVERBOUNCE_TOKEN_KEY,'job_id'=>jobId}));
        request.setTimeout(60000);

        HttpResponse response = http.send(request);
        System.debug('Body:' + response.getBody());

        if (response.getStatusCode() > 400){
            throw new NeverbounceException(response.getBody());
        }
        CDdNeverbounceGetJobStatusResponse wrp = (CDdNeverbounceGetJobStatusResponse) JSON.deserialize(response.getBody(), CDdNeverbounceGetJobStatusResponse.class);
        return wrp.job_status;            
    }

    public static Map<String, String> getJobResults(String jobId){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NEVERBOUNCE_URL_JOB_DOWNLOAD);
        request.setHeader('content-type', 'application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(new Map<String, String>{'key'=>NEVERBOUNCE_TOKEN_KEY,'job_id'=>jobId}));
        request.setTimeout(60000);

        HttpResponse response = http.send(request);
        System.debug('Body:' + response.getBody());

        if (response.getStatusCode() > 400){
           throw new NeverbounceException(response.getBody());
        } else {
            String results = response.getBody();
            List<String> resList = results.split('\n');
            Map<String, String> resMap = new Map<String, String>();
            for (String res : resList){
                // Line should be <id>,<email>,<status> in csv format
                String [] line = res.split(',');
                String id = line[0];
                if (id != null){
                    id = id.replaceAll('"', '').trim();
                }
                String status = line[2];
                if (status != null){
                    status = status.replaceAll('"', '').trim();
                }
                resMap.put(id, status);
            }
            return resMap;
        }
    }

    public static Map<String, String> getCreateJobRequestData(List<SObject> sObjects){
        Map<String, String> data = new Map<String, String>();
        for (SObject item : sObjects){
            String id = (String)item.get('Id');
            String email = (String)item.get('Email');
            if (String.isNotBlank(email)){
                data.put(id, email);
            }
        }
        return data;
    }

    public static void verifyEmails(List<Lead> leadsToProcess){
        List<Lead> leadsToUpdate = new List<Lead>();
        List<String> errorMessages = new List<String>();
        try {
            for (Lead l : leadsToProcess){
                leadsToUpdate.add(new Lead(
                    Id = l.Id,
                    Email_Verification_Status__c = verifyEmail(l.Email),
                    Email_Updated__c = false
                ));
            }
            if (!leadsToUpdate.isEmpty()){
                Database.SaveResult[] updateResults = Database.update(leadsToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
                if(!errorMessages.isEmpty()){
                    CDdErrorUtilities.createApexLogs(errorMessages, 'CDdNeverbounceHandler');
                }     
            }
        } catch(NeverbounceException nbEx){
            CDdErrorUtilities.createApexLogs(new List<String>{nbEx.getMessage()}, 'CDdNeverbounceHandler');
        }        
    }    

    public static void insertNeverbounceTasks(Set<String> jobIds, String sObjectType, String status){
        List<Neverbounce_Task__c> tasks = new List<Neverbounce_Task__c>();
        for (String jobId : jobIds){
            tasks.add(new Neverbounce_Task__c(
                Job_ID__c = jobId,
                Status__c = status,
                Type__c = sObjectType
            ));
        }
        insert tasks;        
    }

    public static void cleanupNeverbounceTasks(){
        List<Neverbounce_Task__c> tasksToDelete = new List<Neverbounce_Task__c>();
        for (Neverbounce_Task__c ntc : [SELECT Id 
                                        FROM Neverbounce_Task__c
                                        WHERE Status__c IN :NEVERBOUNCE_JOB_CLEANUP_STATUSES]){
            tasksToDelete.add(ntc);
        }
        delete tasksToDelete;        
    }    

    public class CDdNeverbounceCreateJobResponse{
        public String status {get; set;}
        public String job_id {get; set;}
        public String message {get; set;}
    }
    
    public class CDdNeverbounceVerifyEmailResponse{
        public String status {get; set;}
        public String result {get; set;}
        public String message {get; set;}
    }    

    public class CDdNeverbounceGetJobStatusResponse{
        public String status {get; set;}
        public String id {get; set;}
        public String job_status {get; set;}
    }    
}