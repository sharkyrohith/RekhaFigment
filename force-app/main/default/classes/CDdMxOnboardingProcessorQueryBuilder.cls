/********************************************************************************************************************
* @author Lathika
* @date 
*
* @group Merchant Services
*
* @description: class to handle MX_ONBOARDING_UPDATE_INBOUND events using 'Mx Support Event' service
*
**************************************************************************************************************************************/
public class CDdMxOnboardingProcessorQueryBuilder {
    public static final CDdMxSupportEventEnum MX_ONBOARDING_UPDATE_INBOUND = CDdMxSupportEventEnum.MX_ONBOARDING_UPDATE_INBOUND;
    public static String QUERY_SELECT = 'SELECT Id, MenuMilestone_Updated_Reason__c, Proposed_Date_of_Activation__c, Menu_MenuUrl__c, UpdateType__c, StoreId__c, Business_Verification_Status__c FROM Mx_Onboarding__c';
    public static String UPDATE_TYPE_CLAUSE = ' WHERE UpdateType__c = :{0}';
    public static String LAST_N_DAYS_CLAUSE = ' AND LastModifiedDate = LAST_N_DAYS:{1}';
    public static String UPDATE_TYPE = CDdMxSxConstants.MX_ONBOARDING_MX_PORTAL_UPDATE_TYPE_INBOUND;
    public static String QUERY_LAST_N_DAYS = String.valueOf(CDdMxSupportEventConfig.getQueryLastNDays(MX_ONBOARDING_UPDATE_INBOUND));

    public static String QUERY_FILTERED_SOBJECT_IDS = ' AND Id IN :{1}';
    public static String FILTERED_SOBJECT_IDS = 'sObjectIds';

    public static String getStringQueryLocator(){
        return String.format(QUERY_SELECT + UPDATE_TYPE_CLAUSE + LAST_N_DAYS_CLAUSE,new List<String>{'UPDATE_TYPE', QUERY_LAST_N_DAYS});                                
    }

    public static String getDbQueryFilteredBySObjectIds(){
        return String.format(QUERY_SELECT  + UPDATE_TYPE_CLAUSE + QUERY_FILTERED_SOBJECT_IDS , new List<String>{'UPDATE_TYPE', FILTERED_SOBJECT_IDS});      
    }  
}