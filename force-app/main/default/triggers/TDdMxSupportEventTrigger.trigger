/********************************************************************************************************************
* @author Veera
* @date 04/28/2022
*
* @group Merchant Services
*
* @description This trigger is a subscriber to the 'Mx Support Event'
*
**************************************************************************************************************************************/
trigger TDdMxSupportEventTrigger on Mx_Support_Event__e (After insert) {

    CDdMxSupportEventSubscriber subsciber = new CDdMxSupportEventSubscriber();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            subsciber.afterInsert(Trigger.new);
        }
    }
}