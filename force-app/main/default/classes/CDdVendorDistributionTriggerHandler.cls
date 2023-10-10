/**
* @author: salesforce.com
* @date: 2020-09-29
* @description Trigger handler for Vendor Distribution (Vendor_Distribution__c).
*/
public class CDdVendorDistributionTriggerHandler {

    // declaration(s)
    @TestVisible private static List<String> errorMessages = new List<String>();
    @TestVisible private static Boolean throwTestException = false;
    
    // before insert handler
    public void beforeInsert(List<Vendor_Distribution__c> newList) { }

    // before update handler
    public void beforeUpdate(Map<Id,Vendor_Distribution__c> newMap, Map<Id,Vendor_Distribution__c> oldMap) { }

    // after insert handler
    public void afterInsert(Map<Id,Vendor_Distribution__c> newMap) { }

    // after update handler
    public void afterUpdate(Map<Id,Vendor_Distribution__c> newMap, Map<ID, Vendor_Distribution__c> oldMap) {
        resetChatCounts(newmap, oldmap);        
    }
    
    /**
     * @description Resets chat counts whenever target distribution has changed. Resets affect all
     *              vendor distribution records for the master chat button distribution record.
    */
    public static void resetChatCounts(Map<Id, Vendor_Distribution__c> newMap, Map<Id, Vendor_Distribution__c> oldMap) {
        try {
                
            // if method is disabled then return
            if (CDdCustomMetadata.isDisabled('CDdVendorDistributionTriggerHandler_rCC')) return;
            
            // declaration(s)
            Set<Id> chatButtonDistIds = new Set<Id>();
        
            // loop through records
            for (Vendor_Distribution__c newRecord : newMap.values()) {
                
                // get previous record
                Vendor_Distribution__c oldRecord = oldMap.get(newRecord.Id);
                
                // if target distribution has changed then add chat button distribution id to set
                if(newRecord.Target_Distribution__c != oldRecord.Target_Distribution__c ) {
                    chatButtonDistIds.add(newRecord.Chat_Button_Distribution__c);
                }
            }
        
            // if chat button distributions need to be reset
            if (chatButtonDistIds.size() > 0) {
                CDdChatButtonDistributionTriggerHandler.resetVendorDistributionChatCounts(new List<Id>(chatButtonDistIds));
            }
            
            // throw exception for test coverage
            if (Test.isRunningTest() && throwTestException) {
                throw new CDdVendorDistributionTriggerHandlerException('Test Exception');
            }
        }
        catch (Exception e) {
            
            // log exception
            system.debug(e.getMessage());
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdVendorDistributionTriggerHandler', 
                                             'resetChatCount', LoggingLevel.ERROR);
        }
    }
    
    // exception test class
    public class CDdVendorDistributionTriggerHandlerException extends Exception { }
}