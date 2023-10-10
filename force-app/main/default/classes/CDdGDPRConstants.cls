/**
* @date 08/31/2021
*
* @description Constants class for GDPR related triggers and classes.

**/

public with sharing class CDdGDPRConstants {

    public static final String MX_PERSONA_VALUE= 'MX';
    public static final String CX_PERSONA_VALUE= 'CX';
    public static final String DX_PERSONA_VALUE= 'DX';
    public static final String DDFW_PERSONA_VALUE = 'DDFW';
    public static final List<String> EXCLUDED_DOMAINS = new List<String>{
                                                            'guest.doordash.com'
                                                            };
    public static final String SEPARATOR = ';';
    
    public static final String ACCOUNT_OBJECT = 'Account';
    public static final String PERSON_FIELD = 'IsPersonAccount';
    public static final String PERSON_OPT_OUT_FIELD = 'PersonHasOptedOutOfEmail';
    public static final String PERSON_OPT_EMAIL_LOG_FIELD = 'OptOutEmail__pc';

    public static final String ACCOUNT_DDFW_RECORD_TYPE = 'DoorDash for Business';

    public static final String PLATFORM_CACHE_TIMESTAMP = 'local.DoorDash.cassieTokenTimeStamp';
    public static final String PLATFORM_CACHE_TOKEN = 'local.DoorDash.cassieToken';
    public static final Integer PLATFORM_CACHE_TTL = 300;

    public static final String CASSIE_UPDATE_METHOD_TYPE = 'Single';

    public static final String CREATE_CONTACT_EVENT_SERVICE = 'CreateContact';
    public static final String SUBSCRIPTION_EVENT_SERVICE = 'Subscription';

    public static final String CASE_LANGUAGE_FIELD = 'Language__c';
    public static final String DEFAULT_LANGUAGE = 'default';
    
    public static final Map<String,String> SUBSCRIPTION_FIELDSETS= 
                                                                new Map<String,String>{
                                                                    'Account' => 'GDPR_Account_Email_Field_Set',
                                                                    'Contact' => 'GDPR_Contact_Email_Field_Set',
                                                                    'Lead'    => 'GDPR_Lead_Email_Field_Set'  
                                                                };
    public static final Map<String,String> OPT_OUT_FIELD= 
                                                        new Map<String,String>{
                                                            'Account' => 'Email_Opt_Out__c',
                                                            'Contact' => 'HasOptedOutOfEmail',
                                                            'Lead' =>'HasOptedOutOfEmail'
                                                        };
                                                            
    public static final Map<String,Set<String>> PERSONA_OBJECTS= 
                                                        new Map<String,Set<String>>{
                                                            MX_PERSONA_VALUE => new Set<String>{'Account','Contact','Lead'},
                                                            DDFW_PERSONA_VALUE => new Set<String>{'Account','Contact','Lead'},
                                                            CX_PERSONA_VALUE => new Set<String>{'Account','Contact'},
                                                            DX_PERSONA_VALUE => new Set<String>{'Account','Contact'}
                                                        };
    public static final Map<String,Set<String>> ADDITIONAL_FIELDS= 
                                                        new Map<String,Set<String>>{
                                                            'Account' => new Set<String>{'CustomerNo__pc','DasherNo__pc','recordtypeid','MerchantNo__c'},
                                                            'Contact' => new Set<String>{'CustomerNo__c','DasherNo__c','IsPersonAccount','Account_Record_Type_Name__c'},
                                                            'Lead' =>  new Set<String>{'Name', 'RecordTypeId'}
                                                        };
    public static final Map<String,String> OPT_EMAIL_LOG= 
                                                        new Map<String,String>{
                                                            'Account' => 'OptOutEmail__c',
                                                            'Contact' => 'OptOutEmail__c',
                                                            'Lead' =>'OptOutEmail__c'
                                                        };
    public static final List<String> CASE_QUERY_FIELDS = 
                                                        new List<String>{
                                                            CASE_LANGUAGE_FIELD,
                                                            'AccountId',
                                                            'Account.Id','Account.CustomerNo__pc','Account.DasherNo__pc','Account.recordtypeid','Account.MerchantNo__c',
                                                            'ContactId',
                                                            'Contact.Id','Contact.CustomerNo__c','Contact.DasherNo__c','Contact.IsPersonAccount','Contact.Account_Record_Type_Name__c'
                                                        };
}