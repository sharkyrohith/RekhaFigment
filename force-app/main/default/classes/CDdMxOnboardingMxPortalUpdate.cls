/********************************************************************************************************************
* @author Lathika
* @date 
*
* @group Merchant Services
*
* @description: class to handle MX_ONBOARDING_UPDATE_INBOUND events using 'Mx Support Event' service
*
**************************************************************************************************************************************/
public class CDdMxOnboardingMxPortalUpdate implements CDdMxSupportEventInterface{

    @TestVisible
    private static final CDdMxSupportEventEnum MX_ONBOARDING_UPDATE_INBOUND = CDdMxSupportEventEnum.MX_ONBOARDING_UPDATE_INBOUND;
    public static String UPDATE_TYPE = CDdMxSxConstants.MX_ONBOARDING_MX_PORTAL_UPDATE_TYPE_INBOUND;
    public static String FILTERED_SOBJECT_IDS = 'sObjectIds';

    /** 
     * @description Return the Query Locator to the caller
     */
    public Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator(CDdMxOnboardingProcessorQueryBuilder.getStringQueryLocator());
        
    }
    /** 
     * @description sends the event details to be published to the CDdMxSupportEventPublisher class
     */
    public void publishEvents(String sObjectType, Set<Id> sObjectIds){
        new CDdMxSupportEventPublisher().publishEvents( MX_ONBOARDING_UPDATE_INBOUND, 
                                                        CDdMxSupportEventConfig.getQuerySObjectType(MX_ONBOARDING_UPDATE_INBOUND), 
                                                        sObjectIds);
    }

    /** 
     * @description handles the events published by the Mx Support Event Batch class
     */
    public void handleEvents(String sObjectType, Set<Id> sObjectIds){
        CDdMxOnboardingProcessor mxOnbPro = new CDdMxOnboardingProcessor(sObjectIds);
        mxOnbPro.execute();
    }
}