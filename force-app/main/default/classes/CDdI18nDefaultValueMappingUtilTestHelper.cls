/**
 * @description       : Helper class for testing I18NDefaultValueMappingUtil
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 12-02-2021
 * @last modified by  : Jose Vega
**/
public with sharing class CDdI18nDefaultValueMappingUtilTestHelper {
    /**
     * @description createMappingRecords returns create and return dummy custom metadata records. 
     * This method is created for test records, otherwise deletion/deactivation existing records from metadata may impact test class
     * @param  recordList recordList description
     * @return            return description
     */
    private static final String NZ_COUNTRY_CODE = 'NZ';
    private static final String JP_COUNTRY_CODE = 'JP';
    private static final String ANY_RECORD_TYPE = CDdI18nDefaultValueMappingUtil.APPLIES_TO_ALL_RECORD_TYPES;
    private static final String DIRECT_DEPOSIT_FIELD_NAME = 'Direct_Deposit__c';
    private static final String DIRECT_DEPOSIT_FIELD_VALUE = 'TRUE';
    private static final String CURRENCY_ISOCODE_FIELD_NAME = 'CurrencyIsoCode';
    private static final String CURRENCY_ISOCODE_FIELD_VALUE = 'NZD';
    private static final String BANK_FIELD_NAME = 'Bank_Account_Number_Encrypted__c';
    private static final String BANK_FIELD_VALUE = 'XXXX';
    private static final String SOBJECT_NAME_ACCOUNT = 'Account';

    @testVisible
    public static List<I18n_Country_Default_Value_Mapping__mdt> createMappingRecords(Set<String> countryCodeSet) {
        List<I18n_Country_Default_Value_Mapping__mdt> mappingList = new List<I18n_Country_Default_Value_Mapping__mdt>();
        List<I18n_Country_Default_Value_Mapping__mdt> mappingListNZ = new List<I18n_Country_Default_Value_Mapping__mdt>();
        List<I18n_Country_Default_Value_Mapping__mdt> mappingListJP = new List<I18n_Country_Default_Value_Mapping__mdt>();
        mappingListNZ.add(new I18n_Country_Default_Value_Mapping__mdt(
            Country_Code__c = NZ_COUNTRY_CODE,
            Label = 'NZ Marketplace Direct Deposit to true',
            DeveloperName = 'NZ_Marketplace_Direct_Deposit_to_true',
            Default_Value__c = DIRECT_DEPOSIT_FIELD_VALUE,
            Record_Type_Id__c = ANY_RECORD_TYPE,
            Field_Name__c = DIRECT_DEPOSIT_FIELD_NAME,
            Object_Name__c = SOBJECT_NAME_ACCOUNT
        ));
        mappingListNZ.add(new I18n_Country_Default_Value_Mapping__mdt(
            Country_Code__c = NZ_COUNTRY_CODE,
            Label = 'NZ Default Account Currency to NZD',
            DeveloperName = 'NZ_Default_Account_Currency_to_NZD',
            Record_Type_Id__c = ANY_RECORD_TYPE,
            Default_Value__c = CURRENCY_ISOCODE_FIELD_VALUE,
            Field_Name__c = CURRENCY_ISOCODE_FIELD_NAME,
            Object_Name__c = SOBJECT_NAME_ACCOUNT
        ));
        mappingListJP.add(new I18n_Country_Default_Value_Mapping__mdt(
            Country_Code__c = JP_COUNTRY_CODE,
            Label = 'JP Bank Account Number to XXXX',
            DeveloperName = 'JP_Phone_Number_Test',
            Default_Value__c = BANK_FIELD_VALUE,
            Record_Type_Id__c = ANY_RECORD_TYPE,
            Field_Name__c = BANK_FIELD_NAME,
            Object_Name__c = SOBJECT_NAME_ACCOUNT
        ));
        if(countryCodeSet.contains(NZ_COUNTRY_CODE)) {
            mappingList.addAll(mappingListNZ);
        }
        if(countryCodeSet.contains(JP_COUNTRY_CODE)) {
            mappingList.addAll(mappingListJP);
        }
        return mappingList;
    }
}