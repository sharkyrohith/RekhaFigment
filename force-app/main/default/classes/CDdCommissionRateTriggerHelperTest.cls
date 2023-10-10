/********************************************************************************************************************
* @author Dan Meseroll (atg)
* @date 2022-01
*
* @description Test for Store Agreement Trigger Helper
**************************************************************************************************************************************/
@isTest
public with sharing class CDdCommissionRateTriggerHelperTest {
    /** 
    * @description Prepare test data
    */
    @TestSetup
    static void makeData(){
            Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
            Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
            List<Product2> products = new List<Product2>{product1, product2};
            insert products;
            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
    }

    /** 
    * @description Test for Search Key generation
    */        
    @isTest
    public static void testGenerateSearchKey(){
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        Submarket__c submarket = [SELECT Id FROM Submarket__c LIMIT 1];
        Commission_Rate__c commissionRate = TDdCPQTestDataFactory.createCommissionRate(
            'USD', 
            products[0].Id, 
            products[1].Id, 
            null, 
            null, 
            Date.today(), 
            Date.today() + 30, 
            CDdCpqBillingConstants.ACC_MERCH_CAT_PREP_FOOD,
            true
        );

        Commission_Rate__c commissionRateAfter = [SELECT Id, Search_Key__c FROM Commission_Rate__c LIMIT 1];
        system.assertEquals(true, String.isNotBlank(commissionRateAfter.Search_Key__c), 'The search key should have a value');
        system.assertEquals(true, commissionRateAfter.Search_Key__c.contains(products[0].Id), 'The search key should have the productId');
        system.assertEquals(true, commissionRateAfter.Search_Key__c.contains(products[1].Id), 'The search key should have the package productId');
        system.assertEquals(true, commissionRateAfter.Search_Key__c.contains('USD'), 'The search key should have currencyCode of USD');
        system.assertEquals(true, commissionRateAfter.Search_Key__c.contains(CDdCpqBillingConstants.ACC_MERCH_CAT_PREP_FOOD), 'The search key should have the primary Mx Category ' + CDdCpqBillingConstants.ACC_MERCH_CAT_PREP_FOOD + ' in it');  
        
        commissionRate.CurrencyIsoCode = 'CAD';
        update commissionRate;

        commissionRateAfter = [SELECT Id, Search_Key__c FROM Commission_Rate__c LIMIT 1];
        system.assertEquals(true, commissionRateAfter.Search_Key__c.contains('CAD'), 'The search key should have currencyCode of CAD');
    }

    /** 
    * @description Test Date Defaults
    */        
    @isTest
    public static void testDateDefaults(){
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        Submarket__c submarket = [SELECT Id FROM Submarket__c LIMIT 1];
        Commission_Rate__c commissionRate = TDdCPQTestDataFactory.createCommissionRate(
            'USD', 
            products[0].Id, 
            products[1].Id, 
            null, 
            null, 
            null, 
            null, 
            CDdCpqBillingConstants.ACC_MERCH_CAT_PREP_FOOD,
            true
        );

        Commission_Rate__c commissionRateAfter = [SELECT Id, Start__c, End__c FROM Commission_Rate__c LIMIT 1];
        system.assertEquals(Date.newInstance(2000, 1, 1), commissionRateAfter.Start__c, 'The Start__c field should be 2000-01-01');
        system.assertEquals(Date.newInstance(3000, 12, 31), commissionRateAfter.End__c, 'The End__c field should be 3000-12-31');
    }

    /** 
    * @description Test for Search Key generation 
    *   BZAP-13182 Null merchancy category should have null search key.
    */        
    @isTest
    public static void testGenerateSearchKey_Negative(){
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        Submarket__c submarket = [SELECT Id FROM Submarket__c LIMIT 1];
        Commission_Rate__c commissionRate = TDdCPQTestDataFactory.createCommissionRate(
            'USD', 
            products[0].Id, 
            products[1].Id, 
            null, 
            null, 
            Date.today(), 
            Date.today() + 30, 
            null,
            false
        );

        Test.startTest();
        insert commissionRate;
        Test.stopTest();

        Commission_Rate__c commissionRateAfter = [SELECT Id, Search_Key__c FROM Commission_Rate__c WHERE Id = :commissionRate.Id];
        system.assertEquals(false, String.isNotBlank(commissionRateAfter.Search_Key__c), 'The search key should NOT have a value');
    }
}