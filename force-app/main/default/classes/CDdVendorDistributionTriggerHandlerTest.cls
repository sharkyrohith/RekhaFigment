/**
* @author: salesforce.com
* @date: 2020-09-29
* @description Test class for CDdVendorDistributionTriggerHandler.
*/
@isTest
public class CDdVendorDistributionTriggerHandlerTest {

    // test chat count reset
    static testMethod void testChatCountsReset() {
        
        // create chat button distributions
        List<Chat_Button_Distribution__c> cbds = new List<Chat_Button_Distribution__c>();
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = 'CBD1');
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');
        Chat_Button_Distribution__c cbd2 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = 'CBD2');
        insert(cbd2);
        system.assertNotEquals(null, cbd2.Id, 'CBD2 not created.');
        
        // get vendor values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }
        
        // create vendor distributions
        List<Vendor_Distribution__c> vds = new List<Vendor_Distribution__c>();
        Vendor_Distribution__c vd1_1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                  Vendor__c = vendors[0],
                                                                  Target_Distribution__c = 50,
                                                                  Actual_Chat_Count__c = 10);
        insert(vd1_1);
        system.assertNotEquals(null, vd1_1.Id, 'VD1_1 not created.');
        Vendor_Distribution__c vd1_2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                  Vendor__c = vendors[1],
                                                                  Target_Distribution__c = 50,
                                                                  Actual_Chat_Count__c = 10);
        insert(vd1_2);
        system.assertNotEquals(null, vd1_2.Id, 'VD1_2 not created.');
        Vendor_Distribution__c vd2_1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd2.Id,
                                                                  Vendor__c = vendors[0],
                                                                  Target_Distribution__c = 50,
                                                                  Actual_Chat_Count__c = 10);
        insert(vd2_1);
        system.assertNotEquals(null, vd2_1.Id, 'VD2_1 not created.');
        Vendor_Distribution__c vd2_2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd2.Id,
                                                                  Vendor__c = vendors[1],
                                                                  Target_Distribution__c = 50,
                                                                  Actual_Chat_Count__c = 10);
        insert(vd2_2);
        system.assertNotEquals(null, vd2_2.Id, 'VD2_2 not created.');
        
        // throw test exception
        CDdVendorDistributionTriggerHandler.throwTestException = true;
        
        // reset target distribution for vendor distribition 1_1
        vd1_1.Target_Distribution__c = 20;
        update(vd1_1);
        
        // confirm counts reset for vd1_1
        vd1_1 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd1_1.Id];
        system.assertEquals(0, vd1_1.Actual_Chat_Count__c, 'VD1_1 actual chat count incorrect.');
        
        // confirm counts reset for vd1_2
        vd1_2 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd1_2.Id];
        system.assertEquals(0, vd1_2.Actual_Chat_Count__c, 'VD1_2 actual chat count incorrect.');
        
        // confirm counts not reset for vsd2_1
        vd2_1 = [SELECT Id, Actual_Chat_Count__c
                  FROM Vendor_Distribution__c
                  WHERE Id = :vd2_1.Id];
        system.assertNotEquals(0, vd2_1.Actual_Chat_Count__c, 'VD2_1 actual chat count incorrect.');
        
        // confirm counts not reset for vsd2_2
        vd2_2 = [SELECT Id, Actual_Chat_Count__c
                  FROM Vendor_Distribution__c
                  WHERE Id = :vd2_2.Id];
        system.assertNotEquals(0, vd2_2.Actual_Chat_Count__c, 'VD2_2 actual chat count incorrect.');
        
        // confirm exception error message logged
        system.assert(CDdVendorDistributionTriggerHandler.errorMessages.size() > 0, 'Exception not logged.');
    }
}