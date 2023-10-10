/**
* @author: salesforce.com
* @date: 2020-10-04
* @description Test class for CDdChatButtonDistributionTriggerHandler.
*/
@isTest
public class CDdChatButtonDistTriggerHandlerTest {

    // test unique key
    static testMethod void testUniqueKey() {
        
        // create chat button distribution
        List<Chat_Button_Distribution__c> cbds = new List<Chat_Button_Distribution__c>();
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = 'CBD1');
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');
        
        // confirm unique key set
        cbd1 = [SELECT Id, Chat_Button_API_Name__c, Start_Time__c, End_Time__c, Unique_Key__c
                FROM Chat_Button_Distribution__c
                WHERE Id = :cbd1.Id];
        system.assertEquals(cbd1.Chat_Button_API_Name__c + 'test', cbd1.Unique_Key__c, 'CBD1 unique key incorrect.');
        
        // update start/end times
        cbd1.Start_Time__c = Time.newInstance(0, 0, 0, 0);
        cbd1.End_Time__c = Time.newInstance(12, 0, 0, 0);
        update(cbd1);
        
        // confirm unique key set
        cbd1 = [SELECT Id, Chat_Button_API_Name__c, Start_Time__c, End_Time__c, Unique_Key__c
                FROM Chat_Button_Distribution__c
                WHERE Id = :cbd1.Id];
        String uniqueKey = cbd1.Chat_Button_API_Name__c + '-' + cbd1.Start_Time__c + '-' + cbd1.End_Time__c + 'test';
        system.assertEquals(uniqueKey, cbd1.Unique_Key__c, 'CBD1 unique key incorrect.');
    }
    
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
        CDdChatButtonDistributionTriggerHandler.throwTestException = true;
        
        // change skip validations for cbd1
        cbd1.Skip_Vendor_Distributions__c = true;
        update(cbd1);
        
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
        system.assert(CDdChatButtonDistributionTriggerHandler.errorMessages.size() > 0, 'Exception not logged.');
    }
}