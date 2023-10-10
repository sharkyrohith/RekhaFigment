/********************************************************************************************************************
* @author Sriram
* @date 04/01/2022
*
* @group Merchant Services
*
* @description Trigger helper for object Mx_Order_Item__c
*
**************************************************************************************************************************************/
public class CDdMxOrderItemTriggerHelper {
    /**
     * @description Handle Order Item identifier change
     * Note: Applicable only for product family 'Tablet' and 'Printer'
     * @param List<Mx_Order_Item__c> newList
     * @param Map<Id, Mx_Order_Item__c> oldMap
     * @return
     */  
    public static void handleOrderItemUpdates(List<Mx_Order_Item__c> newList, Map<Id, Mx_Order_Item__c> oldMap){
        List<Mx_Order_Item__c> orderItemTablets = new List<Mx_Order_Item__c>();
        List<Mx_Order_Item__c> orderItemPrinters = new List<Mx_Order_Item__c>();
        for (Mx_Order_Item__c item : newList){
            if (CDdMxSxConstants.MX_PRODUCT_FAMILY_TABLET.equals(item.Product_Family__c) && String.isNotBlank(item.Identifier__c)){
                orderItemTablets.add(item);
            }
            if (CDdMxSxConstants.MX_PRODUCT_FAMILY_PRINTER.equals(item.Product_Family__c) && String.isNotBlank(item.Identifier__c)){
                orderItemPrinters.add(item);
            }            
        }
        if (!orderItemTablets.isEmpty()){
            CDdMxOrderEventHelper.publishMxOrderItemTabletEvents(orderItemTablets);
        }
        if (!orderItemPrinters.isEmpty()){
            CDdMxOrderEventHelper.publishMxOrderPrinterEvents(orderItemPrinters);
        }        
    }    
}