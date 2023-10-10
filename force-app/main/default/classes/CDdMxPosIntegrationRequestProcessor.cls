/********************************************************************************************************************
* @author Praveen
* @date 1/17/2023
*
* @group Merchant Services
*
* @description This class takes input of pos integration requests id from BAT and process the records. This class is invoked by CDdMxSxPosIntegrationRequestScheduler.
*
**************************************************************************************************************************************/

public class CDdMxPosIntegrationRequestProcessor {
    public Set<String> onboardingIds = new Set<String>();
    public Map<String, Account> accountsByStoreId = new Map<String,Account>();
    public List<Integration_Request__x> posIntegrationRequests = new List<Integration_Request__x>();
    Set<String> storeIds = new Set<String>();
    public Map<String, Map<Id,Case>> openCasesByRecordTypeIdandStoreId = new Map<String, Map<Id,Case>>();
    public List<sObject> listSobjectsToUpdate = new List<sObject>();
    public List<sObject> listSobjectsToInsert = new List<sObject>();
    public String INTEGRATION_REQUEST_ACTION_UPDATE = 'UPDATE';
    public String MILISTONE_STATUS_NOT_STARTED = 'Not Started';
    public String ORDER_PROTOCOL_POS = 'POS';
    public String MILESTONE_SETUP_POS_INTEGRATION ='Setup POS Integration';
    //'Setup POS Integration';
    public String MARKETPLACE_ONBOARDING = CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING;
    public String CAVIAR_ONBOARDING = CDdMxSxConstants.RECORD_TYPE_ID_CASE_CAVIAR_ONBOARDING;
    public static Map<String, Map<String, Bat_To_Milestone_Status_Mapping__mdt>> batSettingForMilestone;
    public static Map<String, Bat_To_Milestone_Status_Mapping__mdt>  batSettingForCase;
    private String BAT_STATUS_INTEGRATION_ACTIVATED = 'INTEGRATION_ACTIVATED';
    public Map<String, String> opportunityOrderProtocolOldvsNew = new Map<String, String>{
        'Android Tablet (Merchant Owns)' => 'POS',
        'Email' => 'POS',
        'Fax' => 'POS',
        'Other' => 'POS',
        'Tablet (DoorDash Owns)' => 'POS and and Tablet (DoorDash Owns)',
        'Tablet and Printer (DoorDash Owns)' => 'POS and and Tablet (DoorDash Owns)',
        'Tablet (Caviar Owns)'=>'POS and Tablet (Caviar Owns)'
    };
    public String INTEGRATION_REQUEST_STATUS_PENDING = 'Pending';
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    // constructor
    public CDdMxPosIntegrationRequestProcessor(Set<String> onboardingIds) {
        batSettingForMilestone = new Map<String, Map<String, Bat_To_Milestone_Status_Mapping__mdt>>();
        batSettingForCase = new Map<String, Bat_To_Milestone_Status_Mapping__mdt>();
        this.onboardingIds = onboardingIds;
        getBatMetaData();
    }
    /**
     * @description execute method to sequentially Process pos integrations cases from BAT.
     * Create new Pos integration if there is no Ob and pos case exist.
     * If the ob case exist update opportunity order protocol to pos and create new pos integration case and pos milestone on the case.
     * If pos integration case exist and providertype or locationId is different is different, make the existing case as dead and create new pos case.
     * If the pos case exists and location Id is blank or same update latest BAT info on POS case. 
     * Reset the ob case Pos milestone if we make the existing case dead.
     * If pos request type action is Update, update the milestones on the case.
    */
    public void execute(){
        try{
            getPosIntegrationRequestStoreIds();
            Set<Id> accountIds = getAccountForStoreIds();
            getOpenCasesForStores(accountIds);
            Boolean createPosCase = true;
            for(Integration_Request__x posRequest: posIntegrationRequests){
                String storeId = posRequest.Store_Id__c;
                if(!accountsByStoreId.containsKey(storeId)){
                    posRequest.Sfdc_status__c = CDdMxSxConstants.POS_INTEGRATION_REQUESTS_STATUS_FAILED;
                    posRequest.Error_Message__c = 'Account not found with store Id';
                    continue;
                }
                //If action is update and if there is no open cases continue to next request.
                if(INTEGRATION_REQUEST_ACTION_UPDATE.equals(posRequest.Action__c) && !isMilestonesCreatedForUpdate(storeId, posRequest.onboarding_id__c)){
                    continue;
                }
                //Update pos request to processed as below processes any way will get processed.
                posRequest.Sfdc_status__c = CDdMxSxConstants.POS_INTEGRATION_REQUESTS_STATUS_PROCESSED;
                // if there is existing open cases on acccount run checks for the existing cases before creating pos case.
                Case openObCase = new Case();
                if(openCasesByRecordTypeIdandStoreId.containsKey(storeId)){
                    Map<Id, Case> openCases = openCasesByRecordTypeIdandStoreId.get(storeId);
                    openObCase = getOpenObCase(openCases);
                    Case openPosIntegrationCase = getCaseByRecordTypeId(openCases, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS);
                    // If action is update, update milestones and continue to next pos request.
                    if(INTEGRATION_REQUEST_ACTION_UPDATE.equals(posRequest.Action__c) && openPosIntegrationCase != null){
                        mapIntegrationRequestToMilestoneAndCase(openPosIntegrationCase, posRequest);
                        continue;
                    }
                    handleScenariosforOpenObCase(openObCase, posRequest);
                    List<Milestone__c> obCaseMilestones = openObCase != null && openObCase.milestones__r != null ? openObCase.milestones__r : new List<Milestone__c>();
                    createPosCase = handleScenariosforOpenPosCase(openPosIntegrationCase, posRequest, obCaseMilestones);
                }
                if(createPosCase && !INTEGRATION_REQUEST_ACTION_UPDATE.equals(posRequest.Action__c)){
                    uow.registerNew(createPosIntegrationCase(posRequest, openObCase));
                }
            }
            uow.commitWork();
            if(!test.isrunningTest()){
                Database.updateAsync(posIntegrationRequests);
            }
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('IntegrationRequest','CDdMxPosIntegrationRequestProcessor', ex);
        }
    }
    /**
     * @description handleScenariosforOpenObCase.
     * @param Case openObCase;
     * @param Integration_Request__x posRequest
     * @return Boolean
    */
    private Boolean handleScenariosforOpenObCase(Case openObCase, Integration_Request__x posRequest){
        Boolean createPosCase = true;
        //If the ob case exist update opportunity order protocol to pos and create new pos integration case
        if(existingOppProtocolNotPos(openObCase)){
            uow.registerDirty(updateOpportunityOrderprotocol(openObCase, posRequest));
        }
        return createPosCase;
    }
    /**
     * @description handleScenariosforOpenPosCase.
     * @param Case openPosIntegrationCase;
     * @param Integration_Request__x posRequest
     * @return Boolean
    */
    private Boolean handleScenariosforOpenPosCase(Case openPosIntegrationCase, Integration_Request__x posRequest, List<Milestone__c> milestones){
        Boolean createPosCase = true;
        if(openPosIntegrationCase != null){
            // If pos integration case exist and provider type is different, make the existing case as dead and create new pos case.
            // If pos integration case exist and location Id is different, make the existing case as dead and create new pos case.
            if(!existingPosRequestSameAsNewPOSRequest(openPosIntegrationCase, posRequest) || !isLocationIdSameAsLocationIdFromBat(openPosIntegrationCase, posRequest)){
                openPosIntegrationCase.status = CDdMxSxConstants.CASE_STATUS_DEAD;
                uow.registerDirty(openPosIntegrationCase);
                // As we are making existing case as dead and creating new pos case reset the ob case pos milestone.
                resetObCaseMilestones(milestones);
            }else{
                // if the existing provider type and location is same, Do not create new pos case contnue to next pos request.
                createPosCase = false;
            }
        }
        return createPosCase;
    }
    /**
     * @description reset the onboarding milestone satus if the existing pos case is dead and new one getting created.
     * @param List<Milestone__c> milestones
     * @return void
    */
    private void resetObCaseMilestones(List<Milestone__c> milestones){
        for(Milestone__c milestone: milestones){
            if(milestone.Milestone_Type__c == MILESTONE_SETUP_POS_INTEGRATION){
                milestone.status__c = MILISTONE_STATUS_NOT_STARTED;
                milestone.Start_Date_Time__c = null;
                milestone.Status_Reason__c = null;
                milestone.Status_Reason_Details__c = null;
                uow.registerDirty(milestone);
            }
        }
    }
    /**
     * @description Process Cases for Merchant Services
     * @param List<Case> newCases
     * @param List<Case> oldMap
     * @return Boolean
    */
    private Set<Id> getAccountForStoreIds(){
        Set<Id> accountIds = new Set<Id>();
        for(Account act: AccountsSelector.newInstance().selectAccountsByStoreId(storeIds)){
            accountsByStoreId.put(act.Restaurant_ID__c, act);
            accountIds.add(act.Id);
        }
        return accountIds;
    }
    /**
     * @description get the pending pos integration requests from Bat.
    */
    private void getPosIntegrationRequestStoreIds(){
        CDdMxIntegrationObject posRequests = integrationRequestsSelector.newInstance().selectIntegrationRequestsByOnboardingIds(onboardingIds);
        for(Integration_Request__x posRequest: posRequests.integrationRequests){
            if(INTEGRATION_REQUEST_STATUS_PENDING.equals(posRequest.Sfdc_Status__c)){
            	posIntegrationRequests.add(posRequest);
                storeIds.add(posRequest.Store_Id__c);
            }
        }
    }
    /**
     * @description update opportunity order protocol.
     * @param case openObCase
     * @return Boolean
    */
    private Boolean existingOppProtocolNotPos(Case obCase){
        return  obCase != null && (String.isBlank(obCase.Opportunity_Name__r.Order_protocol__c) || !(obCase.Opportunity_Name__r.Order_protocol__c).contains('POS')) ? true:false;
    }
    /**
     * @description update opportunity order protocol.
     * @param case openObCase
     * @param Integration_Request__x pos request.
     * @return void
    */
    private opportunity updateOpportunityOrderprotocol(Case openObCas, Integration_Request__x posRequest){
        opportunity opp = new opportunity();
        opp.Id =  openObCas.Opportunity_Name__c;
        String orderProtocol = openObCas.Opportunity_Name__r.Order_protocol__c != null ? 
            opportunityOrderProtocolOldvsNew.get(openObCas.Opportunity_Name__r.Order_protocol__c) : ORDER_PROTOCOL_POS;
        opp.Order_protocol__c = orderProtocol;
        opp.POS_Integration_ID__c = posRequest.Integration_Id__c;
        opp.Activation_Case_Created__c = true;
        opp.POS_Integration_Type__c = posRequest.Integration_Provider__c;
        opp.POS_Fallback_Protocol__c = 'Dasher Red Card';
        return opp;
    }
    /**
     * @description get open cases for given stores.
     * @param List<Id> accountIds
     * @return void
    */
    private void getOpenCasesForStores(Set<Id> accountIds){
        Set<Id> caseRecordTypeIds = new Set<Id>{MARKETPLACE_ONBOARDING, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS, CAVIAR_ONBOARDING};
        for(case openCase: CasesSelector.newInstance().selectCasesWithMilestoneByRecordTypesAndAccountsAndStatus(caseRecordTypeIds, accountIds, CDdMxSxConstants.OB_CASE_OPEN_STATUS)){
            Map<Id, Case> cas = new Map<Id, Case>();
            if(openCasesByRecordTypeIdandStoreId.containsKey(openCase.account.Restaurant_ID__c)){
                cas = openCasesByRecordTypeIdandStoreId.get(openCase.account.Restaurant_ID__c);
                cas.put(openCase.RecordTypeId, openCase);
            }else{
                cas.put(openCase.RecordTypeId, openCase);
            }
            openCasesByRecordTypeIdandStoreId.put(openCase.account.Restaurant_ID__c, cas);
        }
    }
     /**
     * @description get open ob cases for given stores.
     * @param Map<Id, Case> openCase
     * @return case
    */
    private Case getOpenObCase(Map<Id, Case> openCase){
        return openCase.containsKey(MARKETPLACE_ONBOARDING) ? openCase.get(MARKETPLACE_ONBOARDING) : openCase.containsKey(CAVIAR_ONBOARDING) ? openCase.get(CAVIAR_ONBOARDING) : null;
    }
    /**
     * @description get get open Case By RecordTypeId
     * @param Map<Id, Case> openCase
     * @param Id recordTypeId
     * @return case
    */
    private Case getCaseByRecordTypeId(Map<Id, Case> openCase, Id recordTypeId){
        return openCase.containsKey(recordTypeId) ? openCase.get(recordTypeId) : null;
    }
    /**
     * @description get get open Case By RecordTypeId
     * @param Map<Id, Case> openCase
     * @param Id recordTypeId
     * @return case
    */
    private Boolean isMilestonesCreatedForUpdate(String storeId, String onBoardingId){
        Boolean mileStoneExists = false;
        if(openCasesByRecordTypeIdandStoreId.containsKey(storeId)){
            Map<Id, Case> openCases = openCasesByRecordTypeIdandStoreId.get(storeId);
            Case openPosIntegrationCase = getCaseByRecordTypeId(openCases, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS);
            Boolean onboardingIdisSame = openPosIntegrationCase != null && onBoardingId.equals(openPosIntegrationCase.onboarding_id__c) ? true : false;
            mileStoneExists = onboardingIdisSame && openPosIntegrationCase.Milestones__r != null && openPosIntegrationCase.Milestones__r.size() > 0? true : false;
        }   
        return mileStoneExists;
    }
    /**
     * @description check the provider type for existing cases.
     * @param Case openPosIntegrationCase
     * @param Integration_Request__x posRequest
     * @return Boolean
    */
    private Boolean existingPosRequestSameAsNewPOSRequest(Case openPosIntegrationCase, Integration_Request__x posRequest){
        return openPosIntegrationCase.POS_Integration_Type__c != null 
     			&& posRequest.Integration_Provider__c != null 
            	&& posRequest.Integration_Provider__c.equals(openPosIntegrationCase.POS_Integration_Type__c)? true:false;
    }
    /**
     * @description check location id between open case vs integration case.
     * @param Case openPosIntegrationCase
     * @param Integration_Request__x posRequest
     * @return Boolean
    */
    private Boolean isLocationIdSameAsLocationIdFromBat(Case openPosIntegrationCase, Integration_Request__x posRequest){
        Boolean isLocationIdIsSame = String.isEmpty(openPosIntegrationCase.POS_Integration_ID__c) || 
            openPosIntegrationCase.POS_Integration_ID__c.equals(posRequest.Integration_Id__c) ? true : false;
         if(isLocationIdIsSame){
            openPosIntegrationCase.POS_Integration_ID__c = posRequest.Integration_Id__c;
            openPosIntegrationCase.onboarding_id__c = posRequest.Onboarding_Id__c;
            openPosIntegrationCase.Origin = getCaseOrigin(posRequest.Onboarding_Type__c);
            uow.registerDirty(openPosIntegrationCase);
         }
        return isLocationIdIsSame;
    }
    /**
     * @description create pos integration case.
     * @param Integration_Request__x posRequest
     * @return void
    */
    private case createPosIntegrationCase(Integration_Request__x posRequest, Case obCase){
        Case cs = new Case();
        cs.accountId = accountsByStoreId.get(posRequest.Store_Id__c).Id;
        cs.Stage__c = 'Under Review';
        cs.Activation_Method__c = 'Light Up';
        String goLiveDate = posRequest.Activation_Date__c != null ? posRequest.Activation_Date__c.format() : Date.Today().adddays(10).format();
        cs.subject = String.format('{0} {1} Rollout Launches', new List<Object>{ posRequest.Integration_Provider__c	, goLiveDate});
        cs.Origin = getCaseOrigin(posRequest.Onboarding_Type__c);
        cs.Description = String.format('{0} Created by Bulk Tool Automation ', new List<Object>{ posRequest.Integration_Provider__c	,  Date.Today().format() });
        cs.onboarding_id__c = posRequest.Onboarding_Id__c;
        cs.POS_Integration_Type__c	 = posRequest.Integration_Provider__c	;
        cs.POS_Integration_ID__c = posRequest.Integration_Id__c;
        cs.Decision_Maker_Email__c = posRequest.Decision_Maker_Email__c;
        cs.provider_account_owner_email__c = posRequest.provider_account_owner_email__c;
        cs.Business_Id__c = posRequest.Business_Id__c != null ? Integer.valueof(posRequest.Business_Id__c) : null;
        cs.recordTypeId = CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS;
        cs.POS_Go_Live_Date__c = cs.Due_Date__c = cs.Go_Live_Date__c = cs.Requested_Due_Date__c = posRequest.Activation_Date__c;
        cs.Previous_POS_Integration_ID__c = posRequest.Previous_Integration_Id__c;
        cs.Previous_POS_Integration_Type__c	 = posRequest.Previous_Integration_Provider__c	;
        cs.Activation_Notes__c = posRequest.Notes__c;
        cs.parentId = obCase != null ? obCase.Id : null;
        cs.ownerId = CDdMxSxConstants.QUEUE_ID_POS_INTEGRATION_REQUESTS;
        return cs;
    }
    /**
     * @description gets the case origin based on the bat pos request type.
     * @param String posOnboardingType
     * @return String caseOrigin
    */
    private String getCaseOrigin(String posOnboardingType){
        return 'BULK_ACTIVATION'.equals(posOnboardingType) ?'Bulk Tool Automation':'SELF_SERVE_INTEGRATION_ONBOARDING'.equals(posOnboardingType)?'Px Initiated POS Integration [SSIO]':'';
    }
     /**
    * @description This method maps an integration request to a Milestone and case.
    * @param cs A case object.
    * @param ir An Integration_Request__x object.
    */
    private void mapIntegrationRequestToMilestoneAndCase(Case cs, Integration_Request__x ir){

        for(Milestone__c eachMilestone: cs.Milestones__r){
            Bat_To_Milestone_Status_Mapping__mdt setting = getSettingForUpdateMilestone(ir, eachMilestone);
            Boolean updateMilestone = setting != null ? true : false;
            if(updateMilestone){
                updateMilestone(eachMilestone, setting);
            }
        }
        Bat_To_Milestone_Status_Mapping__mdt setting = getSettingForUpdateCase(ir, cs);
        Boolean updateCase = setting != null ? true : false;
        if(updateCase){
            updateCase(cs, setting, ir);
        }
    }
    /**
     * @description This method returns a Bat_To_Milestone_Status_Mapping__mdt object that matches the target status of the
     * Integration_Request__x object and the case object.
     * @param ir An Integration_Request__x object.
     * @param cas A case object.
     * @return A Bat_To_Milestone_Status_Mapping__mdt object.
     */
    private Bat_To_Milestone_Status_Mapping__mdt getSettingForUpdateCase(Integration_Request__x ir, Case cas){
        if(String.isNotBlank(Ir.Target_Status__c) && batSettingForCase.containsKey(Ir.Target_Status__c)){
            return batSettingForCase.get(Ir.Target_Status__c);
        }
        return null;
    }
    /**
     * @description This method returns a Bat_To_Milestone_Status_Mapping__mdt object that matches the target status
     * and exclusion code of the Integration_Request__x object and the Milestone object.
     * @param ir An Integration_Request__x object.
     * @param milestone A Milestone object.
     * @return A Bat_To_Milestone_Status_Mapping__mdt object.
     */
    private Bat_To_Milestone_Status_Mapping__mdt getSettingForUpdateMilestone(Integration_Request__x ir, Milestone__c milestone){
        String statusAndExclusionCode = string.format('{0}@{1}', new string[]{ir.Target_Status__c, ir.Exclusion_Code__c});
        // checks for is Integration Request status exists in default map.
        if(String.isNotBlank(ir.Target_Status__c) && batSettingForMilestone.containsKey(statusAndExclusionCode)){
            Map<String, Bat_To_Milestone_Status_Mapping__mdt> settingByMilestone = batSettingForMilestone.get(statusAndExclusionCode);
            return settingByMilestone.containsKey(milestone.Milestone_Type__c) ? settingByMilestone.get(milestone.Milestone_Type__c) : null;
        }
        return null;
    }
    /**
     * @description This method updates the Status__c and Notes__c fields of a case object based on a Bat_To_Milestone_Status_Mapping__mdt
     * object and an Integration_Request__x object.
     * @param cas A case object.
     * @param setting A Bat_To_Milestone_Status_Mapping__mdt object.
     * @param ir An Integration_Request__x object.
     */
    private void updateCase(Case cas, Bat_To_Milestone_Status_Mapping__mdt setting, Integration_Request__x ir){
        cas.Status = setting.Case_Status__c;
        if(BAT_STATUS_INTEGRATION_ACTIVATED.equals(ir.Target_Status__c)){
            cas.Activation_Notes__c = ir.Notes__c;
        }
        uow.registerDirty(cas);
    }
    /**
     * @description This method updates the Status, Status_Reason__c, and Status_Reason_Details__c fields of a Milestone__c object
     * based on a Bat_To_Milestone_Status_Mapping__mdt object.
     * @param milestone A milestone object.
     * @param setting A Bat_To_Milestone_Status_Mapping__mdt object.
     */
    private void updateMilestone(Milestone__c milestone, Bat_To_Milestone_Status_Mapping__mdt setting){
        milestone.Status__c = setting.Milestone_Status__c;
        milestone.Status_Reason__c = setting.Status_Reason__c;
        uow.registerDirty(milestone);
    }

    /**
     * @description Retrieves the metadata for the Bat_To_Milestone_Status_Mapping__mdt custom metadata type and populates the batSettingForMilestone
     * and batSettingFoCaser maps with the appropriate values.
     */
    private void getBatMetaData(){
        for(Bat_To_Milestone_Status_Mapping__mdt eachMdt: BatToMilestoneStatusMappingSelector.newInstance().getAllValues()){
            String statusAndExclusionCode = string.format('{0}@{1}', new string[]{eachMdt.Bat_Status__c, eachMdt.Exclusion_Code__c});

            if(batSettingForMilestone.containsKey(statusAndExclusionCode)){
                Map<String, Bat_To_Milestone_Status_Mapping__mdt> settingMap = batSettingForMilestone.get(statusAndExclusionCode);
                    settingMap.put( eachMdt.Milestone_Type__c, eachMdt );
            } else {
                batSettingForMilestone.put( statusAndExclusionCode,
                    new Map<String, Bat_To_Milestone_Status_Mapping__mdt>{eachMdt.Milestone_Type__c => eachMdt}
                );
            }
            if(String.isNotBlank(eachMdt.Case_Status__c)){
                batSettingForCase.put(eachMdt.Bat_Status__c, eachMdt);
            }
        }
    }

}