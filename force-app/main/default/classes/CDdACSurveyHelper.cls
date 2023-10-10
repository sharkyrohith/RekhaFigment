/**
* @author: Tia Xuan
* @date: 2022-01
* @description Creates AC Survey resutls in Salesforce
*/ 
public class CDdACSurveyHelper {

    public static final String CASE_PREFIX = '500';

    /**
    * @description Take a series of AC Survey task records and enter information into Survey Taken
    */
    public static void processSurveyResponse(List<AC_Survey_Task__c> tskList){
        List<SurveyTaker__c> surveysToInsert = new List<SurveyTaker__c>();
        List<SurveyQuestionResponse__c> respToInsert = new List<SurveyQuestionResponse__c>();
        List<String> caseIdList = new List<String>();
        for (AC_Survey_Task__c tsk : tskList){
            String strBody = tsk.Body__c.replaceAll('__c', '').replaceAll('_', '');
            ACSurvey body = (ACSurvey) JSON.deserialize(strBody, ACSurvey.class);
            SurveyTaker__c surveyTaken = new SurveyTaker__c();
            surveyTaken.AC_Contact_ID__c = body.contactId;
            if (String.isNotBlank(body.caseId)){
                caseIdList.add(body.caseId);
                surveyTaken.Case__c = body.caseId;
                surveyTaken.CASE_ID__c = body.caseId;
            }
            surveyTaken.Survey_Assigned_To__c = body.surveyAssignedTo;
            surveyTaken.Survey__c = body.survey;
            if(!String.isblank(body.ownerId)) {
                surveyTaken.OwnerId = body.ownerId;  
            }
            surveyTaken.Taken__c = body.taken;
            surveyTaken.SF_Contact_Id__c = body.SFContactId;
            surveyTaken.SF_Account_Id__c = body.SFAccountId;
            surveyTaken.Workflow_Id__c = body.WorkflowId;
            surveysToInsert.add(surveyTaken);

            for (ACSurveyResponse resp : body.responses){
                SurveyQuestionResponse__c response = new SurveyQuestionResponse__c();
                response.SurveyTaker__r = new SurveyTaker__c( AC_Contact_ID__c = body.contactId);
                response.Response__c = resp.response;
                response.Survey_Question__c = resp.surveyQuestion;
                response.of_Time_Question_was_Responded_to__c = resp.ofTimeQuestionWasRespondedTo;
                respToInsert.add(response);
            }
            
            tsk.Survey_Taken__r = new SurveyTaker__c( AC_Contact_ID__c = body.contactId);
            tsk.Processed__c  = true;
        }

        Map<Id, Case> caseList = new Map<Id, Case>([select Id from Case where Id =: caseIdList]);
        Set<Id> existingCaseIds = caseList.keySet();
        for (SurveyTaker__c st : surveysToInsert){
            if (!existingCaseIds.contains(st.Case__c)){
                st.Case__c = null;
            }
        }

        List<String> errorMsgList = new List<String>();
        List<Database.SaveResult> resList = new List<Database.SaveResult>();
  
        if (surveysToInsert.size() > 0){
            resList = Database.insert(surveysToInsert, false);
            errorMsgList = CDdErrorUtilities.processSaveResults(resList, errorMsgList);
        }

        if (respToInsert.size() > 0){
            resList = Database.insert(respToInsert, false);
            errorMsgList = CDdErrorUtilities.processSaveResults(resList, errorMsgList);
        }

        resList = Database.update(tskList, false);
        errorMsgList = CDdErrorUtilities.processSaveResults(resList, errorMsgList);

        if (errorMsgList.size() > 0){
            CDdErrorUtilities.createApexLogs(errorMsgList, 'CDdACSurveyHelper', 
                                                    'processSurveyResponse', LoggingLevel.ERROR); 
        }
    }

    public class ACSurvey {
        public String contactId;
        public String StreamDeliveryName;
        public String caseId {get; set {
            if (value != null && value.startsWith(CASE_PREFIX)){
                caseId = value;
            } else {
                caseId = null;
            }
        }}
        public String surveyAssignedTo;
        public String ownerId;
        public String survey;
        public String taken;
        public String SFAccountId;
        public String SFContactId;
        public String WorkflowId; 
        public List<ACSurveyResponse> responses;
    }

    public class ACSurveyResponse {
        public String response;
        public String surveyQuestion;
        public Integer ofTimeQuestionWasRespondedTo;
    }
}