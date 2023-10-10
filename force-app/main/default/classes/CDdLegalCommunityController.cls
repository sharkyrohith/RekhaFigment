/**
 * @author      Raju
 * @date        June 2022
 * @decription  BIZS-1422/BIZS-1423 - Controller for the Legal Community LWC components.
 */
public with sharing class CDdLegalCommunityController {

    public class PicklistWrapper {
        @AuraEnabled public Map<String,CDdPicklistUtil.PicklistOption> countryOptions = new Map<String,CDdPicklistUtil.PicklistOption>();
        @AuraEnabled public Map<String,List<CDdPicklistUtil.PicklistOption>> languageOptions = new Map<String,List<CDdPicklistUtil.PicklistOption>>();
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the picklist option for country and language dropdowns
     * @param   legalType {String} - Type of Legal content to search against
     * @param   countryFromURL {String} - Country from URL
     * @param   langFromURL {String} - Langauage from URL
     * @return  PicklistWrapper - Picklist information
     */
    @AuraEnabled(cacheable=true)
    public static PicklistWrapper getPicklistOptions(String legalType,String countryFromURL,String langFromURL) {
        List<Legal_CMS_Content__c> legalContents =
           [SELECT Country__c,Country_Code__c,Default_Language_for_Country__c,Language__c,Salesforce_Language_Code__c,IETF_Language_Code__c,
                    (SELECT Id, Effective_Date__c, Status__c
                       FROM Legal_CMS_Content_Versions__r
                      WHERE Status__c = :CDdSupportConstants.STATUS_PUBLISHED
                      LIMIT 1)
              FROM Legal_CMS_Content__c
             WHERE Type__c = :legalType
               AND isActive__c = true
          ORDER BY Country__c,Language__c];

        PicklistWrapper retVal = new PicklistWrapper();
        Boolean defaultLangSetForCountryFromURL = false;
        String defaultLangForCountryFromURL;

        for (Legal_CMS_Content__c content : legalContents) {
            List<Legal_CMS_Content_Version__c> versions = content.Legal_CMS_Content_Versions__r;
            if (versions == null || versions.isEmpty()) {
                continue;
            }
            Boolean isCountryFromURL = content.Country_Code__c == countryFromURL;
            CDdPicklistUtil.PicklistOption countryOption = new CDdPicklistUtil.PicklistOption(content.Country__c,content.Country_Code__c,isCountryFromURL);

            if (!retVal.countryOptions.containsKey(content.Country_Code__c)) {
                retVal.countryOptions.put(content.Country_Code__c,countryOption);
            }

            if (!retVal.languageOptions.containsKey(content.Country_Code__c)) {
                retVal.languageOptions.put(content.Country_Code__c,new List<CDdPicklistUtil.PicklistOption>());
            }

            Boolean selectedLanguage = false;
            if (isCountryFromURL) {
                selectedLanguage = (String.isNotBlank(langFromURL) && (langFromURL == content.Salesforce_Language_Code__c || langFromURL == content.IETF_Language_Code__c)) ||
                    (String.isBlank(langFromURL) && content.Default_Language_for_Country__c);
                defaultLangSetForCountryFromURL = selectedLanguage || defaultLangSetForCountryFromURL;
            } else {
                selectedLanguage = content.Default_Language_for_Country__c;
            }

            CDdPicklistUtil.PicklistOption language = new CDdPicklistUtil.PicklistOption(
                content.Language__c,content.IETF_Language_Code__c,selectedLanguage
            );
            retVal.languageOptions.get(content.Country_Code__c).add(language);
            if (isCountryFromURL && content.Default_Language_for_Country__c) {
                defaultLangForCountryFromURL = content.IETF_Language_Code__c;
            }
        }

        if (!defaultLangSetForCountryFromURL && retVal.languageOptions.containsKey(countryFromURL) && String.isNotBlank(defaultLangForCountryFromURL)) {
            for (CDdPicklistUtil.PicklistOption option : retVal.languageOptions.get(countryFromURL)) {
                if (option.value == defaultLangForCountryFromURL) {
                    option.selected = true;
                }
            }
        }

        return retVal;
    }

    public class ContentWrapper {
        @AuraEnabled public String currentVersionContent {get;set;}
        @AuraEnabled public String currentVersionPublishedDate {get;set;}
        @AuraEnabled public String currentVersionEffectiveDate {get;set;}
        @AuraEnabled public String audienceType {get;set;}
        @AuraEnabled public String previousVersionContent {get;set;}
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the Legal content and previous published version information
     * @param   legalType {String} - Type of Legal content to search against
     * @param   countryFromURL {String} - Country from URL
     * @param   langFromURL {String} - Langauage from URL
     * @return  ContentWrapper - Content information
     */
    @AuraEnabled(cacheable=true)
    public static ContentWrapper getLegalContent(String legalType,String countryFromURL,String langFromURL) {
        Legal_CMS_Content_Version__c contentVersion = getLegalContentVersionRecord(legalType,countryFromURL,langFromURL);
        if (contentVersion == null) {
            throw new AuraHandledException('Unable to find the content for this page');
        }
        ContentWrapper retVal = new ContentWrapper();
        retVal.audienceType = contentVersion.Parent__r.Audience__c;
        retVal.currentVersionContent = contentVersion.Body_1__c +
            (String.isBlank(contentVersion.Body_2__c) ? CDdCoreConstants.BLANK_STRING : contentVersion.Body_2__c) +
            (String.isBlank(contentVersion.Body_3__c) ? CDdCoreConstants.BLANK_STRING : contentVersion.Body_3__c) +
            (String.isBlank(contentVersion.Body_4__c) ? CDdCoreConstants.BLANK_STRING : contentVersion.Body_4__c);

        if (contentVersion.Parent__r.Show_Multiple_Version__c && contentVersion.Effective_Date__c > Date.today() && contentVersion.Previous_Published__c != null) {
            retVal.previousVersionContent = contentVersion.Previous_Published__r.Body_1__c +
                (String.isBlank(contentVersion.Previous_Published__r.Body_2__c) ? CDdCoreConstants.BLANK_STRING : contentVersion.Previous_Published__r.Body_2__c) +
                (String.isBlank(contentVersion.Previous_Published__r.Body_3__c) ? CDdCoreConstants.BLANK_STRING : contentVersion.Previous_Published__r.Body_3__c) +
                (String.isBlank(contentVersion.Previous_Published__r.Body_4__c) ? CDdCoreConstants.BLANK_STRING : contentVersion.Previous_Published__r.Body_4__c);
            retVal.currentVersionEffectiveDate = contentVersion.Effective_Date__c.format();
            retVal.currentVersionPublishedDate =  contentVersion.Published_Date__c.format();
        }
        return retVal;
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the Legal CMS Version record corresponding to the params
     * @param   legalType {String} - Type of Legal content to search against
     * @param   countryFromURL {String} - Country from URL
     * @param   langFromURL {String} - Langauage from URL
     * @return  Legal_CMS_Content_Version__c - Legal CMS Version record corresponding to the params
     */
    private static Legal_CMS_Content_Version__c getLegalContentVersionRecord(String legalType,String countryFromURL,String langFromURL) {
        List<Legal_CMS_Content_Version__c> contentVersions =
           [SELECT Parent__r.Audience__c,Body_1__c,Body_2__c,Body_3__c,Body_4__c,Status__c,Effective_Date__c, Published_Date__c, Previous_Published__r.Effective_Date__c, Previous_Published__c,
                   Previous_Published__r.Body_1__c,Previous_Published__r.Body_2__c,Previous_Published__r.Body_3__c,Previous_Published__r.Body_4__c,Previous_Published__r.Status__c, Parent__r.Show_Multiple_Version__c
              FROM Legal_CMS_Content_Version__c
             WHERE Status__c = :CDdSupportConstants.STATUS_PUBLISHED
               AND Parent__r.Type__c = :legalType
               AND Parent__r.Country_Code__c = :countryFromURL
               AND (Parent__r.Salesforce_Language_Code__c = :langFromURL OR Parent__r.IETF_Language_Code__c = :langFromURL)
               AND Parent__r.isActive__c = true
          ORDER BY LastModifiedDate desc
             LIMIT 1];
        return contentVersions.isEmpty() ? null : contentVersions[0];
    }
}