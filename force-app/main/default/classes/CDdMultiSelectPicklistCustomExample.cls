/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Example of how to implement 'Custom Search' functionality of lwcDdMultiSelectPicklist LWC Component
 *
 * Class implements CDdMultiSelectPicklistSearchInterface interface and its getData Method
 *
 * In your code, if you are using without sharing, make sure to use CDdUtilities.objectIsAccessible(sObjectName)/
 * WITH SECURITY ENFORCED soql / Security.stripInaccessible for security
 */
public with sharing class CDdMultiSelectPicklistCustomExample implements CDdMultiSelectPicklistSearchInterface {
    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Accepts Arguments etc, and has custom code to return data back to the UI
     * @param   String searchKeyword - Word to use as a search param
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - Driving CMT which has the config for the search
     *          Set<String> excludeItemsSet - This has list of already selected records in the UI, so that it can be ignored for current search
     *          Map<String, Object> args - Has Arguments passed by the UI for dynamic queries, etc.
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data
     */
    public List<CDdMultiSelectPicklistWrapper> getData(String searchKeyword,
            DD_Multi_Select_Picklist_Master__mdt sInfo,
            Set<String> excludeItemsSet,Map<String, Object> args) {
        List<CDdMultiSelectPicklistWrapper> retVal = new List<CDdMultiSelectPicklistWrapper>();

        // If there is 'IsActive' in the args, then it adds the dynamic param to the query
        String query =
            'SELECT Id, Name, Manager.Name, Email, Profile.Name ' +
            '    FROM User ' +
            ' WHERE Name LIKE :searchKeyword ' +
            (excludeItemsSet.isEmpty() ? '' : ' AND Id NOT IN :excludeItemsSet ') +
            (args.containsKey('IsActive') ?
                ' AND IsActive = ' + (String)args.get('IsActive') + CDdCoreConstants.DELIMITER_SPACE : CDdCoreConstants.BLANK_STRING) +
            ' ORDER BY Name ' +
            ' LIMIT 10';

        for (User usr: Database.query(query)) {
            // Passes Sobject and Search Info CMT to populate various fields (value,dropdownLabel,dropdownSubLabel, etc)
            retVal.add(CDdMultiSelectPicklistHelper.createWrapperForSobject(usr,sInfo));
        }
        return retVal;
    }
}