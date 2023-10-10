/**
 * CDdGDPREmailActionEventTriggerHelper
 *
 * @author     raja
 * @date  2021-10
 * @decription  This class is the helper for GDPR_Email_Action__e Platform Events 
 */
public with sharing class CDdGDPREmailActionEventTriggerHelper{
    
    /**
     * @author     Raja
     * @date  2020-10
     * @decription This method is the entry point into the Helper. It processes the GDPR Email Actions events and performs API Callouts to the CASSIE endpoint
     * @param   GDPR_Email_Action__e newList
     * @return  void
     */
    public void processGDPREmailActionEvents(List<GDPR_Email_Action__e> newList) {
        List<GDPR_Email_Action__e> ccList = new List<GDPR_Email_Action__e>();
        List<GDPR_Email_Action__e> subList = new List<GDPR_Email_Action__e>();
        for(GDPR_Email_Action__e event: newList){
            if (event.Service__c == CDdGDPRConstants.CREATE_CONTACT_EVENT_SERVICE){
                ccList.add(event);
            } else if (event.Service__c == CDdGDPRConstants.SUBSCRIPTION_EVENT_SERVICE){
                subList.add(event);
            }
        }

        if (ccList.size() > 0){
            CDdGDPRCreateContactHelper.processCreateContactEvents(ccList);
        }

        if (subList.size() > 0){
            CDdGDPRSubscriptionsHelper.processSubscriptionEvents(subList);
        }
    }
    
    
}