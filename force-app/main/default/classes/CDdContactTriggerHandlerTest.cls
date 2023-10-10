/**
* @author Tia Xuan	
* @date 2019-04
*
* @description Test class for CDdContactTriggerHandler
*/
@isTest
public class CDdContactTriggerHandlerTest {
    private static final Decimal TEST_BUSINESS_ID = 76789.0;
    public static final String TEST_DD_ACCOUNT_MERCHANT_CATEGORIES = 'Alcohol / Alcohol-Lite ; Grocery';
   /** 
    * @description Prepare test data
    */
    @testSetup 
    static void setup() {
        List<Business_Vertical__c> bvList = TDdAccountFactory.setUpBusinessVerticals();
        //insert Contact feature flag
        Contact_Feature_Flag__c conFeatureSetting = Contact_Feature_Flag__c.getOrgDefaults();
        conFeatureSetting.Disable_Contact_Trigger__c = false;
        insert conFeatureSetting;
        
        String sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        vCS__c s = VTestUtil.createVeltigSettings();
        s.parentAccMatchFlag__c = true;
        s.SetupOwnerId = sysAdminProfileId;
        insert s;        
        Test.startTest();       
        // insert parent account
        String parentAccountName = 'Test Parent Account';
        Decimal businessId = TEST_BUSINESS_ID;        
        Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Business_Id__c = businessId;
        parentAccount.Deck_Rank__c = 'Jack';
        insert parentAccount;
        Contact parentContact = VTestUtil.createContact('Test Parent', 'Contact Parent', parentAccount);
        parentContact.Email = 'parent.contact@testdd.com';
        insert parentContact;
        Test.stopTest();
    }    

    /**
    * @description test contact owner before insert
    */    
    @isTest
    static void testContactOwnerBeforeInsert() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            childAccount.OwnerId = runUser0.Id;
            childAccount.ADR_Owner_Actual__c = runUser1.Id;
            insert childAccount;
            Test.startTest();
            Contact contact1 = VTestUtil.createContact('Test1', 'Contact1', childAccount);
            contact1.OwnerId = runUser0.Id;
            Contact contact2 = VTestUtil.createContact('Test2', 'Contact2', childAccount);
            contact2.OwnerId =  runUser0.Id;
            List<Contact> newContacts = new List<Contact>{contact1, contact2};
            insert newContacts;
            Account childAccountFromDB = [SELECT Id, OwnerId, ADR_Owner_Actual__c FROM Account WHERE Id = :childAccount.Id];
            List<Contact> childContactsFromDB = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :childAccountFromDB.Id];
            Test.stopTest();
            System.assertEquals(runUser1.Id
                                , childContactsFromDB[0].OwnerId
                                , 'Expecting the Contact Owner to be ' + runUser1.Id);          
            System.assertEquals(true
                                , childContactsFromDB[0].OwnerId.equals(childAccountFromDB.ADR_Owner_Actual__c)
                                , 'Expecting the Contact Owner to match with the Account ADR Owner');
        }
    }
    /**
    * @description test contact owner before update
    */    
    @isTest
    static void testContactOwnerBeforeUpdate() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-76789]';
        String businessVerticalName = 'Test Retail';	
        List<Business_Vertical__c> bvList = [SELECT Id, Menu_UI_Type__c, Primary_Category__c, Name, Business_Vertical_Id__c FROM Business_Vertical__c WHERE name =:businessVerticalName];
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser0 = testUsers[0];
        User runUser1 = testUsers[1];
        System.runAs (runUser0) {
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = TEST_BUSINESS_ID;
            childAccount.Deck_Rank__c = 'Jack';
            childAccount.OwnerId = runUser0.Id;
            childAccount.ADR_Owner_Actual__c = null;
            childAccount.Merchant_Categories__c = TEST_DD_ACCOUNT_MERCHANT_CATEGORIES;		
        	childAccount.Primary_Merchant_Category__c = bvList[0].Primary_Category__c;
            insert childAccount;
            Contact contact1 = VTestUtil.createContact('Test1', 'Contact1', childAccount);
            Contact contact2 = VTestUtil.createContact('Test2', 'Contact2', childAccount);
            List<Contact> newContacts = new List<Contact>{contact1, contact2};
            insert newContacts;
            Test.startTest();
            for (Contact c : newContacts){
                c.OwnerId = runUser1.Id;
            }
            update newContacts;
            Account childAccountFromDB = [SELECT Id, OwnerId, ADR_Owner_Actual__c FROM Account WHERE Id = :childAccount.Id];
            List<Contact> childContactsFromDB = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :childAccountFromDB.Id];
            Test.stopTest();
            System.assertEquals(runUser0.Id
                                , childContactsFromDB[0].OwnerId
                                , 'Expecting the Contact Owner to be ' + runUser0.Id);          
            System.assertEquals(true
                                , childContactsFromDB[0].OwnerId.equals(childAccountFromDB.OwnerId)
                                , 'Expecting the Contact Owner to match with the Account Owner Id');
        }
    }   
    /**
    * @description Test for BZAP-5095 - Match contacts to accounts based on Formstack Store ID
    */    
    @isTest
    static void testMatchOnFormstackStoreId() {
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String TEST_STORE_ID = '12345678';
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            List<Account> childAccounts = TDdAccountFactory.createAccounts(childAccountName, 2, 'Marketplace');
            Account childAccount0 = childAccounts[0];
            childAccount0.BillingCountry = 'United States';
            childAccount0.Business_Id__c = 12345;
            Account childAccount1 = childAccounts[1];
            childAccount1.BillingCountry = 'United States';
            childAccount1.Business_Id__c = 67890;
            childAccount1.Restaurant_ID__c = TEST_STORE_ID;            
            insert childAccounts;
            Test.startTest();
            Contact contact0 = VTestUtil.createContact('Test1', 'Contact0', childAccount0);
            Contact contact1 = VTestUtil.createContact('Test2', 'Contact1', childAccount0);
            contact1.Formstack_Store_ID__c = TEST_STORE_ID;
            List<Contact> newContacts = new List<Contact>{contact0, contact1};
            insert newContacts;
            Test.stopTest();
            Account childAccount0FromDB = null;
            Account childAccount1FromDB = null;
            for (Account a : [SELECT Id, Business_Id__c, Restaurant_ID__c FROM Account WHERE Id IN :childAccounts]){
                if (TEST_STORE_ID.equals(a.Restaurant_ID__c)){
                    childAccount1FromDB = a;
                } else {
                    childAccount0FromDB = a;
                }
            }
            Contact childContact0FromDB = null;
            Contact childContact1FromDB = null;            
            for (Contact c : [SELECT Id, Formstack_Store_ID__c, AccountId FROM Contact WHERE Id IN :newContacts]){
                if (TEST_STORE_ID.equals(c.Formstack_Store_ID__c)){
                    childContact1FromDB = c;
                } else {
                    childContact0FromDB = c;
                }
            }
            System.assertEquals(childAccount0FromDB.Id
                                , childContact0FromDB.AccountId
                                , 'Expecting the Contact 0 Account Id to be ' + childAccount0FromDB.Id);          
            System.assertEquals(childAccount1FromDB.Id
                                , childContact1FromDB.AccountId
                                , 'Expecting the Contact 1 Account Id to be ' + childAccount1FromDB.Id); 
        }
    }       

    @isTest
    static void testContactPhoneBeforeUpdate() {
        Contact cont = [SELECT Id, Phone, Mobile_Phone__c FROM Contact LIMIT 1];
        cont.Phone = '+64 55 44 3322';
        cont.Mobile_Phone__c = '+64 55 44 3322';
        cont.MailingCountryCode = 'NZ';
        cont.MailingCountry = 'New Zealand';
        cont.MailingState = 'Auckland';
        cont.MailingPostalCode = '1234';
        Test.startTest();
        update cont;
        Test.stopTest();
        cont = [SELECT Id, Phone, Mobile_Phone__c FROM Contact WHERE Id =: cont.Id];
        System.assertEquals('+6455443322', cont.Phone);
        System.assertEquals('+6455443322', cont.Mobile_Phone__c);
    }
    
    @isTest
    static void testStateLeadUpdate() {
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Hubspot';
        testRunUser.LastName = 'Integration User';
        testRunUser.email = 'hubspot@doordash.com.testemail';
        insert testRunUser;
        System.runAs (testRunUser) {
            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId());
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.id)[0];
            contact.Phone = '(415) 555-1212';
            contact.MailingStreet = '303 2nd St';
            contact.MailingCity = 'San Francisco';
            contact.MailingState = 'CA';
            contact.MailingCountry = 'United States';
            contact.MailingPostalCode = '94107';
            contact.Email = 'test@doordash.com.test';
            contact.Language__c = 'English';
            insert contact;

            Campaign campaign = new Campaign(Name = 'AcqMktgTest', Title__c = 'AcqMktgTest', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
            insert campaign;

            insert new CampaignMember(ContactId = contact.Id, CampaignId = campaign.Id);
            
            test.startTest();
			contact.MailingState = 'CO';
            update contact;
            test.stopTest();
            
            List<Lead> leadList = [Select id,State,Created_from_Contact__c From Lead Where Created_from_Contact__c =: contact.id];
            System.assertEquals(contact.MailingState, leadList[0].State, 'Contact State and Lead state should be same');
        }
    }
    
    /**
    * description Test for BZAP-13013 - test method for outreachContactCorrectSequence
    */  
    @isTest
    static void testoutreachContactCorrectSequenceInsert() {    
        List<User> testUsers = TDdAccountFactory.createUsers(1);
        User runUser0 = testUsers[0];
        String accountName = 'Test FormStack';
        String TEST_STORE_ID = '12345678';
        System.runAs (runUser0) {          
            Account accountToInsert  = TDdAccountFactory.createAccounts(accountName, 1, 'Marketplace')[0];
            accountToInsert.BillingCountry = 'United States';
            accountToInsert.Business_Id__c = 12345; 
            Test.startTest();
            insert accountToInsert;      
            List<Contact> contactToInsert = TDdAccountFactory.createContacts(1, accountToInsert.id);
            Contact contactToInsertOne = contactToInsert[0];
            contactToInsertOne.Initial_Sequence_Name__c = '';
            contactToInsertOne.Name_of_Currently_Active_Sequence__c = 'test';
            contactToInsertOne.ID_of_Currently_Active_Sequence__c = '123';
            contactToInsertOne.Email = 'testformstackone@doordash.com.test';     
            insert contactToInsert; 
            Test.stopTest();           
            Contact contactFromDB = [SELECT Id, 
                                            ID_of_Currently_Active_Sequence__c,
                                            Name_of_Currently_Active_Sequence__c,
                                            Initial_Sequence_ID__c, 
                                            Initial_Sequence_Date__c, Initial_Sequence_Name__c 
                                    FROM Contact
                                    WHERE Email = 'testformstackone@doordash.com.test'];
            System.assertEquals(contactFromDB.Initial_Sequence_ID__c,contactFromDB.ID_of_Currently_Active_Sequence__c);
            System.assertEquals(contactFromDB.Initial_Sequence_Date__c, System.today());
            System.assertEquals(contactFromDB.Initial_Sequence_Name__c,contactFromDB.Name_of_Currently_Active_Sequence__c);          
        }
    }

    /**
    * @description Test for BZAP-13013 - test method for FormstackUpdateDM
    */  
    @isTest
    static void testFormstackUpdateDM() {    
        List<User> testUsers = TDdAccountFactory.createUsers(1);
        User runUser0 = testUsers[0];
        String accountName = 'Test FormStack';
        String TEST_STORE_ID = '12345678';
        System.runAs (runUser0) {          
            Account accountToInsert  = TDdAccountFactory.createAccounts(accountName, 1, 'Marketplace')[0];
            accountToInsert.BillingCountry = 'United States';
            accountToInsert.Business_Id__c = 12345; 
            Test.startTest();
            insert accountToInsert;      
            List<Contact> contactToInsert = TDdAccountFactory.createContacts(2, accountToInsert.id);
            Contact contactToInsertOne = contactToInsert[0];
            contactToInsertOne.Lead_Source_Detail__c = 'Formstack';
            contactToInsertOne.Phone = '(415) 555-1212';
            contactToInsertOne.MailingStreet = '303 2nd St';
            contactToInsertOne.MailingCity = 'San Francisco';
            contactToInsertOne.MailingState = 'CA';
            contactToInsertOne.MailingCountry = 'United States';
            contactToInsertOne.MailingPostalCode = '94107';
            contactToInsertOne.Email = 'testformstackone@doordash.com.test';
            contactToInsertOne.Language__c = 'English';
            Contact contactToInsertTwo = contactToInsert[1];
            contactToInsertTwo.Current_Sequence_User_Name__c = 'c';
            contactToInsertTwo.Phone = '(415) 555-1213';
            contactToInsertTwo.MailingStreet = '304 2nd St';
            contactToInsertTwo.MailingCity = 'San Francisco';
            contactToInsertTwo.MailingState = 'CA';
            contactToInsertTwo.MailingCountry = 'United States';
            contactToInsertTwo.MailingPostalCode = '94108';
            contactToInsertTwo.Email = 'testformstacktwo@doordash.com.test';
            contactToInsertTwo.Language__c = 'English';
            insert contactToInsert;
            Test.stopTest();
            Account accountFromDB = [SELECT Id,
                                            Name, Decision_Maker__c
                                    FROM Account
                                    WHERE Id = : accountToInsert.Id];
            Contact contactFromDB = [SELECT Id
                                    FROM Contact
                                    WHERE Email = 'testformstackone@doordash.com.test'];
            CampaignMember campMember = [SELECT Id,
                                                ContactID
                                         FROM CampaignMember
                                         where ContactID = : contactToInsertTwo.Id];
            System.assertEquals(contactFromDB.ID, accountFromDB.Decision_Maker__c,'Expecting the Decision Maker on the Account to be ' + contactFromDB.ID);                 
            System.assertEquals(contactToInsertTwo.Id, campMember.ContactID , 'Expecting to create new campaign member with contactID ' + contactToInsertTwo.Id);                           
        }
    }

    /**
    * @description BASD-28825
    */ 
    @isTest
    static void testLeadUpdatePrimaryMerchantCategory() {
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Hubspot';
        testRunUser.LastName = 'Integration User';
        testRunUser.email = 'hubspot@doordash.com.testemail';
        insert testRunUser;
        System.runAs (testRunUser) {
            Vertical_Category_Trigger_Setting__c vertCatSetting = new Vertical_Category_Trigger_Setting__c();
            vertCatSetting.Run_Update_Merchant_Categories_method__c = true;
            vertCatSetting.SetupOwnerId = testRunUser.Id;
            insert vertCatSetting;
            
            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId());
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.id)[0];
            contact.Phone = '(415) 555-1212';
            contact.MailingStreet = '303 2nd St';
            contact.MailingCity = 'San Francisco';
            contact.MailingState = 'CA';
            contact.MailingCountry = 'United States';
            contact.MailingPostalCode = '94107';
            contact.Email = 'test@doordash.com.test';
            contact.Language__c = 'English';
            insert contact;

            Campaign campaign = new Campaign(Name = 'AcqMktgTest', Title__c = 'AcqMktgTest', RecordTypeId = CDdCampaignMemberTriggerHelper.campaignWorkId);
            insert campaign;

            insert new CampaignMember(ContactId = contact.Id, CampaignId = campaign.Id);
            
            test.startTest();
            contact.Primary_Merchant_Category__c = 'Grocery';
            update contact;
            test.stopTest();
            
            List<Lead> leadList = [Select id,State,Primary_Merchant_Category__c,Created_from_Contact__c From Lead Where Created_from_Contact__c =: contact.id];
            System.assertEquals(contact.Primary_Merchant_Category__c, leadList[0].Primary_Merchant_Category__c, 'Contact State and Lead state should be same');
        }
    }

    /**
    * @description BASD-28032
    */ 
    @isTest
    static void testLeadAddressUpdate() {
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Hubspot';
        testRunUser.LastName = 'Integration User';
        testRunUser.email = 'hubspot@doordash.com.testemail';
        insert testRunUser;
        System.runAs (testRunUser) {
            Account account = TDdAccountFactory.createAccount(CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId());
            insert account;

            Contact contact = VTestUtil.createContact('Test', 'Contact', account);
            contact.Phone = '(415) 555-1212';
            contact.MailingStreet = '303 2nd St';
            contact.MailingCity = 'San Francisco';
            contact.MailingState = 'CA';
            contact.MailingCountry = 'United States';
            contact.MailingPostalCode = '94107';
            contact.Email = 'test@doordash.com.test';
            contact.Language__c = 'English';
            insert contact;

            //Insert Campaign record
            CDdContactTriggerHelper.insertCampaign();
            List<Campaign> campaign = new List<Campaign>([SELECT id, Name From Campaign Where Name =:System.label.CampaignNameMxAcqMktg]);

            insert new CampaignMember(ContactId = contact.Id, CampaignId = campaign[0].Id);
            
            test.startTest();
			contact.MailingState = 'CO';
            contact.MailingCity = 'California';
            contact.MailingStreet = '901 6nd St';
            update contact;
            test.stopTest();
            
            List<Lead> leadList = [Select id,State,Street,City,Created_from_Contact__c From Lead Where Created_from_Contact__c =: contact.id];
            System.assertEquals(contact.MailingState, leadList[0].State, 'Contact State and Lead state should be same');
            System.assertEquals(contact.MailingStreet, leadList[0].Street, 'Contact Street and Lead Street should be same');
            System.assertEquals(contact.MailingCity, leadList[0].City, 'Contact City and Lead City should be same');
        }
    }
}