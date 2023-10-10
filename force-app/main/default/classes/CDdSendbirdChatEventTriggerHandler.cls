/**
 * CDdSendbirdChatEventTriggerHandler
 *
 * @author     Jeegar
 * @date  2021-03
 * @decription  This class is the handler for Sendbird_Chat_Event__e Platform Events
 */

 public with sharing class CDdSendbirdChatEventTriggerHandler {
    /**
     * @author     Jeegar
     * @date  2020-03
     * @decription This method handles after insert events
     * @param   List<Sendbird_Chat_Event__e> newList
     * @return  void
     */
    public static void afterInsert(List<Sendbird_Chat_Event__e> newList) {
        System.debug('Inside after Insert'); 
        CDdSendbirdChatEventTriggerHelper chatEventHelper = new CDdSendbirdChatEventTriggerHelper(); 
        chatEventHelper.processSendbirdChatEvents(newList);
    }
}