/********************************************************************************************************************
* @author Sriram
* @date 11/01/2021
*
* @group Merchant Services
*
* @description Helper class for Parent Account
* 
**************************************************************************************************************************************/
public class CDdMxSxParentAccountHelper {
    public static final String CLASS_NAME = 'CDdMxSxParentAccountHelper';
    /**
     * Define class variables here
     */   
    private Set<Id> parentAccountIds;
    private Map<Id, Case> parentAccountWithMostRecentStorefrontOnboardingCase {
        get {
            if (this.parentAccountWithMostRecentStorefrontOnboardingCase == null){
                this.setParentAccountWithMostRecentStorefrontOnboardingCase();
            }
            return this.parentAccountWithMostRecentStorefrontOnboardingCase;
        }
        set;
    }
    private Map<Id, Integer> inactiveStoreAccountCountForParentAccount {
        get {
            if (this.inactiveStoreAccountCountForParentAccount == null){
                this.setInactiveStoreAccountCountForParentAccount();
            }
            return this.inactiveStoreAccountCountForParentAccount;
        }
        set;
    }
    private Map<Id, Integer> storeAccountCountForParentAccount {
        get {
            if (this.storeAccountCountForParentAccount == null){
                this.setStoreAccountCountForParentAccount();
            }
            return this.storeAccountCountForParentAccount;
        }
        set;
    }
    /** 
     * @description Single argument constructor
     * @param Set<Id> parentAccountIds - Collection of Parent Account Ids
     */    
    public CDdMxSxParentAccountHelper(Set<Id> parentAccountIds) {
        this.parentAccountIds = parentAccountIds;
    }
    /**
     * @description Set the Parent Account with most recent Storefront Onboarding Case
     * @param 
     * @return void 
     */
    private void setParentAccountWithMostRecentStorefrontOnboardingCase() {
        this.parentAccountWithMostRecentStorefrontOnboardingCase = new Map<Id, Case>();
        for (Case c :   [   SELECT Id, RecordTypeId, AccountId, OwnerId, Status, IsClosed, ClosedDate 
                            FROM Case
                            WHERE RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING
                            AND AccountId IN :this.parentAccountIds
                            AND Account.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT
                            ORDER BY CreatedDate DESC, ClosedDate DESC NULLS FIRST
                        ]){
            if (!this.parentAccountWithMostRecentStorefrontOnboardingCase.containsKey(c.AccountId)){
                this.parentAccountWithMostRecentStorefrontOnboardingCase.put(c.AccountId, c);
            }
        }
    }
    /**
     * @description Set the count of inactive store accounts for each Parent Account
     * @param 
     * @return void 
     */
    private void setInactiveStoreAccountCountForParentAccount() {
        this.inactiveStoreAccountCountForParentAccount = new Map<Id, Integer>();
        for (AggregateResult ar : [ SELECT COUNT(Id), ParentId
                                    FROM Account
                                    WHERE RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS
                                    AND ParentId IN :this.parentAccountIds
                                    AND (Currently_Active__c != 'Yes' OR Is_Partner__c != 'Yes')
                                    GROUP BY ParentId
                        ]){
            Id parentAccountId = (Id)ar.get('ParentId');
            Integer inactiveStoreCount = (Integer)ar.get('expr0');
            this.inactiveStoreAccountCountForParentAccount.put(parentAccountId, inactiveStoreCount);
        }
    }    
    /** 
     * @description Set the count of store accounts for each Parent Account
     * @param
     * @return void
     */
    private void setStoreAccountCountForParentAccount() {
        this.storeAccountCountForParentAccount = new Map<Id, Integer>();
        for (AggregateResult ar : [ SELECT COUNT(Id), ParentId
                                    FROM Account
                                    WHERE RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS
                                    AND ParentId IN :this.parentAccountIds
                                    GROUP BY ParentId
                        ]){
            Id parentAccountId = (Id)ar.get('ParentId');
            Integer storeCount = (Integer)ar.get('expr0');
            this.storeAccountCountForParentAccount.put(parentAccountId, storeCount);
        }
    }    
    /** 
     * @description Get the Active Storefront Onboarding Case as of the input date time
     * Return the Case, 
     *      - If the Case is currently not closed
     *      - OR If the Case is closed not earlier than the input date time
     * Note: Returns NULL if the above explained criteria is not met i.e if no active case is found
     * @param Id parentAccountId
     * @param DateTime dt - as of input date time 
     * @return Case
     */       
    public Case getActiveStorefrontOnboardingCase(Id parentAccountId, DateTime dt){
        if (!this.parentAccountWithMostRecentStorefrontOnboardingCase.containsKey(parentAccountId)){ return null; }
        Case c = this.parentAccountWithMostRecentStorefrontOnboardingCase.get(parentAccountId);
        return (!c.IsClosed || (c.IsClosed && dt!=null && c.ClosedDate >= dt)) ? c : null;
    }
    /** 
     * @description Does the Parent Account have an active storefront onboarding case as of the input date time
     * @param Id parentAccountId
     * @param DateTime dt - as of input date time 
     * @return Boolean
     */      
    public Boolean hasActiveStorefrontOnboardingCase(Id parentAccountId, DateTime dt){
        return getActiveStorefrontOnboardingCase(parentAccountId, dt) != null;
    }
    /** 
     * @description Is the Active Storefront Onboarding Case record in holding queue?
     * NOTE: Returns false, if no active storefront onboarding case is found
     * @param Id parentAccountId
     * @param DateTime dt - as of input date time 
     * @return Boolean
     */       
    public Boolean hasActiveStorefrontOnboardingCaseInHoldingQueue(Id parentAccountId, DateTime dt){
        return this.hasActiveStorefrontOnboardingCase(parentAccountId, dt) 
                &&
                this.getActiveStorefrontOnboardingCase(parentAccountId, dt).OwnerId.equals(CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE); 
    }
    /** 
     * @description Does the parent account have one or more inactive stores? (i.e stores not activated yet in Nimda)
     * @param Id parentAccountId
     * @return Boolean
     */     
    public Boolean hasInactiveStores(Id parentAccountId){
        return this.inactiveStoreAccountCountForParentAccount.containsKey(parentAccountId)
                &&
                this.inactiveStoreAccountCountForParentAccount.get(parentAccountId) > 0;
    } 
      /** 
     * @description Does the parent account have one or more stores?
     * @param Id parentAccountId
     * @return Boolean
     */    
    public Boolean hasStores(Id parentAccountId){
        return this.storeAccountCountForParentAccount.containsKey(parentAccountId)
                &&
                this.storeAccountCountForParentAccount.get(parentAccountId) > 0;
    }
    
    /**
        @author: Dan Thoreson
        @date: 03-Aug-2022
        @description: Indicates if Parent Account, from its inputted ID, has ANY Stores that 
                        are active (i.e., whose total store count is greater than inactive store count)
    **/
    public Boolean hasAnyActiveStores(Id parentAccountId) {
        return this.hasStores(parentAccountId) && (!this.hasInactiveStores(parentAccountId) || this.storeAccountCountForParentAccount?.get(parentAccountId) > this.inactiveStoreAccountCountForParentAccount?.get(parentAccountId));
    }

    /** 
     * ************************************************************
     * ************  STATIC METHODS GO HERE ***********************
     * ************************************************************
     */
    /** 
     * @description Create Parent Account for Store Accounts (associated with Opportunity Records), that do not have an associated Parent Account
     * Fix for BZAP-13225 - Create missing parent accounts only for Opportunities that have Storefront pricing
     * @param Set<Id> opportunityIds - Collection of Opportunity Record Identifiers
     * @return void
     */ 
    public static void createParentAccountsForOpportunityIds(Set<Id> opportunityIds){
        Set<Id> opportunityIdsToProcess = new Set<Id>();
        CDdMxSxOpportunityHelper opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
        for (Id opportunityId : opportunityIds){
            if (opportunityHelper.hasStorefrontPricing(opportunityId)){
                opportunityIdsToProcess.add(opportunityId);
            }
        }
        if (!opportunityIdsToProcess.isEmpty()){
            Set<Id> accountIds = new Set<Id>();
            for (Opportunity o : [  SELECT Id, AccountId, Account.RecordTypeId, Account.ParentId 
                                    FROM Opportunity 
                                    WHERE Id IN :opportunityIdsToProcess
                                    AND Account.RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS
                                    AND Account.ParentId = NULL
                                ]){
                accountIds.add(o.accountId);
            }
            createParentAccounts(accountIds);
        } 
    }    
    /** 
     * @description Create Parent Accounts for child/store accounts (Record Type Marketplace or Enterprise Marketplace)
     * - Process store accounts (Marketplace, Enterprise Marketplace) that do not have parent account (ParentId == NULL)
     * - Exclude records with Business Id as found in the Collection BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS
     *   accounts with any of this business id (see variable BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS) are not supposed to have a parent account
     * - If a business id is found on the child account, 
     *      - the child account will be updated with the apppropriate ParentId based on a Business Id match with the corresponding Parent Account
     * @param Set<Id> childAccountIds - Collection of Child Account Record Identifiers
     * @return Collection of impacted Child/Store Accounts with updated Parent Id {"Id": <Child Account Id>, "ParentId": <Parent Account Id>}
     *         Operation will return NULL or EMPTY Collection, if no child accounts are impacted
     */     
    public static List<Account> createParentAccounts(Set<Id> childAccountIds){
        String METHOD_NAME = 'createParentAccounts';
        if (childAccountIds == null || childAccountIds.isEmpty()){ return null; }
        String errorMessage = null;
        List<Account> childAccountsToProcess = new List<Account>();
        Map<Decimal, Account> childAccountsByBusinessId = new Map<Decimal, Account>();
        Map<Id, Account> newParentAccountsByChildAccountId = new Map<Id, Account>();
        Id parentAccountRecordTypeId = CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT;
        for (Account a : [  SELECT Id, Account_Type__c, Business_ID__c, Deck_Rank__c, Name, OwnerId, RecordTypeId, ParentId
                            FROM Account 
                            WHERE Id IN :childAccountIds
                            AND RecordTypeId IN :CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS
                            AND ParentId = NULL]){
            // DO NOT process child accounts that inherit a Business Id belonging to CDdMxSxConstants.BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS
            if ((a.Business_ID__c == null) || ((a.Business_ID__c != null) && (!CDdMxSxConstants.BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS.contains(a.Business_ID__c.stripTrailingZeros())))){
                childAccountsToProcess.add(a);
                if (a.Business_ID__c != null){
                    childAccountsByBusinessId.put(a.Business_ID__c.stripTrailingZeros(), a);
                }
            }
        }
        // If nothing to process, return to the caller 
        if (childAccountsToProcess.isEmpty()){ return new List<Account>(); }
        // Retrieve Parent Accounts that have business Id as found on the child accounts
        if (!childAccountsByBusinessId.isEmpty()){
            for (Account a : [  SELECT Id, Account_Type__c, Business_ID__c, Deck_Rank__c, Name, OwnerId, RecordTypeId
                                FROM Account
                                WHERE RecordTypeId = :parentAccountRecordTypeId
                                AND Business_ID__c != null
                                AND Business_ID__c IN :childAccountsByBusinessId.keySet()]){
                if (childAccountsByBusinessId.containsKey(a.Business_ID__c.stripTrailingZeros())){
                    childAccountsByBusinessId.get(a.Business_ID__c.stripTrailingZeros()).ParentId = a.Id;                
                }
            }
        }
        // Prepare to create new parent accounts for child accounts where Parent Id could not be derived via Business Id match 
        for (Account childAccountToProcess : childAccountsToProcess){
            if (String.isBlank(childAccountToProcess.ParentId)) {
                newParentAccountsByChildAccountId.put(childAccountToProcess.Id, createParentAccount(childAccountToProcess));
            }
        }        
        try {
            // Create Parent Accounts, if Collection newParentAccountsByChildAccountId is not empty           
            if (!newParentAccountsByChildAccountId.isEmpty()){
                insert newParentAccountsByChildAccountId.values();
            }
            // Set the Parent Id on the remaining of the child accounts, if they are found to be blank
            for (Account childAccountToProcess : childAccountsToProcess){
                if (String.isBlank(childAccountToProcess.ParentId) && newParentAccountsByChildAccountId.containsKey(childAccountToProcess.Id)) {
                    childAccountToProcess.ParentId = newParentAccountsByChildAccountId.get(childAccountToProcess.Id).Id;
                }
            }
            // Update the child account with the set parent id
            if (!childAccountsToProcess.isEmpty()){
                update childAccountsToProcess;
            }
            return childAccountsToProcess;
        } catch(Exception ex) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ':' + METHOD_NAME + ':' + ex.getMessage());
            errorMessage = CDdErrorUtilities.getFormattedException(CLASS_NAME + ':' + METHOD_NAME, ex);
            throw new CDdMxSxException(ex);
        }  finally {
            if (String.isNotBlank(errorMessage)){ CDdErrorUtilities.publishException(CDdMxSxConstants.SOBJECT_TYPE_ACCOUNT, CLASS_NAME + ':' + METHOD_NAME, (new List<Id>(childAccountIds))[0], errorMessage); }
        }      
    }
    /**
     * @description Instantiate a new Parent Account using the values found on the Child Account
     */
    private static Account createParentAccount(Account childAccount){
        String childAccountName = childAccount.Name.substringBefore('(');
        String newParentAccountName = childAccountName
        +   (childAccountName.endsWith(' ') ? '' : ' ')
        +   '[Parent-' 
        +   (childAccount.Business_ID__c != null ? childAccount.Business_ID__c.stripTrailingZeros().toPlainString() : '')
        +   ']';
        return new Account(
                Name = newParentAccountName
                , Account_Type__c = childAccount.Account_Type__c 
                , Business_ID__c = childAccount.Business_ID__c
                , Deck_Rank__c = childAccount.Deck_Rank__c
                , OwnerId = childAccount.OwnerId
                , RecordTypeId = CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT                            
            );  
    }            
}