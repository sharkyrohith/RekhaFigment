/********************************************************************************************************************
* @author Sriram
* @date 03/10/2022
*
* @group Merchant Services
*
* @description Apex class that publishes Merchant Order events         
*
**************************************************************************************************************************************/
public class CDdMxOrderEventPublisher {
    public static String CLASS_NAME = 'CDdMxOrderEventPublisher';
    /**
     * @description instance variable here
     */
    List<Mx_Order_Event__e> events = new List<Mx_Order_Event__e>();
    String sObjectType;
    /**
     * @description Use this constructor to work with the following events
     * - GENERATE_MX_ORDER (applicable for sObject Type 'Case' and record type 'Tablet_Requests')
     * - QUEUE_MX_ORDER (applicable for sObject Type 'Mx_Order__c')
     * - UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE (applicable for sObject Type 'Account')
     * - UPDATE_CASE_FOR_ORDER_ITEM_PRINTER (applicable for sObject Type 'Mx_Order_Item__c')
     * - UPDATE_CASE_FOR_ORDER_ITEM_PRINTER (applicable for sObject Type 'Mx_Order_Item__c')
     */
    public CDdMxOrderEventPublisher(CDdMxOrderEventEnum event, String sObjectType, List<SObject> sObjects){
        this.sObjectType = sObjectType;
        this.addMxOrderEvents(event, sObjectType, sObjects);
    }
    /**
     * @description Use this constructor to work with the following sObject Update Events
     * - UPDATE_CASE_FOR_MX_ORDER_CANCELLED
     * - UPDATE_CASE_FOR_MX_ORDER_CONFIGURED
     * - UPDATE_CASE_FOR_MX_ORDER_DELIVERED
     * - UPDATE_CASE_FOR_MX_ORDER_FAILED
     * - UPDATE_CASE_FOR_MX_ORDER_INVALID
     * - UPDATE_CASE_FOR_MX_ORDER_LABELED
     * - UPDATE_CASE_FOR_MX_ORDER_NEW
     * - UPDATE_CASE_FOR_MX_ORDER_OPEN
     * - UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED
     * - UPDATE_CASE_FOR_MX_ORDER_PICKED
     * - UPDATE_CASE_FOR_MX_ORDER_SHIPPED
     * - UPDATE_CASE_FOR_MX_ORDER_VALIDATED
     * - UPDATE_CASE_FOR_SETUP_STORE_COMPLETE
     * - UPDATE_MX_ORDER_FOR_CASE_RECEIVED
     * - UPDATE_MX_ORDER_FOR_CASE_SHIPPED
     * - UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE
     */
    public CDdMxOrderEventPublisher(String sObjectType, List<SObject> sObjects){
        this.sObjectType = sObjectType;
        this.addMxOrderEvents(sObjectType, sObjects);
    }
    public void publish(){
        if (!this.events.isEmpty()){
            List<Database.SaveResult> sResults = EventBus.publish(this.events);
            CDdErrorUtilities.publishException(this.sObjectType, CLASS_NAME, sResults);          
        }        
    }
    /**
     * @description Add the Mx Order events for sObjects
     * A pre-determined event is sent as input to this method
     * Pre-determined events are as follows:
     * - GENERATE_MX_ORDER (applicable for sObject Type 'Case' and record type 'Tablet_Requests')
     * - QUEUE_MX_ORDER (applicable for sObject Type 'Mx_Order__c')
     * - UPDATE_NONQUEUED_MX_ORDER_FOR_ACCOUNT_UPDATE (applicable for sObject Type 'Account')
     * - UPDATE_CASE_FOR_ORDER_ITEM_PRINTER (applicable for sObject Type 'Mx_Order_Item__c')
     * - UPDATE_CASE_FOR_ORDER_ITEM_PRINTER (applicable for sObject Type 'Mx_Order_Item__c')
     * Note: Applicable sObjects -  Account (On Update)
     *                              Case (On Insert Only) 
     *                              Mx_Order__c (On approval && Mx Order Validated && Ready to be queued) 
     *                              Mx_Order_Item__c (when identifiers are updated)
     * @param CDdMxOrderEventEnum event
     * @param String sourceSObjectType
     * @param List<sObject> sObjects
     * @return 
    */
    private void addMxOrderEvents(CDdMxOrderEventEnum event, String sourceSObjectType, List<sObject> sourcesSObjects) {
        if (sourcesSObjects!=null && !sourcesSObjects.isEmpty()){
            Map<Id, sObject> sourceSObjectMap = convertListToMap(sourcesSObjects);
            for (SObject sourceSObject : sourceSObjectMap.values()){
                addMxOrderEvent(event, sourceSObjectType, sourceSObject);
            }
        }
    }         
    /**
     * @description Add the Mx Order events for input Collection of sObjects 
     * Following Mx Order Events are derived based on the current 'status' of the Source sObject
     * - UPDATE_CASE_FOR_MX_ORDER_CANCELLED
     * - UPDATE_CASE_FOR_MX_ORDER_CONFIGURED
     * - UPDATE_CASE_FOR_MX_ORDER_DELIVERED
     * - UPDATE_CASE_FOR_MX_ORDER_FAILED
     * - UPDATE_CASE_FOR_MX_ORDER_INVALID
     * - UPDATE_CASE_FOR_MX_ORDER_LABELED
     * - UPDATE_CASE_FOR_MX_ORDER_NEW
     * - UPDATE_CASE_FOR_MX_ORDER_OPEN
     * - UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED
     * - UPDATE_CASE_FOR_MX_ORDER_PICKED
     * - UPDATE_CASE_FOR_MX_ORDER_SHIPPED
     * - UPDATE_CASE_FOR_MX_ORDER_VALIDATED
     * - UPDATE_CASE_FOR_SETUP_STORE_COMPLETE
     * - UPDATE_MX_ORDER_FOR_CASE_RECEIVED
     * - UPDATE_MX_ORDER_FOR_CASE_SHIPPED
     * - UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE
     * Applicable sObjects that participate in the Mx Order event framework based on 'status' are as follows:
     * - Case
     * - Mx_Order__c
     * @param String sObjectType
     * @param List<sObject> sObjects
     * @return 
    */
    private void addMxOrderEvents(String sourceSObjectType, List<sObject> sourcesSObjects) {
        if (sourcesSObjects!=null && !sourcesSObjects.isEmpty()){
            Map<Id, sObject> sourceSObjectMap = convertListToMap(sourcesSObjects);
            for (SObject sourceSObject : sourceSObjectMap.values()){
                CDdMxOrderEventEnum event = CDdMxOrderEventConfig.getMxOrderEvent(sourceSObjectType, sourceSObject);
                addMxOrderEvent(event, sourceSObjectType, sourceSObject);
            }
        }
    }
    /**
     * @description Check for validity of Mx Order Event prior to adding the event for publishing
     */
    private void addMxOrderEvent(CDdMxOrderEventEnum event, String sourceSObjectType, SObject sourceSObject){
        if (CDdMxOrderEventConfig.isValidMxOrderEvent(event, sourceSObjectType, sourceSObject)){
            this.events.add(getNewInstanceOfMxOrderEvent(event, sourceSObjectType, sourceSObject));
        }
    }   
    /**
     * @description Convert Collection of sObjects to Map
     * @param List<sObject> sObjects
     * @return Map<Id, sObject>
     */
    private Map<Id, sObject> convertListToMap(List<sObject> sObjects){
        Map<Id, sObject> sObjMap = new Map<Id, sObject>();
        for (sObject sObj : sObjects){
            sObjMap.put(sObj.Id, sObj);
        }
        return sObjMap;
    }
    /**
     * @description Return a new instance of platform event Mx_Order_Event__e
     * @param CDdMxOrderEventEnum - Mx Order Event
     * @param String sourceSObjectType
     * @param String sourceSObject
     * @return Mx_Order_Event__e  
    */   
    private Mx_Order_Event__e getNewInstanceOfMxOrderEvent(CDdMxOrderEventEnum event, String sourceSObjectType, SObject sourceSObject){
        return new Mx_Order_Event__e(
            Event_Name__c = CDdMxOrderEventEnumHelper.toString(event),
            SObjectType__c = sourceSObjectType,
            SObject_Id__c = sourceSObject.Id
        );       
    }
 }