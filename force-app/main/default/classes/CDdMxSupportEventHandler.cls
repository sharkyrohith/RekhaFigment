/********************************************************************************************************************
* @author Veera
* @date 04/28/2022
*
* @group Merchant Services
*
* @description Apex class that handles processing for Merchant Support events         
*
**************************************************************************************************************************************/
public class CDdMxSupportEventHandler {
    
    /* @description: Invoked by the CDdMxSupportEventSubscriber class to handle the events
    *                handleEvents method in Instance class method will be called
    */
    public static void handleEvents(CDdMxSupportEventEnum event, String sObjectType, Set<Id> sObjectIds){
        CDdMxSupportEventConfig.getMxSupportInstance(event).handleEvents(sObjectType, sObjectIds);
    }

}