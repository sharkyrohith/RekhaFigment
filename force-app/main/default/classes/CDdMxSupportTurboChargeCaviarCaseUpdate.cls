/********************************************************************************************************************
* @author Lathika
* @date 02/2023
*
* @group Merchant Services
*
* @description: class to handle Caviar Case Updates Related to Turbo Charge.
* handle CAVIAR_TURBO_CHARGE_UPDATE events using 'Mx Support Event' service
* Queries the Caviar Onboarding Case :Opp Platform = Caviar and Doordash, Pxp_HandOffdate = today, case status = ready to Activate
* Update the case ststus = Onboaring ads and Promo, Case owner = Queue (Onboarding ads and Promo)
*
**************************************************************************************************************************************/
public class CDdMxSupportTurboChargeCaviarCaseUpdate implements CDdMxSupportEventInterface{

    public static final CDdMxSupportEventEnum CAVIAR_TURBO_CHARGE_UPDATE = CDdMxSupportEventEnum.CAVIAR_TURBO_CHARGE_UPDATE;
    private static String QUERY_SELECT = 'SELECT Id, RecordTypeId, Status FROM Case';
    private static String RECORD_TYPE_ID_CLAUSE = ' WHERE RecordTypeId = :{0}';
    private static String OPPORTUNITY_PLATFORM_CLAUSE = ' AND opportunity_name__r.PLatform__c = :{1}';
    private static String PXP_HANDOFF_DATE_CLAUSE = ' AND MxP_Handoff_Date__c != null';
    private static String LAST_N_DAYS_CLAUSE = ' AND LastModifiedDate = LAST_N_DAYS:{2}';
    private static String LIMIT_CLAUSE = ' LIMIT {3} ';

    public static String RECORD_TYPE_ID = CDdSchemaUtils.CASE_RT.caviarOnboardingId();
    public static String OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH  = CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH;
    public static String QUERY_LAST_N_DAYS = String.valueOf(CDdMxSupportEventConfig.getQueryLastNDays(CAVIAR_TURBO_CHARGE_UPDATE));
    public static String QUERY_LIMIT = String.valueOf(CDdMxSupportEventConfig.getQueryLimit(CAVIAR_TURBO_CHARGE_UPDATE));

    /**
     * @description Return the Query Locator to the caller
     */
    public Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator(String.format(QUERY_SELECT + RECORD_TYPE_ID_CLAUSE + OPPORTUNITY_PLATFORM_CLAUSE + PXP_HANDOFF_DATE_CLAUSE  + LAST_N_DAYS_CLAUSE + LIMIT_CLAUSE,
        new List<String>{'RECORD_TYPE_ID', 'OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH', QUERY_LAST_N_DAYS, QUERY_LIMIT}));

    }

    /**
     * @description sends the event details to be published to the CDdMxSupportEventPublisher class
     */
    public void publishEvents(String sObjectType, Set<Id> sObjectIds){
        new CDdMxSupportEventPublisher().publishEvents( CAVIAR_TURBO_CHARGE_UPDATE,
                                                        CDdMxSupportEventConfig.getQuerySObjectType(CAVIAR_TURBO_CHARGE_UPDATE),
                                                        sObjectIds);
    }

    /**
     * @description handles the events published by the Mx Support Event Batch class
     */
    public void handleEvents(String sObjectType, Set<Id> sObjectIds){
        CDdMxSxTurboChargeHandler mxSxTurboChargeHandler  = new CDdMxSxTurboChargeHandler(sObjectIds);
        mxSxTurboChargeHandler.performUpdates();
    }
}