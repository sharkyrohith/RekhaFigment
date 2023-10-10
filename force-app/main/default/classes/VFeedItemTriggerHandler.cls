/**
 * VFeedItemTriggerHandler
 *
 * @author     Sahil
 * @date  2021-07-27
 * @decription  handler for VFeedItem trigger
 */
global class VFeedItemTriggerHandler {
    /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
    public static final String TEXTPOST = 'TextPost';
    public static final String CONTENTPOST = 'ContentPost';
    private static final Id supportRecordTypeId = 
            CDdSchemaUtils.getRecordTypeIdByDeveloperName(CDdSupportConstants.CASE_OBJECT_LABEL, 
                                                                        CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
    global static Boolean doNotUpdateCases = false;
    /*****************************************************************************************************************************
   *
   * Public Methods
   *
   *****************************************************************************************************************************/
     /**
     * @author     Sahil
     * @date  2021-07-27
     * @decription method executes before insert of feeditem records
     * @param   list of feed item records
     * @return  void
     */
    public void onBeforeInsert(List<FeedItem> newList) {
        if(!doNotUpdateCases) {
            try {
                updateParentCases(newList);
            } catch (Exception e) {
                //log exception as an apex log record
                CDdErrorUtilities.publishException( 'VFeedItemTriggerHandler', 'updateParentCases',e);
                throw new VFeedItemTriggerHandlerException(e.getMessage());
            }
        }
    }

    /**
     * @author     Sahil
     * @date  2021-07-27
     * @decription update parent cases of incoming feed item records from trigger
     * @param   list of feed item records
     * @return  void
     */
    public static void updateParentCases(List<FeedItem> feedItemList) {
        //get parent cases to update comment count
        Map<Id,FeedItem> parCaseIdToFiMapComCnt = getParentTextContentPostCases(feedItemList);
        //get cases to update internal comment
        Map<Id,FeedItem> parCaseIdToFiMapIntCom = getSupCasesWithTextPost(feedItemList);
        //create a consolidated set of case ids to query from database
        Set<Id> caseIdSetForQuery = new Set<Id>();
        //merge 2 sets into 1 for query
        caseIdSetForQuery.addAll(parCaseIdToFiMapComCnt.keyset());
        caseIdSetForQuery.addAll(parCaseIdToFiMapIntCom.keyset());
        if (!caseIdSetForQuery.isEmpty()) {
            //query from Database
            List<Case> finalCasesToUpdate = [SELECT TotalCommentCount__c, RecordTypeId, Last_Internal_Comment__c
                                                FROM Case
                                                WHERE Id =:caseIdSetForQuery];
            if (!finalCasesToUpdate.isEmpty()) {
                //loop through cases and update them
                for (Case caseVar : finalCasesToUpdate) {
                    //increment total count
                    Integer totalCount = 0;
                    if (parCaseIdToFiMapComCnt.containsKey(caseVar.Id) && caseVar.RecordTypeId == supportRecordTypeId &&
                    caseVar.Id == parCaseIdToFiMapComCnt.get(caseVar.Id).ParentId) {
                        totalCount++;
                        if (caseVar.TotalCommentCount__c == null) {
                            caseVar.TotalCommentCount__c = totalCount;
                        } else {
                            caseVar.TotalCommentCount__c += totalCount;
                        }
                    }
                    //update last comment date for cases that are a part of the parCaseIdToFiMapIntCom map
                    if(parCaseIdToFiMapIntCom.containsKey(caseVar.id)){
                        caseVar.Last_Internal_Comment__c = Datetime.now();
                    }
                }
                List<Database.SaveResult> results = Database.update(finalCasesToUpdate,false);
                CDdErrorUtilities.publishException('VFeedItemTriggerHandler','updateParentCases',results);
            }
        }
    }

     /**
     * @author     Sahil
     * @date  2021-07-27
     * @decription return a map of parent case ids and feeditem records which are text or content post
     * @param   list of feed item records
     * @return  Map<Id,FeedItem>
     */
    public static Map<Id,FeedItem> getParentTextContentPostCases(List<FeedItem> feedItemList) {
        Map<Id,FeedItem> caseIdToFeedItemMap = new Map<Id,FeedItem>();
        //return map of parent case id to the feed item record
        for (FeedItem fiRec : feedItemList) {
            if ((fiRec.Type == TEXTPOST || fiRec.Type == CONTENTPOST) && fiRec.ParentId != null) {
                caseIdToFeedItemMap.put(fiRec.ParentId,fiRec);
            }
        }
        return caseIdToFeedItemMap;
    }

     /**
     * @author     Sahil
     * @date  2021-07-27
     * @decription returns a set of parent case ids to update last comment date
     * @param   list of feed item records
     * @return  set of case record ids
     */
    public static Map<Id,FeedItem> getSupCasesWithTextPost(List<FeedItem> feedItemList) {
        DateTime postDate = DateTime.newInstance(2017,4,13);
        Map<Id,FeedItem> caseIdToFeedItemMap = new Map<Id,FeedItem>();
        //return parent case ids to update
        for (FeedItem fiRec : feedItemList) {
            if (fiRec.Type == TEXTPOST && DateTime.now() > postDate && fiRec.ParentId != null
                && fiRec.ParentId.getSObjectType() == Case.SobjectType) {
                    caseIdToFeedItemMap.put(fiRec.ParentId,fiRec);
            }
        }
        return caseIdToFeedItemMap;
    }

    public class VFeedItemTriggerHandlerException extends Exception {}
}