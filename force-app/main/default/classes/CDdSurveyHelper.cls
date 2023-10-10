/**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description This is a helper class for sending surveys. 
     * 
     */ 

public with sharing class CDdSurveyHelper {
    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Asynchronous method to Send Surveys. 
     *              This method is invoked by Platform Events. 
     *              This method creates Delighted Tasks. Delighted Tasks have a trigger that makes an api callout to 
     *              to send CSAT surveys. 
     */ 
    public static final Map<String, RecordTypeInfo> CASE_RT_INFO = Schema.SObjectType.Case.getRecordTypeInfosByName();

    public static void createDelightedTaskRecords(List<Qualtrics_Send_Survery_Event__e> surveyEvents) {
        Set<Id> caseIdSet = new Set<Id>(); 
        for(Qualtrics_Send_Survery_Event__e gPE : surveyEvents) {
            caseIdSet.add(gPE.sObjectId__c); 
        }
        
        processCasesForDelightedTaskCreation(caseIdSet);
    }

    public static void processCasesForDelightedTaskCreation(Set<ID> caseIdSet){
        List<Delighted_Tasks__c> delightedTasksToInsert = new List<Delighted_Tasks__c>(); 
        List<String> errorMessages = new List<String>();
        List<Case> casesToSendSurvey = [SELECT Id, RecordTypeId, Origin, ContactId, ParentId, 
                                                SuppliedEmail, ContactEmail, ChatKey__c, Customer_Type__c
                                            FROM Case
                                            WHERE Id in : caseIdSet FOR UPDATE];
        for(Case currCase : casesToSendSurvey) {
            if(currCase.RecordtypeId == CASE_RT_INFO.get('Menu Update').getRecordTypeId()) {
                delightedTasksToInsert.add(createDelightedTask(currCase.id, 'Menu Update')); 
            } else {
                if (isPhoneChatCase(currCase)) {
                    delightedTasksToInsert.add(createDelightedTask(currCase.id, 'Phone/Chat')); 
                }
                else if (isWebEmailCase(currCase)) {
                    delightedTasksToInsert.add(createDelightedTask(currCase.id, 'Web/Email')); 
                }
                else if (isWebWithNoContactEmailCase(currCase)) {
                    delightedTasksToInsert.add(createDelightedTask(currCase.id, 'Web with No Contact Email')); 
                }
            }
        }
        try {
            if(delightedTasksToInsert.size() > 0 ) {
                List<Database.SaveResult> sResults = Database.insert(delightedTasksToInsert, false); 
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
            }
        } catch (Exception e) {
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdCaseTriggerHelper', 
                    'createDelightedTaskRecords',LoggingLevel.ERROR);
            throw e; 
        }
        if(!errorMessages.isEmpty()) {
            System.debug('ERRORS = ' + errorMessages ); 
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdCaseTriggerHelper', 
                    'createDelightedTaskRecords',LoggingLevel.ERROR);
        }
    }
    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Checks if the case is a Phone/Chat Case
     */ 

    public static boolean isPhoneChatCase (Case currCase) {
        if(currCase.ParentId == null
            && (currCase.Origin == 'Chat' 
                || currCase.Origin == 'Phone'
                || currCase.Origin == 'Cx Detractors'
                || currCase.Origin == 'Email - National')
            && currCase.ContactId != null 
            && !String.isBlank(currCase.ContactEmail)) {
            return true;
        }
            
        return false; 
    }

    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Checks if the case is a Web with No Contact Email Case
     */ 
    public static boolean isWebWithNoContactEmailCase (Case currCase) {
        if ((currCase.Origin == 'Web' 
            || currCase.Origin == 'Email')
        && String.isBlank(currCase.ContactEmail)
        && !String.isBlank(currCase.SuppliedEmail)
        ) {
            return true; 
        }
        return false; 
    }

    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Checks if the case is a Web/Email Case
     */ 
    public static boolean isWebEmailCase (Case currCase) {
        if((currCase.Origin == 'Email'
            || currCase.Origin == 'Facebook' 
            || currCase.Origin == 'Twitter' 
            || currCase.Origin == 'Web'
            || currCase.Origin == 'Instagram' 
            || currCase.Origin == 'Email - DDfB')
        && !String.isBlank(currCase.ContactEmail)
        ) {
            return true; 
        }
        return false; 
    }

    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Determine to send or not send a survey Using random number generator 
     *              
     */ 

    public static boolean toSendOrNotToSend(Integer sendPercentage) {
        Integer randomNumber = Math.abs(Crypto.getRandomInteger()); 
        if(sendPercentage == 0) {
            return false; 
        }
        Integer sendDivisor = Integer.valueOf(100/sendPercentage);
        Integer remainder = Math.Mod(randomNumber,sendDivisor);
        if(remainder == 0 || Test.isRunningTest()){
            return true;
        }
        return false; 
    }


    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Create delighted Task record. Does not insert. 
     */ 
    private static Delighted_Tasks__c createDelightedTask(Id caseId, String surveyType) {
        Delighted_Tasks__c delightedTask = new Delighted_Tasks__c(); 
        delightedTask.Case__c = caseId; 
        delightedTask.Sent__c = false;
        delightedTask.Survey__c = surveyType; 
        delightedTask.Survey_Provider__c = getSurveyProvider(surveyType);
        return delightedTask; 
    }

    /**
     * @author      Jeegar
     * @date        Feb 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1609
     * @description Decide Survey Provider
     */

     private static String getSurveyProvider(String surveyType) {
        
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();
        boolean isQualtricsEnabled = featureFlag.Enable_Qualtrics_Surveys__c;
        if(surveyType.equalsIgnoreCase(CDdSupportConstants.SURVEY_TYPE_MENU_UPDATE) || !isQualtricsEnabled) {
            return CDdSupportConstants.SURVEY_PROVIDER_DELIGHTED;
        } else {
            return CDdSupportConstants.SURVEY_PROVIDER_QUALTRICS;
        }

     }


}