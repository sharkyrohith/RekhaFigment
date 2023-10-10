/* 
* @Author Tia Xuan
* @Date April 2020
* @description The handler class for Zenkraft shipment trigger
* 
*/
public class CDdZKShipmentHandler {
    public void afterInsert(List<SObject> newList){
        stampStatusDescriptionOnCase(newList, null);
    }
    
    public void beforeUpdate(Map<Id, SObject> newMap,Map<Id, SObject> oldMap){
        stampStatusDescriptionOnCase(newMap.values(), oldMap);       
    }
    
    /**
* @author: Tia Xuan
* @date 04/2020
* @description: BZAP-5836 Stamp Status Description on Case from Fedex Shipment Record
*
*/
    public void stampStatusDescriptionOnCase(List<SObject> newList, Map<Id,SObject> oldMap){
        
        String descField = 'zkfedex__StatusDescription__c';
        String lastTrackUpdateField = 'zkfedex__LastTrackUpdateTime__c';
        Id recId = newList[0].Id;
        if (recId.getSObjectType().getDescribe().getName() == 'zkmulti__MCShipment__c'){
            descField = 'zkmulti__Status_Description__c';
            lastTrackUpdateField = 'zkmulti__Last_Track_Update_Time__c';
        }
        
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();
        List<String> errorMessages = new List<String>();
        try {        
            for (SObject obj : newList){
                if (oldMap == null 
                    || obj.get(descField) != oldMap.get(obj.Id).get(descField)){
                        Id caseId = (Id) obj.get('Case__c');
                        String descr = (String) obj.get(descField);
                        DateTime lastTrackUpdate = (DateTime) obj.get(lastTrackUpdateField);
                        Case c = new Case();
                        c.Id =  caseId;
                        c.Tablet_Shipment_Status__c = descr;
                        c.Tablet_Last_Track_Update_Time__c = lastTrackUpdate;
                        casesToUpdate.put(c.Id, c);
                    }
            }
            
            if (!casesToUpdate.isEmpty()){
                List<Database.SaveResult> sResults = Database.update(casesToUpdate.values(), false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw e;
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdZKShipmentHandler', 'stampStatusDescriptionOnCase', LoggingLevel.ERROR);
        }
    }
}