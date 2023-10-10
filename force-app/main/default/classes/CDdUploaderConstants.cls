/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 11/15/2020
*
* @group Bulk Uploader
*
* @description This class maintains all constants relevant to S2N Bulk Uploader functionality
* 
**************************************************************************************************************************************/
public with sharing class CDdUploaderConstants {
    public static final Integer BULK_UPLOADER_PREVIEW_LIMIT = Integer.valueOf(System.Label.Bulk_Uploader_Preview_Limit);    
    public static final Integer BULK_UPLOADER_CREATE_BUSINESS_LIMIT = Integer.valueOf(System.Label.Bulk_Uploader_Create_Business_Limit);
    public static final Integer BULK_UPLOADER_CREATE_BIZ_MIN_CHILDCOUNT = Integer.valueOf(System.Label.Bulk_Uploader_Create_Biz_Min_ChildCount);
    public static final String BULK_UPLOADER_CREATE_BUSINESS_ERROR_MSG = System.Label.Bulk_Uploader_Create_Business_Error_Msg;
    public static final Boolean ENABLE_S2N_CREATE_BUSINESS = CDdExperimentSvc.getFeatureFlag('Enable_S2N_Create_Business__c');    
    public static final String SOBJECT_TYPE_OPPPORTUNITY = 'Opportunity';
    public static final String SOBJECT_FIELD_API_NAME_ID = 'Id';
    public static final String OPPORTUNITY_FIELD_API_NAME_STAGE_NAME = 'StageName';
    public static final String OPPORTUNITY_FIELD_API_NAME_PRIMARY_QUOTE_ID = 'SBQQ__PrimaryQuote__c';
    public static final String OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final List<String> OPPORTUNITY_ADDITIONAL_FIELDS = 
                                                    new List<String>{
                                                                        OPPORTUNITY_FIELD_API_NAME_STAGE_NAME,
                                                                        OPPORTUNITY_FIELD_API_NAME_PRIMARY_QUOTE_ID
                                                                    };
    public static final String SOQL_QUERY_FILTER_OPPORTUNITY_IDS = ' Id IN :opportunityIds ';
    public static final String SOQL_QUERY_OPPORTUNITY_FOR_ADDITIONAL_FIELDS = 'SELECT Id, '
                                        + String.join(OPPORTUNITY_ADDITIONAL_FIELDS, ', ')
                                        + ' FROM ' + SOBJECT_TYPE_OPPPORTUNITY
                                        + ' WHERE ' + SOQL_QUERY_FILTER_OPPORTUNITY_IDS;                                                                    
    public static final String ERROR_MESSAGE_OPPORTUNITY_STAGE_NOT_CLOSED_WON 
                                    = 'Opportunity must be in the "Closed Won" stage.';                                                                    
}