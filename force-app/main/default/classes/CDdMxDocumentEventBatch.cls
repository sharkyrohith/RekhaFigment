/**
 * @author Critical River
 * @date 5/26/2023 
 */
public class CDdMxDocumentEventBatch implements Database.Batchable<sObject>, Schedulable , Database.AllowsCallouts {

    List<String> statusList = new List<String>{'New', 'Retry', 'Failed'};
    String sObjectType = 'ContentVersion';
    
    public void execute(SchedulableContext SC) {
      Database.executeBatch(new CDdMxDocumentEventBatch()); 
    }
    
    public Iterable<SObject>  start(Database.BatchableContext BC) {
        Map<String,Mx_Document_Event__c> storeIdEventMap = new Map<String,Mx_Document_Event__c>();
        for(Mx_Document_Event__c mxDocumentEvent : [SELECT Id,Name,Store_Id__c,SObject_Id__c,SObject_Type__c
                                                    FROM Mx_Document_Event__c
                                                    WHERE Status__c IN :statusList AND
                                                    SObject_Type__c = :sObjectType
                                                    LIMIT 50000]){
            storeIdEventMap.put(mxDocumentEvent.Store_Id__c,mxDocumentEvent);
        }

        return storeIdEventMap.values();
    }

    public void execute(Database.BatchableContext BC, List<Mx_Document_Event__c> scope) {
        Set<String> storeIds = new Set<String>();
        
        for(Mx_Document_Event__c mxDocumentEvent : scope){
            storeIds.add(mxDocumentEvent.Store_Id__c);
        }

        List<Mx_Document_Event__c> mxDocumentList = [SELECT Id,Name,Store_Id__c,SObject_Id__c,SObject_Type__c
                                                    FROM Mx_Document_Event__c
                                                    WHERE Store_Id__c IN :storeIds AND
                                                     Status__c IN :statusList AND
                                                    SObject_Type__c = :sObjectType];

        CDdMxDocumentEventService.sendMxDocumentEvents(storeIds,mxDocumentList);
    }

    public void finish(Database.BatchableContext BC) {

    }

}