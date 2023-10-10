/** 
 * @description       : Test class for zkmultiMCCheckpointTriggerHandler
 * @author            : BizApps Team
 * @description		  : BASD-54056 Tablet Returned to Sender not Applying Correctly 
**/
@isTest
public class zkmultiMCCheckpointTriggerHandlerTest { 
    @testSetup 
    static void setup(){
        zkmulti__MCShipment__c  shipment = new zkmulti__MCShipment__c();	        
        insert shipment;      
    }
    @isTest 
    static void testAfterInsert() {        
        zkmulti__MCShipment__c Shipment = [SELECT Id FROM zkmulti__MCShipment__c LIMIT 1];
        Test.startTest(); 
        zkmulti__MCCheckpoint__c cp = new zkmulti__MCCheckpoint__c();
        cp.zkmulti__Shipment__c = Shipment.Id;
		cp.zkmulti__Source__c = 'RS';
        try{
            insert cp;
        }
        catch(exception e){
            
        }
        
        Test.stopTest();
        zkmulti__MCShipment__c shipmnt = [SELECT Id, Checkpoint_Source__c  FROM zkmulti__MCShipment__c LIMIT 1];
        System.assertEquals('RS', shipmnt.Checkpoint_Source__c);
    }    
}