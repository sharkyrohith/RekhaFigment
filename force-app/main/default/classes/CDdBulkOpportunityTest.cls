/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7037: "Bulk Creation Opportunities" button and batch job
 * Implements BZAP-7046: Batch Job "Retry" Process and GridBuddy button
 */
@IsTest
public with sharing class CDdBulkOpportunityTest {
    private static final String CONTRACT_TYPE = 'Franchisee Opt-Out Addendum';
    private static final String OPP_TYPE = 'New Partner (Create Menu + Nimda)';
    private static final String STAGENAME = 'New';
    private static final Id FRANCHISE_OPPORTUNITY = CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId();

    @IsTest
    public static void testSuccess() {
        List<Account> accounts = new List<Account>();
        List<Opportunity> opps = new List<Opportunity>();

        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        insert testSettings;

        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Account_Validations__c = true;
        insert validation;

        Account grandparentAccount = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.grandparentAccountId());
        grandparentAccount.Name = 'Grandparent';
        insert grandparentAccount;

        Contact contact = TDdAccountFactory.createContacts(1, grandparentAccount.Id)[0];
        insert contact;

        Account parentAccount = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.parentAccountId());
        parentAccount.Name = 'Corporate';
        parentAccount.enterprise_parent_account_type__c = 'Corporate';
        parentAccount.Parent = grandparentAccount;
        parentAccount.Decision_Maker__c = contact.Id;
        accounts.add(parentAccount);

        Account relatedAccount1 = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.parentAccountId());
        relatedAccount1.Name = 'Franchise1';
        relatedAccount1.enterprise_parent_account_type__c = 'Franchise';
        relatedAccount1.Parent = grandparentAccount;
        relatedAccount1.Decision_Maker__c = contact.Id;
        accounts.add(relatedAccount1);

        Account relatedAccount2 = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.parentAccountId());
        relatedAccount2.Name = 'Franchise2';
        relatedAccount2.enterprise_parent_account_type__c = 'Franchise';
        relatedAccount2.Parent = grandparentAccount;
        relatedAccount2.Decision_Maker__c = contact.Id;
        accounts.add(relatedAccount2);

        insert accounts;
        accounts.add(grandparentAccount);

        Opportunity sourceOpp = TDdOpportunityFactory.createOpportunity('Source', parentAccount.Id, contact.Id, 'Closed Won');
        sourceOpp.RecordTypeId = FRANCHISE_OPPORTUNITY;
        sourceOpp.CloseDate = System.today();
        sourceOpp.PactSafe_Contract_Type__c = 'Franchisee Opt-In Addendum';
        sourceOpp.POS_Integration_Type__c = '';
        //sourceOpp.Menu_to_be_completed_by__c = null;
        //sourceOpp.Menu_Setup_Method__c =  null;
        sourceOpp.Tablet_Kit_Type__c = null;
        opps.add(sourceOpp);

        Opportunity relatedOpp = TDdOpportunityFactory.createOpportunity('Related', parentAccount.Id, contact.Id, 'Closed Won');
        relatedOpp.RecordTypeId = FRANCHISE_OPPORTUNITY;
        relatedOpp.CloseDate = System.today();
        relatedOpp.PactSafe_Contract_Type__c = 'Franchisee Opt-In Addendum';
        relatedOpp.POS_Integration_Type__c = '';
        //relatedOpp.Menu_to_be_completed_by__c = null;
        //relatedOpp.Menu_Setup_Method__c =  null;
        relatedOpp.Tablet_Kit_Type__c = null;
        opps.add(relatedOpp);

        insert opps;

        Test.startTest();
        CDdBulkOpportunityController.execute(sourceOpp.Id, String.join(new List<String> { relatedAccount1.Id, relatedAccount2.Id, parentAccount.id }, ','));
        Test.stopTest();

        // Tia Xuan 09/2020 BZAPSUP-484 Switch references of "Number_of_Stores__c" in apex classes
        List<Opportunity> opps2 = [
                select AccountId, Account.Name, Contract_Signed_Date__c, Decision_Maker__c, Docusign_Sent__c, Enterprise_Type__c,
                        Marketplace_Contract_Link__c, Merchant_Supplied_ID__c, Name, of_Addressable_Locations__c,
                        PactSafe_Contract_Type__c, Parent_Opportunity__c, RecordTypeId, StageName, Type
                from Opportunity];
        Opportunity opp1 = [
                select Contract_Signed_Date__c, Decision_Maker__c, Docusign_Sent__c, Enterprise_Type__c,
                        Marketplace_Contract_Link__c, Merchant_Supplied_ID__c, Name, of_Addressable_Locations__c,
                        PactSafe_Contract_Type__c, Parent_Opportunity__c, RecordTypeId, StageName, Type
                from Opportunity where AccountId = :relatedAccount1.Id];
        System.assertEquals('Franchise', opp1.Enterprise_Type__c, 'Unexpected enterprise type');
        System.assertEquals(contact.Id, opp1.Decision_Maker__c, 'Unexpected decision maker');
        System.assertEquals(CONTRACT_TYPE, opp1.PactSafe_Contract_Type__c, 'Unexpected PactSafe contract type');
        System.assertEquals(getName(relatedAccount1, opp1), opp1.Name, 'Unexpected opportunity name');
        System.assertEquals(null, opp1.Contract_Signed_Date__c, 'Unexpected contract signed date');
        System.assertEquals(null, opp1.Docusign_Sent__c, 'Unexpected docusign sent date');
        System.assertEquals(null, opp1.Marketplace_Contract_Link__c, 'Unexpected value for marketplace contract link');
        System.assertEquals(null, opp1.Merchant_Supplied_ID__c, 'Unexpected value for merchant supplied Id');
        System.assertEquals(null, opp1.of_Addressable_Locations__c, 'Unexpected number of stores');
        System.assertEquals(OPP_TYPE, opp1.Type, 'Unexpected opportunity type');
        System.assertEquals(FRANCHISE_OPPORTUNITY, opp1.RecordTypeId, 'Unexpected record type');
        System.assertEquals(sourceOpp.Id, opp1.Parent_Opportunity__c, 'Unexpected parent opportunity');
        System.assertEquals(STAGENAME, opp1.StageName, 'Unexpected stage');

        // Tia Xuan 09/2020 BZAPSUP-484 Switch references of "Number_of_Stores__c" in apex classes
        Opportunity opp2 = [
                select Contract_Signed_Date__c, Decision_Maker__c, Docusign_Sent__c, Enterprise_Type__c,
                        Marketplace_Contract_Link__c, Merchant_Supplied_ID__c, Name, of_Addressable_Locations__c,
                        PactSafe_Contract_Type__c, Parent_Opportunity__c, RecordTypeId, StageName, Type
                from Opportunity where AccountId = :relatedAccount2.Id];
        System.assertEquals('Franchise', opp2.Enterprise_Type__c, 'Unexpected enterprise type');
        System.assertEquals(contact.Id, opp2.Decision_Maker__c, 'Unexpected decision maker');
        System.assertEquals(CONTRACT_TYPE, opp2.PactSafe_Contract_Type__c, 'Unexpected PactSafe contract type');
        System.assertEquals(getName(relatedAccount2, opp2), opp2.Name, 'Unexpected opportunity name');
        System.assertEquals(null, opp2.Contract_Signed_Date__c, 'Unexpected contract signed date');
        System.assertEquals(null, opp2.Docusign_Sent__c, 'Unexpected docusign sent date');
        System.assertEquals(null, opp2.Marketplace_Contract_Link__c, 'Unexpected value for marketplace contract link');
        System.assertEquals(null, opp2.Merchant_Supplied_ID__c, 'Unexpected value for merchant supplied Id');
        System.assertEquals(null, opp2.of_Addressable_Locations__c, 'Unexpected number of stores');
        System.assertEquals(OPP_TYPE, opp2.Type, 'Unexpected opportunity type');
        System.assertEquals(FRANCHISE_OPPORTUNITY, opp2.RecordTypeId, 'Unexpected record type');
        System.assertEquals(sourceOpp.Id, opp2.Parent_Opportunity__c, 'Unexpected parent opportunity');
        System.assertEquals(STAGENAME, opp2.StageName, 'Unexpected stage');
    }

    private static String getName(Account account, Opportunity opp) {
        Datetime dt = System.today();
        String name = account.Name + ' - Franchise ' + opp.Type + ' - ' + dt.format('YYYY-MM-dd');
        return name;
    }
}