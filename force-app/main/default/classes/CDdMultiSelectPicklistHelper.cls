/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Has methods to implement core logic (SOQL, SOSL, etc) of the lwcDdMultiSelectPicklist component
 *             Does inherited sharing - if called from CDdMultiSelectPicklistCtrl, it runs in With sharing mode
 *                                      if called from CDdMultiSelectPicklistWithoutSharingUtil, it runs in Without sharing mode
 */
public inherited sharing class CDdMultiSelectPicklistHelper {
    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Main method which routes request to the other helepr methods based on the type of the search
     * @param   String searchKeyword - Word to use as a search param
     *          String excludeItems - JSON string form of List<CDdMultiSelectPicklistWrapper>;
     *                                This has list of already selected records in the UI, so that it can be ignored for current search
     *          String arguments - JSON string form of Map<String,Object>;
     *                             This is used for the custom search type, to pass to the handling apex class
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - CMT used to know how to retreive data
     *          List<DD_Multi_Select_Picklist_SOSL_Return__mdt> sInfo_SOSL - List<CMT> which has info to formulate SOSL
     * @return  CDdMultiSelectPicklistValuesWrapper - Wrapper which has keyword and lookup result
     *                                                (if user is typing at a regular pace, its important to know which results stack against which keyword)
     */
    public static CDdMultiSelectPicklistValuesWrapper fetchLookupResult(String searchKeyWord, String excludeItems,
            String arguments, DD_Multi_Select_Picklist_Master__mdt sInfo,
            List<DD_Multi_Select_Picklist_SOSL_Return__mdt> sInfo_SOSL) {

        // Store the searchKeyword in another param (to return back later), and pre-process the searchKeyword
        String keyWord = searchKeyword;
        searchKeyWord = searchKeyWord.removeEnd('*');
        searchKeyword = String.escapeSingleQuotes(searchKeyWord);

        if (sInfo.Keyword_Search_Like_Operator__c == 'Contains')
            searchKeyWord = CDdCoreConstants.DELIMITER_PERCENT + searchKeyWord + CDdCoreConstants.DELIMITER_PERCENT;
        else if (sInfo.Keyword_Search_Like_Operator__c == 'Ends With')
            searchKeyWord = CDdCoreConstants.DELIMITER_PERCENT + searchKeyWord;
        else if (sInfo.Type__c == 'SOSL')
            searchKeyWord += '*';
        else
            searchKeyWord += CDdCoreConstants.DELIMITER_PERCENT;

        // To not show previously selected records again the UI dropdown, the component sends the items here
        // Process it to get a set of items to exclude
        Set<String> excludeItemsSet = sInfo.Exclude_Already_Selected_Records__c ?
            getItemsToExclude(excludeItems) : new Set<String>();

        List<CDdMultiSelectPicklistWrapper> values = new List<CDdMultiSelectPicklistWrapper>();
        // Depending on the type of operation, route to the appropriate helper methods
        switch on sInfo.Type__c {
            when 'Object Records' {
                values = fetchLookupResult_ObjectRecords(searchKeyword,sInfo,excludeItemsSet);
            }
            when 'Aggregate Query' {
                values = fetchLookupResult_AggregateQuery(searchKeyword,sInfo,excludeItemsSet);
            }
            when 'SOSL' {
                values = fetchLookupResult_SOSL(searchKeyword,sInfo,sInfo_SOSL,excludeItemsSet);
            }
            when 'Object Field Picklist Metadata' {
                values = fetchLookupResult_FieldPicklist(searchKeyword,sInfo,excludeItemsSet);
            }
            when 'Static Values (in DD Multi Select Picklist Search Value)' {
                values = fetchLookupResult_StaticValues(searchKeyword,sInfo,excludeItemsSet);
            }
            when 'Custom Search' {
                values = fetchLookupResult_CustomSearch(searchKeyWord,sInfo,excludeItemsSet,arguments);
            }
        }

        return new CDdMultiSelectPicklistValuesWrapper(keyWord,values);
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Method which does SOQL to query against object
     * @param   String searchKeyword - Word to use as a search param
     *          Set<String> excludeItemsSet - Items to exclude from search
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - CMT used to know how to retreive data
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data in wrapper
     */
    private static List<CDdMultiSelectPicklistWrapper> fetchLookupResult_ObjectRecords(String searchKeyword,
            DD_Multi_Select_Picklist_Master__mdt sInfo,Set<String> excludeItemsSet) {

        List<CDdMultiSelectPicklistWrapper> retVal = new List<CDdMultiSelectPicklistWrapper>();

        // Object needs to be accessible to the current users profile to perform this (Checking object access only, not FLS)
        // Helps with especially securing guest profile from accessing stuff in without sharing mode.
        if (!CDdUtilities.objectIsAccessible(sInfo.From__c))
            return retVal;

        // Keyword can be seached across multiple fields, this formulates the where clause accordingly
        String keywordWhereClause = CDdCoreConstants.BLANK_STRING;
        for (String keywordSearchField : sInfo.Keyword_Search_Field__c.split('\\,'))
            keywordWhereClause += keywordSearchField + ' LIKE :searchKeyword OR ';

        keywordWhereClause = ' (' + keywordWhereClause.removeEnd(' OR ') + ') ';

        // Creates dynamic where clause
        String whereClause = ' WHERE ' + keywordWhereClause +
            (String.isNotBlank(sInfo.Where_Clause__c) ? ' AND ' + sInfo.Where_Clause__c + CDdCoreConstants.DELIMITER_SPACE : CDdCoreConstants.BLANK_STRING) +
            (excludeItemsSet.isEmpty() ? CDdCoreConstants.BLANK_STRING : ' AND ' + sInfo.Exclude_Field_Name__c + ' NOT IN :excludeItemsSet ');

        // Creates dynamic query
        String query = 'SELECT ' + sInfo.Select__c +
            ' FROM ' + sInfo.From__c + whereClause +
            (String.isNotBlank(sInfo.Order_By__c) ? ' ORDER BY ' + sInfo.Order_By__c +CDdCoreConstants.BLANK_STRING : CDdCoreConstants.BLANK_STRING) +
            (sInfo.Limit__c != null ? ' LIMIT ' + Integer.valueOf(sInfo.Limit__c) : CDdCoreConstants.BLANK_STRING);

        //Creates the result to return back to the component
        for (sObject obj: Database.query(query)) {
            retVal.add(createWrapperForSobject(obj,sInfo));
        }
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Creates the CDdMultiSelectPicklistWrapper wrapper
     * @param   Sobject obj - SObject containing data
     *          Sobject sInfo - DD_Multi_Select_Picklist_Master__mdt records; this has the fields which has the format for returning data to the UI
     * @return  CDdMultiSelectPicklistWrapper - Resultant Wrapper
     */
    public static CDdMultiSelectPicklistWrapper createWrapperForSobject(
            Sobject obj, Sobject sInfo) {

        CDdMultiSelectPicklistWrapper w = new CDdMultiSelectPicklistWrapper(obj);

        // Populate wrapper fields by merging the data into the format specified in the CMT record's field
        w.value = decodeMergeString_ObjectRecords((String)sInfo.get('Value_Merge_Format__c'),obj);
        w.dropDownLabel = decodeMergeString_ObjectRecords((String)sInfo.get('Dropdown_Label_Merge_Format__c'),obj);
        w.pillLabel = decodeMergeString_ObjectRecords((String)sInfo.get('Pill_Label_Merge_Format__c'),obj);

        String dropDownSubLabel = (String)sInfo.get('Dropdown_SubLabel_Merge_Format__c');
        if (String.isNotBlank(dropDownSubLabel))
            w.dropDownSubLabel = decodeMergeString_ObjectRecords(dropDownSubLabel, obj);

        String iconSrc = (String)sInfo.get('IconSrc_Merge_Format__c');
        if (String.isNotBlank(iconSrc))
            w.iconSrc = decodeMergeString_ObjectRecords(iconSrc,obj);

        return w;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Creates Merge string
     * @param   String s - String to merge on
     *          Sobject obj - Object with data
     * @return  String - Resultant merged string
     */
    private static String decodeMergeString_ObjectRecords(String s, Sobject obj) {
        // Fields are provided in merge string in format {<FieldAPIName>}
        // Replace all {<FieldAPIName} with the value of the Field from the Sobject record
        Integer i = s.indexOf('{',0);
        while (i != -1) {
            Integer j = s.indexOf('}', i);
            if (j == -1)
                break;

            String mergeField = s.subString(i,++j);
            if (String.isBlank(mergeField))
                break;

            String field = mergeField.removeStart('{').removeEnd('}');

            // Gives you the field value from field in current obj or from a lookup field (x__c or y__r.z__c)
            String fieldVal = CDdUtilities.getFieldValAsString(obj,field,'String');

            s = s.replace(mergeField, String.isBlank(fieldVal) ? CDdCoreConstants.BLANK_STRING : fieldVal);
            i = s.indexOf('{', 0);
        }
        return s;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Method which does SOQL to query an aggregate query against object
     * @param   String searchKeyword - Word to use as a search param
     *          Set<String> excludeItemsSet - Items to exclude from search
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - CMT used to know how to retreive data
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data in wrapper
     */
    private static List<CDdMultiSelectPicklistWrapper> fetchLookupResult_AggregateQuery(String searchKeyword,
                DD_Multi_Select_Picklist_Master__mdt sInfo, Set<String> excludeItemsSet) {

        List<CDdMultiSelectPicklistWrapper> retVal = new List<CDdMultiSelectPicklistWrapper>();

        // Object needs to be accessible to the current users profile to perform this (Checking object access only, not FLS)
        // Helps with especially securing guest profile from accessing stuff in without sharing mode.
        if (!CDdUtilities.objectIsAccessible(sInfo.From__c))
            return retVal;

        // Keyword can be seached across multiple fields, this formulates the where clause accordingly
        String keywordWhereClause = CDdCoreConstants.BLANK_STRING;
        for (String keywordSearchField : sInfo.Keyword_Search_Field__c.split('\\,'))
            keywordWhereClause += keywordSearchField + ' LIKE :searchKeyword OR ';

        keywordWhereClause = ' (' + keywordWhereClause.removeEnd(' OR ') + ') ';

        // Creates dynamic where clause
        String whereClause = ' WHERE ' + keywordWhereClause +
            (String.isNotBlank(sInfo.Where_Clause__c) ? ' AND ' + sInfo.Where_Clause__c + CDdCoreConstants.DELIMITER_SPACE : CDdCoreConstants.BLANK_STRING) +
            (excludeItemsSet.isEmpty() ? CDdCoreConstants.BLANK_STRING : ' AND ' + sInfo.Exclude_Field_Name__c + ' NOT IN :excludeItemsSet ');

        // Creates dynamic query
        String query = 'SELECT ' + sInfo.Select__c +
            ' FROM ' + sInfo.From__c + whereClause +
            (String.isNotBlank(sInfo.Group_By__c) ? ' GROUP BY ' + sInfo.Group_By__c + CDdCoreConstants.DELIMITER_SPACE : CDdCoreConstants.BLANK_STRING) +
            (String.isNotBlank(sInfo.Order_By__c) ? ' ORDER BY ' + sInfo.Order_By__c + CDdCoreConstants.DELIMITER_SPACE : CDdCoreConstants.BLANK_STRING) +
            (sInfo.Limit__c != null ? ' LIMIT ' + Integer.valueOf(sInfo.Limit__c) : CDdCoreConstants.BLANK_STRING);

        // Run Aggregate query and parse the result
        // Note that this does have merge capabilities like fetchLookupResult_ObjectRecords
        for (AggregateResult agg: Database.query(query)) {
            CDdMultiSelectPicklistWrapper w = new CDdMultiSelectPicklistWrapper();
            w.value = (String)agg.get(sInfo.Value_Merge_Format__c);
            w.dropDownLabel = (String)agg.get(sInfo.Dropdown_Label_Merge_Format__c);
            w.pillLabel = (String)agg.get(sInfo.Pill_Label_Merge_Format__c);
            if (String.isNotBlank(sInfo.Dropdown_SubLabel_Merge_Format__c))
                w.dropDownSubLabel = String.valueOf(agg.get(sInfo.Dropdown_SubLabel_Merge_Format__c));
            if (String.isNotBlank(sInfo.IconSrc_Merge_Format__c))
                w.iconSrc = sInfo.IconSrc_Merge_Format__c;
            retVal.add(w);
        }

        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Method which does SOSL text search
     * @param   String searchKeyword - Word to use as a search param
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - CMT used to know how to retreive data
     *          List<DD_Multi_Select_Picklist_SOSL_Return__mdt> sInfo_SOSL - each mdt has the object,info of fields etc to formualate SOSL query
     *          Set<String> excludeItemsSet - Items to exclude from search
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data in wrapper
     */
    private static List<CDdMultiSelectPicklistWrapper> fetchLookupResult_SOSL(String searchKeyword,
            DD_Multi_Select_Picklist_Master__mdt sInfo, List<DD_Multi_Select_Picklist_SOSL_Return__mdt> sInfo_SOSL,
            Set<String> excludeItemsSet) {

        List<CDdMultiSelectPicklistWrapper> retVal = new List<CDdMultiSelectPicklistWrapper>();

        if (String.isBlank(searchKeyword) || sInfo_SOSL == null || sInfo_SOSL.isEmpty())
            return new List<CDdMultiSelectPicklistWrapper>();

        // Create base SOSL string from keyword and returning field (ALL fields, Name Fields, etc.)
        String sosl = 'Find {' + searchKeyword + '} in ' + sInfo.SOSL_Returning_Fields__c + ' RETURNING ';

        Map<String,DD_Multi_Select_Picklist_SOSL_Return__mdt> soslDefnMap = new Map<String,DD_Multi_Select_Picklist_SOSL_Return__mdt> ();

        // Iterate thru the sInfo_SOSL to formulate the per object SOSL
        for (DD_Multi_Select_Picklist_SOSL_Return__mdt soslDefn : sInfo_SOSL) {
            // Object needs to be accessible to the current users profile to perform this (Checking object access only, not FLS)
            // Helps with especially securing guest profile from accessing stuff in without sharing mode.
            if (!CDdUtilities.objectIsAccessible(soslDefn.SObject_Name__c))
                continue;

            // Create dynamic where clause
            String whereClause = CDdCoreConstants.BLANK_STRING;
            if (String.isNotBlank(soslDefn.Where_Clause__c))
                whereClause += ' WHERE ' + soslDefn.Where_Clause__c + CDdCoreConstants.DELIMITER_SPACE;

            if (String.isNotBlank(soslDefn.Exclude_Field_Name__c) &&
                    !excludeItemsSet.isEmpty())
                whereClause = whereClause + (String.isBlank(whereClause) ? ' WHERE ' : ' AND ') +
                     + soslDefn.Exclude_Field_Name__c + ' NOT IN :excludeItemsSet ';

            // Create dynamic SOSL query string
            sosl += soslDefn.SObject_Name__c +
                ' (' + soslDefn.Return_Fields__c + whereClause +
                     (String.isNotBlank(soslDefn.Order_By__c) ?
                            ' ORDER BY ' + soslDefn.Order_By__c + CDdCoreConstants.DELIMITER_SPACE : CDdCoreConstants.BLANK_STRING) +
                     (soslDefn.Limit__c != null ? ' LIMIT ' +
                        Integer.valueOf(soslDefn.Limit__c) : CDdCoreConstants.BLANK_STRING) +
                ' ), ';

            soslDefnMap.put(soslDefn.SObject_Name__c,soslDefn);
        }

        if (soslDefnMap.isEmpty())
            return retVal;

        sosl = sosl.trim().removeEndIgnoreCase( CDdCoreConstants.DELIMITER_COMMA);

        // Execute SOSL and create result list
        List<List<SObject>> searchResultsList = search.query(sosl);
        for (List<SObject> searchResults : searchResultsList) {
            for (SObject searchResult : searchResults) {
                DD_Multi_Select_Picklist_SOSL_Return__mdt soslDefn =
                    soslDefnMap.get(searchResult.getSObjectType().getDescribe().getName());

                retVal.add(createWrapperForSobject(searchResult,soslDefn));
            }
        }
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Method which returns picklist metadata
     * @param   String searchKeyword - Word to use as a search param
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - CMT used to know how to retreive data
     *          Set<String> excludeItemsSet - Items to exclude from search
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data in wrapper
     */
    private static List<CDdMultiSelectPicklistWrapper> fetchLookupResult_FieldPicklist(String searchKeyword,
            DD_Multi_Select_Picklist_Master__mdt sInfo,Set<String> excludeItemsSet) {

        //Gets picklist values
        Map<String, List<CDdPicklistUtil.PicklistOption>> pickOpts =
            CDdPicklistUtil.getPicklistOptions(sInfo.Picklist_Metadata_Object_name__c, sInfo.Picklist_Metadata_Field_Name__c);

        List<CDdMultiSelectPicklistWrapper> retVal = new List<CDdMultiSelectPicklistWrapper>();

        List<CDdMultiSelectPicklistWrapperSorter> sorter = new List<CDdMultiSelectPicklistWrapperSorter>();

        if (!pickOpts.isEmpty() && pickOpts.containsKey(sInfo.Picklist_Metadata_Field_Name__c)) {
            // Custom formatting is available {Label + Value} etc
            String format = String.isBlank(sInfo.Picklist_Metadata_Search_Label_Format__c) ?
                '{Label}' : sInfo.Picklist_Metadata_Search_Label_Format__c;

            for (CDdPicklistUtil.PicklistOption option : pickOpts.get(sInfo.Picklist_Metadata_Field_Name__c)) {
                if (excludeItemsSet.contains(option.value))
                    continue;
                // Create Wrapper
                CDdMultiSelectPicklistWrapper w = new CDdMultiSelectPicklistWrapper();
                w.value = option.value;
                String label = option.label;
                if (format == '{Value} - {Label}')
                    label = option.value + ' - ' + option.label;

                w.dropDownLabel = label;
                w.pillLabel = label;

                if (String.isNotBlank(sInfo.IconSrc_Merge_Format__c))
                    w.iconSrc = sInfo.IconSrc_Merge_Format__c;

                // Usually, you will use the sort order as given in the picklist metadata
                // But custom sort can also be done by proving the 'Force Sort' option
                if (String.isNotBlank(sInfo.Picklist_Metadata_Force_Sort_By__c))
                    sorter.add(new CDdMultiSelectPicklistWrapperSorter(w,sInfo.Picklist_Metadata_Force_Sort_By__c));
                else
                    retVal.add(w);
            }
        }
        // If Custom Sort is needed, perform the sort
        if (String.isNotBlank(sInfo.Picklist_Metadata_Force_Sort_By__c)) {
            sorter.sort();

            for (CDdMultiSelectPicklistWrapperSorter s : sorter) {
                retVal.add(s.w);
            }
        }
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Static values can be provided as child records to the main sInfo CMT in DD_Multi_Select_Picklist_Search_Value__mdt object.
     * @param   String searchKeyword - Word to use as a search param
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - CMT used to know how to retreive data
     *          Set<String> excludeItemsSet - Items to exclude from search
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data in wrapper
     */
    private static List<CDdMultiSelectPicklistWrapper> fetchLookupResult_StaticValues(String searchKeyword,
            DD_Multi_Select_Picklist_Master__mdt sInfo,Set<String> excludeItemsSet) {
        List<CDdMultiSelectPicklistWrapper> retVal = new List<CDdMultiSelectPicklistWrapper>();

        // Search in DD_Multi_Select_Picklist_Search_Value__mdt for the child static values and create result set.
        for (DD_Multi_Select_Picklist_Search_Value__mdt val :
                [SELECT Dropdown_Label__c,Dropdown_SubLabel__c,
                        Pill_Label__c,Value__c,Parent__c,Display_Sequence__c
                   FROM DD_Multi_Select_Picklist_Search_Value__mdt
                  WHERE Parent__c = :sInfo.Id
                    AND Value__c NOT IN :excludeItemsSet
               ORDER BY Display_Sequence__c asc]) {
            CDdMultiSelectPicklistWrapper w = new CDdMultiSelectPicklistWrapper();
            w.value = val.Value__c;
            w.dropDownLabel = val.Dropdown_Label__c;
            w.pillLabel = val.Pill_Label__c;
            if (String.isNotBlank(val.Dropdown_SubLabel__c))
                w.dropDownSubLabel = val.Dropdown_SubLabel__c;
            retVal.add(w);
        }
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Custom search is an option wherein a standard soql/sosl etc will not meet the requirement and you need to implement custom logic in Apex.
     *             Using this technique of interface means that one never needs to touch this code, but simply implement a class implementing the
     *             CDdMultiSelectPicklistSearchInterface interface (Example: CDdMultiSelectPicklistCustomExample)
     * @param   String searchKeyword - Word to use as a search param
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - CMT used to know how to retreive data
     *          Set<String> excludeItemsSet - Items to exclude from search
     *          String arguments - JSON string form of Map<String,Object>;
     *                             This is used for the custom search type, to pass to the handling apex class
     *
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data in wrapper
     */
    private static List<CDdMultiSelectPicklistWrapper> fetchLookupResult_CustomSearch(String searchKeyword,
            DD_Multi_Select_Picklist_Master__mdt sInfo,Set<String> excludeItemsSet, String arguments) {

        Type iType = null;
        CDdMultiSelectPicklistSearchInterface iClass = null;
        List<CDdMultiSelectPicklistWrapper> retVal =new List<CDdMultiSelectPicklistWrapper>();

        // Unpack the arguments
        Map<String,Object> args = String.isBlank(arguments) ?
            new Map<String,Object>() : (Map<String, Object>)JSON.deserializeUntyped(arguments);

        // Call the Apex class via the interface
        try {
            iType = Type.forName(sInfo.ApexClassName__c);
        } catch (Exception e) {
            CDdErrorUtilities.publishException('MultiSelect','DdMultiSelectPicklistHelper',null,
                CDdErrorUtilities.getFormattedException('fetchLookupResult_CustomSearch Type Not Found -- ClassName: ' + sInfo.ApexClassName__c,e));
            throw new AuraHandledException('MultiSelect - Class not found');
        }
        try {
            iClass = (CDdMultiSelectPicklistSearchInterface) iType.newInstance();
            retVal = iClass.getData(searchKeyword,sInfo,excludeItemsSet,args);
        } catch (Exception e) {
            CDdErrorUtilities.publishException('MultiSelect','DdMultiSelectPicklistHelper',null,
                CDdErrorUtilities.getFormattedException('fetchLookupResult_CustomSearch getData exception -- ClassName: ' + sInfo.ApexClassName__c,e));
            throw new AuraHandledException('Multiselect Exception : ' + e.getMessage());
        }
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription If we dont want to show the data in the dropdown which user has already selected, it will be passed here and we process it.
     * @param   String excludeItems - JSON string form of List<CDdMultiSelectPicklistWrapper>;
     *                                This has list of already selected records in the UI, so that it can be ignored for current search
     *
     * @return  List<String> - Resultant Data to ignore
     */
    public static Set<String> getItemsToExclude(String excludeItems) {
        // Deserialize the exclude Items and simply add 'value' variable to the returned set.
        List<CDdMultiSelectPicklistWrapper> excludeItemsList = String.isNotBlank(excludeItems) ?
            (List<CDdMultiSelectPicklistWrapper>)JSON.deserialize(excludeItems,List<CDdMultiSelectPicklistWrapper>.class) :
            new List<CDdMultiSelectPicklistWrapper>();

        Set<String> itemsToExclude = new Set<String>();
        if (excludeItemsList == null || excludeItemsList.isEmpty())
            return itemsToExclude;

        for (CDdMultiSelectPicklistWrapper item : excludeItemsList)
            itemsToExclude.add(item.value);

        return itemsToExclude;
    }
}