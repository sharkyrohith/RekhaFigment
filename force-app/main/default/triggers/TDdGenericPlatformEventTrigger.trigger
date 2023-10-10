/**
* @author Knick
* @description Trigger for Generic Platform Events
* @date 2020-07
*/
trigger TDdGenericPlatformEventTrigger on Generic_Platform_Event__e (after insert) {

    CDdGenericPlatformEventHelper.handleEvents(trigger.new);

}