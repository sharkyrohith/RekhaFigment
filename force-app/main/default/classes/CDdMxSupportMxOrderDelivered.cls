/********************************************************************************************************************
* @author Sriram
* @date 06/28/2022
*
* @group Merchant Services
*
* @description Support script to sync data points such as Status, IMEI Number on Mx Order/Mx Order Items, when Case is 'Received' (or Delivered)
*
**************************************************************************************************************************************/
public class CDdMxSupportMxOrderDelivered implements CDdMxSupportEventInterface {
    /**
     * @description Variables are defined here
     */
    public static final CDdMxSupportEventEnum MX_ORDER_DELIVERED = CDdMxSupportEventEnum.MX_ORDER_DELIVERED;
    public static String QUERY_SELECT = ' SELECT Id, Case__r.Tablet_Received_Date_2__c, Case__r.Tablet_Serial_Number__c, Case__r.Printer_IMEI__c ';
    public static String QUERY_SELECT_RELATIONSHIP = ' , (SELECT Id, Identifier__c, Product_Family__c FROM Mx_Order_Items__r) ';
    public static String QUERY_FROM = ' FROM Mx_Order__c ';
    public static String QUEUE_FILTER_CRITERIA =  ' WHERE Order_Id__c != NULL '
                                                    +   ' AND Case__r.Status = :{0} ' 
                                                    +   ' AND Order_Status__c != :{1} '; 
    public static String ORDER_BY_CLAUSE = ' ORDER BY Case__r.LastModifiedDate DESC ';
    public static String LIMIT_CLAUSE = ' LIMIT {2} ';
    public static String QUERY_FILTERED_SOBJECT_IDS = ' AND Id IN :{2} ';

    public static String CASE_STATUS_RECEIVED = CDdMxSxConstants.CASE_STATUS_RECEIVED;
    public static String MX_ORDER_STATUS_DELIVERED = CDdMxSxConstants.MX_ORDER_STATUS_DELIVERED;
    public static String QUERY_LIMIT = String.valueOf(CDdMxSupportEventConfig.getQueryLimit(MX_ORDER_DELIVERED));
    public static String FILTERED_SOBJECT_IDS = 'sObjectIds';    
    /** 
     * @description Return the Query Locator to the caller
     */
    public Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator(String.format(QUERY_SELECT + QUERY_FROM + QUEUE_FILTER_CRITERIA + ORDER_BY_CLAUSE + LIMIT_CLAUSE,
                                        new List<String>{'CASE_STATUS_RECEIVED', 'MX_ORDER_STATUS_DELIVERED', QUERY_LIMIT}));
    }
    /** 
     * @description sends the event details to be published to the CDdMxSupportEventPublisher class
     */
    public void publishEvents(String sObjectType, Set<Id> sObjectIds){
        new CDdMxSupportEventPublisher().publishEvents( MX_ORDER_DELIVERED, 
                                                        CDdMxSupportEventConfig.getQuerySObjectType(MX_ORDER_DELIVERED), 
                                                        sObjectIds);
    }
    /** 
     * @description handles the events published by the Mx Support Event Batch class
     */
    public void handleEvents(String sObjectType, Set<Id> sObjectIds){
        List<SObject> sObjectsToUpdate = new List<SObject>();
        for (Mx_Order__c mxOrder : Database.query(getDbQueryFilteredBySObjectIds())){
            sObjectsToUpdate.add(new Mx_Order__c(
                Id = mxOrder.Id,
                Order_Status__c = MX_ORDER_STATUS_DELIVERED,
                Order_Status_Last_Modified_Date__c = mxOrder.Case__r.Tablet_Received_Date_2__c 
            ));
            for (Mx_Order_Item__c item : mxOrder.Mx_Order_Items__r){
                if ((CDdMxSxConstants.MX_PRODUCT_FAMILY_TABLET.equals(item.Product_Family__c) && String.isNotBlank(mxOrder.Case__r.Tablet_Serial_Number__c) && String.isBlank(item.Identifier__c))){
                    sObjectsToUpdate.add(new Mx_Order_Item__c(
                        Id = item.Id,
                        Identifier__c = mxOrder.Case__r.Tablet_Serial_Number__c
                    ));
                }
                if ((CDdMxSxConstants.MX_PRODUCT_FAMILY_PRINTER.equals(item.Product_Family__c) && String.isNotBlank(mxOrder.Case__r.Printer_IMEI__c) && String.isBlank(item.Identifier__c))){
                    sObjectsToUpdate.add(new Mx_Order_Item__c(
                        Id = item.Id,
                        Identifier__c = mxOrder.Case__r.Printer_IMEI__c
                    ));
                }                
            }
        }
        sObjectsToUpdate.sort();
        update sObjectsToUpdate;
    }
    private String getDbQueryFilteredBySObjectIds(){
        return String.format(QUERY_SELECT + QUERY_SELECT_RELATIONSHIP + QUERY_FROM + QUEUE_FILTER_CRITERIA + QUERY_FILTERED_SOBJECT_IDS, 
                            new List<String>{'CASE_STATUS_RECEIVED', 'MX_ORDER_STATUS_DELIVERED', FILTERED_SOBJECT_IDS});
    }    
}