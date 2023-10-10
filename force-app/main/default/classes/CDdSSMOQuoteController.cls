/*
*@Description: Class to prepare validate SSMO Quote required fields before invoking API
@Author : Venkat D
@Date : 2022-06
*/
public class CDdSSMOQuoteController {

    public static final Boolean disableSSMOValidation = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_SSMO_Quote_Validation__c');
    public static final String quoteRecallEmailTemplate = 'SSMO_Quote_Recall_Email_Template';

    @AuraEnabled
    public static ResultMessageWrapper validateQuoteAndSendToSSMO(Id quoteId){
        SBQQ__Quote__c quoteRecord = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Custom_SSMO_Link__c,SBQQ__Opportunity2__r.of_Addressable_Locations__c, SBQQ__Opportunity2__r.Account.BillingCountry,SBQQ__Opportunity2__r.POS_System__c,SBQQ__Primary__c,SBQQ__Opportunity2__r.Order_Protocol__c,
                                        SBQQ__Opportunity2__r.DRN__c,SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c,Experience__c,
                                        (SELECT Id from PactSafe_Requests__r WHERE pactsafe1__Expired__c = FALSE LIMIT 1),
                                        (SELECT Id,SBQQ__Product__r.SSMO_Eligible__c FROM SBQQ__LineItems__r)
                                        FROM SBQQ__Quote__c WHERE Id = :quoteId];


        ResultMessageWrapper resultMessage = new ResultMessageWrapper();
        try{

            if(!disableSSMOValidation){ //bypass validation check
                List<String> validationMessages = validateQuoteData(quoteRecord);
                if(!validationMessages.isEmpty()){
                    resultMessage.status = 'failed';
                    resultMessage.messages = validationMessages;
                    return resultMessage;
                }
            }

            Map<String, Object> responseMessage = CDdSSMOQuoteHelper.sendQuote(quoteId,quoteRecord.SBQQ__Opportunity2__c);
            if(responseMessage.get('status') == 'success'){
                resultMessage.status = (String)responseMessage.get('status');
                resultMessage.messages = new List<String>{CDdSSMOQuoteConstants.QUOTE_SENT_TO_SSMO};
            }else{
                resultMessage.status = (String)responseMessage.get('status');
                resultMessage.messages = new List<String>{(String)responseMessage.get('message')};
            }

        }catch(Exception ex){
            insert new Apex_Log__c(Class_Name__c = 'CDdSSMOQuoteController', Method_Name__c = 'validateQuoteAndSendToSSMO',Log__c = ex.getStackTraceString(), Log_Level__c = 'Error');
            resultMessage.status = 'failed';
            resultMessage.messages = new List<String>{ex.getMessage()};
        }

        return resultMessage;
    }

    public static List<String> validateQuoteData(SBQQ__Quote__c quoteRecord) {

        List<String> validationMessages = new List<String>();
        List<SBQQ__Quote__c> otherSSMOQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE PactSafe_Contract_Type__c IN :CDdSSMOQuoteConstants.REP_ENABLED_SSMO_LIST AND SBQQ__Opportunity2__c = :quoteRecord.SBQQ__Opportunity2__c AND Id != :quoteRecord.Id];

        //check Quote status
        if(quoteRecord.SBQQ__Status__c != 'Approved'){
            validationMessages.add(CDdSSMOQuoteConstants.QUOTE_NOT_APPROVED);
        }

        //check SSMO Eligible flag on quote lineitems
        if(!quoteRecord.SBQQ__LineItems__r.isEmpty()){
            Boolean allEligible = true;
            for(SBQQ__QuoteLine__c quoteLine : quoteRecord.SBQQ__LineItems__r){
                if(!quoteLine.SBQQ__Product__r.SSMO_Eligible__c){
                    allEligible = false;
                    break;
                }
            }
            if(!allEligible){
                validationMessages.add(CDdSSMOQuoteConstants.PRODUCT_SSMO_ELIGIBLE);
            }
        }

        //check PactSafe Contract Type field on other quotes of the Opportunity
        if(String.isNotBlank(quoteRecord.SBQQ__Opportunity2__c) && String.isNotBlank(quoteRecord.SBQQ__Opportunity2__r.Custom_SSMO_Link__c)){
            if(!otherSSMOQuotes.isEmpty() || (String.isNotBlank(quoteRecord.PactSafe_Contract_Type__c) && CDdSSMOQuoteConstants.REP_ENABLED_SSMO_LIST.contains(quoteRecord.PactSafe_Contract_Type__c))){
                validationMessages.add(CDdSSMOQuoteConstants.QUOTE_ALREADY_SENT_TO_SSMO);
            }
        }else{
            if(!otherSSMOQuotes.isEmpty()){
                validationMessages.add(CDdSSMOQuoteConstants.PACTSAFE_CONTR_OTHER_QUOTE);
            }else if(String.isBlank(quoteRecord.PactSafe_Contract_Type__c) ||  !CDdSSMOQuoteConstants.REP_ENABLED_SSMO_LIST.contains(quoteRecord.PactSafe_Contract_Type__c)){
                validationMessages.add(CDdSSMOQuoteConstants.PACTSAFE_CONTR_QUOTE);
            }
        }

        //check if Quote has PactSafe Request records
        if(!quoteRecord.PactSafe_Requests__r.isEmpty()){
            validationMessages.add(CDdSSMOQuoteConstants.QUOTE_RELATED_PACTSAFE_RECORD);
        }

        //check SSMO field requirements
        String requiredFieldsMsg = verifyRequiredFields(quoteRecord.Id,quoteRecord.SBQQ__Opportunity2__c);
        if(requiredFieldsMsg != null){
            validationMessages.add(requiredFieldsMsg);
        }

        //check country
        String billingCountry = quoteRecord.SBQQ__Opportunity2__r.Account.BillingCountry;
        if(!CDdSSMOQuoteConstants.BILLING_COUNTRIES.contains(billingCountry)){
            validationMessages.add(CDdSSMOQuoteConstants.BILLING_COUNTRY);
        }

        //check POS System
        if(String.isNotBlank(quoteRecord.SBQQ__Opportunity2__r.POS_System__c) && !CDdSSMOQuoteConstants.POS_SYSTEMS.contains(quoteRecord.SBQQ__Opportunity2__r.POS_System__c)){
            validationMessages.add(CDdSSMOQuoteConstants.POS_SYSTEM);
        }

        //check SBQQ__Primary__c
        if(quoteRecord.SBQQ__Primary__c == false){
            validationMessages.add(CDdSSMOQuoteConstants.PRIMARY_QUOTE);
        }

        //check Order_Protocol__c
        if(String.isBlank(quoteRecord.SBQQ__Opportunity2__r.Order_Protocol__c) || !CDdSSMOQuoteConstants.ORDER_PROTOCOLS.contains(quoteRecord.SBQQ__Opportunity2__r.Order_Protocol__c)){
            validationMessages.add(CDdSSMOQuoteConstants.ORDER_PROTOCOL_MSG);
        }

        //check DRN__c
        if( ((String.isNotBlank(quoteRecord.Experience__c) && quoteRecord.Experience__c.contains('Caviar')) || quoteRecord.SBQQ__Opportunity2__r.DRN__c == 'Ace' || quoteRecord.SBQQ__Opportunity2__r.DRN__c == 'King')
                && quoteRecord.SBQQ__Opportunity2__r.Proposed_Date_of_Activation__c == null){
            validationMessages.add(CDdSSMOQuoteConstants.DECK_RANK_MSG);
        }

        //check Experience__c
        if(quoteRecord.Experience__c == 'Caviar'){
            validationMessages.add(CDdSSMOQuoteConstants.EXPERIENCE_CAVIAR_MSG);
        }
        return validationMessages;
    }

    private static String verifyRequiredFields(Id quoteId, Id opportunityId){
        String errorMessage = null;
        List<SSMO_Quote_Field_Mapping__mdt> ssmoQuoteAPIFields = CDdSSMOQuoteHelper.fetchSSMOQuoteAPIFields();

        Account acctRecord = null;
        Contact decisionMakerRecord = null;
        User ownerRecord = null;

        String opptyQuery = CDdSSMOQuoteHelper.prepareQuery(opportunityId,ssmoQuoteAPIFields,CDdSSMOQuoteHelper.OPPORTUNITY_OBJECT);
        sObject[] sobjectList = Database.query(opptyQuery);
        Opportunity oppRecord = sobjectList.size() > 0 ? (Opportunity)sobjectList[0]:null;

        if(oppRecord != null){
            String accountQuery = CDdSSMOQuoteHelper.prepareQuery(oppRecord.AccountId,ssmoQuoteAPIFields,CDdSSMOQuoteHelper.ACCOUNT_OBJECT);
            sobjectList = Database.query(accountQuery);
            acctRecord = sobjectList.size() > 0 ? (Account)sobjectList[0]:null;

            String contactQuery = CDdSSMOQuoteHelper.prepareQuery(oppRecord.Decision_Maker__c,ssmoQuoteAPIFields,CDdSSMOQuoteHelper.CONTACT_OBJECT);
            sobjectList = Database.query(contactQuery);
            decisionMakerRecord = sobjectList.size() > 0 ? (Contact)sobjectList[0]:null;

            String userQuery = CDdSSMOQuoteHelper.prepareQuery(oppRecord.OwnerId,ssmoQuoteAPIFields,CDdSSMOQuoteHelper.USER_OBJECT);
            sobjectList = Database.query(userQuery);
            ownerRecord = sobjectList.size() > 0 ? (User)sobjectList[0]:null;
        }

        String quoteQuery = CDdSSMOQuoteHelper.prepareQuery(quoteId,ssmoQuoteAPIFields,CDdSSMOQuoteHelper.QUOTE_OBJECT);
        sobjectList = Database.query(quoteQuery);
        SBQQ__Quote__c quoteRecord = sobjectList.size() > 0 ? (SBQQ__Quote__c)sobjectList[0]:null;

        List<String> requiredFields = new List<String>();

        for(SSMO_Quote_Field_Mapping__mdt fieldMapping:ssmoQuoteAPIFields){
            if(fieldMapping.Is_Required__c){
                Object fieldValue = null;
                if(fieldMapping.Object_Name__c == CDdSSMOQuoteHelper.OPPORTUNITY_OBJECT && oppRecord != null){
                    fieldValue = oppRecord.get(fieldMapping.Field_Name__c);
                }else if(fieldMapping.Object_Name__c == CDdSSMOQuoteHelper.ACCOUNT_OBJECT && acctRecord != null){
                    fieldValue = acctRecord.get(fieldMapping.Field_Name__c);
                }else if(fieldMapping.Object_Name__c == CDdSSMOQuoteHelper.CONTACT_OBJECT && decisionMakerRecord != null){
                    fieldValue = decisionMakerRecord.get(fieldMapping.Field_Name__c);
                }else if(fieldMapping.Object_Name__c == CDdSSMOQuoteHelper.USER_OBJECT && ownerRecord != null){
                    fieldValue = ownerRecord.get(fieldMapping.Field_Name__c);
                }else if(fieldMapping.Object_Name__c == CDdSSMOQuoteHelper.QUOTE_OBJECT && quoteRecord != null){
                    fieldValue = quoteRecord.get(fieldMapping.Field_Name__c);
                }
                if(fieldValue == null){
                    requiredFields.add(fieldMapping.MasterLabel);
                }
            }
        }

        if(requiredFields.size() > 0){
            errorMessage = 'Value not available for the required fields. ';
            errorMessage += String.join(requiredFields, ', ');
        }

        return errorMessage;
    }

    @AuraEnabled
    public static ResultMessageWrapper recallQuote(Id quoteId){
		SBQQ__Quote__c quoteRecord = [SELECT Id,SBQQ__Status__c, PactSafe_Contract_Type__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SSMO_UUID__c,SBQQ__Opportunity2__r.Decision_Maker__r.Email,SBQQ__Opportunity2__r.Owner.Email,SBQQ__Opportunity2__r.Decision_Maker__c
                                        FROM SBQQ__Quote__c WHERE Id = :quoteId];

        ResultMessageWrapper resultMessage = new ResultMessageWrapper();
        try{

            Map<String, Object> responseMessage = CDdSSMOQuoteHelper.recallQuote(quoteId,quoteRecord.SBQQ__Opportunity2__c,quoteRecord.SBQQ__Opportunity2__r.SSMO_UUID__c,quoteRecord.SBQQ__Opportunity2__r.Decision_Maker__c);
            if(responseMessage.get('status') == 'success'){
                resultMessage.status = (String)responseMessage.get('status');
                sendRecallEmail(quoteRecord);
            }else{
                resultMessage.status = (String)responseMessage.get('status');
                resultMessage.messages = new List<String>{(String)responseMessage.get('message')};
            }

        }catch(Exception ex){
            insert new Apex_Log__c(Class_Name__c = 'CDdSSMOQuoteController', Method_Name__c = 'recallQuote',Log__c = ex.getStackTraceString(), Log_Level__c = 'Error');
            resultMessage.status = 'failed';
            resultMessage.messages = new List<String>{ex.getMessage()};
        }

        return resultMessage;
    }

    private static void sendRecallEmail(SBQQ__Quote__c quoteRecord){
        EmailTemplate quoteRecallTemplate = [SELECT Id,Subject,Body,DeveloperName FROM EmailTemplate WHERE DeveloperName  = :quoteRecallEmailTemplate LIMIT 1];

        List<String> toAddress = new List<String>{quoteRecord.SBQQ__Opportunity2__r.Decision_Maker__r.Email,quoteRecord.SBQQ__Opportunity2__r.Owner.Email};
        Messaging.SingleEmailMessage recallEmailMessage = new Messaging.SingleEmailMessage();
        recallEmailMessage.setTemplateId(quoteRecallTemplate.Id);
        recallEmailMessage.setToAddresses(toAddress);
        recallEmailMessage.setTargetObjectId(quoteRecord.SBQQ__Opportunity2__r.Decision_Maker__c);
        recallEmailMessage.setTreatTargetObjectAsRecipient(false);
        recallEmailMessage.setWhatId(quoteRecord.SBQQ__Opportunity2__c);
        recallEmailMessage.setSaveAsActivity(false);
        recallEmailMessage.setUseSignature(false);

        Messaging.SendEmailResult[] emailResults = null;
        if(!Test.isRunningTest()){
            emailResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{recallEmailMessage},false);
        }

        if(emailResults != null && emailResults.size() > 0 && !emailResults[0].isSuccess()){
            List<String> errorMsgList = new List<String>();
            for(Messaging.SendEmailError emilError: emailResults[0].getErrors()){
                errorMsgList.add(emilError.getMessage());
            }
            if (errorMsgList.size() > 0){
                CDdErrorUtilities.createApexLogs(errorMsgList, 'CDdSSMOQuoteController','sendRecallEmail', LoggingLevel.ERROR);
            }
        }
    }

    public class ResultMessageWrapper{
        @AuraEnabled public List<String> messages;
        @AuraEnabled public String status;
    }
}