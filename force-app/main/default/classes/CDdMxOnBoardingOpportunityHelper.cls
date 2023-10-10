/********************************************************************************************************************
* @author Lathika
* @date 08/25/2022
*
* @group Merchant Services
*
* @description helper class for MxOnboarding Opportunity Updates from MxPortal
*
**************************************************************************************************************************************/
public class CDdMxOnBoardingOpportunityHelper extends CDdMxOnboardingHelper {
    /** Id - Mx Onboarding Id
     *  this is a map container where the Oportunity corresponds to a specific Mx Onboarding Record
     */
    public Map<Id, Opportunity> opportunityByMxOnboardingId;
    private Map<String, Mx_Onboarding__c> mxOnboardingByStoreID;
    // Constructor for trigger context
    public CDdMxOnBoardingOpportunityHelper(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap) {
        setOpportunityByMxOnboardingIdyMap(newList);
    }
    // Constructor for Retry logic for failed records
    public CDdMxOnBoardingOpportunityHelper(List<Mx_Onboarding__c> mxOnboardingRecords) {
        setOpportunityByMxOnboardingIdyMap(mxOnboardingRecords);
    }
    /**
     * @description setting the class variables
     * @param List<Mx_Onboarding__c> mxOnboardingRecords
     * @return
     */ 
    private void setOpportunityByMxOnboardingIdyMap(List<Mx_Onboarding__c> mxOnboardingRecords){
        Set<String> storeIDs = new Set<String>();
        Set<String> oppIDs = new Set<String>();
        opportunityByMxOnboardingId = new  Map<Id, Opportunity>();
        this.mxOnboardingByStoreID = new Map<String, Mx_Onboarding__c>();
        for (Mx_Onboarding__c newSobject : mxOnboardingRecords){
            if (String.isNotBlank(newSobject.UpdateType__c) && newSobject.UpdateType__c == CDdMxSxConstants.MX_ONBOARDING_MX_PORTAL_UPDATE_TYPE_INBOUND ) {
                storeIDs.add(newSobject.StoreId__c);
                mxOnboardingByStoreID.put(newSobject.StoreId__c,newSobject);               
            }
        }
        if (storeIDs.isEmpty()) {
            return; 
        }
        for (Account a : [Select id, (Select id, Account.Restaurant_ID__c, Opportunity_Name__c from Cases where RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING order by lastmodifieddate desc Limit 1)
                            from Account where RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS AND Restaurant_ID__c  IN :storeIDs ]) {
            if (!a.Cases.isEmpty() && String.isNotBlank(a.Cases[0].Opportunity_Name__c)) {
                oppIDs.add(a.Cases[0].Opportunity_Name__c);
            }                                                    
        }
        for (opportunity opp : [SELECT id, Menu_URL__c, Proposed_Date_of_Activation__c, Account.Restaurant_ID__c from opportunity where id IN :oppIDs]) {
            if (mxOnboardingByStoreID.containsKey(opp.Account.Restaurant_ID__c)) {
                this.opportunityByMxOnboardingId.put(mxOnboardingByStoreID.get(opp.Account.Restaurant_ID__c).ID, opp);         
            }
       }
    }    
      /**
     * @description Handle the update of Opportunities
     * When Menu_MenuUrl__c / Proposed Date of Activation is updated by Mulesoft Integration User 
     * update the Marketplace Opportunity fields (Menu_URL__c,Proposed_Date_of_Activation__c)
     * @param List<Mx_Onboarding__c> newList
     * @param Map<Id, Mx_Onboarding__c> oldMap
     * @param Set<Id> oppIDs
     * @return List<Opportunity>
     */  
    public override Map <Id, SObject> getsObjectsToUpdate(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap){
        Map <Id, SObject> opportunityList = new Map <Id, SObject>();
        for (Mx_Onboarding__c newSobject : newList) {
            if (this.opportunityByMxOnboardingId.containsKey(newSobject.Id) &&  this.opportunityByMxOnboardingId.get(newSobject.Id) != null ) {
                Opportunity opp = this.opportunityByMxOnboardingId.get(newSobject.Id);
                Mx_Onboarding__c oldSobject = oldMap.get(newSobject.Id);
                if (CDdMxSxTriggerHelper.hasFieldValueChanged(newSobject, oldSobject, 'Menu_MenuUrl__c') || CDdMxSxTriggerHelper.hasFieldValueChanged(newSobject, oldSobject, 'Proposed_Date_of_Activation__c')) {
                    if (CDdMxSxTriggerHelper.hasFieldValueChanged(newSobject, oldSobject, 'Menu_MenuUrl__c') && opp.Menu_URL__c != newSobject.Menu_MenuUrl__c){
                        opp.Menu_URL__c = newSobject.Menu_MenuUrl__c;             
                    }
                    if (CDdMxSxTriggerHelper.hasFieldValueChanged(newSobject, oldSobject, 'Proposed_Date_of_Activation__c') &&  opp.Proposed_Date_of_Activation__c != newSobject.Proposed_Date_of_Activation__c){
                        opp.Proposed_Date_of_Activation__c = newSobject.Proposed_Date_of_Activation__c;
                    }
                    opportunityList.put(newSobject.id, opp);
                }
            }
        }
        return opportunityList;
    }
    /**
     * @description Handle the update of Milestones Retrieve the eligible sObject records for Updation from Batch /Platform Events implementation
     * When Menu_MenuUrl__c / Proposed Date of Activation is updated by Mulesoft Integration User 
     * update the Marketplace Opportunity fields (Menu_URL__c,Proposed_Date_of_Activation__c)
     * @param List<Mx_Onboarding__c> newList
     * @param Map<Id, Mx_Onboarding__c> oldMap
     * @param Set<Id> oppIDs
     * @return List<SObject>
     */
    public override Map <Id, SObject> getsObjectsToUpdate(List<Mx_Onboarding__c> mxOnboardingRecords){
        Map <Id, SObject> opportunityList = new Map <Id, SObject>();
        for (Mx_Onboarding__c mxOnboarding : mxOnboardingRecords) {
            if ( this.opportunityByMxOnboardingId.containsKey(mxOnboarding.Id) &&  this.opportunityByMxOnboardingId.get(mxOnboarding.Id) != null ) {
                Opportunity opp = this.opportunityByMxOnboardingId.get(mxOnboarding.Id);
                if (opp.Menu_URL__c != mxOnboarding.Menu_MenuUrl__c){
                    opp.Menu_URL__c = mxOnboarding.Menu_MenuUrl__c;             
                }
                if (opp.Proposed_Date_of_Activation__c != mxOnboarding.Proposed_Date_of_Activation__c){
                    opp.Proposed_Date_of_Activation__c = mxOnboarding.Proposed_Date_of_Activation__c;
                }
                opportunityList.put(mxOnboarding.id, opp);
            }
        }  
        return opportunityList; 
    }
 }