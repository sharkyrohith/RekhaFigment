/********************************************************************************************************************
* @author Lathika
* @date 08/25/2022
*
* @group Merchant Services
*
* @description helper class for MxOnboarding Opportunity Updates from MxPortal
* 
* Date : 06/07/2023
* BZAP-20210 - Update helper class for Mx SSMO Fraud functionality. 
* Milestone in focus for fraud functionality is 'Review & Triage'
*
**************************************************************************************************************************************/
public class CDdMxOnBoardingMilestoneHelper extends CDdMxOnboardingHelper {

    /** Id - Mx Onboarding Id
     *  this is a map container where the Milestone corresponds to a specific Mx Onboarding Record
     */
    public Map<Id, Milestone__c> milestoneyByMxOnboardingId;
    /** Id - Mx Onboarding Id
     *  this is a map container where the Oportunity corresponds to a specific Mx Onboarding Record
     */
    private Map<Id, Opportunity> opportunityByMxOnboardingId;
    private Map<String, Mx_Onboarding__c> mxOnboardingByStoreID;
    /**
     * @description BZAP-20210 - Introduce variables for mx ssmo fraud functionality
     */
    private Map<Id, Milestone__c> reviewTriageMilestoneByMxOnboardingId;
    private static final String STATUS = 'status';
    private static final String STATUS_REASON = 'statusReason';
    public static final String BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_REQUIRED = 'Documentation Required';
    public static final String BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_DENIED = 'Denied';
    public static final String BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_APPROVED = 'Approved';

    private static final Map<String, Map<String, String>> BUSINESS_VERIFICATION_STATUS_TO_MILESTONE_STATUS_MAP =
        new Map<String, Map<String, String>>{
            BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_REQUIRED => new Map<String, String>{
                STATUS => 'Blocked',
                STATUS_REASON => 'Fraud'
            },
            BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_DENIED => new Map<String, String>{
                STATUS => 'Dead',
                STATUS_REASON => 'Fraud'
            },
            BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_APPROVED => new Map<String, String>{
                STATUS => 'Complete',
                STATUS_REASON => NULL
            }                        
        };

    // Constructor for trigger context
    public CDdMxOnBoardingMilestoneHelper(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap) {
        setMilestoneByMxOnboardingIdyMap(newList);
    }
    // Constructor for Retry logic for failed records
    public CDdMxOnBoardingMilestoneHelper(List<Mx_Onboarding__c> mxOnboardingRecords) {
        setMilestoneByMxOnboardingIdyMap(mxOnboardingRecords);
    }
    /**
     * @description setting the class variables
     * @param List<Mx_Onboarding__c> mxOnboardingRecords
     * @return
     */ 
    private void setMilestoneByMxOnboardingIdyMap(List<Mx_Onboarding__c> mxOnboardingRecords){
        Set<String> storeIDs = new Set<String>();
        Set<Id> oppIDs = new Set<Id>();
        Set<Id> caseIDs = new Set<Id>();
        milestoneyByMxOnboardingId =  new  Map<Id, Milestone__c>();
        this.opportunityByMxOnboardingId = new  Map<Id, Opportunity>();
        this.mxOnboardingByStoreID = new Map<String, Mx_Onboarding__c>();
        this.reviewTriageMilestoneByMxOnboardingId  =  new  Map<Id, Milestone__c>();
        
        for (Mx_Onboarding__c newSobject : mxOnboardingRecords){
            if (String.isNotBlank(newSobject.UpdateType__c) && newSobject.UpdateType__c == CDdMxSxConstants.MX_ONBOARDING_MX_PORTAL_UPDATE_TYPE_INBOUND) {
                storeIDs.add(newSobject.StoreId__c);
                this.mxOnboardingByStoreID.put(newSobject.StoreId__c,newSobject);
            }
        }
        if (storeIDs.isEmpty()) {
            return; 
        }
        for (Account a : [Select id, (Select Id, Account.Restaurant_ID__c, Opportunity_Name__c from Cases where RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING order by lastmodifieddate desc Limit 1)
                            from Account where RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS AND Restaurant_ID__c  IN :storeIDs ]) {
            if (!a.Cases.isEmpty() && String.isNotBlank(a.Cases[0].Opportunity_Name__c)) {
                oppIDs.add(a.Cases[0].Opportunity_Name__c);
                caseIDs.add(a.Cases[0].Id); 
            }
        }
        for (opportunity opp : [SELECT id, Menu_URL__c, Proposed_Date_of_Activation__c, Account.Restaurant_ID__c from opportunity where id IN :oppIDs]) {
            if (mxOnboardingByStoreID.containsKey(opp.Account.Restaurant_ID__c)) {
                this.opportunityByMxOnboardingId.put(mxOnboardingByStoreID.get(opp.Account.Restaurant_ID__c).ID, opp);         
            }
        }
       for (Milestone__c m : [Select id, Case__c, Milestone_Type__c, Case__r.Opportunity_Name__c, Case__r.Account.Restaurant_ID__c, Status__c 
                              from Milestone__c where Case__c IN : caseIDs
                              and RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_MENU and Status__c = : CDdMxSxConstants.MILESTONE_STATUS_BLOCKED]) {
            if (mxOnboardingByStoreID.containsKey(m.Case__r.Account.Restaurant_ID__c)) {
                this.milestoneyByMxOnboardingId.put(mxOnboardingByStoreID.get(m.Case__r.Account.Restaurant_ID__c).ID, m);         
            }
        }
        for (Milestone__c m : [ SELECT Id, Case__c, Case__r.Opportunity_Name__c, Case__r.Account.Restaurant_ID__c, 
                                Status__c, Status_Reason__c, Milestone_Type__c 
                                FROM Milestone__c 
                                WHERE Case__c IN : caseIDs
                                AND RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE ]) {
            if (mxOnboardingByStoreID.containsKey(m.Case__r.Account.Restaurant_ID__c)) {
                this.reviewTriageMilestoneByMxOnboardingId.put(mxOnboardingByStoreID.get(m.Case__r.Account.Restaurant_ID__c).ID, m);         
            }
        }        
    }    
      /**
     * @description Handle the update of Milestones
     * When Menu_MenuUrl__c is updated by Mulesoft Integration User on Mx Onboading record if the SetUpMenu Milestone Status is "Blocked"
     *  update the Status to "IN Progress"
     * @param List<Mx_Onboarding__c> newList
     * @param Map<Id, Mx_Onboarding__c> oldMap
     * @return Map <Id, Milestone__c>
     */  
    public override Map <Id, SObject> getsObjectsToUpdate(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap){
        Map <ID, SObject> milestoneToUpdate = new Map <ID, SObject>();
        for (Mx_Onboarding__c newSobject : newList) {
            Milestone__c setupMenuMilestone = this.milestoneyByMxOnboardingId.get(newSobject.ID);
            Opportunity opp = this.opportunityByMxOnboardingId.get(newSobject.Id);
            Mx_Onboarding__c oldSobject = oldMap.get(newSobject.Id);
            if(setupMenuMilestone != null){
                if (CDdMxSxTriggerHelper.hasFieldValueChanged(newSobject, oldSobject, 'MenuMilestone_Updated_Reason__c')){
                    if (CDdMxSxConstants.MILESTONE_STATUS_BLOCKED.equals(milestoneyByMxOnboardingId.get(newSobject.ID).Status__c)) {
                        setupMenuMilestone.Status__c = 'In Progress';
                        setupMenuMilestone.Status_Reason__c = '';
                        milestoneToUpdate.put(newSobject.id, setupMenuMilestone);
                    }   
                }
            }
        }
        milestoneToUpdate.putAll(getReviewAndTriageMilestonesToUpdate(newList));
        return milestoneToUpdate;
    }
    /**
     * @description Handle the update of Milestones, Retrieve the eligible sObject records for Updation from Batch /Platform Events implementation
     * When Menu_MenuUrl__c / Proposed Date of Activation is updated by Mulesoft Integration User 
     * update the Marketplace Opportunity fields (Menu_URL__c,Proposed_Date_of_Activation__c)
     * @param List<Mx_Onboarding__c> mxOnboardingRecords)
     * @return Map <Id, Milestone__c>
     */
    public override Map <Id, SObject> getsObjectsToUpdate(List<Mx_Onboarding__c> mxOnboardingRecords){
        Map <Id, SObject> milestoneToUpdate = new Map <ID, SObject>();
        for (Mx_Onboarding__c mxOnboarding : mxOnboardingRecords) {
            if (mxOnboarding.MenuMilestone_Updated_Reason__c != null){
                Milestone__c setupMenuMilestone = milestoneyByMxOnboardingId.get(mxOnboarding.ID);
                    if(setupMenuMilestone != null){
                        if (CDdMxSxConstants.MILESTONE_STATUS_BLOCKED.equals(milestoneyByMxOnboardingId.get(mxOnboarding.ID).Status__c)) {
                            setupMenuMilestone.Status__c = 'In Progress';
                            setupMenuMilestone.Status_Reason__c = '';
                            milestoneToUpdate.put(mxOnboarding.id, setupMenuMilestone);
                        }
                    }
            }
        }
        milestoneToUpdate.putAll(getReviewAndTriageMilestonesToUpdate(mxOnboardingRecords));
        return milestoneToUpdate;    
    }
    /**
     * @description BZAP-20210 - Adding Mx SSMO Fraud feature
     * Sync up the Review & Triage milestone with the inbound update to Business Verification Status on the corresponding Mx Onboarding record 
     * @param List<Mx_Onboarding__c> mxOnboardingRecords - List collection of Mx Onboarding records
     * @return Map <Id, SObject> A collection of Review & Triage milestone records with milestone record id as the key for the Map
     */
    private Map<Id, Milestone__c> getReviewAndTriageMilestonesToUpdate(List<Mx_Onboarding__c> mxOnboardingRecords){
        Map<Id, Milestone__c> rtMilestonesToUpdate = new Map<Id, Milestone__c>();
        for(Mx_Onboarding__c mxOnboardingRecord : mxOnboardingRecords){
            if (String.isNotBlank(mxOnboardingRecord.Business_Verification_Status__c)
                && this.reviewTriageMilestoneByMxOnboardingId.containsKey(mxOnboardingRecord.Id)){           
                Milestone__c rtMilestoneToUpdate = getReviewAndTriageMilestoneToUpdate(
                                        mxOnboardingRecord.Business_Verification_Status__c,
                                        this.reviewTriageMilestoneByMxOnboardingId.get(mxOnboardingRecord.Id)
                                    );
                if (rtMilestoneToUpdate != null){
                    rtMilestonesToUpdate.put(rtMilestoneToUpdate.Id, rtMilestoneToUpdate);
                }
            }
        }
        return rtMilestonesToUpdate;        
    }
    private Milestone__c getReviewAndTriageMilestoneToUpdate(String businessVerificationStatus, Milestone__c reviewAndTriageMilestone){
        if (BUSINESS_VERIFICATION_STATUS_TO_MILESTONE_STATUS_MAP.containsKey(businessVerificationStatus)){
            String expectedMilestoneStatus = BUSINESS_VERIFICATION_STATUS_TO_MILESTONE_STATUS_MAP.get(businessVerificationStatus).get(STATUS);
            String expectedMilestoneStatusReason = BUSINESS_VERIFICATION_STATUS_TO_MILESTONE_STATUS_MAP.get(businessVerificationStatus).get(STATUS_REASON);
            if (!expectedMilestoneStatus.equals(reviewAndTriageMilestone.Status__c)
                ||  ((expectedMilestoneStatusReason == NULL && reviewAndTriageMilestone.Status_Reason__c != NULL)
                    ||
                    (expectedMilestoneStatusReason != NULL && expectedMilestoneStatusReason != reviewAndTriageMilestone.Status_Reason__c)
                    )
            ){
                return new Milestone__c( 
                    Id = reviewAndTriageMilestone.Id, 
                    Status__c = expectedMilestoneStatus, 
                    Status_Reason__c = expectedMilestoneStatusReason,
                    Milestone_Type__c = reviewAndTriageMilestone.Milestone_Type__c,
                    Case__c = reviewAndTriageMilestone.Case__c 
                );
            }
        }
        return null;
    }
}