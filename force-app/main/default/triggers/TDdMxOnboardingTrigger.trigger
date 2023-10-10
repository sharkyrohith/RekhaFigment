/********************************************************************************************************************
* @author Lathika
* @date 03/21/2022
*
* @group Merchant Services
*
* @description Trigger on object Mx_Onboarding__c
*
**************************************************************************************************************************************/
trigger TDdMxOnboardingTrigger on Mx_Onboarding__c (before insert, before update, after insert, after update) {
    CDdMxOnboardingTriggerHandler handler = new CDdMxOnboardingTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) { 
        } else if (Trigger.isUpdate) {
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
 }