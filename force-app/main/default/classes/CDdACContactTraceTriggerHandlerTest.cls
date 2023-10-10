/**
* @author Tia Xuan  
* @date 2020-10
*
* @description Test class for CDdACContactTraceTriggerHandler
*/
@isTest
public class CDdACContactTraceTriggerHandlerTest {
    
    public static final Id ACCOUNT_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE).getRecordTypeId();

    @testSetup 
    static void setup() {
        Account acc = TDdAccountFactory.createAccount(ACCOUNT_RECORDTYPE_ID);
        acc.Deck_Rank__c = 'Ace of Spades';
        insert acc;
        List<Contact> testConsList = TDdAccountFactory.createContacts(1, acc.Id);
        insert testConsList;
        List<Case> testCasesList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        insert testCasesList;
    }
    
    /**
    * @description test update case to abandonned
    */    
    @isTest
    static void testUpdateCaseToAbandonned() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Contact ctc =  [SELECT Id, Name FROM Contact WHERE accountId = :acct.Id];
        Case testCases = [SELECT Id, Subject, Status FROM Case WHERE Subject='Test Case'];
        Test.startTest();
        amazonconnect__AC_ContactTraceRecord__c rec = new amazonconnect__AC_ContactTraceRecord__c();
        rec.amazonconnect__Channel__c = 'VOICE';
        rec.amazonconnect__ContactId__c = ctc.Id;
        rec.amazonconnect__QueueEnqueueTimestamp__c = DateTime.now();
        rec.amazonconnect__Initiation_Method__c = 'INBOUND';
        rec.amazonconnect__AgentConnectedToAgentTimestamp__c = null;
        rec.Case__c = testCases.Id;
        insert rec;
        Test.stopTest();

        Case c = [select Id, Status from Case where Id =: testCases.Id];
        System.assertEquals('Abandoned', c.Status, 'Expecting case status to be Abandoned');
    }

    /**
    * @description test fill case on outbound
    */    
    @isTest
    static void testFillCaseOnOutbound() {       
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Contact ctc =  [SELECT Id, Name FROM Contact WHERE accountId =:acct.Id];
        Case testCases = [SELECT Id, Subject, Status FROM Case WHERE Subject='Test Case'];        
        Test.startTest();
        AC_Outbound_Call__c aoc = new AC_Outbound_Call__c();
        aoc.Agent_Username__c = 'test@testing.com';
        aoc.Case__c = testCases.Id;
        aoc.AC_Contact_Trace_Record__r = null;
        insert aoc;

        amazonconnect__AC_ContactTraceRecord__c rec = new amazonconnect__AC_ContactTraceRecord__c();
        rec.amazonconnect__Channel__c = 'VOICE';
        rec.amazonconnect__ContactId__c = ctc.Id;
        rec.Case__c = null;
        rec.amazonconnect__Initiation_Method__c = 'OUTBOUND';
        rec.amazonconnect__AgentUsername__c = 'test@testing.com';
        rec.amazonconnect__AfterContactWorkStartTimestamp__c = DateTime.now().addSeconds(-20);        
        insert rec;
        Test.stopTest();

        amazonconnect__AC_ContactTraceRecord__c ctr = [ SELECT Id, Case__c 
                                                        FROM amazonconnect__AC_ContactTraceRecord__c 
                                                        WHERE Id =: rec.Id];
        System.assertEquals(ctr.Case__c, testCases.Id, 'Case on Contact Track Record is not same as expected.');

        AC_Outbound_Call__c aocTest = [ SELECT Id, AC_Contact_Trace_Record__c 
                                        FROM AC_Outbound_Call__c 
                                        WHERE Id = :aoc.Id];
        System.assertEquals(aocTest.AC_Contact_Trace_Record__c, rec.Id, 'Expecting Ac contact trace record to be amazonconnect__AC_ContactTraceRecord__c Id');

    }

    /**
    * @description test fill opportunity on inbound
    */    
    @isTest
    static void testFillOpportunityOnInbound() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Contact ctc =  [SELECT Id, Name FROM Contact WHERE accountId = :acct.Id];        
        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Opp1', acct.Id, ctc.Id, 'New', 'Enterprise_Marketplace');
        opp.Proposed_Date_of_Activation__c = Date.today();
        insert opp;

        Test.startTest();
        AC_Outbound_Call__c aoc = new AC_Outbound_Call__c();
        aoc.Agent_Username__c = 'test@testing.com';
        aoc.Opportunity__c = opp.Id;
        aoc.AC_Contact_Trace_Record__r = null;
        insert aoc;

        amazonconnect__AC_ContactTraceRecord__c rec = new amazonconnect__AC_ContactTraceRecord__c();
        rec.amazonconnect__Channel__c = 'VOICE';
        rec.amazonconnect__ContactId__c = ctc.Id;
        rec.Opportunity__c = null;
        rec.amazonconnect__Initiation_Method__c = 'INBOUND';
        rec.amazonconnect__AgentUsername__c = 'test@testing.com';
        rec.amazonconnect__AfterContactWorkStartTimestamp__c = DateTime.now().addSeconds(-20);
        
        insert rec;
        Test.stopTest();

        amazonconnect__AC_ContactTraceRecord__c ctr = [ select Id, Opportunity__c 
                                                        from amazonconnect__AC_ContactTraceRecord__c 
                                                        where Id =: rec.Id];
        System.assertEquals(ctr.Opportunity__c,opp.Id,'Expecting Opportunity__c to be opportunity Id');

        AC_Outbound_Call__c aocTest = [ select Id, AC_Contact_Trace_Record__c 
                                        from AC_Outbound_Call__c 
                                        where Id =: aoc.Id];
        System.assertEquals(aocTest.AC_Contact_Trace_Record__c, rec.Id,'Expecting Ac contact trace record to be amazonconnect__AC_ContactTraceRecord__c Id');

    }

}