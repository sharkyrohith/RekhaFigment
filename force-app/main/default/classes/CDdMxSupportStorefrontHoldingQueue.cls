/********************************************************************************************************************
* @author Veera
* @date 04/28/2022
*
* @group Merchant Services
*
* @description: class to handle STOREFRONT_HOLDING_QUEUE events using 'Mx Support Event' service
*
**************************************************************************************************************************************/
public class CDdMxSupportStorefrontHoldingQueue implements CDdMxSupportEventInterface{

    @TestVisible
    private static final CDdMxSupportEventEnum STOREFRONT_HOLDING_QUEUE = CDdMxSupportEventEnum.STOREFRONT_HOLDING_QUEUE;
    @TestVisible
    private static String QUERY_SELECT = 'SELECT Id, AccountId FROM Case';
    private static String QUEUE_ID_CLAUSE = ' WHERE OwnerId = :{0}';
    private static String ORDER_BY_CLAUSE = ' ORDER BY CreatedDate desc';
    private static String LIMIT_CLAUSE = ' LIMIT {1} ';
    private static String QUERY_FILTERED_SOBJECT_IDS = ' AND Id IN :{1} ';

    public static String QUEUE_ID = CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE;
    public static String QUERY_LIMIT = String.valueOf(CDdMxSupportEventConfig.getQueryLimit(STOREFRONT_HOLDING_QUEUE));
    public static String FILTERED_SOBJECT_IDS = 'sObjectIds';

    /** 
     * @description Return the Query Locator to the caller
     */
    public Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator(String.format(QUERY_SELECT + QUEUE_ID_CLAUSE + ORDER_BY_CLAUSE + LIMIT_CLAUSE, new List<String>{'QUEUE_ID', QUERY_LIMIT}));
    }

    /** 
     * @description sends the event details to be published to the CDdMxSupportEventPublisher class
     */
    public void publishEvents(String sObjectType, Set<Id> sObjectIds){
        new CDdMxSupportEventPublisher().publishEvents( STOREFRONT_HOLDING_QUEUE, 
                                                        CDdMxSupportEventConfig.getQuerySObjectType(STOREFRONT_HOLDING_QUEUE), 
                                                        sObjectIds);
    }

    /** 
     * @description handles the events published by the Mx Support Event Batch class
     */
    public void handleEvents(String sObjectType, Set<Id> sObjectIds){
        Set<Id> parentAccountIds = new Set<Id>();
        List<Case> caseList = Database.query(getDbQueryFilteredBySObjectIds());
        for (Case c : caseList){
            parentAccountIds.add(c.AccountId);
        }
        if (!parentAccountIds.isEmpty()){        
            CDdMxSxEventPublisher.publishEventsStoreActive(parentAccountIds);
        }
    }

    private String getDbQueryFilteredBySObjectIds(){
        return String.format(QUERY_SELECT + QUEUE_ID_CLAUSE + QUERY_FILTERED_SOBJECT_IDS, new List<String>{'QUEUE_ID', FILTERED_SOBJECT_IDS});
    }
}