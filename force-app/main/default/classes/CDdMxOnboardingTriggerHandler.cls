/********************************************************************************************************************
* @author Lathika
* @date
*
* @group Merchant Services
*
* @description Trigger handler for object Mx_Onboarding__c
*
**************************************************************************************************************************************/
public class CDdMxOnboardingTriggerHandler {
    /**
     * @description Trigger after update operation on Object Mx_Onboarding__c
     * @param List<Mx_Onboarding__c> newList
     * @param Map<Id, Mx_Onboarding__c> oldMap
     * @return
     */
    public void afterUpdate(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap){
        if(!CDdMxSxConstants.ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE){
            CDdMxOnBoardingTriggerHelper.handleMxOnboardingUpdate(newList, oldMap);
        } else {
            CDdMxSxTriggerHelper.performAfterTriggerEventsForMxOnboarding(newList, oldMap);          
        }    
        
        CDdMxOnBoardingTriggerHelper.handleSSMONewStatusReasons(newList, oldMap);
    }
 }