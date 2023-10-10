/**
 * Created by Jeremy S. Johnson, Perficient, Inc. on 1/29/2020.
 *
 * Test class for the Mulesfoft Bulk Uploader tool.
 */

@isTest
private class CDdUploaderTest {
    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    private final static String RECORD_TYPE_NAME_ACCOUNT_PARENT = 'Parent Account';
    private final static String RECORD_TYPE_NAME_ACCOUNT_ENTERPRISE_MARKETPLACE = 'Enterprise Marketplace';
    private final static RecordType RECORD_TYPE_OPPORTUNITY_ENT_MARKETPLACE;
    private static final String TEST_DD_ACCOUNT_PARENT_0 = 'TestDDAccountParent0';
    private static final String TEST_DD_ACCOUNT_PARENT_1 = 'TestDDAccountParent1';  
    private static final String TEST_DD_ACCOUNT_ENT_MARKETPLACE_0 = 'TestDDAccountEntMarketplace0';
    private static final String TEST_DD_ACCOUNT_ENT_MARKETPLACE_1 = 'TestDDAccountEntMarketplace1';
    private static final Integer TEST_BUSINESS_ID = 503478;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;        
        for (RecordType rt: [SELECT Id, Name, DeveloperName 
                            FROM RecordType
                            WHERE SObjectType = 'Opportunity']){
            if (rt.Name.equals('Enterprise Marketplace')){
                rt = RECORD_TYPE_OPPORTUNITY_ENT_MARKETPLACE; 
            }
        }
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
   /** 
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            CDdContactTriggerHelper.insertCampaign();
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;
            Test.stopTest();
        }
    }       

    @isTest
    static void testRemoveDuplicateAccounts() {
        List<SObject> objects = new List<SObject>();
        objects.add(new Account(Id = Id.valueOf('0012L0000300000'), Name = '3'));
        objects.add(new Account(Id = Id.valueOf('0012L0000200000'), Name = '2'));
        objects.add(new Account(Id = Id.valueOf('0012L0000300000'), Name = '3'));
        objects.add(new Account(Id = Id.valueOf('0012L0000100000'), Name = '1'));
        objects.add(new Account(Id = Id.valueOf('0012L0000300000'), Name = '3'));

        CDdUploaderHelper helper = new CDdUploaderHelper();
        List<SObject> results = helper.dedupeObjects(objects);

        System.assertEquals(3, results.size(), 'Unexpected number of objects.');
        for (Integer i = 0; i < 3; i++) {
            Account acct = (Account) results[i];
            System.assertEquals(String.valueOf(i + 1), acct.Name, 'Unexpected sort order.');
        }
    }

    @isTest
    static void testFieldLevelSecurity() {
        final String objectFieldName = 'Account.Business_ID__c';
        final String profileName = 'Agent';

        String userName = 'CDdUploaderTest' + DateTime.now().getTime() + '@doordash.com';
        Profile profile = [select Id from Profile where Name = :profileName];
        User user = new User(Alias = 'standt', Email = 'CDdUploaderTest@doordash.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = userName);

        String csv = 'Account.Id,Opportunity.Id,' + objectFieldName + '\n'
                + '0012L0000300000,0060r0000031HPxAAM,1234';

        System.runAs(user) {
            CDdUploaderContext ctx = CDdUploaderController.uploadCsv(csv, user.Id, 'Full Onboarding Update', 'test.csv');
            System.assertEquals(1, ctx.csv.csvErrors.size(), 'Unexpected number of errors.');
            System.assertEquals('Unable to import field (field level security): ' + objectFieldName, ctx.csv.csvErrors[0], 'Unexpected error message.');
        }
    }

    @isTest
    static void testRowError() {
        String csv = 'Account.Id\nwhatever';
        CDdUploaderContext ctx = CDdUploaderController.uploadCsv(csv, UserInfo.getUserId(), 'Full Onboarding Create', 'test.csv');
        System.assertEquals(1, ctx.csv.rowErrors.keySet().size(), 'Unexpected number of row errors.');
    }

    @isTest
    static void testDataTypeConversions() {
        Map<String, List<Object>> bindings = new Map<String, List<Object>>{
                'Account_Status__c'     => new List<Object> { 'Active', DisplayType.PICKLIST },
                'Activated_At__c'       => new List<Object> { '2020-01-01 12:00:00', DisplayType.DATETIME },
                'Activation_Date__c'    => new List<Object> { '2020-01-01', DisplayType.DATE },
                'Amount__c'             => new List<Object> { '1.00', DisplayType.CURRENCY },
                'BillingCity'           => new List<Object> { 'Null', DisplayType.STRING },     //Explicit null
                'BillingLatitude'       => new List<Object> { '1.1234', DisplayType.DOUBLE },
                'BillingState'          => new List<Object> { '""', DisplayType.STRING },       //Implicit null
                'BillingStreet'         => new List<Object> { '1 N 1st', DisplayType.TEXTAREA },
                'Competitors__c'        => new List<Object> { 'Amazon,Caviar', DisplayType.MULTIPICKLIST },
                'Id'                    => new List<Object> { '0012L0000300000', DisplayType.ID },
                'Is_Test_Store__c'      => new List<Object> { '1', DisplayType.BOOLEAN },
                'NumberOfEmployees'     => new List<Object> { '100', DisplayType.INTEGER },
                'ParentId'              => new List<Object> { '0012L0000100000', DisplayType.REFERENCE },
                'PersonEmail'           => new List<Object> { 'test@doordash.com', DisplayType.EMAIL },
                'Phone'                 => new List<Object> { '(602) 555-1212', DisplayType.PHONE },
                'Tax_Override_Rate__c'  => new List<Object> { '0.25', DisplayType.PERCENT },
                'Website'               => new List<Object> { 'www.doordash.com', DisplayType.URL }
        };

        CDdUploaderHelper helper = new CDdUploaderHelper();

        SObject account = (SObject) new Account();
        for (String field : bindings.keySet()) {
            String value = (String) bindings.get(field)[0];
            DisplayType type = (DisplayType) bindings.get(field)[1];

            CDdUploaderCSV.ColumnMeta meta = new CDdUploaderCSV.ColumnMeta('Account', field, type, new List<String> {'Active', 'Amazon,Caviar'});
            CDdUploaderCSV.Cell cell = new CDdUploaderCSV.Cell(meta, value);

            helper.bindValue(cell, account);

            if (''.equals(cell.value) || 'null'.equals(cell.value.toLowerCase())) {
                System.assertEquals(null, account.get(field), 'Unexpected type conversion for field: ' + field);
            } else {
                System.assertNotEquals(null, account.get(field), 'Unexpected type conversion for field: ' + field);
            }
        }
    }

    @isTest
    static void testDataTypeConversionEdgeCases() {
        CDdUploaderHelper helper = new CDdUploaderHelper();
        CDdUploaderCSV.ColumnMeta meta;
        CDdUploaderCSV.Cell cell;

        //DisplayType.ADDRESS is an unsupported complex type.
        meta = new CDdUploaderCSV.ColumnMeta('Account', 'BillingAddress', DisplayType.ADDRESS, null);
        cell = new CDdUploaderCSV.Cell(meta, 'whatever');
        try {
            helper.bindValue(cell, new Account());
            System.assert(false, 'Type conversion should throw exception, DisplayType.ADDRESS');
        } catch (Exception e) {
        }

        //By default, Boolean.valueOf() silently returns false for anything that is not 0 or 1. We want to throw an exception instead.
        meta = new CDdUploaderCSV.ColumnMeta('Account', 'Is_Test_Store__c', DisplayType.BOOLEAN, null);
        cell = new CDdUploaderCSV.Cell(meta, 'whatever');
        try {
            helper.bindValue(cell, new Account());
            System.assert(false, 'Type conversion should throw exception, DisplayType.BOOLEAN');
        } catch (Exception e) {
        }

        //Very few objects have a Time field. Test the happy path here.
        meta = new CDdUploaderCSV.ColumnMeta('Case', 'Auto_Cart_Checkout_Time__c', DisplayType.TIME, null);
        cell = new CDdUploaderCSV.Cell(meta, '12:00:00');
        Case c = new Case();
        try {
            helper.bindValue(cell, c);
            System.assertNotEquals(null, c.Auto_Cart_Checkout_Time__c, 'Unexpected null for DisplayType.TIME');
        } catch (Exception e) {
            System.assert(false, 'Type conversion should succeed for DisplayType.TIME');
        }

        //Also test malformed Time field.
        meta = new CDdUploaderCSV.ColumnMeta('Case', 'Auto_Cart_Checkout_Time__c', DisplayType.TIME, null);
        cell = new CDdUploaderCSV.Cell(meta, '12:00');
        try {
            helper.bindValue(cell, new Case());
            System.assert(false, 'Type conversion should throw exception, DisplayType.TIME');
        } catch (Exception e) {
        }

        meta = new CDdUploaderCSV.ColumnMeta('Account', 'Account_Status__c', DisplayType.PICKLIST, new List<String> {'Whatever'});
        cell = new CDdUploaderCSV.Cell(meta, 'whatever');
        try {
            helper.bindValue(cell, new Account());
            System.assert(false, 'Type conversion should throw exception, DisplayType.ADDRESS');
        } catch (Exception e) {
        }
    }

    @isTest
    static void testCDdS2NUtil() {
        System.assertEquals(MSSyncStage.CreateMerchant, CDdS2NUtil.msSyncStageFromString('Create Merchant'));
        System.assertEquals(MSSyncStage.CreateStore, CDdS2NUtil.msSyncStageFromString('Create Store'));
        System.assertEquals(MSSyncStage.CreateUser, CDdS2NUtil.msSyncStageFromString('Create User'));
        System.assertEquals(MSSyncStage.FullOnboardingCreate, CDdS2NUtil.msSyncStageFromString('Full Onboarding Create'));
        System.assertEquals(MSSyncStage.FullOnboardingUpdate, CDdS2NUtil.msSyncStageFromString('Full Onboarding Update'));
        System.assertEquals(MSSyncStage.PaymentAccount, CDdS2NUtil.msSyncStageFromString('Payment Account'));
        System.assertEquals(MSSyncStage.StripeBankAccount, CDdS2NUtil.msSyncStageFromString('Stripe Bank Account'));
        System.assertEquals(MSSyncStage.StripeBankToken, CDdS2NUtil.msSyncStageFromString('Stripe Bank Token'));
        System.assertEquals(MSSyncStage.UpdateStore, CDdS2NUtil.msSyncStageFromString('Update Store'));

        System.assertEquals('Create Merchant', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.CreateMerchant));
        System.assertEquals('Create Store', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.CreateStore));
        System.assertEquals('Create User', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.CreateUser));
        System.assertEquals('Full Onboarding Create', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.FullOnboardingCreate));
        System.assertEquals('Full Onboarding Update', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.FullOnboardingUpdate));
        System.assertEquals('Payment Account', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.PaymentAccount));
        System.assertEquals('Stripe Bank Account', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.StripeBankAccount));
        System.assertEquals('Stripe Bank Token', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.StripeBankToken));
        System.assertEquals('Update Store', CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.UpdateStore));
    }

    @isTest
    static void testBatchableForFullOnboardingUpdate() {
        System.runAs(getTestRunUser()){
            createTestData();
            String csv = 'Account.Id,Account.Confirm_Protocol__c,Opportunity.Id,Opportunity.Order_Protocol_Fax__c\n';
            List<Opportunity> opps = [select AccountId, Account.Confirm_Protocol__c, Id, Order_Protocol_Fax__c from Opportunity];
            Set<Id> accountIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();
            for(Opportunity opp : opps) {
                accountIds.add(opp.AccountId);
                opportunityIds.add(opp.Id);
                csv += opp.AccountId + ',Pass,' + opp.Id + ',0987654321\n';
            }
            List<Account> accounts = [select Id from Account where Id IN :accountIds];

            String msSyncStage = CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.FullOnboardingUpdate);
            CDdUploaderContext ctxMin = CDdUploaderController.uploadCsv(csv, UserInfo.getUserId(), msSyncStage, 'test.csv');
            System.assertEquals(0, ctxMin.csv.csvErrors.size());
            System.assertEquals(0, ctxMin.csv.rowErrors.size());

            CDdUploaderHelper helper = new CDdUploaderHelper();
            ctxMin.isCompositeUpdate = true;
            Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
            allObjects.put('Account', accounts);
            allObjects.put('Opportunity', opps);
            ctxMin.updateListByType = helper.groupObjectsByType(null, allObjects);
            ctxMin.updateListByGroup = helper.groupObjectsByParent(allObjects, ctxMin.isCompositeUpdate);            

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, createMock(true));
            Id batchId = CDdUploaderController.importCsv(UserInfo.getUserId(), 20);
            AsyncApexJob job = CDdUploaderController.getProgress(batchId);
            List<String> messages = CDdUploaderController.getImportMessages(UserInfo.getUserId());
            Test.stopTest();

            System.assertNotEquals(null, batchId, 'Unexpected value for batchId.');
            System.assertNotEquals(null, job, 'Unexpected value for job.');
            System.assertEquals(0, messages.size(), 'Unexpected value for messages.size().');

            List<Account> actualAccts = [select Id, Confirm_Protocol__c, Bulk_Tool_Batch_Id__c, Bulk_Tool_Last_Modified__c, Bulk_Tool_User__c from Account WHERE Id IN :accountIds];
            for(Account acct : actualAccts) {
                System.debug('CDdUploaderTest.testBatchable, account: ' + acct);
                System.assertEquals('Pass', acct.Confirm_Protocol__c, 'Unexpected value for Confirm_Protocol__c.');
                System.assertNotEquals(null, acct.Bulk_Tool_User__c, 'Unexpected value for Bulk_Tool_User__c.');
                System.assertNotEquals(null, acct.Bulk_Tool_Last_Modified__c, 'Unexpected value for Bulk_Tool_Last_Modified__c.');
                System.assertNotEquals(null, acct.Bulk_Tool_Batch_Id__c, 'Unexpected value for Bulk_Tool_Batch_Id__c.');
            }

            List<Opportunity> actualOpps = [select Id, Order_Protocol_Fax__c, Bulk_Tool_Batch_Id__c, Bulk_Tool_Last_Modified__c, Bulk_Tool_User__c from Opportunity WHERE Id IN :opportunityIds];
            for(Opportunity opp : actualOpps) {
                System.debug('CDdUploaderTest.testBatchable, opp: ' + opp);
                System.assertEquals('0987654321', opp.Order_Protocol_Fax__c, 'Unexpected value for Order_Protocol_Fax__c.');
                System.assertNotEquals(null, opp.Bulk_Tool_User__c, 'Unexpected value for Bulk_Tool_User__c.');
                System.assertNotEquals(null, opp.Bulk_Tool_Last_Modified__c, 'Unexpected value for Bulk_Tool_Last_Modified__c.');
                System.assertNotEquals(null, opp.Bulk_Tool_Batch_Id__c, 'Unexpected value for Bulk_Tool_Batch_Id__c.');
            }
        }
    }

    @isTest
    static void testBatchableForFullOnboardingCreate() {
        System.runAs(getTestRunUser()){
            createTestData();
            
            String csv = 'Account.Id,Opportunity.Id\n';
            List<Opportunity> opps = [select AccountId, Id from Opportunity];
            Set<Id> accountIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();
            for(Opportunity opp : opps) {
                accountIds.add(opp.AccountId);
                opportunityIds.add(opp.Id);
                csv += opp.AccountId + ',' + opp.Id + '\n';
            }
            System.assertEquals(4, opps.size(), 'Expecting test opportunity size of ' + 4);
            List<Account> accounts = [select Id from Account where Id IN :accountIds];

            String msSyncStage = CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.FullOnboardingCreate);
            CDdUploaderContext ctxMin = CDdUploaderController.uploadCsv(csv, UserInfo.getUserId(), msSyncStage, 'test.csv');
            System.assertEquals(0, ctxMin.csv.csvErrors.size());
            System.assertEquals(0, ctxMin.csv.rowErrors.size());

            CDdUploaderHelper helper = new CDdUploaderHelper();
            ctxMin.isCompositeUpdate = true;
            Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
            allObjects.put('Account', accounts);
            allObjects.put('Opportunity', opps);
            ctxMin.updateListByType = helper.groupObjectsByType(null, allObjects);
            ctxMin.updateListByGroup = helper.groupObjectsByParent(allObjects, ctxMin.isCompositeUpdate);

            System.assertEquals(4, ctxMin.updateListByGroup.size(), 'Expecting 4 groups of account');
            List<Account> parentAccounts = new CDdUploaderHelper().getParentAccounts(ctxMin.updateListByGroup.keySet(), CDdUploaderConstants.BULK_UPLOADER_CREATE_BIZ_MIN_CHILDCOUNT);
            System.assertEquals(2, parentAccounts.size(), 'Expecting 2 parent accounts');            
        
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, createMock(true));
            Id batchId = CDdUploaderController.importCsv(UserInfo.getUserId(), 20);
            AsyncApexJob job = CDdUploaderController.getProgress(batchId);
            List<String> messages = CDdUploaderController.getImportMessages(UserInfo.getUserId());
            List<AsyncApexJob> myJobs = CDdMyApexJobsController.getMyApexJobs(UserInfo.getUserId(), 'CDdUploaderBatch');
            System.assert(!myJobs.isEmpty(), 'Expecting a job entry with apex class name - CDdUploaderBatch');
            Test.stopTest();

            System.assertNotEquals(null, batchId, 'Unexpected value for batchId.');
            System.assertNotEquals(null, job, 'Unexpected value for job.');
            System.assertEquals(0, messages.size(), 'Unexpected value for messages.size().');

            List<Account> actualAccts = [select Id, Confirm_Protocol__c, Bulk_Tool_Batch_Id__c, Bulk_Tool_Last_Modified__c, Bulk_Tool_User__c from Account WHERE Id IN :accountIds];
            for(Account acct : actualAccts) {
                System.debug('CDdUploaderTest.testBatchable, account: ' + acct);
                System.assertNotEquals(null, acct.Bulk_Tool_User__c, 'Unexpected value for Bulk_Tool_User__c.');
                System.assertNotEquals(null, acct.Bulk_Tool_Last_Modified__c, 'Unexpected value for Bulk_Tool_Last_Modified__c.');
                System.assertNotEquals(null, acct.Bulk_Tool_Batch_Id__c, 'Unexpected value for Bulk_Tool_Batch_Id__c.');
            }

            List<Opportunity> actualOpps = [select Id, Order_Protocol_Fax__c, Bulk_Tool_Batch_Id__c, Bulk_Tool_Last_Modified__c, Bulk_Tool_User__c from Opportunity WHERE Id IN :opportunityIds];
            for(Opportunity opp : actualOpps) {
                System.debug('CDdUploaderTest.testBatchable, opp: ' + opp);
                System.assertNotEquals(null, opp.Bulk_Tool_User__c, 'Unexpected value for Bulk_Tool_User__c.');
                System.assertNotEquals(null, opp.Bulk_Tool_Last_Modified__c, 'Unexpected value for Bulk_Tool_Last_Modified__c.');
                System.assertNotEquals(null, opp.Bulk_Tool_Batch_Id__c, 'Unexpected value for Bulk_Tool_Batch_Id__c.');
            }
        }
    }    

    @IsTest
    public static void testBatchableErrors() {
        CDdUploaderContext ctx = new CDdUploaderContext();
        CDdUploaderHelper helper = new CDdUploaderHelper();
        Integer badAcctIndex = 2; Integer badOppIndex = 0;

        List<Account> accounts = new List<Account> {
                new Account(Name = 'Good1', Status__c = 'Active'),
                new Account(Name = 'Good2', Status__c = 'Active'),
                new Account(Name = 'Bad', Status__c = 'Active')
        };
        insert accounts;

        List<Opportunity> opps = new List<Opportunity>();
        Integer j= 1;
        for (Account account : accounts) {
            opps.add(new Opportunity(AccountId = account.Id, Name = 'Good' + j++, StageName = 'New', CloseDate = Date.today(), 
                    Menu_to_be_completed_by__c = null, Menu_Setup_Method__c =  null, Tablet_Kit_Type__c = null));
            opps.add(new Opportunity(AccountId = account.Id, Name = 'Good' + j++, StageName = 'New', CloseDate = Date.today(), 
                    Menu_to_be_completed_by__c = null, Menu_Setup_Method__c =  null, Tablet_Kit_Type__c = null));
        } 
        opps[badOppIndex].Name = 'Bad';
        insert opps;

        ctx.isCompositeUpdate = true;
        Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
        allObjects.put('Account', accounts);
        allObjects.put('Opportunity', opps);
        ctx.updateListByType = helper.groupObjectsByType(null, allObjects);
        ctx.updateListByGroup = helper.groupObjectsByParent(allObjects, ctx.isCompositeUpdate);

        // updateListByGroup should be a Map of Maps consisting of 3 Accounts in the outer Map and
        // an 1 Account + 2 Opportunities in each inner Map
        System.assertEquals(3, ctx.updateListByGroup.keySet().size(), 'Unexpected number of groupings.');
        System.assertEquals(3, ctx.updateListByGroup.values()[0].size(), 'Unexpected number of children in group 0.');
        System.assertEquals(3, ctx.updateListByGroup.values()[1].size(), 'Unexpected number of children in group 1.');
        System.assertEquals(3, ctx.updateListByGroup.values()[2].size(), 'Unexpected number of children in group 2.');

        Test.startTest();
        CDdUploaderBatch batch = new CDdUploaderBatch(ctx);
        batch.removeObjectForEvents(accounts[badAcctIndex], false); //parent
        batch.removeChildObjects(ctx, opps);
        batch.removeObjectForEvents(opps[badOppIndex], true); //child
        batch.removeChildObjects(ctx, opps);
        batch.finish();
        Test.stopTest();

        ctx = (CDdUploaderContext) Cache.Org.get(ctx.partitionKey());

        // After batch, the 3rd Account in the outer Map should be removed (parent failure)
        System.assertEquals(2, ctx.updateListByGroup.keySet().size(), 'Unexpected number of groupings.');
        System.assertEquals(false, ctx.updateListByGroup.keySet().contains(accounts[badAcctIndex].Id), 'Unexpected account in groupings.');

        // After batch, the 1st Opportunity in the 1st outer Map should be removed (child failure)
        System.assertEquals(2, ctx.updateListByGroup.values()[0].size(), 'Unexpected number of children in group 0.');
        System.assertEquals(false, ctx.updateListByGroup.values()[1].containsKey(opps[badOppIndex].Id), 'Unexpected opp in group 1.');
        System.assertEquals(3, ctx.updateListByGroup.values()[1].size(), 'Unexpected number of children in group 1.');
    }

    @isTest
    static void testCreateBusinessSuccess() {
        CDdUploaderHelper helper = new CDdUploaderHelper();
        System.runAs(getTestRunUser()){
            createTestData();
            String csv = 'Account.Id,Opportunity.Id\n';
            List<Opportunity> opps = [select AccountId, Id from Opportunity];
            Set<Id> accountIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();
            for(Opportunity opp : opps) {
                accountIds.add(opp.AccountId);
                opportunityIds.add(opp.Id);
                csv += opp.AccountId + ',' + opp.Id + '\n';
            }
            System.assertEquals(4, opps.size(), 'Expecting test opportunity size of ' + 4);
            List<Account> accounts = [select Id from Account where Id IN :accountIds];

            String msSyncStage = CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.FullOnboardingCreate);
            CDdUploaderContext ctxMin = CDdUploaderController.uploadCsv(csv, UserInfo.getUserId(), msSyncStage, 'test.csv');
            System.assertEquals(0, ctxMin.csv.csvErrors.size());
            System.assertEquals(0, ctxMin.csv.rowErrors.size());

            ctxMin.isCompositeUpdate = true;
            Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
            allObjects.put('Account', accounts);
            allObjects.put('Opportunity', opps);
            ctxMin.updateListByType = helper.groupObjectsByType(null, allObjects);
            ctxMin.updateListByGroup = helper.groupObjectsByParent(allObjects, ctxMin.isCompositeUpdate);

            System.assertEquals(4, ctxMin.updateListByGroup.size(), 'Expecting 4 groups of account');
            List<Account> parentAccounts = helper.getParentAccounts(ctxMin.updateListByGroup.keySet(), CDdUploaderConstants.BULK_UPLOADER_CREATE_BIZ_MIN_CHILDCOUNT);
            System.assertEquals(2, parentAccounts.size(), 'Expecting 2 parent accounts');            
        
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, createMock(true));
            helper.createBusiness('testRef12345', parentAccounts);
            Test.stopTest();

            List<Account> parentAccountsFromDB = [SELECT Id, Business_Id__c FROM Account WHERE Id IN :parentAccounts];
            System.assertEquals(2, parentAccountsFromDB.size(), 'Expecting 2 parent accounts');
            System.assertEquals(TEST_BUSINESS_ID, parentAccountsFromDB[0].Business_Id__c, 'Expecting parent account business Id : ' + TEST_BUSINESS_ID);
            System.assertEquals(TEST_BUSINESS_ID, parentAccountsFromDB[1].Business_Id__c, 'Expecting parent account business Id : ' + TEST_BUSINESS_ID);                                          
        }
    }

    @isTest
    static void testCreateBusinessFail() {
        CDdUploaderHelper helper = new CDdUploaderHelper();
        System.runAs(getTestRunUser()){
            createTestData();
            String csv = 'Account.Id,Opportunity.Id\n';
            List<Opportunity> opps = [select AccountId, Id from Opportunity];
            Set<Id> accountIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();
            for(Opportunity opp : opps) {
                accountIds.add(opp.AccountId);
                opportunityIds.add(opp.Id);
                csv += opp.AccountId + ',' + opp.Id + '\n';
            }
            System.assertEquals(4, opps.size(), 'Expecting test opportunity size of ' + 4);
            List<Account> accounts = [select Id from Account where Id IN :accountIds];

            String msSyncStage = CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.FullOnboardingCreate);
            CDdUploaderContext ctxMin = CDdUploaderController.uploadCsv(csv, UserInfo.getUserId(), msSyncStage, 'test.csv');
            System.assertEquals(0, ctxMin.csv.csvErrors.size());
            System.assertEquals(0, ctxMin.csv.rowErrors.size());

            ctxMin.isCompositeUpdate = true;
            Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
            allObjects.put('Account', accounts);
            allObjects.put('Opportunity', opps);
            ctxMin.updateListByType = helper.groupObjectsByType(null, allObjects);
            ctxMin.updateListByGroup = helper.groupObjectsByParent(allObjects, ctxMin.isCompositeUpdate);
                        
            System.assertEquals(4, ctxMin.updateListByGroup.size(), 'Expecting 4 groups of account');
            List<Account> parentAccounts = helper.getParentAccounts(ctxMin.updateListByGroup.keySet(), CDdUploaderConstants.BULK_UPLOADER_CREATE_BIZ_MIN_CHILDCOUNT);
            System.assertEquals(2, parentAccounts.size(), 'Expecting 2 parent accounts');            
        
            Test.startTest();
            Boolean encounteredException = false;
            Test.setMock(HttpCalloutMock.class, createMock(false));
            try {
                helper.createBusiness('testRef12345', parentAccounts);
            } catch (CDdNimdaSyncMSService.CDdNimdaSyncMSServiceException e){
                encounteredException = true;
            }
            Test.stopTest();

            System.assert(encounteredException, 'Expecting Create Business API Service Exception');
            List<Account> parentAccountsFromDB = [SELECT Id, Business_Id__c FROM Account WHERE Id IN :parentAccounts];
            System.assertEquals(2, parentAccountsFromDB.size(), 'Expecting 2 parent accounts');
            System.assertEquals(null, parentAccountsFromDB[0].Business_Id__c, 'Expecting parent account business Id : ' + 'null');
            System.assertEquals(null, parentAccountsFromDB[1].Business_Id__c, 'Expecting parent account business Id : ' + 'null');                                          
        }
    }

    @isTest
    static void testHelpText() {
        System.runAs(getTestRunUser()){
            System.assert(String.isNotBlank(CDdUploaderController.helpText()));
        }
    }
    
    @isTest
    static void testOpportunityNotClosedWon() {
        System.runAs(getTestRunUser()){
            createTestData();
            Id testAccountId = [SELECT Id FROM Account LIMIT 1].Id;
            Id testContactId = [SELECT Id FROM Contact LIMIT 1].Id;
            Opportunity testOpportunity = TDdOpportunityFactory.createOpportunity(
                                        'testOpportunity', testAccountId, testContactId, 'Ready for Signature'
                                    );
            insert testOpportunity;
            Test.startTest();                                    
            String csv = 'Account.Id,Opportunity.Id\n';
            csv += testAccountId + ',' + testOpportunity.Id + '\n';
            String rowKey = String.valueOf(testAccountId)+String.valueOf(testOpportunity.Id);
            String rowErrorFieldName = 'Opportunity.Id';
            String rowErrorMessage = CDdUploaderConstants.ERROR_MESSAGE_OPPORTUNITY_STAGE_NOT_CLOSED_WON;
            CDdUploaderContext ctx = CDdUploaderController.uploadCsv(csv, UserInfo.getUserId(), 'Full Onboarding Update', 'test.csv');
            System.assertEquals(1, ctx.csv.rowErrors.size(), 'Unexpected number of errors.');
            System.assertEquals(true, ctx.csv.rowErrors.get(rowKey)!=null, 'Expecting row key ' + new List<String>(ctx.csv.rowErrors.keySet()).get(0));
            System.assertEquals(rowErrorFieldName, ctx.csv.rowErrors.get(rowKey).fieldNames[0]);
            System.assertEquals(true, ctx.csv.rowErrors.get(rowKey).messages[0].contains(rowErrorMessage));
            Test.stopTest();
        }
    }

    @isTest
    static void testBatchableForProductAndPricing() {
        System.runAs(getTestRunUser()){
            createTestData();
            String csv = 'Account.Id,Opportunity.Id\n';
            List<Opportunity> opps = [SELECT Id, AccountId FROM Opportunity];
            Set<Id> accountIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();
            for(Opportunity opp : opps) {
                accountIds.add(opp.AccountId);
                opportunityIds.add(opp.Id);
                csv += opp.AccountId + ',' + opp.Id + '\n';
            }
            List<Account> accounts = [select Id from Account where Id IN :accountIds];

            String msSyncStage = CDdS2NUtil.msSyncStageFromEnum(MSSyncStage.ProductAndPricingOnboarding);
            CDdUploaderContext ctxMin = CDdUploaderController.uploadCsv(csv, UserInfo.getUserId(), msSyncStage, 'test.csv');
            System.assertEquals(0, ctxMin.csv.csvErrors.size());
            System.assertEquals(0, ctxMin.csv.rowErrors.size());

            CDdUploaderHelper helper = new CDdUploaderHelper();
            ctxMin.isCompositeUpdate = true;
            Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
            allObjects.put('Account', accounts);
            allObjects.put('Opportunity', opps);
            ctxMin.updateListByType = helper.groupObjectsByType(null, allObjects);
            ctxMin.updateListByGroup = helper.groupObjectsByParent(allObjects, ctxMin.isCompositeUpdate);            

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, createMock(true));
            Id batchId = CDdUploaderController.importCsv(UserInfo.getUserId(), 20);
            AsyncApexJob job = CDdUploaderController.getProgress(batchId);
            List<String> messages = CDdUploaderController.getImportMessages(UserInfo.getUserId());
            Test.stopTest();

            System.assertNotEquals(null, batchId, 'Unexpected value for batchId.');
            System.assertNotEquals(null, job, 'Unexpected value for job.');
            System.assertEquals(0, messages.size(), 'Unexpected value for messages.size().');

            List<Account> actualAccts = [select Id, Bulk_Tool_Batch_Id__c, Bulk_Tool_Last_Modified__c, Bulk_Tool_User__c from Account WHERE Id IN :accountIds];
            for(Account acct : actualAccts) {
                System.debug('CDdUploaderTest.testBatchable, account: ' + acct);
                System.assertNotEquals(null, acct.Bulk_Tool_User__c, 'Unexpected value for Bulk_Tool_User__c.');
                System.assertNotEquals(null, acct.Bulk_Tool_Last_Modified__c, 'Unexpected value for Bulk_Tool_Last_Modified__c.');
                System.assertNotEquals(null, acct.Bulk_Tool_Batch_Id__c, 'Unexpected value for Bulk_Tool_Batch_Id__c.');
            }

            List<Opportunity> actualOpps = [select Id, Bulk_Tool_Batch_Id__c, Bulk_Tool_Last_Modified__c, Bulk_Tool_User__c from Opportunity WHERE Id IN :opportunityIds];
            for(Opportunity opp : actualOpps) {
                System.debug('CDdUploaderTest.testBatchable, opp: ' + opp);
                System.assertNotEquals(null, opp.Bulk_Tool_User__c, 'Unexpected value for Bulk_Tool_User__c.');
                System.assertNotEquals(null, opp.Bulk_Tool_Last_Modified__c, 'Unexpected value for Bulk_Tool_Last_Modified__c.');
                System.assertNotEquals(null, opp.Bulk_Tool_Batch_Id__c, 'Unexpected value for Bulk_Tool_Batch_Id__c.');
            }
        }
    }    

    /** Test Data Setup **/
    static StaticResourceCalloutMock createMock(Boolean isSuccess) {
        Integer statusCode = isSuccess ? 200 : 500;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        switch on statusCode{
            when 200 {
                mock.setStaticResource('mockResponse_DSJ_create_business_success');
            }
            when else {
                mock.setStaticResource('mockResponse_DSJ_create_business_failure');
            }
        }
        mock.setStatusCode(statusCode);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }

    static void createTestData() {
        System.runAs(getTestRunUser()){
            List<Account> parentAccounts = createParentAccounts();
            List<Account> childAccounts = createChildAccounts(parentAccounts);
            Contact contact = createContact();
            List<Opportunity> opportunities = createOpportunities(childAccounts, contact);
        }        
    }

    static List<Account> createParentAccounts() {
        List<Account> testAccounts = TDdAccountFactory.createAccounts('TestDDAccountParent', 2, RECORD_TYPE_NAME_ACCOUNT_PARENT);
        Account testAcct1 = testAccounts[0];
        testAcct1.Name = TEST_DD_ACCOUNT_PARENT_0;
        testAcct1.BillingStreet = TDdAccountFactory.getRandom() + ' Mulberry Ln';
        testAcct1.Business_ID__c = null;
        testAcct1.Restaurant_Id__c = null;
        Account testAcct2 = testAccounts[1];
        testAcct2.Name = TEST_DD_ACCOUNT_PARENT_1;
        testAcct2.BillingStreet = TDdAccountFactory.getRandom() + ' Mulberry Ln';
        testAcct2.Business_ID__c = null;
        testAcct2.Restaurant_Id__c = null;
        insert testAccounts;
        return testAccounts;
    }

    static List<Account> createChildAccounts(List<Account> parentAccounts) {
        List<Account> testAccounts = new List<Account>();
        for (Account parentAccount : parentAccounts){
            List<Account> childAccounts = TDdAccountFactory.createAccounts(parentAccount.Name.replace('Parent','Child'), 2, RECORD_TYPE_NAME_ACCOUNT_ENTERPRISE_MARKETPLACE);
            Account childAcct1 = childAccounts[0];
            childAcct1.Parent = parentAccount;
            childAcct1.ParentId = parentAccount.Id;
            childAcct1.BillingStreet = TDdAccountFactory.getRandom() + ' Mulberry Ln';
            childAcct1.Business_ID__c = null;
            childAcct1.Restaurant_Id__c = null;
            childAcct1.Confirm_Protocol__c = 'Fail';
            Account childAcct2 = childAccounts[1];
            childAcct2.Parent = parentAccount;
            childAcct2.ParentId = parentAccount.Id;
            childAcct2.BillingStreet = TDdAccountFactory.getRandom() + ' Mulberry Ln';
            childAcct2.Business_ID__c = null;
            childAcct2.Restaurant_Id__c = null;
            childAcct2.Confirm_Protocol__c = 'Fail';
            testAccounts.addAll(childAccounts);
        }
        System.assertEquals(4, testAccounts.size(), 'Expecting child account size of ' + 4);
        insert testAccounts;
        return testAccounts;        
    }

    static Contact createContact(){
        //CDdContactTriggerHelper.insertCampaign();
        Contact c = new Contact(FirstName='Test', LastName='Merchant', Email='test@doordash.com');
        insert c;
        return c;        
    }

    static List<Opportunity> createOpportunities(List<Account> accounts, Contact c) {
        List<Opportunity> opps = new List<Opportunity>();
        Integer i = 0;
        for (Account a : accounts) {
            Opportunity o = TDdOpportunityFactory.createOpportunity(
                    'Uploader Opportunity ' + i,
                    a.Id,
                    c.Id,
                    'Closed Won',
                    'Omitted',
                    UserInfo.getUserId()
            );
            o.Activation_Fee__c = '$0'; //to trigger CDdS2NUtil.isStorePartnership
            o.Order_Protocol_Fax__c = '1234567890';
            opps.add(o);
        }
        System.assertEquals(4, opps.size(), 'Expecting test opportunity size of ' + 4);
        insert opps;
        return opps;
    }
}