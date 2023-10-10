/**
 * @author      Raju
 * @date        June 2022
 * @decription  Legal CMS Content / Legal Community Test factory.
 */
 public with sharing class CDdLegalCmsTestFactory {
    public static final String PRIVACY_POLICY = 'cx-privacy-policy';

    public static final String UNITED_STATES = 'United States';
    public static final String US = 'US';

    public static final String CANADA = 'Canada';
    public static final String CA = 'CA';

    public static final String LANG_ENGLISH = 'English';
    public static final String LANG_IETF_EN_US = 'en-US';
    public static final String LANG_SF_EN_US = 'en_US';

    public static final String LANG_SPANISH = 'Spanish (Español)';
    public static final String LANG_IETF_ES_US = 'es-US';
    public static final String LANG_SF_ES = 'es';

    public static final String LANG_IETF_EN_CA = 'en-CA';
    public static final String LANG_SF_EN_CA = 'en_US';

    public static final String ALL_AUDIENCE =  'Mx;Cx;Dx;';

    /**
    * @description Create and Optionally insert a Legal CMS Content Record
    */
    public static Legal_CMS_Content__c createLegalCmsContent(String type, String country, String language, Boolean shouldInsert) {
        String countryCode;
        String ietfLangCode;
        String sfLangCode;

        switch on country {
            when 'United States' {
                countryCode = US;
                switch on language {
                    when 'English' {
                        ietfLangCode = LANG_IETF_EN_US;
                        sfLangCode = LANG_SF_EN_US;
                    }
                    when 'Spanish (Español)' {
                        ietfLangCode = LANG_IETF_ES_US;
                        sfLangCode = LANG_SF_ES;
                    }
                }
            }
            when 'Canada' {
                countryCode = CA;
                switch on language {
                    when 'English' {
                        ietfLangCode = LANG_IETF_EN_CA;
                        sfLangCode = LANG_SF_EN_CA;
                    }
                }
            }
        }

        Legal_CMS_Content__c content = new Legal_CMS_Content__c(
            isActive__c = true,
            Legal_Hub_Label__c =  type,
            Audience__c = ALL_AUDIENCE,
            Country__c = country,
            Country_Code__c = countryCode,
            IETF_Language_Code__c = ietfLangCode,
            Language__c = language,
            Salesforce_Language_Code__c = sfLangCode,
            Type__c = type,
            Show_Multiple_Version__c = true
        );

        if (shouldInsert) {
            insert content;
        }

        return content;
    }

    /**
    * @description Create and Optionally insert a Legal CMS Content Version Record
    */
    public static Legal_CMS_Content_Version__c createLegalCmsContentVersion(String parentId,Integer majorVersion,Integer minorVersion,Boolean shouldInsert) {
        Legal_CMS_Content_Version__c contentVersion = new Legal_CMS_Content_Version__c(
            Body_1__c = PRIVACY_POLICY,Body_2__c = PRIVACY_POLICY,
            Major_Version__c = majorVersion, Minor_Version__c = minorVersion,
            Parent__c = parentId,
            Status__c = CDdSupportConstants.STATUS_DRAFT
        );

        if (shouldInsert) {
            insert contentVersion;
        }

        return contentVersion;
    }

}