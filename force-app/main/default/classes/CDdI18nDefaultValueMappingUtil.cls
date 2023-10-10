/**
 * @description       : Utility class that facilitates interaction with the
 * CountryToDefaultValueMapping custom metadta object.
 * For new object, the sObjectNameToCountryFieldNameMap needs to be updated.
 * To support multiple objects, the sObjectName variable needs to be updated to a collection, the query in getMappingRecords() should be updated
 * New field types may need to be added to processRecord(), such as DATE
 * @author            : Abhijeet
 * @group             :
 * @last modified on  : 02-02-2023
 * @last modified by  : Jose Vega
**/
public with sharing class CDdI18nDefaultValueMappingUtil {

    public static final String RECORD_TYPE_ID = 'RecordTypeId';
    public static final String APPLIES_TO_ALL_RECORD_TYPES = 'ANY';
    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    public static Map<String,String> sObjectNameToCountryFieldNameMap = new Map<String,String> {
        'Account'   => 'BillingCountryCode',
        'Case'      => 'CountryCode',
        'Lead'      => 'CountryCode',
        'Contact'   => 'MailingCountry'
    };

    private static Map<String, String> countryToCountryCodeMap = new Map<String, String> {
        'New Zealand' => 'NZ',
        'Germany'     => 'DE',
        'Japan'       => 'JP'
    };

    private static Map<String, String> countryCodeToCountryMap = new Map<String, String> {
        'NZ' => 'New Zealand',
        'DE' => 'Germany',
        'JP' => 'Japan'
    };

    public static final String NO_COUNTRY_FIELD_NAME_ERROR = 'Field name to determine country not set';

    /**
     * @description countryFieldName Holds the name of the field use to determine country
     */
    public static String countryFieldName;
    /**
     * @description sObjectName Holds the object type name
     */
    public static String sObjectName;
    /**
     * @description fieldSet Holds the fields being filled for the Object
     */
    public static Set<String> fieldSet;

    /**
     * @description setSObjectName Sets the sObjectName based on the record
     */
    public static void setSObjectName(List<sObject> recordList) {
        for(sObject record: recordList) {
            sObjectName = String.valueOf(record.getSObjectType());
            break;
        }
    }

    /**
     * @description setCountryFieldName setter
     * @param  countryFieldNameParam countryFieldNameParam description
     */
    public static void setCountryFieldName(String countryFieldNameParam) {
        countryFieldName = countryFieldNameParam;
    }

    /**
     * @description setCountryFieldNameBasedOnSobject description
     */
    public static void setCountryFieldNameBasedOnSobject() {
        if (sObjectNameToCountryFieldNameMap.containsKey(sObjectName)) {
            countryFieldName = sObjectNameToCountryFieldNameMap.get(sObjectName);
        } else {
            throw new CDdI18nDefaultValueMappingUtilException (NO_COUNTRY_FIELD_NAME_ERROR);
        }
    }

    /**
     * @description setDefaultValuesBasedOnCountry By reference fills record fields
     * that are country specific.
     * @param  recordList recordList Records that need to be I18N
     * @param  countryFieldName can be used from other classes if countryfieldname needs to be defined outside of this class.
     */
    public static void setDefaultValuesBasedOnCountry(List<sObject> recordList, String countryFieldName) {
        setSObjectName(recordList);
        setCountryFieldName(countryFieldName);
        populateDefaultValues(recordList);
    }

    /**
     * @description setDefaultValuesBasedOnCountry By reference fills record fields
     * that are country specific.
     * @param  recordList recordList Records that need to be I18n
     */
    public static void setDefaultValuesBasedOnCountry(List<sObject> recordList) {
        setSObjectName(recordList);
        setCountryFieldNameBasedOnSobject();
        populateDefaultValues(recordList);
    }

    /**
     * @description  populateDefaultValues By reference fills record fields
     * that are country specific.
     * @param  recordList recordList Records that need to be I18n
     */
    public static void populateDefaultValues(List<sObject> recordList) {
        try {

            Set<String> countryCodeSet = populateCountryCodeSet(recordList);

            List<I18n_Country_Default_Value_Mapping__mdt> mappingList = getMappingRecords(countryCodeSet);

            Map<String, List<I18n_Country_Default_Value_Mapping__mdt>> countryToMappingListMap = getCountryToMappingListMap(mappingList);

            Map<String, String> fieldNametoDataTypeMap = getFieldNametoDataTypeMap();

            for(sobject record: recordList) {
                String country= (String) record.get(countryFieldName);
                String countryCode = countryToCountryCodeMap.containsKey(country) ? countryToCountryCodeMap.get(country) : country;

                String recordTypeId = (String) record.get(RECORD_TYPE_ID);

                List<I18n_Country_Default_Value_Mapping__mdt> countryMappingList = countryToMappingListMap.get(countryCode);
                if(countryMappingList != null) {
                    for(I18n_Country_Default_Value_Mapping__mdt mapping: mappingList) {
                        String fieldDataType = fieldNameToDataTypeMap.get(String.valueOf(mapping.Field_Name__c).toLowerCase());
                        Boolean hasCorrectRecordType = APPLIES_TO_ALL_RECORD_TYPES.equalsIgnoreCase(mapping.Record_Type_Id__c) || (!String.isBlank(mapping.Record_Type_Id__c) && mapping.Record_Type_Id__c.contains(recordTypeId));
                        if(hasCorrectRecordType) {
                            processRecord(record, mapping, fieldDataType);
                        }
                    }
                }
            }
        } catch (Exception ex) {
            CDdErrorUtilities.createApexLogs(new List<String>{'Exception: ' + ex.getMessage()}, 'CDdI18nDefaultValueMappingUtil',
                'setDefaultValuesBasedOnCountry', LoggingLevel.ERROR);
        }
    }

    /**
     * @description populateCountryCodeSet populate countrycodes from record
     * @param  recordList recordList records that will be processed
     * @return            A set of strings with all countries in the list of records
     */
    @TestVisible
    private static Set<String> populateCountryCodeSet(List<sObject> recordList) {
        Set<String> countryCodeSet = new Set<String>();
        for(sobject record: recordList) {
            String country = (String) record.get(countryFieldName);
            String countryCode = countryToCountryCodeMap.containsKey(country) ? countryToCountryCodeMap.get(country) : country;
            if(countryCodeSet != null) {
                countryCodeSet.add(countryCode);
            }
        }
        return countryCodeSet;
    }

    /**
     * @description getMappingRecords getting mapping records from custom metadata
     * @param  countryCodeSet countryCodeSet description
     * @return                return description
     */
    public static List<I18n_Country_Default_Value_Mapping__mdt> getMappingRecords(Set<String> countryCodeSet) {
        List<I18n_Country_Default_Value_Mapping__mdt> mappingList = new List<I18n_Country_Default_Value_Mapping__mdt>();
        if(Test.isRunningTest()) {
            mappingList = CDdI18nDefaultValueMappingUtilTestHelper.createMappingRecords(countryCodeSet);
        } else {
            mappingList = [
                SELECT Country_Code__c, Default_Value__c, Field_Name__c, Object_Name__c, Record_Type_Id__c
                FROM I18n_Country_Default_Value_Mapping__mdt
                WHERE Object_Name__c = :sObjectName
                AND Country_Code__c in :countryCodeSet
                AND Is_Active__c = TRUE
            ];
        }
        return mappingList;
    }

    /**
     * @description getCountryToMappingListMap
     *  Creates map of country to list of field related to the country
     *  Japan => LIST<{Field: Currency , Value: 'YEN'}
     *  Germany => LIST <{Field: Currency, Value ; 'EURO'}
     * @param  mappingList mappingList description
     * @return             return description
     */
    public static Map<String, List<I18n_Country_Default_Value_Mapping__mdt>> getCountryToMappingListMap(List<I18n_Country_Default_Value_Mapping__mdt> mappingList) {
        Map<String, List<I18n_Country_Default_Value_Mapping__mdt>> countryToDefaultFieldMappingMap = new Map<String, List<I18n_Country_Default_Value_Mapping__mdt>>();
        fieldSet = new Set<String>();
        for(I18n_Country_Default_Value_Mapping__mdt mapping: mappingList) {
            if(!countryToDefaultFieldMappingMap.containsKey(mapping.Country_Code__c)) {
                countryToDefaultFieldMappingMap.put(mapping.Country_Code__c, new List<I18n_Country_Default_Value_Mapping__mdt>());
            }
            countryToDefaultFieldMappingMap.get(mapping.Country_Code__c).add(mapping);
            String fieldName = String.valueOf(mapping.Field_Name__c);
            fieldSet.add(fieldName.toLowerCase());
        }
        return countryToDefaultFieldMappingMap;
    }

    /**
     * @description getFieldNametoDataTypeMap Generate a Map with fieldName to fieldDataType
     * @return   return description
     */
    private static Map<String, String> getFieldNametoDataTypeMap() {
        Map<String, String> fieldNameToDataTypeMap = new Map<String, String>();
        try {
            Map<String, Schema.SObjectField> fieldMap = SOBJECT_TYPES.get(sObjectName).getDescribe().fields.getMap();

            for (String fieldName: fieldSet) {
                if (fieldMap.keySet().contains(fieldName)) {
                    Schema.DescribeFieldResult fldResult = fieldMap.get(fieldName).getDescribe();
                    fieldNameToDataTypeMap.put(fieldName, String.valueOf(fldResult.getType()));
                }
            }
        } catch(Exception ex) {
            CDdErrorUtilities.createApexLogs(new List<String>{'Exception: ' + ex.getMessage()}, 'CDdI18nDefaultValueMappingUtil',
                'getFieldNametoDataTypeMap', LoggingLevel.ERROR);
        }
        return fieldNameToDataTypeMap;
    }

    /**
     * @description Set default values based on data type
     * @param  record        record description
     * @param  mapping       mapping description
     * @param  fieldDataType fieldDataType description
     */
    private static void processRecord(sobject record, I18n_Country_Default_Value_Mapping__mdt mapping, String fieldDataType) {
        try {
            switch on fieldDataType {

                when 'BOOLEAN' {
                    record.put(mapping.Field_Name__c, Boolean.valueOf(mapping.Default_Value__c));
                }

                when 'INTEGER' {
                    record.put(mapping.Field_Name__c, Integer.valueOf(mapping.Default_Value__c));
                }
                when 'STRING','PICKLIST', 'TEXTAREA', 'REFERENCE', 'URL', 'CURRENCY'  {
                    record.put(mapping.Field_Name__c, mapping.Default_Value__c);
                }
                when else {
                    String exStr = 'Exception: ' + mapping.Field_Name__c + ' is of type ' + fieldDataType + '. This type is not supported';
                    throw new CDdI18nDefaultValueMappingUtilException (exStr);
                }
            }
        } catch(CDdI18nDefaultValueMappingUtilException ex) {
            CDdErrorUtilities.createApexLogs(new List<String>{'Exception: ' + ex.getMessage()}, 'CDdI18nDefaultValueMappingUtil',
                'processRecord', LoggingLevel.ERROR);
        }
    }

    /**
    * @description Custom validation exception
    **/
    public class CDdI18nDefaultValueMappingUtilException  extends Exception {}
}