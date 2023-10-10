/**
 * CDdLiveChatTransTriggerHandlerV2Test
 *
 * @author     Sahil
 * @date  2021-12-27
 * @decription Test class for CDdLiveChatTransTriggerHandlerV2
 */

@isTest(seeAllData=false)
public class CDdLiveChatTransTriggerHandlerV2Test {
    public static Boolean callFutureMethod = true;

    @TestSetup
    static void makeData(){
        CDdContactTriggerHelper.insertCampaign();
        Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
        ftrFlag.Enable_LCT_Trigger_Optimization__c = true;
        insert ftrFlag;
    }

    @isTest
    static void link_transcript_to_case() {
        Trigger_Control_Panel__c tcp=new Trigger_Control_Panel__c();
        tcp.Name='Control Panel';
        tcp.Account_Trigger_Enabled__c=True;
        insert tcp;

        Account acc = new Account(Name='DoorDash HQ (123 Street)'); //,Market_Area__c='ATL - Atlanta');
        insert acc;

        Contact con = new Contact(
            FirstName='john',
            LastName='doe',
            Email='john@doe.com',
            AccountId=acc.Id);
        insert con;

        Opportunity opp = TDdOpportunityFactory.createOpportunity('test', acc.Id, con.Id, 'New');
        opp.Bulk_Activation__c = true;
        insert opp;

        List<OpportunityLineItem> items = TDdOpportunityFactory.createOppProducts(opp.Id);
        insert items;

        List<PricebookEntry> pricebookEntries = TDdOpportunityFactory.createPriceBookEntries(1);
        Id productId = [SELECT Id FROM Product2 LIMIT 1].Id;
        Asset ast = new Asset(  AccountId=acc.Id,ContactId=con.Id,
                              Opportunity__c = opp.Id, Name='testing',
                              Post_Sale_Activations_Case_Created__c = true,
                              Product2Id = productId);
        insert ast;

        Entitlement ent = new Entitlement(Name='Testing',AccountId=acc.Id, StartDate=Date.valueof(System.now().addDays(-2)),
                                          EndDate=Date.valueof(System.now().addYears(2)), AssetId=ast.Id);
        insert ent;

        EntitlementContact ec2 = new EntitlementContact(EntitlementId=ent.Id,ContactId=con.Id);
        insert ec2;

        Case c1 = new Case( ContactId=con.Id,  AccountId=con.AccountId, Subject='Test Subject',
                           chatkey__c = '123', EntitlementId=ent.Id, ChatWaitTime__c=15, ChatDuration__c=43,
                           Origin='Webform_B2B');
        insert c1;

        Case c2 = new Case(ContactId=con.Id, AccountId=con.AccountId,Subject='Test Subject',chatkey__c = '123',
                           EntitlementId=ent.Id, Origin='Webform_B2B');
        insert c2;

        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name FROM SlaProcess WHERE Name='Standard SLA'
                                                  and IsActive = true LIMIT 1];
        if (lstEntitlementProcess.size()>0){
            ent.SlaProcessId = lstEntitlementProcess[0].id;
            update ent;
        }

        LiveChatVisitor visitor = new LiveChatVisitor();

        insert visitor;

        LiveChatTranscript tx = new LiveChatTranscript(
            chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
            StartTime= datetime.newInstance(2017, 9, 15, 12, 31, 0), EndTime=datetime.newInstance(2017, 9, 15, 12, 32, 0),
            RequestTime=datetime.newInstance(2017, 9, 15, 12, 30, 0), DasherNo__c=2345, CustomerNo__c=35463,
            DeliveryNo__c=64754);

        insert tx;
        TriggerFactory.isTriggerExecuted = false;
        tx.caseId=c1.Id;
        update tx;

        tx = [ SELECT id, caseId, chatKey FROM LiveChatTranscript WHERE id = :tx.id ];

        System.assertEquals( c1.chatkey__c, tx.chatKey );
        System.assertEquals( c1.id, tx.caseId );

        TriggerFactory.isTriggerExecuted = false;
        delete tx;
        TriggerFactory.isTriggerExecuted = false;
        undelete tx;
    }

    /**
     *  @author: Tia Xuan
     *  @date: 2020-08
     *  @description    Test method for
     *                  BZAPSUP-732 --- Populate Pre-chat Info on Chat
     *                  Transcript and Update Case for Community Chats
    */
    @isTest
    static void associateChatIdsTest() {
        Account acct = TDdAccountFactory.createAccounts('test', 1, 'Consumer or Dasher')[0];
        insert acct;

        acct = [select Id, PersonContactId from Account where Id =: acct.Id];

        Contact ctc =  new Contact(
            Id = acct.PersonContactId,
            Email = 'test@test.com',
            CustomerNo__c = 123,
            DasherNo__c = 123);
        update ctc;

        Test.startTest();

        LiveChatTranscript tx = TDdCaseFactory.createTranscripts(1)[0];
        tx.Status='Missed';
        tx.Chat_First_Name__c = 'test';
        tx.Chat_Last_Name__c = 'test';
        insert tx;

        tx.CustomerEmail__c = 'test@test.com';
        tx.Channel__c = 'Consumer Community';
        update tx;

        tx = [ SELECT id, CustomerName__c, CustomerNo__c FROM LiveChatTranscript WHERE id = :tx.id ];
        System.assertEquals('test test', tx.CustomerName__c);
        System.assertEquals(123, tx.CustomerNo__c);


        tx = TDdCaseFactory.createTranscripts(1)[0];
        tx.Status='Missed';
        tx.Chat_First_Name__c = 'test';
        tx.Chat_Last_Name__c = 'test';
        tx.DasherEmail__c = 'test@test.com';
        tx.Channel__c = 'Dasher Community';
        insert tx;

        tx = [ SELECT id, DasherName__c, DasherNo__c FROM LiveChatTranscript WHERE id = :tx.id ];
        System.assertEquals('test test', tx.DasherName__c);
        System.assertEquals(123, tx.DasherNo__c);

        Test.stopTest();
    }

    /**
     *  @author: salesforce
     *  @date: 2020-09-16
     *  @description    Test method for setPreferredVendor
    */
    @isTest
    static void setPreferredVendorTestNoTime() {

        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];

        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');

        // get vendor site values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }

        // create vendor distributions (one at 40%, one at 60%)
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[0],
                                                                Target_Distribution__c = 40,
                                                                Actual_Chat_Count__c = 0);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[1],
                                                                Target_Distribution__c = 60,
                                                                Actual_Chat_Count__c = 0);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');

        // throw test exception
        CDdLiveChatTransTriggerHandlerV2.throwTestException = true;

        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // start test
        Test.startTest();

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');

        // stop test
        Test.stopTest();

        // check for preferred vendor
        lct = [SELECT Id, Preferred_Vendor__c
               FROM LiveChatTranscript
               WHERE Id = :lct.Id];
        system.assertEquals(vd2.Vendor__c, lct.Preferred_Vendor__c, 'Preferred vendor incorrect.');

        // check for vendor chat count
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(1, vd2.Actual_Chat_Count__c, 'VD2 chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransTriggerHandlerV2.errorMessages.size() > 0, 'Exception not logged.');
    }

    /**
     *  @author: salesforce
     *  @date: 2020-09-16
     *  @description    Test method for setPreferredVendor
    */
    @isTest
    static void setPreferredVendorTestWithTime() {

        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];

        // create chat button distribution with no time
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');

        // create chat button distribution with start/end time
        Chat_Button_Distribution__c cbd2 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName,
                                                                           Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                                           End_Time__c = Time.newInstance(22, 0, 0, 0));
        insert(cbd2);
        system.assertNotEquals(null, cbd2.Id, 'CBD2 not created.');

        // force test to use time that fits within start/end time
        CDdLiveChatTransTriggerHandlerV2.nowTime = Time.newInstance(12, 0, 0, 0);

        // get vendor site values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }

        // create vendor distributions for cbd1 (one at 40%, one at 60%)
        Vendor_Distribution__c vd1_1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                  Vendor__c = vendors[0],
                                                                  Target_Distribution__c = 40,
                                                                  Actual_Chat_Count__c = 0);
        insert(vd1_1);
        system.assertNotEquals(null, vd1_1.Id, 'VD1_1 not created.');
        Vendor_Distribution__c vd1_2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                  Vendor__c = vendors[1],
                                                                  Target_Distribution__c = 60,
                                                                  Actual_Chat_Count__c = 0);
        insert(vd1_2);
        system.assertNotEquals(null, vd1_2.Id, 'VD1_2 not created.');

        // create vendor distributions for cbd2 (one at 40%, one at 60%)
        Vendor_Distribution__c vd2_1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd2.Id,
                                                                  Vendor__c = vendors[0],
                                                                  Target_Distribution__c = 40,
                                                                  Actual_Chat_Count__c = 0);
        insert(vd2_1);
        system.assertNotEquals(null, vd2_1.Id, 'VD2_1 not created.');
        Vendor_Distribution__c vd2_2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd2.Id,
                                                                  Vendor__c = vendors[1],
                                                                  Target_Distribution__c = 60,
                                                                  Actual_Chat_Count__c = 0);
        insert(vd2_2);
        system.assertNotEquals(null, vd2_2.Id, 'VD2_2 not created.');

        // throw test exception
        CDdLiveChatTransTriggerHandlerV2.throwTestException = true;

        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // start test
        Test.startTest();

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');

        // stop test
        Test.stopTest();

        // check for preferred vendor
        lct = [SELECT Id, Preferred_Vendor__c
               FROM LiveChatTranscript
               WHERE Id = :lct.Id];
        system.assertEquals(vd2_2.Vendor__c, lct.Preferred_Vendor__c, 'Preferred vendor incorrect.');

        // check for vd1_2 vendor chat count
        vd1_2 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd1_2.Id];
        system.assertEquals(0, vd1_2.Actual_Chat_Count__c, 'VD1_2 chat count incorrect.');

        // check for vd2_2 vendor chat count
        vd2_2 = [SELECT Id, Actual_Chat_Count__c
                 FROM Vendor_Distribution__c
                 WHERE Id = :vd2_2.Id];
        system.assertEquals(1, vd2_2.Actual_Chat_Count__c, 'VD2_2 chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransTriggerHandlerV2.errorMessages.size() > 0, 'Exception not logged.');
    }

    /**
     *  @author: salesforce
     *  @date: 2020-09-16
     *  @description    Test method for setPreferredVendor, skipping vendor distributions
    */
    @isTest
    static void setPreferredVendorSkipTest() {

        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];

        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName,
                                                                           Skip_Vendor_Distributions__c = true);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');

        // get vendor site values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }

        // create vendor distributions (one at 40%, one at 60%)
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[0],
                                                                Target_Distribution__c = 40,
                                                                Actual_Chat_Count__c = 0);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[1],
                                                                Target_Distribution__c = 60,
                                                                Actual_Chat_Count__c = 0);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');

        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // start test
        Test.startTest();

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');

        // stop test
        Test.stopTest();

        // check for no preferred vendor
        lct = [SELECT Id, Preferred_Vendor__c
               FROM LiveChatTranscript
               WHERE Id = :lct.Id];
        system.assertEquals(null, lct.Preferred_Vendor__c, 'Preferred vendor incorrect.');

        // check vendor chat count
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(0, vd2.Actual_Chat_Count__c, 'VD2 chat count incorrect.');
    }

    /**
     *  @author: Sahil
     *  @date: 2021-02-22
     *  @description    Test method for setPreferredVendor with platform events
    */
    @isTest
    static void setPreferredVendorWithPE() {

        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];

        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');

        // get vendor site values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }

        // create vendor distributions (one at 40%, one at 60%)
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[0],
                                                                Target_Distribution__c = 40,
                                                                Actual_Chat_Count__c = 0);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[1],
                                                                Target_Distribution__c = 60,
                                                                Actual_Chat_Count__c = 0);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');

        // throw test exception
        CDdLiveChatTransTriggerHandlerV2.throwTestException = true;

        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // start test
        Test.startTest();

        //set flag
        callFutureMethod = false;

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');

        // stop test
        Test.stopTest();

        // check for preferred vendor
        lct = [SELECT Id, Preferred_Vendor__c
               FROM LiveChatTranscript
               WHERE Id = :lct.Id];
        system.assertEquals(vd2.Vendor__c, lct.Preferred_Vendor__c, 'Preferred vendor incorrect.');

        // check for vendor chat count
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(1, vd2.Actual_Chat_Count__c, 'VD2 chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransTriggerHandlerV2.errorMessages.size() > 0, 'Exception not logged.');
    }

    /**
     *  @author: Mahesh Chouhan
     *  @date: 2021-07-19
     *  @description    Test method for setPreferredVendor with LCT platform event
    */
    @isTest
    static void setPreferredVendorWithLCTPE() {

        //Set Use LCTPlatformEvent
        Support_Feature_Flag__c supportFeatureFlag = new Support_Feature_Flag__c(Use_LCTPlatformEvent__c=true);
        insert supportFeatureFlag;

        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];

        // create chat button distribution
        Chat_Button_Distribution__c cbd1 = new Chat_Button_Distribution__c(Chat_Button_API_Name__c = lcb.DeveloperName);
        insert(cbd1);
        system.assertNotEquals(null, cbd1.Id, 'CBD1 not created.');

        // get vendor site values
        List<String> vendors = new List<String>();
        for (Schema.PicklistEntry ple : LiveChatTranscript.Actual_Vendor__c.getDescribe().getPicklistValues())
        {
            vendors.add(ple.getLabel());
        }

        // create vendor distributions (one at 40%, one at 60%)
        Vendor_Distribution__c vd1 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[0],
                                                                Target_Distribution__c = 40,
                                                                Actual_Chat_Count__c = 0);
        insert(vd1);
        system.assertNotEquals(null, vd1.Id, 'VD1 not created.');
        Vendor_Distribution__c vd2 = new Vendor_Distribution__c(Chat_Button_Distribution__c = cbd1.Id,
                                                                Vendor__c = vendors[1],
                                                                Target_Distribution__c = 60,
                                                                Actual_Chat_Count__c = 0);
        insert(vd2);
        system.assertNotEquals(null, vd2.Id, 'VD2 not created.');

        // throw test exception
        CDdLiveChatTransTriggerHandlerV2.throwTestException = true;

        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        // start test
        Test.startTest();

        //set flag
        callFutureMethod = false;

        // create chat transcript
        LiveChatTranscript lct = new LiveChatTranscript(LiveChatButtonId = lcb.Id, LiveChatVisitorId = lcv.Id);
        insert(lct);
        system.assertNotEquals(null, lct.Id, 'LiveChatTranscript not created.');

        // stop test
        Test.stopTest();

        // check for preferred vendor
        lct = [SELECT Id, Preferred_Vendor__c
               FROM LiveChatTranscript
               WHERE Id = :lct.Id];
        system.assertEquals(vd2.Vendor__c, lct.Preferred_Vendor__c, 'Preferred vendor incorrect.');

        // check for vendor chat count
        vd2 = [SELECT Id, Actual_Chat_Count__c
               FROM Vendor_Distribution__c
               WHERE Id = :vd2.Id];
        system.assertEquals(1, vd2.Actual_Chat_Count__c, 'VD2 chat count incorrect.');

        // confirm exception error message logged
        system.assert(CDdLiveChatTransTriggerHandlerV2.errorMessages.size() > 0, 'Exception not logged.');
    }

    /**
     * @author:     Jeegar
     * @date:       2021-04
     * @description Test SkipVendorSplit positive test
     * @jira:       BZAPSUP-1746
     */
    @isTest
    static void testSkipVendorSplitPositive() {
        List<Issue_Based_Routing_Map__mdt> ibRoutings = [SELECT Id, Customer_Type__c, Is_Active__c, Issue_Category__c,
                                                                Issue_Subcategory__c, Routing_Destination__c,Chat_Button_Id__c
                                                            FROM Issue_Based_Routing_Map__mdt
                                                            WHERE Is_Active__c = true];
        String issueCategory;
        String issueSubCategory;
        String expectedRouting;
        String chatButtonId;
        if(ibRoutings.size()> 0) {
            issueCategory = ibRoutings[0].Issue_Category__c;
            issueSubCategory = ibRoutings[0].Issue_Subcategory__c;
            issueSubCategory = ibRoutings[0].Issue_Subcategory__c.split(';')[0];
            expectedRouting = ibroutings[0].Routing_Destination__c;
            chatButtonId = ibRoutings[0].Chat_Button_Id__c;
        }
        System.assertNotEquals(null, issueCategory, 'Issue Category is null. Custom metadata not found');
        System.assertNotEquals(null, issueSubCategory, 'Issue SubCategory is null. Please check Custom metadata');
        System.assertNotEquals(null, expectedRouting, 'Expected Routing is null. Please check Custom metadata');
        System.assertNotEquals(null, chatButtonId, 'Chat Button Id is null. Please check Custom metadata');
        Boolean skipVendorDistribution = CDdLiveChatTransTriggerHandlerV2.skipVendorSplit(issueCategory,issueSubCategory,
                                                                                             false, chatButtonId);
        System.assertEquals(true, skipVendorDistribution, 'Expected True for skipVendorDistribution received False.');

    }
    /**
     * @author:     Jeegar
     * @date:       2021-04
     * @description Test SkipVendorSplit negative test
     * @jira:       BZAPSUP-1746
     */
    @isTest
    static void testSkipVendorSplitNegative() {
        List<Issue_Based_Routing_Map__mdt> ibRoutings = [SELECT Id, Customer_Type__c, Is_Active__c, Issue_Category__c,
                                                                Issue_Subcategory__c, Routing_Destination__c,Chat_Button_Id__c
                                                            FROM Issue_Based_Routing_Map__mdt
                                                            WHERE Is_Active__c = true];
        String issueCategory;
        String issueSubCategory;
        String expectedRouting;
        String chatButtonId;
        if(ibRoutings.size()> 0) {
            issueCategory = ibRoutings[0].Issue_Category__c;
            issueSubCategory = ibRoutings[0].Issue_Subcategory__c;
            issueSubCategory = ibRoutings[0].Issue_Subcategory__c.split(';')[0];
            expectedRouting = ibroutings[0].Routing_Destination__c;
            chatButtonId = ibRoutings[0].Chat_Button_Id__c;
        }
        System.assertNotEquals(null, issueCategory, 'Issue Category is null. Custom metadata not found');
        System.assertNotEquals(null, issueSubCategory, 'Issue SubCategory is null. Please check Custom metadata');
        System.assertNotEquals(null, expectedRouting, 'Expected Routing is null. Please check Custom metadata');
        System.assertNotEquals(null, chatButtonId, 'Chat Button Id is null. Please check Custom metadata');
        Boolean skipVendorDistribution = CDdLiveChatTransTriggerHandlerV2.skipVendorSplit(issueCategory,issueSubCategory,
                                                                                             true, chatButtonId);
        System.assertEquals(false, skipVendorDistribution, 'Expected False for skipVendorDistribution received True.');

    }

    /**
     * @author:     Jeegar
     * @date:       2021-04
     * @description Test SkipVendorSplit negative test
     * @jira:       BZAPSUP-1746
     */
    @isTest
    static void getDefaultRoutingInfo() {
        Test.startTest();
        CDdIssueBasedRoutingHelper.RoutingInfo info = CDdLiveChatTransTriggerHandlerV2.getDefaultRoutingInfo();
        Test.stopTest();
        System.assertEquals(info.prioritizeVIP, true, 'Prioritize VIP defaults to TRUE');
        System.assertEquals(info.standardRouting, true, 'Standard Routing defaults to TRUE');
        System.assertEquals(info.doVendorSplit, true, 'doVendorSplit defaults to TRUE');

    }
    /**
     * @author Dinesh
     * @date: 2021-08
     * @description test method for setChatOwner
     *
     */

    @isTest
    static void testSetChatOwner()
    {
        List<Support_Assignment_Mapping__c> listSettings =new List<Support_Assignment_Mapping__c>();
        Support_Assignment_Mapping__c setting = new Support_Assignment_Mapping__c();
        setting.Chat_Button_Id__c ='5731a00000005iJAAQ';
        setting.Object__c ='chat';
        setting.Issue_Based_Queue__c ='Chat - Dx P2P Support';
        setting.Queue_Id__c ='00G2L000001XadMUAS';
        setting.Queue_Name__c ='Chat - Dx P2P Support';
        setting.Support_Assignment_Name__c = 'Chat - Dx P2P Support';
        setting.Name = 'Chat - Dx P2P Support';
        listSettings.add(setting);

        insert listSettings;

        Support_Feature_Flag__c featureflag = Support_Feature_Flag__c.getInstance();
        featureflag.Enable_Metadata_Skip_Vendor_Split__c = true;
        featureflag.LCT_Enable_Set_Owner_Assignment__c = true;
        upsert featureflag;

        system.debug(listSettings.size());
        Test.startTest();
        List<Support_Assignment_Mapping__c> sams = CDdSupportHelper.getSupportAssignmentRecordsByObject('chat');
        system.debug(sams.size());
        Support_Assignment_Mapping__c preferredVendor ;
        Support_Assignment_Mapping__c preferredVendorVIP;
        Support_Assignment_Mapping__c vipThresold;
        List<String> allSamQueueIds = new List<String>();
        for(Support_Assignment_Mapping__c sam:sams)
        {
            allSamQueueIds.add(sam.Queue_Id__c);
        }
        List<LiveChatTranscript> insertTranscripts = new List<LiveChatTranscript>();
        for(Support_Assignment_Mapping__c sam:sams)
        {
            system.debug('Here iam :::');
            LiveChatTranscript tx = TDdCaseFactory.createTranscripts(1)[0];
            tx.Chat_First_Name__c = 'test';
            tx.Chat_Last_Name__c = 'test';
            tx.CustomerEmail__c = 'test@test.com';
            tx.Channel__c = 'Consumer Community';
            tx.Status='Missed';
            tx.DasherEmail__c = 'test@test.com';
            if(sam.Is_VIP__c && sam.Threshold__c)
            {
                tx.Is_VIP__c= true;
                tx.Cx_VIP_Pref_Vendor_WT_Over_Threshold__c= true;
            }
            else if(sam.Is_VIP__c && sam.Preferred_Vendor__c != null)
            {
                tx.Is_VIP__c= true;
                tx.Preferred_Vendor__c = sam.Preferred_Vendor__c;
            }
            else if(sam.Preferred_Vendor__c != null)
            {
                tx.Preferred_Vendor__c = sam.Preferred_Vendor__c;
            }
            if(sam.Issue_Based_Queue__c!= null){
                tx.Issue_Based_Queue__c = sam.Issue_Based_Queue__c;
            }
            tx.LiveChatButtonId = sam.Chat_Button_Id__c;
            insertTranscripts.add(tx);
        }
        insert insertTranscripts;
        List<LiveChatTranscript> txList = new list<LiveChatTranscript>([select Id,Name,ownerId from LiveChatTranscript]);
        Test.stopTest();
        system.debug(txList);
        for(LiveChatTranscript tx:txList)
        {
            System.assertEquals(true,allSamQueueIds.contains(tx.ownerId), 'QueueId Matched');
        }
    }


    /**
     * @author:     Nayana
     * @date:       2021-11
     * @description Test Customer Segment logic
     * @jira:       BIZS-527
     */
    @isTest
    static void testCustomerSegmentmapping(){
        List<Customer_Segment_Mapping__c> lstCustomerSetting =new List<Customer_Segment_Mapping__c>();
        lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test1',Audience_Attribute_Number__c =94,Customer_Segment__c='VIP1',Is_Active__c=true,Is_VIP__c=true));
        lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test2',Audience_Attribute_Number__c =98,Customer_Segment__c='VIP2',Is_Active__c=true,Is_VIP__c=true));
        insert lstCustomerSetting;

        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];

        Audience_Attribute__c a1 = new Audience_Attribute__c(email__c ='testuservip@gmail.com',VIP__c=94);
        insert a1;

        List<Audience_Attribute__c> vipList = [SELECT Id, Email__c,VIP__c FROM Audience_Attribute__c WHERE email__c ='testuservip@gmail.com' AND VIP__c>0];
        System.assertEquals(94, vipList[0].VIP__c, 'Query should return the record');

        LiveChatTranscript testChatTranscript = TDdCaseFactory.createTranscripts(1)[0];
        testChatTranscript.Issue__c	= 'Account Help';
        testChatTranscript.Issue_Subcategory__c	= CDdSupportConstants.CHAT_TRANS_ISSUE_ACCT_SETTINGS;
        testChatTranscript.Preferred_Vendor__c = 'TaskUs';
        testChatTranscript.Location = 'NULL,australia';
        testChatTranscript.CustomerEmail__c = 'testuservip@gmail.com';
        testChatTranscript.LiveChatButtonId = lcb.Id;
        List<LiveChatTranscript> lstChats = new List<LiveChatTranscript>();
        lstChats.add(testChatTranscript);
        Test.startTest();
        CDdLiveChatTransTriggerHandlerV2.setPreferredVendor(lstChats);
        Test.stopTest();
         System.assertEquals('VIP1', lstChats[0].Customer_Segment__c, 'Method should set Customer Segment value to VIP1');
    }

    /**
     * @author:     Sahil
     * @date:       2022-01-10
     * @description Test populating aggregate time of transcripts on related case
     * @jira:       BIZS-814
    */
    @isTest
    static void testPopulateTimesOnCases() {
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        //insert a case to attach with the transcript
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = '2445';
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Customer_Type__c = 'Consumer';
        insert casesToTest;

        // start test
        Test.startTest();
        LiveChatTranscript tx = TDdCaseFactory.createTranscripts(1)[0];
        tx.LiveChatButtonId = lcb.Id;
        tx.LiveChatVisitorId = lcv.Id;
        tx.Chat_First_Name__c = 'test';
        tx.Chat_Last_Name__c = 'test';
        tx.CustomerEmail__c = 'test@test.com';
        tx.Channel__c = 'Consumer Community';
        tx.DasherEmail__c = 'test@test.com';
        tx.ChatKey = '2445';
        tx.CaseId = casesToTest[0].Id;
        insert tx;
        system.assertNotEquals(null, tx.Id, 'LiveChatTranscript not created.');

        //update transcript status
        tx.Status = 'Completed';
        update tx;
        // stop test
        Test.stopTest();

        Case caseFromDb = [SELECT Chat_Type__c,ChatWaitTime__c,ChatDuration__c FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        System.assertEquals('Served Chat', caseFromDb.Chat_Type__c, 'Chat type should be in Served status');
        System.assertEquals(60.0, caseFromDb.ChatWaitTime__c, 'wait time should be 60 seconds');
        System.assertEquals(60.0, caseFromDb.ChatDuration__c, 'duration should be 60 seconds');
    }

    /**
     * @author:     Sahil
     * @date:       2022-01-10
     * @description Test populating transcript with cases based on chatkeys
     * @jira:       BIZS-814
    */
    @isTest
    static void testPopulateCaseWithChatKey() {
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        //insert a case to attach with the transcript
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = '12345';
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Customer_Type__c = 'Consumer';
        insert casesToTest;

        // start test
        Test.startTest();
        LiveChatTranscript tx = TDdCaseFactory.createTranscripts(1)[0];
        tx.LiveChatButtonId = lcb.Id;
        tx.LiveChatVisitorId = lcv.Id;
        tx.Chat_First_Name__c = 'test';
        tx.Chat_Last_Name__c = 'test';
        tx.CustomerEmail__c = 'test@test.com';
        tx.Channel__c = 'Consumer Community';
        tx.DasherEmail__c = 'test@test.com';
        tx.ChatKey = '12345';
        tx.CaseId = casesToTest[0].Id;
        insert tx;
        system.assertNotEquals(null, tx.Id, 'LiveChatTranscript not created.');

        //update transcript status
        tx.Status = 'Completed';
        update tx;
        // stop test
        Test.stopTest();

        LiveChatTranscript lctFromDb = [SELECT CaseId FROM LiveChatTranscript WHERE Id =:tx.Id LIMIT 1];
        System.assertEquals(casesToTest[0].Id, lctFromDb.CaseId, 'transcript and case should be linked');
    }

    /**
     * @author:     Sahil
     * @date:       2022-01-10
     * @description Test populating customer's name on related case
     * @jira:       BIZS-814
    */
    @isTest
    static void testPopulateNameOnCases() {
        // get random live chat button
        LiveChatButton lcb = [SELECT Id, DeveloperName
                              FROM LiveChatButton
                              ORDER BY DeveloperName ASC LIMIT 1];
        // create chat visitor
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert(lcv);
        system.assertNotEquals(null, lcv.Id, 'LiveChatVisitor not created.');

        //insert a case to attach with the transcript
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = '1122';
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Customer_Type__c = 'Consumer';
        insert casesToTest;

        // start test
        Test.startTest();
        LiveChatTranscript tx = TDdCaseFactory.createTranscripts(1)[0];
        tx.LiveChatButtonId = lcb.Id;
        tx.LiveChatVisitorId = lcv.Id;
        tx.Chat_First_Name__c = 'test';
        tx.Chat_Last_Name__c = 'test';
        tx.CustomerEmail__c = 'test@test.com';
        tx.Channel__c = 'Consumer Community';
        tx.DasherEmail__c = 'test@test.com';
        tx.ChatKey = '1122';
        insert tx;
        system.assertNotEquals(null, tx.Id, 'LiveChatTranscript not created.');

        //update transcript status
        tx.Status = 'Completed';
        update tx;
        // stop test
        Test.stopTest();

        Case caseFromDb = [SELECT SuppliedName,Full_Name__c  FROM Case WHERE Id =:casesToTest[0].Id LIMIT 1];
        System.assertEquals('test test', caseFromDb.SuppliedName, 'Supplied Name should be populated');
        System.assertEquals('test test', caseFromDb.Full_Name__c, 'Full Name should be populated');
    }

    /**
     * @author:     Sahil
     * @date:       2022-01-10
     * @description Test transcript optimization helper
     * @jira:       BIZS-814
    */
    @isTest
    static void testOptimizationHelper() {
        //insert a case to attach with the transcript
        List<Case> casesToTest = TDdCaseFactory.createCaseRecords(1,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        casesToTest[0].ChatKey__c = '8988';
        casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        casesToTest[0].Customer_Type__c = 'Consumer';
        CDdLiveChatTransOptimizationHelper.setSObjectToInsert('Case', casesToTest);

        // start test
        Test.startTest();
        LiveChatTranscript tx = TDdCaseFactory.createTranscripts(1)[0];
        tx.ChatKey = '8988';

        insert tx;
        system.assertNotEquals(null, tx.Id, 'LiveChatTranscript not created.');

        //update transcript status
        tx.Status = 'Completed';
        CDdLiveChatTransOptimizationHelper.setSobjectToUpdate('LiveChatTranscript',tx.Id,'Status','Completed');
        // stop test
        Test.stopTest();
    }

    /**
     * @author:     Mahesh
     * @date:       2022-04
     * @description Test method to test handleDispatchResponse
     * @jira:       BIZS-916
    */
    @isTest
    static void testHandleDispatchResponse() {
        Dispatch_Settings__c setting = VTestUtil.createDispatchSettings();
        setting.Use_ERS_API__c = true;
        setting.Dispatch_ERS_Endpoint__c = 'test';
        setting.Dispatch_ERS_Token__c = 'test';
		insert setting;

        Test.startTest();
        LiveChatTranscript tx = TDdCaseFactory.createTranscripts(1)[0];
        tx.DispatchRQResponse__c = VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE;
        insert tx;
        Test.stopTest();

        LiveChatTranscript expectedTx = [SELECT ID, Business_Vertical_ID__c, DispatchRQStatus__c
                                         FROM LiveChatTranscript
                                         WHERE ID =:tx.Id];
        System.assertEquals('123456', expectedTx.Business_Vertical_ID__c, 'Business Vertical ID is not same as expected.');
        System.assertEquals('Success', expectedTx.DispatchRQStatus__c, 'DispatchRQStatus is not same as expected.');
    }
}