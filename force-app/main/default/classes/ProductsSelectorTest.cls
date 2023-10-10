/********************************************************************************************************************
* @author Sriram
* @date 10/08/2022
*
* @group fflib
*
* @description Apex test class for Products Selector      
* 
**************************************************************************************************************************************/
@IsTest
private class ProductsSelectorTest {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheOpportunitySObject() {
        SObjectType actualType = new ProductsSelector().getSObjectType();
        System.assertEquals(
            Product2.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Product2.SObjectType and received: ' + actualType );
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Product2.DD_Custom_ID__c,
            Product2.Description,
            Product2.Id,
            Product2.IsActive,
            Product2.Name,
            Product2.Package_Name__c,
            Product2.Platform__c,
            Product2.ProductCode,
            Product2.Family
        };

        SObjectField[] actualTokens = new ProductsSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
        product1.Name = 'Test Product 1';
        product1.DD_Custom_ID__c = '12345';
        Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
        product2.Name = 'Test Product 2';
        product2.DD_Custom_ID__c = '56789';
        insert new List<Product2>{ product1, product2 };        

        // Select
        Map<Id, Product2> testRecords = new Map<Id, Product2>( new ProductsSelector().selectById( new Set<Id>{
            product1.Id,
            product2.Id
        } ) );

        // Assert
        System.assert( testRecords.keySet().contains( product1.Id ) );
        System.assert( testRecords.keySet().contains( product2.Id ) );
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        // Arrange
        Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
        product1.Name = 'Test Product 1';
        product1.DD_Custom_ID__c = '12345';
        Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
        product2.Name = 'Test Product 2';
        product2.DD_Custom_ID__c = '56789';
        insert new List<Product2>{ product1, product2 }; 

        // Select
        Map<Id, Product2> testRecords = new Map<Id, Product2>( new ProductsSelector().selectById( new Set<Id>{
            Fake.generateId( Product2.class ),
            Fake.generateId( Product2.class )
        } ) );

        // Assert
        System.assert( testRecords.isEmpty() );
    }

    @IsTest
    static void testWhenSelectedByDDCustomIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
        product1.Name = 'Test Product 1';
        product1.DD_Custom_ID__c = '12345';
        Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
        product2.Name = 'Test Product 2';
        product2.DD_Custom_ID__c = '56789';
        insert new List<Product2>{ product1, product2 };        

        // Select
        Map<Id, Product2> testRecords = new Map<Id, Product2>( new ProductsSelector().selectByDDCustomId( new Set<String>{
            product1.DD_Custom_ID__c,
            product2.DD_Custom_ID__c
        } ) );

        // Assert
        System.assert( testRecords.keySet().contains( product1.Id ) );
        System.assert( testRecords.keySet().contains( product2.Id ) );
    }

    @IsTest
    static void testWhenSelectedByDDCustomIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        // Arrange
        Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
        product1.Name = 'Test Product 1';
        product1.DD_Custom_ID__c = '12345';
        Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
        product2.Name = 'Test Product 2';
        product2.DD_Custom_ID__c = '56789';
        insert new List<Product2>{ product1, product2 }; 

        // Select
        Map<Id, Product2> testRecords = new Map<Id, Product2>( new ProductsSelector().selectByDDCustomId( new Set<String>{
            '99999',
            '00000'
        } ) );

        // Assert
        System.assert( testRecords.isEmpty() );
    }    
}