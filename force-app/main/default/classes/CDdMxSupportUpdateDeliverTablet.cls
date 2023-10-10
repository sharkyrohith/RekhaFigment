/********************************************************************************************************************
* @author Veera
* @date 04/28/2022
*
* @group Merchant Services
*
* @description: class to handle UPDATE_DELIVER_TABLET events using 'Mx Support Event' service
*
**************************************************************************************************************************************/
public class CDdMxSupportUpdateDeliverTablet implements CDdMxSupportEventInterface{

    @TestVisible
    private static final CDdMxSupportEventEnum UPDATE_DELIVER_TABLET = CDdMxSupportEventEnum.UPDATE_DELIVER_TABLET;

    private static String QUERY_SELECT = 'SELECT Id, AccountId, RecordTypeId, Status, Request_Type__c FROM Case';
    private static String RECORD_TYPE_ID_CLAUSE = ' WHERE RecordTypeId = :{0}';
    private static String STATUS_CLAUSE = ' AND Status IN :{1}';
    private static String REQUEST_TYPE_CLAUSE = ' AND Request_Type__c IN :{2}';//BASD-35044
    private static String LAST_N_DAYS_CLAUSE = ' AND LastModifiedDate = LAST_N_DAYS:{3}';//BASD-35044

    public static String RECORD_TYPE_ID = CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS;
    public static List<String> CASE_STATUSES = new List<String>{'Shipped','Received', 'Dead', 'Returned to Sender'};
    public static String QUERY_LAST_N_DAYS = String.valueOf(CDdMxSupportEventConfig.getQueryLastNDays(UPDATE_DELIVER_TABLET));
    public static List<String> REQUEST_TYPE_VALUES = CDdMxSxConstants.REQUEST_TYPE_FITER_VALUES_UPDATE_DELIVER_TABLET;//BASD-35044

    private static String QUERY_FILTERED_SOBJECT_IDS = ' AND Id IN :{3}';//BASD-35044
    public static String FILTERED_SOBJECT_IDS = 'sObjectIds';

    /** 
     * @description Return the Query Locator to the caller
     * BASD-35044 : Added the filter with Specific Filter Values of Request Type on Case.
     */
    public Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator(String.format(QUERY_SELECT + RECORD_TYPE_ID_CLAUSE + STATUS_CLAUSE + REQUEST_TYPE_CLAUSE + LAST_N_DAYS_CLAUSE, 
                                        new List<String>{'RECORD_TYPE_ID', 'CASE_STATUSES', 'REQUEST_TYPE_VALUES',QUERY_LAST_N_DAYS}));
    }

    /** 
     * @description sends the event details to be published to the CDdMxSupportEventPublisher class
     */
    public void publishEvents(String sObjectType, Set<Id> sObjectIds){
        new CDdMxSupportEventPublisher().publishEvents( UPDATE_DELIVER_TABLET, 
                                                        CDdMxSupportEventConfig.getQuerySObjectType(UPDATE_DELIVER_TABLET), 
                                                        sObjectIds);
    }

    /** 
     * @description handles the events published by the Mx Support Event Batch class
     */
    public void handleEvents(String sObjectType, Set<Id> sObjectIds){
        String querywithIdsFilter = getDbQueryFilteredBySObjectIds();
        List<Case> caseList = Database.query(querywithIdsFilter);
        if (!caseList.isEmpty()){
            CDdCaseMilestone.updateDeliverTabletMilestone(caseList);
        }
    }
    //BASD-35044 - Updated the query to add Request Type distinct values
    private String getDbQueryFilteredBySObjectIds(){
        return String.format(QUERY_SELECT + RECORD_TYPE_ID_CLAUSE + STATUS_CLAUSE + REQUEST_TYPE_CLAUSE + QUERY_FILTERED_SOBJECT_IDS, 
        new List<String>{'RECORD_TYPE_ID', 'CASE_STATUSES','REQUEST_TYPE_VALUES', FILTERED_SOBJECT_IDS});
    }
}