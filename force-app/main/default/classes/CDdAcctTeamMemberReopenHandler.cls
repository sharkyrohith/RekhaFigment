/**
 * @author | Kody Hungenberg
 * @date   | 2021-4-26
 * @ticket | BZAPSUP-1744
 *
 * @description Handles reopening cases to specific account team members
 *
 **/
public class CDdAcctTeamMemberReopenHandler {
  
  static final String CLASS_INFO = 'Class Name: CDdAcctTeamMemberReopenHandler';
  //Handles incoming cases for reopening to queue or account team members
  
  public List<Case> reopenHandler(List<Case> caseList) {
    Boolean reopenNotEnabled = false;
    List<Case> casesToUpdate = new List<Case>(); //cases will be added to this list for dml
    List<Case> casesWithoutATM = new List<Case>(); //cases that have no account team member
    Map<Id, Set<Id>> acctIdToATMIds = new Map<Id, Set<Id>>(); //map of accountIds to account team members
    Map<Id, List<Case>> atmUserToCases = new Map<Id, List<Case>>(); //map of user id to cases under that account
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();
    
    //bypass check - if enabled, reopens cases to queue
    Boolean isMxpReopenEnabled = featureFlag.EnableMXPAgentReopens__c;
    if (isMxpReopenEnabled == reopenNotEnabled) {
      casesToUpdate.addAll(atmUtil.updateCasesToFallBackQueue(caseList, CDdSupportConstants.MX_SUCCESS_ASSOCIATE));
      return casesToUpdate;
    } else {
      //returns set of account Ids from Cases
      Set<Id> accountIdsFromCase = atmUtil.getAcctIdsFromCase(caseList);
      //builds a list of accounts with active MXP ATMs
      List<Account> acctATMList = atmUtil.getATMByMXPRole(accountIdsFromCase);

      if (!acctATMList.isEmpty()) {
        //builds a map of accts with ATM users
        acctIdToATMIds = atmUtil.mapUserIdsToAcctIds(acctATMList);
        //Maps ATM user to list of cases
        atmUserToCases = atmUtil.mapUserToCases(caseList, acctIdToATMIds);

        casesToUpdate.addAll(atmUtil.setOwnerToAccountTeamMember(atmUserToCases, acctIdToATMIds));
      }
      //builds a list of cases that do not have have an ATM user
      casesWithoutATM = atmUtil.getCasesWithoutATM(caseList, acctATMList);
      //build list of cases to update
      casesToUpdate.addAll(atmUtil.updateCasesToFallBackQueue(casesWithoutATM, CDdSupportConstants.MX_SUCCESS_ASSOCIATE));
      return casesToUpdate;
    }
  }
}