/**
 * @author: Raju Lakshman
 * @date: Oct 2022
 * @description Validations for the Mxp BoB Update Request tool
 */
public without sharing class CTrMxpBoBUpdReqValidations extends CDdTriggerHandler {
    /**
     * @description Constructor
     */
    public CTrMxpBoBUpdReqValidations() {}

    /**
     * @description Overriden event handlers..
     */

    public override void beforeInsert() {
        validateRecordTypeSelection();
    }
    public override void beforeUpdate() {
        validateRecordPriorToApproval();
    }

    /**
     * @description Ensure that records are valid prior to approval, sometimes approver would need to update the record prior to approval
     */
    @TestVisible
    private void validateRecordPriorToApproval() {
        List<MXP_BoB_Update_Request__c> recList = (List<MXP_BoB_Update_Request__c>)triggerList;
        Map<Id,MXP_BoB_Update_Request__c> recOldMap = (Map<Id,MXP_BoB_Update_Request__c>)triggerOldMap;

        String error = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.MXP_BOB_UPDATE_PRE_APPROVE_ERROR);
        for (MXP_BoB_Update_Request__c rec : recList) {
            if (isFieldUpdated(rec, recOldMap, 'Status__c') && rec.Status__c == 'Approved' && rec.Any_MXP__c) {
                rec.addError(error);
            }
        }
    }

    /**
     * @description Depending on ATM data, validate the record type selection.
     */
    @TestVisible
    private void validateRecordTypeSelection() {
        List<MXP_BoB_Update_Request__c> recList = (List<MXP_BoB_Update_Request__c>)triggerList;

        Id newMerchantBobRecTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_NEW_MERCHANT_BOB);
        Id transferMerchantBobRecTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_TRANSFER_SINGLE_BUSINESSID);

        Set<Id> recTypeIdsToCheck = new Set<Id>{newMerchantBobRecTypeId,transferMerchantBobRecTypeId};
        Set<Id> accountsToSearchMxp = new Set<Id>();
        List<MXP_BoB_Update_Request__c> toProcess = new List<MXP_BoB_Update_Request__c>();
        for (MXP_BoB_Update_Request__c rec : recList) {
            if (recTypeIdsToCheck.contains(rec.RecordTypeId) && rec.Merchant__c != null) {
                accountsToSearchMxp.add(rec.Merchant__c);
                toProcess.add(rec);
            }
        }
        if (toProcess.isEmpty()) {
            return;
        }

        Map<Id,String> accountMxpMap = new Map<Id,String>();
        for (AccountTeamMember atm : AccountTeamMembersSelector.newInstance().selectByAccountIdAndRoles(accountsToSearchMxp, new Set<String>{CDdSupportConstants.MXP_ROLE_NAME})) {
            accountMxpMap.put(atm.AccountId,atm.User.Name);
        }

        String newMerchantMxpError = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.MXP_BOB_UPDATE_NEW_MERCHANT_MXP_ERROR);
        String updateMerchantMxpError = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.MXP_BOB_UPDATE_TRANSFER_MXP_ERROR);

        for (MXP_BoB_Update_Request__c rec : toProcess) {
            if (rec.RecordTypeId == newMerchantBobRecTypeId && accountMxpMap.containsKey(rec.Merchant__c)) {
                rec.addError(newMerchantMxpError + accountMxpMap.get(rec.Merchant__c));
            } else if (rec.RecordTypeId == transferMerchantBobRecTypeId && !accountMxpMap.containsKey(rec.Merchant__c)) {
                rec.addError(updateMerchantMxpError);
            }
        }
    }
}