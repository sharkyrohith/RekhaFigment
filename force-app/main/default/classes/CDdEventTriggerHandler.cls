/********************************************************************************************************************
* @author Venkat D
* @date 08/02/2022
*
* @group Trigger Handler
*
* @description Trigger handler for Event object
**************************************************************************************************************************************/
public class CDdEventTriggerHandler {
    /**
    * @description Before insert trigger event
    */
    public void beforeInsert(List<Event> newList) {
    	
    }

    /**
    * @description After insert trigger event
    */
    public void afterInsert(Map<Id, Event> newMap) {
    	CDdEventHelper.processPreSaleEvents(newMap);
    }

    /**
    * @description Before update trigger event
    */
    public void beforeUpdate(Map<Id, Event> newMap, Map<Id, Event> oldMap) {
        
    } 

    /**
    * @description After update trigger event
    */
    public void afterUpdate(Map<Id, Event> newMap, Map<Id, Event> oldMap) {
        CDdEventHelper.processPreSaleEvents(newMap);
    }

    /**
    * @description before delete trigger event
    */
    public void beforeDelete (Map<Id, Event> oldMap) {
        
    }

    /**
    * @description after delete trigger event
    */
    public void afterDelete (Map<Id, Event> oldMap) {
        
    }
}