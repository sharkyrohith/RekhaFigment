/**
  * @author:Mahesh C
  * @date  08/05/2021
  * @decription: Trigger for User Nesting Platform Event.
  */
trigger TDdUserNestingPlatformEventTrigger on User_Nesting__e (after insert) {
    CDdUserNestingPlatformEventHelper.handleEvents(trigger.new);
}