@isTest
public class CDdOpportunityTriggerAdditionalTest {

    public static void setGDPROff(){
        //GDPR
        CDdGDPREmailHelper.ENABLE_CREATE_CONTACT = false;
        CDdGDPREmailHelper.ENABLE_SUBSCRIPTION = false;
        CDdGDPREmailHelper.ENABLE_DELIGHTED_TASK = false;
    }

    @isTest(SeeAllData=true)
    static void testInsertWithFormStackOpportunitySuccess() {

        //GDPR
        setGDPROff();
        
        // // login to FS integration user
        // // create lead
        // // create account
        Id leadId;
        Id acctId;
        List<UserRole> roleIds = [select Id from UserRole where DeveloperName = 'COO']; 
        List<User> selfServiceUsers = TDdAccountFactory.createUsers(2, null, roleIds[0].id);
        selfServiceUsers[0].LastName = 'formstackTestUser';
        insert selfServiceUsers;
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>(); 
        PermissionSetAssignment psa; 
        for(User selfServiceUser : selfServiceUsers){
            psa = new PermissionSetAssignment(); 
            psa.PermissionSetId = '0PS1a0000001bYE' ;
            psa.AssigneeId = selfServiceUser.id; 
            psas.add(psa);
        }
        insert psas;
        String TEST_STORE_ID = '12345678'; 
        List<Self_Serve_Users__c> selfServeUsersSettings = Self_Serve_Users__c.getAll().values(); 
        Self_Serve_Users__c ssUser; 
        
        System.runAs(selfServiceUsers[0]) {
            CDdContactTriggerHelper.insertCampaign();
            CDdAccountHelperMethods.testingAccountFormStack = false;  
            Lead ld = VTestUtil.createLead('Test', 'Lead', true);
            ld.Street = '123 Main St';
            insert ld;
            leadId = ld.Id;
            Account acct = VTestUtil.createFormstackAccount('Test Account');
            acct.BillingStreet = '123 Main Street';
            acct.formstack_version__c = 'Local';
            acct.Restaurant_ID__c = TEST_STORE_ID;
            insert acct;
            Opportunity opportunity = VTestUtil.createOpportunity('Test Opp', acct);
            opportunity.Formstack_Store_ID__c = TEST_STORE_ID;
            opportunity.AccountId = acct.Id;
            opportunity.Menu_to_be_completed_by__c = null;
            opportunity.Menu_Setup_Method__c =  null;
            opportunity.Tablet_Kit_Type__c = null;
            insert opportunity;

            // acctId = acct.Id;
        }
        Test.startTest();
        Lead ldFromQuery = [SELECT Id, Status, IsConverted, Auto_Conversion_Failed__c FROM Lead WHERE Id = :leadId];
        System.assert(!ldFromQuery.Auto_Conversion_Failed__c);
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    static void testInsertWithFormStackOpportunityDuplicateLeadSuccess() {

        //GDPR
        setGDPROff();

        // // login to FS integration user
        // // create lead
        // // create account
        Id leadId;
        Id acctId;
        List<UserRole> roleIds = [select Id from UserRole where DeveloperName = 'COO']; 
        List<User> selfServiceUsers = TDdAccountFactory.createUsers(2, null, roleIds[0].id);
        selfServiceUsers[0].LastName = 'formstackTestUser';
        insert selfServiceUsers; 
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>(); 
        PermissionSetAssignment psa; 
        for(User selfServiceUser : selfServiceUsers){
            psa = new PermissionSetAssignment(); 
            psa.PermissionSetId = '0PS1a0000001bYE' ;
            psa.AssigneeId = selfServiceUser.id; 
            psas.add(psa);
        }
        insert psas;
        String TEST_STORE_ID = '12345678'; 

        List<Self_Serve_Users__c> selfServeUsers = Self_Serve_Users__c.getAll().values(); 
        Self_Serve_Users__c ssUser; 
        System.runAs(selfServiceUsers[0]) {
            CDdAccountHelperMethods.testingAccountFormStack = false;  
            
            List<Lead> leadsToInsert = TDdLeadFactory.createLeads('FormstackLeads', 2, false);
            Lead tempLead = leadsToInsert[0];
            leadsToInsert[1].phone = TDdAccountFactory.getRandom(); 
            leadsToInsert[1].email = 'test@thisisfake.com';
            leadsToInsert[1].Store_Id__c = null;
            leadsToInsert[1].smartystreets__Address_Last_Verified__c = Date.today();
            tempLead.phone = leadsToInsert[1].phone; 
            tempLead.Street = leadsToInsert[1].Street; 
            tempLead.PostalCode = leadsToInsert[1].PostalCode;
            tempLead.email = leadsToInsert[1].email;
            tempLead.Store_Id__c = leadsToInsert[1].Store_Id__c;
            tempLead.smartystreets__Address_Last_Verified__c = leadsToInsert[1].smartystreets__Address_Last_Verified__c;
            leadsToInsert[0] = tempLead;
            VTestUtil.allowDuplicates(); 
            Insert leadsToInsert;    
            System.debug('Leads to insert size = ' + leadsToInsert.size()); 

            leadId = leadsToInsert[0].Id;
        
            Test.startTest(); 
            CDdAccountHelperMethods.testingAccountFormStack = false;          
            // leadId = ld.Id;
            Account acct = VTestUtil.createFormstackAccount('Test Account');
            acct.Formstack_Email__c = tempLead.email;
            acct.Formstack_Mobile_Phone__c = tempLead.phone; 
            acct.formstack_version__c = 'Local';
            acct.Restaurant_ID__c = TEST_STORE_ID;
            insert acct;

            Opportunity opportunity = VTestUtil.createOpportunity('Test Opp', acct);
            opportunity.Formstack_Store_ID__c = TEST_STORE_ID;
            opportunity.AccountId = acct.Id;
            opportunity.Menu_to_be_completed_by__c = null;
            opportunity.Menu_Setup_Method__c =  null;
            opportunity.Tablet_Kit_Type__c = null;
            insert opportunity;
            Test.stopTest();
        }

        Lead ldFromQuery = [SELECT Id, Status, IsConverted, Auto_Conversion_Failed__c FROM Lead WHERE Id = :leadId];
        System.assert(!ldFromQuery.Auto_Conversion_Failed__c);

    }

    @isTest(SeeAllData=true)
    static void testInsertWithFormStackDuplicateLeadSuccess() {

        //GDPR
        setGDPROff();

        // // login to FS integration user
        // // create lead
        // // create account
        Id leadId;
        Id acctId;
        List<UserRole> roleIds = [select Id from UserRole where DeveloperName = 'COO']; 
        List<User> selfServiceUsers = TDdAccountFactory.createUsers(2, null, roleIds[0].id);
        selfServiceUsers[0].LastName = 'formstackTestUser';
        insert selfServiceUsers; 
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>(); 
        PermissionSetAssignment psa; 
        for(User selfServiceUser : selfServiceUsers){
            psa = new PermissionSetAssignment(); 
            psa.PermissionSetId = '0PS1a0000001bYE' ;
            psa.AssigneeId = selfServiceUser.id; 
            psas.add(psa);
        }
        insert psas;
        List<Self_Serve_Users__c> selfServeUsers = Self_Serve_Users__c.getAll().values(); 
        Self_Serve_Users__c ssUser;
        String TEST_STORE_ID = '12345678'; 

        System.runAs(selfServiceUsers[0]) {
            CDdAccountHelperMethods.testingAccountFormStack = false;  
            
            List<Lead> leadsToInsert = TDdLeadFactory.createLeads('FormstackLeads', 2, false);
            Lead tempLead = leadsToInsert[0];
            leadsToInsert[1].phone = TDdAccountFactory.getRandom(); 
            leadsToInsert[1].email = 'test@thisisfake.com';
            leadsToInsert[1].Store_Id__c = null;
            leadsToInsert[1].smartystreets__Address_Last_Verified__c = Date.today();
            tempLead.phone = leadsToInsert[1].phone; 
            tempLead.Street = leadsToInsert[1].Street; 
            tempLead.PostalCode = leadsToInsert[1].PostalCode;
            tempLead.email = leadsToInsert[1].email;
            tempLead.Store_Id__c = leadsToInsert[1].Store_Id__c;
            tempLead.smartystreets__Address_Last_Verified__c = leadsToInsert[1].smartystreets__Address_Last_Verified__c;
            leadsToInsert[0] = tempLead;
            VTestUtil.allowDuplicates(); 
            Insert leadsToInsert;    
            System.debug('Leads to insert size = ' + leadsToInsert.size()); 
            leadId = leadsToInsert[0].Id;
        
            Test.startTest();            
            // leadId = ld.Id;
            Account acct = VTestUtil.createFormstackAccount('Test Account');
            acct.Formstack_Email__c = tempLead.email;
            acct.Formstack_Mobile_Phone__c = tempLead.phone; 
            acct.formstack_version__c = 'Local';
            insert acct;

            Opportunity opportunity = VTestUtil.createOpportunity('Test Opp', acct);
            opportunity.Formstack_Store_ID__c = TEST_STORE_ID;
            opportunity.AccountId = acct.Id;
            opportunity.Menu_to_be_completed_by__c = null;
            opportunity.Menu_Setup_Method__c =  null;
            opportunity.Tablet_Kit_Type__c = null;
            insert opportunity;
            Test.stopTest();
        } 

        Lead ldFromQuery = [SELECT Id, Status, IsConverted, Auto_Conversion_Failed__c FROM Lead WHERE Id = :leadId];
        System.assert(!ldFromQuery.Auto_Conversion_Failed__c);
    }

    @isTest
    static void testAlcoholAddendumSigned() {

        Test.startTest();
           
        RealZip__RealZips__c realZipRec = new RealZip__RealZips__c(Submarket_ID__c = 10);
        realZipRec.Alcohol_Eligibility__c ='Marketplace; Self Delivery; Pickup';
        insert realZipRec; 
            
        List<Account> accounts = TDdAccountFactory.createAccounts('Account', 2);
        accounts[0].RealZip__RealZip__c = realZipRec.Id;
        accounts[0].Phone = '1231231234';
        accounts[0].Legal_Business_Name__c = 'Test Business';
		accounts[0].BillingStreet = '1231231234 Victory Blvd';
		accounts[0].BillingCity = 'Los Angeles';
		accounts[0].BillingState = 'CA';
		accounts[0].BillingPostalCode = '91367';
	    accounts[0].BillingCountryCode = 'US';
		accounts[0].EIN_Encrypted__c = '123456789';
        
        accounts[1].RealZip__RealZip__c = realZipRec.Id;
        accounts[1].Phone = '2342342341';
        accounts[1].Legal_Business_Name__c = 'Test Business';
		accounts[1].BillingStreet = '2342342341 Victory Blvd';
		accounts[1].BillingCity = 'Los Angeles';
		accounts[1].BillingState = 'CA';
		accounts[1].BillingPostalCode = '91367';
	    accounts[1].BillingCountryCode = 'US';
		accounts[1].EIN_Encrypted__c = '987654321';
        
        insert accounts;
        
        List<Contact> contacts = new List<Contact>();
        Contact contact1 = TDdAccountFactory.createContacts(1, accounts[0].Id)[0];
        contact1.firstName = 'TestCon1';
        contact1.LastName = 'TestCon1'; 
        contact1.Email = '1testCon@dd.com';
        contact1.Birthdate = Date.newInstance(1990, 9, 29);
        contact1.Personal_ID_Number__c = '1234';
        
        Contact contact2 = TDdAccountFactory.createContacts(1, accounts[1].Id)[0];
        contact2.firstName = 'TestCon2';
        contact2.LastName = 'TestCon2'; 
        contact2.Email = '2testCon@dd.com';
        contact2.Birthdate = Date.newInstance(1991, 9, 29);
        contact2.Personal_ID_Number__c = '4321';
        
        contacts.add(contact1);
        contacts.add(contact2);
        insert contacts;
	    
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = TDdOpportunityFactory.createOpportunity('ClosedWonOpp1', accounts[0].id, contacts[0].id, 'Closed Won');
        opp1.Commission__c = 0;
        opp1.Trial_Type__c = 'Free Trial';
        opp1.Trial_Commission__c = 10;
        opp1.Manager_Package_Override__c = 'Plus';
        opp1.Length_of_Trial__c = '7 Days';
        
        
        Opportunity opp2 = TDdOpportunityFactory.createOpportunity('ClosedWonOpp2', accounts[1].id, contacts[1].id, 'Closed Won');
        opp2.Commission__c = 0;
        opp2.Trial_Type__c = 'Free Trial';
        opp2.Trial_Commission__c = 10;
        opp2.Manager_Package_Override__c = 'Plus';
        opp2.Length_of_Trial__c = '7 Days';
        opp2.Product_IDs__c = Label.DdAlcohol_Product_ID;
        
        oppList.add(opp1);
        oppList.add(opp2);
        insert oppList; 
        
        Account account1 = [Select Id,Name,Alcohol_Addendum_Signed__c from Account Where Id=:accounts[0].Id];
        System.assertEquals(false, account1.Alcohol_Addendum_Signed__c);
        
        Account account2 = [Select Id,Name,Alcohol_Addendum_Signed__c from Account Where Id=:accounts[1].Id];
        System.assertEquals(true, account2.Alcohol_Addendum_Signed__c);
        
        Test.stopTest();
    }

    /**
     * BZAP-16703 - For Bbot Only opportunity, the Opp runs an asynchronous @future call to move the
     * Opp to Closed Won
     * Nathalie Mendezona
     */
    @isTest
    static void testBbotContractSignedAutoMoveToCloseWon() {
        User pactsafeUser = [SELECT Id FROM User WHERE alias = 'psafe'];

        // insert Product
        Product2 bbotProduct = new Product2(Name = 'Test Bbot Product', Family = 'Bbot');
        insert bbotProduct;
        
        // insert PricebookEntry
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = bbotProduct.Id,
                    UnitPrice = 0,
                    IsActive = true
        );
        insert pbe;
        Opportunity opp;
        Account acct = TDdAccountFactory.createAccounts('Test Account', 1, 'Marketplace')[0];
        insert acct;
        
        System.runAs(pactsafeUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Opportunity_Product_Validations__c = true;
            insert validation;
            
            Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
            opp = TDdOpportunityFactory.createOpportunityByDevRT('Bbot Opp', acct.Id, contact.Id, CDdOpportunityTriggerHelper.STAGE_NAME_MEETING_RAN_NEGOTIATED, 'ML_Inside_Sales');
            opp.Tablet_Delivery_Method__c = null;
            opp.Tablet_Kit_Type__c = null;
            opp.Has_Bbot_Product__c = true;   // Setting this to true manually because the point of the test is not to test OLI trigger         
            opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opp.Menu_Setup_Method__c = 'Create New Menu(s) using Menu Source';
            insert opp;
            OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = 1, UnitPrice = 1);
            insert oli;
            CDdOpportunityTriggerHelper.ranUpdateOppAsynchronous = false;
            opp.StageName = CDdOpportunityTriggerHelper.STAGE_NAME_CONTRACT_SIGNED;
            Test.startTest();
            update opp;
            Test.stopTest();
        }
        Opportunity oppVerify = [SELECT Id, StageName FROM Opportunity WHERE Id =: opp.Id];
        System.assertEquals(CDdOpportunityTriggerHelper.STAGE_NAME_CLOSED_WON, oppVerify.StageName);
    }

    /**
     * BZAP-16703 - For Bbot + MP opportunity, the Opp should NOT run the asynchronous @future call to move the
     * Opp to Closed Won, because there is a Marketplace product on the opp
     * Nathalie Mendezona
     */
    @isTest
    static void testBbotContractSignedDoNOTAutoMoveToCloseWon() {
        User pactsafeUser = [SELECT Id FROM User WHERE alias = 'psafe'];

        // insert Products
        List<Product2> products = new List<Product2>();
        Product2 bbotProduct = new Product2(Name = 'Test Bbot Product', Family = 'Bbot');
        products.add(bbotProduct);
        Product2 nonbbotProduct = new Product2(Name = 'Test Other Product', Family = 'Marketplace');
        products.add(nonbbotProduct);
        insert products;

        // insert PricebookEntries
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = bbotProduct.Id,
                    UnitPrice = 0,
                    IsActive = true
        );
        pbes.add(pbe);
        PricebookEntry pbe2 = new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = nonbbotProduct.Id,
                    UnitPrice = 0,
                    IsActive = true
        );
        pbes.add(pbe2);
        insert pbes;
        
        Opportunity opp;
        Account acct = TDdAccountFactory.createAccounts('Test Account', 1, 'Marketplace')[0];
        insert acct;
        System.runAs(pactsafeUser) {
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Opportunity_Product_Validations__c = true;
            insert validation;
            Contact contact = TDdAccountFactory.createContacts(1, acct.Id)[0];  insert contact;
            opp = TDdOpportunityFactory.createOpportunityByDevRT('Bbot Opp', acct.Id, contact.Id, CDdOpportunityTriggerHelper.STAGE_NAME_MEETING_RAN_NEGOTIATED, 'ML_Inside_Sales');
            opp.Tablet_Delivery_Method__c = null;
            opp.Tablet_Kit_Type__c = null;
            opp.Has_Bbot_Product__c = true; // Setting this to true manually because the point of the test is not to test OLI trigger         
            opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opp.Menu_Setup_Method__c = 'Create New Menu(s) using Menu Source';
            insert opp;

            List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
            OpportunityLineItem bbotoli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = 1, UnitPrice = 1);
            olis.add(bbotoli);
            OpportunityLineItem nonBbotoli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe2.Id, Product2Id = pbe2.Product2Id, Quantity = 1, UnitPrice = 1);
            olis.add(nonBbotoli);
            insert olis;

            opp.StageName = CDdOpportunityTriggerHelper.STAGE_NAME_CONTRACT_SIGNED;
            CDdOpportunityTriggerHelper.ranUpdateOppAsynchronous = false;
            Test.startTest();
            update opp;
            Test.stopTest();
        }
        Opportunity oppVerify = [SELECT Id, StageName FROM Opportunity WHERE Id =: opp.Id];
        System.assertNotEquals(CDdOpportunityTriggerHelper.STAGE_NAME_CLOSED_WON, oppVerify.StageName);
    }

    @isTest
    static void testPrimaryAccount() {

        RealZip__RealZips__c realZipRec = new RealZip__RealZips__c(Submarket_ID__c = 10);
        realZipRec.Alcohol_Eligibility__c ='Marketplace; Self Delivery; Pickup';
        insert realZipRec;
            
        List<Account> accounts = TDdAccountFactory.createAccounts('Account', 2);
        accounts[0].RealZip__RealZip__c = realZipRec.Id;
        accounts[0].Phone = '1231231234';
        accounts[0].Legal_Business_Name__c = 'Test Business';
        accounts[0].BillingStreet = '1231231234 Victory Blvd';
        accounts[0].BillingCity = 'Los Angeles';
        accounts[0].BillingState = 'CA';
        accounts[0].BillingPostalCode = '91367';
        accounts[0].BillingCountryCode = 'US';
        accounts[0].EIN_Encrypted__c = '123456789';
        
        accounts[1].RealZip__RealZip__c = realZipRec.Id;
        accounts[1].Phone = '2342342341';
        accounts[1].Legal_Business_Name__c = 'Test Business';
        accounts[1].BillingStreet = '2342342341 Victory Blvd';
        accounts[1].BillingCity = 'Los Angeles';
        accounts[1].BillingState = 'CA';
        accounts[1].BillingPostalCode = '91367';
        accounts[1].BillingCountryCode = 'US';
        accounts[1].EIN_Encrypted__c = '987654321';
        
        insert accounts;
        
        List<Contact> contacts = new List<Contact>();
        Contact contact1 = TDdAccountFactory.createContacts(1, accounts[0].Id)[0];
        contact1.firstName = 'TestCon1';
        contact1.LastName = 'TestCon1'; 
        contact1.Email = '1testCon@dd.com';
        contact1.Birthdate = Date.newInstance(1990, 9, 29);
        contact1.Personal_ID_Number__c = '1234';
        
        Contact contact2 = TDdAccountFactory.createContacts(1, accounts[1].Id)[0];
        contact2.firstName = 'TestCon2';
        contact2.LastName = 'TestCon2'; 
        contact2.Email = '2testCon@dd.com';
        contact2.Birthdate = Date.newInstance(1991, 9, 29);
        contact2.Personal_ID_Number__c = '4321';
        
        contacts.add(contact1);
        contacts.add(contact2);
        insert contacts;
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = TDdOpportunityFactory.createOpportunity('ClosedWonOpp1', accounts[0].id, contacts[0].id, 'Closed Won');
        opp1.Commission__c = 0;
        opp1.Trial_Type__c = 'Free Trial';
        opp1.Trial_Commission__c = 10;
        opp1.Manager_Package_Override__c = 'Plus';
        opp1.Length_of_Trial__c = '7 Days';         
        
        oppList.add(opp1);
        insert oppList;
        
        Test.starttest();
            List<sObject> pas1 = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            opp1.Payment_Account__c = pas1[0].Id;
            update opp1;
        Test.stopTest();
        
        system.assertEquals([SELECT Id, Primary_Opportunity__c FROM Payment_Account__c LIMIT 1].Primary_Opportunity__c, opp1.Id);
        
    }
}