/**
 * CDdCaseTriggerHandlerV2Test
**/
@isTest
public class CDdCaseTriggerHandlerV2Test {

    public static final Id CASE_Menu_Update_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Menu Update').getRecordTypeId();
    public static final Id CASE_Support_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
    public static final Id ACCOUNT_Marketplace_RECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();

    public static final Id deliverTabletRT  = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Deliver Tablet').getRecordTypeId();
    public static final Id onboardingCaseRT  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();
    public static final Id apiCaseRT  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('API').getRecordTypeId();
    public static final Id CASE_POS_Integrations_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('POS Integrations').getRecordTypeId();
    public static final Id CASE_PHOTOSHOOT_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Photoshoot_Processing').getRecordTypeId();
    public static final Id PARTNER_INTEGRATION_POS_RECORDTYPEID = Schema.SObjectType.Partner_Integration__c.getRecordTypeInfosByDeveloperName().get('Point_Of_Sale').getRecordTypeId();

    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String SHIPPING_TYPE_NZ = CDdNameValuePairHelper.getTextValue('Shipping_Type_DHL_NZ');
    public static final String ZENKRAFT_PREFERNCE_NZ = CDdNameValuePairHelper.getTextValue('Zenkraft_Preference_DHL_NZ');

    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdSupportHelper.class
    };

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name =: CDdSupportConstants.PROFILE_SYS_ADM].Id;
    }

    static {
        CDdCaseDetailCreationHelper.configsForTest =
        [SELECT  Id, DeveloperName, Is_Active__c,Filter_Logic__c,Is_Test_Record__c,Sort_Order__c,
        (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
        Field_Value__c, Is_Active__c, Object_API_Name__c,
        Case_Shadow_Creation_Config__c,Rule_Number__c
        FROM Case_Shadow_Creation_Criteria__r WHERE Is_Active__c = TRUE)
        FROM Case_Shadow_Creation_Config__mdt
        WHERE Is_Active__c = TRUE AND Is_Test_Record__c = TRUE
        ORDER BY Sort_Order__c ASC];
    }
    /**
* @description Prepare and return the test running user
*/
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    @testSetup
    static void testSetup() {
        system.debug('test start test setup method');
        System.runAs(getTestRunUser()){
            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            testSettings.FireAutoResponseRules__c = true;
            insert testSettings;

            Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
            featureFlag.Enable_Qualtrics_Surveys__c = false;
            featureFlag.EnableReopen__c = true;
            featureFlag.EnableMXPAgentReopens__c = true;
            featureFlag.Enable_Tasks_on_Case_Feed__c = true;
            featureFlag.MXP_Support_E2C_Linking__c = true;
            featureFlag.Enable_Sendbird_API_Callouts__c = true;
            featureFlag.Publish_AWS_Events__c = true;
            featureFlag.Sendbird_Use_Future_Method__c = false;
            featureFlag.Disable_THQ_Callouts__c = true;
            upsert featureFlag;

            insert new Sendbird_Settings__c(Callout_Retries__c = 1);

            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_CPU_Time_Check__c = true;
            ftrFlag.Enable_Debug_Logs__c = true;
            insert ftrFlag;

            List<Opportunity> opplist = new List<Opportunity>();
            List<Contact> conlist = new List<Contact>();
            List<Account> accountsToInsert = new List<Account>();
            List<Case> casesToInsert = new List<Case>();

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            insert validation;
            Id realZipId = TDdAccountFactory.setupRealZIPData();

            List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 10, false);
            for (Integer i = 0; i < acclist.size(); i++) {

                acclist[i].BillingCountry = 'United States';
                if(i<5){
                    acclist[i].Name = 'AccountIdTest '+i;
                    acclist[i].Restaurant_ID__c = ''+i;
                    accountsToInsert.add(acclist[i]);
                }
                else if(i==5){
                    acclist[i].Name = 'Test Acc';
                    acclist[i].Phone = '7868799484';
                    acclist[i].BillingCountryCode = 'US';
                    acclist[i].Market_Area__c = 'Northern California - East Bay';
                    acclist[i].Business_ID__c = 123456;
                    acclist[i].Language__c = 'French';
                    acclist[i].RecordTypeId = ACCOUNT_Marketplace_RECORDTYPEID;
                    accountsToInsert.add(acclist[i]);
                }
                else if(i==8){
                    acclist[i].Name = 'Test Acc1';
                    acclist[i].Phone = '7868793484';
                    acclist[i].BillingCountryCode = 'US';
                    acclist[i].Market_Area__c = 'Northern California - East Bay';
                    acclist[i].Business_ID__c = 183456;
                    acclist[i].Language__c = 'French';
                    acclist[i].RecordTypeId = ACCOUNT_Marketplace_RECORDTYPEID;
                    acclist[i].Is_Partner__c = 'Yes';
                    accountsToInsert.add(acclist[i]);
                }
                else if(i==9){
                    acclist[i].Name = 'Test Acc2';
                    acclist[i].Phone = '7861799484';
                    acclist[i].BillingCountryCode = 'US';
                    acclist[i].Market_Area__c = 'Northern California - East Bay';
                    acclist[i].Business_ID__c = 123956;
                    acclist[i].Language__c = 'French';
                    acclist[i].RecordTypeId = ACCOUNT_Marketplace_RECORDTYPEID;
                    accountsToInsert.add(acclist[i]);
                }
                else if(i==6 || i==7){
                    acclist[i].Address_Latitude__c = 37.785171;
                    acclist[i].Address_Longitude__c = -122.396162;
                    acclist[i].RealZip__RealZip__c = realZipId;
                    acclist[i].RecordTypeId = ACCOUNT_Marketplace_RECORDTYPEID;
                    if(i==6)
                        acclist[i].Name = 'Photoshoot Account 0';
                    if(i==7)
                        acclist[i].Name = 'Photoshoot Account 1';
                    accountsToInsert.add(acclist[i]);
                }


            }
            Test.startTest();

            insert accountsToInsert;
            Account testAcc =[Select Id From Account where Name = 'Test Acc' limit 1];
            Account testAcc1 =[Select Id From Account where Name = 'Test Acc1' limit 1];

            // insert entitlement
            List<Entitlement> entiltlementLst = new List<Entitlement>();
            Entitlement entmRec = new Entitlement(Name='MxSx - National', AccountId =testAcc1.id);
            entiltlementLst.add(entmRec);
            insert entiltlementLst;
            Map<string,string> IdMetadataMap = new Map<string,string>();
            Id_Metadata__mdt IdMetDataRec = new Id_Metadata__mdt(MasterLabel='MxSx - National',DeveloperName='Mx_Entitlement_Id', Category__c= '18 Digit', Id__c= string.valueof(entmRec.id));
            IdMetadataMap.put(IdMetDataRec.DeveloperName, IdMetDataRec.Id__c);
            system.debug('IdMetadataMap'+IdMetadataMap);
            CDdCustomMetadata.IdMetadata = IdMetadataMap;


            Contact con1 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => accountsToInsert[0].Id,
                'FirstName' => 'Test Contact 1'
                    }, false);
            conlist.add(con1);

            Contact con2 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => testAcc.Id
                    }, false);
            conlist.add(con2);

            Contact con3 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => testAcc1.Id
                    }, false);
            con3.firstName = 'TestFn';
            con3.LastName = 'TestLn';
            con3.Email = 'testfnln23@test.com';
            con3.Birthdate = Date.newInstance(1991, 9, 29);
            conlist.add(con3);

            Contact con4 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => accountsToInsert[6].Id
                    }, false);
            con4.firstName = 'TestPhoto';
            con4.LastName = 'shoot';
            con4.Email = 'testphotoshoot13@test.com';
            con4.Phone = '+1 914-378-0888';
            conlist.add(con4);

            List<Account> listPhotoshootAccounts = [Select Id From Account where Name = 'Photoshoot Account 1' OR Name = 'Photoshoot Account 0'];
            Contact photoshootContact1 = TDdAccountFactory.createContacts(1, listPhotoshootAccounts[0].Id)[0];
            Contact photoshootContact2 = TDdAccountFactory.createContacts(1, listPhotoshootAccounts[1].Id)[0];
            photoshootContact1.firstName = 'PhotoshootContact1';
            photoshootContact1.lastName = 'PhotoshootContact1';
            photoshootContact1.Email = 'photoshootemail1@doordash.com';
            PhotoshootContact2.firstName = 'PhotoshootContact2';
            photoshootContact2.lastName = 'PhotoshootContact2';
            photoshootContact2.Email = 'photoshootemail2@doordash.com';
            conlist.add(photoshootContact1);
            conlist.add(photoshootContact2);
            insert conlist;
            Contact con = [Select id from contact where contact.firstName=:'PhotoshootContact1'Limit 1];
       // snapper api Snappr_API_Setting__mdt custom metadta
                     Snappr_API_Setting__mdt snpmdt = new Snappr_API_Setting__mdt(MasterLabel='US',DeveloperName='US', Region__c= 'US', Named_Credential__c='Snappr_US',Bookings_EndPoint__c='/bookings/',
                                                                              Shoot_Type__c='food',Duration__c=60,Gallery_URL_PostFix__c='/gallery?downloadingGallery=true',Bookings_URL_Prefix__c='https://app.snappr.co/partner/doordash-ca/bookings/',
                                                                              Photoshoot_Provider__c='Snappr',Merchant_Email_Template_Id__c='00X2L0000015y9w',Snappr_Email_Template_Id__c='00X2L0000015y9x',
                                                                              Org_Wide_Email_Address_Id__c='0D21a00000007BK',Snappr_Support_Contact_Id__c=con.Id);
            Map<string,Snappr_API_Setting__mdt> regionKeyDataMap = new Map<string,Snappr_API_Setting__mdt>();
            regionKeyDataMap.put(snpmdt.Region__c, snpmdt);
            CDdSnapprAPIHandler.regionKeyMap = regionKeyDataMap;
            CDdSnapprAPIHandler.regionalSetting = snpmdt;

            Opportunity photoshootOpportunity1 = TDdOpportunityFactory.createOpportunity('photoShootOpp1', listPhotoshootAccounts[0].Id,
                                                                                         photoshootContact1.id, 'New');
            Opportunity photoshootOpportunity2 = TDdOpportunityFactory.createOpportunity('photoShootOpp2', listPhotoshootAccounts[1].Id,
                                                                                         photoshootContact2.id, 'New');
            opplist.add(photoshootOpportunity1);
            opplist.add(photoshootOpportunity2);


            List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 20, false);
            for(Integer i = 0; i < 20; i++){
                if(i<5){
                    cslist1[i].Store_ID__c = '' +i;
                    cslist1[i].BusinessHours =null;
                    cslist1[i].Subject = 'setAccountIdUpdateTest'+i;
                    casesToInsert.add(cslist1[i]);
                }
                else if(i==5 || i==6){
                    cslist1[i].BusinessHours =null;
                    cslist1[i].CreateInternalComment__c = false;
                    cslist1[i].InternalCommentToFeed__c = null;
                    cslist1[i].RecordTypeId = CASE_Support_RECORDTYPEID;
                    casesToInsert.add(cslist1[i]);
                }

            }

            insert casesToInsert;

            Test.stopTest();

            List<Case> casesToInsert2 = new List<Case> {TDdCaseFactory.createCaseRecords(1, 'API')[0] /* non marketplace onboarding */};
            casesToInsert2.addAll(TDdCaseFactory.createCaseRecords(8, 'Marketplace Onboarding'));
            casesToInsert2[2].Last_Blocked_Date_Time__c = system.now().addDays(-10);
            casesToInsert2[2].Status = 'Blocked';
            casesToInsert2[2].Case_Claimed__c = System.Now();
            casesToInsert2.add(TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0]);
            insert casesToInsert2;

        }
    }

    @isTest
    static void setAccountIdTest() {
        Test.startTest();
        List<Account> checkAccounts;
        List<Case> checkCases;
        checkAccounts = [SELECT Id, Name, Restaurant_ID__c FROM Account where name like 'AccountIdTest%'];
        Map<String, Id> AccountIDmap = new Map<String, Id>();
        for (Account a : checkAccounts) AccountIDmap.put(a.Restaurant_ID__c,a.Id);
        checkCases = [SELECT Id, AccountId, Store_ID__c, Account.Restaurant_ID__c FROM Case where Subject like 'setAccountIdUpdateTest%'];
        for (Case c: checkCases) {
            system.assertEquals(c.Account.Restaurant_ID__c, c.Store_Id__c);
            system.assertEquals(AccountIdmap.get(c.Store_ID__c), c.AccountId);
            c.Store_ID__c = null;
        }
        Test.stopTest();
    }

    @isTest
    static void setAccountIdUpdateTest() {
        System.runAs(getTestRunUser()){
            test.startTest();
            List<Case> Cases = new List<Case>();
            List<Case> checkCases;
            List<Account> checkAccounts = [SELECT Id, Name, Restaurant_ID__c FROM Account where name like 'AccountIdTest%'];
            Map<String, Id> AccountIDmap = new Map<String, Id>();
            for (Account a : checkAccounts) AccountIDmap.put(a.Restaurant_ID__c,a.Id);

            checkCases = [SELECT Id, AccountId, Store_ID__c, Account.Restaurant_ID__c FROM Case where Subject like 'setAccountIdUpdateTest%'];
            for (Case c: checkCases) {
                system.assertEquals(c.Account.Restaurant_ID__c, c.Store_Id__c);
                system.assertEquals(AccountIdmap.get(c.Store_ID__c), c.AccountId);
                c.Store_ID__c = null;
            }

            update checkCases;

            checkCases = [SELECT Id, AccountId, Store_ID__c, Account.Restaurant_ID__c FROM Case where Subject like 'setAccountIdUpdateTest%'];
            Integer i = 1;
            for (Case c: checkCases) {
                system.assertEquals(null, c.Store_ID__c);
                system.assertNotEquals(null, c.AccountId);  // Existing does not clear
                c.Store_ID__c = ''+i++;
            }
            test.stopTest();
        }
    }

    @isTest
    static void setAccountIdUpdateTest2() {
        System.runAs(getTestRunUser()){
            test.startTest();
            List<Case> Cases = new List<Case>();
            List<Case> checkCases;
            List<Account> checkAccounts = [SELECT Id, Name, Restaurant_ID__c FROM Account where name like 'AccountIdTest%'];
            Map<String, Id> AccountIDmap = new Map<String, Id>();
            Cases = [Select id from case where subject like 'setAccountIdUpdate2Test%'];

            // insert Cases;
            checkCases = [SELECT Id, AccountId, Store_ID__c, Account.Restaurant_ID__c FROM Case where subject like 'setAccountIdUpdate2Test%'];
            for (Case c: checkCases) {
                system.assertEquals(c.Account.Restaurant_ID__c, c.Store_Id__c);
                system.assertEquals(AccountIdmap.get(c.Store_ID__c), c.AccountId);
                c.Store_ID__c = null;
            }

            update checkCases;

            checkCases = [SELECT Id, AccountId, Store_ID__c, Account.Restaurant_ID__c FROM Case where subject like 'setAccountIdUpdate2Test%'];
            Integer i = 1;
            for (Case c: checkCases) {
                system.assertEquals(null, c.Store_ID__c);
                system.assertNotEquals(null, c.AccountId);  // Existing does not clear
                c.Store_ID__c = ''+i++;
            }



            update checkCases;

            checkCases = [SELECT Id, AccountId, Store_ID__c, Account.Restaurant_ID__c FROM Case where subject like 'setAccountIdUpdate2Test%'];
            for (Case c: checkCases) {
                system.assertEquals(c.Account.Restaurant_ID__c, c.Store_Id__c);
                system.assertEquals(AccountIdmap.get(c.Store_ID__c), c.AccountId);
            }
            test.stopTest();
        }
    }
    @isTest
    static void updateOpActDetailsTest1() {
        Contact con = [SELECT ID, AccountId FROM Contact WHERE FirstName = 'Test Contact 1'];
        Opportunity opp = (Opportunity)CDdTestDataFactory.createSObject('Opportunity', new Map<String,Object>{
            'AccountId' => con.AccountId,
            'ContactId'=>con.Id,
            'StageName'=>'New',
            'Name'=>'Test Opp'
            }, true);
        List<PricebookEntry> pricebookEntries = TDdOpportunityFactory.createPriceBookEntries(1);
        Id ProductId = [SELECT Id FROM Product2 LIMIT 1].Id;
        Asset asset = new Asset(Name = 'Test Asset', Status = 'Purchased', AccountId = opp.AccountId, Opportunity__c = opp.Id, Product2Id = ProductId);
        insert asset;
        system.debug('Asset is currently: ' + asset);
        Case testCase = TDdCaseFactory.createCaseRecords(1, 'Post-Sale Activations')[0];
        testCase.AssetId = asset.Id;
        testCase.Opportunity_Name__c = opp.Id;
        insert testCase;
        system.debug('Case is currently: ' + testCase);
        asset = [SELECT Id, Name, Status, Activation_Date__c, Deactivation_Date__c FROM Asset WHERE Id = :asset.Id];
        system.debug('Asset is now: ' + asset);
        test.startTest();
        testCase.Status = 'Closed';
        testCase.Activation_Date__c = System.Date.Today();
        update testCase;
        asset = [SELECT Id, Name, Status, Activation_Date__c, Deactivation_Date__c FROM Asset WHERE Id = :asset.Id];
        system.debug('Asset is now: ' + asset);
        system.assertEquals('Activated', asset.Status);
        system.assertNotEquals(null, asset.Activation_Date__c);

        test.stopTest();
    }

    @isTest
    static void updateOpActDetailsTest2() {
        Contact con = [SELECT ID, AccountId FROM Contact WHERE FirstName = 'Test Contact 1'];
        Opportunity opp = (Opportunity)CDdTestDataFactory.createSObject('Opportunity', new Map<String,Object>{
            'AccountId' => con.AccountId,
            'ContactId'=>con.Id,
            'StageName'=>'New',
            'Name'=>'Test Opp'
            }, true);
        List<PricebookEntry> pricebookEntries = TDdOpportunityFactory.createPriceBookEntries(1);
        Id ProductId = [SELECT Id FROM Product2 LIMIT 1].Id;
        Asset asset = new Asset(Name = 'Test Asset', Status = 'Purchased', AccountId = opp.AccountId, Opportunity__c = opp.Id, Product2Id = ProductId);
        insert asset;
        system.debug('Asset is currently: ' + asset);
        Case testCase = TDdCaseFactory.createCaseRecords(1, 'Post-Sale Activations')[0];
        testCase.AssetId = asset.Id;
        testCase.Opportunity_Name__c = opp.Id;
        insert testCase;
        system.debug('Case is currently: ' + testCase);
        asset = [SELECT Id, Name, Status, Activation_Date__c, Deactivation_Date__c FROM Asset WHERE Id = :asset.Id];
        system.debug('Asset is now: ' + asset);
        test.startTest();
        testCase.Deactivation_Date__c = System.Date.Today();
        testCase.Status = 'Closed';
        update testCase;
        asset = [SELECT Id, Name, Status, Activation_Date__c, Deactivation_Date__c FROM Asset WHERE Id = :asset.Id];
        system.debug('Asset is now: ' + asset);
        system.assertEquals('Deactivated', asset.Status);
        system.assertNotEquals(null, asset.Deactivation_Date__c);
        test.stopTest();
    }

    @isTest
    static void postInternalChatterFeedTestUpdate() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Integer dataVol = 2;
            List<Case> caseRecords = [select id from Case where Recordtype.Name = 'Support'];
            dataVol = caseRecords.size();
            List<Task> tasksFromDB = [SELECT Id, WhatId, Priority, Status, Description
                                        FROM Task
                                        WHERE WhatId IN :caseRecords];
            system.assertEquals(0,tasksFromDB.size());
            for (Integer i = 0; i < dataVol; i++) {
                caseRecords[i].CreateInternalComment__c = true;
                caseRecords[i].InternalCommentToFeed__c = 'Just commenting on the Case.';
            }
            update caseRecords;
            Test.stopTest();
            List<Case> casesFromDB = [SELECT Id, CreateInternalComment__c, InternalCommentToFeed__c ,TotalCommentCount__c
                            FROM Case
                            WHERE ID IN :caseRecords];
            List<FeedItem> feedItemsFromDB = [  SELECT Id, Title, Body, Type, ParentId
                                                FROM FeedItem
                                                WHERE ParentId IN :caseRecords];
            tasksFromDB = [SELECT Id, WhatId, Priority, Status, Description
                                        FROM Task
                                        WHERE WhatId IN :caseRecords];
            for (Case c: casesFromDB) system.assertEquals(false, c.CreateInternalComment__c);
            system.assertEquals(datavol, casesFromDB.size());
            system.assertEquals(datavol, feedItemsFromDB.size());
            system.assertEquals(datavol, tasksFromDB.size());
            System.assertEquals(1, casesFromDB[0].TotalCommentCount__c, 'Total comment count should be 1');
        }
    }
    /**
    * @description - BZAP-6950 Changing PB to Trigger -- Update Tablet Delivered on Op
    */
    @isTest
    static void updateTabletDeliveredOnOppTest() {
        Account acc = [select Id from Account where Name = 'Test Acc' limit 1];

        Contact con = [select Id from Contact where AccountId =: acc.Id limit 1];

        Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
        opp.Tablet_Received_Date__c = null;
        insert opp;

        test.startTest();

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Tablet Requests')[0];
        cse.Tablet_Received_Date_2__c = DateTime.now();
        cse.Opportunity_Name__c = opp.Id;
        insert cse;

        Opportunity oppResult = [select Id,
                                        Tablet_Delivered__c,
                                        Tablet_Received_Date__c
                                from Opportunity
                                where Id =: opp.Id];
        System.assertEquals(oppResult.Tablet_Delivered__c, true);
        System.assertEquals(oppResult.Tablet_Received_Date__c, cse.Tablet_Received_Date_2__c);

        test.stopTest();
    }
    /**
    * @description - BZAP-6950 Changing PB to Trigger -- Include Marketing Kit on Tablet Request Case
    */
    @isTest
    static void includeMarketingKitTabletRequestTest() {

        test.startTest();
        Contact con = [SELECT ID, AccountId FROM Contact WHERE FirstName = 'Test Contact 1'];
        Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con.AccountId, con.id, 'Ready for Signature');
        opp.Tablet_Received_Date__c = null;
        insert opp;

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Tablet Requests')[0];
        cse.Request_Type__c = 'Ship to Merchant (New Tablet)';
        cse.AccountId = opp.AccountID;
        cse.Opportunity_Name__c = opp.Id;
        cse.Origin = 'New Tablet Request';
        cse.Include_Marketing_Kit__c = false;
        cse.Return_Shipping_Address_State__c = 'Florida';
        insert cse;

        test.stopTest();
        Case caseResult = [select   Id,
                                    Include_Marketing_Kit__c
                            from Case
                            where Id =: cse.Id];
        System.assertEquals(caseResult.Include_Marketing_Kit__c, true);
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- General Case Updates
    */
    @isTest
    static void generalCaseUpdatesTest1() {
        Account acc = [select Id from Account where Name = 'Test Acc'];
        acc.Language__c = 'French';
        update acc;

        test.startTest();

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Bulk Upload Request')[0];
        cse.AccountId = acc.Id;
        insert cse;

        Case caseResult =   [select Id,
                                    Language__c
                            from Case
                            where Id =: cse.Id];
        System.assertEquals(caseResult.Language__c, acc.Language__c);

        Test.stopTest();
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- General Case Updates
    */
    @isTest
    static void generalCaseUpdatesTest2() {
        test.startTest();

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Bulk Upload Request')[0];
        cse.Opportunity_Name__c = null;
        cse.AccountId = null;
        cse.Requester__c = UserInfo.getUserId();
        insert cse;

        Case caseResult = [ select Id,
                                    User_Email__c
                            from Case
                            where Id =: cse.Id];
        System.assertEquals(caseResult.User_Email__c, UserInfo.getUserEmail());

        cse.Requester__c = null;
        cse.Trial_Adjustment_Date__c = Date.today();
        update cse;

        Test.stopTest();
    }

    /**
    * @description -  BZAP-6950 Changing PB to Trigger -- Update Cases from Support Form in Mx Portal
    */
    @isTest
    static void updateCasesFromSupportFormMxPortalTest1(){

        Test.startTest();
         Account acc = [select Id from Account where Name = 'Test Acc'];
        acc.Language__c = 'French';
        update acc;

        List<Case> cslist = new List<Case>();
        Case cse1 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse1.Formstack_Source__c = 'Support Request - Mx Portal';
        cse1.Formstack_Category__c = 'Point of Sale Troubleshooting';
        cse1.Customer_Type__c = 'Merchant';
        cslist.add(cse1);



        Case cse2 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse2.Formstack_Source__c = 'Support Request - Mx Portal';
        cse2.Formstack_Category__c = 'Tablet and Tech Troubleshooting';
        cslist.add(cse2);

        Case cse3 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse3.Formstack_Source__c = 'Support Request - Mx Portal';
        cse3.Formstack_Category__c = 'Feedback / Other';
        cslist.add(cse3);

        Case cse4 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse4.Formstack_Source__c = 'Support Request - Mx Portal';
        cse4.Formstack_Type__c = 'Reopen Store - End Temporary Deactivation';
        cslist.add(cse4);

        Case cse5 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse5.Formstack_Source__c = 'Support Request - Mx Portal';
        cse5.Formstack_Type__c = 'Close Store - Permanent Deactivation';
        cslist.add(cse5);

        Case cse6 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse6.Formstack_Source__c = 'Support Request - Mx Portal';
        cse6.Formstack_Subcategory__c = 'Change of Ownership';
        cslist.add(cse6);



        insert cslist;
        Case caseResult1 =   [select Id,
                                    Issue_Category__c,
                                    Priority
                            from Case
                            where Id =: cse1.Id];
        System.assertEquals(caseResult1.Issue_Category__c, 'Order Protocol');
        System.assertEquals(caseResult1.Priority, 'Urgent');

        Case caseResult2 =[select Id,
                            Issue_Category__c,
                            Priority
                    from Case
                    where Id =: cse2.Id];
        System.assertEquals(caseResult2.Issue_Category__c, 'Tablet/Printer');
        System.assertEquals(caseResult2.Priority, 'Normal');

        Case caseResult3 =[  select  Id,
                                    Issue_Category__c
                            from Case
                            where Id =: cse3.Id];
        System.assertEquals(caseResult3.Issue_Category__c, 'Feedback');

        case caseResult4 =[select Id,
                            Issue_Category__c
                    from Case
                    where Id =: cse4.Id];
        System.assertEquals(caseResult4.Issue_Category__c, 'Reactivation');

        Case caseResult5 =   [select Id,
                                    Issue_Category__c
                            from Case
                            where Id =: cse5.Id];
        System.assertEquals(caseResult5.Issue_Category__c, 'Deactivation');

        case caseResult6 =[select Id,
                            Issue_Category__c
                    from Case
                    where Id =: cse6.Id];
        System.assertEquals(caseResult6.Issue_Category__c, 'Change of Ownership');


        Test.stopTest();
    }
    @isTest
    static void updateCasesFromSupportFormMxPortalTest2(){

        Test.startTest();
         Account acc = [select Id from Account where Name = 'Test Acc'];
        acc.Language__c = 'French';
        update acc;
        List<Case> cslist = new List<Case>();
        Case cse7 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse7.Formstack_Source__c = 'Support Request - Mx Portal';
        cse7.Formstack_Subcategory__c = 'Item-Level Tax Update';
        cslist.add(cse7);

        Case cse8 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse8.Formstack_Source__c = 'Support Request - Mx Portal';
        cse8.Formstack_Subcategory__c = 'Menu';
        cslist.add(cse8);

        Case cse9 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse9.Formstack_Source__c = 'Support Request - Mx Portal';
        cse9.Formstack_Subcategory__c = 'Onboarding';
        cslist.add(cse9);

        Case cse10 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse10.Formstack_Source__c = 'Support Request - Mx Portal';
        cse10.Formstack_Subcategory__c = 'Merchant Portal';
        cslist.add(cse10);

        Case cse11 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse11.Formstack_Source__c = 'Support Request - Mx Portal';
        cse11.Formstack_Subcategory__c = 'Legal Concern';
        cslist.add(cse11);

        Case cse12 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse12.Formstack_Source__c = 'Support Request - Mx Portal';
        cse12.Formstack_Category__c = 'Menu';
        cse12.Formstack_Subcategory__c = 'Other';
        cslist.add(cse12);

        Case cse13 = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse13.Formstack_Source__c = 'Support Request - Mx Portal';
        cse13.Formstack_Subcategory__c = 'Receiving a Tablet';
        cse13.Formstack_Category__c = 'Point of Sale Troubleshooting';
        cse13.Customer_Type__c = 'Merchant';
        cslist.add(cse13);

        insert cslist;

        Case caseResult7 =   [select Id,
                                    Issue_Category__c
                            from Case
                            where Id =: cse7.Id];
        System.assertEquals(caseResult7.Issue_Category__c, 'Payment');

        Case caseResult8 =[select Id,
                            Issue_Category__c
                    from Case
                    where Id =: cse8.Id];
        System.assertEquals(caseResult8.Issue_Category__c, 'Menu');

        Case caseResult9 =   [select    Id,
                                    Issue_Category__c
                            from Case
                            where Id =: cse9.Id];
        System.assertEquals(caseResult9.Issue_Category__c, 'Onboarding Issues');

        Case caseResult10 =[select Id,
                            Issue_Category__c
                    from Case
                    where Id =: cse10.Id];
        System.assertEquals(caseResult10.Issue_Category__c, 'Merchant Portal');

        Case caseResult11 =   [select Id,
                                    Issue_Category__c,
                                    Priority
                            from Case
                            where Id =: cse11.Id];
        System.assertEquals(caseResult11.Issue_Category__c, 'Account settings');
        System.assertEquals(caseResult11.Priority, 'High');


        Case caseResult12 =[select Id,
                            RecordTypeId
                    from Case
                    where Id =: cse12.Id];
        System.assertEquals(caseResult12.RecordTypeId, CASE_Menu_Update_RECORDTYPEID);

        Case caseResult13 =   [select Id,
                                    Customer_Type__c,
                                    RecordTypeId
                            from Case
                            where Id =: cse13.Id];
        System.assertEquals(caseResult13.Customer_Type__c, 'Merchant');
        System.assertEquals(caseResult13.RecordTypeId, CASE_Support_RECORDTYPEID);


        Test.stopTest();
    }

    /**
     * @description - BASD-15556 - Assign Support record type to MxSx - Menu and MxSx - Mx Success Assoicate cases
     */
    @isTest
    static void updateCasesFromSupportFormMxPortalTest3(){

        Test.startTest();
        Account acc = [SELECT Id
                       FROM Account
                       WHERE Name = 'Test Acc'];
        acc.Deck_Rank__c = 'Ace';
        update acc;

        Account acc1 = [SELECT Id
                        FROM Account
                        WHERE Name = 'Test Acc1'];
        acc1.Case_Routing_Override__c = 'Mx Success Associate Queue';
        update acc1;

        List<Case> cslist = new List<Case>();
        Case cse1 = TDdCaseFactory.createCaseRecords(1, 'Account Management')[0];
        cse1.Formstack_Source__c = 'Support Request - Mx Portal';
        cse1.Formstack_Category__c = 'Menu';
        cse1.Formstack_Subcategory__c = 'Menu Update';
        cse1.AccountId = acc.Id;
        cslist.add(cse1);

        Case cse2 = TDdCaseFactory.createCaseRecords(1, 'Account Management')[0];
        cse2.Formstack_Source__c = 'Support Request - Mx Portal';
        cse2.Formstack_Category__c = 'Getting Activated';
        cse2.Formstack_Subcategory__c = 'Add Banking Information';
        cse2.AccountId = acc1.Id;
        cslist.add(cse2);

        insert cslist;

        Case caseResult1 = [SELECT Id, RecordType.Name
                            FROM Case
                            WHERE Id =: cse1.Id];
        System.assertEquals(caseResult1.RecordType.Name, 'Support');

        Case caseResult2 = [SELECT Id, RecordType.Name
                            FROM Case
                            WHERE Id =: cse2.Id];
        System.assertEquals(caseResult2.RecordType.Name, 'Support');
        Test.stopTest();
    }

    /**
    * @description -  BZAP-6950 Changing PB to Trigger -- Update Account Owner from Handoff Cases
    */
    @isTest
    static void updateAccountOwnerFromHandoffCasesTest1() {
        Test.StartTest();
        List<Case> cslist = new List<Case>();
        List<User> testUsers = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID);
        testUsers[0].Username = 'formstack@doordash.com';
        insert testUsers;

        Contact con = [SELECT ID, AccountId FROM Contact WHERE FirstName = 'Test Contact 1'];
        Opportunity opp;
        System.runAs(getTestRunUser()){
            opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con.AccountId, con.id, 'Ready for Signature');
            opp.Tablet_Received_Date__c = null;
            insert opp;
            Case cse3 = TDdCaseFactory.createCaseRecords(1, 'Onboarding Manager Handoff')[0];
            cse3.Status = 'Request Approved';
            cse3.Post_Sale_Owner__c = testUsers[0].Id;
            cse3.Opportunity_Name__c = opp.Id;
            cslist.add(cse3);

            insert cslist;
        }
        Account accResult3 = [select Id,
                                    BypassValidationForProcessBuilder__c,
                                    Helper__c
                            from Account
                            where Id =: opp.AccountId];
        System.assertEquals(accResult3.Helper__c, testUsers[0].Id);
        Test.stopTest();
    }
    /**
     * @description BZAP-5898 Snappr Photoshoot case creation test
     */
    @isTest
    static void photoshootCaseSuccess() {
        System.runAs(getTestRunUser()){
            Test.startTest();

            // need to setup: Account.Real-Zip__RealZip__r.Submarket_Lookup__r.Region__c
            // or may be use Flordia address
            // updated per BZAP-9070 and BZAP-9508 (2/5/2021)
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Snappr_Success');
            mock.setStatusCode(201);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);

            Case marketplaceOnBoardingCase = createPhotoshootData(null);
            insert marketplaceOnBoardingCase;

            marketplaceOnBoardingCase.Menu_Preview_Links__c = 'Menu preview links';
            update marketplaceOnBoardingCase;
            Test.stopTest();

            Contact con = [Select id From Contact where AccountId=: marketplaceOnBoardingCase.AccountId limit 1];

            // snapper api Snappr_API_Setting__mdt custom metadta
                     Snappr_API_Setting__mdt snpmdt = new Snappr_API_Setting__mdt(MasterLabel='US',DeveloperName='US', Region__c= 'US', Named_Credential__c='Snappr_US',Bookings_EndPoint__c='/bookings/',
                                                                              Shoot_Type__c='food',Duration__c=60,Gallery_URL_PostFix__c='/gallery?downloadingGallery=true',Bookings_URL_Prefix__c='https://app.snappr.co/partner/doordash-ca/bookings/',
                                                                              Photoshoot_Provider__c=CDdSupportConstants.CASE_PHOTOSHOOT_VENDOR_SNAPPR,Merchant_Email_Template_Id__c='00X2L0000015y9w',Snappr_Email_Template_Id__c='00X2L0000015y9x',
                                                                              Org_Wide_Email_Address_Id__c='0D21a00000007BK',Snappr_Support_Contact_Id__c=con.Id);
            Map<string,Snappr_API_Setting__mdt> regionKeyDataMap = new Map<string,Snappr_API_Setting__mdt>();
            regionKeyDataMap.put(snpmdt.Region__c, snpmdt);
            CDdSnapprAPIHandler.regionKeyMap = regionKeyDataMap;
            CDdSnapprAPIHandler.regionalSetting = snpmdt;

            List<Case> photoshootCases  = [Select id, photo_provider__c, Kodakit_Event__c from Case where photo_provider__c != null AND Opportunity_Name__c = :marketplaceOnBoardingCase.Opportunity_Name__c];
            System.assertEquals(CDdSupportConstants.CASE_PHOTOSHOOT_VENDOR_SNAPPR, photoshootCases[0].photo_provider__c);
            Set<Id> photoshootCaseIds = new Set<Id>();
            photoshootCaseIds.add(photoshootCases[0].Id);
            CDdSnapprAPIHandler.createPhotoshoot(photoshootCaseIds);

        }
    }

    /**
     * @description BZAP-5898 Snappr Photoshoot case creation test
     */
    @isTest
    static void photoshootCaseNoCoverage() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            // need to setup: Account.Real-Zip__RealZip__r.Submarket_Lookup__r.Region__c
            // or may be use Flordia address
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Snappr_NoCoverage');
            mock.setStatusCode(400);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);

            Account acct = [Select id, name,BillingCity, BillingState, BillingStreet, BillingPostalCode, BillingCountry,Address_Latitude__c, Address_Longitude__c, Address_Time_Zone__c, Address_UTC_Offset__c from Account where name = 'Photoshoot Account 1' ][0];
            System.debug('longitude =  ' + acct.Address_Latitude__c);
            Contact photoshootContact1 = [Select id, AccountId from contact where contact.firstName=:'PhotoshootContact1'Limit 1];
            Opportunity photoshootOpportunity1 = TDdOpportunityFactory.createOpportunity('photoShootOpp1', photoshootContact1.AccountId, photoshootContact1.id, 'New');
            insert photoshootOpportunity1;
            //photoshootOpportunity1.Photoshoot_Date__c = System.today() + 1;
            //photoshootOpportunity1.Photoshoot_Time__c = '11:00 AM';
            //photoshootOpportunity1.stagename = 'Closed Won';
            //photoshootOpportunity1.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            //update photoshootOpportunity1;

            Case photoshootCase = new Case();
            photoshootCase.AccountId = acct.Id;
            photoshootCase.Address_Latitude__c = acct.Address_Latitude__c;
            photoshootCase.Address_Longitude__c = acct.Address_Longitude__c;
            photoshootCase.Address_Time_Zone__c = acct.Address_Time_Zone__c;
            photoshootCase.Address_UTC_Offset__c = acct.Address_UTC_Offset__c;
            photoshootCase.ContactId = photoshootOpportunity1.Decision_Maker__c;
            photoshootCase.Opportunity_Name__c = photoshootOpportunity1.Id;
            photoshootCase.Origin = 'Photoshoot Request';
            photoshootCase.OwnerId = Label.User_DoorDash_ApexAdmin;
            photoshootCase.Photo_Provider__c = 'Snappr';
            photoshootCase.Photoshoot_Date__c = System.today() + 1;
            photoshootCase.Photoshoot_Time__c = '11:00 AM';
            photoshootCase.RecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Photoshoot_Processing');
            photoshootCase.Return_Shipping_Address_City__c = acct.BillingCity;
            photoshootCase.Return_Shipping_Address_State__c = acct.BillingState;
            photoshootCase.Return_Shipping_Address_Street__c = acct.BillingStreet;
            photoshootCase.Return_Shipping_Address_Zip__c = acct.BillingPostalCode;
            photoshootCase.Shipping_Address_Country__c = acct.BillingCountry;
            photoshootCase.Status = 'Open';
            insert photoshootCase;

            Contact con = [Select id From Contact where AccountId=: acct.Id limit 1];
            // photoshootOpportunity1 = [Select id, Photoshoot_Date__c, Photoshoot_Time__c, stagename,
            //                             Account.Account_Type__c, Type, CreatedByID, Account.RealZip__RealZip__c,
            //                             Account.RealZip__RealZip__r.Submarket_lookup__c, Account.RealZip__RealZip__r.Submarket_lookup__r.Region__c
            //                             FROM Opportunity where name = 'photoShootOpp1'][0];

            List<Case> photoshootCases  = [Select id, photo_provider__c, Kodakit_Event__c from Case where photo_provider__c != null];
            System.assertEquals('Snappr', photoshootCases[0].photo_provider__c);
            Set<Id> photoshootCaseIds = new Set<Id>();
            photoshootCaseIds.add(photoshootCases[0].Id);
            // create Snappr_API_Setting__mdt instance for US

                     Snappr_API_Setting__mdt snpmdt = new Snappr_API_Setting__mdt(MasterLabel='US',DeveloperName='US', Region__c= 'US', Named_Credential__c='Snappr_US',Bookings_EndPoint__c='/bookings/',
                                                                              Shoot_Type__c='food',Duration__c=60,Gallery_URL_PostFix__c='/gallery?downloadingGallery=true',Bookings_URL_Prefix__c='https://app.snappr.co/partner/doordash-ca/bookings/',
                                                                              Photoshoot_Provider__c='Snappr',Merchant_Email_Template_Id__c='00X2L0000015y9w',Snappr_Email_Template_Id__c='00X2L0000015y9x',
                                                                              Org_Wide_Email_Address_Id__c='0D21a00000007BK',Snappr_Support_Contact_Id__c=con.Id);
            Map<string,Snappr_API_Setting__mdt> regionKeyDataMap = new Map<string,Snappr_API_Setting__mdt>();
            regionKeyDataMap.put(snpmdt.Region__c, snpmdt);
            CDdSnapprAPIHandler.regionKeyMap = regionKeyDataMap;
            CDdSnapprAPIHandler.regionalSetting = snpmdt;

            CDdSnapprAPIHandler.createPhotoshoot(photoshootCaseIds);
            Test.stopTest();

            photoshootCases  = [Select id, photo_provider__c, Kodakit_Event__c from Case where photo_provider__c != null];
            System.assertEquals('NoCoverage', photoshootCases[0].Kodakit_Event__c);
        }

    }
    /**
     * @description BZAP-7594
     */
    @isTest
    static void fillSubjectCaviarChatTest(){
        Test.startTest();
        Case cse = TDdCaseFactory.createCaseRecords(1, 'Caviar Support')[0];
        cse.Channel__c = 'Caviar Diner Community';
        cse.Origin = 'Chat';
        cse.Subject = '';
        cse.Caviar_Diner_Category__c = 'Account Settings';
        insert cse;

        Case cseResult = [  select  Id,
                                    Subject
                            from Case
                            where Id =: cse.Id];
        System.assertEquals(cseResult.Subject, 'Inbound Diner Help Center Chat - Account Settings');


        Test.stopTest();
    }
    /**
     * @description BZAPSUP-296 For Chat created Cases match Contact on Phone in addition to Email
     */
    @isTest
    static void fillContactOnCaseTest1(){
        Test.startTest();
        Account testAcct =[Select Id From Account where Name = 'Test Acc' limit 1];
        List<Contact> conrecs = new List<Contact>();
        Contact ctc1 = VTestUtil.createContact('Test Contact', 'Contact1', testAcct);
        ctc1.Email = 'test1@test.com';
        ctc1.CustomerNo__c = 123;
        conrecs.add(ctc1);

        Contact ctc2 = VTestUtil.createContact('Test Contact', 'Contact1', testAcct);
        ctc2.Email = 'test2@test.com';
        ctc2.DasherNo__c = 123;
        conrecs.add(ctc2);

        Contact ctc3 = VTestUtil.createContact('Test Contact', 'Contact1', testAcct);
        ctc3.Email = 'test3@test.com';
        conrecs.add(ctc3);

        insert conrecs;

        List<Case> caserecs = new List<Case>();
        Case cse1 = TDdCaseFactory.createCaseRecords(1, 'Caviar Support')[0];
        cse1.Origin = 'Chat';
        cse1.SuppliedEmail = 'test1@test.com';
        cse1.Customer_Type__c = 'Consumer';
        caserecs.add(cse1);

        Case cse2 = TDdCaseFactory.createCaseRecords(1, 'Caviar Support')[0];
        cse2.Origin = 'Chat';
        cse2.SuppliedEmail = 'test2@test.com';
        cse2.Customer_Type__c = 'Dasher';
        caserecs.add(cse2);

        Case cse3 = TDdCaseFactory.createCaseRecords(1, 'Caviar Support')[0];
        cse3.Origin = 'Chat';
        cse3.SuppliedEmail = 'test3@test.com';
        cse3.Customer_Type__c = 'Merchant';
        caserecs.add(cse3);

        insert caserecs;

        Case cseResult1 = [  select  Id,
                                    ContactId
                            from Case
                            where Id =: cse1.Id];
        System.assertEquals(cseResult1.ContactId, ctc1.Id);

        Case cseResult2 = [  select  Id,
                                    ContactId
                            from Case
                            where Id =: cse2.Id];
        System.assertEquals(cseResult2.ContactId, ctc2.Id);

        Case cseResult3 = [  select  Id,
                                    ContactId
                            from Case
                            where Id =: cse3.Id];
        System.assertEquals(cseResult3.ContactId, ctc3.Id);

        Test.stopTest();
    }
    /**
     * @description Convert Case PB to Trigger --- Case Process Builder (Caviar Onboarding)
     */
    @isTest
    static void caviarOnboardingTest1(){
        Test.startTest();
        List<case> caserecs = new List<Case>();
        Case cse1 = TDdCaseFactory.createCaseRecords(1, 'Caviar Onboarding')[0];
        cse1.Activations_Lead__c = UserInfo.getUserId();
        // cse1.Status = 'Tablet and Banking Configuration';
        caserecs.add(cse1);

        Case cse2 = TDdCaseFactory.createCaseRecords(1, 'Caviar Onboarding')[0];
        cse2.Activations_Lead__c = null;
        // cse2.Status = 'Tablet and Banking Configuration';
        caserecs.add(cse2);

        insert caserecs;

        caserecs[0].Status = 'Tablet and Banking Configuration';
        caserecs[1].Status = 'Tablet and Banking Configuration';
        update caserecs;

        Group grp = [   select Id
                        from Group
                        where Name = 'Caviar Onboarding Team'
                            and Type = 'Queue'];

        Case cseResult1 = [  select  Id,
                                    OwnerId,
                                    Activations_Lead__c
                            from Case
                            where Id =: cse1.Id];
        System.assertEquals(cseResult1.OwnerId, cseResult1.Activations_Lead__c);

        Case cseResult2 = [  select  Id,
                                    OwnerId
                            from Case
                            where Id =: cse2.Id];
        System.assertEquals(cseResult2.OwnerId, grp.Id);


        Test.stopTest();
    }
    /**
     * @description Convert Case PB to Trigger --- Caviar - Update Previous Case Owner
     */
    @isTest
    static void caviarUpdatePreviousCaseOwnerTest(){
        Test.startTest();

        User u = [  select Id
                    from User
                    where isActive = true
                        and Profile.Name =: 'System Administrator'
                        and Id !=: UserInfo.getUserId()][0];

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Caviar Support')[0];
        insert cse;

        cse.OwnerId = u.Id;
        update cse;


        Case cseResult = [  select  Id,
                                    Previous_Case_Owner__c
                            from Case
                            where Id =: cse.Id];
        System.assertEquals(cseResult.Previous_Case_Owner__c, UserInfo.getUserId());


        Test.stopTest();
    }

    /**
     * @description Convert Case PB to Trigger --- Caviar Support - Case Creation Flow
     */
    @isTest
    static void caviarCaseCreationFlowTest(){
        Test.startTest();

        Account testAcct =[Select Id From Account where Name = 'Test Acc' limit 1];

        Contact ctc = VTestUtil.createContact('Test Parent', 'Contact Parent', testAcct);
        ctc.Email = 'contact@testdd.com';
        insert ctc;

        testAcct.Decision_Maker__c = ctc.Id;
        update testAcct;

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Caviar Support')[0];
        cse.SuppliedEmail = 'contact@testdd.com';
        cse.Community_Form__c = 'Merchant - Caviar';
        insert cse;

        Case cseResult = [  select  Id,
                                    ContactId,
                                    AccountId
                            from Case
                            where Id =: cse.Id];
        System.assertEquals(cseResult.ContactId, ctc.Id);
        System.assertEquals(cseResult.AccountId, testAcct.Id);

        Test.stopTest();
    }
    /**
     * @description Test populating KB Article BZAPSUP-169
     */
    @isTest
    static void populateKBRecommendation() {
        List<Case> cslist = new List<Case>();
        List<Case> caseList = TDdCaseFactory.createCaseRecords(2, 'Support');
        Case caseThatShouldHaveKBPopulated = caseList[0];
        Case caseThatShouldNotHaveKBPopulated = caseList[1];

        caseThatShouldHaveKBPopulated.Customer_Type__c = 'Consumer';
        caseThatShouldHaveKBPopulated.Origin = 'Chat';
        caseThatShouldHaveKBPopulated.Chat_Issue__c = '';
        caseThatShouldHaveKBPopulated.comm_dependent_cx_Category__c = 'Account Issues';
        caseThatShouldHaveKBPopulated.communities_cx_Subcategory__c = 'Reactivate Account';

        caseThatShouldNotHaveKBPopulated.Origin = 'Chat';
        caseThatShouldHaveKBPopulated.Customer_Type__c = 'Dasher';

        Test.startTest();
        cslist.add(caseThatShouldNotHaveKBPopulated);
        cslist.add(caseThatShouldHaveKBPopulated);

        insert cslist;

        Test.stopTest();

        caseList = [SELECT Id, KB_Recommendation__c
                        FROM Case
                        WHERE Id =: caseThatShouldNotHaveKBPopulated.Id
                            OR ID =: caseThatShouldNotHaveKBPopulated.Id];

        System.assert(caseList.size() > 0 );

        for(Case currCase : caseList) {
            if(currCase.Id == caseThatShouldNotHaveKBPopulated.Id) {
                System.assert(currCase.KB_Recommendation__c == null);
            } else if(currCase.Id == caseThatShouldHaveKBPopulated.Id) {
                System.assert(currCase.KB_Recommendation__c != null);
            }
        }

    }

    /**
    * @author: Jeremy Johnson
    * @date 08/2020
    * @description: BZAP-8298: et Case Record Type to "POS Integrations" if a POS Order Protocol Change support request from the portal
    */
    @isTest
    static void testPosIntegrations() {
        List<String> queueNames = new List<String> {
            CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION,
            CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION_ENTERPRISE
        };
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);

        List<Group> owners = [select Id from Group where DeveloperName in ('POS_Integration_Requests', 'POS_Integration_Requests_Enterprise')];

        Id posIntgRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('POS_Integrations');

        Case oldCase = new Case(Id = '5000100000134rwAAA', RecordTypeId = posIntgRecordTypeId, OwnerId = owners[0].Id, POS_Go_Live_Date__c = System.today().addDays(-1));
        Map<Id, Case> oldMap = new Map<Id, Case>();
        oldMap.put(oldCase.Id, oldCase);

        Case newCase = oldCase.clone();
        newCase.Id = '5000100000134rwAAA';
        newCase.OwnerId = '0051a000000oOGuAAM';
        List<Case> newList = new List<Case> { newCase };

        CDdCaseTriggerHelperV2.updatePOSIntegrationsGoLiveDate(newList);
        System.assertEquals(System.today().addDays(5), newCase.POS_Go_Live_Date__c);

        newCase.RecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_ACCOUNT_MANAGEMENT);
        CDdCaseTriggerHelperV2.updatePOSIntegrationsRecordType(newList, oldMap);
        System.assertEquals(posIntgRecordTypeId, newCase.RecordTypeId);
    }
    // Commenting out as part of BZAP 9371
    /**
    * @author: Knick
    * @date 07/2020
    * @description: Test for Mx Rescue Process
    */
    /*@isTest
    static void testMxRescue() {
        test.startTest();
        User runningUser = TDdAccountFactory.createUsers(1)[0];  insert runningUser;
        system.runAs(runningUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = runningUser.id);
            validation.Bypass_Opportunity_Validations__c = true;  validation.Bypass_Case_Validations__c = true;
            insert validation;
            Account account = [Select Id, (Select Id From Contacts Limit 1) From Account where Name = 'Test Acc'];
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', account.Id, account.Contacts[0].Id, 'New', 'Enterprise_Marketplace');
            // 12345
            opp.RecordTypeId = CDdCaseTriggerHelper.opportunityMarketplaceRT;
            insert opp;
            //12345
            Case c = new Case(
                Status = 'New',
                RecordTypeId = CDdCaseTriggerHelper.caseActivationsTeamRT,
                OwnerId = runningUser.Id,
                AccountId = account.Id,
                Opportunity_Name__c = opp.Id,
                Op_Owner__c = runningUser.Id,
                Mx_Rescued__c = 'Gone Dark'
            );
            insert c;

                c.Status = 'Rejected';
                update c;

            Opportunity testOpp = [
                SELECT Id, Mx_Needs_Rescuing_Date__c, Rescue_Notes__c, Rescue_Status__c
                FROM Opportunity
                WHERE Id = :opp.Id
            ];
            system.assertNotEquals(null, testOpp.Mx_Needs_Rescuing_Date__c);
            system.assertNotEquals(null, testOpp.Rescue_Notes__c);
            system.assertEquals('Needs Rescuing', testOpp.Rescue_Status__c);
            c.Status = 'Closed'; update c;
            Case testCase = [SELECT Id, Mx_Rescued__c FROM Case WHERE Id = :c.Id];
            system.assertEquals('Rescued', testCase.Mx_Rescued__c);
            test.stopTest();
        }
    }*/
    /**
    * @author: Knick
    * @date 11/2020
    * @description: Test for checkMilestones
    */
    /* update: 05/07/2021
     * @author:- Narender
     * @desc:- updated test method to refer the metadta from test class insted of org metadta.  It will avoid hardcoded Id refreal and cause test failure
    */
    @isTest
    static void testMilestones() {
        test.startTest();
        // create emtitlement record
        List<Entitlement> entiltlementLst = new List<Entitlement>();
        // querying account from test setup method
        List<Account> accLst = [select id from Account where name like 'AccountIdTest%' Limit 1];
        Entitlement entmRec = new Entitlement(Name='MxSx - National', AccountId =accLst[0].id);
        entiltlementLst.add(entmRec);
        insert entiltlementLst;
        Map<string,string> IdMetadataMap = new Map<string,string>();
        Id_Metadata__mdt IdMetDataRec = new Id_Metadata__mdt(MasterLabel='MxSx - National',DeveloperName='Mx_Entitlement_Id', Category__c= '18 Digit', Id__c=entmRec.Id ); //string.valueOf(entmRec.id)
        IdMetadataMap.put(IdMetDataRec.DeveloperName, IdMetDataRec.Id__c);
        system.debug('IdMetadataMap'+IdMetadataMap);
        // assign value to metadta proeprty
        CDdCustomMetadata.IdMetadata = IdMetadataMap;

        Case c = new Case();
        c.Status = 'New';
        c.Origin = 'Web';
        c.RecordTypeId = CDdRecordTypeCase.mxMarketingRequests();
        insert c;
        c.Status = 'Open';
        c.Subject = 'Subject';
        c.Customer_Type__c = 'Merchant';
        c.Initial_Queue_Name__c = 'MxSx - National';
        update c;
        List<CaseMilestone> milestones;


            Case checkCase = [SELECT Id, EntitlementId FROM Case WHERE Id = :c.Id];
            system.assertEquals(CDdCaseTriggerHelperV2.MxEntitlementId, checkCase.EntitlementId);
            milestones = [SELECT Id, MilestoneType.Name, StartDate FROM CaseMilestone WHERE CaseId = :c.Id];
            c.Subject = 'Subject updated';
            update c;
        test.stopTest();
        if (milestones.size() > 0) {
            CaseMilestone checkStone = [SELECT Id, MilestoneType.Name, StartDate FROM CaseMilestone WHERE Id = :milestones[0].Id];
            // system.assert(checkStone.StartDate > milestones[0].StartDate);
            system.debug('Milestones: ' + milestones[0] + checkStone);
        }
    }
     /**
    * @author: Knick
    * @date 11/2020
    * @description: Test for setEnitlements
    */

    /* Update:-
     * @author:- Narender
     * @date 05/07/2021
     * @description: updated test method to refer to metadta created in test class so that test wont fail in target orgs
     *
     */
    @isTest
    static void testEntitlements() {
        test.startTest();
        // create emtitlement record
        List<Entitlement> entiltlementLst = new List<Entitlement>();
        // querying account from test setup method
        List<Account> accLst = [select id from Account where name like 'AccountIdTest%' Limit 1];
        Entitlement entmRec = new Entitlement(Name='MxSx - National', AccountId =accLst[0].id);
        entiltlementLst.add(entmRec);
        insert entiltlementLst;
        Map<string,string> IdMetadataMap = new Map<string,string>();
        Id_Metadata__mdt IdMetDataRec = new Id_Metadata__mdt(MasterLabel='MxSx - National',DeveloperName='Mx_Entitlement_Id', Category__c= '18 Digit', Id__c=entmRec.Id ); //string.valueOf(entmRec.id)
        IdMetadataMap.put(IdMetDataRec.DeveloperName, IdMetDataRec.Id__c);
        system.debug('IdMetadataMap'+IdMetadataMap);
        // assign value to metadta proeprty
        CDdCustomMetadata.IdMetadata = IdMetadataMap;

        Case c = new Case();
        c.Status = 'New';
        c.Origin = 'Web';
        c.RecordTypeId = CDdRecordTypeCase.mxMarketingRequests();
        insert c;

            c.Status = 'Open';
            c.Initial_Queue_Name__c = 'MxSx - National';
            update c;
        test.stopTest();
        Case checkCase = [SELECT Id, EntitlementId FROM Case WHERE Id = :c.Id];
        system.assertEquals(CDdCaseTriggerHelperV2.MxEntitlementId, checkCase.EntitlementId);
    }
    /**
    * @author: Tia Xuan
    * @date 09/2020
    * @description: BZAPSUP-922: Populate Decision Maker Email Field with Decision Maker Email
    */
    @isTest
    static void testPopulateDecisionMakerEmail() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Account testAcct =[Select Id From Account where Name = 'Test Acc' limit 1];

        Contact ctc = VTestUtil.createContact('Test Contact', 'Contact1', testAcct);
        ctc.Email = 'test@test.com';
        insert ctc;

        testAcct.Decision_Maker__c = ctc.Id;
        update testAcct;

        Test.startTest();
        Case cse = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        insert cse;

        cse.AccountId = testAcct.Id;
        update cse;

        Case c = [  select  Id,
                            Decision_Maker_Email__c
                    from Case
                    where Id =: cse.Id];
        System.assert(c.Decision_Maker_Email__c == 'test@test.com');

        Test.stopTest();
    }
    @isTest
    static void testAutomateOnboardingKPIs() {
        Test.startTest();

        List<Case> blockedCase = [SELECT Id FROM Case WHERE RecordTypeId = :onboardingCaseRT AND Status = 'Blocked'];
        blockedCase[0].Status = 'Open';
        update blockedCase[0];

        System.assertEquals(10, Integer.valueOf([SELECT Time_Spent_In_Blocked_Days__c FROM Case WHERE Id = :blockedCase[0].Id].Time_Spent_In_Blocked_Days__c));

        List<Case> cases = [SELECT Id FROM Case WHERE RecordTypeId IN (:onboardingCaseRT, :apiCaseRT)];

        update new List<Case>{
            new Case(Id = cases[0].Id, Status = 'Open'),
            new Case(Id = cases[1].Id, Status = 'Blocked', Last_Blocked_Date_Time__c = system.now()),
            new Case(Id = cases[2].Id, Status = 'Open'),
            new Case(Id = cases[3].Id, Stage__c = 'Under Review'),
            new Case(Id = cases[4].Id, Stage__c = 'Store Configuration'),
            new Case(Id = cases[5].Id, Stage__c = 'Menu Configuration'),
            new Case(Id = cases[6].Id, Stage__c = 'Onboarding Quality Check'),
            new Case(Id = cases[7].Id, Stage__c = 'Contacting Mx'),
            new Case(Id = cases[8].Id, Stage__c = 'Ready for Activation')
        };

        Map<Id, Case> queriedCases =  new Map<Id, Case>(
                [SELECT Id, Under_Review_Date_Time__c, Store_Configuration_Date_Time__c,
                    Menu_Configuration_Date_Time__c, Onboarding_Quality_Check_Date_Time__c,
                    Contacting_Mx_Date_Time__c, Ready_for_Activation_Date_Time__c, Stage__c,
                    Status, Time_Spent_In_Blocked_Days__c, Last_Blocked_Date_Time__c
                FROM Case WHERE Id IN: cases]);
        System.assertNotEquals(null, queriedCases.get(cases[1].Id).Last_Blocked_Date_Time__c);
        System.assertEquals(0, Integer.valueOf(queriedCases.get(cases[1].Id).Time_Spent_In_Blocked_Days__c));
        for(Integer k = 3; k <= 8; k++){
            for(Integer j = 1; j <= CDdCaseTriggerHelperV2.MARKETPLACE_ONBOARDING_CASE_STAGE_SORT_ORDER
                    .get(queriedCases.get(cases[k].Id).Stage__c.capitalize()); j++){
                System.assertNotEquals(null, queriedCases.get(cases[k].Id)
                    .get(CDdCaseTriggerHelperV2.MARKETPLACE_SORT_ORDER_KPI_FIELD.get(j)));
            }
        }
        Test.stopTest();
    }
    @isTest
    static void testUpdateDeliverTabletMilestone() {

        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 6, 'Marketplace');
        insert accs;
        List<Case> cases = new List<Case>();
        List<Case> onboardingCases = TDdCaseFactory.createCaseRecords(6, 'Marketplace Onboarding');
        List<Case> dtCases = TDdCaseFactory.createCaseRecords(6, 'Tablet Requests');
        cases.addAll(onboardingCases);
        for(Integer k=0; k<dtCases.size(); k++){
            dtCases[k].Return_Shipping_Address_State__c = 'Florida';
        }
        cases.addAll(dtCases);
        for(Integer k=0; k<accs.size(); k++){
            onboardingCases[k].AccountId = accs[k].Id;
            dtCases[k].AccountId = accs[k].Id;
            onboardingCases[k].Status = 'Opened';
            dtCases[k].Status = 'Opened';
            dtCases[k].Request_Type__c = 'Ship to Merchant (New Tablet)';//BASD-35044
        }
        insert cases;
        Milestone_Template__c templ = new Milestone_Template__c(
                Milestone_Type__c = 'Deliver Tablet',
                Milestone_Record_Type_ID_18__c = deliverTabletRT,
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = onboardingCaseRT,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = Userinfo.getUserId(),
                Default_Sort_Order__c = 1,
                Active__c = true,
                Completed_by_Stage__c = 'Contacting Mx',
                Reviewed_by_Stage__c = 'Onboarding Quality Check',
                Stage_Completed_Sort_Order__c = 0,
                Stage_Reviewed_Sort_Order__c = 0);
        insert templ;
        List<Milestone__c> tabletRequestMilestones = new List<Milestone__c>{
            new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[0].Id, Sort_Order__c = 1,
                    RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
            new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[1].Id, Sort_Order__c = 1,
                    RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
            new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[2].Id, Sort_Order__c = 1,
                    RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
            new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[3].Id, Sort_Order__c = 1,
                    RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
            new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[4].Id, Sort_Order__c = 1,
                    RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id),
            new Milestone__c(Status__c = 'Not Started', Case__c = onboardingCases[5].Id, Sort_Order__c = 1,
                    RecordTypeId = deliverTabletRT, Milestone_Template__c = templ.Id)
        };
        insert tabletRequestMilestones;
        Test.startTest();
        update new List<Case>{
            new Case(Id = dtCases[0].Id, Status = 'Shipped',Request_Type__c = 'Ship to Merchant (New Tablet, Printer)'),
            new Case(Id = dtCases[1].Id, Status = 'Shipped',Request_Type__c = 'Ship to Merchant (New Tablet, Printer)'),
            new Case(Id = dtCases[2].Id, Status = 'Received',Request_Type__c = 'Ship to Merchant (New Tablet, Printer)'),
            new Case(Id = dtCases[3].Id, Status = 'Returned to Sender', Request_Type__c = 'Ship to Merchant (New Tablet, Printer)'),
            new Case(Id = dtCases[4].Id, Status = 'Dead'),
            new Case(Id = dtCases[5].Id, Status = 'Rejected', Rejection_Reason_2__c = 'Fraud', Rejection_Reason_Details__c = 'Testing')
        };
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();
        Map<Id, Milestone__c> queriedMilestones = new Map<Id, Milestone__c>([SELECT Id, Status__c, Status_Reason__c, Status_Reason_Details__c FROM Milestone__c WHERE Id IN :tabletRequestMilestones]);
        system.assertEquals('In Progress', queriedMilestones.get(tabletRequestMilestones[0].Id).Status__c);
        system.assertEquals('In Progress', queriedMilestones.get(tabletRequestMilestones[1].Id).Status__c);
        system.assertEquals('Complete', queriedMilestones.get(tabletRequestMilestones[2].Id).Status__c);
        system.assertEquals('Blocked', queriedMilestones.get(tabletRequestMilestones[3].Id).Status__c);
        system.assertEquals('Blocked', queriedMilestones.get(tabletRequestMilestones[4].Id).Status__c);
        system.assertEquals('Blocked', queriedMilestones.get(tabletRequestMilestones[5].Id).Status__c);
        system.assertEquals(CDdMxSxConstants.MILESTONE_STATUS_REASON_TABLET_CASE_REJECTED , queriedMilestones.get(tabletRequestMilestones[5].Id).Status_Reason__c);
        system.assertEquals('Testing', queriedMilestones.get(tabletRequestMilestones[5].Id).Status_Reason_Details__c);
    }
    @isTest
    static void testSurveyMenuUpdateCase() {
        Id menuUpdateRTId = CASE_Menu_Update_RECORDTYPEID;
        Account menuUpdateAcct = [Select Id From Account where Name = 'Test Acc1' limit 1];
        Contact menuUpdateContact = [Select Id From Contact where AccountId =: menuUpdateAcct.Id limit 1];
        Case menuUpdateCase  = TDdCaseFactory.createCaseRecords(1, 'Menu Update')[0];
        menuUpdateCase.Status = 'Solved';
        menuUpdateCase.Solved_At__c = System.now();
        menuUpdateCase.AccountId = menuUpdateAcct.id;
        menuUpdateCase.ContactId = menuUpdateContact.Id;
        insert menuUpdateCase;

        Test.startTest();
        menuUpdateCase.Status = 'Closed';
        update menuUpdateCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();
        menuUpdateCase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: menuUpdateCase.Id];
      //  system.assertNotEquals(null, menuUpdateCase.Delighted_Task_Created__c);

    }
    @isTest
    static void testSurveyPhoneCase() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());

        Account phoneAcct = [Select Id From Account where Name = 'Test Acc1' limit 1];

        Contact phoneContact = [Select Id From Contact where AccountId =: phoneAcct.Id limit 1];

        Case phoneCase = TDdCaseFactory.createSolveableSupportCase(1, 'Support', phoneAcct.Id, phoneContact.id)[0];
        phoneCase.Origin = 'Phone';
        phoneCase.Status = 'Open';
        phonecase.Language__c = 'English';

        insert phoneCase;

        Test.startTest();
        phonecase.status = 'Solved';
        update phoneCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();
        phonecase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: phonecase.Id];
        system.assertNotEquals(null, phonecase.Delighted_Task_Created__c);
    }

    @isTest
    static void testSurveyWebWithNoContactEmail() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Account webAcct = [Select Id From Account where Name = 'Test Acc1' limit 1];

        Contact webContact = TDdAccountFactory.createContacts(1, webAcct.Id)[0];
        webContact.email = null;
        insert webContact;
        Case webCase = TDdCaseFactory.createSolveableSupportCase(1, 'Support', webAcct.Id, webContact.id)[0];
        webCase.Origin = 'Web';
        webCase.Status = 'Open';
        webCase.Language__c = 'English';

        insert webCase;

        Test.startTest();
        webCase.Status = 'Solved';
        update webCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();
        webCase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: webCase.Id];
        system.assertNotEquals(null, webCase.Delighted_Task_Created__c);

    }
    @isTest
    static void testSurveyWebCaseDelighted() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Account webAcct = [Select Id From Account where Name = 'Test Acc1' limit 1];
        Contact webContact = [Select Id From Contact where AccountId =: webAcct.Id limit 1];

        Case webCase = TDdCaseFactory.createSolveableSupportCase(1, 'Support', webAcct.Id, webContact.id)[0];
        webCase.Origin = 'Facebook';
        webCase.Status = 'Open';
        webCase.Language__c = 'English';

        insert webCase;

        Test.startTest();
        webCase.Status = 'Solved';
        update webCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();
        webCase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: webCase.Id];
        System.assertNotEquals(null, webCase.Delighted_Task_Created__c);
        List<Delighted_Tasks__c> tasks = [Select id, Survey_Provider__c from Delighted_Tasks__c where case__c =: webCase.id];
        System.assert(tasks.size() > 0);
        if(tasks.size() > 1){
            // if the process builder is enalbed, we sould have 2 tasks because
            // CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_sendSurvey') returns true for test classes
            System.assertEquals(CDdSupportConstants.SURVEY_PROVIDER_DELIGHTED, taskS[1].Survey_Provider__c);
        }

    }

    @isTest
    static void testSurveyWebCaseQualtrics() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Qualtrics_Surveys__c = true;
        upsert featureFlag;
        Account webAcct = [Select Id From Account where Name = 'Test Acc1' limit 1];
        Contact webContact = [Select Id From Contact where AccountId =: webAcct.Id limit 1];

        Case webCase = TDdCaseFactory.createSolveableSupportCase(1, 'Support', webAcct.Id, webContact.id)[0];
        webCase.Origin = 'Facebook';
        webCase.Status = 'Open';
        webCase.Language__c = 'English';
        insert webCase;
        List<Delighted_Tasks__c> tasks = [Select id, Survey_Provider__c from Delighted_Tasks__c where case__c =: webCase.id];
        System.assertEquals(0, tasks.size());
        Test.startTest();
        webCase.Status = 'Solved';
        update webCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();
        webCase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: webCase.Id];
        System.assertNotEquals(null, webCase.Delighted_Task_Created__c);
        tasks = [Select id, Survey_Provider__c from Delighted_Tasks__c where case__c =: webCase.id];
        System.assert(tasks.size() > 0);
        if(tasks.size() > 1){
            // if the process builder is enalbed, we sould have 2 tasks because
            // CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_sendSurvey') returns true for test classes
            System.assertEquals(CDdSupportConstants.SURVEY_PROVIDER_QUALTRICS, taskS[1].Survey_Provider__c);
        }

    }
    @isTest
    static void testSurveyInAppCxChatCase() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Account chatAcct = [Select Id From Account where Name = 'Test Acc1' limit 1];
        Contact chatContact = [Select Id From Contact where AccountId =: chatAcct.Id limit 1];

        Case chatCase = TDdCaseFactory.createSolveableSupportCase(1, 'Support', chatAcct.Id, chatContact.id)[0];
        chatCase.Origin = 'Chat';
        chatCase.Status = 'Open';
        chatCase.Language__c = 'English';
        chatCase.ChatKey__c = '123';
        insert chatCase;
        Account acct = TDdAccountFactory.createAccounts('test', 1, 'Consumer or Dasher')[0];
        insert acct;

        acct = [select Id, PersonContactId from Account where Id =: acct.Id];

        Contact ctc =  new Contact(
            Id = acct.PersonContactId,
            Email = 'test@test.com',
            CustomerNo__c = 123,
            DasherNo__c = 123);
        update ctc;

        LiveChatTranscript transcript = TDdCaseFactory.createTranscripts(1)[0];
        transcript.Status='Completed';
        transcript.Chat_First_Name__c = 'test';
        transcript.Chat_Last_Name__c = 'test';
        transcript.Platform = 'Android';
        transcript.CaseId = chatCase.Id;
        transcript.ChatKey = '123';
        insert transcript;

        Test.startTest();
        chatCase.Status = 'Solved';
        update chatCase;
        Test.stopTest();


        chatCase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: chatCase.Id];
        system.assertEquals(null, chatCase.Delighted_Task_Created__c);
    }
    @isTest
    static void testSurveyInAppMxChatCase() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Account chatAcct = [Select Id From Account where Name = 'Test Acc1' limit 1];
        Contact chatContact = [Select Id From Contact where AccountId =: chatAcct.Id limit 1];

        Case chatCase = TDdCaseFactory.createSolveableSupportCase(1, 'Support', chatAcct.Id, chatContact.id)[0];
        chatCase.Origin = 'Chat';
        chatCase.Status = 'Open';
        chatCase.Language__c = 'English';
        chatCase.Customer_Type__c = 'Dasher';
        chatCase.Resolution__c = 'Account Info Reset';
        chatCase.Resolution_Type__c = 'Account Management - DX';
        chatCase.Issue_Type__c = 'Account Issue - Dx';
        chatCase.Issue__c = 'Account Updates - Dx';

        chatCase.ChatKey__c = '123';
        insert chatCase;
        Account acct = TDdAccountFactory.createAccounts('test', 1, 'Consumer or Dasher')[0];
        insert acct;

        acct = [select Id, PersonContactId from Account where Id =: acct.Id];

        Contact ctc =  new Contact(
            Id = acct.PersonContactId,
            Email = 'test@test.com',
            CustomerNo__c = 123,
            DasherNo__c = 123);
        update ctc;

        LiveChatTranscript transcript = TDdCaseFactory.createTranscripts(1)[0];
        transcript.Status='Completed';
        transcript.Chat_First_Name__c = 'test';
        transcript.Chat_Last_Name__c = 'test';
        transcript.Platform = 'Android';
        transcript.CaseId = chatCase.Id;
        insert transcript;

        Test.startTest();
        chatCase.Status = 'Solved';
        update chatCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();

        chatCase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: chatCase.Id];
        system.assertNotEquals(null, chatCase.Delighted_Task_Created__c);
    }
    @isTest
    static void testPOSIntegrationCaseReopened() {
        System.runAs(getTestRunUser()){
            Account testAccount = [Select Id From Account where Name = 'Test Acc1' limit 1];
            Contact testContact = [Select Id From Contact where AccountId =: testAccount.Id limit 1];

            Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
            testCase.Status = 'Solved';
            testCase.Last_Email_from_Customer__c = DateTime.now().addDays(-5);
            testCase.Solved_At__c = DateTime.now().addDays(-4);
            testCase.AccountId = testAccount.Id;
            testCase.ContactId = testContact.Id;
            insert testCase;

            Test.startTest();
            testCase.Last_Email_from_Customer__c = DateTime.now().addHours(-5);
            update testCase;
            Test.stopTest();

            Case testCaseFromDB = [Select Id, Status from Case where id =: testCase.Id];
            system.assertEquals('Reopened', testCaseFromDB.Status, 'Expecting case to be reopened');
        }
    }
     @isTest
    static void testPOSIntegrationRedirectCase() {
        System.runAs(getTestRunUser()){
            Account testAccount = [Select Id From Account where Name = 'Test Acc1' limit 1];
            Contact testContact = [Select Id From Contact where AccountId =: testAccount.Id limit 1];

            Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
            testCase.Status = 'Closed';
            testCase.Last_Email_from_Customer__c = DateTime.now().addDays(-5);
            testCase.Solved_At__c = DateTime.now().addDays(-4);
            testCase.AccountId = testAccount.Id;
            testCase.ContactId = testContact.Id;
            insert testCase;

            Test.startTest();
            testCase.Last_Email_from_Customer__c = DateTime.now().addHours(-5);
            update testCase;
            Test.stopTest();

            Case testCaseFromDB = [Select Id, Status from Case where id =: testCase.Id];
            system.assertEquals('Closed', testCaseFromDB.Status, 'Expecting case to be Closed');
        }
    }
    @isTest
    static void testPOSIntegrationCaseActivation() {
        System.runAs(getTestRunUser()){
            Id posIntegrationsRT = CASE_POS_Integrations_RECORDTYPEID;
            Account testAccount = [Select Id From Account where Name = 'Test Acc1' limit 1];
            Contact testContact = [Select Id From Contact where AccountId =: testAccount.Id limit 1];

            Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
            testCase.AccountId = testAccount.Id;
            testCase.ContactId = testContact.Id;
            insert testCase;

            Case testCaseFromDB;

            Test.startTest();
            testCaseFromDB = [Select Id, RecordTypeId, Status, Activation_Date__c from Case where id =: testCase.Id];
            System.assertEquals(posIntegrationsRT, testCaseFromDB.RecordTypeId, 'Expecting case to be of record type POS Integrations');
            System.assertEquals('Open', testCaseFromDB.Status, 'Expecting case to be open');
            // Update activation date on the Case record
            testCase.Activation_Date__c = Date.today();
            testCase.POS_Go_Live_Date__c = Date.today();
            testCase.Activation_Notes__c = 'dummy notes';
            testCase.Link_to_POS_Pre_Work__c = 'http://test.pos.pre.work.net';
            update testCase;
            Test.stopTest();

            testCaseFromDB = [Select Id, Status, Activation_Date__c from Case where id =: testCase.Id];
            System.assertEquals('Solved', testCaseFromDB.Status, 'Expecting case to be solved');
            System.assertEquals(true, testCaseFromDB.Activation_Date__c!=null, 'Expecting a valid activation date on the Case');

        }
    }


    @isTest
    static void testWhenMOCaseChangesFromInitialQueueThenItRoutesToCorrectOne() {
        Map<String, Id> queueNameToId = new Map<String, Id>();
        String menuReadyForQAQueueName = 'Onboarding - Menu Ready for QA', menuVendorAllocationQueueName = 'Onboarding - Menu Vendor Allocation',
                newPartnerEscalationsQueueName = 'Onboarding - New Partner Escalations', ssmePendingQueueName = 'Onboarding - SSME Pending';

        Id setupMenuRT = CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeId('Setup Menu');
        Id onboardingCaseRT =CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Marketplace Onboarding');

        for(Group q: [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name IN (:menuReadyForQAQueueName, :menuVendorAllocationQueueName, :newPartnerEscalationsQueueName, :ssmePendingQueueName)]){
            queueNameToId.put(q.Name, q.Id);
        }
        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 4, 'Marketplace');
        insert accs;
        List<Case> onboardingCases = TDdCaseFactory.createCaseRecords(4, 'Marketplace Onboarding');
        for(Integer k=0; k<accs.size(); k++){
            onboardingCases[k].AccountId = accs[k].Id;
            onboardingCases[k].Status = 'Opened';
            onboardingCases[k].OwnerId = Userinfo.getUserId();
        }
        insert onboardingCases;
        Milestone_Template__c templ = new Milestone_Template__c(
                Milestone_Type__c = 'Setup Menu',
                Milestone_Record_Type_ID_18__c = [select Id from RecordType where DeveloperName = 'Setup_Menu'].Id,
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = onboardingCaseRT,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = Userinfo.getUserId(),
                Default_Sort_Order__c = 1,
                Active__c = true,
                Completed_by_Stage__c = 'Menu Configuration',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 3,
                Stage_Reviewed_Sort_Order__c = null);
        insert templ;
        List<Milestone__c> setupMenuMilestones = new List<Milestone__c>{
            new Milestone__c(Case__c = onboardingCases[0].Id,RecordTypeId = setupMenuRT, Milestone_Template__c = templ.Id, Status__c = 'Ready for QA'),
            new Milestone__c(Case__c = onboardingCases[1].Id,RecordTypeId = setupMenuRT, Milestone_Template__c = templ.Id, Status__c = 'Escalated', Status_Reason__c = 'SSME to Doordash'),
            new Milestone__c(Case__c = onboardingCases[2].Id,RecordTypeId = setupMenuRT, Milestone_Template__c = templ.Id, Status__c = 'Ready for QA'),
            new Milestone__c(Case__c = onboardingCases[3].Id,RecordTypeId = setupMenuRT, Milestone_Template__c = templ.Id, Status__c = 'Escalated', Status_Reason__c = 'SSME to Doordash')
        };
        insert setupMenuMilestones;
        Test.startTest();
        update new List<Case>{
            new Case(Id = onboardingCases[0].Id, OwnerId = queueNameToId.get(menuVendorAllocationQueueName)),
            new Case(Id = onboardingCases[1].Id, OwnerId = queueNameToId.get(menuVendorAllocationQueueName)),
            new Case(Id = onboardingCases[2].Id, OwnerId = queueNameToId.get(ssmePendingQueueName)),
            new Case(Id = onboardingCases[3].Id, OwnerId = queueNameToId.get(ssmePendingQueueName))
        };
        Test.stopTest();
        Map<Id, Milestone__c> queriedMilestones = new Map<Id, Milestone__c>([SELECT Id, Case__r.OwnerId FROM Milestone__c WHERE Id IN :setupMenuMilestones]);
        system.assertEquals(queueNameToId.get(menuReadyForQAQueueName), queriedMilestones.get(setupMenuMilestones[0].Id).Case__r.OwnerId);
        system.assertEquals(queueNameToId.get(newPartnerEscalationsQueueName), queriedMilestones.get(setupMenuMilestones[1].Id).Case__r.OwnerId);
        system.assertEquals(queueNameToId.get(menuReadyForQAQueueName), queriedMilestones.get(setupMenuMilestones[2].Id).Case__r.OwnerId);
        system.assertEquals(queueNameToId.get(newPartnerEscalationsQueueName), queriedMilestones.get(setupMenuMilestones[3].Id).Case__r.OwnerId);
    }

   /**
     * @author      Sahil
     * @date        March 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
     * @description tests invalid escalation queue selection by logged in user
     */
    @isTest
    static void testInvalidEscalation() {
        //Creating Group
        Group testGroup = new Group(Name='Test Queue', Type = CDdSupportConstants.GROUP_QUEUE);
        insert testGroup;
        QueuesObject testQueue;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            //Associating queue with group AND to the Case object
            testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert testQueue;

            //create configs
            Site_Escalation_Config__c escConfigObj = new Site_Escalation_Config__c( Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                        Queue_Id__c = testQueue.Id,
                        Queue_Label__c = CDdSupportConstants.ROLE_CEBU_ESC_DEV_NAME,
                        Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                        IsEscalation__c = true,
                        IsTransfer__c = false
                        );
            insert escConfigObj;
            Site_Escalation_Config__c  defautlEscConfigObj = new Site_Escalation_Config__c( Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                Queue_Id__c = testGroup.Id,
                                Queue_Label__c = CDdSupportConstants.TEST_QUEUE_LABEL,
                                Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                IsEscalation__c = false,
                                IsTransfer__c = false,
                                Is_Default_Escalation__c = true
                                );
            insert defautlEscConfigObj;
        }

        Id newOwnerId = [SELECT Id FROM Group WHERE Type =: CDdSupportConstants.GROUP_QUEUE
                            AND DeveloperName =: CDdSupportConstants.ROLE_CEBU_ESC_DEV_NAME LIMIT 1].Id;

        User runningUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
        Boolean isError = false;

        System.runAs(runningUser) {
             List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
             Case testCase = testCaseList[0];
             try{
                 insert testCase;
                 //assert the test case was created
                 List<Case> testCaseFromDBList = [SELECT Id FROM Case WHERE Id =:testCase.Id];
                 System.assertEquals(1,testCaseFromDBList.size(),'1 test case should be returned from Database');
                 testCase.isEscalated = true;
                 testCase.OwnerId = testQueue.Id;
                 testCase.Issue__c = CDdSupportConstants.CASE_ISSUE_ACCT_SETTINGS;
                 testCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
                 testCase.Escalation_Reason__c = CDdSupportConstants.CASE_ESC_REASON_SUP_OPS;
                 Test.startTest();
                 update testCase;
             } catch (Exception e) {
                 isError = true;
             }
             Test.stopTest();
             System.assertEquals(true,isError,'An exception should be thrown');
        }
    }

    /**
     * @author      Sahil
     * @date        March 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
     * @description tests invalid transfer queue selection by logged in user
     */
    @isTest
    static void testInvalidTransfer() {
         //Creating Group
         Group testGroup = new Group(Name='Test Queue', Type = CDdSupportConstants.GROUP_QUEUE);
         insert testGroup;
         QueuesObject testQueue;
         System.runAs(new User(Id=UserInfo.getUserId())) {
            //Associating queue with group AND to the Case object
            testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert testQueue;

            //create configs
            Site_Escalation_Config__c escConfigObj = new Site_Escalation_Config__c( Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                        Queue_Id__c = testQueue.Id,
                        Queue_Label__c = CDdSupportConstants.ROLE_CEBU_ESC_DEV_NAME,
                        Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR_DEV_NAME,
                        IsEscalation__c = true,
                        IsTransfer__c = true
                        );
            insert escConfigObj;
         }

          Id newOwnerId = [SELECT Id FROM Group WHERE Type =: CDdSupportConstants.GROUP_QUEUE
                            AND DeveloperName =: CDdSupportConstants.ROLE_CEBU_ESC_DEV_NAME LIMIT 1].Id;

          User runningUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
          Boolean isError = false;

          System.runAs(runningUser) {
              List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
              Case testCase = testCaseList[0];
              try{
                insert testCase;
                //assert the test case was created
                List<Case> testCaseFromDBList = [SELECT Id FROM Case WHERE Id =:testCase.Id];
                System.assertEquals(1,testCaseFromDBList.size(),'1 test case should be returned from Database');
                testCase.OwnerId = testQueue.Id;
                testCase.Issue__c = CDdSupportConstants.CASE_ISSUE_ACCT_SETTINGS;
                testCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
                testCase.Escalation_Reason__c = CDdSupportConstants.CASE_ESC_REASON_SUP_OPS;
                Test.startTest();
                update testCase;
              } catch (Exception e) {

                isError = true;
              }
              Test.stopTest();
              System.assertEquals(true,isError,'An exception should be thrown');
          }
    }


    /**
     * @author      Sahil
     * @date        March 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
     * @description tests default escalation queue if case is escalated without choosing a queue
     */
    @isTest
    static void testDefaultEscalationPositive() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
       //Creating Group
       Group testGroup = new Group(Name='Test Queue', Type = CDdSupportConstants.GROUP_QUEUE);
       insert testGroup;
       QueuesObject testQueue;
       System.runAs(new User(Id=UserInfo.getUserId())) {
            //Associating queue with group AND to the Case object
            testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert testQueue;

            //create configs
            Site_Escalation_Config__c escConfigObj = new Site_Escalation_Config__c( Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
            Queue_Id__c = testGroup.Id,
            Queue_Label__c = CDdSupportConstants.TEST_QUEUE_LABEL,
            Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
            IsEscalation__c = true,
            IsTransfer__c = false,
            Is_Default_Escalation__c = true
            );
            insert escConfigObj;
       }

        User runningUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
        Id userRoleId = [SELECT Id, DeveloperName, Name
                           FROM UserRole
                           WHERE DeveloperName =: CDdSupportConstants.ROLE_HQ_SUPERVISOR_DEV_NAME
                           LIMIT 1].Id;

        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case testCase = testCaseList[0];
        runningUser.UserRoleId = userRoleId;

        System.runAs(runningUser) {
            insert testCase;
            //assert the test case was created
            List<Case> testCaseFromDBList = [SELECT Id FROM Case WHERE Id =:testCase.Id];
            System.assertEquals(1,testCaseFromDBList.size(),'1 test case should be returned from Database');
            testCase.isEscalated = true;//User escalates the case without selecting a new owner
            testCase.Issue__c = CDdSupportConstants.CASE_ISSUE_ACCT_SETTINGS;
            testCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
            testCase.OwnerId = testGroup.Id;
            testCase.Escalation_Reason__c = CDdSupportConstants.CASE_ESC_REASON_SUP_OPS;
            Test.startTest();
            update testCase;
            Test.stopTest();
        }
        //query for the case with new owner
        List<Case> updatedCaseList = [SELECT OwnerId FROM Case WHERE Id =:testCase.Id];
        System.debug('updatedCaseList-> '+updatedCaseList);
        Id testGroupId = [SELECT Id FROM Group WHERE Name = 'Test Queue' AND Type = 'Queue' LIMIT 1].Id;
        System.assertEquals(testGroupId,updatedCaseList[0].OwnerId,'Case Owner Id should be updated');
    }

    /**
     * @author      Sahil
     * @date        June 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1866
     * @description tests processing of MxP cases
     */
    @isTest
    static void testMxPcases() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        //to avoid mixed dml error, insert a user with System.runAs running user
        User runningUser = [SELECT Id FROM User where Id = :UserInfo.getUserId()];
        String PARTNER_INTEGRATION_KWIKTRIP = 'kwiktrip';
        System.runAs(runningUser) {
            //create test user who is the mxp agent
            User mxpAgentUser = TDdUserFactory.createUsers(1)[0];
            mxpAgentUser.isActive = true;
            mxpAgentUser.Is_Out_Of_Office__c = false;
            mxpAgentUser.FirstName = CDdSupportConstants.NAME_MXP_AGENT;
            mxpAgentUser.LastName = CDdSupportConstants.NAME_TEST_USER;
            insert mxpAgentUser;
        }
        //get mxp agent user id from database
        Id mxpAgentUserId = [SELECT Id FROM User
                                WHERE FirstName =: CDdSupportConstants.NAME_MXP_AGENT
                                AND LastName =: CDdSupportConstants.NAME_TEST_USER
                                LIMIT 1].Id;
        //create test account
        Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        //test account override true
        testAcct.Case_Routing_Override__c = CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE;
        insert testAcct;

        //create account team member
        AccountTeamMember testAccTeamMember = new AccountTeamMember();
        testAccTeamMember.AccountId = testAcct.Id;
        testAccTeamMember.UserId = mxpAgentUserId;
        testAccTeamMember.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
        insert testAccTeamMember;

        Test.startTest();
        //create valid case
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case testCase = testCaseList[0];
        testCase.Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        testCase.Issue_Type__c = CDdSupportConstants.ISSUE_POS;
        testCase.POS_Integration_Type__c = PARTNER_INTEGRATION_KWIKTRIP;
        testCase.AccountId = testAcct.Id;
        insert testCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();

        //assert that the case owner is mxp agent
        Case caseFromDB = [SELECT OwnerId FROM Case WHERE Id =:testCase.Id LIMIT 1];
        System.assertEquals(mxpAgentUserId, caseFromDB.OwnerId, 'Case Owner should be Mxp Agent Test User');
    }

    /**
     * @author      Sahil
     * @date        June 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1923
     * @description tests processing of case touch count
     */
    @isTest
    static void testProcessCaseTouchCount() {

        //get a case from database
        Case caseToUpdate = [SELECT Id, OwnerId, Status, recordtypeid, case_record_type__c,Overall_Touch_Count__c
                                FROM Case where case_record_type__c = 'Support' LIMIT 1];

        //first assert overall touch count value - it should be 1 because status changes from new to open

        Integer touchCountInitialValue = (Integer) caseToUpdate.Overall_Touch_Count__c;
        System.assertEquals(1, touchCountInitialValue, 'initial touch count should be 1');
        //update the case with change in owner
        //to avoid mixed dml error, insert a user with System.runAs running user
        User runningUser = [SELECT Id FROM User where Id = :UserInfo.getUserId()];
        System.runAs(runningUser) {
            //create test user who is the mxp agent
            User mxpAgentUser = TDdUserFactory.createUsers(1)[0];
            mxpAgentUser.isActive = true;
            mxpAgentUser.Is_Out_Of_Office__c = false;
            mxpAgentUser.FirstName = CDdSupportConstants.NAME_MXP_AGENT;
            mxpAgentUser.LastName = CDdSupportConstants.NAME_TEST_USER;
            insert mxpAgentUser;
        }
        //get mxp agent user id from database
        Id mxpAgentUserId = [SELECT Id FROM User
                                WHERE FirstName =: CDdSupportConstants.NAME_MXP_AGENT
                                AND LastName =: CDdSupportConstants.NAME_TEST_USER
                                LIMIT 1].Id;
        caseToUpdate.OwnerId = mxpAgentUserId;//Owner changed, touch count should increment
        Test.startTest();
        update caseToUpdate;
        Test.stopTest();
        //the above update should increment counter by 1, assert it
        Integer updatedTCountValue = (Integer) [SELECT Overall_Touch_Count__c FROM Case WHERE Id =:caseToUpdate.Id LIMIT 1].Overall_Touch_Count__c;
        System.assertEquals(2, updatedTCountValue, 'updated touch count should be 2');
    }

    @isTest
    static void testPhotoshootCaseFromOnboarding() {

        List<Account> accountsToInsert = new List<Account>();
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;

        List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1, false);
        for (Integer i = 0; i < acclist.size(); i++) {
            acclist[i].Name = 'Test Acc';
            acclist[i].BillingStreet = 'Rotebühlstraße 121';
            acclist[i].BillingCity = 'Stuttgart';
            acclist[i].BillingPostalCode = '70178';
            acclist[i].BillingCountryCode = 'DE';
            acclist[i].BillingCountry = 'Germany';
            acclist[i].Legal_Business_Name__c = 'German';
            acclist[i].Market_Area__c = 'Northern California - East Bay';
            acclist[i].Business_ID__c = 123456;
            acclist[i].Language__c = 'German';
            acclist[i].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
            accountsToInsert.add(acclist[i]);
        }
        insert accountsToInsert;

        Contact con1 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
            'AccountId' => accountsToInsert[0].Id
                }, false);
        insert con1;

        Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con1.AccountId, con1.id, 'Closed Won');
        opp2.Tablet_Received_Date__c = null;
        opp2.Mx_Requesting_Photoshoot__c = CDdCoreConstants.STRING_YES;
        insert opp2;

        List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 1, false);
        for(Integer i = 0; i < 1; i++){
            cslist1[i].Store_ID__c = '' +i;
            cslist1[i].BusinessHours =null;
            cslist1[i].Subject = 'setAccountIdUpdateTest'+i;
            cslist1[i].RecordTypeId = onboardingCaseRT;
            cslist1[i].Photo_Review_Notes__c = 'OCUS';
            cslist1[i].Language__c = 'German';
            cslist1[i].AccountId = accountsToInsert[0].Id;
            cslist1[i].Opportunity_Name__c = opp2.Id;
        }
        Test.startTest();
        insert cslist1[0];

        cslist1[0].Menu_Preview_Links__c = 'Menu preview links';
        update cslist1;
        Test.stopTest();
        List<Case> newCase = [SELECT Id FROM Case WHERE Opportunity_Name__c= :opp2.Id AND RecordTypeId=:CASE_PHOTOSHOOT_RECORDTYPEID];
        System.assertEquals(1, newCase.size());

    }

    /**
     * @author      Veera
     * @date        06-2022
     * @decription  test Snapper photoshoot creation on marketplace onboaring case update
     * @param       None
     * @return      None
    */
    @isTest
    static void testSnapperPhotoshootCaseFromOnboardingCase() {
        System.runAs(getTestRunUser()){
            List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();
            Id businessVerticalId;
            for(Business_Vertical__c bv : bvList){
                if(bv.Menu_UI_Type__c == CDdSupportConstants.BUSINESS_VERTICAL_RESTAURANT){
                    businessVerticalId = bv.Id;
                    break;
                }
            }

            Case marketplaceOnBoardingCase = createPhotoshootData(businessVerticalId);
            insert marketplaceOnBoardingCase;

            List<Case> newCase = [SELECT Id,Photo_Provider__c FROM Case WHERE Opportunity_Name__c= :marketplaceOnBoardingCase.Opportunity_Name__c AND RecordTypeId=:CASE_PHOTOSHOOT_RECORDTYPEID];
            System.assertEquals(0, newCase.size());

            Test.startTest();
            marketplaceOnBoardingCase.Menu_Preview_Links__c = 'Menu preview links';
            update marketplaceOnBoardingCase;
            Test.stopTest();

            newCase = [SELECT Id,Photo_Provider__c FROM Case WHERE Opportunity_Name__c= :marketplaceOnBoardingCase.Opportunity_Name__c AND RecordTypeId=:CASE_PHOTOSHOOT_RECORDTYPEID];
            System.assertEquals(1, newCase.size());
            System.assertEquals(CDdSupportConstants.CASE_PHOTOSHOOT_VENDOR_SNAPPR, newCase[0].Photo_Provider__c);
        }
    }

    /**
     * @author      Veera
     * @date        06-2022
     * @decription  Test for BASD-26831 : Removal of Accounts with Business Vertical ID populated from Automation for Photoshoot Creation
     * @param       None
     * @return      None
    */
    @isTest
    public static void testCreatePhotoshootCaseForRetail() {
        System.runAs(getTestRunUser()){
            List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();
            Id businessVerticalId;
            for(Business_Vertical__c bv : bvList){
                if(bv.Menu_UI_Type__c != CDdSupportConstants.BUSINESS_VERTICAL_RESTAURANT){
                    businessVerticalId = bv.Id;
                    break;
                }
            }

            Case marketplaceOnBoardingCase = createPhotoshootData(businessVerticalId);
            insert marketplaceOnBoardingCase;


            List<Case> newCase = [SELECT Id,Photo_Provider__c FROM Case WHERE Opportunity_Name__c= :marketplaceOnBoardingCase.Opportunity_Name__c AND RecordTypeId=:CASE_PHOTOSHOOT_RECORDTYPEID];
            System.assertEquals(0, newCase.size());

            Test.startTest();
            marketplaceOnBoardingCase.Menu_Preview_Links__c = 'Menu preview links';
            update marketplaceOnBoardingCase;
            Test.stopTest();

            newCase = [SELECT Id,Photo_Provider__c FROM Case WHERE Opportunity_Name__c= :marketplaceOnBoardingCase.Opportunity_Name__c AND RecordTypeId=:CASE_PHOTOSHOOT_RECORDTYPEID];
            System.assertEquals(0, newCase.size(), 'Photoshoot case should not be created for Non-restuarant Business vertical');
        }
    }

    private static Case createPhotoshootData(Id businessVerticalId){
       Id realZipId = TDdAccountFactory.setupRealZIPData();

       Account acct = TDdAccountFactory.createAccountsWithDynamicAddress('Test Account',1,'Marketplace','Australia','AU','Victoria', '+61 999 999 999','3005')[0];
       acct.RealZip__RealZip__c = realZipId;
       if(businessVerticalId != null){
           acct.Business_Vertical__c = businessVerticalId;
       }
       insert acct;

       Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];
       insert contact;

       Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acct.Id, contact.Id, 'New', CDdOpportunityConstants.RECORD_TYPE_OPPORTUNITY_DEV_NAME_MARKETPLACE);
       opp.StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;
       opp.Decision_Maker__c = contact.Id;
       opp.OwnerId = UserInfo.getUserId();
       opp.Mx_Requesting_Photoshoot__c = CDdCoreConstants.STRING_YES;
       insert opp;

       List<Case> marketplaceOnBoardingCase = CDdTestDataFactory.createSObjectList('Case', 1, false);
       for(Integer i = 0; i < 1; i++){
           marketplaceOnBoardingCase[i].Store_ID__c = '' +i;
           marketplaceOnBoardingCase[i].BusinessHours =null;
           marketplaceOnBoardingCase[i].Subject = 'setAccountIdUpdateTest'+i;
           marketplaceOnBoardingCase[i].RecordTypeId = onboardingCaseRT;
           marketplaceOnBoardingCase[i].Photo_Review_Notes__c = 'Snappr';
           marketplaceOnBoardingCase[i].Language__c = 'German';
           marketplaceOnBoardingCase[i].AccountId = opp.AccountId;
           marketplaceOnBoardingCase[i].Opportunity_Name__c = opp.Id;
       }
       return marketplaceOnBoardingCase[0];
    }

       /**
     * @author      Sahil
     * @date        December 2021
     * @decription  test linking account and contact on mxpsupport@ incoming emails
     * @param       None
     * @return      None
     */
    @isTest
    static void testMXPE2CAccountLinking() {
        Test.startTest();
        //feature enabled in test setup. Insert a case which would meet entry criteria
        //Create an account with multiple contacts with same email

        //allow duplicate records to insert
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;

        //insert account
        List<Account> accountsToInsert = new List<Account>();
        List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1, false);
        for (Integer i = 0; i < acclist.size(); i++) {
            acclist[i].Name = 'Test Acc';
            acclist[i].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE).getRecordTypeId();
            accountsToInsert.add(acclist[i]);
        }
        insert accountsToInsert;
        //insert a contact
        Contact con1 = (Contact)CDdTestDataFactory.createSObject('Contact',
                                                                    new Map<String,Object>{
                                                                        'AccountId' => accountsToInsert[0].Id,
                                                                        'Email' => CDdSupportConstants.TEST_EMAIL
                                                                        }, false);
        insert con1;
        //insert another contact with same email
        Contact con2 = (Contact)CDdTestDataFactory.createSObject('Contact',
                                                                    new Map<String,Object>{
                                                                        'AccountId' => accountsToInsert[0].Id,
                                                                        'Email' => CDdSupportConstants.TEST_EMAIL
                                                                        }, false);
        Database.SaveResult sr = Database.insert(con2, dml);

        //insert case
        List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 1, false);
        for(Integer i = 0; i < 1; i++){
            cslist1[i].BusinessHours =null;
            cslist1[i].RecordTypeId = CDdSchemaUtils.CASE_RT.customerId();
            cslist1[i].Priority = CDdSupportConstants.MEDIUM_PRIORITY;
            cslist1[i].Origin = CDdSupportConstants.ORIGIN_EMAIL_MXP;
            cslist1[i].SuppliedEmail = CDdSupportConstants.TEST_EMAIL;
        }
        insert cslist1[0];
        Test.stopTest();
        //assert that the account and contact got populated
        Case caseFromDB = [SELECT AccountId, ContactId FROM Case WHERE Id =:cslist1[0].Id LIMIT 1];
        System.assertEquals(accountsToInsert[0].Id, caseFromDB.AccountId, 'Account should be populated');
        System.assertEquals(con2.Id, caseFromDB.ContactId, 'Contact should be populated');
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Dec 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-835
     * @description testing validation error for updating case status
     */
    @isTest
    static void testPreventCaseClosingWithoutReopenReasonForMxp() {
        //to avoid mixed dml error, insert a user with System.runAs running user
        User runningUser = [SELECT Id FROM User where Id = :UserInfo.getUserId()];
        User mxpAgentUser;
        String PARTNER_INTEGRATION_SQUARE = 'square';
        System.runAs(runningUser) {
            //create test user who is the mxp agent
            mxpAgentUser = TDdUserFactory.createUsers(1)[0];
            mxpAgentUser.isActive = true;
            mxpAgentUser.Is_Out_Of_Office__c = false;
            mxpAgentUser.FirstName = CDdSupportConstants.NAME_MXP_AGENT;
            mxpAgentUser.LastName = CDdSupportConstants.NAME_TEST_USER;
            insert mxpAgentUser;
        }
        //get mxp agent user id from database
        Id mxpAgentUserId = [SELECT Id FROM User
                                WHERE FirstName =: CDdSupportConstants.NAME_MXP_AGENT
                                AND LastName =: CDdSupportConstants.NAME_TEST_USER
                                LIMIT 1].Id;
        //create test account
        Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        insert testAcct;

        //create account team member
        AccountTeamMember testAccTeamMember = new AccountTeamMember();
        testAccTeamMember.AccountId = testAcct.Id;
        testAccTeamMember.UserId = mxpAgentUserId;
        testAccTeamMember.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
        insert testAccTeamMember;

        //create valid case
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case testCase = testCaseList[0];
        testCase.Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        testCase.Issue_Type__c = CDdSupportConstants.ISSUE_POS;
        testCase.Issue__c = 'Other';
        testCase.POS_Integration_Type__c = PARTNER_INTEGRATION_SQUARE;
        testCase.AccountId = testAcct.Id;
        testCase.Subject = 'MXP Test Case';
        testCase.Status = CDdSupportConstants.REOPEN_STATUS;
        insert testCase;

        System.runAs(mxpAgentUser) {
            try {
                Test.startTest();
                testCase.Resolution_Type__c = CDdSupportConstants.ISSUE_POS;
                testCase.Resolution__c = 'Submitted Jira';
                testCase.Status = CDdSupportConstants.CLOSED_STATUS;
                update testCase;
                Test.stopTest();
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains(CDdCaseTriggerHelperV2.CASE_STATUS_UPDATE_NOT_ALLOWED_ERROR_MESG), 'Validation error message is not same as expected.');
            }
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Feb 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-21568
     * @description testing validation error for Reopened MXP Cases
     */
    @isTest
    static void testPreventCaseClosingWithoutReopenReasonForMxp2() {
        //to avoid mixed dml error, insert a user with System.runAs running user
        User runningUser = [SELECT Id FROM User where Id = :UserInfo.getUserId()];
        Group mxSxSuccessAssociateQueue = [SELECT ID FROM Group WHERE DeveloperName = :CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK];
        User mxpAgentUser;
        String PARTNER_INTEGRATION_SQUARE = 'square';
        System.runAs(runningUser) {
            //create test user who is the mxp agent
            mxpAgentUser = TDdUserFactory.createUsers(1)[0];
            mxpAgentUser.isActive = true;
            mxpAgentUser.Is_Out_Of_Office__c = false;
            mxpAgentUser.FirstName = CDdSupportConstants.NAME_MXP_AGENT;
            mxpAgentUser.LastName = CDdSupportConstants.NAME_TEST_USER;
            insert mxpAgentUser;
        }
        //get mxp agent user id from database
        Id mxpAgentUserId = [SELECT Id FROM User
                                WHERE FirstName =: CDdSupportConstants.NAME_MXP_AGENT
                                AND LastName =: CDdSupportConstants.NAME_TEST_USER
                                LIMIT 1].Id;
        //create test account
        Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        insert testAcct;

        //create account team member
        AccountTeamMember testAccTeamMember = new AccountTeamMember();
        testAccTeamMember.AccountId = testAcct.Id;
        testAccTeamMember.UserId = mxpAgentUserId;
        testAccTeamMember.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
        insert testAccTeamMember;

        //create valid case
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case testCase = testCaseList[0];
        testCase.Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        testCase.Issue_Type__c = CDdSupportConstants.ISSUE_POS;
        testCase.Issue__c = 'Other';
        testCase.POS_Integration_Type__c = PARTNER_INTEGRATION_SQUARE;
        testCase.AccountId = testAcct.Id;
        testCase.Subject = 'MXP Test Case';
        testCase.Resolution_Type__c = CDdSupportConstants.ISSUE_POS;
        testCase.Resolution__c = 'Submitted Jira';
        testCase.Status = CDdSupportConstants.REOPEN_STATUS;
        insert testCase;

        System.runAs(mxpAgentUser) {
            try {
                Test.startTest();
                testCase.OwnerId = mxpAgentUser.Id;
                update testCase;
                testCase.Status = CDdSupportConstants.SOLVED_STATUS;
                update testCase;
                Test.stopTest();
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains(CDdCaseTriggerHelperV2.REOPEN_REASON_ERROR_MESG), 'Validation error message is not same as expected.');
            }
        }
    }

    /**
     * @description - BIZS-821: Menu Update cases Created with Menu Update Record Type instead of Support Record Type
     */
    @isTest
    static void updateCasesFromSupportFormMxPortalForSupportTest(){
        Account acc = [SELECT Id,
                       Support_Priority_Rank__c,
                       Restaurant_ID__c,
                       Deck_Rank__c,
                       Case_Routing_Override__c
                       FROM Account
                       WHERE Name = 'Test Acc2'];
        acc.Support_Priority_Rank__c = 2;
        acc.Restaurant_ID__c = '121212';
        acc.Deck_Rank__c = 'Ace';
        acc.Case_Routing_Override__c = 'Mx Success Associate Queue';
        update acc;

        Test.startTest();
        List<Case> cslist = new List<Case>();

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Account Management')[0];
        cse.Formstack_Source__c = 'Support Request - Mx Portal';
        cse.Formstack_Category__c = 'Menu';
        cse.Formstack_Subcategory__c = 'Menu Update';
        cse.Store_ID__c = '121212';
        cse.AccountId = acc.Id;
        cslist.add(cse);

        Case cse1 = TDdCaseFactory.createCaseRecords(1, 'Account Management')[0];
        cse1.Formstack_Source__c = 'Support Request - Mx Portal';
        cse1.Formstack_Category__c = 'Payments';
        cse1.Formstack_Subcategory__c = 'Payment Reporting';
        cse1.Store_ID__c = '121212';
        cse1.AccountId = acc.Id;
        cslist.add(cse1);

        insert cslist;

        Case caseResult = [SELECT Id, RecordType.Name
                           FROM Case
                           WHERE Id =: cse.Id
                           AND AccountId=: acc.Id];
        System.assertEquals(caseResult.RecordType.Name, 'Support');

        Case caseResult1 = [SELECT Id, RecordType.Name
                           FROM Case
                           WHERE Id =: cse1.Id
                           AND AccountId=: acc.Id];
        System.assertEquals(caseResult1.RecordType.Name, 'Support');
        Test.stopTest();
    }
    /**
     * @author      Sriram
     * @date        Dec 2021
     * @jira        https://doordash.atlassian.net/browse/BZAP-12797
     * @description On a POS Integration Case, associate Partner Integration record that corresponds to POS Integration Type Value
     */
    @isTest
    static void testInsertPOSIntegrationCaseAssociatePartnerIntegration(){
        System.runAs(getTestRunUser()){
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Acc'];
            String PARTNER_INTEGRATION_SQUARE = 'square';
            String PARTNER_INTEGRATION_TOAST = 'toast';
            Partner_Integration__c partnerIntegration1 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_SQUARE, Provider_Name__c = PARTNER_INTEGRATION_SQUARE, Integration_Function__c = 'New Verticals', Launch_Day__c = 'PDOA', Menu_Type__c = 'OPEN_API', Menu_Pull__c = 'False', Menu_Push__c = 'True', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
            Partner_Integration__c partnerIntegration2 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_TOAST, Provider_Name__c = PARTNER_INTEGRATION_TOAST, Integration_Function__c = 'New Verticals', Launch_Day__c = 'Thursday', Menu_Type__c = 'INVENTORY_FEED', Menu_Pull__c = 'True', Menu_Push__c = 'False', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
            insert new List<Partner_Integration__c>{partnerIntegration1, partnerIntegration2};
            Test.startTest();
            Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
            testCase.AccountId = testAccount.Id;
            testCase.POS_Integration_Type__c = PARTNER_INTEGRATION_SQUARE;
            insert testCase;
            Test.stopTest();
            Case testCaseFromDB = [SELECT Id, POS_Integration_Type__c, Partner_Integration__c FROM Case WHERE Id = :testCase.Id];
            Partner_Integration__c partnerIntegrationRec = [SELECT Id FROM Partner_Integration__c WHERE Provider_Type__c = :PARTNER_INTEGRATION_SQUARE AND RecordTypeId = :PARTNER_INTEGRATION_POS_RECORDTYPEID];
            System.assertEquals(PARTNER_INTEGRATION_SQUARE, testCaseFromDB.POS_Integration_Type__c);
            System.assertEquals(true, testCaseFromDB.Partner_Integration__c != null);
            System.assertEquals(true, testCaseFromDB.Partner_Integration__c.equals(partnerIntegrationRec.Id));
        }
    }
    /**
     * @author      Sriram
     * @date        Dec 2021
     * @jira        https://doordash.atlassian.net/browse/BZAP-12797
     * @description On a POS Integration Case, associate Partner Integration record that corresponds to POS Integration Type Value
     */
    @isTest
    static void testUpdatePOSIntegrationCaseAssociatePartnerIntegration(){
        System.runAs(getTestRunUser()){
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Acc'];
            String PARTNER_INTEGRATION_SQUARE = 'square';
            String PARTNER_INTEGRATION_TOAST = 'toast';
            Partner_Integration__c partnerIntegration1 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_SQUARE, Provider_Name__c = PARTNER_INTEGRATION_SQUARE, Integration_Function__c = 'New Verticals', Launch_Day__c = 'PDOA', Menu_Type__c = 'OPEN_API', Menu_Pull__c = 'False', Menu_Push__c = 'True', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
            Partner_Integration__c partnerIntegration2 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_TOAST, Provider_Name__c = PARTNER_INTEGRATION_TOAST, Integration_Function__c = 'New Verticals', Launch_Day__c = 'Thursday', Menu_Type__c = 'INVENTORY_FEED', Menu_Pull__c = 'True', Menu_Push__c = 'False', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
            insert new List<Partner_Integration__c>{partnerIntegration1, partnerIntegration2};
            Test.startTest();
            Case testCase  = [SELECT Id FROM Case LIMIT 1];
            testCase.RecordTypeId = CDdSchemaUtils.CASE_RT.posIntegrationsId();
            testCase.AccountId = testAccount.Id;
            testCase.POS_Integration_Type__c = PARTNER_INTEGRATION_TOAST;
            update testCase;
            Test.stopTest();
            Case testCaseFromDB = [SELECT Id, POS_Integration_Type__c, Partner_Integration__c FROM Case WHERE Id = :testCase.Id];
            Partner_Integration__c partnerIntegrationRec = [SELECT Id FROM Partner_Integration__c WHERE Provider_Type__c = :PARTNER_INTEGRATION_TOAST AND RecordTypeId = :PARTNER_INTEGRATION_POS_RECORDTYPEID];
            System.assertEquals(PARTNER_INTEGRATION_TOAST, testCaseFromDB.POS_Integration_Type__c);
            System.assertEquals(true, testCaseFromDB.Partner_Integration__c != null);
            System.assertEquals(true, testCaseFromDB.Partner_Integration__c.equals(partnerIntegrationRec.Id));
        }
    }

    /**
     * @author      Nayana Kapse
     * @date        Dec 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-833
     */
    @isTest
    static void testOnboardingMgrCaseUpdate(){
        Contact photoshootContact1 = [Select id, AccountId from contact where contact.firstName=:'PhotoshootContact1'Limit 1];
        Id accId = photoshootContact1.AccountId;
        Opportunity opp = TDdOpportunityFactory.createOpportunity('photoShootOpp1', accId, photoshootContact1.id, 'New');
        insert opp;
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_ONBOARDING_MGR_HANDOFF);
        testCaseList[0].AccountId = accId;
        testCaseList[0].Opportunity_Name__c = opp.Id;
        insert testCaseList;
        Test.startTest();
        testCaseList[0].Status = CDdSupportConstants.STATUS_REQUEST_DENIED;
        testCaseList[0].Decision_Approved_Denied__c ='Test';
        update testCaseList[0];
        Test.stopTest();
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-18394
     */
    @isTest
    static void testReopenJapanCasesToTokyoEscalations(){
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        //create test account
        // Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        List<Account> testAccts = [Select id, name from Account where recordtype.name = 'Marketplace'];
        Account testAcct;
        if(testAccts.size() > 0 ) {
            testAcct = testAccts[0];
        }
        // insert testAcct;

        //create test case
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case testCase = testCaseList[0];
        testCase.Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        testCase.Country__c = CDdSupportConstants.COUNTRY_NAME_JAPAN;
        testCase.Origin = 'Phone';
        if(testAcct != null) {
            testCase.AccountId = testAcct.Id;
        }
        testCase.Subject = 'Japan Case';
        testCase.Resolution__c = 'Changed Order Protocol';
        testCase.Resolution_Type__c = 'Account Management - MX';
        testCase.Issue_Type__c = 'Account Management - MX';
        testCase.Issue__c = 'Switch Order Protocol';
        testCase.Status = CDdSupportConstants.SOLVED_STATUS;
        insert testCase;

        Test.startTest();
        testCase.Status = CDdSupportConstants.REOPEN_STATUS;
        update testCase;
        Test.stopTest();

        List<Group> tokyoEscalationQueue = [SELECT ID FROM Group WHERE Name = 'Tokyo Escalations'];
        List<Case> updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(tokyoEscalationQueue[0].Id, updatedCase[0].OwnerId, 'Reopened Japan case is not assigned to Tokyo Escalations Queue');
    }

    /**
     * @author      Sharvani Sri
     * @date        Jan 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-18658
     * @description If Case Owner is changed, then “Contract Verification Date” attributes must be cleared
     */
    @isTest
    static void testupdateContractVerificationDate() {

        Test.startTest();
        List<Case> cslist = new List<Case>();

        Case cse1 = TDdCaseFactory.createCaseRecords(1, 'Bulk Upload Request')[0];

        cse1.Contract_Verification_Date__c = system.today();
        cslist.add(cse1);

        insert cslist;
        Case caseToUpdate = [SELECT Id, RecordType.Name
                            FROM Case
                            WHERE Id =: cse1.Id];

        User runningUser = [SELECT Id FROM User where Id = :UserInfo.getUserId()];
        System.runAs(runningUser) {
            User NewUser = TDdUserFactory.createUsers(1)[0];
            NewUser.isActive = true;
            NewUser.FirstName = 'System admin';
            NewUser.LastName = 'Test';
            insert NewUser;
        }
        Id NewUserId = [SELECT Id FROM User
                                WHERE FirstName ='System admin'
                                AND LastName ='Test'
                                LIMIT 1].Id;
        caseToUpdate.OwnerId = NewUserId;//Owner changed
        update caseToUpdate;
        Test.stopTest();
        Datetime updatedOwner = (Datetime) [SELECT Contract_Verification_Date__c FROM Case WHERE Id =:caseToUpdate.Id LIMIT 1].Contract_Verification_Date__c;
        System.assertEquals(null, updatedOwner);
    }

    /**
    * @author Veera Maddukuri
    * @date 2022-01
    *
    * @description: Test method for trackPackages - Hikyaku express
    */
    @isTest
    static void testTrackPackagesForHikyaku(){
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Account> acctRecordsToBeInserted = new List<Account>();

        acctRecordsToBeInserted = TDdAccountFactory.createAccounts('Testy McTesterson', 1);
        insert acctRecordsToBeInserted;

        caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1,'Tablet Requests');
        caseRecordsToBeInserted[0].AccountId = acctRecordsToBeInserted[0].Id;
        caseRecordsToBeInserted[0].Status ='New';
        caseRecordsToBeInserted[0].Shipping_Type__c = System.Label.SHIPPING_HIKYAKU_EXPRESS;
        caseRecordsToBeInserted[0].Return_Shipping_Address_State__c = 'TX';
        insert caseRecordsToBeInserted;

        CDdCaseTriggerHelperV2.PACKAGE_TRACKING_RUN_ONCE = false;
        caseRecordsToBeInserted[0].Tablet_Tracking__c = '169890814542';
        Test.startTest();
        update caseRecordsToBeInserted;
        Test.stopTest();

        List<zkmulti__MCShipment__c> shipmentRecord = [SELECT Id, zkmulti__Tracking_Number__c FROM zkmulti__MCShipment__c WHERE zkmulti__Tracking_Number__c = '169890814542'];
        System.assertEquals(false, shipmentRecord.isEmpty(), 'No Shipment created for shipment type '+System.Label.SHIPPING_HIKYAKU_EXPRESS);
    }

    /**
    * @author Swedhaa Sri M
    * @date 2022-05
    *
    * @description: Test method for trackPackages - DHL NZ
    */
    @isTest
    static void testTrackPackagesForDHLNZ(){
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Account> acctRecordsToBeInserted = new List<Account>();

        zkmulti__MCShipmate_Preference__c ShippingPreference = new zkmulti__MCShipmate_Preference__c ( zkmulti__CarrierAccountDescription__c = 'DHL Express - For NZ');
        insert ShippingPreference;

        List <zkmulti__MCShipmate_Preference__c> shipPreference = [SELECT Id, zkmulti__CarrierAccountDescription__c FROM zkmulti__MCShipmate_Preference__c WHERE zkmulti__CarrierAccountDescription__c =: ZENKRAFT_PREFERNCE_NZ];

        List<Account> Accounts = [SELECT Id FROM Account where name like 'AccountIdTest%'];

        caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1,'Tablet Requests');
        caseRecordsToBeInserted[0].AccountId = Accounts[0].Id;
        caseRecordsToBeInserted[0].Status ='New';
        caseRecordsToBeInserted[0].Shipping_Type__c = SHIPPING_TYPE_NZ;
        caseRecordsToBeInserted[0].Shipping_Address_Country__c = 'New Zealand';
        caseRecordsToBeInserted[0].Return_Shipping_Address_State__c = 'TX';
        insert caseRecordsToBeInserted;

        CDdCaseTriggerHelperV2.PACKAGE_TRACKING_RUN_ONCE = false;
        caseRecordsToBeInserted[0].Tablet_Tracking__c = '142345678910';
        Test.startTest();
        update caseRecordsToBeInserted;
        Test.stopTest();

        List<zkmulti__MCShipment__c> shipmentRecord = [SELECT Id, zkmulti__Tracking_Number__c,  zkmulti__Shipmate_Preference__c FROM zkmulti__MCShipment__c WHERE zkmulti__Tracking_Number__c = '142345678910'];

        System.assertEquals(false, shipmentRecord.isEmpty(), 'No. of Shipment record is created for shipment type should be greater then 0');
        System.assertEquals(shipmentRecord[0].zkmulti__Tracking_Number__c, caseRecordsToBeInserted[0].Tablet_Tracking__c, 'Case & Shipment Record Tracking Number should be same');
        System.assertEquals(shipmentRecord[0].zkmulti__Shipmate_Preference__c, shipPreference[0].Id, 'Shipment Record should be attached to correct Shipmate Preference Record');
    }

    /**
    * @author Nayana
    * @date 2022-03
    * @description: Test method for AutoCaseShadowCreation
    */
    @isTest
    static void testAutoCaseShadowCreation() {
        //create Case record
        Case testCase = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        testCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        Test.startTest();
        insert testCase;
        Test.getEventBus().deliver();
        Test.stopTest();
        List<EventBusSubscriber> lstEventSubscriber = [SELECT Name, Position, Retries, LastError ,Topic
                                        FROM EventBusSubscriber where Type='ApexTrigger' AND topic = 'Generic_Platform_Event__e'];
        System.assertEquals(1,lstEventSubscriber.size(),'Event published successfuly');
    }

    /* @author Nayana Kapse
    * @date 2022-03
    * @description: Test method for processSendbirdChats for Mulesoft PE
    */
    @isTest
    static void testProcessSendbirdChatsMulesoftPE() {
        List<Case> sendbirdCases = TDdCaseFactory.createSendbirdCase(1, null, null);
        insert sendbirdCases;

        Test.startTest();
        sendbirdCases[0].Status = CDdSupportConstants.OPEN_STATUS;
        update sendbirdCases[0];
        Test.getEventBus().deliver();
        Test.stopTest();
        /*Though Test.getEventBus().deliver(); used query not returning Event.
        List<EventBusSubscriber> lstEventSubscriber = [SELECT Name, Position, Retries, LastError ,Topic
                                                       FROM EventBusSubscriber where Type='ApexTrigger' AND topic = 'Sendbird_Mulesoft_Chat_Event__e'];
        System.assertEquals(1,lstEventSubscriber.size(),'Sendbird_Mulesoft_Chat_Event__e Event published successfully');*/
    }


    /*****************************************************************************************************************************
     *
     * Raju L - BZAP-14831 - Moved from VCaseTriggerHandlerTest - Start
     *
     *****************************************************************************************************************************/

    @isTest
    static void doInsertTest () {
        Id supportRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case testCase = new Case(RecordTypeId=supportRecTypeId,
                                 Subject='Test Case',
                                 Status='New',
                                 Origin='Web',
                                 Customer_Type__c='Consumer',
                                 SuppliedEmail='test@fakemail.com',
                                 SuppliedName='Testy McTesterson');
        insert testCase;
    }

    @isTest
    static void testBypass() {
        vCS__c testSettings = vCS__c.getOrgDefaults();
        testSettings.CaseTrigger__c = false;
        update testSettings;
        Id supportRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case testCase = new Case(RecordTypeId=supportRecTypeId,
                                 Subject='Test Case',
                                 Status='New',
                                 Origin='Web',
                                 Customer_Type__c='Consumer',
                                 SuppliedEmail='test@fakemail.com',
                                 SuppliedName='Testy McTesterson');
        insert testCase;
    }

    @isTest
    static void testTriggerAutoResponse() {
        Id supportRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case testCase = new Case(RecordTypeId=supportRecTypeId,
                                 Subject='Test Case',
                                 Status='New',
                                 Origin='Web',
                                 Customer_Type__c='Consumer',
                                 SuppliedEmail='test@fakemail.com',
                                 SuppliedName='Testy McTesterson');
        insert testCase;
    }

/**
    * @author Saniya Belim
    * @date 2018-11
    *
    * @description: Test vBackToQueue method
    * Create a Queue
    * Queue should be assigned as a Case owner
    * Case Record Type: Support
    */
    @isTest
    static void vBackToQueue_testMethod(){
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        List<Case> caseRecordsToBeInserted = new List<Case>();
        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }

        caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1,'Support');
        insert caseRecordsToBeInserted;

        Test.startTest();

        caseRecordsToBeInserted[0].OwnerId = testGroup.Id;
        caseRecordsToBeInserted[0].Issue_Type__c ='Account Management - CX';
        caseRecordsToBeInserted[0].Issue__c ='Update Account Information';
        update caseRecordsToBeInserted;

        List<Case> recentlyAddedcase = [Select Id, AccountId, Initial_Queue__c,
                                        OwnerId, Back_to_Queue__c, BypassVeltigCaseTrigger__c
                                        FROM Case
                                        WHERE Id IN :caseRecordsToBeInserted];

        System.assertEquals(recentlyAddedcase[0].OwnerId, recentlyAddedcase[0].Initial_Queue__c);

        recentlyAddedcase[0].Back_to_Queue__c  = true;
        update recentlyAddedcase;

        List<Case> recentlyUpdatedcase = [Select Id, AccountId, Initial_Queue__c,
                                          OwnerId, Back_to_Queue__c, BypassVeltigCaseTrigger__c
                                          FROM Case
                                          WHERE Id IN :recentlyAddedcase];
        System.assertEquals(false, recentlyUpdatedcase[0].Back_to_Queue__c);
        System.assertEquals(recentlyAddedcase[0].Initial_Queue__c, recentlyUpdatedcase[0].OwnerId);


        Test.stopTest();
    }

    /**
    * @author Saniya Belim
    * @date 2018-11
    *
    * @description: Test MxMarketingCase method
    * Create a Queue
    * Queue should be assigned as a Case owner
    * Case Record Type: Dasher / Merchant Kits
    * Account: Any account with Billing Address
    */
    @isTest
    static void mxMarketingCase_testMethod(){
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Account> acctRecordsToBeInserted = new List<Account>();

        acctRecordsToBeInserted = TDdAccountFactory.createAccounts('Bob', 1);
        insert acctRecordsToBeInserted;

        Test.startTest();
        caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1,'Dasher / Merchant Kits');
        caseRecordsToBeInserted[0].AccountId = acctRecordsToBeInserted[0].Id;
        insert caseRecordsToBeInserted;

        List<Case> recentlyAddedcase = [Select Id, AccountId, RecordTypeId, Return_Shipping_Address_State__c
                                        FROM Case
                                       WHERE ID IN :caseRecordsToBeInserted];
        System.assertEquals('CA', recentlyAddedcase[0].Return_Shipping_Address_State__c);
        Test.stopTest();
    }

    /**
    * @author Saniya Belim
    * @date 2018-11
    *
    * @description: Test vPersonAccountChange method
    * Create a Queue
    * Queue should be assigned as a Case owner
    * Case Record Type: Menu Team
    * Account Record Type: Dasher
    * Account should be a person account
    */
    @isTest
    static void vPersonAccountChange_testMethod(){
        List<Account> prospectAcctRecords = TDdAccountFactory.createAccounts('Bob', 1, 'Consumer or Dasher');
        insert prospectAcctRecords;
        Test.startTest();
        List<Account> acctList = [SELECT Id, Name FROM Account];
        List<Case> caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseRecordsToBeInserted[0].AccountId = acctList[0].Id;
        insert caseRecordsToBeInserted;
        List<Case> c = [SELECT ID, Subject, IsPersonAccount__c FROM CASE];
        System.assertEquals(false, c[0].IsPersonAccount__c);

        List<Account> acct = TDdAccountFactory.createAccounts('Cody', 1, 'Consumer or Dasher');
        insert acct;

        List<Case> recentlyAddedcase = [Select Id, SuppliedEmail, AccountId, IsPersonAccount__c
                                        FROM Case];
        recentlyAddedcase[0].AccountId = acct[0].Id;
        update recentlyAddedcase;
        List<Case> updatedCase = [Select Id, SuppliedEmail, AccountId, IsPersonAccount__c
                                        FROM Case];
        System.assertEquals(true, updatedCase[0].IsPersonAccount__c);
        Test.stopTest();
    }

    /**
    * @author Saniya Belim
    * @date 2018-11
    *
    * @description: TODO
    */
    @isTest
    static void caseSubjectAutomation_testMethod(){
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Account> acctRecordsToBeInserted = new List<Account>();

        acctRecordsToBeInserted = TDdAccountFactory.createAccounts('Testy McTesterson', 1);
        insert acctRecordsToBeInserted;

        Test.startTest();
        caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1,'Support');
        caseRecordsToBeInserted[0].AccountId = acctRecordsToBeInserted[0].Id;
        caseRecordsToBeInserted[0].Issue_Type__c ='Account Management - CX';
        caseRecordsToBeInserted[0].Issue__c ='Update Account Information';
        insert caseRecordsToBeInserted;

        List<Case> recentlyAddedcase = [Select Id, Subject
                                        FROM Case
                                       WHERE Id in :caseRecordsToBeInserted];
        System.assertEquals('Testy McTesterson - Update Account Information - Account Management - CX', recentlyAddedcase[0].Subject);
        Test.stopTest();
    }

    /**
    * @author Tia Xuan
    * @date 2019-05
    *
    * @description: Test method for caseReopenedDate
    */
    @isTest
    static void caseReopenedDate_testMethod(){
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Account> acctRecordsToBeInserted = new List<Account>();

        acctRecordsToBeInserted = TDdAccountFactory.createAccounts('Testy McTesterson', 1);
        insert acctRecordsToBeInserted;

        Test.startTest();
        caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1,'Support');
        caseRecordsToBeInserted[0].AccountId = acctRecordsToBeInserted[0].Id;
        caseRecordsToBeInserted[0].Status ='Reopened';
        insert caseRecordsToBeInserted;

        List<Case> recentlyAddedcase = [Select Id, PB_WF_Flow_Ran__c, Reopened_Date__c
                                        FROM Case];
        //System.Assert(recentlyAddedcase[0].PB_WF_Flow_Ran__c == 'Case Reopened Date');
        //System.Assert(recentlyAddedcase[0].Reopened_Date__c != null);
        Test.stopTest();
    }

    /**
    * @author Tia Xuan
    * @date 2019-09
    *
    * @description: Test method for trackPackages
    *               Raju L - this fails with zkusps.ShipmentInterfaceException: CAS Load Error - inside the zkusps package.
    *               possibly because the tracking numbers are invalid.
    */
    /*@isTest
    static void trackPackages_testMethod(){
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Account> acctRecordsToBeInserted = new List<Account>();

        acctRecordsToBeInserted = TDdAccountFactory.createAccounts('Testy McTesterson', 1);
        insert acctRecordsToBeInserted;

        Test.startTest();

        caseRecordsToBeInserted = TDdCaseFactory.createCaseRecords(1,'Pre to Post-Sale Handoff');
        caseRecordsToBeInserted[0].AccountId = acctRecordsToBeInserted[0].Id;
        caseRecordsToBeInserted[0].Status ='New';
        caseRecordsToBeInserted[0].USPS_Tracking_Number__c = '111111';
        insert caseRecordsToBeInserted;

        caseRecordsToBeInserted[0].Tablet_Tracking_FedEx__c = '111111';
        update caseRecordsToBeInserted;

        update caseRecordsToBeInserted;
        Test.stopTest();
    }*/


    /**
    * @author Tia Xuan
    * @date 2019-09
    *
    * @description: Test method for routeCaseToDenali
    */
    @isTest
    static void routeCaseToDenali_testMethod(){
        Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'Queen';
        acct.iPad_Password__c = 'asdf';
        acct.iPad_Username__c = 'asdf';
        insert acct;

        Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        insert ctc;

        Case cs = new Case(
            AccountId = acct.Id,
            ContactId = ctc.Id,
            RecordTypeId = Schema.SObjectType.Case
                            .getRecordTypeInfosByName()
                            .get('Tablet Requests').getRecordTypeId(),
            subject = 'Test Case',
            Return_Label_Shipping_Contact_Name__c = 'test',
            Status = 'New',
            Tablet_Device_Type__c = 'Samsung Galaxy Tab E LTE',
            Shipping_Type__c = 'Standard',
            Request_Type__c  = 'Ship to Merchant (New Tablet, Printer)',
            Include_Large_Marketing_Kit__c = true,
            Include_Marketing_Kit__c = true,
            Origin ='Photos Sent',
            Return_Shipping_Address_State__c = 'Florida'
        );
        insert cs;

        Test.startTest();

        cs.Status ='Approved';
        update cs;

        Case c = [select Id, Send_To_Denali__c, PB_WF_Flow_Ran__c, status from Case where Id =: cs.Id];
        System.assert(c.Send_To_Denali__c == true);

        Test.stopTest();
    }

    /**
    * @author Tia Xuan
    * @date 2019-10
    *
    * @description: Test method for assignEquipmentToCase
    */
    @isTest
    static void assignEquipmentToCase_testMethod(){
        Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'Queen';
        insert acct;

        Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        insert ctc;

        Case cs = new Case(
            AccountId = acct.Id,
            ContactId = ctc.Id,
            RecordTypeId = Schema.SObjectType.Case
                            .getRecordTypeInfosByName()
                            .get('Tablet Requests').getRecordTypeId(),
            subject = 'Test Case',
            Return_Label_Shipping_Contact_Name__c = 'test',
            Status = 'New',
            Tablet_Device_Type__c = 'Samsung Galaxy Tab E LTE',
            Shipping_Type__c = 'Standard',
            Request_Type__c  = 'Ship to Merchant (New Tablet, Printer)',
            Include_Large_Marketing_Kit__c = true,
            Include_Marketing_Kit__c = true,
            Origin ='Photos Sent',
            Return_Shipping_Address_State__c = 'Florida'
        );
        insert cs;

        Test.startTest();

        User u = [select Id from User where LastName = 'Dataloader.io' ];

        System.runAs(u){

            cs.Denali_Tablet_Record_ID__c = 'test';
            cs.Denali_Printer_Record_ID__c = 'test1';
            update cs;

            Case c = [select Id, Equipment__c, Printer_Equipment__c from Case where Id =: cs.Id];
            System.assert(c.Equipment__c != null);
            System.assert(c.Printer_Equipment__c != null);
        }

        Test.stopTest();
    }
    /**
     * @author @ebby
    * @date 2021-10
    *
    * @description: Test method for createDenaliLogs
    */
    @isTest
    static void createDenaliLogs_testMethod(){
        Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'Queen';
        acct.iPad_Password__c = 'asdf';
        acct.iPad_Username__c = 'asdf';
        insert acct;

        Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        insert ctc;

        Case cs = new Case(
            AccountId = acct.Id,
            ContactId = ctc.Id,
            RecordTypeId = Schema.SObjectType.Case
                            .getRecordTypeInfosByName()
                            .get('Tablet Requests').getRecordTypeId(),
            subject = 'Test Case',
            Return_Label_Shipping_Contact_Name__c = 'test',
            Status = 'New',
            Tablet_Device_Type__c = 'Samsung Galaxy Tab E LTE',
            Shipping_Type__c = 'Standard',
            Request_Type__c  = 'Ship to Merchant (New Tablet, Printer)',
            Include_Large_Marketing_Kit__c = true,
            Include_Marketing_Kit__c = true,
            Origin ='Photos Sent',
            Return_Shipping_Address_State__c = 'Florida'
        );
        insert cs;

        Test.startTest();

        cs.Status ='Approved';
        cs.Denali_Record_ID__c = '946d27729d9fa53d54910c4b36bcc898b4c02a8669';
        update cs;

        List<Denali_Log__c> logs = [select Id from Denali_Log__c where Case__c =: cs.Id];
        System.assert(logs != null && !logs.isEmpty());

        Test.stopTest();
    }

    /**
     * @author      Mahesh Chouhan
     * @date        May 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-30021
     * @description Test method for preventInvalidEsc
     */
    @isTest
    static void testPreventInvalidEsc(){
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Test.startTest();
        //create test account
        // Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        List<Account> testAccts = [Select id, name from Account where recordtype.name = 'Marketplace'];
        Account testAcct;
        if(testAccts.size() > 0 ) {
            testAcct = testAccts[0];
        }
        // insert testAcct;

        //create valid case
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        testCaseList[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_DASHER;
        testCaseList[0].Issue_Type__c = 'Account Issue - Dx';
        testCaseList[0].Issue__c = 'Account Updates - Dx';
        if(testAcct != null){
            testCaseList[0].AccountId = testAcct.Id;
        }
        insert testCaseList;

        List<Group> sfDahserQueue = [SELECT ID FROM Group WHERE DeveloperName = :CDdCaseTriggerHelperV2.QUEUE_SF_DASHER];
        try {
            testCaseList[0].OwnerId = sfDahserQueue[0].Id;
            update testCaseList;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains(System.Label.Case_Invalid_Escalation_Issue_Type), 'Error Message on changing case owner is not same as expected.');
        }
        Test.stopTest();
    }
    /*****************************************************************************************************************************
     *
     * Raju L - BZAP-14831 - Moved from VCaseTriggerHandlerTest - End
     *
     *****************************************************************************************************************************/

     /**
    * @author Veera
    * @date 2022-06
    *
    * @description: Test method for tablet request updateCaseStatus
    */
    @isTest
    static void testCaseMVStatusChange(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Case_Validations__c = true;
        insert validation;

        Account acc = [SELECT Id from Account LIMIT 1];
        acc.iPad_Username__c = 'username';
        acc.iPad_Password__c = 'password';
        update acc;

       Contact con = [SELECT ID, AccountId FROM Contact WHERE FirstName = 'Test Contact 1'];
       Opportunity opp = (Opportunity)CDdTestDataFactory.createSObject('Opportunity', new Map<String,Object>{
            'AccountId' => con.AccountId,
            'ContactId'=>con.Id,
            'StageName'=>'New',
            'Name'=>'Test Opp'
            }, true);
        List<Opportunity> oppty = [SELECT Id from Opportunity LIMIT 1];

        Case caseRec = TDdCaseFactory.createCases(1, acc.Id, oppty[0].Id, CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId)[0];
        caseRec.Status = CDdSupportConstants.ESCALATED_STATUS;
        caseRec.MV_Status__c = '';
        caseRec.Return_Shipping_Address_State__c = 'CA';
        insert caseRec;
        caseRec.Status = CDdSupportConstants.ESCALATED_STATUS;
        update caseRec;

        Test.startTest();
        caseRec.Status = CDdSupportConstants.APPROVED_STATUS;
        update caseRec;
        Test.stopTest();
        Case updatedCase = [SELECT Id,MV_Status__c,Status,recordtype.name FROM Case where Id=:caseRec.Id LIMIT 1];
        System.assertEquals(CDdSupportConstants.COMPLETED_STATUS, updatedCase.MV_Status__c, 'MV Status not updated to completed when Case status moved from Escalated to Approved');
    }


    /**
     * @author      Mahesh Chouhan
     * @date        April 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-961
     */
    @isTest
    static void testDispatchIfResponseIsPopulatedPositive(){
        Test.startTest();
        Dispatch_Settings__c setting = VTestUtil.createDispatchSettings();
        setting.Use_ERS_API__c = true;
        setting.Dispatch_ERS_Endpoint__c = 'test';
        setting.Dispatch_ERS_Token__c = 'test';
        insert setting;

        String msg = VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE;

        Support_Feature_Flag__c settings = Support_Feature_Flag__c.getOrgDefaults();
        settings.Enable_Dispatch_for_Sendbird__c = true;
        upsert settings;

        VDispatchdeliveryCalloutMock mock = new VDispatchdeliveryCalloutMock(
            200,
            'Success',
            msg
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse.Origin = 'Chat';
        cse.Channel__c = 'DoorDash App - Sendbird';
        cse.Customer_Type__c = 'Dasher';
        cse.chatkey__c = 'sh-mobile-aead0b61-99f6-4fef-9af9-b4139bb2de0a';
        cse.DeliveryUUID__c = '033f579d-2b4b-4810-ba17-e480e643f710';
        cse.Alert_Type__c = 'Dx self help needs follow up';
        cse.DispatchRQResponse__c = VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE;
        insert cse;
        Test.stopTest();

        Case cseResult = [SELECT  Id,DispatchRQStatus__c
                          FROM Case
                          WHERE Id =: cse.Id];
        System.assertEquals('Success', cseResult.DispatchRQStatus__c, 'DispatchRQStatus__c is not same as expected.');
    }

    /**
     * @author      Mahesh Chouhan
     * @date        April 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-961
     */
    @isTest
    static void testDispatchIfResponseIsPopulatedNegative(){
        Test.startTest();
        Dispatch_Settings__c setting = VTestUtil.createDispatchSettings();
        setting.Use_ERS_API__c = true;
        setting.Dispatch_ERS_Endpoint__c = 'test';
        setting.Dispatch_ERS_Token__c = 'test';
        insert setting;

        String msg = VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE;

        Support_Feature_Flag__c settings = Support_Feature_Flag__c.getOrgDefaults();
        settings.Enable_Dispatch_for_Sendbird__c = true;
        upsert settings;

        VDispatchdeliveryCalloutMock mock = new VDispatchdeliveryCalloutMock(
            200,
            'Success',
            '{}'
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Case cse = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse.Origin = 'Chat';
        cse.Channel__c = 'DoorDash App - Sendbird';
        cse.Customer_Type__c = 'Dasher';
        cse.chatkey__c = 'sh-mobile-aead0b61-99f6-4fef-9af9-b4139bb2de0a';
        cse.DeliveryUUID__c = '033f579d-2b4b-4810-ba17-e480e643f710';
        cse.Alert_Type__c = 'Dx self help needs follow up';
        cse.DispatchRQResponse__c = '{invalid json}';
        insert cse;
        Test.stopTest();

        Case cseResult = [SELECT  Id,DispatchRQStatus__c, Subject
                          FROM Case
                          WHERE Id =: cse.Id];
        System.assertEquals('Failure', cseResult.DispatchRQStatus__c, 'DispatchRQStatus__c is not same as expected.');
    }
    /**
    * @author @CriticalRiver
    * @date 2022-07
    *
    * @description: Test method for reopenMxDxCxCases
    */
    @isTest
    static void reopenMxDxCxCases_testMethod(){
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        Account testAccount=TDdAccountFactory.createAccounts('Testy McTesterson', 1)[0];
        insert testAccount;
        Case testCase=TDdCaseFactory.createCaseRecords(1,'Support')[0];
        testCase.AccountId=testAccount.Id;
        testCase.Status=CDdSupportConstants.SOLVED_STATUS;
        testCase.Last_Email_from_Customer__c= DateTime.now().addDays(-5);
        testCase.Priority =CDdSupportConstants.MEDIUM_PRIORITY;
        testCase.SF_Queue__c = true;
        testCase.Customer_Type__c =CDdSupportConstants.CUSTOMER_TYPE_DASHER;
        testCase.ownerId=[SELECT Id FROM User WHERE IsActive = true AND Profile.Name='Agent' LIMIT 1].Id;
        Insert testCase;

        Test.startTest();
        testCase.Last_Email_from_Customer__c = DateTime.now().addHours(-5);
        update testCase;
        Case caseResult1 = [SELECT Id, RecordType.Name,status
                            FROM Case
                            WHERE Id =: testCase.Id];
        System.assertEquals(caseResult1.status, CDdSupportConstants.REOPEN_STATUS);
        Test.stopTest();
    }
    /**
    * @author Ila Maheshwari
    * @date 2022-07
    *
    * @description: Test method for populate Date/Time case become workable
    */
    @isTest
    static void populateDateTimeCaseBecameWorkable_testMethod(){
        Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'King of Spades';
        acct.iPad_Password__c = 'asdf';
        acct.iPad_Username__c = 'asdf';
        insert acct;

        Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        insert ctc;

        Test.startTest();
        Case cs = new Case(
            AccountId = acct.Id,
            ContactId = ctc.Id,
            RecordTypeId = Schema.SObjectType.Case
                            .getRecordTypeInfosByName()
                            .get('Menu Update').getRecordTypeId(),
            subject = 'Test Case Menu Update',
            Return_Label_Shipping_Contact_Name__c = 'test',
            Status = 'New',
            Tablet_Device_Type__c = 'Samsung Galaxy Tab E LTE',
            Shipping_Type__c = 'Standard',
            Request_Type__c  = 'Ship to Merchant (New Tablet, Printer)',
            Include_Large_Marketing_Kit__c = true,
            Include_Marketing_Kit__c = true,
            Origin ='Photos Sent',
            Return_Shipping_Address_State__c = 'Florida'
        );
        insert cs;
        Test.stopTest();

        List<Case> caseList = [SELECT Id, Date_Time_Case_Became_Workable__c FROM Case Where subject = 'Test Case Menu Update'];
        System.assertEquals(caseList[0].Date_Time_Case_Became_Workable__c, DateTime.newInstance(Date.today().addDays(1),Time.newInstance(7, 0, 0, 0)));
    }

    /**
     * @author      Sid Agarwal
     * @date        July 2022
     * @jira        BIZS-1506 MxP Pending to Solve Automated Delay
     * @description Perform validations on Case 'Pending Reason' picklist field values
     */
    @isTest
    static void test_validationsCasePendingReason_Delay()
    {
        // -- Validate CMT Records for 'Name Value Pair' exists -- //

        String nameValuePair1 = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_SOLVE_MISSING_PERM);
        system.assert(String.isNotBlank(nameValuePair1), 'Name Value pair does not exist: CASE_VR_PENDING_SOLVE_MISSING_PERM');

        String nameValuePair2 = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_SOLVE_WRONG_STATUS);
        system.assert(String.isNotBlank(nameValuePair2), 'Name Value pair does not exist: CASE_VR_PENDING_SOLVE_WRONG_STATUS');

        // -- Prepare dummy data -- //

        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        Case testCase = [Select id from Case Where RecordType.Id =: supportRecordTypeId Limit 1];

        // -- Test Validations -- //

        test.startTest();

        try {
            testCase.Pending_Reason__c = CDdSupportConstants.CASE_MXP_PENDING_REASON_SOLVE_WITH_DELAY;
            update testCase;
            System.assert(false, 'Excepted Exception was not thrown.');
        }
        catch (Exception e) {
            system.assert(e.getMessage().contains(nameValuePair2),'Exception thrown is different from expected - ' + e.getMessage());
        }

        test.stopTest();
    }

    /**
     * @author      Sid Agarwal
     * @date        July 2022
     * @jira        BIZS-1539 [Q3] POS Reporting Optimization
     * @description Perform validations on Case 'Pending Reason' picklist field values
     */
    @isTest
    static void test_validationsCasePendingReason_POS()
    {
        // -- Validate CMT Records for 'Name Value Pair' exists -- //

        String nameValuePair1 = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_POS_WRONG_FIELD);
        system.assert(String.isNotBlank(nameValuePair1), 'Name Value pair does not exist: CASE_VR_PENDING_POS_WRONG_FIELD');

        String nameValuePair2 = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_POS_MISSING_FIELD);
        system.assert(String.isNotBlank(nameValuePair2), 'Name Value pair does not exist: CASE_VR_PENDING_POS_MISSING_FIELD');

        // -- Prepare dummy data -- //

        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        Case testCase = [Select id from Case Where RecordType.Id =: supportRecordTypeId Limit 1];

        // -- Test Validations -- //

        test.startTest();

        try {
            testCase.Pending_Reason__c = CDdSupportConstants.CASE_MXP_PENDING_REASON_WAITING_ON_POS_PROVIDER;
            testCase.Issue_Type__c = 'Other - MX';
            update testCase;
            System.assert(false, 'Excepted Exception was not thrown.');
        }
        catch (Exception e) {
            system.assert(e.getMessage().contains(nameValuePair1),'Exception thrown is different from expected - ' + e.getMessage());
        }

        try {
            testCase.Pending_Reason__c = CDdSupportConstants.CASE_MXP_PENDING_REASON_WAITING_ON_POS_PROVIDER;
            testCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_TYPE_POINT_OF_SALE;
            update testCase;
            System.assert(false, 'Excepted Exception was not thrown.');
        }
        catch (Exception e) {
            system.assert(e.getMessage().contains(nameValuePair2),'Exception thrown is different from expected - ' + e.getMessage());
        }

        test.stopTest();
    }

    /**
     * @author      Sahil
     * @date        August 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1609
     * @description test method for handling phone cases which were marked unresolved contact
     */
    @isTest
    static void test_handleUnresolvedContactPhoneCases() {
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        Case testCase = [Select id from Case Where RecordType.Id =: supportRecordTypeId Limit 1];
        System.assertNotEquals(null, testCase, 'test case should be returned from database');
        Test.startTest();
        testCase.Customer_Type__c = 'Consumer';
        testCase.Origin = CDdSupportConstants.CASE_ORIGIN_PHONE;
        testCase.Issue_Type__c = 'Other - CX';
        testCase.Issue__c = 'Unresolved Contact: Dropped';
        update testCase;
        Test.stopTest();
        //assert that case issue got updated
        List<Case> caseFromDB = [SELECT Issue__c FROM Case WHERE Id =:testCase.Id];
        System.assertEquals('Unresolved Contact: Dropped', caseFromDB[0].Issue__c, 'case issue should be unresolved contact');
        //unable to test event delivery to external subscriber
        //https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_test_events.htm
    }

    /* /**
     * @author      Sid Agarwal
     * @date        Aug 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1700
     * @description Auto-Reject Duplicate Chargeback Submissions - P0s

    @isTest
    static void test_mxChargebackCheckDuplicate()
    {
        // collections
        List<Case> existingCases = new List<Case>();
        List<Case> newCases = new List<Case>();
        Set<Id> newCaseIds = new Set<Id>();

        // query pre-req data
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        Id mxParkingQueueId = [Select id from Group Where Name =: CDdCaseTriggerHelperV2.QUEUE_MX_PARKING Limit 1].id;

        // query and update Support Cases created in the setup to meet the use case
        existingCases = [Select id, AccountId, Delivery_UUID_8_Digit__c, Description from Case Where RecordTypeId =: supportRecordTypeId and AccountId != null Limit 4];
        existingCases[0] = test_mxChargebackCheckDuplicate_update_helper(existingCases[0], 'Cancelled Order Refund', '11111111');
        existingCases[1] = test_mxChargebackCheckDuplicate_update_helper(existingCases[1], 'Cancelled Order Refund', '22222222');
        existingCases[2] = test_mxChargebackCheckDuplicate_update_helper(existingCases[2], 'Error Charge Disputes', '33333333');
        existingCases[3] = test_mxChargebackCheckDuplicate_update_helper(existingCases[3], 'Error Charge Disputes', '44444444');
        update existingCases;

        // insert new cases
        for(Case c : [Select id, AccountId, RecordType.Id, Formstack_Subcategory__c, Delivery_UUID_8_Digit__c From Case Where Id =: existingCases]) {
            Case newCase = test_mxChargebackCheckDuplicate_insert_helper(mxParkingQueueId, c.AccountId, c.RecordTypeId, c.Formstack_Subcategory__c, c.Delivery_UUID_8_Digit__c);
            newCases.add(newCase);
        }
        insert newCases;

        // validate Delivery Id is setup on new Cases
        for(Case c : [Select id, OwnerId, Delivery_UUID_8_Digit__c From Case Where Id =: newCases])
        {
            system.assertEquals(c.OwnerId, mxParkingQueueId);
            system.assert(String.isNotBlank(c.Delivery_UUID_8_Digit__c), 'Exception: Delivery_UUID_8_Digit is not set on setup cases');
        }

        // fire Platform Event
        List<Generic_Platform_Event__e> platformEventsList = CDdGenericPlatformEventHelper.createEvents(CDdGenericPlatformEventHelper.PlatformEventType.CASE_MX_CHARGEBACK, null, JSON.serialize(newCaseIds));
        Test.startTest();
        CDdCaseEventHelper.mxChargebackCheckDuplicate(platformEventsList);
        Test.stopTest();

        // validate duplicate logic
        for(Case c : [Select id, AccountId, RecordTypeId, ParentId, OwnerId, Delivery_UUID_8_Digit__c From Case Where Id IN: newCaseIds])
        {
            if(c.Delivery_UUID_8_Digit__c.startsWith('5') || c.Delivery_UUID_8_Digit__c.startsWith('6'))
                system.assertEquals(null, c.ParentId);      // no dup
            else
                system.assertNotEquals(null, c.ParentId);   // dups
        }
    }
    static Case test_mxChargebackCheckDuplicate_update_helper(Case c, String formstackSubcategory, String deliveryId)
    {
        c.Origin = 'Web';
        c.Formstack_Source__c = 'Support Request - Mx Portal';
        c.Formstack_Subcategory__c = formstackSubcategory;
        c.Description = 'Payments - ' + formstackSubcategory + ' \n ' + deliveryId + ' \n Test Line 3 \n Test Line 4';
        c.Delivery_UUID_8_Digit__c = deliveryId;
        return c;
    }
    static Case test_mxChargebackCheckDuplicate_insert_helper(Id ownerId, Id accountId, Id recordTypeId, String formstackSubcategory, String deliveryId)
    {
        Case c = new Case();
        c.OwnerId = String.isBlank(ownerId) ? UserInfo.getuserId() : ownerId;
        c.AccountId = accountId;
        c.RecordTypeId = recordTypeId;
        c.Origin = 'Web';
        c.Formstack_Source__c = 'Support Request - Mx Portal';
        c.Formstack_Subcategory__c = formstackSubcategory;
        c.Description = 'Payments - ' + formstackSubcategory + ' \n ' + deliveryId + ' \n Test Line 3 \n Test Line 4';
        return c;
    }
 */
    /**
     * @author      Ila Maheshwari
     * @date        November 2022
     * @jira        BASD-39057
     * @description test method for throwing error when manually updating case status to In Rescue
     */
    @isTest
    static void test_preventInRescueStatusOnCase() {
        Id posRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_POS_INTEGRATIONS);
        Case testCase = [Select id from Case Where RecordType.Id =: posRecordTypeId Limit 1];
        Boolean correctErrorThrown = false;
        try {
            Test.startTest();
            testCase.Status = CDdSupportConstants.INRESCUE_STATUS;
            update testCase;
            Test.stopTest();
        }
        catch(Exception ex){
            correctErrorThrown = ex.getMessage().contains(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_TRIGGER_VALIDATE_INRESCUE_STATUS_ERROR_MSG));
        }
        System.assert(correctErrorThrown, 'Validation error message is not same as expected.');
    }

    /**
     * @author      Ila Maheshwari
     * @date        Dec 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-41240
     * @description test method for handling OCUS creation for Country US
     */
    @isTest
    static void testPhotoshootCaseForUS() {
		List<String> queueNames = new List<String> {'Photoshoot cases- US(OCUS)'};
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);
        Id photoshootOcusUSQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Photoshoot cases- US(OCUS)');

        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;

        Account accountsToInsert = [SELECT Id, Business_Vertical__c FROM Account WHERE Name = 'Photoshoot Account 0' LIMIT 1];
        Contact con1 = [SELECT Id, AccountId FROM Contact WHERE firstname = 'TestPhoto' LIMIT 1];
        Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonPhotoshootOpp', con1.AccountId, con1.id, 'Ready for Signature');
        opp2.Tablet_Received_Date__c = null;
        opp2.Decision_Maker__c = con1.id;
        opp2.Mx_Requesting_Photoshoot__c = CDdCoreConstants.STRING_YES;
        opp2.Case_Created__c = false;
        insert opp2;

        List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 1, false);
        for(Integer i = 0; i < 1; i++){
            cslist1[i].Store_ID__c = '' +i;
            cslist1[i].BusinessHours =null;
            cslist1[i].Subject = 'createOcusCaseForUSTest'+i;
            cslist1[i].RecordTypeId = onboardingCaseRT;
            cslist1[i].Photo_Review_Notes__c = 'OCUS';
            cslist1[i].Language__c = 'English';
            cslist1[i].AccountId = accountsToInsert.Id;
            cslist1[i].Opportunity_Name__c = opp2.Id;
        }
        Test.startTest();
        insert cslist1[0];

        cslist1[0].Menu_Preview_Links__c = 'Menu preview links';
        update cslist1;
        Test.stopTest();
        List<Case> newCase = [SELECT Id, Photo_Provider__c, RecordTypeId, OwnerId  FROM Case WHERE Opportunity_Name__c= :opp2.Id AND RecordTypeId=:CASE_PHOTOSHOOT_RECORDTYPEID];
        System.assertEquals(1, newCase.size());
        System.assertEquals('OCUS', newCase[0].Photo_Provider__c);
        System.assertEquals(photoshootOcusUSQueueId, newCase[0].OwnerId);
    }

        /**
     * @author      Rebecca
     * @date        Nov 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-39912
     * @description test method for handling setCaseOwnerForHibernatedAndSuspended() method
     */

    @isTest
    static void setCaseOwnerForHibernatedAndSuspendedTest(){
        Id onboardingCaseRT =CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Marketplace Onboarding');
        Id POSIntegrationsCaseRT =CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('POS Integrations');
        Id ReviewAndTriageRT = CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeId('Review & Triage');
        Id SetupStoreRT = CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeId('Setup Store');
        Id SetupBusinessRT = CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeId('Setup Business');
        Id GrantPortalAccessRT = CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeId('Grant Portal Access');

        List<String> queueNames = new List<String> {'Hibernated POS Providers','Suspended POS Providers','Onboarding - POS','Onboarding - POS Integrations','ENT Onboarding - Under Review'};
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);

        Id hibernatedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Hibernated POS Providers');
        Id suspendedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Suspended POS Providers');
        Id onboardingPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Onboarding - POS');

        Queue_Settings__mdt testMetadataRecord = new Queue_Settings__mdt(DeveloperName='Marketplace_Onboarding_Queue_IDs', MasterLabel='Marketplace Onboarding Queue IDs', Queue_IDs_Part_5__c = (string)(hibernatedPOSProvidersQueueId +','+ suspendedPOSProvidersQueueId ));

        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 1, 'Marketplace');
        for(Integer k=0; k<accs.size(); k++)
        {
            accs[k].iPad_Username__c = 'test '+ k;
            accs[k].iPad_Password__c = '12345';
            accs[k].Restaurant_ID__c = '11111';
        }
        insert accs;

        List<Case> onboardingCases = TDdCaseFactory.createCaseRecords(1,'Marketplace Onboarding');
        for(Integer k=0; k< onboardingCases.size(); k++)
        {
          onboardingCases[k].AccountId = accs[0].Id;
          onboardingCases[k].Status = 'Open';
          onboardingCases[k].OwnerId = onboardingPOSProvidersQueueId;
          onboardingCases[k].POS_Integration_Type__c= 'farmstead';
        }
        insert onboardingCases;


        Milestone_Template__c RTtempl = new Milestone_Template__c(
                Milestone_Type__c = 'Review & Triage',
                Milestone_Record_Type_ID_18__c = ReviewAndTriageRT,
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = onboardingCaseRT,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = Userinfo.getUserId(),
                Default_Sort_Order__c = 1,
                Active__c = true);
        insert RTtempl;
        Milestone_Template__c SStempl = new Milestone_Template__c(
                Milestone_Type__c = 'Setup Store',
                Milestone_Record_Type_ID_18__c = SetupStoreRT,
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = onboardingCaseRT,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = Userinfo.getUserId(),
                Default_Sort_Order__c = 1,
                Active__c = true);
        insert SStempl;
        Milestone_Template__c SBtempl = new Milestone_Template__c(
                Milestone_Type__c = 'Setup Business',
                Milestone_Record_Type_ID_18__c = SetupBusinessRT,
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = onboardingCaseRT,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = Userinfo.getUserId(),
                Default_Sort_Order__c = 1,
                Active__c = true);
        insert SBtempl;
        Milestone_Template__c GPAtempl = new Milestone_Template__c(
                Milestone_Type__c = 'Grant Portal Access',
                Milestone_Record_Type_ID_18__c = GrantPortalAccessRT,
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = onboardingCaseRT,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = Userinfo.getUserId(),
                Default_Sort_Order__c = 1,
                Active__c = true);
        insert GPAtempl;

        List<Milestone__c> marketplaceOnboardingMilestones = new List<Milestone__c>{
              new Milestone__c(Status__c = 'Complete',Milestone_Type__c ='Review & Triage', Case__c = onboardingCases[0].Id, Sort_Order__c = 1,
                  RecordTypeId = ReviewAndTriageRT, Milestone_Template__c = RTtempl.Id),
              new Milestone__c(Status__c = 'Complete',Milestone_Type__c='Setup Store', Case__c = onboardingCases[0].Id, Sort_Order__c = 1,
                  RecordTypeId = SetupStoreRT, Milestone_Template__c = SStempl.Id),
              new Milestone__c(Status__c = 'Complete',Milestone_Type__c='Setup Business', Case__c = onboardingCases[0].Id, Sort_Order__c = 1,
                  RecordTypeId = SetupBusinessRT, Milestone_Template__c = SBtempl.Id),
              new Milestone__c(Status__c = 'Complete',Milestone_Type__c='Grant Portal Access', Case__c = onboardingCases[0].Id, Sort_Order__c = 1,
                  RecordTypeId = GrantPortalAccessRT, Milestone_Template__c = GPAtempl.Id)
            };
        insert marketplaceOnboardingMilestones;

        test.startTest();
        onboardingCases[0].POS_Integration_Type__c = 'cardenas_markets';
        update onboardingCases;
        test.stopTest();

        Case c = [Select Id,OwnerId From Case Where Id =: onboardingCases[0].Id];
        System.assertEquals(hibernatedPOSProvidersQueueId, c.OwnerId);
    }

    /**
     * @author      Swedhaa Sri M
     * @date        Feb 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-44122
     * @description test method for handling setCaseOwnerForHibernatedAndSuspended() method for Insert Scenario
     */

     @isTest
     static void setCaseOwnerForHibernatedAndSuspendedInsertTest(){
         Id POSIntegrationsCaseRT =CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('POS Integrations');

         List<String> queueNames = new List<String> {'Hibernated POS Providers','Suspended POS Providers'};
         CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);

         Id hibernatedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Hibernated POS Providers');
         Id suspendedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Suspended POS Providers');

         List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 1, 'Marketplace');
         List<Case> posIntegrationCases = TDdCaseFactory.createCaseRecords(1,'POS Integrations');
         for(Integer k=0; k< posIntegrationCases.size(); k++)
         {
           posIntegrationCases[k].AccountId = accs[0].Id;
           posIntegrationCases[k].Status = 'Open';
           posIntegrationCases[k].POS_Integration_Type__c= 'xenial';
         }
         test.startTest();
         insert posIntegrationCases;
         test.stopTest();

         Case c = [Select Id,OwnerId From Case Where Id =: posIntegrationCases[0].Id];
         System.assertEquals(suspendedPOSProvidersQueueId, c.OwnerId);
     }

    /**
     * @author      Mahesh Chouhan
     * @date        Map 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description test method for handling Disaster Esalation Case
     */
    @isTest
    static void testCheckForDisasterPreventionCase() {
        //create valid case
        List<Case> caseRecord = new List<Case>();
        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
        System.runAs(getTestRunUser())
        {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }

        caseRecord = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        caseRecord[0].OwnerId = testGroup.Id;
        insert caseRecord;

        List<CaseHistory> fakeCaseHistories = new List<CaseHistory>();

        for(Integer index = 0; index < 3; index++){
            CaseHistory ownerChangeHistory = (CaseHistory) new Fake(CaseHistory.class)
                .setField(CaseHistory.Id, Fake.generateId(CaseHistory.class))
                .setField(CaseHistory.DataType, 'EntityId')
                .setField(CaseHistory.Field, 'Owner')
                .setField(CaseHistory.CaseId, caseRecord[0].Id)
                .toSObject();
            fakeCaseHistories.add(ownerChangeHistory);
        }

        for(Integer index = 0; index < 3; index++){
            CaseHistory statusChangeHistory = (CaseHistory) new Fake(CaseHistory.class)
                .setField(CaseHistory.Id, Fake.generateId(CaseHistory.class))
                .setField(CaseHistory.Field, 'Status')
                .setField(CaseHistory.CaseId, caseRecord[0].Id)
                .toSObject();
            fakeCaseHistories.add(statusChangeHistory);
        }

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ICaseHistoriesSelector caseHistorySelectorMock = (ICaseHistoriesSelector) mocks.mock(
            ICaseHistoriesSelector.class
        );

        mocks.startStubbing();
        mocks.when(caseHistorySelectorMock.sObjectType()).thenReturn(CaseHistory.SObjectType);
        mocks.when(caseHistorySelectorMock.selectByCaseIdAndFields(new Set<Id>{caseRecord[0].Id}, new Set<String>{'Status', 'Owner'})).thenReturn(fakeCaseHistories);
        mocks.stopStubbing();

        Application.Selector.setMock(caseHistorySelectorMock);

        Test.startTest();
        caseRecord[0].OwnerId = getTestRunUser().Id;
        caseRecord[0].Previous_Queue_Id__c = testGroup.Id;
        caseRecord[0].Previous_Queue__c = 'test group';
        update caseRecord;
        Test.stopTest();

        caseRecord[0].Subject = 'Check for Already Disaster Escalated Case';
        update caseRecord;

        List<Case> escalatedCase = [SELECT Id, Disaster_Escalation_Case__c FROM Case WHERE Id = :caseRecord[0].Id];
        System.assert(escalatedCase[0].Disaster_Escalation_Case__c, 'Case should be marked as Disaster Escalation Case');
    }

     /**
     * @author      Lathika
     * @date        Feb 2023
     * @jira        BZAP-19375
     * @description test method for setting the  CaseOwner To ActivationLead On Caviar Case: Turbo charge
     */
    @isTest
    static void testSetCaseOwnerToActivationLeadOnCaviarTurboCharge(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Case_Validations__c = true;
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;

        Account acc = [SELECT Id from Account LIMIT 1];
        Contact con = [SELECT ID, AccountId FROM Contact WHERE FirstName = 'Test Contact 1'];
        Opportunity opp = (Opportunity)CDdTestDataFactory.createSObject('Opportunity', new Map<String,Object>{
            'AccountId' => con.AccountId,
            'ContactId'=>con.Id,
            'StageName'=>'New',
            'Name'=>'Test Opp'
            }, true);
        opp.Platform__c = CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH;
        update opp;

        Case caseRec = TDdCaseFactory.createCases(1, acc.Id, opp.Id, CDdGenericTriggerOptimizationHelper.caviarOnboardingRecordTypeId)[0];
        caseRec.Status = CDdMxSxConstants.CASE_STATUS_ONBOARDING_ADS_AND_PROMO;
        caseRec.MxP_Handoff_Date__c = System.Today();
        caseRec.Activations_Lead__c = UserInfo.getUserId();
        insert caseRec;
        Test.startTest();
        caseRec.Status = CDdMxSxConstants.CASE_STATUS_CLOSED;
        update caseRec;
        Test.stopTest();
        Case updatedCaseFromDB = [SELECT Id, OwnerID, Activations_Lead__c FROM Case where Id = :caseRec.Id LIMIT 1];
        System.assertEquals(updatedCaseFromDB.OwnerID, updatedCaseFromDB.Activations_Lead__c);
    }

    /**
     * @author      Lathika
     * @date        Feb 2023
     * @jira        BZAP-19359
     * @description test method for setCaseStatusToClosed: Caviar Onbaording case, with no ads and Promo
     * Case Status should be set to 'Closed'
     */
    @isTest
    static void testSetCaviarOnboardingCaseStatusToClosedForPlatformCaviarAndDoordash(){
       Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
       validation.Bypass_Case_Validations__c = true;
       validation.Bypass_Opportunity_Validations__c = true;
       insert validation;
       Account acc = [SELECT Id from Account LIMIT 1];
       Contact con = [SELECT ID, AccountId FROM Contact WHERE FirstName = 'Test Contact 1'];
       Opportunity opp = (Opportunity)CDdTestDataFactory.createSObject('Opportunity', new Map<String,Object>{
            'AccountId' => con.AccountId,
            'ContactId'=>con.Id,
            'StageName'=>'New',
            'Name'=>'Test Opp'
            }, true);
       opp.Platform__c = CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH;
       Case caseRec = TDdCaseFactory.createCases(1, acc.Id, opp.Id, CDdGenericTriggerOptimizationHelper.caviarOnboardingRecordTypeId)[0];
       caseRec.Status = 'New';
       caseRec.Activation_Date__c = System.Today();
       Test.startTest();
       insert caseRec;
       Test.stopTest();
       Case updatedCaseFromDB = [SELECT Id, Status FROM Case where Id =:caseRec.Id LIMIT 1];
       System.assertEquals('Closed', updatedCaseFromDB.Status, 'Case status not set to Closed');
    }

    /**
     * @author      Lathika
     * @date        Feb 2023
     * @jira        BZAP-19359
     * @description test method for setCaseStatusToClosed: Marketplace Onbaording case,
     * Case Status should not be set to 'Closed'
     */
    @isTest
    static void testSetCaseStatusToClosed(){
       Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
       validation.Bypass_Case_Validations__c = true;
       validation.Bypass_Opportunity_Validations__c = true;
       insert validation;
       Account acc = [SELECT Id from Account LIMIT 1];
       Case onboardingCase = TDdCaseFactory.createCaseRecords(1,'Marketplace Onboarding')[0];
       onboardingCase.AccountId = acc.Id;
       onboardingCase.Status = 'Open';
       Test.startTest();
       insert onboardingCase;
       Test.stopTest();
       Case updatedCaseFromDB = [SELECT Id, Status FROM Case where Id =:onboardingCase.Id LIMIT 1];
       System.assertEquals('Open', updatedCaseFromDB.Status, 'Case status not set to Open');
    }
    /**
     * @author      Sharvani
     * @date        Mar 2023
     * @jira        BASD-43874
     * @description
     */
    @isTest
    static void testacContactTraceTransferOptimization(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Case_Validations__c = true;
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;
        List<Case> testCaseList = [select Id from case where RecordTypeId =:CASE_Support_RECORDTYPEID];
        insert new FeedItem(
            Type = CDdSupportConstants.CASEFEED_TYPE_TEXTPOST,
            Body = 'Test Record',
            ParentId = testCaseList[0].Id
        );
        Set<id> caseIdSet = new Set<id>();
        caseIdSet.add(testCaseList[0].Id);
        //Create amazonconnect__AC_ContactTraceRecord__c
        amazonconnect__AC_ContactTraceRecord__c testAmazonConnect = new amazonconnect__AC_ContactTraceRecord__c(
            Case__c = testCaseList[0].Id,
            amazonconnect__Initiation_Method__c = 'TRANSFER',
            amazonconnect__QueueName__c = 'AC Queue',
            amazonconnect__Channel__c = 'VOICE',
            amazonconnect__ContactId__c = '000aaa0a-0a00-0a0a-00aa-00a000000a00'
        );
        insert testAmazonConnect;
        List<amazonconnect__AC_ContactTraceRecord__c> acContactTraceList = new List<amazonconnect__AC_ContactTraceRecord__c>();
        acContactTraceList.add(testAmazonConnect);

        Test.startTest();
        CDdCaseTriggerOptimizationHelper.addToAcContactTraceTransferMap(acContactTraceList);
        CDdCaseTriggerOptimizationHelper.setAcContactTraceTransferMap(caseIdSet);
        CDdCaseTriggerOptimizationHelper.refreshAcContactTraceTransferMap();
        Map<Id, Set<String>> AcConTraceTransferMap = CDdCaseTriggerOptimizationHelper.getAcContactTraceTransferMap();
        Set<String> getAcContactTraceTransfers = CDdCaseTriggerOptimizationHelper.getAcContactTraceTransfers(testCaseList[0].Id);
        Test.stopTest();

       system.assertEquals(caseIdSet.size(), AcConTraceTransferMap.size(),'Map size is same as list');
       system.assertEquals( 1,getAcContactTraceTransfers.size(), 'size should be one');
    }
    @isTest
    static void testCasetoIncreaseCodeCoverage(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Case_Validations__c = true;
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;

        Account acc = [select Id from Account where Name = 'Test Acc' limit 1];
        Contact con = [select Id from Contact where AccountId =: acc.Id limit 1];
        con.Email = 'TEST@email.com';
        Update con;
        List<Contact> contactsToChecklst = new List<Contact>();
        contactsToChecklst.add(con);
        User u = [  select Id from User where isActive = true and Profile.Name =: 'System Administrator' and Id !=: UserInfo.getUserId()][0];
        Case testCase = [select Id from case where RecordTypeId =:CASE_Support_RECORDTYPEID limit 1];
        testCase.Requester__c = u.id;
        testCase.Activations_Lead__c = UserInfo.getUserId();
        update testCase;
        Set<id> caseIds = new Set<id>();
        caseIds.add(testCase.id);
        List<Case> caseLst = new List<Case>();
        caseLst.add(testCase);

        Test.startTest();
        //Case Optimization
        CDdCaseTriggerOptimizationHelper.setCaseMap(caseIds);
        CDdCaseTriggerOptimizationHelper.addToCaseMap(caseLst);
        CDdCaseTriggerOptimizationHelper.refreshCaseMap();
        Map<Id, Case>  caseMap= CDdCaseTriggerOptimizationHelper.getCaseMap();
        //Account Optimization
        CDdCaseTriggerOptimizationHelper.refreshAccountMap();
        //Contact Optimization
        CDdCaseTriggerOptimizationHelper.setContactMap(caseIds);
        CDdCaseTriggerOptimizationHelper.refreshContactMap();
        Contact c = CDdCaseTriggerOptimizationHelper.getLastContactByDate(contactsToChecklst,'CreatedDate');
        //User Optimization
        CDdCaseTriggerOptimizationHelper.refreshUserMap();
        Test.stopTest();
        system.assertEquals(caseLst.size(), caseMap.size(),'list and map size should be same');
        system.assertEquals(con.id, c.id, 'Same contact has returned');
    }

    /**
     * @author      Sanidhya jain
     * @date        June 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-46039
     */
    @isTest
    static void testcheckValidEscalatedTrustSaftyCaseWithError() {
        Boolean isError = false;

        //Create Trust & Safety Queue
        Group testGroup = new Group(Name='P0 - Trust & Safety', Type='Queue');
        insert testGroup;
        //Assigning Trust & Safety Queue to Case Object
        QueuesObject q1 = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
        insert q1;

        System.runAs(getTestRunUser()){
            //create Case record
            Case testCase = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
            testCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
            testCase.OwnerId = testGroup.id;
            testCase.Issue_Type__c = CDdSupportConstants.ISUETYPE_OTHER_CX;
            testCase.Issue__c = CDdSupportConstants.ISSUE_UNRESOLVED_CONTACT;
            testCase.Resolution__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER;
            testCase.Resolution_Type__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER_CX;
            insert testCase;
            //create Case Detail record
            Case_Detail__c cDetail = new Case_Detail__c();
            cDetail.Case_Origin__c = testCase.Origin;
            cDetail.Case_Customer_Type__c = testCase.Customer_Type__c;
            CDetail.Case_RecordType__c = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeDevNameById(testCase.RecordTypeId);
            CDetail.Case_Owner_ID__c = testGroup.id;
            insert cDetail;

            Test.startTest();
            try{
                testCase.Case_Detail__c = cDetail.id;
                testCase.Status = CDdSupportConstants.SOLVED_STATUS;
                update testCase;
            }
            catch(Exception ex){
                isError = true;
                System.assert(isError,'An exception should be thrown');
            }
            Test.stopTest();
        }
    }

    /**
     * @author      Sanidhya jain
     * @date        June 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-46039
     */
    @isTest
    static void testcheckValidEscalatedTrustSaftyCaseWithoutError() {
        //Case Detail Map
        Map<String, Case_Detail__c> caseDetailMap = new Map<String, Case_Detail__c>();
        //Case Detail Map by Case Id
        Case_Detail__c caseDetailCaseRecord = new Case_Detail__c();

        //Create Trust & Safety Queue
        Group testGroup = new Group(Name='P0 - Trust & Safety', Type='Queue');
        insert testGroup;
        //Assigning Trust & Safety Queue to Case Object
        QueuesObject q1 = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
        insert q1;

        System.runAs(getTestRunUser()){
            //create Case record
            Case testCase = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
            testCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
            testCase.OwnerId = testGroup.id;
            testCase.Issue_Type__c = CDdSupportConstants.ISUETYPE_OTHER_CX;
            testCase.Issue__c = CDdSupportConstants.ISSUE_UNRESOLVED_CONTACT;
            testCase.Resolution__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER;
            testCase.Resolution_Type__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER_CX;
            insert testCase;
            //create Case Detail record
            Case_Detail__c cDetail1 = new Case_Detail__c();
            cDetail1.Case_Origin__c = testCase.Origin;
            cDetail1.Case_Customer_Type__c = testCase.Customer_Type__c;
            cDetail1.Case_RecordType__c = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeDevNameById(testCase.RecordTypeId);
            cDetail1.Case_Owner_ID__c = testGroup.id;
            cDetail1.Primary_Incident_Type__c = CDdSupportConstants.PRIMARY_INCIDENT_TYPE;
            cDetail1.Secondary_Incident_Type__c = CDdSupportConstants.SECONDARY_INCIDENT_TYPE;
            cDetail1.Reporter__c = CDdSupportConstants.REPORTER;
            cDetail1.Incident_History__c = CDdSupportConstants.INCIDENT_HISTORY;
            cDetail1.Actions_Taken__c = CDdSupportConstants.ACTIONS_TAKEN;
            cDetail1.Account_Sharing_Not_My_Dasher__c = CDdSupportConstants.ACCOUNT_SHARING_NOT_MY_DASHER;
            cDetail1.Case__c = testCase.id;
			insert cDetail1;

            Test.startTest();
            try{
                testCase.Case_Detail__c = cDetail1.id;
                testCase.Status = CDdSupportConstants.SOLVED_STATUS;
                update testCase;
                Set<Id> caseDetailId = new Set<Id>{
                    cDetail1.id
                };
                CDdCaseTriggerOptimizationHelper.setCaseDetailMap(caseDetailId);
                caseDetailMap = CDdCaseTriggerOptimizationHelper.getcaseDetailCaseMap();
                caseDetailCaseRecord = CDdCaseTriggerOptimizationHelper.getcaseDetailCaseMapById(testCase.id);
                CDdCaseTriggerOptimizationHelper.refreshcaseDetailMap();
            }
            catch(Exception ex){
            }
            Test.stopTest();
            System.assert(caseDetailMap.size()>0, 'Case Detail Map size should be greater then 0');
            System.assertEquals(caseDetailCaseRecord.id, cDetail1.id , 'Case Detail Id should match with case deatil record inserted');
            List<Case> caseList = new List<Case>([Select id,status from Case where id = :testCase.id]);
            System.assertEquals(caseList[0].status,CDdSupportConstants.SOLVED_STATUS,'Case should be moved to solved successfully');
        }
    }
}