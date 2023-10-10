@IsTest
public class CDdCampaignMemberTriggerHandlerTest {
    private static String email = 'test@doordash.com.test';
    private static String holdingUserName = 'holdinguser@doordash.com';
    private static String holdingUserAlias = 'Hold';
    private static String inboundSalesOmniQueueName = CDdSupportConstants.QUEUE_INBOUND_SALES_OMNI_QUEUE;
    private static String badLeadDataQueueName = CDdSupportConstants.QUEUE_BAD_LEAD_DATA;

    @IsTest
    public static void testGenerateLeadsNegative1() { // open opportunity
        Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId());
        insert account;

        Contact contact = createContact(account.Id);
        contact.Email = email;
        insert contact;

        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test', account.Id, contact.Id, 'New', CDdSchemaUtils.OpportunityRTEnum.DoorDash_for_Business.name());
        insert opp;

        Campaign campaign = new Campaign(Name = 'Test', Title__c = 'Test', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
        insert campaign;

        insert new CampaignMember(ContactId = contact.Id, CampaignId = campaign.Id);

        List<Lead> leads = [select Id from Lead];
        System.assertEquals(0, leads.size());
    }

    @IsTest
    public static void testGenerateLeadsNegative2() { // existing lead
        Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId());
        insert account;

        Contact contact = createContact(account.Id);
        contact.Email = email;
        insert contact;

        Lead lead = new Lead(LastName = 'Test', Email = email, PostalCode = '94107', Phone = '(415) 555-1212');
        insert lead;

        Campaign campaign = new Campaign(Name = 'Test', Title__c = 'Test', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
        insert campaign;

        insert new CampaignMember(ContactId = contact.Id, CampaignId = campaign.Id);

        List<Lead> leads = [select Id from Lead];
        System.assertEquals(1, leads.size());
    }

    /**
     * @description Prepare and return the test running user
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1)[0];
            testRunUser.FirstName = 'Hubspot';
            testRunUser.LastName = 'Integration User';
            testRunUser.email = 'hubspot@doordash.com.testemail';
        }
        return testRunUser;
    }

    @IsTest
    public static void testGenerateLeadsPositive1() {
        System.runAs(getTestRunUser()) {
            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId());
            insert account;

            Contact contact = createContact(account.Id);
            contact.Email = email;
            contact.Language__c = 'English';
            contact.Referrer_Store_ID__c = '12345';
            insert contact;

            Campaign campaign = new Campaign(Name = 'AcqMktgTest', Title__c = 'AcqMktgTest', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
            insert campaign;

            insert new CampaignMember(ContactId = contact.Id, CampaignId = campaign.Id);

            List<Lead> leads = [select Id,Language__c,Referrer_Store_ID__c from Lead];
            System.assertEquals(1, leads.size());
            System.assertEquals(contact.Language__c, leads[0].Language__c, 'Lead Language should be same Contact Language');
            System.assertEquals(contact.Referrer_Store_ID__c, leads[0].Referrer_Store_ID__c, 'Lead Referrer_Store_ID__c should be same Contact Language');
        }
    }

    private static Contact createContact(Id accountId) {
        Contact contact = TDdAccountFactory.createContacts(1, accountId)[0];
        contact.Phone = '(415) 555-1212';
        contact.MailingStreet = '303 2nd St';
        contact.MailingCity = 'San Francisco';
        contact.MailingState = 'CA';
        contact.MailingCountry = 'United States';
        contact.MailingPostalCode = '94107';
        contact.Email = email;
        return contact;
    }

    @IsTest
    static void testWhenInsertCMThenUpdateContact() {
        List<User> testUsers = TDdAccountFactory.createUsers(3);
        insert testUsers[0];
        system.runAs(testUsers[2]) {
            Lead l = new Lead(LastName = 'Test Lead 1', Street = '1231 Mulberry Ln', City = 'South San Francisco',
                    State = 'CA', PostalCode = '94101', CountryCode = 'US', Phone = '2135551231', Type__c = 'Franchise',
                    Lead_List__c = System.today(), Store_ID__c = '1234561', ARR__c = 1001.00, Amount__c = 1001.00,
                    Starting_Point__c = '101', Starting_Point_ID__c = 101, Deactivation_Code__c = 'Awaiting activation',
                    OwnerId = testUsers[0].Id, Email = email);
            insert l;
            Account acct = TDdAccountFactory.createAccounts('Test Account', 1)[0];
            insert acct;
            Contact con = createContact(acct.Id);
            insert con;
            List<Campaign> campaigns = new List<Campaign>{
                    new Campaign(Name = 'test campaign 1', Title__c = 'test campaign 1 title'),
                    new Campaign(Name = 'test campaign 2', Title__c = 'test campaign 2 title')
            };
            insert campaigns;
            Test.startTest();
            // List<CampaignMember> cms =
            insert new List<CampaignMember>{
                    new CampaignMember(CampaignId = campaigns[0].Id, ContactId = con.Id),
                    new CampaignMember(CampaignId = campaigns[1].Id, LeadId = l.Id)
            };
            Test.stopTest();

            for (Apex_Log__c log : [select Id, Class_Name__c, Log__c from Apex_Log__c]) {
                System.debug('CampaignMember: log: ' + log);
            }

            system.assertEquals(campaigns[0].Id, [SELECT Primary_Campaign_Source__c FROM Contact WHERE Id = :con.Id].Primary_Campaign_Source__c);
            system.assertEquals(campaigns[1].Id, [SELECT Primary_Campaign_Source__c FROM Lead WHERE Id = :l.Id].Primary_Campaign_Source__c);
        }
    }

    @IsTest
    static void testInsertLeadWithoutEmail() {
        List<User> testUsers = TDdAccountFactory.createUsers(3);
        insert testUsers[0];
        system.runAs(testUsers[2]) {
            Lead l = new Lead(LastName = 'Test Lead 1', Street = '1231 Mulberry Ln', City = 'South San Francisco',
                    State = 'CA', PostalCode = '94101', CountryCode = 'US', Phone = '2135551231', Type__c = 'Franchise',
                    Lead_List__c = System.today(), Store_ID__c = '1234561', ARR__c = 1001.00, Amount__c = 1001.00,
                    Starting_Point__c = '101', Starting_Point_ID__c = 101, Deactivation_Code__c = 'Awaiting activation',
                    OwnerId = testUsers[0].Id);
            insert l;

            List<Campaign> campaigns = new List<Campaign>{
                    new Campaign(Name = 'test campaign 1', Title__c = 'test campaign 1 title')
            };
            insert campaigns;
            Test.startTest();
            insert new List<CampaignMember>{
                    new CampaignMember(CampaignId = campaigns[0].Id, LeadId = l.Id)
            };
            Test.stopTest();

            for (Apex_Log__c log : [select Id, Class_Name__c, Log__c from Apex_Log__c]) {
                System.debug('CampaignMember: log: ' + log);
            }

            // Lead without Email was added to campaign
            system.assertEquals(1, [SELECT Id FROM CampaignMember WHERE LeadId = :l.Id].size());
        }
    }

    @isTest
    public static void testUpdateLeadInboundTimeAndOwner(){
        List<User> testUsers = TDdAccountFactory.createUsers(3);

        system.runAs(testUsers[2]) {
            Map<String, Id> keyToQueueOrUserIds = new Map<String, Id>();

            for(Group q: [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name IN (:inboundSalesOmniQueueName, :badLeadDataQueueName)]){
                keyToQueueOrUserIds.put(q.Name, q.Id);
            }

            Lead l = new Lead(
                LastName = 'Test Lead 1',
                Street = '1231 Mulberry Ln', City = 'South San Francisco', State = 'CA',
                PostalCode = '94101', CountryCode = 'US', Phone = '2135551231',
                Type__c = 'Franchise',
                Lead_List__c = System.today(),
                Store_ID__c = '1234561',
                ARR__c = 1001.00, Amount__c = 1001.00,
                Starting_Point__c = '101', Starting_Point_ID__c = 101, Deactivation_Code__c = 'Awaiting activation',
                OwnerId = keyToQueueOrUserIds.get(badLeadDataQueueName));
            insert l;

            Campaign campaignRecord = new Campaign(Name = 'MxAcqMktg Test Campaign A', Title__c = 'test campaign 1 title', Type = 'A');
            insert campaignRecord;

            Test.startTest();
            CampaignMember campaignMemberRecord = new CampaignMember(CampaignId = campaignRecord.Id, LeadId = l.Id);
            insert campaignMemberRecord;
            Test.stopTest();

            CampaignMember campaignMemberRecordInserted = [SELECT Id, Createddate from CampaignMember LIMIT 1];
            Lead leadToTest = [SELECT Id, OwnerId, Last_Inbound_Date_Time__c FROM Lead WHERE Id = :l.Id];
            // Lead Owner Changed to Inbound Sales Omni Queue
            system.assertEquals(keyToQueueOrUserIds.get(inboundSalesOmniQueueName), leadToTest.OwnerId);
            system.assertEquals(campaignMemberRecordInserted.createddate, leadToTest.Last_Inbound_Date_Time__c);
        }
    }

    @isTest
    public static void testDeleteLeadUpdateLeadInboundTimeAndOwner(){
        List<User> testUsers = TDdAccountFactory.createUsers(3, null, [SELECT Id FROM UserRole LIMIT 1].ID);
        insert testUsers;

        system.runAs(testUsers[2]) {
            Map<String, Id> keyToQueueOrUserIds = new Map<String, Id>();

            for(Group q: [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name IN (:inboundSalesOmniQueueName, :badLeadDataQueueName)]){
                keyToQueueOrUserIds.put(q.Name, q.Id);
            }

            Test.startTest();
            Lead l = new Lead(
                LastName = 'Test Lead 1',
                Street = '1231 Mulberry Ln', City = 'South San Francisco', State = 'CA',
                PostalCode = '94101', CountryCode = 'US', Phone = '2135551231',
                Type__c = 'Franchise',
                Lead_List__c = System.today(),
                Store_ID__c = '1234561',
                ARR__c = 1001.00, Amount__c = 1001.00,
                Starting_Point__c = '101',
                Starting_Point_ID__c = 101,
                Deactivation_Code__c = 'Awaiting activation',
                OwnerId = keyToQueueOrUserIds.get(badLeadDataQueueName));
            insert l;

            List<Campaign> campaigns = new List<Campaign>{
                    new Campaign(
                        Name = 'Test Campaign A',
                        Title__c = 'test campaign 1 title',
                        Type = 'A')
            };
            insert campaigns;

            List<CampaignMember> campaignMember = new List<CampaignMember>{
                    new CampaignMember(CampaignId = campaigns[0].Id, LeadId = l.Id)
            };
            insert campaignMember;

            delete campaignMember;
            Test.stopTest();

            Lead leadToTest = [SELECT Id, OwnerId, Last_Inbound_Date_Time__c FROM Lead WHERE Id = :l.Id];
            system.assertEquals(null, leadToTest.Last_Inbound_Date_Time__c);
        }
    }

    @IsTest
    public static void testCDdCampaignMemberQueueable() {
        System.runAs(getTestRunUser()) {
            Map<String, Id> keyToQueueOrUserIds = new Map<String, Id>();

            for(Group q: [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name IN (:inboundSalesOmniQueueName, :badLeadDataQueueName)]){
                keyToQueueOrUserIds.put(q.Name, q.Id);
            }

            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId());
            insert account;

            Contact contact = createContact(account.Id);
            contact.Email = email;
            contact.Language__c = 'English';
            insert contact;

            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            testLeads[0].Email = email;
            insert testLeads;

            List<Lead> existingLeads = [select Id, LeadSource, OwnerId from Lead];

            Id oldOwnerId = existingLeads[0].OwnerId;

            List<Campaign> campaignList = TDdCampaignCampaignMemberFactory.createCampaigns('AcqMktgTest', 2, CDdCampaignMemberTriggerHelper.campaignWorkId, True);

            Test.startTest();
            CampaignMember cmp1 = TDdCampaignCampaignMemberFactory.createCampaignMember(campaignList[1].Id, null, testLeads[0].Id, True);
            CampaignMember cmp2 = TDdCampaignCampaignMemberFactory.createCampaignMember(campaignList[0].Id, contact.Id, null, True);
            Test.stopTest();

            List<Lead> leads = [select Id, LeadSource, OwnerId from Lead];
            System.assertEquals('Merchant Inbound', leads[0].LeadSource);
            System.assertEquals(oldOwnerId, leads[0].OwnerId);
        }
    }
}