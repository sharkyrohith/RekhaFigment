@isTest
public class CDdCloneOppAndQuoteTest {
    @testSetup
    static void setup(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Account_Validations__c = true;
        validation.Bypass_Quote_Validations__c = true;
        insert validation;

        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;

        List<Account> parentAccounts = TDdAccountFactory.createAccounts('ParentAccount', 2);

        Id parentRecordTypeId =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
        for(Account currentAccount : parentAccounts){
            currentAccount.RecordTypeId = parentRecordTypeId;
        }
        parentAccounts[1].Name = 'other_parent';
        insert parentAccounts;
        Account parentAccount = parentAccounts[0]; // main parent account

        List<Account> childAccounts = TDdAccountFactory.createAccounts('childAccount', 3);
        childAccounts[0].ParentId = parentAccount.Id;
        childAccounts[1].ParentId = parentAccount.Id;
        childAccounts[0].Ultimate_Parent_Account__c = parentAccount.Id;
        childAccounts[1].Ultimate_Parent_Account__c = parentAccount.Id;
        childAccounts[0].Restaurant_ID__c = '1';
        childAccounts[1].Restaurant_ID__c = '2';
        childAccounts[2].Restaurant_ID__c = '3';
        insert childAccounts;

        Account CurrencyMismatchAccount = TDdAccountFactory.createAccounts('CurrencyMismatchAccount', 1)[0];
        CurrencyMismatchAccount.CurrencyISOCode='AUD';
        insert CurrencyMismatchAccount;

        List<Contact> contacts = new List<Contact>{
            TDdAccountFactory.createContacts(1, parentAccount.Id)[0],
            TDdAccountFactory.createContacts(1, childAccounts[0].Id)[0],
            TDdAccountFactory.createContacts(1, childAccounts[1].Id)[0]
        };
        insert contacts;

        childAccounts[0].Decision_Maker__c = contacts[1].Id;
        childAccounts[1].Decision_Maker__c = contacts[2].Id;
        childAccounts[0].Ultimate_Parent_Account__c = parentAccount.Id;
        childAccounts[1].Ultimate_Parent_Account__c = parentAccount.Id;
        childAccounts[2].Ultimate_Parent_Account__c = parentAccounts[1].Id;
        update childAccounts;

        Opportunity sourceOpp = TDdCpqTestDataFactory.createOpportunityByDevRT('SourceOpp', childAccounts[0].Id, contacts[1].Id, 'Closed Won', 'ML_Inside_Sales',false);
        sourceOpp.Bulk_Activation__c = true;
        insert sourceOpp;
        Test.StartTest();
        List<Product2> products = new List<Product2>{
            TDdCpqTestDataFactory.createProduct(false),
            TDdCpqTestDataFactory.createProduct(false)
        };
        insert products;

        List<PricebookEntry> pbes = new List<PricebookEntry>{
            TDdCpqTestDataFactory.createPriceBookEntry(products[0], 'USD', false),
            TDdCpqTestDataFactory.createPriceBookEntry(products[1], 'USD', false)
        };
        insert pbes;

        OpportunityLineItem oli1 = TDdCpqTestDataFactory.createOpportunityLineItem(sourceOpp.Id, products[0].Id, pbes[0].Id, true);
        OpportunityLineItem oli2 = TDdCpqTestDataFactory.createOpportunityLineItem(sourceOpp.Id, products[1].Id, pbes[1].Id, false);
        oli2.SBQQ__ParentId__c = oli1.Id;
        insert oli2;

        SBQQ__Quote__c sourceQuote = TDdCpqTestDataFactory.createQuote(sourceOpp, childAccounts[0], contacts[1], false);
        sourceQuote.ApprovalStatus__c = 'Approved';
        insert sourceQuote;
        sourceQuote.SBQQ__Status__c = 'Contract Signed';
        SBQQ.TriggerControl.disable();

        SBQQ__QuoteLine__c parentQL =  TDdCpqTestDataFactory.createQuoteLine(products[0], sourceQuote, false);
        parentQL.SBQQ__PricebookEntryId__c = pbes[0].Id;
        parentQL.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        insert parentQL;

        SBQQ__QuoteLine__c childQL =  TDdCpqTestDataFactory.createQuoteLine(products[1], sourceQuote, false);
        childQL.SBQQ__RequiredBy__c = parentQL.Id;
        childQL.SBQQ__PricebookEntryId__c = pbes[1].Id;
        childQL.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        insert childQL;

        sourceQuote.SBQQ__Ordered__c = true;
        update sourceQuote;

        SBQQ.TriggerControl.enable();

        oli1.SBQQ__QuoteLine__c = parentQL.Id;
        oli1.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;

        oli2.SBQQ__QuoteLine__c = childQL.Id;
        oli2.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;

        List<OpportunityLineItem> oppLines = new List<OpportunityLineItem>{oli1,oli2};
        update oppLines;

        Test.stopTest();
    }

    private static Opportunity getOpportunity(){
        return [
            SELECT Id, AccountId, SBQQ__PrimaryQuote__c, Name, Bulk_Activation__c, StageName, Account.Primary_Merchant_Categories__c
            FROM Opportunity LIMIT 1
        ];
    }

    private static SBQQ__Quote__c getQuote(){
        return [
            SELECT Id, SBQQ__Status__c, ApprovalStatus__c,
                (
                    SELECT Id, SBQQ__Source__c
                    FROM SBQQ__LineItems__r
                )
            FROM SBQQ__Quote__c
            LIMIT 1
        ];
    }

    private static Account getOtherParentAccount(){
        return getAccountByName('other_parent');
    }


    private static Account getAccountByName(String byName){
        return [
            SELECT Id, Restaurant_ID__c, Currently_Active__c, Is_Partner__c, Ultimate_Parent_Account__c,Primary_Merchant_Categories__c
            FROM Account WHERE Name = :byName
        ];
    }

    private static Opportunity queryClonedOpportunity(Id opportunityId){
        return [
            SELECT Id, isCloned__c, AccountId, Account.ParentId, SBQQ__PrimaryQuote__c, StageName, Name
            FROM Opportunity
            WHERE Id != :opportunityId LIMIT 1
        ];
    }

    private static List<OpportunityLineItem> getOpportunityLineItems(){
        return [
            SELECT Id, Price_Basis__c, Final_Fee__c, ListPrice FROM OpportunityLineItem
        ];
    }

    private static List<SBQQ__QuoteLine__c> getQuoteLines(){
        return [
            SELECT Id, Price_Basis__c, Final_Fee__c, SBQQ__ListPrice__c FROM SBQQ__QuoteLine__c
        ];
    }

    @isTest
    public static void testCloneOppAndQuoteBatch(){
        Opportunity sourceOpp = getOpportunity();
        SBQQ__Quote__c sourceQuote =  getQuote();

        List<CDdCloneOppAndQuote.AccountReturn> accountsForClone = CDdCloneOppAndQuote.getRelatedAccounts(String.valueOf(sourceOpp.Id));
        System.assertEquals(1,accountsForClone.size(), 'The correct number of related stores for cloning were not returned');
        System.assertEquals('False',accountsForClone[0].CurrentlyActive, 'CurrentlyActive is null, should return False');
        System.assertEquals('False',accountsForClone[0].IsPartnerNimda, 'IsPartnerNimda is null, should return False');

        Test.startTest();
        List<CDdCloneOppAndQuote.AccountReturn> accountsForSelected = CDdCloneOppAndQuote.getSelectedAccounts(new List<String>{String.valueOf(accountsForClone[0].Id)}, String.valueOf(sourceOpp.SBQQ__PrimaryQuote__c));
        System.assertEquals(1,accountsForSelected.size(), 'The correct number of Selected stores for cloning were not returned');
        List<CDdCloneOppAndQuote.AccountReturn> accountsForStoreId = CDdCloneOppAndQuote.getSelectedStoreIds(new List<String>{'1'}, String.valueOf(sourceOpp.SBQQ__PrimaryQuote__c));
        System.assertEquals(1,accountsForStoreId.size(), 'The correct number of StoreIds for cloning were not returned');
        CDdCloneOppAndQuote.CloneResult result = CDdCloneOppAndQuote.cloneOppandQuote(String.valueOf(sourceOpp.Id), new List<String>{String.valueOf(accountsForClone[0].Id)}, 'false', 'Closed Won');
        Test.stopTest();
        System.debug(accountsForSelected[0]);
        System.assertEquals(true, result.messages.isEmpty(), 'There was an error when submitting the batch');

        Opportunity sourceOppAfter = [
            SELECT Id, SBQQ__PrimaryQuote__c, Name, Bulk_Activation__c
            FROM Opportunity
            WHERE Id = :sourceOpp.Id LIMIT 1
        ];
        System.assertEquals(sourceOppAfter.Bulk_Activation__c, false, 'The Bulk_Activation__c field on the source Opp should now be false');

        Opportunity clonedOpp = queryClonedOpportunity(sourceOpp.Id);
        System.assertEquals(clonedOpp.isCloned__c, true, 'The isCloned field was not set to true as expected');
        System.assertNotEquals(clonedOpp.SBQQ__PrimaryQuote__c, sourceOpp.SBQQ__PrimaryQuote__c, 'The Primary quote should have changed to the new cloned quote');
        System.assertEquals('Closed Won', clonedOpp.StageName, 'The cloned Opp should be Closed Won');
        System.assertEquals(sourceOpp.Name, clonedOpp.Name, 'The cloned Opp should have the same name as the source opp');

        SBQQ__Quote__c clonedQuote = [
            SELECT Id, SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Status__c,
                    ApprovalStatus__c, SBQQ__Source__c, SBQQ__Uncalculated__c,
                    Drawer_Attributes__c,
                    (
                        SELECT Id, SBQQ__Source__c
                        FROM SBQQ__LineItems__r
                    )
            FROM SBQQ__Quote__c
            WHERE Id != :sourceQuote.Id LIMIT 1
        ];
        System.assertEquals(clonedQuote.SBQQ__Opportunity2__c, clonedOpp.Id, 'The cloned Opportunity was not mapped to the cloned quote as expected');
        System.assertEquals(clonedQuote.SBQQ__Account__c, clonedOpp.AccountId, 'The cloned quote did not get the correct account associated');
        System.assertEquals(sourceQuote.SBQQ__Status__c, clonedQuote.SBQQ__Status__c, 'The cloned quote did not get the correct status');
        System.assertEquals(clonedQuote.ApprovalStatus__c, 'Approved', 'The cloned quote did not get the correct approval status');
        System.assertEquals(clonedQuote.SBQQ__Source__c, sourceQuote.Id, 'The cloned quote did not get the source field mapped correctly');
        System.assertEquals(sourceQuote.SBQQ__LineItems__r.size(),clonedQuote.SBQQ__LineItems__r.size(), 'The cloned quote should have the same number of lines as the source quote');

        System.assertEquals(
            CDdCreateQuoteFromOppCtrl.drawer_attributes,
            clonedQuote.Drawer_Attributes__c,
            'The cloned quote did not get the source drawer attributes set correctly'
        );

        Set<Id> sourceLineIds = new Set<Id>();
        for(SBQQ__QuoteLine__c line : sourceQuote.SBQQ__LineItems__r){
            sourceLineIds.add(line.Id);
        }

        for(SBQQ__QuoteLine__c line : clonedQuote.SBQQ__LineItems__r){
            System.assertEquals(sourceLineIds.contains(line.SBQQ__Source__c), true, 'The cloned quote line should have a source linked to an original quote line');
        }
    }

    @isTest
    public static void testCloneOppAndQuoteBatch_CurrencyMismatch(){
        Opportunity sourceOpp = [
            SELECT Id, SBQQ__PrimaryQuote__c, Name, Bulk_Activation__c, Account_Billing_Country__c
            FROM Opportunity LIMIT 1
        ];

        SBQQ__Quote__c sourceQuote =  [
            SELECT Id, SBQQ__Status__c, ApprovalStatus__c,
                (
                    SELECT Id, SBQQ__Source__c
                    FROM SBQQ__LineItems__r
                )
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c = :sourceOpp.Id
        ];

        List<Account> accountsForClone = [SELECT Id, Name, Decision_Maker__c, Ultimate_Parent_Account__c, Ultimate_Parent_Id__c, Restaurant_ID__c,
                CurrencyISOCode, BillingCountry
                FROM Account where currencyISOCode= 'AUD' limit 1];

        Test.startTest();
        CDdCloneOppAndQuote.CloneResult result = CDdCloneOppAndQuote.cloneOppandQuote(String.valueOf(sourceOpp.Id), new List<String>{String.valueOf(accountsForClone[0].Id)},
                'false', 'Closed Won');
        Test.stopTest();

        List<Opportunity> clonedOpp = [
            SELECT Id, isCloned__c, AccountId, Account.ParentId, SBQQ__PrimaryQuote__c, StageName, Name
            FROM Opportunity
            WHERE Id != :sourceOpp.Id ];

        System.assertEquals(clonedOpp.size(), 0, 'There should be no cloned opp');
    }

    @isTest
    private static void cloneOppandQuote_byStoreId_expectParentToBeStore(){
        Opportunity sourceOpp = getOpportunity();
        List<CDdCloneOppAndQuote.AccountReturn> accountsForStoreId =
            CDdCloneOppAndQuote.getSelectedStoreIds(
                new List<String>{'3'},
                String.valueOf(sourceOpp.SBQQ__PrimaryQuote__c)
            );

        Test.startTest();
        CDdCloneOppAndQuote.CloneResult result =
            CDdCloneOppAndQuote.cloneOppandQuote(
                String.valueOf(sourceOpp.Id),
                new List<String>{String.valueOf(accountsForStoreId[0].Id)},
                'false',
                'Closed Won'
            );
        Test.stopTest();
        System.assertEquals(true, result.messages.isEmpty(), 'There was an error when submitting the batch');

        Opportunity clonedOpp = queryClonedOpportunity(sourceOpp.Id);
        System.assertNotEquals(
            accountsForStoreId[0].Id,
            sourceOpp.AccountId,
            'Expected test data to have different parentIds set.'
        );
        System.assertNotEquals(
            sourceOpp.AccountId,
            clonedOpp.AccountId,
            'Expected the source and cloned opportunities to have different parent accounts.'
        );
        System.assertEquals(
            accountsForStoreId[0].Id,
            clonedOpp.AccountId,
            'Expected cloned opportunity to be parented against the supplied storeId account\'s Id.'
        );
    }

    @isTest
    private static void getSelectedStoreIds_expectUltimateParentAsMocked(){
        Opportunity sourceOpp = getOpportunity();
        Account expectedParent = getOtherParentAccount();

        Test.startTest();
        List<CDdCloneOppAndQuote.AccountReturn> wrappedAccounts = CDdCloneOppAndQuote.getSelectedStoreIds(
            new List<String>{'3'},
            String.valueOf(sourceOpp.SBQQ__PrimaryQuote__c)
        );
        Test.stopTest();

        System.assertEquals(1, wrappedAccounts.size(), 'Expected a single result, as mocked and requested.');
        System.assertEquals(
            expectedParent.Id,
            wrappedAccounts[0].UltimateParentAccount,
            'Expected the ultimate parent to be set as mocked.'
        );
    }

    @isTest
    public static void testGetCloneReferenceId(){
        List<Product2> products = [SELECT Id, Name FROM Product2 LIMIT 1];
        List<Product2> productClones = new List<Product2>();
        for(Product2 product : products){
            Product2 clone = product.clone(false, true, false, false);
            productClones.add(clone);
        }
        insert productClones;

        Map<Id,Id> cloneMap = CDdCloneOppAndQuote.getCloneReferenceIds(productClones);
        System.assertNotEquals(cloneMap, null, 'There should be a map with 1 entry');
        System.assertEquals(cloneMap.get(products[0].Id),productClones[0].Id);

    }

    @isTest
    public static void testAddErrorMessageToList(){

        CDdCloneOppAndQuote.CloneResult result = new CDdCloneOppAndQuote.CloneResult();
        CDdCloneOppAndQuoteBatch.addErrorsToList(result, new List<String>{'Error1','Error2'}, 'Test Errors');
        System.assertEquals(CDdCloneOppAndQuote.STATUS_ERROR, result.status, 'The result should have an error status');
        System.assertEquals(3, result.messages.size(), 'The result should have 3 messages');
    }

    @isTest
    public static void testBuildErrorString(){

        String errMessage = 'This is an error message';
        String objName = 'sObject';
        String errString = CDdCloneOppAndQuote.buildErrorString(new List<String>{errMessage}, objName);
        System.assertEquals(true, errString.contains(errMessage), 'The error string html should contain the error message');
    }

    @isTest
    public static void testgetRelatedAccountsException(){
        Opportunity sourceOpp = getOpportunity();
        sourceOpp.StageName = CDdCpqBillingConstants.OPP_STAGENAME_OUT_FOR_SIGNATURE;
        update sourceOpp;

        Test.startTest();

        try {
            List<CDdCloneOppAndQuote.AccountReturn> accountsForClone = CDdCloneOppAndQuote.getRelatedAccounts(String.valueOf(sourceOpp.Id));
            System.assert(false, 'This line should never be reached, an exception should have been thrown.');
        } catch (AuraHandledException e){
            System.assert(true, 'The Aura Exception happened correctly.');
        }
        Test.stopTest();
    }

    @isTest
    public static void testgetRelatedAccountsWhenStageEqualsToContractSignedAndPMCNotEqualsToAlcoholException(){
        Opportunity sourceOpp = getOpportunity();
        sourceOpp.StageName = CDdCpqBillingConstants.OPP_STAGENAME_CONTRACT_SIGNED;
        sourceOpp.Account.Primary_Merchant_Categories__c = 'Cannabis';
        update sourceOpp;

        Test.startTest();

        try {
            List<CDdCloneOppAndQuote.AccountReturn> accountsForClone = CDdCloneOppAndQuote.getRelatedAccounts(String.valueOf(sourceOpp.Id));
            System.assert(false, 'This line should never be reached, an exception should have been thrown.');
        } catch (AuraHandledException e){
            System.assert(true, 'The Aura Exception happened correctly.');
        }
        Test.stopTest();
    }

    @isTest
    public static void testPrimaryQuoteException(){
        Opportunity sourceOpp = getOpportunity();
        sourceOpp.SBQQ__PrimaryQuote__c = null;
        update sourceOpp;

        Test.startTest();

        try {
            List<CDdCloneOppAndQuote.AccountReturn> accountsForClone = CDdCloneOppAndQuote.getRelatedAccounts(String.valueOf(sourceOpp.Id));
            System.assert(false, 'This line should never be reached, an exception should have been thrown.');
        } catch (AuraHandledException e){
            System.assert(true, 'The Aura Exception happened correctly.');
        }
        Test.stopTest();
    }

    @isTest
    private static void cloneOppLines_withZeroFinalFee_expectFinalFeeRemainsZero(){
        Opportunity testOpportunity = getOpportunity();
        List<OpportunityLineItem> testOppLineItems = getOpportunityLineItems();

        for(OpportunityLineItem currentItem : testOppLineItems){
            currentItem.Final_Fee__c = 0.00;
        }

        Test.startTest();
        List<OpportunityLineItem> resultLineItems = CDdCloneOppAndQuote.cloneOppLines(testOppLineItems, testOpportunity);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testOppLineItems.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(OpportunityLineItem currentResult : resultLineItems){
            System.assertEquals(
                0.00,
                currentResult.Final_Fee__c,
                'Expected the final fee to remain zero.'
            );
        }
    }

    @isTest
    private static void cloneOppLines_withFinalFee_withNoListPrice_expectFinalFeeRemains(){
        Decimal expectedFinalFee = 85.65;
        Opportunity testOpportunity = getOpportunity();
        List<OpportunityLineItem> testOppLineItems = getOpportunityLineItems();

        for(OpportunityLineItem currentItem : testOppLineItems){
            currentItem.Final_Fee__c = expectedFinalFee;
        }

        Test.startTest();
        List<OpportunityLineItem> resultLineItems = CDdCloneOppAndQuote.cloneOppLines(testOppLineItems, testOpportunity);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testOppLineItems.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(OpportunityLineItem currentResult : resultLineItems){
            System.assertEquals(
                expectedFinalFee,
                currentResult.Final_Fee__c,
                'Expected the final fee to remain unchanged.'
            );
        }
    }

    @isTest
    private static void cloneOppLines_withLegacyPriceBasisCommissionBased_expectClonedAsCommission(){
        Opportunity testOpportunity = getOpportunity();
        List<OpportunityLineItem> testOppLineItems = getOpportunityLineItems();

        for(OpportunityLineItem currentItem : testOppLineItems){
            currentItem.Price_Basis__c = CDdCloneOppAndQuote.DEPRECATED_COMMISSION_BASED;
        }

        Test.startTest();
        List<OpportunityLineItem> resultLineItems = CDdCloneOppAndQuote.cloneOppLines(testOppLineItems, testOpportunity);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testOppLineItems.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(OpportunityLineItem currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Commission" on cloning.'
            );
        }
    }

    @isTest
    private static void cloneOppLines_withLegacyPriceBasisCurrencyBased_expectClonedAsFlatCommission(){
        Opportunity testOpportunity = getOpportunity();
        List<OpportunityLineItem> testOppLineItems = getOpportunityLineItems();

        for(OpportunityLineItem currentItem : testOppLineItems){
            currentItem.Price_Basis__c = CDdCloneOppAndQuote.DEPRECATED_CURRENCY_BASED;
        }

        Test.startTest();
        List<OpportunityLineItem> resultLineItems = CDdCloneOppAndQuote.cloneOppLines(testOppLineItems, testOpportunity);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testOppLineItems.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(OpportunityLineItem currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_FLATCOMMISSION,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Flat_Commission" on cloning.'
            );
        }
    }

    @isTest
    private static void cloneOppLines_withLegacyPriceBasisCurrencyPlusUnit_expectClonedAsCommissionPlusFlat(){
        Opportunity testOpportunity = getOpportunity();
        List<OpportunityLineItem> testOppLineItems = getOpportunityLineItems();

        for(OpportunityLineItem currentItem : testOppLineItems){
            currentItem.Price_Basis__c = CDdCloneOppAndQuote.DEPRECATED_CURRENCY_PLUS_UNIT;
        }

        Test.startTest();
        List<OpportunityLineItem> resultLineItems = CDdCloneOppAndQuote.cloneOppLines(testOppLineItems, testOpportunity);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testOppLineItems.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(OpportunityLineItem currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSIONPLUSFLAT,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Flat_Commission" on cloning.'
            );
        }
    }

    @isTest
    private static void cloneOppLines_withLegacyPriceBasisCurrencyPlusUnit_weirdCasing_expectClonedAsCommissionPlusFlat(){
        Opportunity testOpportunity = getOpportunity();
        List<OpportunityLineItem> testOppLineItems = getOpportunityLineItems();

        for(OpportunityLineItem currentItem : testOppLineItems){
            currentItem.Price_Basis__c = 'cURRency + UNiT';
        }

        Test.startTest();
        List<OpportunityLineItem> resultLineItems = CDdCloneOppAndQuote.cloneOppLines(testOppLineItems, testOpportunity);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testOppLineItems.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(OpportunityLineItem currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSIONPLUSFLAT,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Commission + Flat" on cloning.'
            );
        }
    }

    @isTest
    private static void cloneQuoteLines_withNoFinalFee_withListPrice_expectFinalFeeSetToListPrice(){
        Decimal expectedFinalFee = 22.50;
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.SBQQ__ListPrice__c = expectedFinalFee;
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                expectedFinalFee,
                currentResult.Final_Fee__c,
                'Expected the final fee to have been updated to the mocked list price.'
            );
        }
    }

    @isTest
    private static void cloneQuoteLines_withNoFinalFee_withNoListPrice_expectFinalFeeRemainsNull(){
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.SBQQ__ListPrice__c = null;
            currentQuoteLine.Final_Fee__c = null;
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                null,
                currentResult.Final_Fee__c,
                'Expected the final fee to remain null if neither it nor list price is set.'
            );
        }
    }

    @isTest
    private static void cloneQuoteLines_withZeroFinalFee_withListPrice_expectFinalFeeRemainsZero(){
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.SBQQ__ListPrice__c = 23.44;
            currentQuoteLine.Final_Fee__c = 0.00;
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                0,
                currentResult.Final_Fee__c,
                'Expected the final fee to remain zero even though a list price exists (since it was zero and not null).'
            );
        }
    }

    @isTest
    private static void cloneQuoteLines_withFinalFee_withNoListPrice_expectFinalFeeRemains(){
        Decimal expectedFinalFee = 55.55;
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.Final_Fee__c = expectedFinalFee;
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                expectedFinalFee,
                currentResult.Final_Fee__c,
                'Expected the final fee to remain unchanged.'
            );
        }
    }


    @isTest
    private static void cloneQuoteLines_withLegacyPriceBasisCommissionBased_expectClonedAsCommission(){
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.Price_Basis__c = CDdCloneOppAndQuote.DEPRECATED_COMMISSION_BASED;
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Commission" on cloning.'
            );
        }
    }

    @isTest
    private static void cloneQuoteLines_withLegacyPriceBasisCurrencyBased_expectClonedAsFlatCommission(){
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.Price_Basis__c = CDdCloneOppAndQuote.DEPRECATED_CURRENCY_BASED;
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_FLATCOMMISSION,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Flat_Commission" on cloning.'
            );
        }
    }

    @isTest
    private static void cloneQuoteLines_withLegacyPriceBasisCurrencyBased_weirdCasing_expectClonedAsFlatCommission(){
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.Price_Basis__c = 'currenCY-BaSED';
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_FLATCOMMISSION,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Flat_Commission" on cloning.'
            );
        }
    }

    @isTest
    private static void cloneQuoteLines_withLegacyPriceBasisCurrencyPlusUnit_expectClonedAsCommissionPlusFlat(){
        SBQQ__Quote__c testQuote = getQuote();
        List<SBQQ__QuoteLine__c> testQuoteLines = getQuoteLines();

        for(SBQQ__QuoteLine__c currentQuoteLine : testQuoteLines){
            currentQuoteLine.Price_Basis__c = CDdCloneOppAndQuote.DEPRECATED_CURRENCY_PLUS_UNIT;
        }

        Test.startTest();
        List<SBQQ__QuoteLine__c> resultLineItems = CDdCloneOppAndQuote.cloneQuoteLines(testQuoteLines, testQuote);
        Test.stopTest();

        System.assertNotEquals(null, resultLineItems, 'Expected a non-null result.');
        System.assertEquals(
            testQuoteLines.size(),
            resultLineItems.size(),
            'Expected as many results as were submitted for cloning.'
        );
        for(SBQQ__QuoteLine__c currentResult : resultLineItems){
            System.assertEquals(
                CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSIONPLUSFLAT,
                currentResult.Price_Basis__c,
                'Expected the price basis to have been updated to "Commission + Flat" on cloning.'
            );
        }
    }
}