/**
 * @author Raju Lakshman
 * @date Sept 2020
 * @description Test class for the ddMultiSelectPicklist component and framework
 */

@IsTest
public without sharing class CDdMultiSelectPicklistTest {

    @IsTest
    public static void testObjectRecords() {
        CDdMultiSelectPicklistCtrl.InitWrapper initWrapper = CDdMultiSelectPicklistCtrl.getSearchInfo('Example_Object_Records');
        system.assert(initWrapper.searchInfo.Query_and_Cache_on_Init__c == false,'Example_Object_Records Query and Cache on Init is incorrect');

        List<CDdMultiSelectPicklistWrapper> recordIdsToIgnore = new List<CDdMultiSelectPicklistWrapper>();
        List<User> users = [SELECT Id,Name FROM User WHERE Name LIKE 'John%' and isActive = true LIMIT 1];
        if (!users.isEmpty()) {
            recordIdsToIgnore.add(createTestWrapper(users[0].Id,users[0].Name));
        }

        CDdMultiSelectPicklistValuesWrapper valuesWrapper = CDdMultiSelectPicklistCtrl.getLookupResultBySearchInfo(
            'John',
            JSON.serialize(recordIdsToIgnore),
            null,
            initWrapper.searchInfo,
            initWrapper.searchInfo.DD_Multi_Select_Picklist_SOSL_Return__r == null ?
                new List<DD_Multi_Select_Picklist_SOSL_Return__mdt>() : initWrapper.searchInfo.DD_Multi_Select_Picklist_SOSL_Return__r
        );

        system.assertEquals(valuesWrapper.keyWord,'John','Invalid keyword');
        for (CDdMultiSelectPicklistWrapper value : valuesWrapper.values) {
            if (!users.isEmpty())
                system.assertNotEquals(value.value,users[0].Id,'Example_Object_Records exclude record did not work');
            system.assert(value.pillLabel.containsIgnoreCase('john'),'Did not find keyword in return value');
        }
    }

    @IsTest
    public static void testAggregateQuery() {
        CDdMultiSelectPicklistCtrl.InitWrapper initWrapper = CDdMultiSelectPicklistCtrl.getSearchInfo('Example_Aggregate_Query');
        system.assert(initWrapper.searchInfo.Query_and_Cache_on_Init__c == true,'Example_Aggregate_Query Query and Cache on Init is incorrect');
        system.assert(!initWrapper.lookupResults.isEmpty(),'Example_Aggregate_Query lookupResult is empty');
    }

    @IsTest
    public static void testSOSL() {
        CDdMultiSelectPicklistCtrl.InitWrapper initWrapper = CDdMultiSelectPicklistCtrl.getSearchInfo('Example_SOSL');
        system.assert(initWrapper.searchInfo.Query_and_Cache_on_Init__c == false,'Example_SOSL Query and Cache on Init is incorrect');
        List<DD_Multi_Select_Picklist_SOSL_Return__mdt> soslMdt = initWrapper.searchInfo.DD_Multi_Select_Picklist_SOSL_Return__r;
        system.assert(soslMdt != null && !soslMdt.isEmpty(),'Example_SOSL Did not have sosl cmt records');

        List<CDdMultiSelectPicklistWrapper> recordIdsToIgnore = new List<CDdMultiSelectPicklistWrapper>();
        List<User> users = [SELECT Id,Name FROM User WHERE Name LIKE 'John%' and isActive = true LIMIT 2];
        List<Id> fixedSearchResults = new List<Id>();
        if (!users.isEmpty()) {
            recordIdsToIgnore.add(createTestWrapper(users[0].Id,users[0].Name));

            if (users.size() == 2)
                fixedSearchResults.add(users[1].Id);
        }
        Test.setFixedSearchResults( fixedSearchResults );

        CDdMultiSelectPicklistValuesWrapper valuesWrapper = CDdMultiSelectPicklistCtrl.getLookupResultBySearchInfo(
            'John',
            JSON.serialize(recordIdsToIgnore),
            null,
            initWrapper.searchInfo,
            initWrapper.searchInfo.DD_Multi_Select_Picklist_SOSL_Return__r
        );

        system.assertEquals(valuesWrapper.keyWord,'John','Invalid keyword');
    }

    @IsTest
    public static void testPicklistMetadata() {
        CDdMultiSelectPicklistCtrl.InitWrapper initWrapper = CDdMultiSelectPicklistCtrl.getSearchInfo('Example_Object_Picklist');
        system.assert(initWrapper.searchInfo.Query_and_Cache_on_Init__c == true,'Example_Object_Picklist Query and Cache on Init is incorrect');
        system.assert(!initWrapper.lookupResults.isEmpty(),'Example_Object_Picklist Lookupresult is empty');
    }

    @IsTest
    public static void testStaticValues() {
        CDdMultiSelectPicklistCtrl.InitWrapper initWrapper = CDdMultiSelectPicklistCtrl.getSearchInfo('Example_Filter_Static_Values');
        system.assert(initWrapper.searchInfo.Query_and_Cache_on_Init__c == true,'Example_Filter_Static_Values Query and Cache on Init is incorrect');
        system.assert(!initWrapper.lookupResults.isEmpty(),'Example_Filter_Static_Values Lookupresult is empty');
    }

    @IsTest
    public static void testCustomSearch() {
        CDdMultiSelectPicklistCtrl.InitWrapper initWrapper = CDdMultiSelectPicklistCtrl.getSearchInfo('Example_Custom_Search');
        system.assert(initWrapper.searchInfo.Query_and_Cache_on_Init__c == false,'Example_Custom_Search Query and Cache on Init is incorrect');

        Map<String,Object> arguments = new Map<String,Object> {
            'IsActive' => 'true'
        };

        CDdMultiSelectPicklistValuesWrapper valuesWrapper = CDdMultiSelectPicklistCtrl.getLookupResultBySearchInfo(
            'John',
            CDdCoreConstants.BLANK_STRING,
            JSON.serialize(arguments),
            initWrapper.searchInfo,
            initWrapper.searchInfo.DD_Multi_Select_Picklist_SOSL_Return__r == null ?
                new List<DD_Multi_Select_Picklist_SOSL_Return__mdt>() : initWrapper.searchInfo.DD_Multi_Select_Picklist_SOSL_Return__r
        );

        system.assertEquals(valuesWrapper.keyWord,'John','Invalid keyword');
    }

    @isTest
    public static void testLookupResult() {
        CDdMultiSelectPicklistValuesWrapper valuesWrapper = CDdMultiSelectPicklistCtrl.getLookupResult(
            'John', '[]', null, 'Example_Object_Records');
        system.assertEquals(valuesWrapper.keyWord,'John','Invalid keyword');
    }

    @isTest
    public static void testIncreaseCodeCoverage() {

        CDdMultiSelectPicklistValuesWrapper valuesWrapper = new CDdMultiSelectPicklistValuesWrapper();

        List<CDdMultiSelectPicklistWrapper> toSort = new List<CDdMultiSelectPicklistWrapper>();
        toSort.add(createTestWrapper('1'));
        toSort.add(createTestWrapper('3'));
        toSort.add(createTestWrapper('5'));
        toSort.add(createTestWrapper('2'));
        toSort.add(createTestWrapper('4'));

        List<CDdMultiSelectPicklistWrapperSorter> dropdownLabelSorter = new List<CDdMultiSelectPicklistWrapperSorter>();
        List<CDdMultiSelectPicklistWrapperSorter> valueSorter = new List<CDdMultiSelectPicklistWrapperSorter>();
        for (CDdMultiSelectPicklistWrapper wrapper : toSort) {
            dropdownLabelSorter.add(new CDdMultiSelectPicklistWrapperSorter(wrapper));
            valueSorter.add(new CDdMultiSelectPicklistWrapperSorter(wrapper,'value'));
        }

        dropdownLabelSorter.sort();
        valueSorter.sort();
    }

    private static CDdMultiSelectPicklistWrapper createTestWrapper(String value) {
        return createTestWrapper(value,value);
    }

    private static CDdMultiSelectPicklistWrapper createTestWrapper(String value,String label) {
        CDdMultiSelectPicklistWrapper wrapper = new CDdMultiSelectPicklistWrapper();
        wrapper.dropDownLabel = label;
        wrapper.pillLabel = label;
        wrapper.value = value;
        return wrapper;
    }
}