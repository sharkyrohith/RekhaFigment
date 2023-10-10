/**
 * @description Unit Tests for the OrdeItemsSelector
 *
 * @author Krishna Sanisetty
 * @date 10/07/2022
 */
@isTest
private class OrderItemsSelectorSpec {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheMilestoneSObject() {
        SObjectType actualType = new OrderItemsSelector().getSObjectType();
        System.assertEquals(
            OrderItem.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Case.SObjectType and received: ' + actualType);
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            OrderItem.Id,
            OrderItem.Promo_End_Day__c,
            OrderItem.Promo_Start_Day__c
        };

        SObjectField[] actualTokens = new OrderItemsSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenselectByOrderIdAndProductFamilyThenItShouldReturnRecordsWithTheGivenIds() {
        List<String> productFamilyList = new List<string>{'Advertisement','Marketplace'};
        Account account = TDdAccountFactory.createAccount();
        insert account;

        Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
        insert contact;

        Opportunity opportunity = TDdOpportunityFactory.createOpportunity('Test', account.Id, contact.Id, 'New', 'Pipeline',UserInfo.getUserId());
        insert opportunity;

        SBQQ.TriggerControl.disable();

        List<Product2> productList = new List<Product2>();
        for(String productFamily: productFamilyList){
            Product2 product = TDdCPQTestDataFactory.createProduct(false);
            product.Family = productFamily;
            productList.add(product);
        }
        insert productList;

        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opportunity, account, null, true);

        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        List<SBQQ__QuoteLine__c> quoteLinesList = new List<SBQQ__QuoteLine__c>();

        for(Product2 product: productList){
            PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, 'USD', false);
            pricebookEntryList.add(pbe);
            SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
            quoteLine.Trial_Period__c = '60';
            quoteLinesList.add(quoteLine);
        }
        insert pricebookEntryList;
        insert quoteLinesList;

        Order order = TDdCPQTestDataFactory.createOrder(account, opportunity, quote, false);
        order.EndDate = null;
        insert order;

        OrderItem orderProduct1 = TDdCPQTestDataFactory.createOrderItem(order, quoteLinesList[0], pricebookEntryList[0].Id, false);
        OrderItem orderProduct2 = TDdCPQTestDataFactory.createOrderItem(order, quoteLinesList[1], pricebookEntryList[1].Id, false);
        insert new List<OrderItem>{orderProduct1, orderProduct2};

        SBQQ.TriggerControl.enable();

        List<OrderItem> orderItems = OrderItemsSelector.newInstance().selectByOrderIdAndProductFamily(new Set<Id>{opportunity.Id}, new Set<String>{productFamilyList[0]});

        System.assert(orderItems.size() == 1);
        System.assert(orderItems[0].Product2.Family == productFamilyList[0]);
    }
}