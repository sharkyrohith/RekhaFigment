public class CDdAccountTeamMemberUtilities {
  /**
   * constants
   **/
  static final String CLASS_INFO = 'Class Name: CDdAccountTeamMemberUtilities';
  static final String MXPESCALATIONQUEUE_CATEGORY = 'MxPEscalationQueue';

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
   * @date       | 2021-5-6
   * @ticket     | BZAPSUP-1744
   * @description| Returns set of account Ids from a list of cases
   * @param List<Case>
   * @return Set<Id>
   **/
  //builds a set of accountIds from cases
  public Set<Id> getAcctIdsFromCase(List<Case> caseList) {
    Set<Id> accountIdsFromCase = new Set<Id>();
    for (Case c : caseList) {
      accountIdsFromCase.add(c.AccountId);
    }
    return accountIdsFromCase;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-04
   * @ticket     | BZAPSUP-1744
   * @description| Finds account team members by accountId
   * returns list of accounts with ATMs
   * @param Set<Id>
   * @return List<Account>
   **/
  public List<Account> getATMByMXPRole(Set<Id> accountIds) {
    List<Account> returnAccts = new List<Account>();
    String roleName = CDdSupportConstants.MXP_ROLE_NAME;

    List<Account> acctQuery = [
      SELECT
        Id,
        Case_Routing_Override__c,
        (
          SELECT Id, UserId, AccountId, Is_Active__c, Is_Out_Of_Office__c
          FROM AccountTeamMembers
          WHERE
            TeamMemberRole =: roleName
            AND Is_Active__c =: true
            AND Is_Out_Of_Office__c =: false
        )
      FROM Account
      WHERE Id IN :accountIds
    ];
    for (Account a : acctQuery){
      if(!a.AccountTeamMembers.isEmpty()){
        returnAccts.add(a);
      }
    }
    return returnAccts;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-10
   * @ticket     | BZAPSUP-1744
   * @description| Returns a map of Account Team Member user Ids to a set of Account Ids
   * @param List<Account>
   * @return Map<Id, Set<Id>>
   **/
  //Maps accounts to account team member user ids
  public Map<Id, Set<Id>> mapUserIdsToAcctIds(List<Account> acctsWithATM) {
    Map<Id, Set<Id>> acctIdToATMIds = new Map<Id, Set<Id>>();

    if (!acctsWithATM.isEmpty()) {
      for (Account acct : acctsWithATM) {
        Set<Id> acctTeamMembersIds = new Set<Id>();
        for (AccountTeamMember acctTeamMembers : acct.AccountTeamMembers) {
          acctTeamMembersIds.add(acctTeamMembers.UserId);
        }
        acctIdToATMIds.put(acct.Id, acctTeamMembersIds);
      }
    }
    return acctIdToATMIds;
  }

  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-6
   * @ticket     | BZAPSUP-1744
   * @description| finds/returns cases where account.case_routing_override__c ==Mx Success Associate Queue
   * @param List<Case>
   * @return List<Case>
   **/
  public List<Case> getOverrideCases(List<Case> caseList) {
    List<Case> routingOverrideCases = new List<Case>();
    for (Case c : caseList) {
      if (String.isNotBlank(c.AccountId) &&
          String.isNotBlank(c.Account.Case_Routing_Override__c)) {

          routingOverrideCases.add(c);
      }
    }
    return routingOverrideCases;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-4-26
   * @ticket     | BZAPSUP-1744
   * @description| finds/returns cases where account.case_routing_override__c != Mx Success Associate Queue
   * @param List<Case>
   * @return List<Case>
   **/
  public List<Case> getNonOverrideCases(List<Case> caseList) {
    List<Case> routingOverrideNullCases = new List<Case>();

    for (Case c : caseList) {
      if (String.isNotBlank(c.AccountId) &&
        String.isBlank(c.Account.Case_Routing_Override__c)) {
        routingOverrideNullCases.add(c);
      }
    }
    return routingOverrideNullCases;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-4-26
   * @ticket     | BZAPSUP-1744
   * @description| Returns a list of cases without account team members
   * @param List<Case>, List<Account>
   * @return List<Case>
   **/
  public List<Case> getCasesWithoutATM(List<Case> caseList,List<Account> acctList) {
    List<Case> casesWithoutATM = new List<Case>();
    Set<Id> accountIds = new Set<Id>();
    if (acctList.isEmpty()){
      return caseList;
    } else {
      for (Account acc : acctList) {
        accountIds.add(acc.Id);
      }
      for (Case c : caseList) {
        if (!accountIds.contains(c.AccountId)) {
          casesWithoutATM.add(c);
        }
      }
    }
    return casesWithoutATM;
  }

  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-4-26
   * @ticket     | BZAPSUP-1744
   * @description| maps user to the cases that are under the account the user is a team member for
   * @param List<Case>, Map<Id, Set<Id>>
   * @return Map<Id, List<Case>>
   **/
  public Map<Id, List<Case>> mapUserToCases(List<Case> caseList,Map<Id, Set<Id>> accountIdToUserIdMap) {
    Map<Id, List<Case>> userIdCasesMap = new Map<Id, List<Case>>();

    for (Case c : caseList) {
      Set<Id> userIdSet = accountIdToUserIdMap.get(c.accountId);
      if (!userIdSet.isEmpty()) {
        Id userId = (new List<Id>(userIdSet))[0]; //may need to refactor to assign to specific user, currently not required
        if (!userIdCasesMap.containsKey(userId)) {
          userIdCasesMap.put(userId, new List<Case>());
          userIdCasesMap.get(userId).add(c);
        } else {
          userIdCasesMap.get(userId).add(c);
        }//else {} todo else statement with 'userIdCasesMap.get(userId).add(c);'
      }
    }
    return userIdCasesMap;
  }

  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-6
   * @ticket     | BZAPSUP-1744
   * @description| Method to find fallback queue in custom metadata by name
   * @param String queueName
   * @return Id
   **/
  public static Id fallbackQueueIdSelector(String queueName) {
    Id fallBackQueueId;
    Boolean isFallBackTrue = true;

    for (Case_Reopen_Queues__mdt crq : caseReopenQueueMap.values()){
      if (String.isNotBlank(queueName) && queueName.equalsIgnoreCase(crq.MasterLabel)){
        if (crq.isFallback__c == isFallBackTrue
        && String.isNotBlank(crq.Queue_Id__c)){
          fallBackQueueId = crq.Queue_Id__c;
        }
      }
    }

    return fallBackQueueId;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-6
   * @ticket     | BZAPSUP-1744
   * @description| Method to find reopen queues in custom metadata by name
   * @param String queueName
   * @return Id
   **/
  public Id reopenQueueIdSelector(String queueName) {
    Id reopenQueueId;
    Boolean isReopenTrue = true;

    for (Case_Reopen_Queues__mdt crq : caseReopenQueueMap.values()){
      if (String.isNotBlank(queueName) && queueName.equalsIgnoreCase(crq.MasterLabel)){
        if (crq.Queue_Reopen__c == isReopenTrue
        && String.isNotBlank(crq.Queue_Id__c)){
          reopenQueueId = crq.Queue_Id__c;
        }
      }
    }
    return reopenQueueId;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-6
   * @ticket     | BZAPSUP-1744
   * @description| handles reopening cases to the account team members
   * @param Map<Id, List<Case>> userIdCasesMap, Map<Id, Set<Id>> acctIdToATMIds
   * @return List<Case>
   **/
  public List<Case> setOwnerToAccountTeamMember(Map<Id, List<Case>> userIdCasesMap,Map<Id, Set<Id>> acctIdToATMIds) {
    List<Case> casesToReopen = new List<Case>();

    for (Id userId : userIdCasesMap.keySet()) {
      List<Case> cases = userIdCasesMap.get(userId);
      for (Case c : cases) {
        Id accountId = c.AccountId;
        Set<Id> userIds = acctIdToATMIds.get(accountId);
        if (userIds?.size() > 0 && !userIds.contains(c.OwnerId)) {
          c.OwnerId = (new List<Id>(userIds))[0];
          casesToReopen.add(c);
        }
      }
    }
    return casesToReopen;
  }
  /**
   * @author     | Kody Hungenberg
   * @date       | 2021-5-6
   * @ticket     | BZAPSUP-1744
   * @description| updates cases without account team members to the fallback queue
   * @param List<Case> caseList, String queueName
   * @return List<Case>
   **/
  //updates cases without account team members to the fallback queue
  public List<Case> updateCasesToFallBackQueue(List<Case> caseList,String queueName) {
    Id fallBackQueue = fallbackQueueIdSelector(queueName); //queries cmdt for the fall back queue
    List<Case> casesToReopen = new List<Case>();

    for (Case c : caseList) {
      if (fallBackQueue != null && c.OwnerId != fallBackQueue) {
        //set the owner to the fallback queue if present
        c.OwnerId = fallBackQueue;
      }
      casesToReopen.add(c);
    }
    return casesToReopen;
  }

   /**
     * @author      Nayana
     * @date        August 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-348
     * @description Check if the given case is eligible for MXP Routing override or not
     */

    public Boolean isMxPRoutingOverridenCase(Case c){
      Boolean isMxPCase = false;
      if(string.isNotBlank(c.Case_Routing_Override__c) && c.Case_Routing_Override__c == CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE){
          isMxPCase = true;
      }
      return isMxPCase;
  }

    /**
   * @author      Nayana
   * @date        August 2021
   * @jira        https://doordash.atlassian.net/browse/BIZS-348
   * @description ier 3 queue Ids to which MxP case can't be escalated
   */
  public static Set<Id> getMxPEscalationQueue() {
    Set<Id> setTier3QueueIds = new Set<Id>();
    //Get the tier 3 queue Ids to which MxP case can't be escalated
    for(Id_Metadata__mdt idMdt : CDdCustomMetadata.idMetadataByCategory(MXPESCALATIONQUEUE_CATEGORY).values()){
        if(String.isNotBlank(idMdt.Id__c)){
          setTier3QueueIds.add(idMdt.Id__c);
        }
    }
    return setTier3QueueIds;
  }

  /**
   * @author      Raju Lakshman
   * @date        October 2021
   * @jira        https://doordash.atlassian.net/browse/BIZS-632
   * @description Get MXP Queue Id
   */
  private static Id mxpQueueId = null;
  public static Id getMxpQueueId() {
    if (mxpQueueId == null) {
      List<Group> mxpQueue =
         [SELECT ID
            FROM Group
           WHERE DeveloperName = :CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK];
      if (!mxpQueue.isEmpty()) {
          mxpQueueId = mxpQueue[0].Id;
      }
    }
    return mxpQueueId;
  }
}