/********************************************************************************************************************
* @author Sriram
* @date 04/05/2022
*
* @group Merchant Services
*
* @description Account Helper class for Mx Order
*
**************************************************************************************************************************************/
public class CDdMxOrderAccountHelper {
    /**
     * Define class variables here
     */
    private Map<Id, Account> accounts;
    private Map<Id, Map<Id, Milestone__c>> milestonesByAccountId;
    public Set<Id> caseIdSet;
    /**
     * Default Constructor
     * @param Set<Id> accountIds
     * @return
     */
    public CDdMxOrderAccountHelper(Map<Id, Mx_Order__c> mxOrders) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Id> opportunityIdForAccountId = new Map<Id, Id>();
        this.caseIdSet = new Set<Id>();
        for (Mx_Order__c mxOrder : mxOrders.values()){
            accountIds.add(mxOrder.Account__c);
            if (String.isNotBlank(mxOrder.Case__c) && String.isNotBlank(mxOrder.Case__r.Opportunity_Name__c)){
                opportunityIdForAccountId.put(mxOrder.Account__c, mxOrder.Case__r.Opportunity_Name__c);
                this.caseIdSet.add(mxOrder.Case__c);
            }
        }
        this.accounts = new Map<Id, Account>([  SELECT Id, Restaurant_ID__c, smartystreets__Billing_Return_Code__c,
                                                Starting_Point__c, In_Coverage__c, iPad_Username__c, iPad_Password__c,
                                                RealZip_Submarket_ID__c, Region_RealZips__c, Deck_Rank__c, Top_Mx__c
                                                FROM Account
                                                WHERE Id IN :accountIds
                                                AND RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS
                                            ]);
        this.milestonesByAccountId = new Map<Id, Map<Id, Milestone__c>>();
        for (Milestone__c m : [ SELECT Id, RecordTypeId, Case__r.AccountId, Status__c, Status_Reason__c, Case__r.Opportunity_Name__c
                                FROM Milestone__c
                                WHERE RecordTypeId IN :CDdMxSxConstants.MX_ORDER_APPLICABLE_MILESTONE_RECORD_TYPE_IDS
                                AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                AND Case__r.AccountId IN :this.accounts.keySet()
                                ORDER BY CreatedDate DESC]){
            if (opportunityIdForAccountId.containsKey(m?.Case__r?.AccountId) && opportunityIdForAccountId.get(m?.Case__r?.AccountId).equals(m?.Case__r?.Opportunity_Name__c)){
                if (this.milestonesByAccountId.containsKey(m.Case__r.AccountId)){
                    if (!milestonesByAccountId.get(m.Case__r.AccountId).containsKey(m.RecordTypeId)){
                        milestonesByAccountId.get(m.Case__r.AccountId).put(m.RecordTypeId, m);
                    }
                } else {
                    milestonesByAccountId.put(m.Case__r.AccountId, new Map<Id, Milestone__c>{ m.RecordTypeId => m });
                }
            }
        }
    }
    /**
     * @description Handle order updates from account which includes credentials..
     * @param
     * @return void
     */
    public static void handleOrderUpdatesFromAccount(set<Id> accountIds){
        set<string> mxOrderStatus = new set<string>{CDdMxSxConstants.MX_ORDER_STATUS_QUEUED, CDdMxSxConstants.MX_ORDER_STATUS_NEW, CDdMxSxConstants.MX_ORDER_STATUS_BLOCKED};
        List<mx_order__c> mxOrders = [select id,Order_Id__c,Order_Status__c,Order_Status_Last_Modified_Date__c from mx_order__c where Account__c IN:accountIds and Order_Status__c IN :mxOrderStatus];
        for(mx_order__c mxOrder: mxOrders){
            mxOrder.Order_Id__c  = '';
            mxOrder.Order_Status__c  = 'open';
            mxOrder.Order_Status_Last_Modified_Date__c = null;
        }
        update mxOrders;
    }
    /**
     * @description Does the Account Helper instance have accounts?
     * @param
     * @return Boolean
     */
    public Boolean hasAccounts(){
        return !this.accounts.isEmpty();
    }
    /**
     * @description Is an Account record present for the input Account Id
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasAccount(Id accountId){
        return hasAccounts() && this.accounts.containsKey(accountId);
    }
    /**
     * @description Return the Account record for the input Account Id
     * @param Id accountId
     * @return Account
     */
    public Account getAccount(Id accountId){
        return hasAccount(accountId) ? this.accounts.get(accountId) : null;
    }
    /**
     * @description Is a Store Id present on the Account record?
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasStore(Id accountId){
        return hasAccount(accountId) ? String.isNotBlank(getAccount(accountId).Restaurant_ID__c) : false;
    }
    /**
     * @description Is a Starting Point present on the Account record?
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasStartingPoint(Id accountId){
        return hasAccount(accountId) ? String.isNotBlank(getAccount(accountId).Starting_Point__c) : false;
    }
    /**
     * @description Is there coverage for the Billing Address found on the Account record?
     * @param Id accountId
     * @return Boolean
     */
    public Boolean isAddressInCoverage(Id accountId){
        return hasAccount(accountId)
                ? String.isNotBlank(getAccount(accountId).In_Coverage__c)
                    && getAccount(accountId).In_Coverage__c.toLowercase().contains('yes')
                : false;
    }
    /**
     * @description Is the Tablet Username present on the Account record?
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasTabletUsername(Id accountId){
        return hasAccount(accountId) ? String.isNotBlank(getAccount(accountId).iPad_Username__c) : false;
    }
    /**
     * @description Is the Tablet Password present on the Account record?
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasTabletPassword(Id accountId){
        return hasAccount(accountId) ? String.isNotBlank(getAccount(accountId).iPad_Password__c) : false;
    }
    /**
     * @description Is there a valid sub market present on the Account record?
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasSubmarket(Id accountId){
        return hasAccount(accountId) ? (getAccount(accountId).RealZip_Submarket_ID__c != null) : false;
    }
    /**
     * @description Is there a valid region present on the Account record?
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasRegion(Id accountId){
        return hasAccount(accountId) ? String.isNotBlank(getAccount(accountId).Region_RealZips__c) : false;
    }
    /**
     * @description Does the account record have open Marketplace Onboarding related milestones
     * Milestones are 'Review & Triage' and 'Setup Store'
     * @param Id accountId
     * @return Boolean
     */
    public Boolean hasMilestones(Id accountId){
        return this.milestonesByAccountId.containsKey(accountId) && !this.milestonesByAccountId.get(accountId).isEmpty();
    }
    /**
     * @description Is there a milestone available with regards to Marketplace Onboarding for the input Record Type
     * Record Types relevant here are 'Review & Triage' and 'Setup Store'
     * @param Id accountId
     * @param Id recordTypeId
     * @return Boolean
     */
    public Boolean hasMilestone(Id accountId, Id recordTypeId){
        return hasMilestones(accountId) && this.milestonesByAccountId.get(accountId).containsKey(recordTypeId);
    }
    /**
     * @description Is the milestone in 'Complete' status for the corresponding account?
     * Record Types relevant here are 'Review & Triage' and 'Setup Store'
     * @param Id accountId
     * @param Id recordTypeId
     * @return Boolean
     */
    public Boolean isMilestoneComplete(Id accountId, Id recordTypeId){
        return hasMilestone(accountId, recordTypeId) && CDdMxSxConstants.MILESTONE_STATUS_COMPLETE.equals(this.milestonesByAccountId.get(accountId).get(recordTypeId).Status__c);
    }
    /**
     * @description Is the milestone in 'Blocked' status for the corresponding account?
     * Record Types relevant here are 'Review & Triage' and 'Setup Store'
     * @param Id accountId
     * @param Id recordTypeId
     * @return Boolean
     */
    public Boolean isMilestoneBlocked(Id accountId, Id recordTypeId){
        return hasMilestone(accountId, recordTypeId) && CDdMxSxConstants.MILESTONE_STATUS_BLOCKED.equals(this.milestonesByAccountId.get(accountId).get(recordTypeId).Status__c);
    }
    /**
     * @description This method will check if the account is eligible for printer or not. This will be called from CDdMxOrderValidator.
     * @param Id accountId
     * @return Boolean
     */
    public Boolean isAccountEligibleForPrinter(Id accountId){
        return CDdMxSxCaseHelper.isTopMxAccountToSendPrinter(accounts.get(accountId));
    }
}