/********************************************************************************************************************
* @author Ganesh
* @date 10/27/2022
*
* @group Trigger Handler
*
* @description Trigger handler for Campaign Item object
**************************************************************************************************************************************/
public class CDdCampaignItemTriggerHandler {
        
    /**
    * @description Before insert trigger event
    */
    public void beforeInsert(List<Campaign_Item__c> newList) {
      
    }
    /**
    * @description After insert trigger event
    */
    public void afterInsert(Map<Id, Campaign_Item__c> newMap) {
      
    }
    /**
    * @description Before update trigger event
    */
    public void beforeUpdate(Map<Id, Campaign_Item__c> newMap, Map<Id, Campaign_Item__c> oldMap) {
        CDdCampaignItemTriggerHelper.updateOwnerOnCBChange(newMap, oldMap);
    }    
    /**
    * @description After update trigger event
    */
    public void afterUpdate(Map<Id, Campaign_Item__c> newMap, Map<Id, Campaign_Item__c> oldMap) {
    }
    /**
    * @description before delete trigger event
    */
    public void beforeDelete (Map<Id, Campaign_Item__c> oldMap) {
        
    }
    /**
    * @description after delete trigger event
    */
    public void afterDelete (Map<Id, Campaign_Item__c> oldMap) {
        
    }
     
}