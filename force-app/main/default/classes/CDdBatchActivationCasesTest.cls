/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7492: Scheduled Batch Job for bulk activation cases
 * Implements BZAP-7352: Scheduled Batch Job for bulk deactivation case
 */
@IsTest
public with sharing class CDdBatchActivationCasesTest {

    public static void setup() {
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true; insert validation;

        Account parentAccount = createAccount(CDdSchemaUtils.ACCOUNT_RT.parentAccountId(), null);
        insert parentAccount;

        List<Account> franchiseAccounts = new List<Account>();

        Account franchiseAccount1 = createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId(), '1');
        franchiseAccount1.ParentId = parentAccount.Id;
        franchiseAccounts.add(franchiseAccount1);

        Account franchiseAccount2 = createAccount(CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId(), '2');
        franchiseAccount2.ParentId = parentAccount.Id;
        franchiseAccounts.add(franchiseAccount2);

        insert franchiseAccounts;
    }

    private static Account createAccount(Id recTypeId, String restaurantId) {
        Account account = new Account();
        account.Bank_Account_Number_Encrypted__c = '123456789';
        account.Bank_Routing_Number_Encrypted__c = '123456789';
        account.BillingCity = 'South San Francisco';
        account.BillingCountry = 'United States';
        account.BillingCountryCode = 'US';
        account.BillingPostalCode = '95689';
        account.BillingState = 'CA';
        account.BillingStreet = '1 Mulberry Ln';
        account.Business_ID__c = Integer.valueOf(getRandom().left(5));
        account.Currently_Active__c = 'Yes';
        account.EIN_Encrypted__c = '123456789';
        account.Legal_Business_Name__c = 'TestAccount';
        account.Name = 'Subway US [Corporate Parent-3720]';
        account.Phone = getRandom();
        account.RecordTypeId = recTypeId;
        account.Restaurant_ID__c = restaurantId;
        account.enterprise_parent_account_type__c = 'Corporate';
        return account;
    }

    @IsTest
    public static void testSchedulable() {
        Test.startTest();
        System.schedule('CDdBatchActivationCasesSchedulable', '20 30 8 10 2 ?', new CDdBatchActivationCasesSchedulable());
        Test.stopTest();
    }

    @IsTest
    public static void testActivations() {
        setup();
        Account account = [select Id from Account where RecordTypeId = :CDdSchemaUtils.ACCOUNT_RT.parentAccountId() limit 1];
        List<Opportunity> opps = new List<Opportunity>();

        Opportunity parentOppHit = createOpportunity(account.Id);
        parentOppHit.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DDActivationDays) + 1));
        parentOppHit.Name='Parent Opp Hit';
        parentOppHit.PactSafe_Record__c = 'https://doordash.com';
        parentOppHit.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.corporateId();
        opps.add(parentOppHit);

        Opportunity parentOppMiss = createOpportunity(account.Id);
        parentOppMiss.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DDActivationDays)));
        parentOppMiss.Name='Parent Opp Miss';
        parentOppMiss.PactSafe_Record__c = 'https://doordash.com';
        parentOppMiss.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.corporateId();
        opps.add(parentOppMiss);

        insert opps;
        opps.clear();

        Opportunity childOppHit1 = createOpportunity(account.Id);
        childOppHit1.Name='Child Opp Hit 1';
        childOppHit1.Parent_Opportunity__c = parentOppHit.Id;
        childOppHit1.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();
        opps.add(childOppHit1);

        Opportunity childOppHit2 = createOpportunity(account.Id);
        childOppHit2.Name='Child Opp Hit 2';
        childOppHit2.Parent_Opportunity__c = parentOppHit.Id;
        childOppHit2.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();
        opps.add(childOppHit2);

        Opportunity childOppMiss = createOpportunity(account.Id);
        childOppMiss.Name='Child Opp Miss';
        childOppMiss.Parent_Opportunity__c = parentOppMiss.Id;
        childOppMiss.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();
        opps.add(childOppMiss);

        insert opps;

        Test.startTest();
        Database.executeBatch(new CDdBatchActivationCases());
        Test.stopTest();

        List<Case> cases = [select Id from Case];
        List<Opportunity> hitOpps = [
                select Id, Activation_Case_Created__c
                from Opportunity
                where Id = :new List<Id>{parentOppHit.Id, childOppHit1.Id, childOppHit2.Id}
        ];

        System.assertEquals(1, cases.size());
        System.assertEquals(3, hitOpps.size());

        for(Opportunity opp : hitOpps) {
            System.assertEquals(true, opp.Activation_Case_Created__c, 'Unexpected value for Activation_Case_Created__c');
        }

        Case cas = cases[0];

        ContentVersion cv = [select Id, ContentDocumentId, VersionData from ContentVersion limit 1];
        System.assertEquals('Restaurant_Id__c\n1\n2\n', cv.VersionData.toString(), 'Unexpected csv format');

        for(ContentDocumentLink cdl : [select Id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId = :cas.Id]) {
            System.assertEquals(cv.ContentDocumentId, cdl.ContentDocumentId, 'Unexpected ContentDocumentId');
            System.assertEquals(cas.Id, cdl.LinkedEntityId, 'Unexpected LinkedEntityId');
        }
    }

    @IsTest
    public static void testDeactivations() {
        setup();
        Account account = [select Id from Account where RecordTypeId = :CDdSchemaUtils.ACCOUNT_RT.parentAccountId() limit 1];
        List<Opportunity> opps = new List<Opportunity>();

        Opportunity parentOppHit = createOpportunity(account.Id);
        parentOppHit.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DDDeactivationDays) + 1));
        parentOppHit.Name='Parent Opp Hit';
        parentOppHit.PactSafe_Record__c = 'https://doordash.com';
        parentOppHit.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.corporateId();
        opps.add(parentOppHit);

        Opportunity parentOppMiss = createOpportunity(account.Id);
        parentOppMiss.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DDDeactivationDays)));
        parentOppMiss.Name='Parent Opp Miss';
        parentOppMiss.PactSafe_Record__c = 'https://doordash.com';
        parentOppMiss.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.corporateId();
        opps.add(parentOppMiss);

        insert opps;
        opps.clear();

        Opportunity childOppHit1 = createOpportunity(account.Id);
        childOppHit1.Name='Child Opp Hit 1';
        childOppHit1.Parent_Opportunity__c = parentOppHit.Id;
        childOppHit1.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();
        childOppHit1.StageName = 'Closed Lost';
        childOppHit1.Lost_Reason__c = 'Gone dark';
        opps.add(childOppHit1);

        Opportunity childOppHit2 = createOpportunity(account.Id);
        childOppHit2.Name='Child Opp Hit 2';
        childOppHit2.Parent_Opportunity__c = parentOppHit.Id;
        childOppHit2.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();
        childOppHit2.StageName = 'Closed Lost';
        childOppHit2.Lost_Reason__c = 'Gone dark';
        opps.add(childOppHit2);

        Opportunity childOppMiss = createOpportunity(account.Id);
        childOppMiss.Name='Child Opp Miss';
        childOppMiss.Parent_Opportunity__c = parentOppMiss.Id;
        childOppMiss.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();
        opps.add(childOppMiss);

        insert opps;

        Test.startTest();
        Database.executeBatch(new CDdBatchDeactivationCases());
        Test.stopTest();

        List<Case> cases = [select Id from Case];
        List<Opportunity> hitOpps = [
                select Id, Deactivation_Case_Created__c
                from Opportunity
                where Id = :new List<Id>{parentOppHit.Id, childOppHit1.Id, childOppHit2.Id}
        ];

        System.assertEquals(1, cases.size());
        System.assertEquals(3, hitOpps.size());

        for(Opportunity opp : hitOpps) {
            System.assertEquals(true, opp.Deactivation_Case_Created__c, 'Unexpected value for Deactivation_Case_Created__c');
        }

        Case cas = cases[0];

        ContentVersion cv = [select Id, ContentDocumentId, VersionData from ContentVersion limit 1];
        System.assertEquals('Restaurant_Id__c\n1\n2\n', cv.VersionData.toString(), 'Unexpected csv format');

        for(ContentDocumentLink cdl : [select Id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId = :cas.Id]) {
            System.assertEquals(cv.ContentDocumentId, cdl.ContentDocumentId, 'Unexpected ContentDocumentId');
            System.assertEquals(cas.Id, cdl.LinkedEntityId, 'Unexpected LinkedEntityId');
        }
   }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity();
        opp.AccountId = accountId;
        opp.CloseDate = System.today().addDays(-1);
        // Tia Xuan 09/2020 BZAPSUP-484 Switch references of "Number_of_Stores__c" in apex classes
        opp.of_Addressable_Locations__c = 1;
        opp.StageName = 'Closed Won';
        //opp.Menu_to_be_completed_by__c = null;
        //opp.Menu_Setup_Method__c =  null;
        opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
        opp.Tablet_Kit_Type__c = null;
        return opp;
    }

    public static String getRandom(){
        Integer len = 10;
        final String chars = '0123456789';
        String randStr = '';

        While (randStr.length() < len){
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }
}