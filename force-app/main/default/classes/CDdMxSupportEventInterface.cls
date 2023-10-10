/********************************************************************************************************************
* @author Veera
* @date 04/26/2022
*
* @group Merchant Services
*
* @description: Interface to define Mx Support Event
*               Must implement this interface to utilize Mx Support Event service
* 
**************************************************************************************************************************************/
public interface CDdMxSupportEventInterface {
    /** 
     * @description Return the Query Locator to the caller
     */
    Database.QueryLocator getQueryLocator();
    /**
     * @description This method should return the Enum type using the Sobject Type and Ids.
     * Can have validations specific to events
     */      
    void publishEvents(String sObjectType, Set<Id> sObjectIds);

    /** 
     * @description Implement this method to handle the events published by the CDdMxSupportEventBatch class
     */
    void handleEvents(String sObjectType, Set<Id> sObjectIds);
}