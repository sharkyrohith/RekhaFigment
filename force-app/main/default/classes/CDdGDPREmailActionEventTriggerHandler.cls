/**
 * CDdSendbirdChatEventTriggerHandler
 *
 * @author     Raja
 * @date  2021-10
 * @decription  This class is the handler for GDPR_Email_Action__e Platform Events
 */

 public with sharing class CDdGDPREmailActionEventTriggerHandler {
    /**
     * @author     Raja
     * @date  2020-10
     * @decription This method handles after insert events
     * @param   List<GDPR_Email_Action__e> newList
     * @return  void
     */
    public static void afterInsert(List<GDPR_Email_Action__e> newList) {
        CDdGDPREmailActionEventTriggerHelper eventHelper = new CDdGDPREmailActionEventTriggerHelper(); 
        eventHelper.processGDPREmailActionEvents(newList);
    }
}