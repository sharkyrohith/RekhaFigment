/********************************************************************************************************************
* @author Veera
* @date 04/26/2022
*
* @group Merchant Services
*
* @description: Enum class for Merchant Support Event
*               Enum class should be updated to process the records in Mx_Support_Event_Config__c object
*               Event_Name__c field on Mx_Support_Event_Config__c should represent the Enum
*
**************************************************************************************************************************************/
public enum CDdMxSupportEventEnum {
    MX_SUPPORT_TEST_1,    // Please do not remove. This is used for apex code coverage of Mx Support framework
    MX_SUPPORT_TEST_2,    // Please do not remove. This is used for apex code coverage of Mx Support framework
    STOREFRONT_HOLDING_QUEUE,
    UPDATE_DELIVER_TABLET,
    MX_ORDER_DELIVERED,
    MX_ONBOARDING_UPDATE_INBOUND,
    CAVIAR_TURBO_CHARGE_UPDATE
}