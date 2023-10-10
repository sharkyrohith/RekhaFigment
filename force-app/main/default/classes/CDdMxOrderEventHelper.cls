/********************************************************************************************************************
* @author Sriram
* @date 03/21/2022
*
* @group Merchant Services
*
* @description Helper methods for processing Mx Order Events are defined here
*
**************************************************************************************************************************************/
public class CDdMxOrderEventHelper {
    /**
     * @description Return the eligible Record Type Ids for the input Source SObject Type, to allow for processing related to Mx Orders
     * @param String sourceSObjectType
     * @return Set<Id> Return a Collection of Record Type Ids to allow for processing related to Mx Orders
     */
    public static Set<Id> getSourceSObjectRecordTypeIds(String sourceSObjectType){
        return CDdMxOrderEventConfig.getSourceSObjectRecordTypeIds(sourceSObjectType);
    }
    /**
     * @description Return the applicable status values for an SObject Type pertaining to a Mx Order Event
     * @param String sourceSObjectType
     * @param CDdMxOrderEventEnum event
     * @return Set<String> Collection of status values
     */
    public static Set<String> getSourceSObjectStatusValues(String sourceSObjectType, CDdMxOrderEventEnum event){
        return CDdMxOrderEventConfig.getSourceSObjectStatusValues(sourceSObjectType, event);
    }
    /**
     * @description Return a Collection of Changed Fields on the Source SObject associated with the Merchant Order Event Enum 
     * @param CDdMxOrderEventEnum mxOrderEventEnum
     * @return List<String>
     */
    public static List<String> getSourceChangedFields(CDdMxOrderEventEnum event){
        return CDdMxOrderEventConfig.getSourceChangedFields(event);
    }
    /**
     * @description Publish Generate Mx Order Events for new Case records
     * @param List<Case> newCases
     * @return Boolean
     */    
    public static Boolean publishGenerateMxOrderEvents(List<Case> newCases){
        if (!CDdMxSxConstants.GENERATE_MX_ORDER) { return true; }
        new CDdMxOrderEventPublisher(CDdMxOrderEventEnum.GENERATE_MX_ORDER, CDdMxSxConstants.SOBJECT_TYPE_CASE, newCases).publish();
        return true;
    }
    /**
     * @description Publish Mx Order Item events related to tablet updates
     * @param LList<Mx_Order_Item__c> mxOrderItems
     * @return Boolean
     */    
    public static Boolean publishMxOrderItemTabletEvents(List<Mx_Order_Item__c> mxOrderItems){
        new CDdMxOrderEventPublisher(CDdMxOrderEventEnum.UPDATE_CASE_FOR_ORDER_ITEM_TABLET, CDdMxSxConstants.SOBJECT_TYPE_MX_ORDER_ITEM, mxOrderItems).publish();
        return true;
    }
    /**
     * @description Publish Mx Order Item events related to printer updates
     * @param List<Mx_Order_Item__c> mxOrderItems
     * @return Boolean
     */    
    public static Boolean publishMxOrderPrinterEvents(List<Mx_Order_Item__c> mxOrderItems){
        new CDdMxOrderEventPublisher(CDdMxOrderEventEnum.UPDATE_CASE_FOR_ORDER_ITEM_PRINTER, CDdMxSxConstants.SOBJECT_TYPE_MX_ORDER_ITEM, mxOrderItems).publish();
        return true;
    }            
    /**
     * @description Publish relevant Mx Order Events for updated Case records
     * @param List<Case> newCases
     * @param List<Case> oldMap
     * @return Boolean
     */    
    public static Boolean publishMxOrderEvents(List<Case> newCases, Map<Id, Case> oldMap){
        Map<CDdMxOrderEventEnum, List<Case>> mxOrderEvents = new Map<CDdMxOrderEventEnum, List<Case>>();
        Set<Id> approvedCaseIds = new Set<Id>();
        Set<Id> caseIdsToProcess = new Set<Id>();
        Map<Id, Mx_Order__c> mxOrdersToProcessByCaseId = new Map<Id, Mx_Order__c>();
        Boolean publishedMxOrderEvents = false;
        for (Case newCase : newCases) {      
            Case oldCase = oldMap.get(newCase.Id);
            if (CDdMxSxConstants.CASE_STATUS_APPROVED.equals(newCase.Status) && (CDdMxSxTriggerHelper.hasFieldValueChanged(newCase, oldCase, CDdMxSxConstants.CASE_FIELD_API_NAME_STATUS))){
                approvedCaseIds.add(newCase.Id);
            }            
            CDdMxOrderEventEnum event = CDdMxOrderEventConfig.getMxOrderEvent(CDdMxSxConstants.SOBJECT_TYPE_CASE, newCase);
            if (event != null && ((CDdMxSxTriggerHelper.hasFieldValueChanged(newCase, oldCase, new Set<String>(getSourceChangedFields(event)))) || new Set<String>{CDdMxSxConstants.CASE_STATUS_SHIPPED, CDdMxSxConstants.CASE_STATUS_RECEIVED}.contains(newCase.Status))){    
                addMxOrderEvent(mxOrderEvents, event, newCase);
                caseIdsToProcess.add(newCase.Id);                                                        
            }
        }
        for (Mx_Order__c mxOrder : [SELECT Id, Order_Id__c, Case__c, Vendor__c FROM Mx_Order__c WHERE Case__c IN :caseIdsToProcess]){
            Boolean processMxOrder = String.isBlank(mxOrder.Order_Id__c);
            processMxOrder = CDdMxSxConstants.MX_VENDOR_DENALI.equals(mxOrder.Vendor__c) || processMxOrder;
            if (processMxOrder){ 
                mxOrdersToProcessByCaseId.put(mxOrder.Case__c, mxOrder);
            }
        } 
        for (CDdMxOrderEventEnum event : mxOrderEvents.keySet()){
            List<Case> casesToProcess = mxOrderEvents.get(event);
            switch on event {
                when UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE {
                    List<Case> casesWithOpenMxOrder = new List<Case>();
                    for (Case c : casesToProcess){
                        if (mxOrdersToProcessByCaseId.containsKey(c.Id)){
                            casesWithOpenMxOrder.add(c);
                        }
                    }
                    if (!casesWithOpenMxOrder.isEmpty()){
                        new CDdMxOrderEventPublisher(CDdMxSxConstants.SOBJECT_TYPE_CASE, casesWithOpenMxOrder).publish();
                        publishedMxOrderEvents = true;
                    }
                }
                when UPDATE_MX_ORDER_FOR_CASE_SHIPPED {
                    CDdMxSxEventPublisher.publishEventsTabletCaseShipped(CDdMxSxConstants.SOBJECT_TYPE_CASE, new Map<Id,Case>(casesToProcess).keySet());
                    new CDdMxOrderEventPublisher(CDdMxSxConstants.SOBJECT_TYPE_CASE, casesToProcess).publish();
                    publishedMxOrderEvents = true;
                }
                when UPDATE_MX_ORDER_FOR_CASE_RECEIVED {
                    CDdMxSxEventPublisher.publishEventsTabletCaseReceived(CDdMxSxConstants.SOBJECT_TYPE_CASE, new Map<Id,Case>(casesToProcess).keySet());
                    new CDdMxOrderEventPublisher(CDdMxSxConstants.SOBJECT_TYPE_CASE, casesToProcess).publish();
                    publishedMxOrderEvents = true;
                }                
            }
        }
        if (!approvedCaseIds.isEmpty()){
            CDdMxSxEventPublisher.publishEventsSendMxOrderToVendor(CDdMxSxConstants.SOBJECT_TYPE_CASE, approvedCaseIds);
            publishedMxOrderEvents = true;
        }
        return publishedMxOrderEvents;                                               
    }
    /**
     * @description Publish Mx Order Events for updates to Mx Order records
     * @param List<Mx_Order__c> newList
     * @return Boolean
     */    
    public static Boolean publishMxOrderEvents(List<Mx_Order__c> newList){
        new CDdMxOrderEventPublisher(CDdMxSxConstants.SOBJECT_TYPE_MX_ORDER, newList).publish();
        return true;
    }    
    private static void addMxOrderEvent(Map<CDdMxOrderEventEnum, List<Case>> mxOrderEvents, CDdMxOrderEventEnum event, Case newCase){
        if (mxOrderEvents.containsKey(event)){
            mxOrderEvents.get(event).add(newCase);
        } else {
            mxOrderEvents.put(event, new List<Case> { newCase });
        }
    }        
    /**
     * @description Return the Merchant Order Request record for the input Case Request Type and the corresponding Account Billing Country Code
     * @param String requestType (Case.Request_Type__c)
     * @param String countryCode (Account.BillingCountryCode)
     * @return Mx_Order_Request__c Return Merchant Order Request record
     */    
    public static Mx_Order_Request__c getMxOrderRequest(String requestType, String countryCode){
        Mx_Order_Request__c retVal = null;
        if (String.isNotBlank(requestType) && String.isNotBlank(countryCode)){
            for (Mx_Order_Request__c request : CDdMxOrderEventConfig.MX_ORDER_REQUEST_MAP.values()){
                if (requestType.equals(request.Request_Type__c) && countryCode.equals(request.Country_Code__c)){
                    retVal = request;
                }
            }
        }
        return retVal;
    }
}