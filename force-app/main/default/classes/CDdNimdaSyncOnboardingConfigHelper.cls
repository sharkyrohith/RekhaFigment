/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 12/07/2020
*
* @group Nimda
*
* @description This is the config helper class that queries/returns information found in the following custom metadata
* - Nimda_Store_Field_Definition__mdt 
*   (config that maintains the various actions available for STN and Bulk Upload)
* - Nimda_Onboarding_Field__mdt 
*   (A collection of Nimda Onboarding Field definitions associated with a 
*   specific Nimda Onboarding step. It is also used to prepare a data model template for a form (STN tool) 
*   that supports a Nimda Step such as 'Product and Pricing Onboarding')
* 
**************************************************************************************************************************************/
public class CDdNimdaSyncOnboardingConfigHelper {
    public static final String KEY = 'key';
    public static final String MODE = 'mode';
    public static final String ICONNAME = 'iconName';
    public static final String LABEL = 'label';
    public static final String ALTERNATIVETEXT = 'alternativeText';
    public static final String TITLE = 'title';
    public static final String VALUE = 'value';
    public static final String VERSION = 'version';
    public static final String DISABLED = 'disabled';
    public static final String HELPTEXT = 'helpText';
    public static final String FIELD_ATTRIBUTE_LABEL = 'label';
    public static final String FIELD_ATTRIBUTE_PROPERTY = 'property';
    public static final String FIELD_ATTRIBUTE_TYPE = 'type';
    public static final String FIELD_ATTRIBUTE_SCALE = 'scale';
    public static final String FIELD_ATTRIBUTE_READ_ONLY = 'readOnly';
    public static final String FIELD_ATTRIBUTE_OPTIONS = 'options';
    public static final String FIELD_ATTRIBUTE_OLD_VALUE = 'oldValue';
    public static final String FIELD_ATTRIBUTE_NEW_VALUE = 'newValue';
    public static final String NIMDA_ONBOARDING_SQL_QUERY_FIELDS = 'SELECT Id, Label, DeveloperName, Version__c '
                                                    + ', Active__c, Custom_Permission__c, Display_Name__c, Display_Name_ja__c '
                                                    + ', Mode__c, Sequence__c, Step__c, Store_Exists_On_Account__c, Is_Change_of_Ownership__c, Help_Text__c ';
    public static final String NIMDA_ONBOARDING_SQL_FROM =  ' FROM Nimda_Onboarding_Step__mdt ';
    public static final String NIMDA_ONBOARDING_SQL_WHERE =  ' WHERE Active__c = true ';
    public static final String NIMDA_ONBOARDING_SQL_ORDER_BY =  ' ORDER BY Sequence__c ASC ';
    public static String NIMDA_ONBOARDING_SQL_PARAMETERIZED = NIMDA_ONBOARDING_SQL_QUERY_FIELDS
                                                                    + NIMDA_ONBOARDING_SQL_FROM
                                                                    + NIMDA_ONBOARDING_SQL_WHERE
                                                                    + '{0}'
                                                                    + NIMDA_ONBOARDING_SQL_ORDER_BY;
    /**
    * @description Return a Collection of Map object with Nimda steps and corresponding attributes available 
    * for display on the STN Tool Home Component. 
    * If storeExistsOnAccount == true,
    *   then return the Nimda Steps relevant to update
    * If storeExistsOnAccount == false,
    *   then return the Nimda Steps relevant to create    
    * @param Boolean storeExistsOnAccount
    * @return <Map<String, Object>> A collection of Map object
    **/
    public static List<Map<String, Object>> getSendToNimdaSteps(Boolean storeExistsOnAccount,Boolean isChangeOfOwnership) {
        return getSteps(new Map<String, Object>{
                        'Store_Exists_On_Account__c' => storeExistsOnAccount,
                        'Is_Send_To_Nimda__c' => true,
                        'Is_Change_of_Ownership__c' => isChangeOfOwnership
                            
                    });
    }
    /**
    * @description Return a Collection of Map object with Nimda bulk steps and corresponding attributes available 
    * for display on the Bulk Uploader Actions component
    * @return <Map<String, Object>> A collection of Map object
    **/
    public static List<Map<String, Object>> getBulkSteps() {
        return getSteps(new Map<String, Object>{
            'Is_Bulk__c' => true
        });        
    }
    /**
    * @description Return a Collection of Map object with Nimda steps and corresponding attributes available for display on the Nimda Home Component
    * @param Map<String, Object> A collection of field name/value pairs
    * @return <Map<String, Object>> A collection of Map object
    **/
    public static List<Map<String, Object>> getSteps(Map<String, Object> params) {
        List<Map<String, Object>> retVal = new List<Map<String, Object>>();
        String locale = UserInfo.getLocale();
        String addtionalQueryParams = '';
        for (String field : params.keySet()){
            addtionalQueryParams += ' AND ' + field + ' = ' + params.get(field) + ' ';
        }
        for (Nimda_Onboarding_Step__mdt config : Database.query(String.format(NIMDA_ONBOARDING_SQL_PARAMETERIZED, new List<String>{addtionalQueryParams}))){
            Map<String, Object> stepAndAttributes = new Map<String, Object>();
            stepAndAttributes.put(KEY, config.Sequence__c);
            stepAndAttributes.put(MODE, config.Mode__c);
            stepAndAttributes.put(ICONNAME,'standard:record_' + config.Mode__c);
            stepAndAttributes.put(LABEL, getLocalizedNimdaStepLabel(config, locale));
            stepAndAttributes.put(ALTERNATIVETEXT, config.Display_Name__c);
            stepAndAttributes.put(TITLE, config.Display_Name__c);
            stepAndAttributes.put(VALUE, config.Step__c);
            stepAndAttributes.put(VERSION, config.Version__c);
            stepAndAttributes.put(DISABLED, String.isNotBlank(config.Custom_Permission__c) 
                                                ? !FeatureManagement.checkPermission(config.Custom_Permission__c)
                                                : false
                                            );
           stepAndAttributes.put(HELPTEXT, config.Help_Text__c);                               
            retVal.add(stepAndAttributes);
        }
        return retVal;
    }
    
    private static String getLocalizedNimdaStepLabel(Nimda_Onboarding_Step__mdt config, String locale) {
        if (locale == CDdCoreConstants.JAPAN_LOCALE) {
            return config.Display_Name_ja__c;
        }
        return config.Display_Name__c;
    }
    /**
    * @description Return all the field properties associated with the input onboarding step
    * @param String Input Onboarding Step Name
    * @return List<String> Return the Collection of field properties
    **/     
    public static List<String> getAllFieldProperties(String onboardingStepName){
        Set<String> fieldProperties = new Set<String>();
        Map<String, List<Map<String, Object>>> dataModelTemplate = getDataModelTemplate(onboardingStepName);
        for (String table : dataModelTemplate.keySet()){
            for (Map<String, Object> onboardingField : dataModelTemplate.get(table)){
                if (onboardingField.containsKey(FIELD_ATTRIBUTE_PROPERTY) 
                    && onboardingField.get(FIELD_ATTRIBUTE_PROPERTY)!=null 
                    && (String.isNotBlank((String)onboardingField.get(FIELD_ATTRIBUTE_PROPERTY)))){
                    fieldProperties.add((String)onboardingField.get(FIELD_ATTRIBUTE_PROPERTY));
                }
            }
        }
        return new List<String>(fieldProperties);
    }
    /**
    * @description Return the data model template for the input onboarding step
    * @param String Input Onboarding Step Name
    * @return Map<String, List<Map<String, Object>>> Return the Data Model template
    **/    
    public static Map<String, List<Map<String, Object>>> getDataModelTemplate(String onboardingStepName) {
        Map<String, List<Map<String, Object>>> retVal = new Map<String, List<Map<String, Object>>>();
        for (Nimda_Onboarding_Step__mdt  step : [SELECT Id, Step__c, 
                                                    (SELECT Table__c, Label__c, Property__c, Type__c, ReadOnly__c, 
                                                    Options__c, Scale__c, Sequence__c 
                                                    FROM Nimda_Onboarding_Fields__r
                                                    WHERE Is_Active__c = true 
                                                    ORDER BY Table__c, Sequence__c ASC) 
                                                FROM Nimda_Onboarding_Step__mdt 
                                                WHERE Step__c = :onboardingStepName]){
            for (Nimda_Onboarding_Field__mdt field : step.Nimda_Onboarding_Fields__r){
                if (retVal.containsKey(field.Table__c)){
                    retVal.get(field.Table__c).add(getDataModelAttributes(field));
                } else {
                    retVal.put(field.Table__c, new List<Map<String, Object>>{getDataModelAttributes(field)});
                }
            }
        }
        return retVal;
    }
    /**
    * @description Populate and return the data model attributes from the Onboarding Field configuration record
    **/ 
    private static Map<String, Object> getDataModelAttributes(Nimda_Onboarding_Field__mdt field){
        return new Map<String, Object>{
            FIELD_ATTRIBUTE_LABEL => field.Label__c,
            FIELD_ATTRIBUTE_PROPERTY => field.Property__c,
            FIELD_ATTRIBUTE_TYPE => field.Type__c,
            FIELD_ATTRIBUTE_SCALE => (field.Scale__c!=null ? Integer.valueOf(field.Scale__c) : null),
            FIELD_ATTRIBUTE_READ_ONLY => field.ReadOnly__c,
            FIELD_ATTRIBUTE_OPTIONS => (field.Options__c!=null ? field.Options__c.split(';') : null),
            FIELD_ATTRIBUTE_OLD_VALUE => null,
            FIELD_ATTRIBUTE_NEW_VALUE => null
        };
    }
}