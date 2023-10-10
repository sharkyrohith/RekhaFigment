/**
* @description       : Handler for zkmultiMCCheckpointTrigger
* @author            : BizApps Team
* @description		  : BASD-54056 Tablet Returned to Sender not Applying Correctly
**/
public class zkmultiMCCheckpointTriggerHandler {
    public void afterInsert(List<zkmulti__MCCheckpoint__c> newList){
        List<String> errorMessages = new List<String>();
        List<zkmulti__MCShipment__c > shipmentsToUpdate = new List<zkmulti__MCShipment__c>();        
        try {    
            for(zkmulti__MCCheckpoint__c checkpoint : newList){
                if(String.isNotEmpty(checkpoint.zkmulti__Source__c) && checkpoint.zkmulti__Shipment__c != null && checkpoint.zkmulti__Source__c == 'RS' ){
                    zkmulti__MCShipment__c shipment = new zkmulti__MCShipment__c();
                    shipment.Id = checkpoint.zkmulti__Shipment__c;
                    shipment.Checkpoint_Source__c = checkpoint.zkmulti__Source__c;
                    shipmentsToUpdate.add(shipment);
                }            
            }
            if(!shipmentsToUpdate.isEmpty()){
                update shipmentsToUpdate;
            }
            
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw e;
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'zkmultiMCCheckpointTriggerHandler', 'afterInsert', LoggingLevel.ERROR);
        }
    }
}