/**
 * @description       :Test class for Utity class that facilitates interaction with the
 * CountryToDefaultValueMapping custom metadta object.
 * @author            : Abhijeet
 * @group             : 
 * @last modified on  : 12-01-2021
 * @last modified by  : Jose Vega
**/
@IsTest
public class CDdI18nDefaultValueMappingUtilTest {

    /**
    * @description: End to end test case for setDefaultValuesBasedOnCountry
    */
    @TestSetup
    static void testAccountDefaultValues() {

        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getOrgDefaults();
        loggerSettings.Enable_Logging__c = true; 
        upsert loggerSettings; 

        Test.startTest();
        List<Account> accountsToInsert = new List<Account>();

        List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 2 , false);
        for (Integer i = 0; i < acclist.size(); i++) {
          
            acclist[i].Name = 'Test NZ Acc ' + String.valueOf(i);
            acclist[i].Phone = '+64 1234767' + String.valueOf(i);
            acclist[i].BillingStreet = String.valueOf(i) + ' Test NZ BillingStrret ' + String.valueOf(i);

            acclist[i].BillingCity = 'Auckland';
            acclist[i].BillingPostalCode = '123' + String.valueOf(i);
            acclist[i].BillingCountryCode = 'NZ';
            acclist[i].BillingCountry = 'New Zealand';
            acclist[i].Entity_Type__c = 'Company';

            acclist[i].Business_ID__c = 123456 + i;

            acclist[i].Language__c = 'English';
            acclist[i].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
            accountsToInsert.add(acclist[i]);
        }
        insert accountsToInsert;
        Test.stopTest();
        List<Account> accountRecords = [SELECT Id, CurrencyISOCode FROM Account];
        System.assertEquals(2, accountRecords.size(), 'must contain 2 records');
        for(Account accountRecord: accountRecords) {
            System.assertEquals('NZD', accountRecord.CurrencyISOCode, 'must have NZD currency');
        }
    }

    /**
    * @description: Unit test case for setCountryFieldName
    */
    @isTest
    static void setCountryFieldNameTest() {
        CDdI18nDefaultValueMappingUtil.setCountryFieldName('BillingCountryCode');
        System.assertEquals('BillingCountryCode', CDdI18nDefaultValueMappingUtil.countryFieldName, 'Incorrect countryFieldName');
    }

    /**
    * @description: Unit test case for setCountryFieldNameBasedOnSobject
    */
    @isTest
    static void setCountryFieldNameBasedOnSobjectTest() {
        CDdI18nDefaultValueMappingUtil.sObjectName = 'Account';
        CDdI18nDefaultValueMappingUtil.setCountryFieldNameBasedOnSobject();
        System.assertEquals('BillingCountryCode', CDdI18nDefaultValueMappingUtil.countryFieldName, 'Incorrect countryFieldName');
    }

    /**
    * @description: Unit test case for populateCountryCodeSet
    */
    @isTest
    static void populateCountryCodeSetTest() {
        List<Account> acctList = [SELECT Id, BillingCountryCode FROM Account];
        CDdI18nDefaultValueMappingUtil.sObjectName = 'Account';
        CDdI18nDefaultValueMappingUtil.setCountryFieldName('BillingCountryCode');
        Set<String> countryCodeSet = CDdI18nDefaultValueMappingUtil.populateCountryCodeSet(acctList);
        System.assertEquals(1, countryCodeSet.size(), 'countryCodeSet must contain 1 record');
    }

    /**
    * @description: Unit test case for getCountryToMappingListMap
    */
    @isTest
    static void getCountryToMappingListMapTest() {
        CDdI18nDefaultValueMappingUtil.sObjectName = 'Account';
        CDdI18nDefaultValueMappingUtil.setCountryFieldName('BillingCountryCode');
        List<I18n_Country_Default_Value_Mapping__mdt> mappingList = CDdI18nDefaultValueMappingUtil.getMappingRecords(new Set<String> {'NZ'});
        Map<String, List<I18n_Country_Default_Value_Mapping__mdt>> countryToMappingListMap = CDdI18nDefaultValueMappingUtil.getCountryToMappingListMap(mappingList);
        System.assertEquals(1, countryToMappingListMap.size(), 'countryToMappingListMap must contain 1 record');
    }

    /**
    * @description: Unit test case for getCountryToMappingListMap
    */
    @isTest
    static void setDefaultValuesBasedOnCountryUnSupportedExceptionTest() {

        CDdI18nDefaultValueMappingUtil.sObjectName = 'Account';
        CDdI18nDefaultValueMappingUtil.setCountryFieldName('BillingCountryCode');
        List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1 , false);
        acclist[0].Name = 'Test JP Acc';
        acclist[0].Phone = '+81 1234567';
        acclist[0].BillingStreet = 'Test JP BillingStreet';
        acclist[0].BillingPostalCode = '123';
        acclist[0].BillingCountryCode = 'JP';
        acclist[0].BillingCountry = 'Japan';
        acclist[0].Entity_Type__c = 'Company';
        acclist[0].Business_ID__c = 123456;
        acclist[0].Language__c = 'English';
        acclist[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();

        Test.startTest();
        CDdI18nDefaultValueMappingUtil.sObjectName = 'Account';
        CDdI18nDefaultValueMappingUtil.setDefaultValuesBasedOnCountry(acclist, 'BillingCountryCode');
        Test.stopTest();
        // Bank_Account_Number_Encrypted__c is not supported
        List<Apex_Log__c> logList = [SELECT Id, Class_Name__c, Log__c, Method_Name__c FROM Apex_Log__c]; 
        System.assert(logList.size() > 0, 'logList can not be empty');
        System.assert(logList[0].Log__c.contains('This type is not supported'), 'Must throw type exception');
    }
}