/**
* Jira : BZAP-18107
* @author: Venkat D
* @date: 2022-11
* @description Queueable for Implementation Request record creation.
*/
public class CDdImplementationRequestQueueable implements Queueable{
    
    public static final Map<String,String> accPMCOSAQueueMap;
    public Map<String,Id> osaQueueMap;
    public static final Id nvOSARecordTypeId;
    public static final List<String> countryList;
    
    static{
        Map<String, Schema.RecordTypeInfo> IR_RT_INFO_BY_NAME = Schema.SObjectType.Implementation_Request__c.getRecordTypeInfosByName();
        accPMCOSAQueueMap = getAccountPMCOSAQueueMapppingData();
 		nvOSARecordTypeId = IR_RT_INFO_BY_NAME.get('NV OSA').getRecordTypeId();
        countryList = new List<String>{'United States'};
    }
    
    List<Opportunity> newList;
    //Constructor of CDdImplementationRequestQueueable
    public CDdImplementationRequestQueueable(List<Opportunity> newList) {
        this.newList = newList;
    }
	
    
    public void execute(QueueableContext context) {
        createImplementationRequest();
    }
    
    public void createImplementationRequest(){
        osaQueueMap = getOSAQueues(accPMCOSAQueueMap.values());
        List<Opportunity> opportunityList = [SELECT Id,Account.Primary_Merchant_Categories__c,Account.BillingCountry,(Select Id FROM Implementation_Requests__r WHERE RecordTypeId = :nvOSARecordTypeId limit 1) FROM Opportunity WHERE Id IN :newList];
        List<Implementation_Request__c> newImplementationRequestList = populateImplementationRequest(opportunityList);
        
        if(!newImplementationRequestList.isEmpty()){
            Database.SaveResult[] saveResults = Database.insert(newImplementationRequestList,false);
            List<String> errorMessages = CDdErrorUtilities.processSaveResults(saveResults);
        
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdImplementationRequestQueueable');
            }
        }
    }

    @TestVisible
    private List<Implementation_Request__c> populateImplementationRequest(List<Opportunity> opportunityList){
        List<Implementation_Request__c> newImplementationRequestList = new List<Implementation_Request__c>();
        
        for(Opportunity oppRec:opportunityList){
            String accPrimaryMerchantCategory = oppRec.Account.Primary_Merchant_Categories__c;
            List<Implementation_Request__c> existingImplRequests = oppRec.Implementation_Requests__r;
            if((existingImplRequests == null ||  existingImplRequests.size() == 0) && 
                    accPMCOSAQueueMap.keySet().contains(accPrimaryMerchantCategory) &&
                    countryList.contains(oppRec.Account.BillingCountry)){
                
                Implementation_Request__c newImplRequest = new Implementation_Request__c();
                newImplRequest.Opportunity__c = oppRec.Id;
                newImplRequest.RecordTypeId = nvOSARecordTypeId;
                if(osaQueueMap.get(accPMCOSAQueueMap.get(accPrimaryMerchantCategory)) != null){
                    newImplRequest.OwnerId = osaQueueMap.get(accPMCOSAQueueMap.get(accPrimaryMerchantCategory));       
                }
                newImplementationRequestList.add(newImplRequest);      
            }
        }
        
        return newImplementationRequestList;
    }
    
    @TestVisible
    private static Map<String,String> getAccountPMCOSAQueueMapppingData(){
        Map<String,String> accPMCOSAQueueMap = new Map<String,String>();
        for (Account_PMC_OSA_Queue_Mapping__mdt pmcOsaMapping : [SELECT Id, MasterLabel, DeveloperName, Queue_Name__c FROM Account_PMC_OSA_Queue_Mapping__mdt limit 100]){
        	accPMCOSAQueueMap.put(pmcOsaMapping.MasterLabel,pmcOsaMapping.Queue_Name__c);                                           
        }
        return accPMCOSAQueueMap;
    }
    
    @TestVisible
    private Map<String,Id> getOSAQueues(List<String> queueNameList){
        Map<String,Id> osaQueueMap = new Map<String,Id>();
        for(Group queueRec : [Select Id,Name,DeveloperName from Group WHERE Type = 'Queue' AND DeveloperName IN :queueNameList]){
            osaQueueMap.put(queueRec.DeveloperName,queueRec.Id);
        }
        return osaQueueMap;
    }
}