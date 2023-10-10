/********************************************************************************************************************
* @author Knick
* @date 06/2020
*
* @group Trigger Handler
*
* @description Trigger handler for user object
**************************************************************************************************************************************/
public class CDdUserTriggerHandler {
    /**
    * @description After insert trigger event
    */
    public void beforeInsert(List<User> newList) {
    	CDdUserTriggerHelper.updateCallCenter(newList,null);
    	CDdUserTriggerHelper.updateAccountOwnerRole(newList,null);
    }
    /**
    * @description After insert trigger event
    */
    public void afterInsert(List<User> newList) {
    	CDdUserTriggerHelper.checkLicenses(newList, false);
    }
    /**
    * @description Before update trigger event
    */
    public void beforeUpdate(List<User> newList, Map<Id, User> oldMap) {
    	CDdUserTriggerHelper.checkLicenses(newList, false);
        CDdUserTriggerHelper.logProfileChange(newList,oldMap);
        CDdUserTriggerHelper.updateCallCenter(newList,oldMap);
        CDdUserTriggerHelper.revertToLightningProfile(newList, oldMap);
        CDdUserTriggerHelper.updateAccountOwnerRole(newList,oldMap);
        CDdUserTriggerHelper.logCallCenterChange(newList,oldMap);
    }
    /**
    * @description After update trigger event
    */
    public void afterUpdate(List<User> newList, Map<Id, User> oldMap) {
        if (CDdExperimentSvc.getSupportFeatureFlag('Enable_deActivateUsersCaseReassign__c')) {
            CDdUserTriggerHelper.deActivateUsersCaseReassign(newList,oldMap);
        }
        CDdUserTriggerHelper.removeUserPackageLicenseOnUserDeActivation(newList, oldMap);
    }
}