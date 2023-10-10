/********************************************************************************************************************
* @author Raju
* @date Dec 2022
* @description This trigger is a subscriber to the 'API Logger' platform event
*
*********************************************************************************************************************/
trigger ApiLoggerEventTrigger on API_Logger__e (after insert) {
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            ApiLoggerService.log(trigger.new);
        }
    }
}