/**
 *
 * @author: Tia Xuan
 * @date: 2020-04
 * @description class for Delighted Task
 *
 */

public class CDdDelightedTaskHelper {

    /**
     * @author: Jeegar
     * @date:   2021-03
     * @param   newList     List    Delighted_Tasks__c
     * @param   oldMap      Map     Delighted_Tasks__c
     * @return  None
     * @Description Update the delighted taks's Send_Time__c field.
     */
    public static void updateDelightedTaskSendTime(List<Delighted_Tasks__c> newList, Map<Id, Delighted_Tasks__c> oldMap) {
        for (Delighted_Tasks__c dt : newList){
            if (dt.Survey_Provider__c == CDdSupportConstants.SURVEY_PROVIDER_QUALTRICS
            ||( dt.Sent__c == true
                && (oldMap == null ||
                    (oldMap != null &&
                        dt.Sent__c != oldMap.get(dt.Id).Sent__c)))){

                dt.Send_Time__c = System.now();
            }
        }
    }

    /**
     * @author: Jeegar
     * @date:   2021-03
     * @param   newList     List    Delighted_Tasks__c
     * @param   oldMap      Map     Delighted_Tasks__c
     * @return  None
     * @Description For new Cases, update the Delighted_Task_Created__c field
     *              For Qualtrics Tasks or sent Delighted Tasks
     *                  update Survey_Date_Sent__c and Delighted_Survey_Sent__c fields
     */

     public static void updateCases(List<Delighted_Tasks__c> newList, Map<Id, Delighted_Tasks__c> oldMap){
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();
        Case tempCase;
        for (Delighted_Tasks__c dt : newList){
            tempCase = new Case();
            if(oldMap == null) {
                tempCase.Id = dt.Case__c;
                tempCase.Delighted_Task_Created__c = System.now();

            }
            if (dt.Survey_Provider__c == CDdSupportConstants.SURVEY_PROVIDER_QUALTRICS
                || ( dt.Sent__c == true
                    && (oldMap == null
                        || (oldMap != null
                        && dt.Sent__c != oldMap.get(dt.Id).Sent__c)))){

                tempCase.Id = dt.Case__c;
                tempCase.Survey_Date_Sent__c = Date.today();
                tempCase.Delighted_Survey_Sent__c = Datetime.now();
            }
            if(tempCase.id != null) {
                casesToUpdate.put(tempCase.Id, tempCase);
            }
        }
        if (casesToUpdate.size() > 0){
            CDdTriggerConstantsUtil.skipCaseTriggerExecution = true;
            update casesToUpdate.values();
        }
    }

    /**
    * @description BZAP-16100 - Convert Outbound Message
    * @author Jose Vega | 09-08-2022
    * @param List<Delighted_Tasks__c> newList
    **/
    public static void sendQualtricSurvey(List<Delighted_Tasks__c> newList) {
        if(!CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_Send_Qualtric_Survey_Trigger__c')) {
            Set<Id> delightedTaskIds = new Set<Id>();

            for(Delighted_Tasks__c delightedTask : newList) {
                if(evaluateShouldSendQualtricsSurvey(delightedTask)) {
                    delightedTaskIds.add(delightedTask.Id);
                }
            }

            if(delightedTaskIds.size() > 0) {
                List<String> errorMessages = new List<String>();
                try {
                    handleQualtricSurveys(delightedTaskIds);
                } catch (System.AsyncException ex) {
                    errorMessages.add('Executing Future method from Future method. Exception Message : ' + ex.getMessage()
                    + ' Exception Type: ' + ex.getTypeName() + ' StackTrace: ' + ex.getStackTraceString());
                } catch (Exception ex) {
                    errorMessages.add('Exception Message : ' + ex.getMessage()
                    + ' Exception Type: ' + ex.getTypeName() + ' StackTrace: ' + ex.getStackTraceString());
                } finally {
                    if (!errorMessages.isEmpty()) {
                        CDdErrorUtilities.createApexLogs(errorMessages, 'CDdDelightedTaskHelper', 'sendQualtricSurvey', LoggingLevel.ERROR);
                    }
                }
            }
        }
    }

    /**
    * @description Determine if we should send qualtric survery
    * @author Jose Vega | 09-14-2022
    * @param Delighted_Tasks__c delightedTask
    * @return Boolean
    **/
    private static Boolean evaluateShouldSendQualtricsSurvey(Delighted_Tasks__c delightedTask) {
        return !delightedTask.Sent__c
                && (String.isBlank(delightedTask.Survey_Provider__c)
                    || delightedTask.Survey_Provider__c == CDdSupportConstants.SURVEY_PROVIDER_QUALTRICS)
                && (delightedTask.Send_Time__c == null
                    || delightedTask.Send_Time__c <= System.now());
    }

    /**
    * @description BZAP-16100
    * @author Jose Vega | 09-08-2022
    * @param Set<Id> delightedTaskIds
    **/
    @future(callout=true)
    private static void handleQualtricSurveys(Set<Id> delightedTaskIds) {
        List<Delighted_Tasks__c> tasks;

        if(delightedTaskIds.size() > 0) {
            tasks = [SELECT
                        Id, Case__c, Case__r.OwnerId, Case__r.Contact.FirstName, Case__r.Contact.LastName, Case_Contact__c,
                        Cassie_Subscription_URL__c, Contact_Email__c, Case__r.Solved_At__c,
                        GDPR_Persona__c, Name, OwnerId, Owner.Name, Send_Time__c,
                        Web_Email__c, Language__c
                    FROM  Delighted_Tasks__c
                    WHERE Id in: delightedTaskIds];
        }
        if(tasks != null && tasks.size() > 0 ) {
            processQualtricSurveys(tasks);
        }
    }

    /**
    * @description Performs HTTP callout to AWS SNS
    * @author Jose Vega | 09-14-2022
    * @param List<Delighted_Tasks__c> tasks
    **/
    private Static void processQualtricSurveys(List<Delighted_Tasks__c> tasks) {
        Map<String, String> qualtricsEndpointbyLanguage = getQualtricsEndpoints();
        List<Delighted_Tasks__c> taskToUpdate = new List<Delighted_Tasks__c>();
        List<String> errorMessages = new List<String>();

        for (Delighted_Tasks__c delightedTask : tasks) {

            String languageEndpoint = qualtricsEndpointbyLanguage.get(delightedTask.Language__c);
            if (String.isEmpty(languageEndpoint)) {
                continue;
            }

            CDdQualtricsRequest request = new CDdQualtricsRequest();
            request.Identifier = delightedTask.Id;
            request.CaseIdentifier = delightedTask.Case__c;
            request.CaseContact = delightedTask.Case_Contact__c;
            request.CassieSubscriptionURL = delightedTask.Cassie_Subscription_URL__c;
            request.ContactEmail = delightedTask.Contact_Email__c;
            request.GDPRPersona = delightedTask.GDPR_Persona__c;
            request.Name = delightedTask.Name;
            request.OwnerId = delightedTask.OwnerId;
            request.CaseOwner = delightedTask.Case__r.OwnerId;
            request.SendTime = delightedTask.Send_Time__c;
            request.WebEmail = delightedTask.Web_Email__c;
            request.FirstName = delightedTask.Case__r.Contact.FirstName;
            request.LastName = delightedTask.Case__r.Contact.LastName;
            request.AgentName = delightedTask.Owner.Name;
            if(delightedTask.Case__r.Solved_At__c != null){
                request.SolvedDate = delightedTask.Case__r.Solved_At__c.format('MMM d, y');
            }
            request.Endpoint = languageEndpoint;

            CDdAmazonSNSClient.Response response = CDdAmazonSNSClient.publish(
                JSON.serialize(request), 'QUALTRICS', Label.AWS_Qualtric_SNS_Topic);

            if(response.success) {
                taskToUpdate.add(new Delighted_Tasks__c(Id = delightedTask.Id, Sent__c = true ));
            }
        }

        if(!taskToUpdate.isEmpty()) {
            try{
                Database.SaveResult[] updateResults = Database.update(taskToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
            } catch(Exception ex) {
                errorMessages.add('Exception Message : ' + ex.getMessage()
                + ' Exception Type: ' + ex.getTypeName() + ' StackTrace: ' + ex.getStackTraceString());
            }
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdDelightedTaskHelper');
            }
        }
    }

    /**
    * @description Creates Map of Language to Endpoint
    * @author Jose Vega | 09-14-2022
    * @return Map<String, String>
    **/
    private static Map<String, String> getQualtricsEndpoints() {
        List<Qualtrics_Configuration__mdt> qcs = [
            SELECT Language__c, Endpoint__c
            FROM Qualtrics_Configuration__mdt
            WHERE Active__c = true AND Is_Sandbox__c = :CDdUtilities.getIsSandbox()];
        Map<String, String> endpointByLanguage = new Map<String, String>();
        for(Qualtrics_Configuration__mdt qc : qcs) {
            endpointByLanguage.put(qc.Language__c, qc.Endpoint__c);
        }
        return endpointByLanguage;
    }

    /**
     * @author: Jeegar
     * @date: Aug 2020
     * BZAPSUP-205 Convert Delighted Batch to Trigger
     *          description goes here
     */
    public static void sendCSATSurvey(List<Delighted_Tasks__c> newList) {
        if(CDdExperimentSvc.getFeatureFlag('Send_Delighted_Survey_Trigger__c')) {
            Set<Id> delightedTaskIds = new Set<Id>();
            for(Delighted_Tasks__c delightedTask : newList) {
                if(!delightedTask.sent__c
                    && (String.isBlank(delightedTask.Survey_Provider__c)
                        || delightedTask.Survey_Provider__c == CDdSupportConstants.SURVEY_PROVIDER_DELIGHTED)
                    && (delightedTask.Send_Time__c == null
                        || delightedTask.Send_Time__c <= System.now())) {

                    delightedTaskIds.add(delightedTask.Id);

                }
            }
            if(delightedTaskIds.size() > 0) {
                try {
                    handleDelightedSurveys(delightedTaskIds);
                } catch (System.AsyncException ex) {
                    List<String> errorMessages = new List<String>();
                    errorMessages.add('Executing Future method from Future method. Exception Message : ' + ex.getMessage()
                    + ' Exception Type: ' + ex.getTypeName() + ' StackTrace: ' + ex.getStackTraceString());

                    CDdErrorUtilities.createApexLogs(errorMessages, 'CDdDelightedTaskHelper', 'sendCSATSurvey', LoggingLevel.ERROR);
                }
            }
        }

    }

    /**
     * @author: Jeegar
     * @date: Aug 2020
     * BZAPSUP-205 Convert Delighted Batch to Trigger
     *                  Description goes here
     */
    @future
    public static void handleDelightedSurveys(Set<Id> delightedTaskIds) {
        // add flag to disable handling
        List<Delighted_Tasks__c> tasks;

        if(delightedTaskIds.size() > 0) {
            tasks = [SELECT Id, Case__c, Case__r.ContactEmail, Case__r.SuppliedEmail, Case__r.CreatedDate, Sent__c,
                            Case__r.User_Id__c, Case__r.CaseOriginFormatted__c, Survey__c, Error_Message__c, Survey_Provider__c
                     FROM  Delighted_Tasks__c
                     WHERE Id in: delightedTaskIds];

        }
        if(tasks != null && tasks.size() > 0 ) {
            processDelightedSurveys(tasks);
        }

    }

    /**
     * @author: Jeegar
     * @date: Aug 2020
     * BZAPSUP-205 Convert Delighted Batch to Trigger
     *          Process Delighted Task records. If there are errors set the error message and update the Delighted Task record.
     */

    public Static void processDelightedSurveys(List<Delighted_Tasks__c> tasks) {
        List<Delighted_Tasks__c> recToUpdate = new List<Delighted_Tasks__c>();
        for (Delighted_Tasks__c stat : tasks){
            try {
                if (String.isBlank(stat.Case__r.ContactEmail)
                    && String.isBlank(stat.Case__r.SuppliedEmail)){
                    if (stat.Error_Message__c != 'Request not sent due to missing email'){
                        stat.Sent__c = false;
                        stat.Error_Message__c = 'Request not sent due to missing email';
                        stat.Error__c = true;
                        recToUpdate.add(stat);
                    }
                }
            } catch (Exception e){
                stat.Error_Message__c = e.getMessage();
                stat.Sent__c = false;
                stat.Error__c = true;
                recToUpdate.add(stat);
            }
        }
        System.debug('### rectoUpdate Size = ' + rectoUpdate.size());

        if (recToUpdate.size() > 0){

            Database.update(recToUpdate, false);
            // process save results here?
        }
    }

    /*
     * Tia Xuan
     * @Date 03-2022
     * Generate Subscription link
     * */
	public static void updateSubscriptionLink(List<Delighted_Tasks__c> newList){
        Boolean subLinkEnabled = CDdGDPREmailHelper.ENABLE_SUBSCRIPTION;
        if (subLinkEnabled){
            subLinkEnabled = CDdGDPREmailHelper.SETTING.Enable_Delighted_Task_Trigger__c != null
                                ? CDdGDPREmailHelper.SETTING.Enable_Delighted_Task_Trigger__c : false;
        }

        if(!subLinkEnabled) return;

        List<Id> caseIdList = new List<Id>();

        for(Delighted_Tasks__c dTask:newList){
            if(dTask.Contact_Email__c != null ){
                caseIdList.add(dTask.Case__c);
            }
        }

        if (caseIdList.size() > 0){
            Map<Id, String> personaLangMap = CDdGDPREmailHelper.getPersonaLanguageFromCase(caseIdList);
            for(Delighted_Tasks__c dTask:newList){
                if(String.isNotBlank(dTask.Contact_Email__c)){
                    String email = dTask.Contact_Email__c;
                    String perLang = personaLangMap.get(dTask.Case__c);
                    if (String.isNotBlank(perLang)){
                        List<String> perLangList = perLang.split(CDdGDPRConstants.SEPARATOR);
                        if (perLangList.size() > 0) {
                            String persona = perLangList[0];
                            String language = CDdGDPRConstants.DEFAULT_LANGUAGE;
                            if (perLangList.size() > 1){
                                language = perLangList[1];
                            }

                            dTask.GDPR_Persona__c = persona;
                            dTask.Cassie_Subscription_URL__c =
                                CDdGDPREmailHelper.getEncryptedSubscriptionLink(email, persona, language);
                        }
                    }
                }
            }
        }
    }
}