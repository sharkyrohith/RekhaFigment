@isTest
public with sharing class NetSuiteAccountCreatorControllerTest {
    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String oppCorpRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Corporate').getRecordTypeId();
    public static final String oppDDFBRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('DoorDash for Business').getRecordTypeId();
    public static final List<String> accountNames = new List<String> {
        'NSCallout_no_update',
        'NSCallout_update',
        'NSCallout_QExc',
        'NSCallout_update_ddfb',
        'NSCallout_update_marketplace'
    };
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;        
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
    @TestSetup
    static void createSetupData(){
        System.runAs(getTestRunUser()){
            Test.startTest();

            List<sObject> configs = Test.loadData(OAuth_Config__c.sObjectType, 'OAuth_Config_NS');
            List<sObject> pas1 = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            List<sObject> pas2 = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            List<sObject> pas3 = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            List<sObject> pas4 = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            List<sObject> pas5 = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            List<sObject> pas6 = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            List<Account> accs = TDdAccountFactory.createAccounts('person account LastName', 5);
            accs[0].Name = accountNames[0];
            accs[0].Primary_Payment_Account__c = pas1[0].Id;
            accs[1].Name = accountNames[1];
            accs[2].Name = accountNames[2];
            accs[3].Name = accountNames[3];
            accs[4].Name = accountNames[4];
            insert accs;
            List<Contact> contacts = TDdAccountFactory.createContacts(5, null);
            contacts[0].AccountId = accs[0].Id;
            contacts[1].AccountId = accs[1].Id;
            contacts[2].AccountId = accs[2].Id;
            contacts[3].AccountId = accs[3].Id;
            contacts[4].AccountId = accs[4].Id;
            insert contacts;           
            List<Opportunity> opps = new List<Opportunity> {
                TDdOpportunityFactory.createOpportunityByDevRT('TestOpp0', accs[0].Id, contacts[0].Id, 'Contract Signed', 'Corporate'),
                TDdOpportunityFactory.createOpportunityByDevRT('TestOpp1', accs[1].Id, contacts[1].Id, 'Contract Signed', 'Corporate'),
                TDdOpportunityFactory.createOpportunityByDevRT('TestOpp2', accs[2].Id, contacts[2].Id, 'Contract Signed', 'Enterprise_Marketplace'),
                TDdOpportunityFactory.createOpportunityByDevRT('TestOpp3', accs[3].Id, contacts[3].Id, 'Contract Signed', 'DoorDash_for_Business'),
                TDdOpportunityFactory.createOpportunityByDevRT('TestOpp3', accs[3].Id, contacts[3].Id, 'Contract Signed', 'ML_Inside_Sales')
            };
            opps[0].Payment_Account__c = pas2[0].Id;
            opps[0].CloseDate = system.today().addDays(1);
            opps[0].PactSafe_Record__c = null;
            opps[0].Menu_to_be_completed_by__c = null;
            opps[0].Menu_Setup_Method__c =  null;
            opps[0].Tablet_Kit_Type__c = null;

            opps[1].Payment_Account__c = pas3[0].Id;
            opps[1].CloseDate = system.today().addDays(1);
            opps[1].Menu_to_be_completed_by__c = null;
            opps[1].Menu_Setup_Method__c =  null;
            opps[1].Tablet_Kit_Type__c = null;

            opps[2].Payment_Account__c = pas4[0].Id;
            opps[2].CloseDate = system.today().addDays(1);
            opps[2].PactSafe_Record__c = 'fsfds5ddsfds6ys';
            opps[2].Menu_to_be_completed_by__c = null;
            opps[2].Menu_Setup_Method__c =  null;
            opps[2].Tablet_Kit_Type__c = null;

            opps[3].Payment_Account__c = pas5[0].Id;
            opps[3].Payment_Protocol__c = 'Invoicing';
            opps[3].CloseDate = system.today().addDays(1); 
            opps[3].PactSafe_Record__c = null;
            opps[3].Menu_to_be_completed_by__c = null;
            opps[3].Menu_Setup_Method__c =  null;
            opps[3].Tablet_Kit_Type__c = null;

            opps[4].Payment_Account__c = pas6[0].Id;
            opps[4].Payment_Protocol__c = 'Invoicing';
            opps[4].CloseDate = system.today().addDays(1); 
            opps[4].PactSafe_Record__c = null;
            opps[4].Menu_to_be_completed_by__c = null;
            opps[4].Menu_Setup_Method__c =  null;
            opps[4].Tablet_Kit_Type__c = null;
            opps[4].Legal_Entity__c = 'US - G&C';

            insert opps;

            Test.stopTest();
        }
    }
    @isTest
    static void testCreateNetSuiteAccountSuccess(){
        System.runAs(getTestRunUser()){
            List<Opportunity> opps = [SELECT Id, Payment_Account__c, Account.Primary_Payment_Account__c 
                                        FROM Opportunity WHERE Account.Name IN :accountNames];
            Map<Id, String> messages = new Map<Id, String>();
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new NSAccountCreationResponseGenerator.MockSuccess());
            for(Opportunity opp: opps){
                messages.put(opp.Id, NetSuiteAccountCreatorController.createNetSuiteAccount(opp.Payment_Account__c));
            }
            Test.stopTest();
            List<Opportunity> testOpps = [SELECT Id, Account.Name, Payment_Account__c, 
                                        Payment_Account__r.NetSuite_ID__c, Account.Primary_Payment_Account__c 
                                        FROM Opportunity WHERE Id IN :opps];
            for(Opportunity opp: testOpps){
                if(opp.Account.Name == accountNames[1]){
                    system.assertEquals(true, messages.get(opp.Id).contains(NetSuiteAccountCreatorController.successMessage));
                    system.assertNotEquals('5678656', opp.Payment_Account__r.NetSuite_ID__c);
                }
                if(opp.Account.Name == accountNames[0]){
                    system.assertEquals(true, messages.get(opp.Id).contains(NetSuiteAccountCreatorController.successMessage));
                    system.assertEquals('5678656', opp.Payment_Account__r.NetSuite_ID__c);
                    system.assertNotEquals(opp.Payment_Account__c, opp.Account.Primary_Payment_Account__c);
                }
                if(opp.Account.Name == accountNames[2]){
                    system.assertEquals(true, messages.get(opp.Id).contains(NetSuiteAccountCreatorController.queryExceptionMessage));
                }
                if(opp.Account.Name == accountNames[3]){
                    system.assertEquals(true, messages.get(opp.Id).contains(NetSuiteAccountCreatorController.successMessage));
                    system.assertNotEquals('5678656', opp.Payment_Account__r.NetSuite_ID__c);
                    system.assertNotEquals(opp.Payment_Account__c, opp.Account.Primary_Payment_Account__c);
                }
                if(opp.Account.Name == accountNames[4]){
                    system.assertEquals(true, messages.get(opp.Id).contains(NetSuiteAccountCreatorController.successMessage));
                    system.assertNotEquals('5678656', opp.Payment_Account__r.NetSuite_ID__c);
                    system.assertNotEquals(opp.Payment_Account__c, opp.Account.Primary_Payment_Account__c);
                }      
            }
        }
    }
    @isTest
    static void testCreateNetSuiteAccountFailure(){
        System.runAs(getTestRunUser()){
            List<Opportunity> opps = [SELECT Id, Payment_Account__c, Account.Primary_Payment_Account__c 
                                        FROM Opportunity WHERE Account.Name = :accountNames[0]];
            Map<Id, String> messages = new Map<Id, String>();
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new NSAccountCreationResponseGenerator.MockFailure());
            for(Opportunity opp: opps){
                messages.put(opp.Id, NetSuiteAccountCreatorController.createNetSuiteAccount(opp.Payment_Account__c));
            }
            Test.stopTest();
            List<Payment_Account__c> testPymtAccts = [SELECT Id, Netsuite_Fail_Response__c, Netsuite_Success_Status__c 
                                                        FROM Payment_Account__c 
                                                        WHERE Id = :opps[0].Payment_Account__c];
            for(Payment_Account__c testPymtAcct: testPymtAccts){
                system.assertEquals(true, testPymtAcct.Netsuite_Success_Status__c.contains('Failed'));
            }
        }
    }    
}