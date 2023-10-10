/**
* @author: salesforce.com
* @date: 2020-09-15
* @description Test class for CDdLiveChatTransEventTriggerHandler.
*/
@isTest
public class CDdLiveChatTransEventTriggerHandlerTest {

    // static values
    private static final String agentUserName = 'agent@sftest.sftest';
    
    // data setup
    @testSetup static void setup() {
        // get vendor site values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }

        // get agent profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Agent']; 
        
        // get vendor user mapping
        Vendor_User_Mapping__mdt vum = [SELECT MasterLabel, Email_Domain_Prefixes__c,
                                        Company_Name__c
                                        FROM Vendor_User_Mapping__mdt LIMIT 1];
        String emailDomainPrefix = vum.Email_Domain_Prefixes__c.split('\n')[0];
        
        // create agent user with email matching vendor user mapping (storing vendor in company name)
        User agent = new User(Alias = 'agent', Email = 'agent@' + emailDomainPrefix + '.sftest', 
                              EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey = 'en_US', ProfileId = p.Id, CompanyName = vum.MasterLabel,
                              TimeZoneSidKey = 'America/Los_Angeles', UserName = agentUserName);
        insert(agent);
        system.assertNotEquals(null, agent.Id, 'Agent not created.');

        Live_Chat_Transcript_Settings__c lctSetting = Live_Chat_Transcript_Settings__c.getOrgDefaults(); 
        lctSetting.Accept_Events__c = 'Transfer;Accept;PushAssignment';
        upsert lctSetting; 
    }
    
    // test preferred vendor (preferred vendor got the chat)
    static testMethod void testPreferredVendorNoTime() {
        
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName DESC LIMIT 1];
        
        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');
        
        // get vendor values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }
            
        // get agent
        User agent = [SELECT Id, CompanyName
                      FROM User
                      WHERE UserName = :agentUserName LIMIT 1];
        
        // create vendor distributions
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = agent.CompanyName,
                                                                Target_Distribution__c = 75);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        String vendor2 = vendors[0].equalsIgnoreCase(agent.CompanyName) ? vendors[1] : vendors[0];
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendor2,
                                                                Target_Distribution__c = 25);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');
        
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');
        
        // throw test exception
        CDdLiveChatTransEventTriggerHandler.throwTestException = true;
        
        // start test
        Test.startTest();
        
        // create transfer event
        LiveChatTranscriptEvent lcte = new LiveChatTranscriptEvent(Type = 'Transfer', AgentId = agent.Id,
                                                                   LiveChatTranscriptId = lct.Id, Time = DateTime.now());
        insert(lcte);
        system.assertNotEquals(null, lcte.Id, 'LiveChatTranscriptEvent not created.');
        
        // update transfer event (just for trigger coverage)
        update(lcte);
        
        // stop test
        Test.stopTest();
        
        // check counter for vendor distributions
        vd1 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd1.Id];
        system.assertEquals(1, vd1.Actual_Chat_Count__c, 'VD1 actual chat count incorrect.');
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(0, vd2.Actual_Chat_Count__c, 'VD2 actual chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransEventTriggerHandler.errorMessages.size() > 0, 'Exception not logged.');
    }
    
    // test preferred vendor (preferred vendor got the chat)
    static testMethod void testPreferredVendorWithTime() {
        
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName DESC LIMIT 1];
        
        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');
        
        // create chat button distribution
        Chat_Button_Distribution__c cbd2 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName,
                                                                           Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                                           End_Time__c = Time.newInstance(22, 0, 0, 0));
        insert(cbd2);
        system.assertNotEquals(null, cbd2.Id, 'CBD1 not created.');
        
        // get vendor values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }
            
        // get agent
        User agent = [SELECT Id, CompanyName
                      FROM User
                      WHERE UserName = :agentUserName LIMIT 1];
        
        // create vendor distributions
        Vendor_Distribution__c vd1_1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                  Vendor__c = agent.CompanyName,
                                                                  Target_Distribution__c = 75);
        insert(vd1_1);
        system.assertNotEquals(null, vd1_1.Id, 'VD1_1 not created.');
        String vendor2 = vendors[0].equalsIgnoreCase(agent.CompanyName) ? vendors[1] : vendors[0];
        Vendor_Distribution__c vd1_2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                  Vendor__c = vendor2,
                                                                  Target_Distribution__c = 25);
        insert(vd1_2);
        system.assertNotEquals(null, vd1_2.Id, 'VD1_2 not created.');
        Vendor_Distribution__c vd2_1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd2.Id,
                                                                  Vendor__c = agent.CompanyName,
                                                                  Target_Distribution__c = 75);
        insert(vd2_1);
        system.assertNotEquals(null, vd2_1.Id, 'VD2_1 not created.');
        Vendor_Distribution__c vd2_2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd2.Id,
                                                                  Vendor__c = vendor2,
                                                                  Target_Distribution__c = 25);
        insert(vd2_2);
        system.assertNotEquals(null, vd2_2.Id, 'VD2_2 not created.');
        
        // force test to use time that fits within start/end time
        CDdLiveChatTranscriptTriggerHandler.nowTime = Time.newInstance(12, 0, 0, 0);
        CDdLiveChatTransEventTriggerHandler.createdTime = Time.newInstance(12, 0, 0, 0);
        
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');
        
        // throw test exception
        CDdLiveChatTransEventTriggerHandler.throwTestException = true;
        
        // start test
        Test.startTest();
        
        // create transfer event
        LiveChatTranscriptEvent lcte = new LiveChatTranscriptEvent(Type = 'Transfer', AgentId = agent.Id,
                                                                   LiveChatTranscriptId = lct.Id, Time = DateTime.now());
        insert(lcte);
        system.assertNotEquals(null, lcte.Id, 'LiveChatTranscriptEvent not created.');
        
        // update transfer event (just for trigger coverage)
        update(lcte);
        
        // stop test
        Test.stopTest();
        
        // check counter for vendor distributions
        vd1_1 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd1_1.Id];
        system.assertEquals(0, vd1_1.Actual_Chat_Count__c, 'VD1_1 actual chat count incorrect.');
        vd1_2 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd1_2.Id];
        system.assertEquals(0, vd1_2.Actual_Chat_Count__c, 'VD1_2 actual chat count incorrect.');
        vd2_1 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd2_1.Id];
        system.assertEquals(1, vd2_1.Actual_Chat_Count__c, 'VD2_1 actual chat count incorrect.');
        vd2_2 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd2_2.Id];
        system.assertEquals(0, vd2_2.Actual_Chat_Count__c, 'VD2_2 actual chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransEventTriggerHandler.errorMessages.size() > 0, 'Exception not logged.');
    }
    
    // test non preferred vendor (non preferred vendor got chat)
    static testMethod void testNonPreferredVendor() {
        
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName DESC LIMIT 1];
        
        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');
        
        // get vendor values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }
        
        // get agent
        User agent = [SELECT Id, CompanyName
                      FROM User
                      WHERE UserName = :agentUserName LIMIT 1];
        
        // create vendor distributions
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = agent.CompanyName,
                                                                Target_Distribution__c = 25);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        String vendor2 = vendors[0].equalsIgnoreCase(agent.CompanyName) ? vendors[1] : vendors[0];
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendor2,
                                                                Target_Distribution__c = 75);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');
        
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');
        
        // throw test exception
        CDdLiveChatTransEventTriggerHandler.throwTestException = true;
        
        // start test
        Test.startTest();

        // create transfer event
        LiveChatTranscriptEvent lcte = new LiveChatTranscriptEvent(Type = 'Transfer', AgentId = agent.Id,
                                                                   LiveChatTranscriptId = lct.Id, Time = DateTime.now());
        insert(lcte);
        system.assertNotEquals(null, lcte.Id, 'LiveChatTranscriptEvent not created.');
        
        // update transfer event (just for trigger coverage)
        update(lcte);
        
        // stop test
        Test.stopTest();
        
        // check counter for vendor distributions
        vd1 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd1.Id];
        system.assertEquals(1, vd1.Actual_Chat_Count__c, 'VD1 actual chat count incorrect.');
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(0, vd2.Actual_Chat_Count__c, 'VD2 actual chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransEventTriggerHandler.errorMessages.size() > 0, 'Exception not logged.');
    }
    
    // test other vendor (neither preferred nor non preferred vendor got chat)
    static testMethod void testOtherVendor() {
        
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName DESC LIMIT 1];
        
        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');
        
        // get vendor values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }
        
        // get agent
        User agent = [SELECT Id, CompanyName
                      FROM User
                      WHERE UserName = :agentUserName LIMIT 1];
        
        // create vendor site distributions
        String vendor1 = vendors[0].equalsIgnoreCase(agent.CompanyName) ? vendors[1] : vendors[0];
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendor1,
                                                                Target_Distribution__c = 25);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        String vendor2 = vendors[2].equalsIgnoreCase(agent.CompanyName) ? vendors[3] : vendors[2];
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendor2,
                                                                Target_Distribution__c = 75);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');
        
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');
        
        // throw test exception
        CDdLiveChatTransEventTriggerHandler.throwTestException = true;
        
        // start test
        Test.startTest();

        // create transfer event
        LiveChatTranscriptEvent lcte = new LiveChatTranscriptEvent(Type = 'Transfer', AgentId = agent.Id,
                                                                   LiveChatTranscriptId = lct.Id, Time = DateTime.now());
        insert(lcte);
        system.assertNotEquals(null, lcte.Id, 'LiveChatTranscriptEvent not created.');
        
        // update transfer event (just for trigger coverage)
        update(lcte);
        
        // stop test
        Test.stopTest();
        
        // check counter for vendor distributions
        vd1 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd1.Id];
        system.assertEquals(0, vd1.Actual_Chat_Count__c, 'VD1 actual chat count incorrect.');
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(0, vd2.Actual_Chat_Count__c, 'VD2 actual chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransEventTriggerHandler.errorMessages.size() > 0, 'Exception not logged.');
    }

    static testMethod void testChatAcceptEventTime() {
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName DESC LIMIT 1];
        // get agent
        User agent = [SELECT Id, CompanyName
                      FROM User
                      WHERE UserName = :agentUserName LIMIT 1];

        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');

        Test.startTest();
        
        // create transfer event
        LiveChatTranscriptEvent lcte = new LiveChatTranscriptEvent(Type = 'Transfer', AgentId = agent.Id,
                                                                   LiveChatTranscriptId = lct.Id, Time = DateTime.now());
        insert(lcte);
        system.assertNotEquals(null, lcte.Id, 'LiveChatTranscriptEvent not created.');

        Test.stopTest();
        lct = [SELECT id, Chat_Event_Accept_Time__c from LiveChatTranscript where id =: lct.id];
        System.assertNotEquals(null, lct.Chat_Event_Accept_Time__c, 'Chat_Event_Accept_Time__c not populated');
    }

    static testMethod void testTrueUpVDPlatformEvent() {

           
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName DESC LIMIT 1];
        
        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');
        
        // get vendor values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }
        
        // get agent
        User agent = [SELECT Id, CompanyName
                      FROM User
                      WHERE UserName = :agentUserName LIMIT 1];
        
        // create vendor distributions
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = agent.CompanyName,
                                                                Target_Distribution__c = 25);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        String vendor2 = vendors[0].equalsIgnoreCase(agent.CompanyName) ? vendors[1] : vendors[0];
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendor2,
                                                                Target_Distribution__c = 75);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');
        
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');
        
        // throw test exception
        CDdLiveChatTransEventTriggerHandler.throwTestException = true;
        
        // start test
        Test.startTest();

        // create transfer event
        LiveChatTranscriptEvent lcte = new LiveChatTranscriptEvent(Type = 'Transfer', AgentId = agent.Id,
                                                                   LiveChatTranscriptId = lct.Id, Time = DateTime.now());
        insert(lcte);
        system.assertNotEquals(null, lcte.Id, 'LiveChatTranscriptEvent not created.');
        
        // update transfer event (just for trigger coverage)
        update(lcte);
        //call platform event
        CDdLiveChatTransEventTriggerHandler.trueUpVendorDistributionsPE(lct.Id);
        
        // stop test
        Test.stopTest();
        
        // check counter for vendor distributions
        vd1 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd1.Id];
        system.assertEquals(2, vd1.Actual_Chat_Count__c, 'VD1 actual chat count incorrect.');
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(-1, vd2.Actual_Chat_Count__c, 'VD2 actual chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransEventTriggerHandler.errorMessages.size() > 0, 'Exception not logged.');
    }

    static testMethod void testDeleteChatTranscriptEvent() {
        Support_Feature_Flag__c ffSetting = Support_Feature_Flag__c.getInstance();
        ffSetting.Disable_Delete_Transcript_Event__c = true;
        insert ffSetting;

        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                                FROM LiveChatButton
                                ORDER BY DeveloperName DESC LIMIT 1];

        
        // get agent
        User agent = [SELECT Id, CompanyName
        FROM User
        WHERE UserName = :agentUserName LIMIT 1];

        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');
        
        // throw test exception
        CDdLiveChatTransEventTriggerHandler.throwTestException = true;
        
        // start test
        Test.startTest();

        // create transfer event
        LiveChatTranscriptEvent lcte = new LiveChatTranscriptEvent(Type = 'Transfer', AgentId = agent.Id,
                                                                   LiveChatTranscriptId = lct.Id, Time = DateTime.now());
        insert(lcte);
        system.assertNotEquals(null, lcte.Id, 'LiveChatTranscriptEvent not created.');
        
        Boolean hasException = false;
        try {
            delete lcte;
        } catch(Exception e){
            hasException = true;
        }
        System.assert(hasException == true, 'No Exception was thrown on event delete');


        // stop test
        Test.stopTest();
        
       
    }

}