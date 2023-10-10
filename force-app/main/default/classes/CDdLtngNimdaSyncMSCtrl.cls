/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/10/2020
*
* @group Nimda
*
* @description This is the Lightning Controller for Nimda Sync that is integrated with MuleSoft REST Services
* Purpose of this controller is to
* - Communicate with S2N V4 Lightning Components that are redesigned for MuleSoft integration.
* - Perform SOQL Query and DML operations on Account and Opportunity object related to Nimda Sync data points
* - Interact via the CDdNimdaSyncMSService with MuleSoft REST Services
* 
**************************************************************************************************************************************/
public class CDdLtngNimdaSyncMSCtrl {
    /**
    * @description Get store request for update purpose
    * @param String input Business Id   
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return the store request object <CDdRestJSONObj.DoorstepStoreRequest>
    **/
    @AuraEnabled
    public static Object getStoreRequest(String businessId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(CDdNimdaSyncStoreHelper.getStoreRequest(CDdNimdaSyncConstants.STEP_UPDATE_STORE, businessId, account, opportunity));
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get store request object: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getStoreRequest', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Return the data model template for the input onboarding step
    * @param String Input Onboarding Step Name
    * @return Return the Serialized result for Data Model template
    **/
    @AuraEnabled    
    public static Object getDataModelTemplate(String onboardingStepName) {
        try {
            return JSON.serialize(CDdNimdaSyncOnboardingConfigHelper.getDataModelTemplate(onboardingStepName));
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get data model template for ' + onboardingStepName + ' : '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Onboarding Step Name : ' + onboardingStepName + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'getDataModelTemplate', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }        
    /**
    * @description Get store detail for the input Store Id
    * @param String input Store Id    
    * @return Serialized store detail record from Nimda backend
    **/
    @AuraEnabled
    public static Object getStore(String storeId) {
        try {
            return new CDdNimdaSyncMSService().getStore(storeId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get store: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'getStore', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Get mxAffiliate Program Details for the input Store Id
    * @param String input Store Id    
    * @return Serialized store detail record from Nimda backend
    **/
    @AuraEnabled
    public static Object getmxAffiliateProgram(String storeId) {
        try {
            return new CDdNimdaSyncMSService().getMxAffiliaetProgramDetails(storeId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get MxAffiliate Program Details: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'getmxAffiliateProgram', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Get Nimda Store field definitions from custom metadata
    * @return Serialized store field definitions
    **/
    @AuraEnabled
    public static Object getNimdaStoreFieldDefinitions() {
        return JSON.serialize(CDdNimdaSyncStoreHelper.getNimdaStoreFieldDefinitions());
    }
    /**
    * @description Check if the Given Opp is a Trial Opportunity
    * @return Boolean
    **/
    @AuraEnabled
    public static Boolean getCheckforTrialOpportunity(Opportunity opportunity) {
        return new CDdNimdaSyncStoreProductHelper(new Set<Id>{opportunity.Id}).isTrialOpp();
    }
    /**
    * @description Update store for the input Store Id
    * @param String input Store Id
    * @param String input Opportunity Id        
    * @return Serialized store detail record from Nimda backend
    **/
    @AuraEnabled
    public static Object updateStore(String storeId, String opportunityId){
        try {
            return new CDdNimdaSyncMSService().updateStore(storeId, opportunityId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to update store: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'updateStore', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }        
    /**
    * @description Full Onboard the store and related activities
    * @param String input Opportunity Id
    * @param String originatingOnboardingStep Full Onboarding Originating Step
    * @return Serialized full onboard response from Nimda backend
    **/    
    @AuraEnabled
    public static Object fullOnboard(String opportunityId, String originatingOnboardingStep){
        try {
            return new CDdNimdaSyncMSService().fullOnboard(opportunityId, originatingOnboardingStep);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to full onboard: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunityId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'fullOnboard', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
    * @description Apply updates to Account and Opportunity record
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @param Contact decision maker
    * @return <Boolean> true or false
    **/
    @AuraEnabled
    public static Boolean updateAccountAndOpportunity(Account account, Opportunity opportunity, Contact decisionMaker) {
        try {
            // Update Account
            if (account!=null){
                update account;
            }
            // Update Opportunity
            if (opportunity!=null){
                update opportunity;
            }
            // Update Decision Maker
            if (decisionMaker!=null){
                if (String.isBlank(decisionMaker.Id)){
                    throw new CDdNimdaSyncService.CDdNimdaSyncServiceException(CDdNimdaSyncConstants.STEP_UPDATE_STORE, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, CDdNimdaSyncConstants.ERROR_MSG_DECISION_MAKER_NOT_FOUND);
                }
                update decisionMaker;
            }            
            // Return true for success
            return true;    
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to update Account and Opportunity: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'updateAccountAndOpportunity', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
    * @description Return the Nimda Sync status fields on the Opportunity object updated by MuleSoft upon completion of processing the input request
    * @param String input Opportunity Id     
    * @return <Opportunity> record
    **/    
    @AuraEnabled
    public static Opportunity getNimdaSyncStatus(String opportunityId){
        try {        
            Opportunity opportunity = null;
            for (Opportunity opp : [  SELECT Id, Nimda_Sync_Step__c, Nimda_Sync_Error_Type__c, Nimda_Sync_Error_Message__c, 
                                    Nimda_Sync_Callout_Request__c, Nimda_Sync_Callout_Response__c
                                    FROM Opportunity
                                    WHERE Id = :opportunityId ]){
                opportunity = opp;
            }
            return opportunity;
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get Nimda Sync Status: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunityId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'getNimdaSyncStatus', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }            
    }
    /**
    * @description Reset the Nimda Sync status fields on the Opportunity object prior to calling the MuleSoft API
    * @param String input Opportunity Id     
    * @return <Boolean> boolean true or false
    **/    
    @AuraEnabled
    public static Boolean updateNimdaSyncStatus(String step, String opportunityId){
        try {
            //Update the nimda sync fields on the Opportunity object object
            Opportunity opportunity = new Opportunity( Id = opportunityId, 
                                                        Nimda_Sync_Step__c = step,
                                                        Nimda_Sync_Error_Type__c = null,
                                                        Nimda_Sync_Error_Message__c = null,  
                                                        Nimda_Sync_Callout_Request__c = null,       
                                                        Nimda_Sync_Callout_Response__c = null 
                                                    );
            List<SObject> sObjects = new CDdNimdaEnforceStepHelper(opportunityId, step).prepareSObjectsForOnboarding(opportunity);                                                     
            update sObjects;
            return true;
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to update Nimda Sync Status: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunityId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncMSCtrl', 'updateNimdaSyncStatus', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
    * @description Get payment account info for the input Payment Account Id
    * @param String input Payment Account Id    
    * @return Serialized Payment Account info from Nimda backend
    **/
    @AuraEnabled
    public static Object getPaymentAccount(String paymentAccountId) {
        try {
            return new CDdNimdaSyncSearchStoreService().getPaymentAccount(paymentAccountId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get payment account: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Payment Account Id : ' + paymentAccountId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getPaymentAccount', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }                     
}