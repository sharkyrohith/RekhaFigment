@isTest
private with sharing class CDdPactSafeRequestTriggerHelperTest {
    private static final String QUOTE_REQUERY = 'SELECT Id,{0} FROM SBQQ__Quote__c LIMIT 1';

    private static String quoteFieldName {
        get {
            if (quoteFieldName == null){
                quoteFieldName = PSExtensionMainSettings.getRequestFieldName;
            }

            return quoteFieldName;
        }

        set;
    }

    @testSetup
    static void makeData(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Account_Validations__c = true;
        validation.Bypass_Quote_Validations__c = true;
        insert validation;

        Account testAccount = TDdCPQTestDataFactory.createAccount(true);

        CDdContactTriggerHelper.insertCampaign();
        Contact testContact = TDdCPQTestDataFactory.createContact(true);

        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, testContact.Id, true);
        TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, testContact, true);
    }

    private static SBQQ__Quote__c getQuote(){
        String quoteRequery = String.format(
            QUOTE_REQUERY,
            new List<String>{quoteFieldName}
        );
        return Database.query(quoteRequery);
    }

    @isTest
    private static void linkToQuote_nullParam_expectEmptyResult(){
        Test.startTest();
        List<SBQQ__Quote__c> results = CDdPactSafeRequestTriggerHelper.linkToQuote(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected a non-null result.');
        System.assertEquals(0, results.size(), 'Expected an empty result.');
    }

    @isTest
    private static void linkToQuote_emptyParam_expectEmptyResult(){
        Test.startTest();
        List<SBQQ__Quote__c> results = CDdPactSafeRequestTriggerHelper.linkToQuote(new List<pactsafe1__PactSafeRequest__c>());
        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected a non-null result.');
        System.assertEquals(0, results.size(), 'Expected an empty result.');
    }

    @isTest
    private static void linkToQuote_quoteUnlinked_expectQuoteLinked(){
        SBQQ__Quote__c testQuote = getQuote();
        testQuote.put(quoteFieldName, null);
        update testQuote;

        pactsafe1__PactSafeRequest__c withUnlinkedQuote = TDdCPQTestDataFactory.createPSRequest(testQuote.Id, false);

        Test.startTest();
        insert withUnlinkedQuote;
        Test.stopTest();

        SBQQ__Quote__c finalQuote = getQuote();
        System.assertNotEquals(null, finalQuote, 'Expected a non-null quote');

        Id linkedToId = (Id)finalQuote.get(quoteFieldName);
        System.assertNotEquals(linkedToId, null, 'Expected the Quote to be linked to *something*.');
        System.assertEquals(linkedToId, withUnlinkedQuote.Id, 'Expect Quote linked to newly inserted PSRequest.');
    }

    @isTest
    private static void linkToQuote_quoteAlreadyLinked_expectQuoteLinked(){
        SBQQ__Quote__c testQuote = getQuote();
        pactsafe1__PactSafeRequest__c preexistingRequest = TDdCPQTestDataFactory.createPSRequest(testQuote.Id, true);

        testQuote.put(quoteFieldName, preexistingRequest.Id);
        update testQuote;

        pactsafe1__PactSafeRequest__c withLinkedQuote = TDdCPQTestDataFactory.createPSRequest(testQuote.Id, false);

        Test.startTest();
        insert withLinkedQuote;
        Test.stopTest();

        SBQQ__Quote__c finalQuote = getQuote();
        System.assertNotEquals(null, finalQuote, 'Expected a non-null quote');

        Id linkedToId = (Id)finalQuote.get(quoteFieldName);
        System.assertNotEquals(linkedToId, null, 'Expected the Quote to be linked to *something*.');
        System.assertEquals(linkedToId, withLinkedQuote.Id, 'Expect Quote linked to newly inserted PSRequest.');
    }
}