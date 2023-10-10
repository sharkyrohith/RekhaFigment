@isTest
public class CDdCampaignMemberEventHandlerTest {
	private static String email = 'test@doordash.com.test';
    
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
    static void testContactLeadPrimaryCampaignSource() {
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
            insert new List<CampaignMember>{
                    new CampaignMember(CampaignId = campaigns[0].Id, ContactId = con.Id),
                    new CampaignMember(CampaignId = campaigns[1].Id, LeadId = l.Id)
            };
            Test.getEventBus().deliver();
            Test.stopTest();
			
            system.assertEquals(campaigns[0].Id, [SELECT Primary_Campaign_Source__c FROM Contact WHERE Id = :con.Id].Primary_Campaign_Source__c);
            system.assertEquals(campaigns[1].Id, [SELECT Primary_Campaign_Source__c FROM Lead WHERE Id = :l.Id].Primary_Campaign_Source__c);
        }
    }
    
}