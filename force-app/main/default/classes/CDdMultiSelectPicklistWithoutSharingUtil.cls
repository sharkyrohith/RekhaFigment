/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription CDdMultiSelectPicklist code uses this to force 'without sharing' mode for the queries
 */
public without sharing class CDdMultiSelectPicklistWithoutSharingUtil {
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
    public static CDdMultiSelectPicklistValuesWrapper fetchLookupResult(
            String searchKeyWord, String excludeItems, String arguments,
            DD_Multi_Select_Picklist_Master__mdt sInfo,
            List<DD_Multi_Select_Picklist_SOSL_Return__mdt> sInfo_SOSL) {
        return CDdMultiSelectPicklistHelper.fetchLookupResult(
            searchKeyWord,excludeItems,arguments,sInfo,sInfo_SOSL
        );
    }
}