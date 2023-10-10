/********************************************************************************************************************
* @author Sriram
* @date 03/09/2022
*
* @group Merchant Services
*
* @description Enum class for Merchant Order Event
* 
**************************************************************************************************************************************/
public enum CDdMxOrderEventEnum {
    GENERATE_MX_ORDER,
    QUEUE_MX_ORDER,
    UPDATE_CASE_FOR_MX_ORDER_CANCELLED,
    UPDATE_CASE_FOR_MX_ORDER_CONFIGURED,
    UPDATE_CASE_FOR_MX_ORDER_DELIVERED,
    UPDATE_CASE_FOR_MX_ORDER_FAILED,
    UPDATE_CASE_FOR_MX_ORDER_INVALID,
    UPDATE_CASE_FOR_MX_ORDER_LABELED,
    UPDATE_CASE_FOR_MX_ORDER_NEW,
    UPDATE_CASE_FOR_MX_ORDER_OPEN,
    UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED,
    UPDATE_CASE_FOR_MX_ORDER_PICKED,
    UPDATE_CASE_FOR_MX_ORDER_SHIPPED,
    UPDATE_CASE_FOR_MX_ORDER_VALIDATED,
    UPDATE_CASE_FOR_ORDER_ITEM_PRINTER,
    UPDATE_CASE_FOR_ORDER_ITEM_TABLET,
    UPDATE_CASE_FOR_SETUP_STORE_COMPLETE,
    UPDATE_MX_ORDER_FOR_CASE_RECEIVED,
    UPDATE_MX_ORDER_FOR_CASE_SHIPPED,
    UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE,
    UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE,
    UPDATE_CASE_FOR_MX_ORDER_BLOCKED
}