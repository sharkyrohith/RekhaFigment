public with sharing class CDdMxEquipmentOrderRequestModel {
    @AuraEnabled
    public string requestType{get; set;}
    @AuraEnabled
    public string orderId{get; set;}
    @AuraEnabled
    public List<CDdMxEquipmentOrderRequestProduct> mxOrderRequestProduct {get; set;}
    public CDdMxEquipmentOrderRequestModel(String requestTypes, Id orderId, List<Mx_Order_Request_Product__c> mxOrderRequestProductList, Account act) {
        this.requestType =  requestTypes;
        this.orderId=orderId;
        List<CDdMxEquipmentOrderRequestProduct> mxproducts = new List<CDdMxEquipmentOrderRequestProduct>();
        for(Mx_Order_Request_Product__c mxProduct:mxOrderRequestProductList ){
            if(CDdMxSxConstants.PRODUCT_TYPE_FAMILY_MARKETING_KIT.equals(mxProduct.Mx_Product__r.Family__c) && CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(act.RecordTypeId)){
                continue;
            } 
            String Language = String.isNotBlank(act.Language__c)?act.Language__c:'English';
            if(String.isBlank(mxProduct.Mx_Product__r.Language__c) || mxProduct.Mx_Product__r.Language__c == Language){
            CDdMxEquipmentOrderRequestProduct mxOrderRequestProduct = new  CDdMxEquipmentOrderRequestProduct(orderId, mxProduct);
            mxproducts.add(mxOrderRequestProduct);
            }
        }
        this.mxOrderRequestProduct = mxproducts;

    }
    public class CDdMxEquipmentOrderRequestProduct{
        @AuraEnabled
        public string orderId{get; set;}
        @AuraEnabled
        public string orderProductId{get; set;}
        @AuraEnabled
        public string productId{get; set;}
        @AuraEnabled
        public string productName{get; set;}
        @AuraEnabled
        public string productFamily{get; set;}
        public CDdMxEquipmentOrderRequestProduct(String orderId,Mx_Order_Request_Product__c mxOrderRequestProduct) {
            this.orderId = orderId;
            this.orderProductId = mxOrderRequestProduct.Id;
            this.productId = mxOrderRequestProduct.Mx_Product__c;
            this.productName = mxOrderRequestProduct.Mx_Product__r.Name+' - '+mxOrderRequestProduct.Mx_Product__r.Family__c ;
            this.productFamily = mxOrderRequestProduct.Mx_Product__r.Family__c;
        }
     
    }
}