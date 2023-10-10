/**
* @author: salesforce.com
* @date: 2020-10-01
* @description Trigger handler for Chat Button Distribution (Chat_Button_Distribution__c).
*/
public class CDdChatButtonDistributionTriggerHandler {

    // declaration(s)
    @TestVisible private static List<String> errorMessages = new List<String>();
    @TestVisible private static Boolean throwTestException = false;
    
    // before insert handler
    public void beforeInsert(List<Chat_Button_Distribution__c> newList) {
        setUniqueKey(newList);
    }

    // before update handler
    public void beforeUpdate(Map<Id, Chat_Button_Distribution__c> newMap, Map<Id, Chat_Button_Distribution__c> oldMap) {
        setUniqueKey(newMap.values());
    }

    // after insert handler
    public void afterInsert(Map<Id, Chat_Button_Distribution__c> newMap) { }

    // after update handler
    public void afterUpdate(Map<Id, Chat_Button_Distribution__c> newMap, Map<ID, Chat_Button_Distribution__c> oldMap) {
        resetChatCounts(newMap, oldMap);
    }
    
    /**
     * @description Updates unique key field. Done in trigger vs. flow due to Time fields not supported in flows.
    */
    public static void setUniqueKey(List<Chat_Button_Distribution__c> records) {
        
        // loop through records
        for (Chat_Button_Distribution__c record : records) {

            // update unique key and test value (to ensure uniqueness in apex testing)
            String timeValue = record.Start_Time__c != null ?
                '-' + record.Start_Time__c + '-' + record.End_Time__c : '';
            String testValue = Test.isRunningTest() ? 'test' : '';
            record.Unique_Key__c = record.Chat_Button_API_Name__c + timeValue + testValue;
        }
    }
    
    /**
     * @description Resets vendor distribution chat counts whenever skip validations has changed. Resets affect all
     *              vendor distribution records for the chat button distribution record.
    */
    public static void resetChatCounts(Map<Id, Chat_Button_Distribution__c> newMap, Map<Id, Chat_Button_Distribution__c> oldMap) {
        try {
                
            // if method is disabled then return
            if (CDdCustomMetadata.isDisabled('CDdChatButtonDistributionTriggerHandler_rCC')) return;
            
            // declaration(s)
            Set<Id> chatButtonDistIds = new Set<Id>();
        
            // loop through records
            for (Chat_Button_Distribution__c newRecord : newMap.values()) {
                
                // get previous record
                Chat_Button_Distribution__c oldRecord = oldMap.get(newRecord.Id);
                
                // if skip vendor distribution has changed then add chat button distribution id to set
                if(newRecord.Skip_Vendor_Distributions__c != oldRecord.Skip_Vendor_Distributions__c ) {
                    chatButtonDistIds.add(newRecord.Id);
                }
            }
        
            // if chat button distributions need to be reset
            if (chatButtonDistIds.size() > 0) {
                CDdChatButtonDistributionTriggerHandler.resetVendorDistributionChatCounts(new List<Id>(chatButtonDistIds));
            }
            
            // throw exception for test coverage
            if (Test.isRunningTest() && throwTestException) {
                throw new CDdChatButtonDistributionTriggerHandlerException('Test Exception');
            }
        } catch (Exception e) {
            
            // log exception
            system.debug(e.getMessage());
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdChatButtonDistributionTriggerHandler', 
                                             'resetChatCount', LoggingLevel.ERROR);
        }
    }
    
    /**
     * @description Resets vendor distribution chat counts. Resets affect all vendor distribution
     *              records for the chat button distribution record.
    */
    @InvocableMethod
    public static void resetVendorDistributionChatCounts(List<Id> chatButtonIds) {
        try {
            
            // get chat button distribution (lock for update)
            List<Chat_Button_Distribution__c> chatButtonDistributions = [SELECT Id, Last_Count_Reset__c
                                                                         FROM Chat_Button_Distribution__c
                                                                         WHERE Id IN :chatButtonIds
                                                                         FOR UPDATE];
            if (chatButtonDistributions.size() > 0) {
                
                // update last count reset to current date/time
                for (Chat_Button_Distribution__c chatButtonDistribution : chatButtonDistributions) {
                    chatButtonDistribution.Last_Count_Reset__c = DateTime.now();
                }
                update(chatButtonDistributions);
                
                // get vendor distribution records (lock for update)
                List<Vendor_Distribution__c> vendorDistributions = [SELECT Id, Actual_Chat_Count__c
                                                                    FROM Vendor_Distribution__c
                                                                    WHERE Chat_Button_Distribution__c IN :chatButtonIds
                                                                    FOR UPDATE];
                if (vendorDistributions.size() > 0) {
                    
                    // update chat counts to zero
                    for (Vendor_Distribution__c vendorDistribution : vendorDistributions) {
                        vendorDistribution.Actual_Chat_Count__c = 0;
                    }
                    
                    // update records
                    update(vendorDistributions);
                }
            }
            
            // throw exception for test coverage
            if (Test.isRunningTest() && throwTestException) {
                throw new CDdChatButtonDistributionTriggerHandlerException('Test Exception');
            }
        } catch (Exception e) {
            
            // log exception
            system.debug(e.getLineNumber());
            system.debug(e.getMessage());
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdChatButtonDistributionTriggerHandler', 
                                             'resetVendorDistributionChatCounts', LoggingLevel.ERROR);
        }
    }
    
    // exception test class
    public class CDdChatButtonDistributionTriggerHandlerException extends Exception { }
}