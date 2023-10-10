/********************************************************************************************************************
* @author Sriram
* @date 03/21/2022
*
* @group Merchant Services
*
* @description Trigger helper for object Mx_Order__c
*
**************************************************************************************************************************************/
public class CDdMxOrderTriggerHelper {
    /**
     * @description Variables defined here
     */
    public static final String VALIDATION_MX_ORDER_ALREADY_GENERATED = 'Mx Order is already generated for Case {0}.';
    public static final String DISABLE_SHIPMENT_TRACKING_SETTING = 'Disable_shipment_tracking';
    /**
     * @description Validate the inbound Mx Order record
     * Validation Rule - Prevent the generation of Mx Order record, if one already exists for the corresponding Case (Tablet Request)
     * @param List<Mx_Order__c> newList
     * @return
     */  
    public static void validate(List<Mx_Order__c> newList){
        Set<Id> newCaseIds = new Set<Id>();
        Set<Id> existingCaseIds = new Set<Id>();
        for (Mx_Order__c newMxOrder : newList){
            if (String.isNotBlank(newMxOrder.Case__c)){
                newCaseIds.add(newMxOrder.Case__c);                    
            }
        }
        for (Mx_Order__c existingMxOrder : [SELECT Id, Case__c FROM Mx_Order__c WHERE Case__c IN :newCaseIds]){
            if (String.isNotBlank(existingMxOrder.Case__c)){
                existingCaseIds.add(existingMxOrder.Case__c);
            }
        }
        for (Mx_Order__c newMxOrder : newList){
            if (String.isNotBlank(newMxOrder.Case__c)){
                if (existingCaseIds.contains(newMxOrder.Case__c)){
                    newMxOrder.addError(String.format(VALIDATION_MX_ORDER_ALREADY_GENERATED, new List<String>{ newMxOrder.Case__c }));
                    newMxOrder.Case__c.addError(String.format(VALIDATION_MX_ORDER_ALREADY_GENERATED, new List<String>{ newMxOrder.Case__c }));
                }
            }
        }        
    }
    /**
     * @description Override inbound status 'labeled' with status as 'shipped', if a tracking number is available in the Order Update payload
     * This is specific to P0 Social Mobile Integration
     * In P0, the following status is not received from the Vendor
     * - shipped
     * - delivered
     * If the Order Id on new Order generation is not blank (example: existing Cases for Denali that are already submitted), then set the status to 'new'
     * - exclude the Order where the Status is already preset
     * @param List<Mx_Order__c> newList
     * @param Map<Id, Mx_Order__c> oldMap
     * @param Map<Id, Case> cases
     * @return
     */  
    public static void overrideStatusIfNecessary(List<Mx_Order__c> newList, Map<Id, Mx_Order__c> oldMap, Map<Id, Case> cases){
        for (Mx_Order__c order : newList){
            if (CDdMxSxConstants.MX_ORDER_STATUS_LABELED.equals(order.Order_Status__c) && String.isNotBlank(order.Shipping_Tracking_Number__c)){
                order.Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_SHIPPED;                               
            }
            if (Trigger.isInsert && String.isNotBlank(order.Order_Id__c) && String.isBlank(order.Order_Status__c)){
                order.Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_NEW;
            }
            if (Trigger.isUpdate && CDdMxSxConstants.MX_ORDER_STATUS_NEW.equals(order.Order_Status__c)){
                if (String.isNotBlank(order.Case__c) && cases.containsKey(order.Case__c) && CDdMxSxConstants.REQUEST_TYPES_CI_MAINTENANCE.contains(cases.get(order.Case__c).Request_Type__c) && CDdMxSxConstants.MX_VENDOR_DENALI.equals(order.Vendor__c)){
                    order.Order_Id__c = String.valueOf(CDdMxSxConstants.getRandomInteger());
                }
            }
            if (Trigger.isUpdate && CDdMxSxConstants.MX_ORDER_STATUS_SHIPPED.equals(order.Order_Status__c) && oldMap.containsKey(order.Id) && CDdMxSxConstants.MX_ORDER_STATUS_DELIVERED.equals(oldMap.get(order.Id).Order_Status__c)){
                order.Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_DELIVERED;
                order.Order_Status_Last_Modified_Date__c = oldMap.get(order.Id).Order_Status_Last_Modified_Date__c;
            }
        }
    }        
    /**
     * @description Set the Shipping Carrier on the Mx Order
     * @param List<Mx_Order__c> newList
     * @param Map<Id, Mx_Order__c> oldMap
     * @return
     */  
    public static void setShippingCarrier(List<Mx_Order__c> newList, Map<Id, Mx_Order__c> oldMap){
        for (Mx_Order__c order : newList){
            if (String.isNotBlank(order.Shipping_Carrier__c)){
                String shippingCarrierNewValue = order.Shipping_Carrier__c.toLowerCase();
                for (String shippingCarrierMappingValue : CDdMxSxConstants.MX_SHIPPING_CARRIER_MAPPING_VALUES.keySet()){
                    if (shippingCarrierNewValue.contains(shippingCarrierMappingValue)){
                        order.Shipping_Carrier__c = CDdMxSxConstants.MX_SHIPPING_CARRIER_MAPPING_VALUES.get(shippingCarrierMappingValue);
                    }                    
                }                               
            }
        }
    }
    /**
     * @description Handle Mx Order Request Updates
     * @param List<Mx_Order__c> newList
     * @param Map<Id, Mx_Order__c> oldMap
     * @return
     */    
    public static void handleMxOrderItemsUpdate(List<Mx_Order__c> newList, Map<Id, Mx_Order__c> oldMap){
        List<Mx_Order__c> mxOrdersForMxOrderItemsToDelete = new List<Mx_Order__c>();
        List<Mx_Order__c> mxOrdersForMxOrderItemsToInsert = new List<Mx_Order__c>();
        for (Mx_Order__c newSobject : newList){
            Mx_Order__c oldSobject = oldMap.get(newSobject.Id);
            if (CDdMxSxTriggerHelper.hasFieldValueChanged(newSobject, oldSobject, new Set<String>{'Mx_Order_Request__c','Language__c'})){
                mxOrdersForMxOrderItemsToDelete.add(oldSobject);
                mxOrdersForMxOrderItemsToInsert.add(newSobject);
            }
        }
        deleteMxOrderItems(mxOrdersForMxOrderItemsToDelete);
        insertMxOrderItems(mxOrdersForMxOrderItemsToInsert);        
    }
    /**
     * @description Handle Mx Order Status Updates
     * @param List<Mx_Order__c> newList
     * @param Map<Id, Mx_Order__c> oldMap
     * @return
     */    
    public static void handleMxOrderStatusUpdate(List<Mx_Order__c> newList, Map<Id, Mx_Order__c> oldMap){
        List<Mx_Order__c> mxOrdersToProcess = new List<Mx_Order__c>();
        for (Mx_Order__c newMxOrder : newList){
            if (oldMap == null || !oldMap.containsKey(newMxOrder.Id) || (CDdMxSxTriggerHelper.hasFieldValueChanged(newMxOrder, oldMap.get(newMxOrder.Id), CDdMxSxConstants.MX_ORDER_FIELD_API_NAME_STATUS))){ 
                mxOrdersToProcess.add(newMxOrder); 
            }
        }
        if (!mxOrdersToProcess.isEmpty()){
            CDdMxOrderEventHelper.publishMxOrderEvents(mxOrdersToProcess);
        }
    }    
    /**
     * @description Insert the Mx Order Item records for the input Mx Orders
     * @param List<Mx_Order__c> mxOrders
     * @return
     */
    public static void insertMxOrderItems(List<Mx_Order__c> mxOrders){
        new CDdMxOrderItemHandler(mxOrders).insertOrderItems();
    }
    /**
     * @description Delete the Mx Order Item records for the input Mx Orders
     * @param List<Mx_Order__c> mxOrders
     * @return
     */
    public static void deleteMxOrderItems(List<Mx_Order__c> mxOrders){
        List<Mx_Order_Item__c> mxOrderItems = new List<Mx_Order_Item__c>();
        Set<Id> mxOrderIds = new Set<Id>();
        for (Mx_Order__c mxOrder : mxOrders){
            mxOrderIds.add(mxOrder.Id);
        }
        for (Mx_Order_Item__c mxOrderItem : [SELECT Id FROM Mx_Order_Item__c WHERE Mx_Order__c IN :mxOrderIds]){
            mxOrderItems.add(mxOrderItem);
        }
        delete mxOrderItems;
    }
    /**
     * @description Insert the shipment records for the input Mx Orders
     * @param List<Mx_Order__c> mxOrders
     * @param Map<Id, Mx_Order__c> oldmxOrders
     * @return
     */
    public static void handleInsertShipmentRecords(List<Mx_Order__c> newMxOrders, Map<Id, Mx_Order__c> oldMxOrders){
        if(!CDdMxSxConstants.isDisabled(DISABLE_SHIPMENT_TRACKING_SETTING)){
            List<Mx_Order__c> mxOrdersToProcess = new List<Mx_Order__c>();
            for (Mx_Order__c newMxOrder : newMxOrders){
                Mx_Order__c oldMxOrder = (oldMxOrders != null ? oldMxOrders.get(newMxOrder.Id) : null);
                if(String.isNotBlank(newMxOrder.Shipping_Tracking_Number__c) && oldMxOrder != null && String.isBlank(oldMxOrder.Shipping_Tracking_Number__c)){
                    mxOrdersToProcess.add(newMxOrder);
                }
            }
            if (!mxOrdersToProcess.isEmpty()){
                new CDdMxOrderShipmentService(mxOrdersToProcess).createShipments();
            }
        }
    }
    /**
     * @description Send the Mx Orders to the Mx Order Processor via the Mx Order Event framework
     * @param List<Mx_Order__c> newList
     * @return
     */    
    public static void publishEventsSendMxOrderToVendor(List<Mx_Order__c> newList){
        Set<Id> mxOrderIds = new Set<Id>();
        for (Mx_Order__c mxOrder : newList){
            mxOrderIds.add(mxOrder.Id);
        }
        CDdMxSxEventPublisher.publishEventsSendMxOrderToVendor(CDdMxSxConstants.SOBJECT_TYPE_MX_ORDER, mxOrderIds);
    }
}