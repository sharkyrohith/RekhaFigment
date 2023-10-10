/********************************************************************************************************************
* @author Veera
* @date 04/27/2022
*
* @group Merchant Services
*
* @description Apex class that publishes Merchant Support events       
* 
**************************************************************************************************************************************/
public with sharing class CDdMxSupportEventPublisher {
    public static String CLASS_NAME = 'CDdMxSupportEventPublisher';
    /**
     * @description instance variable here
     */
    List<Mx_Support_Event__e> events = new List<Mx_Support_Event__e>();
    String sObjectType;
    
     /**
     * @description method will be invoked by CDdMxSupportEventBatch to publish the events
     * @params: event       -    CDdMxSupportEventEnum
     *          sObjectType -    sObjectType to set event parameter
     *          sObjectIds  -    Record Ids for the object
     */
    public void publishEvents(CDdMxSupportEventEnum event, String sObjectType, Set<Id> sObjectIds){
        this.sObjectType = sObjectType;
        this.addMxSupportEvents(event, sObjectType, sObjectIds);
        publish();
    }

    private void publish(){
        if (!this.events.isEmpty()){
            List<Database.SaveResult> sResults = EventBus.publish(this.events);
            CDdErrorUtilities.publishException(this.sObjectType, CLASS_NAME, sResults);          
        }        
    }

    private void addMxSupportEvents(CDdMxSupportEventEnum event, String sourceSObjectType, Set<Id> sObjectIds) {
        if (sObjectIds!=null && !sObjectIds.isEmpty()){
            for (Id sObjectId : sObjectIds){
                this.events.add(getNewInstanceOfMxSupportEvent(event, sourceSObjectType, sObjectId));
            }
        }
    }      

    /**
     * @description retruns the Mx_Support_Event__e event instance
    */
    private Mx_Support_Event__e getNewInstanceOfMxSupportEvent(CDdMxSupportEventEnum event, String sourceSObjectType, Id sObjectId){
        return new Mx_Support_Event__e(
            Event_Name__c = event.name(),
            SObjectType__c = sourceSObjectType,
            SObjectId__c = sObjectId
        );       
    }
}