/********************************************************************************************************************
* @author Praveen
* @date 08/10/2022
*
* @group Merchant Services
*
* @description CDdMxOrderItemHandler is to create order items for mx Order. It will be called from mxorder trigger and Equipment request UI controller.
*
**************************************************************************************************************************************/
public with sharing class CDdMxOrderItemHandler {
    private Map<Id, List<Mx_Order_Request_Product__c>> mxProductsByMxOrderRequestId;
    private Map<Id, Mx_product__c> productMapById;
    private List<Mx_Order_Item__c> mxOrderItems;
    /**
    * @description instiate the class from Equipment request UI to create mx order items.
    * @param List<Mx_Order__c> mxOrders
    * @param Map<Id, List<String>> prodIdsByOrderIdMap
    * @param String defectTabletIMEI
    * @param String DefectPrinterIMEI
    * @return
    */
    public CDdMxOrderItemHandler(List<Mx_Order__c> mxOrders, Map<Id, List<String>> prodIdsByOrderIdMap, String defectTabletIMEI, String DefectPrinterIMEI) {
        this.mxOrderItems = new List<Mx_Order_Item__c>();
        this.getProducts();
        for (Mx_Order__c mxOrder : mxOrders) {
            this.GetOrderItemsbyProductIds(mxOrder, prodIdsByOrderIdMap.get(mxOrder.Id), defectTabletIMEI, DefectPrinterIMEI);
        }
    }
    /**
    * @description Instantiate the class from Mxorder trigger to Insert the Mx Order Item records for the input Mx Orders
    * @param List<Mx_Order__c> mxOrders
    * @return
    */
    public CDdMxOrderItemHandler(List<Mx_Order__c> mxOrders) {
        mxOrderItems = new List<Mx_Order_Item__c>();
        Map<id, Mx_Order__c> mxOrderMap = new Map<id, Mx_Order__c>();
        Map<Id, Set<Id>> mxOrderIdsByMxOrderRequestId = new Map<Id, Set<Id>>();
        Map<Id, Case> cases = CDdMxSxQueryCases.getCases(CDdMxSxQueryCases.getCaseIds(mxOrders)); 
        getMxOrderIdsByMxOrderRequestId(mxOrders, mxOrderIdsByMxOrderRequestId, mxOrderMap, cases);
        getMxOrderRequestProducts(mxOrderIdsByMxOrderRequestId.keySet());
        // Iterate over the Mx Order Request Identifiers
        for (Id mxOrderRequestId : mxOrderIdsByMxOrderRequestId.keySet()) {            
            // - In the first level child loop, iterate over the Mx Order Identifiers for a specific Mx Order Request Identifier
            if(mxProductsByMxOrderRequestId.containskey(mxOrderRequestId)){
                for (Id mxOrderId : mxOrderIdsByMxOrderRequestId.get(mxOrderRequestId)) {
                    Mx_Order__c mxOrder = mxOrderMap.get(mxOrderId);
                    Case cas = cases.ContainsKey(mxOrder.case__c) ? cases.get(mxOrder.case__c) : new case();
                    GetOrderItemsbyRequestType(mxProductsByMxOrderRequestId.get(mxOrderRequestId), mxOrder, cas);
                }
            }
        }
    }
    /**
    * @description Organize Mx Order Identifiers by Mx Order Request by mx Order
    * @param List<Mx_Order__c> mxOrders
    * Map<Id, Set<Id>> mxOrderIdsByMxOrderRequestId
    * Map<id, Mx_Order__c> mxOrderMap
    * @return
    */
    private void getMxOrderIdsByMxOrderRequestId(List<Mx_Order__c> mxOrders, Map<Id, Set<Id>> mxOrderIdsByMxOrderRequestId, Map<id, Mx_Order__c> mxOrderMap, Map<Id, Case> cases) {
        for (Mx_Order__c mxOrder : mxOrders) {
            mxOrderMap.put(mxOrder.Id, mxOrder);
            Case cas = cases.ContainsKey(mxOrder.case__c) ? cases.get(mxOrder.case__c) : new case();
            Boolean isSupportCase = CDdMxSxCaseOriginHandler.isEquipmentRequestSupportCase(cas.origin);
            if (String.isNotBlank(mxOrder.Mx_Order_Request__c) && !isSupportCase) {
                if (mxOrderIdsByMxOrderRequestId.containsKey(mxOrder.Mx_Order_Request__c)) {
                    mxOrderIdsByMxOrderRequestId.get(mxOrder.Mx_Order_Request__c).add(mxOrder.Id);
                } else {
                    mxOrderIdsByMxOrderRequestId.put(mxOrder.Mx_Order_Request__c, new Set<Id>{ mxOrder.Id });
                }
            }
        }
    }
    /**
    * @description  Run query to fetch the product family details for tablet request.
    * @return
    */
    private void getProducts() {
        productMapById = new Map<Id, Mx_product__c>([SELECT id, Family__c FROM Mx_product__c limit 1000]);
    }
    /**
    * @description getMxOrderRequestProducts by order request ids.
    * @param set<Id> orderRequests
    * @return
    */
    private void getMxOrderRequestProducts(set<Id> orderRequests) {
        // Organize Mx Product Identifiers by Mx Order Request Identifier
        mxProductsByMxOrderRequestId = new Map<Id, List<Mx_Order_Request_Product__c>>();
        for (Mx_Order_Request_Product__c p : [
            SELECT Id, Mx_Order_Request__c, Mx_Product__c, Mx_Product__r.Language__c, Mx_Product__r.Family__c
            FROM Mx_Order_Request_Product__c
            WHERE Mx_Order_Request__c IN :orderRequests AND Mx_Order_Request__r.Is_Active__c = TRUE
        ]) {            
            if (mxProductsByMxOrderRequestId.containsKey(p.Mx_Order_Request__c)) {
                mxProductsByMxOrderRequestId.get(p.Mx_Order_Request__c).add(p);
            } else {
                mxProductsByMxOrderRequestId.put(p.Mx_Order_Request__c, new List<Mx_Order_Request_Product__c>{ p });
            }
        }
    }
    
    /**
    * @description If the order is creating from equipment request case. create the order items for selected products only.
    * @param mxOrder and details.
    * @return List<Mx_Order_Item__c>
    */
    private void GetOrderItemsbyProductIds(Mx_Order__c mxOrder, List<String> productIds, String defectTabletIMEI, String defectPrinterIMEI) {
        Set<String> orderTypes = new Set<String>{CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN,CDdMxSxConstants.TYPE_OF_MX_ORDER_REPLACEMENT};
        for (String mxProductId : productIds) {
            if (productMapById.containsKey(mxProductId)) {
                String identifier = '';
                // assign identifier based on the product family.
                if (orderTypes.contains(mxOrder.Type_Of_Mx_Order__c)) {
                    String productFamily = productMapById.get(mxProductId).Family__c;
                    identifier = productFamily == CDdMxSxConstants.MX_PRODUCT_FAMILY_TABLET
                        ? defectTabletIMEI
                        : productFamily == CDdMxSxConstants.MX_PRODUCT_FAMILY_PRINTER ? defectPrinterIMEI : '';
                }
                mxOrderItems.add(createOrderItemInstance(mxOrder.Id, mxProductId, identifier));
            }
        }
    }
    /**
    * @description create order item instance for insert.
    * @param orderId, mxProductId and identifier.
    * @return Mx_Order_Item__c
    */
    private Mx_Order_Item__c createOrderItemInstance(Id orderId, id mxProductId, String identifier) {
        return new Mx_Order_Item__c(Mx_Order__c = orderId, Mx_Product__c = mxProductId, Identifier__c = identifier, Quantity__c = 1);
    }
    /**
    * @description GetOrderItemsbyRequestType 
    * @param List<Mx_Order_Request_Product__c> mxOrderRequestProducts
    * @param Mx_Order__c mxOrder
    * @return
    */
    private void GetOrderItemsbyRequestType(List<Mx_Order_Request_Product__c> mxOrderRequestProducts, Mx_Order__c mxOrder, case cs) {
        for (Mx_Order_Request_Product__c orp : mxOrderRequestProducts) {
            if(CDdMxSxConstants.PRODUCT_TYPE_FAMILY_MARKETING_KIT.equals(orp.Mx_Product__r.Family__c) && !cs.include_marketing_kit__c){
                continue;
            }            
            if (String.isNotBlank(orp.Mx_Product__r.Language__c)) {                
                if (String.isNotBlank(mxOrder.Language__c)) {                    
                    if (mxOrder.Language__c.equals(orp.Mx_Product__r.Language__c)){                        
                        mxOrderItems.add(createOrderItemInstance(mxOrder.Id, orp.Mx_Product__c, ''));
                    }
                }
            } else {
                mxOrderItems.add(createOrderItemInstance(mxOrder.Id, orp.Mx_Product__c, ''));
            }
        }
    }
    /**
    * @description Insert the Mx Order Item records for the input Mx Orders
    * @return
    */
    public void insertOrderItems() {
        insert mxOrderItems;
    }
}