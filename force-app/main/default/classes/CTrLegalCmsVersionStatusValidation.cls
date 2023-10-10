/**
 * @author: Raju Lakshman
 * @date: June 2021
 * @description Validate the Status change of the Legal CMS Content Version Record
 */
public without sharing class CTrLegalCmsVersionStatusValidation extends CDdTriggerHandler {
    private List<Legal_CMS_Content_Version__c> triggerList;
    private Map<Id, Legal_CMS_Content_Version__c> triggerMapOld;

    /**
     * @description Constructor that sets class variables based on Trigger context vars
     */
    public CTrLegalCmsVersionStatusValidation() {
        Boolean isDelete = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_DELETE ||
                           getTriggerContext() == CDdTriggerHandler.TriggerContext.AFTER_DELETE;
        this.triggerList = isDelete ? (List<Legal_CMS_Content_Version__c>)trigger.old : (List<Legal_CMS_Content_Version__c>)trigger.new;
        this.triggerMapOld = (Map<Id, Legal_CMS_Content_Version__c>) Trigger.oldMap;
    }

    /**
     * @description Overriden event handlers.
     */

    public override void beforeInsert() {
        validateInsert();
    }

    public override void beforeDelete() {
        validateDelete();
    }

    /**
     * @description Insert should have only 'Draft' status, despite what is set while creating the record
     */
    private void validateInsert() {
        for (Legal_CMS_Content_Version__c rec : triggerList) {
            rec.Status__c = CDdSupportConstants.STATUS_DRAFT;
        }
    }

    /**
     * @description Allow delete only for 'Draft' status
     */
    private void validateDelete() {
        String sysAdminProfile = CDdCustomMetadata.getIdValueFor('System_Admin_Profile');
        for (Legal_CMS_Content_Version__c rec : triggerList) {
            if (rec.Status__c != CDdSupportConstants.STATUS_DRAFT && UserInfo.getProfileId() != sysAdminProfile) {
                rec.addError('Only records with status \'Draft\' can be deleted.');
            }
        }
    }

}