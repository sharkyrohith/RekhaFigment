/**@author | Kody Hungenberg
 * @date   | 2021-4-15
 * @ticket | BZAPSUP-1744
 * @description Handles Case_Reopen_Event__e plaform events
 * for Cases to be reopened */
public class CDdCaseReopenHandler {
  /*** constants ***/
  static final String CLASS_INFO = 'Class Name: CDdCaseReopenHandler';

  /**@author     | Kody Hungenberg
   * @date       | 2021-4-15
   * @ticket     | BZAPSUP-1744
   * @param List<Case_Reopen_Event__e> reopenEvents
   * @return void **/

  public static void handleCaseReopens(List<Case_Reopen_Event__e> reopenEvents) {
    //instaniate lists/classes
    List<Case> casesToUpdate = new List<Case>();
    CDdCaseReopenHandler caseReopenHandler = new CDdCaseReopenHandler();
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    //support feature flag - EnableReopen default == false
    Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();
    Boolean isNewCase = false;
    Boolean isReopenEnabled = featureFlag.EnableReopen__c;
    Boolean reopenNotEnabled = false;


    if (!reopenEvents.isEmpty()){
      isNewCase = caseReopenHandler.checkForNewCases(reopenEvents);
      Set<Id> caseIds = caseReopenHandler.addCaseIdsToSet(reopenEvents);

      //query cases based on Id from platform event
      List<Case> caseList = caseReopenHandler.caseQuery(caseIds);

        //if feature flag is false set case to reopened - same function as pb we are replacing
        if (isReopenEnabled == reopenNotEnabled && isNewCase == false){
            List<Case> reopenCases = caseReopenHandler.updateStatus(CDdSupportConstants.REOPEN_STATUS, caseList);
            caseReopenHandler.updateCases(reopenCases);
        } else {
            //Build list of cases where Routing Override is set
            List<Case> routingOverrideCases = atmUtil.getOverrideCases(caseList);
            //build list of cases where Routing Override is not set
            List<Case> routingOverrideNullCases = atmUtil.getNonOverrideCases(caseList);
            //update all cases where routing is not set to reopened
            if (!routingOverrideNullCases.isEmpty() && !isNewCase){
                casesToUpdate.addAll((caseReopenHandler.updateCaseOwner(routingOverrideNullCases)));
            }
            //pass routing override cases to handler if not empty
            if (!routingOverrideCases.isEmpty()){
                CDdAcctTeamMemberReopenHandler atmHandler = new CDdAcctTeamMemberReopenHandler();
                casesToUpdate.addAll(atmHandler.reopenHandler(routingOverrideCases));
            }
            if (!isNewCase){
              casesToUpdate = caseReopenHandler.updateStatus(CDdSupportConstants.REOPEN_STATUS, casesToUpdate);
            }
            caseReopenHandler.updateCases(casesToUpdate);
        }
    } 
  }
    /**
   * @author     | Raj Chilukuri
   * @date       |
   * @ticket     | BZAPSUP-1744
   * @description|
   * @param
   * @return
   **/
  // this is to be set from test class
  @testVisible
  public static Map<String, Case_Reopen_Queues__mdt> caseReopenQueueMap {
    get {
      if (caseReopenQueueMap == null) {
        caseReopenQueueMap = Case_Reopen_Queues__mdt.getAll();
      }
      return caseReopenQueueMap;
    }
    set;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-18
   * @ticket     | BZAPSUP-1744
   * @description| returns the Case Id from the platform event record
   * @param List<Case_Reopen_Event__e> reopenEvents
   * @return Set<Id>
   **/
  public Set<Id> addCaseIdsToSet(List<Case_Reopen_Event__e> reopenEvents) {
    Set<Id> caseIds = new Set<Id>();
    for (Case_Reopen_Event__e event : reopenEvents) {
      caseIds.add(event.CaseId__c);
    }
    return caseIds;
  }
  /**@author     | Kody Hungenberg
   * @date       | 2021-4-15
   * @ticket     | BZAPSUP-1744
   * @description| queries Case based on Ids passed in Set<Id> caseIds
   * @param caseIds
   * @return List<Case> */
  public List<Case> caseQuery(Set<Id> caseIds) {
    List<Case> caseList = new List<Case>();
    if (!caseIds.isEmpty() && caseIds != null){
      caseList = [
        SELECT Id, OwnerId, Previous_Queue_ID__c, Previous_Queue__c, AccountId, Status, Account.Case_Routing_Override__c, RecordTypeId
        FROM Case
        WHERE Id IN :caseIds
      ];
    }
    return caseList;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-4-15
   * @ticket     | BZAPSUP-1744
   * @description| Updates case owner to previous queue if routing override is null &
   * previous queue is set to reopen to queue in Case_Reopen_Queues__mdt
   * @param
   * @return List<Case>
   **/
  public List<Case> updateCaseOwner(List<Case> caseList) {
    //System.debug('<><><>updateCaseOwner<><><');
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();

    for (Case c : caseList) {
      if (String.isNotBlank(c.Previous_Queue__c)){
        Id reopenQueueId = atmUtil.reopenQueueIdSelector(c.Previous_Queue__c);
        if (
          String.isNotBlank(c.Previous_Queue_ID__c) &&
          reopenQueueId == c.Previous_Queue_ID__c) {
          c.OwnerId = c.Previous_Queue_ID__c;
        } 
      }
    }
    return caseList;
  }
    /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-18
   * @ticket     | BZAPSUP-1744
   * @description| Updates case status 
   * @param String status, List<Case> caseList
   * @return List<Case>
   **/
  private List<Case> updateStatus(String status, List<Case> caseList) {
    List<Case> casesToReturn = new List<Case>();
    if (String.isNotBlank(status) && !caseList.isEmpty()){
      for (Case c : caseList) {
        if (c.Status != 'Closed' || (c.Status == 'Closed' && c.RecordTypeId == '0121a0000006RKKAA2')) {
          c.Status = status;
        }
      }
    }
    return caseList;
  }
//checks boolean on platform event. Only == true for new cases
  private boolean checkForNewCases(List<Case_Reopen_Event__e> reopenEvents){
    Boolean isNewCase = false;
    for (Case_Reopen_Event__e cre : reopenEvents){
      if (cre.newCase__c == true){
        isNewCase = true;
        break;
      }
    }
    return isNewCase;
  }

  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-10
   * @ticket     | BZAPSUP-1744
   * @description| Updates cases
   * @param List<Case>
   * @return void
   **/
  //Handles case DML
  public void updateCases(List<Case> casesToUpdate) {
      if (!casesToUpdate.isEmpty()) {
        List<Database.SaveResult> sResults = Database.update(casesToUpdate,false);
        CDdErrorUtilities.publishException('Case', CLASS_INFO+'.updateCases', sResults);
      }
  }
}