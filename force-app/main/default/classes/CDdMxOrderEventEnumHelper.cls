/********************************************************************************************************************
* @author Sriram
* @date 03/09/2022
*
* @group Merchant Services
*
* @description Enum helper class for Merchant Order Event
* 
**************************************************************************************************************************************/
public class CDdMxOrderEventEnumHelper {
    public static final String GENERATE_MX_ORDER = 'Generate Mx Order';
    public static final String QUEUE_MX_ORDER = 'Queue Mx Order';
    public static final String UPDATE_CASE_FOR_MX_ORDER_CANCELLED = 'Update Case For Mx Order Cancelled';
    public static final String UPDATE_CASE_FOR_MX_ORDER_CONFIGURED = 'Update Case For Mx Order Configured';
    public static final String UPDATE_CASE_FOR_MX_ORDER_DELIVERED = 'Update Case For Mx Order Delivered';
    public static final String UPDATE_CASE_FOR_MX_ORDER_FAILED = 'Update Case For Mx Order Failed';
    public static final String UPDATE_CASE_FOR_MX_ORDER_INVALID = 'Update Case For Mx Order Invalid';
    public static final String UPDATE_CASE_FOR_MX_ORDER_LABELED = 'Update Case For Mx Order Labeled';
    public static final String UPDATE_CASE_FOR_MX_ORDER_NEW = 'Update Case For Mx Order New';
    public static final String UPDATE_CASE_FOR_MX_ORDER_OPEN = 'Update Case For Mx Order Open';
    public static final String UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED = 'Update Case For Mx Order Partially Delivered';
    public static final String UPDATE_CASE_FOR_MX_ORDER_PICKED = 'Update Case For Mx Order Picked';
    public static final String UPDATE_CASE_FOR_MX_ORDER_SHIPPED = 'Update Case For Mx Order Shipped';
    public static final String UPDATE_CASE_FOR_MX_ORDER_VALIDATED = 'Update Case For Mx Order Validated';
    public static final String UPDATE_CASE_FOR_MX_ORDER_BLOCKED = 'Update Case For Mx Order Blocked';
    public static final String UPDATE_CASE_FOR_ORDER_ITEM_PRINTER = 'Update Case For Order Item Printer';
    public static final String UPDATE_CASE_FOR_ORDER_ITEM_TABLET = 'Update Case For Order Item Tablet';
    public static final String UPDATE_CASE_FOR_SETUP_STORE_COMPLETE = 'Update Case For Setup Store Complete';
    public static final String UPDATE_MX_ORDER_FOR_CASE_RECEIVED = 'Update Mx Order For Case Received';
    public static final String UPDATE_MX_ORDER_FOR_CASE_SHIPPED = 'Update Mx Order For Case Shipped';
    public static final String UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE = 'Update Nonqueued Mx Order For Account Update';
    public static final String UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE = 'Update Nonqueued Mx Order For Case Update';
    public static final Map<String, CDdMxOrderEventEnum> STRING_TO_ENUM = new Map<String, CDdMxOrderEventEnum>{
        GENERATE_MX_ORDER => CDdMxOrderEventEnum.GENERATE_MX_ORDER,
        QUEUE_MX_ORDER => CDdMxOrderEventEnum.QUEUE_MX_ORDER,
        UPDATE_CASE_FOR_MX_ORDER_CANCELLED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_CANCELLED, 
        UPDATE_CASE_FOR_MX_ORDER_CONFIGURED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_CONFIGURED,
        UPDATE_CASE_FOR_MX_ORDER_DELIVERED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_DELIVERED,
        UPDATE_CASE_FOR_MX_ORDER_FAILED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_FAILED, 
        UPDATE_CASE_FOR_MX_ORDER_INVALID => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_INVALID,
        UPDATE_CASE_FOR_MX_ORDER_LABELED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_LABELED,
        UPDATE_CASE_FOR_MX_ORDER_NEW => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_NEW, 
        UPDATE_CASE_FOR_MX_ORDER_OPEN => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_OPEN,  
        UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED,
        UPDATE_CASE_FOR_MX_ORDER_PICKED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_PICKED,
        UPDATE_CASE_FOR_MX_ORDER_SHIPPED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_SHIPPED, 
        UPDATE_CASE_FOR_MX_ORDER_VALIDATED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_VALIDATED,
        UPDATE_CASE_FOR_MX_ORDER_BLOCKED => CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_BLOCKED,
        UPDATE_CASE_FOR_ORDER_ITEM_PRINTER => CDdMxOrderEventEnum.UPDATE_CASE_FOR_ORDER_ITEM_PRINTER,
        UPDATE_CASE_FOR_ORDER_ITEM_TABLET => CDdMxOrderEventEnum.UPDATE_CASE_FOR_ORDER_ITEM_TABLET, 
        UPDATE_CASE_FOR_SETUP_STORE_COMPLETE => CDdMxOrderEventEnum.UPDATE_CASE_FOR_SETUP_STORE_COMPLETE,
        UPDATE_MX_ORDER_FOR_CASE_RECEIVED => CDdMxOrderEventEnum.UPDATE_MX_ORDER_FOR_CASE_RECEIVED,
        UPDATE_MX_ORDER_FOR_CASE_SHIPPED => CDdMxOrderEventEnum.UPDATE_MX_ORDER_FOR_CASE_SHIPPED, 
        UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE => CDdMxOrderEventEnum.UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE,
        UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE => CDdMxOrderEventEnum.UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE
    };
    public static final Map<CDdMxOrderEventEnum, String> ENUM_TO_STRING = new Map<CDdMxOrderEventEnum, String>{
        CDdMxOrderEventEnum.GENERATE_MX_ORDER => GENERATE_MX_ORDER,
        CDdMxOrderEventEnum.QUEUE_MX_ORDER => QUEUE_MX_ORDER,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_CANCELLED => UPDATE_CASE_FOR_MX_ORDER_CANCELLED, 
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_CONFIGURED => UPDATE_CASE_FOR_MX_ORDER_CONFIGURED,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_DELIVERED => UPDATE_CASE_FOR_MX_ORDER_DELIVERED,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_FAILED => UPDATE_CASE_FOR_MX_ORDER_FAILED, 
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_INVALID => UPDATE_CASE_FOR_MX_ORDER_INVALID,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_LABELED => UPDATE_CASE_FOR_MX_ORDER_LABELED,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_NEW => UPDATE_CASE_FOR_MX_ORDER_NEW, 
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_OPEN => UPDATE_CASE_FOR_MX_ORDER_OPEN,  
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED => UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_PICKED => UPDATE_CASE_FOR_MX_ORDER_PICKED,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_SHIPPED => UPDATE_CASE_FOR_MX_ORDER_SHIPPED, 
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_VALIDATED => UPDATE_CASE_FOR_MX_ORDER_VALIDATED,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_MX_ORDER_BLOCKED => UPDATE_CASE_FOR_MX_ORDER_BLOCKED,                                               
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_ORDER_ITEM_PRINTER => UPDATE_CASE_FOR_ORDER_ITEM_PRINTER,
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_ORDER_ITEM_TABLET => UPDATE_CASE_FOR_ORDER_ITEM_TABLET, 
        CDdMxOrderEventEnum.UPDATE_CASE_FOR_SETUP_STORE_COMPLETE => UPDATE_CASE_FOR_SETUP_STORE_COMPLETE,
        CDdMxOrderEventEnum.UPDATE_MX_ORDER_FOR_CASE_RECEIVED => UPDATE_MX_ORDER_FOR_CASE_RECEIVED,
        CDdMxOrderEventEnum.UPDATE_MX_ORDER_FOR_CASE_SHIPPED => UPDATE_MX_ORDER_FOR_CASE_SHIPPED, 
        CDdMxOrderEventEnum.UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE => UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE,
        CDdMxOrderEventEnum.UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE => UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE
    };
    /**
     * @description Return the String value for input Mx Order Event Enum
     * @param CDdMxOrderEventEnum mxOrderEventEnum
     * @return String
     */
    public static String toString(CDdMxOrderEventEnum mxOrderEventEnum){
        return mxOrderEventEnum!= null && ENUM_TO_STRING.containsKey(mxOrderEventEnum) ? ENUM_TO_STRING.get(mxOrderEventEnum) : null;
    }
    /**
     * @description Return the CDdMxOrderEventEnum for input Mx Order Event Name
     * @param String mxOrderEventName
     * @return CDdMxOrderEventEnum
     */    
    public static CDdMxOrderEventEnum toEnum(String mxOrderEventName){
        return String.isNotBlank(mxOrderEventName) && STRING_TO_ENUM.containsKey(mxOrderEventName) ? STRING_TO_ENUM.get(mxOrderEventName) : null;
    }         
}