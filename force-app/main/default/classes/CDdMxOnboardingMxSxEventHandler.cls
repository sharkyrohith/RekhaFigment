/********************************************************************************************************************
* @author Lathika
* @date 08/10/2022
*
* @group Merchant Services
*
* @description Apex class that handles Mx Onboarding events
*
**************************************************************************************************************************************/
public class CDdMxOnboardingMxSxEventHandler {

    public CDdMxOnboardingMxSxEventHandler() {
     }
    public static Set<String> DECK_RANKS_TO_EXCLUDE = new Set<String>{
        CDdMxSxConstants.DECK_RANK_ACE_OF_SPADES,
        CDdMxSxConstants.DECK_RANK_KING_OF_SPADES
    };

    public static Map<String,List<Merchant_Onboarding_Properties__mdt>> MdtConfig;
    static {
        // Query the Mx Onboaring Config
        MdtConfig = new  Map<String,List<Merchant_Onboarding_Properties__mdt>>();
        for (Mx_Onboarding_Config__mdt mxOnboardingConfig :  [Select id, DeveloperName,
                                                              (Select Id, Source_SObject_API_Field__c, Target_SObject_API_Field__c, Source_Record_Types__c from Merchant_Onboarding_Properties__r)
                                                              from Mx_Onboarding_Config__mdt where Is_Active__c = TRUE]) {
            MdtConfig.put(mxOnboardingConfig.DeveloperName,(mxOnboardingConfig.Merchant_Onboarding_Properties__r));
        }
    }
    /**
     * @description Handle events - MARKETPLACE_ONBOARDING_CASE_INSERT_EVENT
     * @param Set<Id> caseIds
     * @return
    */
    public static void handleEventsForMarketplaceOnboardingCaseInsert(Set<Id> caseIds){
        // applyMilestoneUpdates: Set to False: Since not sure Milestones are created at the time of Marketplace Case Creation
        createOrUpdateMxOnboardingRecord(caseIds, false);
    }
    /**
     * @description Handle events - Milestone Status changes
     * @param Set<Id> milestoneIds
     * @return
    */
    public static void handleMilestoneEvent(Set<Id> milestoneIds){
        Set<Id> caseIds = new Set<Id>();
        for (Milestone__c m : [SELECT Id, Case__r.Opportunity_Name__c, Case__r.Account.Restaurant_ID__c from Milestone__c where Id IN :milestoneIds
                               AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]) {
            if ( m.Case__r.Account.Restaurant_ID__c != null && m.Case__r.Opportunity_Name__c != null ) {
                caseIds.add(m.Case__c);
            }
        }
        createOrUpdateMxOnboardingRecord(caseIds, true);
    }
    /**
     * @description Create/Update MxOnboarding Records
     * applyMilestoneUpdates Set to True when called from Milestone event
     * applyMilestoneUpdates Set to False when called on Case Insert
     * @param Set<ID> caseIds
     * @param List<String> storeIDs
     * @param Boolean applyMilestoneUpdates
     * @return
    */
    public static void createOrUpdateMxOnboardingRecord(Set<ID> caseIdsToProcess, Boolean applyMilestoneUpdates){
        Map<Id, String> storeIdToCaseIdMap = getEligibleCasesForOnboarding(caseIdsToProcess);
        if (storeIdToCaseIdMap.isEmpty()) {
            return;
        }
        Set<Id> caseIds = storeIdToCaseIdMap.keySet();
        List<String> storeIds = storeIdToCaseIdMap.values();
        Map<String, Mx_Onboarding__c> mxOnboardingBystoreID = getMxOnboardingRecord(storeIDs);
        Map<String, String> mxOnboardingCreatePayload = new Map<String, String>();
        mxOnboardingCreatePayload = getPropertyAPINames(MdtConfig.get('MxOnboarding_Config'));
        String mxonboardingCreateQuery = getPayloadQuery('Case', mxOnboardingCreatePayload.values(), caseIds, 'ID');
        for(Case c : Database.Query(mxonboardingCreateQuery)){
            String storeId = (c.Account != null && String.isNotBlank(c.Account.Restaurant_ID__c) ? c.Account.Restaurant_ID__c : null);
            if (String.isNotBlank(storeId)){
                Mx_Onboarding__c mxOnboarding = mxOnboardingBystoreID.containsKey(storeId) ? mxOnboardingBystoreID.get(storeId) : new Mx_Onboarding__c(StoreId__c = storeId);
                applyUpdates(c, mxOnboardingCreatePayload, mxOnboarding);
                mxOnboarding.Case_Status__c = c.Status;
                mxOnboarding.Case_StatusReason__c = c.Status_Reason__c;
                mxOnboarding.Case_Stage__c = c.Stage__c;
                mxOnboardingBystoreID.put(storeId, mxOnboarding);
                if (mxOnboarding.UpdateType__c != 'Inbound') {
                    mxOnboarding.UpdateType__c = 'Outbound';
                }
            }
        }
        if (!mxOnboardingBystoreID.isEmpty()) {
            if (applyMilestoneUpdates) {
                applyMilestoneUpdates(caseIds, mxOnboardingBystoreID);
            }
            List<Database.UpsertResult> uResults = Database.upsert(mxOnboardingBystoreID.values(), false);
            CDdErrorUtilities.publishException('Mx_Onboarding__c', 'CDdMxOnboardingMxSxEventHandler', uResults);
        }
    }
     /**
     * @description get the Milestone Status Updates
     * @param Set<Id> caseIds
     * @param Map<String, Mx_Onboarding__c> mxOnboardingBystoreID
     * @return
    */
    public static void applyMilestoneUpdates(Set<Id> caseIds, Map<String, Mx_Onboarding__c> mxOnboardingBystoreID){
        Map<String, Id> marketplaceCaseIDByStoreId = new  Map<String, Id>();
        Map<ID, List<Milestone__c>> milestoneByCaseID = new Map<ID, List<Milestone__c>>();
        Set<Id> accountIDs = new Set<Id>();
        for (Milestone__c m : [SELECT Id, Case__c, Case__r.Account.Restaurant_ID__c, Case__r.Opportunity_Name__c,
                            RecordType.developername, Status__c, Status_Reason__c, Milestone_Type__c
                            FROM Milestone__c
                            WHERE Case__c IN :caseIds
                            AND RecordTypeId IN: CDdMxSxConstants.MX_ONBOARDING_APPLICABLE_MILESTONE_RECORD_TYPE_IDS]){
            if (m.Case__r != null && m.Case__r.Account != null && String.isNotBlank(m.Case__r.Account.Restaurant_ID__c)){
                if (milestoneByCaseID.containsKey(m.Case__c)) {
                    milestoneByCaseID.get(m.Case__c).add(m);
                } else {
                    milestoneByCaseID.put(m.Case__c, new List<Milestone__c>{m});
                }
                marketplaceCaseIDByStoreId.put(m.Case__r.Account.Restaurant_ID__c, m.Case__c);
                //add only the accIds if the milestone is a deliver tablet type
                if (m.RecordType.developername == 'Deliver_Tablet') {
                    accountIDs.add(m.Case__r.AccountId);
                }
            }
        }
        // Preparing the data for Tablet Milestone
        Map<String,Mx_Order__c> storeIDBymxOrderID;
        Map<String,String> mxOnboardingTabletPayload = new Map<String, String>();
        if(!accountIDs.isEmpty()){
            mxOnboardingTabletPayload = getPropertyAPINames(MdtConfig.get('Mx_Onboarding_Config_Tablet'));
            storeIDBymxOrderID =  getMxOrder(accountIDs, mxOnboardingTabletPayload);
        }
        for (String storeID :marketplaceCaseIDByStoreId.keySet()) {
            Id caseId = marketplaceCaseIDByStoreId.get(storeID);
            if (mxOnboardingBystoreID.containsKey(storeID)){
                Mx_Onboarding__c mxOnboarding = mxOnboardingBystoreID.get(storeID);
                for(Milestone__c m : milestoneByCaseID.get(caseId)){
                    if (m.RecordType.developername == 'Setup_Menu'){
                        mxOnboarding.Menu_Status__c = m.Status__c;
                        mxOnboarding.Menu_StatusReason__c = m.Status_Reason__c;
                    } else if (m.RecordType.developername == 'Setup_Banking') {
                        mxOnboarding.Banking_Status__c = m.Status__c;
                        mxOnboarding.Banking_StatusReason__c = m.Status_Reason__c;
                    }else if (m.RecordType.developername == 'Activate_Store') {
                        mxOnboarding.ActivateStore_Status__c = m.Status__c;
                        mxOnboarding.ActivateStore_StatusReason__c = m.Status_Reason__c;
                    } else if (m.RecordType.developername == 'Activations_Checklist') {
                        mxOnboarding.ActivationsChecklist_Status__c = m.Status__c;
                        mxOnboarding.ActivationsChecklist_StatusReason__c = m.Status_Reason__c;
                    } else if (m.RecordType.developername == 'Setup_Store') {
                        mxOnboarding.SetupStore_Status__c = m.Status__c;
                        mxOnboarding.SetupStore_StatusReason__c = m.Status_Reason__c;
                    } else if (m.RecordType.developername == 'General_POS' || m.RecordType.developername == 'Setup_POS_Integration') {
                        if(m.Milestone_Type__c == 'Store & POS Integration Setup' || m.Milestone_Type__c == 'Setup POS Integration'){
                            mxOnboarding.StorePOSIntegrationSetup_Status__c = m.Status__c;
                            mxOnboarding.StorePOSIntegrationSetup_Status_Reason__c =  m.Status_Reason__c;
                        }else if (m.Milestone_Type__c == 'Ingest POS Menu') {
                            mxOnboarding.IngestPOSMenu_Status__c =  m.Status__c;
                            mxOnboarding.IngestPOSMenu_StatusReason__c =  m.Status_Reason__c;
                        }
                    } else if (m.RecordType.developername == 'Deliver_Tablet') {
                        mxOnboarding.Tablet_Status__c =  m.Status__c;
                        mxOnboarding.Tablet_StatusReason__c =  m.Status_Reason__c;
                        if (storeIDBymxOrderID.get(storeID) != null) {
                            applyUpdates(storeIDBymxOrderID.get(storeID), mxOnboardingTabletPayload, mxOnboarding);
                        }
                    }
                }
            }
        }
    }
    /**
     * @description gets the Mx_Onboarding__c record for a given StoreID
     * @param List<String> storeIDs
     * @return Map<String,Mx_Onboarding__c
     */
    public static Map<String,Mx_Onboarding__c> getMxOnboardingRecord(List<String> storeIDs){
        Map<String, Mx_Onboarding__c> mxOnboardingBystoreID = new Map<String,Mx_Onboarding__c>();
        for (Mx_Onboarding__c mo : [SELECT Id, StoreID__c, UpdateType__c from Mx_Onboarding__c where StoreID__c IN : storeIDs]) {
            mxOnboardingBystoreID.put(mo.StoreID__c, mo );
        }
        return mxOnboardingBystoreID;
    }
    /**
     * @description retrieve the Mx order for the Unique StroeID
     * @param Set<Id> accountIDs
     * @param Map<String,String> mxOnboardingTabletPayload
     * @return Map<String,Mx_Order__c>
     */
    public static  Map<String,Mx_Order__c> getMxOrder(Set<Id> accountIDs, Map<String,String> mxOnboardingTabletPayload ){
        Map<id,String> tabletCaseIDByStoreID = new Map<Id,String>();
        Map<String,Mx_Order__c> mxOrderIDBystoreID = new Map<String,Mx_Order__c>();
        //populating tablet case by StoreId
        for (Account a : [Select id, Restaurant_ID__c, (Select id from Cases where RecordType.name = 'Tablet Requests' order by lastmodifieddate desc Limit 1) from account where ID IN : accountIDs]){
            if (a.Cases != null && !a.Cases.isEmpty()){
                tabletCaseIDByStoreID.put(a.Cases[0].ID, a.Restaurant_ID__c);
            }
        }
        // Tablet caseIDs
        Set<Id> sObjectIds = new Set<Id>();
        sObjectIds = tabletCaseIDByStoreID.keySet();
        String mxonboardingTabletQuery = getPayloadQueryTablet('Mx_Order__c',mxOnboardingTabletPayload.values(), sObjectIds, 'Case__c');
        // Merchant order by StoreId
        for (Mx_Order__c mo : Database.Query(mxonboardingTabletQuery)) {
            mxOrderIDBystoreID.put(tabletCaseIDByStoreID.get(mo.Case__c),mo);
        }
        return  mxOrderIDBystoreID;
    }
    /**
     * @description Handle events - Opportunity changes
     * @param Set<Id> opportunityIds
     * @return
    */
    public static void handleOpportunityUpdates(Set<Id> opportunityIds){
        Set <String> storeIDs = new Set<String>();
        Map <String, Opportunity> opportunityByStoreId = new  Map<String, Opportunity>();
        for (opportunity opp : [SELECT id, Menu_URL__c, Proposed_Date_of_Activation__c, Account.Restaurant_ID__c from opportunity where id IN :opportunityIds and
                                Account.RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS and Account.Restaurant_ID__c != null]) {
            storeIDs.add(opp.Account.Restaurant_ID__c);
            if (!opportunityByStoreId.containsKey(opp.Account.Restaurant_ID__c)) {
                opportunityByStoreId.put(opp.Account.Restaurant_ID__c, opp);
            }
        }
        // Mdt Config for Opportunity changes
        Map<String,String> mxOnboardingOpportunityPayLoad = new Map<String,String>();
        mxOnboardingOpportunityPayLoad = getPropertyAPINames(MdtConfig.get('Mx_Onboarding_Config_Opportunity'));
        String mxOnboardingOpportunityQuery = getPayloadQueryOpportunity('Opportunity',mxOnboardingOpportunityPayLoad.values(), opportunityIds, 'Id');

        // Querying the Mx Onboarding Fields to compare with the Opportunity updates
        List<String> fieldAPIs = new List<String>( mxOnboardingOpportunityPayLoad.keySet());
        String mxOnboardingQuery = getPayloadQueryMxOboarding('Mx_Onboarding__c', fieldAPIs, storeIDs, 'StoreId__c');
        List <Mx_Onboarding__c> mxOnboardingList =  Database.Query(mxOnboardingQuery);
        if (mxOnboardingList.isEmpty()) {
            return;
        }

        Map <Id, Mx_Onboarding__c> mxOnboardingByOpportunityID = new Map<Id, Mx_Onboarding__c>();

        for (Mx_Onboarding__c mxOnboarding : mxOnboardingList){
            if (opportunityByStoreId.containsKey(mxOnboarding.StoreId__c)) {
                mxOnboardingByOpportunityID.put(opportunityByStoreId.get(mxOnboarding.StoreId__c).ID, mxOnboarding);
            }
        }

        // Mx_Onboarding__c List to Update
        List<Mx_Onboarding__c> mxOnboardingToUpdate = new List <Mx_Onboarding__c>();
        for(Opportunity opp : Database.Query(mxOnboardingOpportunityQuery)){
            Boolean mxOnboardingRecordTobeUpdated = false;
            if (mxOnboardingByOpportunityID.containsKey(opp.Id) && mxOnboardingByOpportunityID.get(opp.Id) != null) {
                Mx_Onboarding__c mxOnboarding = mxOnboardingByOpportunityID.get(opp.Id);
                for(String key: mxOnboardingOpportunityPayLoad.keySet()){
                    Object mxOnboardingFieldvalue = getFieldValue(key, mxOnboarding);
                    Object oppFieldvalue = getFieldValue(mxOnboardingOpportunityPayLoad.get(key), opp);
                    if (mxOnboardingFieldvalue != oppFieldvalue) {
                        mxOnboardingRecordTobeUpdated = true;
                        mxOnboarding.put(key,oppFieldvalue);
                    }
                }
                if (mxOnboardingRecordTobeUpdated) {
                    mxOnboardingToUpdate.add(mxOnboarding);
                }
            }
        }
         // Update Mx_Onboarding__c records
         if (!mxOnboardingToUpdate.isEmpty()) {
            List<Database.SaveResult> sResults = Database.update(mxOnboardingToUpdate, false);
            CDdErrorUtilities.publishException('Mx_Onboarding__c', 'handleOpportunityUpdates', sResults);
         }
    }
    /**
     * @description get Eligible Cases for Onboarding
     * @param Set<Id> caseIds
     * @return Set<Id>
    */
    public static  Map<Id,String> getEligibleCasesForOnboarding(Set<Id> caseIds){
        Map<Id,String> storeIdToCaseIdMap = new Map<Id, String>();
        Map<Id,Case> caseToOppIDMap = new  Map<Id, Case>();
        for (Case c : getCases(caseIds)) {
            // Checks for SMB Merchants and RestaurantId not equal to Null
            if (c.Account.Restaurant_ID__c != null && c.Opportunity_Name__c != null) {
                caseToOppIDMap.put(c.Opportunity_Name__c, c);
            }
        }
         //get eligible opportunities for MxOnboarding
        for (Opportunity oppty : getOpportunities(caseToOppIDMap.keySet())) {
            if (isOpportunityEligibleForMxOnboarding(oppty)){
                storeIdToCaseIdMap.put(caseToOppIDMap.get(oppty.Id).ID, caseToOppIDMap.get(oppty.Id).Account.Restaurant_ID__c);
            }
        }
        return storeIdToCaseIdMap;
    }
     /**
     * @description get Opportunities by opportunityIds
     * @param Set<Id> opportunityIds
     * @return List<Opportunity>
    */
    public static List<Opportunity> getOpportunities(Set<Id> opportunityIds){
        return [SELECT Id, RecordTypeId, AccountId, Region_Type__c,
                Account.RecordTypeId, Account.Deck_Rank__c, Account.Launch_Deck_Rank__c
                FROM Opportunity
                WHERE Id IN :opportunityIds];
    }
    /**
     * @description get Cases by caseIds
     * @param Set<Id> caseIds
     * @return List<Case>
    */
    public static List<Case> getCases(Set<Id> caseIds){
        return [SELECT Id, Opportunity_Name__c, Opportunity_Name__r.RecordTypeId, Opportunity_Name__r.AccountId, Opportunity_Name__r.Account.RecordTypeId,
                Opportunity_Name__r.Account.Deck_Rank__c, Opportunity_Name__r.Account.Launch_Deck_Rank__c, Account.Restaurant_ID__c
                FROM Case
                WHERE Id IN :caseIds];
    }
      /**
     * @description check if Closed Won Opportunity is meeting criteria to Create Mx Onbaording records
     * @param Opportunity oppty
     * @return Boolean
    */
    public static Boolean isOpportunityEligibleForMxOnboarding(Opportunity opportunity){
        if (CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_MARKETPLACE.equals(opportunity.RecordTypeId)
            && String.isNotBlank(opportunity.AccountId)
            && !CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(opportunity.Account.RecordTypeId)
            && !DECK_RANKS_TO_EXCLUDE.contains(opportunity.Account.Deck_Rank__c)
            && !DECK_RANKS_TO_EXCLUDE.contains(opportunity.Account.Launch_Deck_Rank__c)){
                return true;
        }
        return false;
    }
    /**
     * @description instantiate the Mx_Onboarding__c for Tablet updates
     * @param SObject source
     * @param Map<String, String> payLoad
     * @return SObject target
     */
    public static void applyUpdates(SObject source, Map<String, String> values, SObject target){
        for(String key: values.keySet()){
            Object value = getFieldValue(values.get(key), source);
            if(value != null){
                target.put(key,value);
            }
        }
    }
    /**
     * @description Prepares the key, value pair of the metadata from Merchant_Onboarding_Properties__mdt
     * @param
     * @return Map<String, String> payLoad
     */
    public static Map<String, String> getPropertyAPINames(List<Merchant_Onboarding_Properties__mdt> merchantOnBoardingtData){
        if(merchantOnBoardingtData == null || merchantOnBoardingtData.isEmpty()){
            return null ;
        }
        Map<String, String> payLoad = new Map<String, String>();
        for(Merchant_Onboarding_Properties__mdt mxOnboardingProperty : merchantOnBoardingtData){
            payLoad.put(mxOnboardingProperty.Target_SObject_API_Field__c, mxOnboardingProperty.Source_SObject_API_Field__c);
        }
        return payLoad ;
    }
     /**
     * @description Extracts the field value from the Api field name
     * @param String fieldAPI
     * @param sObject obj
     * @return String value
     */
    public static Object getFieldValue(String fieldAPI, sObject obj){
        Object value = '';
        List<String> fieldAPIs = fieldAPI.split('\\.');
        if(!fieldAPIs.isEmpty()){
            for(Integer i = 0; i<fieldAPIs.Size(); i++){
                if(obj != null){
                    if( i == (fieldAPIs.Size() - 1)){
                        value = obj.get(fieldAPIs[i]);
                    }else{
                        obj = (sObject)obj.getSobject(fieldAPIs[i]);
                    }
                }
           }
        }
        return value ;
    }
    /**
     * @description Get the Query String for Sobject Type
     * @param String sObjectType
     * @param List<String> fieldAPIs
     * @param Set<Id> sObjectIds
     * @param String referenceField
     * @return String query
     */
    public static String getPayloadQuery(String sObjectType, List<String> fieldAPIs, Set<Id> caseIds, String referenceField){
        String query = '';
        query = 'Select Id, Status, Status_Reason__c, Stage__c, '+ String.Join(fieldAPIs, ', ') + ' from ' +
                 sObjectType+ ' where '+ referenceField +' IN :caseIds' ;
        return query;
    }
    public static String getPayloadQueryTablet(String sObjectType, List<String> fieldAPIs, Set<Id> sObjectIds, String referenceField){
        String query = '';
        query = 'Select Id, '+ String.Join(fieldAPIs, ', ') + ' from ' +
                 sObjectType+ ' where '+ referenceField +' IN :sObjectIds' ;
        return query;
    }
    public static String getPayloadQueryMxOboarding(String sObjectType, List<String> fieldAPIs, Set<String> storeIDs, String referenceField){
        String query = '';
        query = 'Select Id, StoreId__c, '+ String.Join(fieldAPIs, ', ') + ' from ' +
                 sObjectType+ ' where '+ referenceField +' IN :storeIDs' ;
        return query;
    }
    public static String getPayloadQueryOpportunity(String sObjectType, List<String> fieldAPIs, Set<Id> opportunityIds, String referenceField){
        String query = '';
        query = 'Select Id, Account.Restaurant_ID__c, '+ String.Join(fieldAPIs, ', ') + ' from ' +
                 sObjectType+ ' where '+ referenceField +' IN :opportunityIds' ;
        return query;
    }
 }