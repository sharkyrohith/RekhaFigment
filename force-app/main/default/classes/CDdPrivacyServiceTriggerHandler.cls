public class CDdPrivacyServiceTriggerHandler {

    public void beforeInsert(List<Privacy_Service__c> newList){ 
        CDdPIISvc.treatDuplicatePS(newList);
    }
    public void beforeUpdate(List<Privacy_Service__c> newList, Map<Id, Privacy_Service__c> oldMap){
    }
    public void afterInsert(List<Privacy_Service__c> newList){
        CDdPIISvc.processPrivacyService(JSON.serialize(newList));
    }
    public void afterUpdate(List<Privacy_Service__c> newList, Map<Id, Privacy_Service__c> oldMap){
    }
}