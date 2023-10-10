/*
*@Description: Class to send Custom SSMO Link which is populated by Mulesoft to Decision Maker
@Author : Venkat D
@Date : 2022-06
*/
public class CDdSSMOLinkController {

    public static final String DECISION_MAKER_REQUIRED = 'Decision Maker should be populated on Opportunity';
    public static final String DECISION_MAKER_EMAIL_REQUIRED = 'Decision Maker Email should be populated';
    public static final String SSMO_LINK_REQUIRED = 'Missing SSMO Link';
    public static final String SSMO_LINK_TEMPLATE_ENGLISH = 'SSMO_Link_Email_Template';
    public static final String SSMO_LINK_OWNER_TEMPLATE_ENGLISH = 'SSMO_Link_Owner_Email_Template';

    @AuraEnabled
    public static ResultMessageWrapper sendSSMOLink(Id opportunityId){
        ResultMessageWrapper resultMessage = new ResultMessageWrapper('success',new List<String>());
        List<String> templateNames = new List<String>{SSMO_LINK_TEMPLATE_ENGLISH,SSMO_LINK_OWNER_TEMPLATE_ENGLISH};
        Map<String,EmailTemplate> emailTemplateMap = new Map<String,EmailTemplate>();
        Map<String,String> dmEmailTemplateMap = new Map<String,String>();
        Map<String,String> ownerEmailTemplateMap = new Map<String,String>();

        try{
            Opportunity oppRecord = [SELECT Id,Decision_Maker__c, Decision_Maker__r.Email,Owner.Email,Custom_SSMO_Link__c,PactSafe_Contract_Type__c,Docusign_Sent__c FROM Opportunity WHERE Id=:opportunityId];

            for (SSMO_Email_Setting__mdt emailSetting : [SELECT Id, MasterLabel, DeveloperName,PactSafe_Contract_Type__c,Email_Template_Name__c,Email_Receipient__c
                                                            FROM SSMO_Email_Setting__mdt WHERE PactSafe_Contract_Type__c = :oppRecord.PactSafe_Contract_Type__c]){
                templateNames.add(emailSetting.Email_Template_Name__c);
                if(emailSetting.Email_Receipient__c == 'Decision Maker'){
                    dmEmailTemplateMap.put(emailSetting.PactSafe_Contract_Type__c,emailSetting.Email_Template_Name__c);
                }else if(emailSetting.Email_Receipient__c == 'Owner'){
                    ownerEmailTemplateMap.put(emailSetting.PactSafe_Contract_Type__c,emailSetting.Email_Template_Name__c);
                }
            }

            List<EmailTemplate> ssmoLinkTemplates = [SELECT Id,Subject,Body,DeveloperName FROM EmailTemplate WHERE DeveloperName  IN :templateNames];
            for(EmailTemplate template:ssmoLinkTemplates){
                emailTemplateMap.put(template.DeveloperName,template);
            }

            if(String.isBlank(oppRecord.Decision_Maker__c)){
               resultMessage.messages.add(DECISION_MAKER_REQUIRED);
            }

            if(String.isBlank(oppRecord.Decision_Maker__r.Email)){
                resultMessage.messages.add(DECISION_MAKER_EMAIL_REQUIRED);
            }
            if(String.isBlank(oppRecord.Custom_SSMO_Link__c)){
                resultMessage.messages.add(SSMO_LINK_REQUIRED);
            }

            if(resultMessage.messages.isEmpty()){
                String dmEmailTemplateName = dmEmailTemplateMap.containsKey(oppRecord.PactSafe_Contract_Type__c)?dmEmailTemplateMap.get(oppRecord.PactSafe_Contract_Type__c):SSMO_LINK_TEMPLATE_ENGLISH;
            	String ownerEmailTemplateName = ownerEmailTemplateMap.containsKey(oppRecord.PactSafe_Contract_Type__c)?ownerEmailTemplateMap.get(oppRecord.PactSafe_Contract_Type__c):SSMO_LINK_OWNER_TEMPLATE_ENGLISH;
                Messaging.SingleEmailMessage emailMessage = prepareEmailMessage(oppRecord,oppRecord.Decision_Maker__r.Email,emailTemplateMap.get(dmEmailTemplateName));
                Messaging.SingleEmailMessage emailMessageOwner = prepareEmailMessage(oppRecord,oppRecord.Owner.Email,emailTemplateMap.get(ownerEmailTemplateName));

            	Messaging.SendEmailResult[] emailResults = null;
                if(!Test.isRunningTest()){
                	emailResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{emailMessage,emailMessageOwner},false);
                }

                if(emailResults != null && emailResults.size() > 0 && !emailResults[0].isSuccess()){
                	resultMessage.status = 'failed';
                    for(Messaging.SendEmailError emilError: emailResults[0].getErrors()){
                        resultMessage.messages.add(emilError.getMessage());
                    }
                }else{
                    Opportunity opptyRecToUpdate = new Opportunity(Id = oppRecord.Id, Docusign_Sent__c = System.today());
                    List<Database.SaveResult> resList = Database.update(new List<Opportunity>{opptyRecToUpdate},false);
                    List<String> errorMsgList = new List<String>();
                    errorMsgList = CDdErrorUtilities.processSaveResults(resList, errorMsgList);

                    if (errorMsgList.size() > 0){
                        CDdErrorUtilities.createApexLogs(errorMsgList, 'CDdSSMOLinkController','sendSSMOLink', LoggingLevel.ERROR);
                    }
                }
           	}else{
                resultMessage.status = 'failed';
            }
       	}catch(Exception ex){
            insert new Apex_Log__c(Class_Name__c = 'CDdSSMOLinkController', Method_Name__c = 'sendSSMOLink',Log__c = ex.getStackTraceString(), Log_Level__c = 'Error');
            resultMessage = new ResultMessageWrapper('failed',new List<String>{ex.getMessage()});
        }

        return resultMessage;
    }

    private static Messaging.SingleEmailMessage prepareEmailMessage(Opportunity oppRecord,String emailId,EmailTemplate ssmoLinkTemplate){
        List<String> toAddress = new List<string>();
        toAddress.add(emailId);
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setTemplateId(ssmoLinkTemplate.Id);
        emailMessage.setToAddresses(toAddress);
        emailMessage.setTargetObjectId(oppRecord.Decision_Maker__c);
        emailMessage.setTreatTargetObjectAsRecipient(false);
        emailMessage.setWhatId(oppRecord.Id);
        emailMessage.setSaveAsActivity(false);
        emailMessage.setUseSignature(false);
        return emailMessage;
    }

    public class ResultMessageWrapper{
        @AuraEnabled public List<String> messages;
        @AuraEnabled public String status;

        public ResultMessageWrapper(String status,List<String> messages){
            this.status = status;
            this.messages = messages;
        }
    }
}