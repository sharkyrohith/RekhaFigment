/**
 * @author: Nayana Kapse
 * @date: Oct 2022
 * @description Processing approved BoB requests
 */  
public without sharing class CTrMxpBoBApprovedUpdReqProcess extends CDdTriggerHandler {  
    
    /**
     * @description Constructor
     */
    public CTrMxpBoBApprovedUpdReqProcess() {}

    /**
     * @description Overriden event handlers..
     */
     public override void afterUpdate() {
        processApprovedTransferRecords();
    }
    
    /**
     * @description Depending on ATM data, validate the record type selection.
     */
    @TestVisible
    private void processApprovedTransferRecords() {
        Id newMerchantBobRecTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_NEW_MERCHANT_BOB);
        Id transferMerchantBobRecTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_TRANSFER_SINGLE_BUSINESSID);
        Id businessBobRecTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_BOOK_OF_BUSINESS);
        Set<Id> lstBusinessIdRecordTypesToProcess = new Set<Id>{newMerchantBobRecTypeId,transferMerchantBobRecTypeId};
        List<MXP_BoB_Update_Request__c> recList = (List<MXP_BoB_Update_Request__c>)triggerList;
        Map<Id,MXP_BoB_Update_Request__c> recOldMap = (Map<Id,MXP_BoB_Update_Request__c>)triggerOldMap;
        Set<Id> batchBusinessRecProcessIds = new Set<Id>();
        Set<Id> batchTransferBobProcessIds = new Set<Id>();
        Map<Id,Id> mapMerchantIdNewUserId = new Map<Id,Id>();
        //Loop over records to find matching recordsa
        for (MXP_BoB_Update_Request__c rec : recList) {
            if (isFieldUpdated(rec, recOldMap, 'Status__c') && rec.Status__c == 'Approved') {
                //for new business/store recordType check if it's for Business or just for one store
                if(lstBusinessIdRecordTypesToProcess.contains(rec.RecordTypeId)){
                    //If for business Id and not for single store then call batch else synchronous
                    if(rec.RecordTypeId == newMerchantBobRecTypeId && rec.Merchant__c != null && String.isNotBlank(rec.Store_Id__c)){
                        mapMerchantIdNewUserId.put(rec.Merchant__c,rec.New_MXP__c);
                        
                    }else{
                    	batchBusinessRecProcessIds.add(rec.Id); 
                    }   
                }else if(rec.RecordTypeId == businessBobRecTypeId){
                    batchTransferBobProcessIds.add(rec.Id); 
                }               
            }
        }
        //Calling business batch job
        if(!batchBusinessRecProcessIds.isEmpty()){
            database.executeBatch(new MxpBobBusinessBatch(batchBusinessRecProcessIds)); // Calling batch class.
        }
        //Calling transfer bob batch job
        if(!batchTransferBobProcessIds.isEmpty()){
            database.executeBatch(new MxpBobTransferBatch(batchTransferBobProcessIds)); // Calling batch class.
        }

        //processing synchronous
        if(!mapMerchantIdNewUserId.isEmpty()){
            List<AccountTeamMember> lstAccoutTeamToDel = new List<AccountTeamMember>();
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        	for (AccountTeamMember atm : AccountTeamMembersSelector.newInstance().selectByAccountIdAndRoles(mapMerchantIdNewUserId.keySet(), new Set<String>{CDdSupportConstants.MXP_ROLE_NAME})) {
                lstAccoutTeamToDel.add(atm);
            }
            for(Id accId: mapMerchantIdNewUserId.keySet()){
                SObject atm = new AccountTeamMember(AccountId=accId,TeamMemberRole= CDdSupportConstants.MXP_ROLE_NAME,
                                                    UserId=mapMerchantIdNewUserId.get(accId),Source__c = MxpBoBUpdateRequest.ACCOUNT_TEAM_MEMBER_SOURCE);
                uow.registerNew(atm);
                //Check if Case Routing Override set if not then set
                Account acc = new Account(Id =accId, Case_Routing_Override__c = CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE);
                uow.registerDirty(acc);
            }
            try{
                uow.registerDeleted(lstAccoutTeamToDel);
            	uow.commitWork();
            }catch(Exception e){
                CDdErrorUtilities.publishException('CTrMxpBoBApprovedUpdReqProcess', 'processApprovedTransferRecords', e);
            }
        }
    }
}