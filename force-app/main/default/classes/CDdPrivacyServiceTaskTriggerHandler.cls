public class CDdPrivacyServiceTaskTriggerHandler {

    public void beforeInsert(List<Privacy_Service_Task__c> newList){ 
    }
    public void beforeUpdate(List<Privacy_Service_Task__c> newList, Map<Id, Privacy_Service_Task__c> oldMap){
    }
    public void afterInsert(List<Privacy_Service_Task__c> newList){
    }
    public void afterUpdate(List<Privacy_Service_Task__c> newList, Map<Id, Privacy_Service_Task__c> oldMap){
        CDdPIISvc.respondAfterTreatment(newList);
    }
}