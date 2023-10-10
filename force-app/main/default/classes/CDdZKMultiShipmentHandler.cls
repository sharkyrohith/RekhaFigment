/**
 * CDdZKMultiShipmentHandler
**/
public class CDdZKMultiShipmentHandler {
    public CDdZKMultiShipmentHandler() {}

    public void beforeUpdate(Map<Id, SObject> newMap,Map<Id, SObject> oldMap){
        StampDateReturnedToSenderOnShipment(newMap.values(), oldMap);
    }
    public void beforeInsert(List<SObject> newList){
        StampDateReturnedToSenderOnShipment(newList, null);  
    }
    public void afterInsert(List<SObject> newList){
        UpdateStatusOnCaseUponShipmentDescription(newList,null);
    }
    public void afterUpdate(Map<Id, SObject> newMap,Map<Id, SObject> oldMap){
        UpdateStatusOnCaseUponShipmentDescription(newMap.values(), oldMap);       
    }

    /**
    * @author: Sharvani Sri
    * @date 11/2021
    * @description: BASD-17392 Stamp DateReturnedToSender on shipment
    *
    */
    public void StampDateReturnedToSenderOnShipment(List<SObject> newList, Map<Id,SObject> oldMap){
        String descField = 'zkmulti__Status_Description__c';
        String dateReturnedToSenderField = 'Date_returned_to_sender__c';     
        List<String> errorMessages = new List<String>();
        try {    
            for (Sobject obj : newList){
                if ((oldMap == null || obj.get(descField) != oldMap.get(obj.Id).get(descField)) && obj.get(descField) == 'Unsuccessful Delivery'){ 
                    obj.put(dateReturnedToSenderField, system.today());
                }                
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw e;
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdZKShipmentHandler', 'StampDateReturnedToSenderOnShipment', LoggingLevel.ERROR);
        }
    }

    /**
    * @author: Sharvani Sri
    * @date 11/2021
    * @description: BASD-17392 Stamp Status on case upon updating the shipment
    *
    */   
    public void UpdateStatusOnCaseUponShipmentDescription(List<SObject> newList, Map<Id,SObject> oldMap){
        String descField = 'zkmulti__Status_Description__c';
        String dateReturnedToSenderField = 'Date_returned_to_sender__c';     
        String trackingNumber = 'zkmulti__Tracking_Number__c';
        String checkPointSource = 'Checkpoint_Source__c';
        List<String> errorMessages = new List<String>();
        List<Case> casesToUpdate = new List<Case>();
        List<Id> caseIds = new List<Id>();
        Map<Id,Case> caseMap;
        
        For(SObject obj : newList){
           caseIds.add((Id)obj.get('Case__c'));
        }
        
        if(!caseIds.isEmpty())
        {
          caseMap = new Map<Id,Case>([SELECT Id, Tablet_Tracking__c, Request_Type__c FROM Case WHERE Id IN :caseIds]);  
        }

        try {
                for (Sobject obj : newList){
                    if (((oldMap == null || obj.get(descField) != oldMap.get(obj.Id).get(descField)) && obj.get(descField) == 'Unsuccessful Delivery')||((oldMap == null || obj.get(checkPointSource) != oldMap.get(obj.Id).get(checkPointSource)) && obj.get(checkPointSource) == 'RS')){ 
                        Case c = new Case(Id =  (Id) obj.get('Case__c'),status = 'Returned to Sender');
                        casesToUpdate.add(c);
                    }   
                    //BASD-28172 Copy tracking number from Shipment to tablet case
                    if((oldMap == null || obj.get(trackingNumber) != oldMap.get(obj.Id).get(trackingNumber)) && obj.get('Case__c') != null && obj.get(trackingNumber) != null){
                        Id caseId = (Id)obj.get('Case__c');
                        if( caseId == caseMap.get(caseId).Id && (caseMap.get(caseId).Tablet_Tracking__c == null || caseMap.get(caseId).Tablet_Tracking__c != (String) obj.get(trackingNumber)) && caseMap.get(caseId).Request_Type__c.contains('Return')){
                            Case cs = new Case(Id = (Id) obj.get('Case__c') , Status = 'Shipped', Tablet_Tracking__c = (String) obj.get(trackingNumber));
                        	if(!casesToUpdate.contains(cs))
                        	{
                            	casesToUpdate.add(cs);
                        	} 
                    	}
                    }
                }
                if (!casesToUpdate.isEmpty()){
                    List<Database.SaveResult> sResults = Database.update(casesToUpdate, false);
                    errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
                }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw e;
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdZKShipmentHandler', 'StampDateReturnedToSenderOnShipment', LoggingLevel.ERROR);
        }
    }  
}