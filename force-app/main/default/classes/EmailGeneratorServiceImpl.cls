public inherited sharing class EmailGeneratorServiceImpl implements IEmailGeneratorService{
    /**
     *  @author     Sugan
     * @date        2/9/2023
     * @decription  A method to prepare emails with templates and custom merge fields and values
     * @param       templateIdVal - email template Id, targetObjectId - Id for email template merge fields, mergeValuesForTemplate - custom merge fields
     * @return      Messaging.SingleEmailMessage - email output
     */
    static final OrgWideEmailAddress[] supportEmail = [select Id from OrgWideEmailAddress where Address =:System.label.Support_EmailId];
    //Note: the test context needs to be set explicitly for test methods - we are setting this variable from test classes to avoid calls to test.isrunningtest for every transaction
    @TestVisible
    static Boolean isTestContext = false;

    @TestVisible
    static Messaging.SingleEmailMessage testEmailMsg;//we set the test email msg while running unit tests as we cannot stub the Messaging.renderStoredEmailTemplate method
    public Messaging.SingleEmailMessage getEmailToSend(String templateIdVal, String whatId, String[] toAddresses,Map<String,String> mergeValuesForTemplate,Boolean isSupport){
        Messaging.SingleEmailMessage mail =  isTestContext ? testEmailMsg : (Messaging.renderStoredEmailTemplate(templateIdVal, null, whatId));
        if(isSupport && !supportEmail.isEmpty()){
            mail.setOrgWideEmailAddressId(supportEmail[0].Id);
        }
        if(toAddresses != null){
            mail.setToAddresses(toAddresses);
        }
        String htmlBody = mail.htmlBody;
        for(String mergeField : mergeValuesForTemplate.keyset()){
            htmlBody = htmlBody.replaceAll(mergeField,mergeValuesForTemplate.get(mergeField));
        }
        mail.setHtmlBody(htmlBody);
        //logic to replace contact_name on email body
        return mail;
    }
    /**
     *  @author     Sugan
     * @date        4/6/2023
     * @decription  A method to Fire an email alert - we have a flow (created as a part of project horizon) that does this - and we simply kick of the flow from this method.
     * It accomplishes 2 things
     *  1 - configure everything into an email alert
     *  2 - send an email from apex - while still counting against the wf email limit for the day (around 2 Million for figment) which is way higher than single apex limit (around 6000 for figment)
     * PRE-REQUISITES TO USE THIS METHOD:
     *  1. A new email alert
     *  2. Add a branch for the email alert into Workflow_Email_Alert_Evaluator_Case for case and the corresponding flow for other sobjects
     * @param       recordId - for merge values, sobjecttype - we can build for all objects in the furure (this method only has case for now), emailAlertName - the developer name of the email alert to fire
     */
    public void sendWFEmailAlert(String recordId, String sObjectType, String emailAlertName){
        //Create parameter map
        Map<String, Object> Params = new Map<String, Object>();
        Params.put('RecordId',recordId);
        Params.put('EmailAlertName',emailAlertName);
        Flow.Interview emailAlertFlow;
        switch on sObjectType {
            when 'Case' {
                //create instance of Interview based on sobjecttype
                emailAlertFlow = new Flow.Interview.Workflow_Email_Alert_Evaluator_Case(Params);
            }
        }
        //Invoke start method
        if(!isTestContext && emailAlertFlow != null){
            emailAlertFlow.start();
        }
    }
}