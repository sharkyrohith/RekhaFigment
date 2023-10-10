/**
 * TDdGDPREmailActionEventTrigger
 *
 * @author     Raja
 * @date  2021-10
 * @decription  This trigger subscribes to GDPR_Email_Action__e . Since it is a platform event, 
 *               it should not have anything but after insert. 
 */

trigger TDdGDPREmailActionEventTrigger on GDPR_Email_Action__e(after insert) {
    CDdGDPREmailActionEventTriggerHandler.afterInsert(Trigger.new); 
}