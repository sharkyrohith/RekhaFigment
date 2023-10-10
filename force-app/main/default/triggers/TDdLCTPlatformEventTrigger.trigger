/**
* @author Mahesh Chouhan
* @description Trigger for Live Chat Transcript Platform Events
* @date 07-16-2021
*/
trigger TDdLCTPlatformEventTrigger on Live_Chat_Transcript_Platform_Event__e (after insert) {
    
    CDdLCTPlatformEventHelper.handleEvents(trigger.new);
    
}