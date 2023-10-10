/**
 * Created by Jeremy S. Johnson, Perficient, Inc. on 3/18/2020.
 */
@IsTest
public with sharing class CDdBulkLeadConvertTest {
    public static final String partitionPrefix = 'local.DoorDash.bulkLeadConvert';

    @TestSetup
    public static void  setup() {
        try {
            insert new E2F__FindApi_Triggers_Settings__c(E2F__Bypass_Trigger__c = true);
        } catch(Exception e) {

        }

        Account parentAccount = VTestUtil.createAccount('Parent');
        insert parentAccount;

        Account childAccount = VTestUtil.createAccount('Child');
        childAccount.ParentId = parentAccount.Id;
        childAccount.Restaurant_ID__c = '1';
        insert childAccount;

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;

        List<Lead> leads = new List<Lead>();
        leads.add(createLead('0', null, null));
        leads.add(createLead('1', childAccount.Id, null));
        leads.add(createLead('2', null, parentAccount.Id));
        insert leads;
    }

    @IsTest
    public static void testController() {
        List<Lead> leads = [select Id, Account__c, Parent_Account_ID__c from Lead];
        String ids = '';
        for(Lead lead : leads) {
            ids += lead.Id + ',';
        }
        ids = ids.removeEnd(',');

        Test.startTest();
        String batchId = CDdBulkLeadConvertController.bulkConvertLeads(ids, 200);
        List<String> messages = CDdBulkLeadConvertController.getImportMessages();
        Test.stopTest();

        AsyncApexJob job = CDdBulkLeadConvertController.getProgress(batchId);

        System.assertNotEquals(null, batchId, 'Unexpected value for batchId');
        System.assertEquals(0, messages.size(), 'Unexpected number or errors');
        System.assertEquals('Completed', job.Status, 'Unexpected batch job status');

        List<Account> accounts = [select Id, Parent_Account_ID__c from Account order by Id];
        List<Contact> contacts = [select Id from Contact order by Id];
        List<Opportunity> opportunities = [select Id from Opportunity order by Id];

        System.assertEquals(4, accounts.size(), 'Unexpected number of accounts');
        System.assertEquals(3, contacts.size(), 'Unexpected number of contacts');
        System.assertEquals(3, opportunities.size(), 'Unexpected number of opportunities');
    }

    public static Lead createLead(String order, String accountId, String parentId) {
        String randStr = String.valueOf((Integer)(Math.random() * 10000)).leftPad(4, '0');

        Lead lead = new Lead(
                LastName = 'Lead_' + randStr,
                Street = randStr + ' Mulberry Ln',
                City = 'South San Francisco',
                State = 'CA',
                PostalCode = '94108',
                Phone = '(800) 555-' + randStr,
                Email = randStr + 'test@thisisfake.com',
                Company = 'Company_' + randStr,
                Store_ID__c = order,
                Validation_Bypass__c = true,
                Account__c = accountId,
                Parent_Account__c = parentId
        );
        return lead;
    }
}