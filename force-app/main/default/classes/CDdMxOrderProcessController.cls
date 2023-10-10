public without sharing class CDdMxOrderProcessController {
    @AuraEnabled
    public static void processMxOrder(Id caseId){
        Case caseToProcess = null;
        Boolean hasMxOrder = false;
        for (Case c : [  SELECT Id, RecordTypeId, Status, (SELECT Id, Case__c FROM Mx_Orders__r) 
                                    FROM Case
                                    WHERE Id = :caseId]){
            caseToProcess = c;
            hasMxOrder = !c.Mx_Orders__r.isEmpty();
        }
        if (!hasMxOrder){
            CDdMxOrderEventHelper.publishGenerateMxOrderEvents(new List<Case> { caseToProcess });
        } else {
            new CDdMxOrderProcessor(CDdMxSxConstants.SOBJECT_TYPE_CASE, new Set<Id>{ caseId }).execute();
        }
    }
    @AuraEnabled
    public static MxOrder getMxOrder(Id caseId){
        Mx_Order__c mxOrder = null;
        for (Mx_Order__c order : [  SELECT Id, Case__c, Order_Id__c, Vendor__c, Order_Status__c, Order_Status_Description__c, Order_Status_Last_Modified_Date__c 
                                    FROM Mx_Order__c
                                    WHERE Case__c = :caseId]){
            mxOrder = order;
        }
        return mxOrder!=null ? new MxOrder(mxOrder) : null;        
    }
    public class MxOrder {
        @AuraEnabled
        public String orderId { get; set;}
        @AuraEnabled
        public String vendor { get; set;}        
        @AuraEnabled
        public String orderStatus { get; set;}
        @AuraEnabled
        public String orderStatusDescription { get; set;}
        @AuraEnabled
        public DateTime orderStatusLastModifiedDate { get; set; }              
        public MxOrder(Mx_Order__c o){
            this.orderId = o.Order_Id__c;
            this.vendor = o.Vendor__c;
            this.orderStatus = o.Order_Status__c;
            this.orderStatusDescription = o.Order_Status_Description__c;
            this.orderStatusLastModifiedDate = o.Order_Status_Last_Modified_Date__c;
        }
    }    
}