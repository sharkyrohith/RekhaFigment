/**
 * TDdSendbirdChatEventTrigger
 *
 * @author     Jeegar
 * @date  2021-03
 * @decription  This trigger subscribes to Sendbird_Chat_Event__e. Since it is a platform event, 
 *               it should not have anything but after insert. 
 */

trigger TDdSendbirdChatEventTrigger on Sendbird_Chat_Event__e (after insert) {
    CDdSendbirdChatEventTriggerHandler.afterInsert(Trigger.new); 
}