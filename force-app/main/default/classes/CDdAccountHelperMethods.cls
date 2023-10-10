/**
* @author: Ajinkya Amrute
* @date: 2018-02
* @description This Class contains Account specific helper methods
*/
public class CDdAccountHelperMethods {
    public static Boolean runOnce = CDdExperimentSvc.getFeatureFlag('Run_Once__c');
    public static boolean ranUpdateAcctsWithParentAcctInformation = false;
    public static boolean ranPopulatePreviousOwner = false;
    public static boolean ranUpdateDeckRankOnParentAccounts = false;
    public static boolean ranDxMarketingCase = false;
    public static boolean ranSetActivationDateOnOpps = false;
    public static boolean ranUpdateTaskCount = false;
    public static boolean ranCopyFieldsToContact = false;
    public static boolean ranDoAccountRollups = false;
    public static boolean ranCreateLeadOnLeadCreationApproval = false;
    public static boolean ranSetupCatalogMilestoneForBusinessVerticalRetail = false;
    public static boolean ranBusinessVerticalDetails = false;
    public static Boolean ranPostSaleAccountOwnerApprovalProcess = false;
    public static Boolean ranPostSaleAccountOwnershipRejected = false;

    public static boolean flag = true;
    public static boolean matchAccMissingParentAccountFlag = false;
    public static Boolean fieldCopyToContactFlag = false;
    public static Boolean fieldCopyToChildAccountFlag = false;
    public static Boolean fieldCopyToOpportunityFlag = false;
    public static Boolean leadMergePerformed = false;
    public static Boolean testingAccountFormStack = false;
    public static Boolean copyAccountOwnerToOpportunityFlag = false;
    public static Boolean copyAccountAmountToOpportunityFlag = false;
    public static Boolean ranUltimateParent = false;

    public static final vCS__c SETTINGS = vCS__c.getInstance();
    public static final Feature_Flags__c featureFlag = Feature_Flags__c.getInstance();
    public static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_INFO_BY_DEV_NAME
        = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    public static final String RECORD_TYPE_DEV_NAME_GRANDPARENT_ACCOUNT = 'Grandparent_Account';
    public static final String RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT = 'Parent_Account';
    public static final String RECORD_TYPE_DEV_NAME_MARKETPLACE = 'Prospect';
    public static final String RECORD_TYPE_DEV_NAME_ENTERPRISE_DRIVE = 'Enterprise_Drive';
    public static final String RECORD_TYPE_DEV_NAME_ENTERPRISE_MARKETPLACE = 'Enterprise_Marketplace';
    public static final Set<Decimal> BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS = new Set<Decimal>{45655, 70678};
        public static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    public static final String SOBJECT_TYPE_CONTACT = 'Contact';
    public static String hubspotIntegrationUserEmail = 'hubspot@doordash.com';
    public static final Map<Decimal, String> DECK_RANK_TO_STRING_MAP = new Map<Decimal, String>{
        1 => 'Ace of Spades',
            2 => 'King of Spades',
            3 => 'Ace',
            4 => 'King',
            5 => 'Queen',
            6 => 'Jack',
            7 => 'Joker'
            };
                public static Map<String, String> ZIP_CODE_TO_TERRITORY_ID_MAP;
    public static Map<Id, Id> ACCOUNT_OWNER_MANAGER_MAP;
    public static CDdSObjectFieldCopyObj accountFieldCopyToAccountObj;
    public static List<String> errorMessages = new List<String>();
    public static Boolean ENABLE_PLATFORM_EVENT_COPY_ACCT_TO_OPP = CDdExperimentSvc.getFeatureFlag('Enable_Platform_Event_Copy_Acct_To_Opp__c');
    public static Map<Id, Business_Vertical__c> BUSINESS_VERTICAL_MAP;
    public static final String MENU_UI_TYPE_RETAIL = 'Retail';
    public static Set<String> excludeCountryCodePhoneFormatting = new Set<String> {'CA', 'US', 'JP'};
    public static final Id SPM_HOLDING_USER = System.Label.Spm_Holding_User;
    public static final Id PM_HOLDING_USER = System.Label.Pm_Holding_User;
    public static final Id HOLDING_USER = System.Label.Holding_User;
    public static final Id PARTNER_MANAGER_ROLE = System.Label.Partner_Manager_Role;
    public static final Id SPM_ROLE = System.Label.Spm_Role;

    static {
        accountFieldCopyToAccountObj = new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT).getFieldCopyObj(SOBJECT_TYPE_ACCOUNT);
        ZIP_CODE_TO_TERRITORY_ID_MAP = new Map<String, String>();
        for(Territory__c tr: [SELECT id, Zip_Codes__c, name
                              FROM Territory__c
                              WHERE Zip_Codes__c != Null
                              AND Active__c != False]){

                                  for(String s : tr.Zip_Codes__c.split(',',0)){
                                      ZIP_CODE_TO_TERRITORY_ID_MAP.put(s.trim(), tr.id);
                                  }
                              }
        ACCOUNT_OWNER_MANAGER_MAP = new Map<Id, Id>();
        BUSINESS_VERTICAL_MAP = new Map<Id, Business_Vertical__c>([ SELECT Id, Name, Business_Vertical_Details__c, Business_Vertical_Id__c,
                                                                    BV_Search__c, Menu_UI_Type__c, Primary_Category__c
                                                                    FROM Business_Vertical__c
                                                                ]);
    }

    /**
    * @description When Copy_Account_Info__c is changed and set to true, copy the data in all the fields mentioned in Fieldset__c from Source_Account__c fields
    * at the time of Update operation), it populates the Territory based of Postal Code
    */
    public static void detectDuplicateFlagAndCopySensitiveInfo(List<Account> newAccts, Map<Id,Account> oldAccountsMap){

        List<sObject> accountLisToProcess = new List<sObject>();
        for(Account accountObj: newAccts) {
            if(accountObj.Copy_Account_Info__c != oldAccountsMap.get(accountObj.Id).Copy_Account_Info__c && accountObj.Copy_Account_Info__c) {
                accountLisToProcess.add(accountObj);
            }
        }

        //call Generic Copy method which will copy the data
        if(accountLisToProcess.size() > 0) {
            CDdCopyMerge.copySourceDataToSurvivor(accountLisToProcess, 'Copy_Account_Info__c', 'Field_Set__c', 'Source_Account__c');
        }
    }

    /**
    * @description For all the Accounts present in the account List(considered at the time of Insert operation) or in the account Map(considered
    * at the time of Update operation), it populates the Territory based of Postal Code
    */
    public static void populateTerritory(List<Account> newAccts, Map<Id,Account> oldAccountsMap, Boolean isInsert){
        for(Account a : newAccts){
            a.Territory__c = null;
            if((a.BillingPostalCode != null && a.BillingPostalCode !='' && a.BillingPostalCode.length() >= 5)
               &&
               (isInsert || (a.BillingPostalCode != oldAccountsMap.get(a.id).BillingPostalCode))){
                   String PostalCode = a.BillingPostalCode.subString(0,5);
                   if(ZIP_CODE_TO_TERRITORY_ID_MAP.get(PostalCode) != null){
                       a.Territory__c = ZIP_CODE_TO_TERRITORY_ID_MAP.get(PostalCode);
                   }
               }
        }
    }
    /**
    * @description BZAP-2578 and BZAP-3335 Update Child Account Information to match Parent Account Information if the Child Account qualifies
    * BZAP-4273 - Ability to turn off parent to child copy. Use copyFieldsFromParent__c to determine whether to trigger the copy to child records
    * BZAP-4559 - Improve Parent to Child Account flow - Use Platform Event 'Copy_Parent_Account_Event__e' to trigger the copy in a separate transaction
    */
    public static void updateChildAcctsInformation(Map<Id,Account> newAccountsMap, Map<Id,Account> oldAccountsMap){
        if (!SETTINGS.copyFieldsFromParent__c || fieldCopyToChildAccountFlag) return;

        List<Copy_Parent_Account_Event__e> copyParentAccountEvents = new List<Copy_Parent_Account_Event__e>();
        Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
        List<String> parentAccountCopyFields = accountFieldCopyToAccountObj.sourceFields;
        /* BASD-15227 added for Virtual Checkbox */
        Set<Id> AccRecTypeIds = new Set<Id>();
        AccRecTypeIds.add(parentAccountRecordTypeId);
        Id grandParentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Grandparent Account').getRecordTypeId();
        AccRecTypeIds.add(grandParentRecordTypeId);
        /***/

        for (Id acctId : newAccountsMap.keySet()) {
            Account newAcct = newAccountsMap.get(acctId);
            Account oldAcct = oldAccountsMap.get(acctId);
            Boolean hasChanged = false;

            //if (parentAccountRecordTypeId.equals(newAcct.RecordTypeId)) {
            /* BASD-15227 added for Virtual Checkbox */
            if (AccRecTypeIds.contains(newAcct.RecordTypeId)) {
                for (String copyField : parentAccountCopyFields){
                    if (newAcct.get(copyField) != oldAcct.get(copyField)){
                        hasChanged = true;
                    }
                }
            }
            /****/
            if (hasChanged){
                copyParentAccountEvents.add(new Copy_Parent_Account_Event__e(Parent_Account_Id__c = acctId));
            }
        }
        if (!copyParentAccountEvents.isEmpty()) {
            EventBus.publish(copyParentAccountEvents);
            fieldCopyToChildAccountFlag = true;
        }
    }
    /**
    * @description BZAP-2578 and BZAP-3335 Update Account Information when ParentAccount is changed if the Account qualifies
    */
    public static void updateAcctsWithParentAcctInformation(List<Account> newAccts, Map<Id,Account> oldAccountsMap, Boolean isInsert){
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        // if(runOnce && ranUpdateAcctsWithParentAcctInformation) {
        //     return;
        // }
        Set<Id> parentAcctIds = new Set<Id>();
        Set<Id> childAccRecTypeIds = new Set<Id>();
        List<Account> accountsToBeUpdated = new List<Account>();
        List<Account> accCatToBeUpdated = new List<Account>();
        Map<Id,Account> parentAcctMap = new Map<Id, Account>();
        Account oldAcct, currParentAcct;

        Id enterpriseDriveRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Enterprise Drive').getRecordTypeId();
        childAccRecTypeIds.add(enterpriseDriveRecordTypeId);
        Id enterpriseMarketplaceRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Enterprise Marketplace').getRecordTypeId();
        childAccRecTypeIds.add(enterpriseMarketplaceRecordTypeId);
        Id marketplaceRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
        childAccRecTypeIds.add(marketplaceRecordTypeId);
         /* For BASD-15227*/
         Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();

        for (Account newAcct : newAccts){
            if (isInsert && newAcct.ParentId != null && (childAccRecTypeIds.contains(newAcct.RecordTypeId) || parentAccountRecordTypeId.equals(newAcct.RecordTypeId))) {
                parentAcctIds.add(newAcct.ParentId);
                accountsToBeUpdated.add(newAcct);
                accCatToBeUpdated.add(newAcct);
            }
            else if (!isInsert){
                oldAcct = oldAccountsMap.get(newAcct.Id);
                if (newAcct.ParentId != null && newAcct.ParentId != oldAcct.ParentId && (childAccRecTypeIds.contains(newAcct.RecordTypeId) || parentAccountRecordTypeId.equals(newAcct.RecordTypeId))) {
                    parentAcctIds.add(newAcct.ParentId);
                    accountsToBeUpdated.add(newAcct);
                }

                if (newAcct.ParentId != null && (newAcct.ParentId != oldAcct.ParentId || (newAcct.Primary_Merchant_Category__c == null || newAcct.Merchant_Categories__c == null))){
					accCatToBeUpdated.add(newAcct);
                }
            }
        }

        if (parentAcctIds.isEmpty()) return;

        parentAcctMap = new Map<Id,Account>([SELECT Id, OwnerId, Business_ID__c, Deck_Rank__c, Account_Type__c, Amount__c,Virtual_Concept__c, Merchant_Categories__c, Primary_Merchant_Category__c
                                             FROM Account
                                             WHERE Id in :parentAcctIds]);

        for (Account currAcct : accountsToBeUpdated){
            currParentAcct = parentAcctMap.get(currAcct.ParentId);

            /* BASD-15227 : To Validate  Virtual_Concept__c checkbox */
            if (currAcct.Virtual_Concept__c != currParentAcct.Virtual_Concept__c && !(childAccRecTypeIds.contains(currAcct.RecordTypeId))){
                currAcct.Virtual_Concept__c = currParentAcct.Virtual_Concept__c;
            }

            /*BZAP-14973 : Added this condition to prevent Business Id and other fields below being copied from Grand Parent to Parent accounts*/
            if(childAccRecTypeIds.contains(currAcct.RecordTypeId)){

                if (currParentAcct.Business_ID__c != null && currParentAcct.Business_ID__c != currAcct.Business_ID__c){
                    currAcct.Business_ID__c = currParentAcct.Business_ID__c;
                }

                if (currParentAcct.OwnerId != null && currParentAcct.OwnerId != currAcct.OwnerId){
                    currAcct.OwnerId = currParentAcct.OwnerId;
                }

                //BZAP-6387 - Fix parent child deck rank logic, do not overwrite the deck rank on the child account in the event of a parent change
                /*if (currParentAcct.Deck_Rank__c != null && currParentAcct.Deck_Rank__c != currAcct.Deck_Rank__c){
                currAcct.Deck_Rank__c = currParentAcct.Deck_Rank__c;
                }*/

                if (currParentAcct.Account_Type__c != null && currParentAcct.Account_Type__c != currAcct.Account_Type__c){
                    currAcct.Account_Type__c = currParentAcct.Account_Type__c;
                }

                /***/
                //BZAP-4559 - Copy Parent Account nTam amount to Marketplace Account
                if (marketplaceRecordTypeId.equals(currAcct.RecordTypeId)){
                    if (currParentAcct.Amount__c != null && currAcct.Amount__c == null){
                        currAcct.Amount__c = currParentAcct.Amount__c;
                    }
                }
            }
            ranUpdateAcctsWithParentAcctInformation = true;
        }

        updateChildMerchantCategory(accCatToBeUpdated, parentAcctMap, oldAccountsMap, marketplaceRecordTypeId);
    }

    /* BASD-22872 - Request auto-filling merchant category and primary merchant category on child account based on the parent */
    // BASD-26359 - Added seperate loop to avoid overriding business ID, Owner ID fields
    public static void updateChildMerchantCategory(List<Account> accountsToBeUpdated,Map<Id,Account> parentAcctMap,Map<Id,Account> oldAccountsMap, Id marketplaceRecordTypeId){
		String currParentPrimaryCat, currParentMerchantCat, currAcctPrimartCat, currAcctMerchantCat;

        for (Account currAcct : accountsToBeUpdated) {
            currParentPrimaryCat = parentAcctMap?.get(currAcct.ParentId)?.Primary_Merchant_Category__c;
            currParentMerchantCat = parentAcctMap?.get(currAcct.ParentId)?.Merchant_Categories__c;
            currAcctPrimartCat = currAcct.Primary_Merchant_Category__c;
            currAcctMerchantCat = currAcct.Merchant_Categories__c;

            //Do not override Primary Merchant Category on child account from parent if user is entering a value in it
            if(oldAccountsMap != null && currAcctPrimartCat != oldAccountsMap.get(currAcct.Id).Primary_Merchant_Category__c && currAcctPrimartCat != null){
                continue;
            }
            //During insert populate Primary Merchant Category on child account from parent if it's blank
            else if(oldAccountsMap == null && currAcct.RecordTypeId == marketplaceRecordTypeId && currParentPrimaryCat != null && currParentPrimaryCat != currAcctPrimartCat && currAcctPrimartCat == null){
                currAcctPrimartCat = currParentPrimaryCat;
            }
            //During update populate Primary Merchant Category on child account from parent if it's blank or not matching to parent field
            else if(oldAccountsMap != null && currAcct.RecordTypeId == marketplaceRecordTypeId && currParentPrimaryCat != null && (currParentPrimaryCat != currAcctPrimartCat || currAcctPrimartCat == null)){
                currAcctPrimartCat = currParentPrimaryCat;
            }

            //Same logic written for 'Merchant Categories' field as above
            if(oldAccountsMap != null && currAcctMerchantCat != oldAccountsMap.get(currAcct.Id).Merchant_Categories__c && currAcctMerchantCat != null){
                continue;
            }
            else if(oldAccountsMap == null && currAcct.RecordTypeId == marketplaceRecordTypeId && currParentMerchantCat != null && currParentMerchantCat != currAcctMerchantCat && currAcctMerchantCat == null){
                currAcctMerchantCat = currParentMerchantCat;
            }
            else if(oldAccountsMap != null && currAcct.RecordTypeId == marketplaceRecordTypeId && currParentMerchantCat != null && (currParentMerchantCat != currAcctMerchantCat || currAcctMerchantCat == null)){
                currAcctMerchantCat = currParentMerchantCat;
            }
            /***/
            ranUpdateAcctsWithParentAcctInformation = true;
        }
    }

    /**
    * @description BZAPP-2576 PB NimdaCurrentlyActive_UpdateOp
    * For all the qualified Accounts present in the Account NewMap it sets
    * the Activation date on the respective qualified Opportunities to today's date
    */
    public static void setActivationDateOnOpps(Map<Id,Account> newAccountsMap, Map<Id,Account> oldAccountsMap){
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranSetActivationDateOnOpps) {
            return;
        }
        Set<Id> accountIdsSet = new Set<Id>();
        List<Opportunity> oppsToBeUpdatedWithActivationDate = new List<Opportunity>();

        for (Id acctId : newAccountsMap.keyset()) {
            if ((newAccountsMap.get(acctId).Currently_Active__c != oldAccountsMap.get(acctId).Currently_Active__c) &&
                (newAccountsMap.get(acctId).Currently_Active__c == 'Yes')) {
                    accountIdsSet.add(acctId);
                }
        }

        if (!accountIdsSet.isEmpty()){
            for(Opportunity opp : [SELECT Id, Activation_Date__c
                                   FROM Opportunity
                                   WHERE AccountId IN :accountIdsSet
                                   AND Activation_Date__c = null
                                   AND StageName = 'Closed Won'
                                   AND (
                                       RecordTypeId = :CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() or
                                       RecordTypeId = :CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId()
                                   )]) {
                                       opp.Activation_Date__c = System.today();
                                       oppsToBeUpdatedWithActivationDate.add(opp);
                                   }
            ranSetActivationDateOnOpps = true;
            try{
                update oppsToBeUpdatedWithActivationDate;
            }catch(Exception ex){
                CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity activation date exception: ' + ex.getMessage()}, 'CDdAccountHelperMethods',
                                                 'setActivationDateOnOpps', LoggingLevel.ERROR);
                throw ex;
            }
        }
    }

    /**
    * @description BZAP-3396 Prevent master account deletion
    * 'Send to Nimda' marks accounts as master when Nimda Stores have a salesforce Id
    */
    public static void preventMasterDeletion(Map<Id,Account> oldAccountsMap) {
        Account currAcc;
        for (Id key : oldAccountsMap.keySet()) {
            currAcc = oldAccountsMap.get(key);
            if (currAcc.isMaster__c) {
                currAcc.addError('Master Account can not be deleted. If merging, please mark Account w/ ID ' + currAcc.Id + ' as master.');
            }
        }
    }

    /**
    * @description BZAP-3547 Match Missing Parent Account
    *       BZAP-3755 - if there is no Parent Account for that Bus ID, create a Parent Account
    */
    public static void matchMissingParentAccount(List<Account> newAccounts) {
        if (!SETTINGS.parentAccMatchFlag__c || matchAccMissingParentAccountFlag) return;

        Map<Id, Account> newAccountsMap = new Map<Id, Account>();
        Map<Id, Account> newParentAccountsByChildAccountId = new Map<Id, Account>();
        Map<Decimal, Account> childAccountsByBusinessId = new Map<Decimal, Account>();
        Map<Decimal, Account> parentAccountsByBusinessId = new Map<Decimal, Account>();

        Set<Id> recordTypeIdFilterSet = new Set<Id>{
            RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_MARKETPLACE).getRecordTypeId()
                // , RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_ENTERPRISE_MARKETPLACE).getRecordTypeId()
                // commented out temporarily for Emma's Hierarchy updates
                };
                    Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();

        // Process accounts that
        // - belong to record type Marketplace or Enterprise Marketplace
        // - have a non-null Business Id
        // - exclude records with Business Id as found in the Collection BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS
        //      accounts with any of this business id (see variable BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS)
        //      are not supposed to have a parent account
        // - do not have a reference to a parent account
        for (Account a : newAccounts){
            if (recordTypeIdFilterSet.contains(a.RecordTypeId)
                && (a.Business_ID__c != null)
                && (!BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS.contains(a.Business_ID__c.stripTrailingZeros()))
                && (String.isBlank(a.ParentId))
               ){
                   newAccountsMap.put(a.Id, a);
                   childAccountsByBusinessId.put(a.Business_ID__c.stripTrailingZeros(), a);
               }
        }
        for (Account a : [  SELECT Id, Account_Type__c, Business_ID__c, Deck_Rank__c, Name, OwnerId, RecordTypeId
                          FROM Account
                          WHERE RecordTypeId = :parentAccountRecordTypeId
                          AND Business_ID__c != null
                          AND Business_ID__c IN :childAccountsByBusinessId.keySet()
                         ]){
                             parentAccountsByBusinessId.put(a.Business_ID__c.stripTrailingZeros(), a);
                         }
        // Walk through the child account Collection (a collection with Business Id as the key)
        // Determine if each child account has a corresponding parent account
        // - Perform this by using the Business Id key to retrieve a parent account from the Parent Account Collection
        // If a corresponding parent account is found,
        // - populate the Parent Id reference on the Child Account with the Parent Account Identifier
        // If a corresponding parent account is not found
        // - populate the newParentAccountsByChildAccountId with a new Parent Account and use the child Account Id as the key
        //   within the Collection
        for (Decimal businessId : childAccountsByBusinessId.keySet()){
            Account childAccount = childAccountsByBusinessId.get(businessId);
            if (parentAccountsByBusinessId.containsKey(businessId)){
                childAccount.ParentId = parentAccountsByBusinessId.get(businessId).Id;
            } else {
                String childAccountName = childAccount.Name.substringBefore('(');
                String newParentAccountName = childAccountName
                    +   (childAccountName.endsWith(' ') ? '' : ' ')
                    + '[Parent-' + childAccount.Business_ID__c.stripTrailingZeros().toPlainString() + ']';
                newParentAccountsByChildAccountId.put(childAccount.Id,
                                                      new Account(
                                                          Name = newParentAccountName
                                                          , Account_Type__c = childAccount.Account_Type__c
                                                          , Business_ID__c = childAccount.Business_ID__c
                                                          , Deck_Rank__c = childAccount.Deck_Rank__c
                                                          , OwnerId = childAccount.OwnerId
                                                          , RecordTypeId = parentAccountRecordTypeId
                                                      )
                                                     );
            }
        }
        // Create Parent Accounts, if Collection newParentAccountsByChildAccountId is not empty
        // Walk through newParentAccountsByChildAccountId Collection to put back the Parent Account Id reference
        //   on the Child Account
        // Note: Use the Child Account Id key to identify the corresponding Child Account
        //  in the newParentAccountsByChildAccountId Map Collection
        if (!newParentAccountsByChildAccountId.isEmpty()){
            try{
                insert newParentAccountsByChildAccountId.values();
            }catch(Exception ex){
                CDdErrorUtilities.createApexLogs(new List<String>{'Matching missing parent accounts exception: ' + ex.getMessage()}, 'CDdAccountHelperMethods',
                                                 'matchMissingParentAccount', LoggingLevel.ERROR);
                throw ex;
            }
            for (Id childAccountId : newParentAccountsByChildAccountId.keySet()){
                Account childAccount = newAccountsMap.get(childAccountId);
                childAccount.ParentId = newParentAccountsByChildAccountId.get(childAccountId).Id;
            }
        }
        // Once all of this is done, turn on the flag to prevent this operation from executing once again within the same transaction
        matchAccMissingParentAccountFlag = true;
    }

    /**
    * @author Tia Xuan
    * @date 2019-04
    *
    * @description Convert PB to Trigger (Populate Pre-sale Owner)
    */
    public static void PopulatePresaleOwner(List<Account> newAccountList){
        Id accRTId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Parent Account')
            .getRecordTypeId();

        for (Account acc : newAccountList){
            if (acc.RecordTypeId == accRTId){
                acc.ADR_Owner__c = acc.OwnerId;
                acc.PB_WF_Flow_Ran__c = 'Populate Pre-sale owner';
            }
        }
    }

    /**
    * @author Sriram
    * @date 05/23/2019
    *
    * @description Copy fields to Contact object
    * BZAP-3801 - update owner on Contact records if the owner has changed on the Account records
    */
    public static void copyFieldsToContact(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranCopyFieldsToContact) {
            return;
        }

        Set<Id> recordTypeIdFilterSet = new Set<Id>{
            RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId()
                , RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_MARKETPLACE).getRecordTypeId()
                , RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_ENTERPRISE_DRIVE).getRecordTypeId()
                , RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_ENTERPRISE_MARKETPLACE).getRecordTypeId()
                };
                    Set<Id> accountIdsToProcess = new Set<Id>();
        // Process accounts that
        // - belong to record type Parent Account, Marketplace, Enterprise Drive or Enterprise Marketplace
        // - Owner Id has changed between old and new account record
        for (Account newAcct : newMap.values()){
            Account oldAcct = oldMap.get(newAcct.Id);
            if (recordTypeIdFilterSet.contains(newAcct.RecordTypeId)
                && (
                    (!newAcct.OwnerId.equals(oldAcct.OwnerId))
                    ||
                    (   (String.isNotBlank(newAcct.ADR_Owner_Actual__c) && String.isBlank(oldAcct.ADR_Owner_Actual__c))
                     ||
                     (String.isBlank(newAcct.ADR_Owner_Actual__c) && String.isNotBlank(oldAcct.ADR_Owner_Actual__c))
                     ||
                     (String.isNotBlank(newAcct.ADR_Owner_Actual__c) && String.isNotBlank(oldAcct.ADR_Owner_Actual__c) && !newAcct.ADR_Owner_Actual__c.equals(oldAcct.ADR_Owner_Actual__c))
                    )
                )
               ){
                   accountIdsToProcess.add(newAcct.Id);
               }
        }
        if (!accountIdsToProcess.isEmpty()){
            // Retrieve corresponding Contact records that require an update to OwnerId
            List<Contact> contacts = (List<Contact>)new CDdSObjectFieldCopyProcessor(
                new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT)
                .getFieldCopyObj(SOBJECT_TYPE_CONTACT)
                , accountIdsToProcess)
                .targetRecords;
            // Update Contact records if the Collection is not empty
            if (!contacts.isEmpty()){
                ranCopyFieldsToContact = true;
                update contacts;
            }
        }
    }

    /**
    * @author Sriram
    * @date 06/12/2019
    *
    * @description BZAP-4088 Populate previous owner information
    */
    public static void populatePreviousOwner(List<Account> newList, Map<Id, Account> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        // if(runOnce && ranPopulatePreviousOwner) {
        //     return;
        // }

        Set<Id> ownerIds = new Set<Id>();
        for (Account newAccount : newList){
            ownerIds.add(newAccount.OwnerId);
        }
        if (oldMap!=null && !oldMap.isEmpty()){
            for (Account oldAccount : oldMap.values()){
                ownerIds.add(oldAccount.OwnerId);
            }
        }
        Set<Id> idsNotInOwnerManagerMap = new Set<Id>();
        for (Id ownerId : ownerIds){
            if (!ACCOUNT_OWNER_MANAGER_MAP.containsKey(ownerId)){
                idsNotInOwnerManagerMap.add(ownerId);
            }
        }
        if (!idsNotInOwnerManagerMap.isEmpty()){
            for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :idsNotInOwnerManagerMap]){
                ACCOUNT_OWNER_MANAGER_MAP.put(u.Id, u.ManagerId);
            }
        }
        for (Account newAccount : newList){
            newAccount.Account_Owner_Manager__c = ACCOUNT_OWNER_MANAGER_MAP.containsKey(newAccount.OwnerId) ? ACCOUNT_OWNER_MANAGER_MAP.get(newAccount.OwnerId) : null;
            if (oldMap!=null && !oldMap.isEmpty() && oldMap.containsKey(newAccount.Id)){
                Account oldAccount = oldMap.get(newAccount.Id);
                if (!newAccount.OwnerId.equals(oldAccount.OwnerId)){
                    newAccount.Previous_Account_Owner__c = oldAccount.OwnerId;
                    newAccount.Previous_Account_Owner_Manager__c = ACCOUNT_OWNER_MANAGER_MAP.containsKey(oldAccount.OwnerId) ? ACCOUNT_OWNER_MANAGER_MAP.get(oldAccount.OwnerId) : null;
                }
            }
            ranPopulatePreviousOwner = true;
        }
    }

    /**
    * @description BZAP-4247 - Move Update Parent Account with Child Deck Rank to code from process builder
    *   This method will update the deck rank on Parent Accounts only. It will update only if the deck rank is currently blank
    *   The value for the deck rank is based on values in the folowing fields
    *   - Highest_Child_Deck_Rank__c
    *   - Highest_Lead_Deck_Dank__c
    *   Note: Rollup Helper (managed package) is expected to update the above fields via its own trigger functionality
    */
    public static void updateDeckRankOnParentAccounts(List<Account> newList, Map<Id, Account> oldMap){
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranUpdateDeckRankOnParentAccounts) {
            return;
        }

        Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
        for (Account newAccount : newList){
            if (parentAccountRecordTypeId.equals(newAccount.RecordTypeId) && String.isBlank(newAccount.Deck_Rank__c)){
                Decimal highestChildDeckRank = newAccount.Highest_Child_Deck_Rank__c != null ? newAccount.Highest_Child_Deck_Rank__c : 0;
                Decimal highestLeadDeckRank = newAccount.Highest_Lead_Deck_Dank__c != null ? newAccount.Highest_Lead_Deck_Dank__c : 0;
                Decimal deckRank =  (   highestChildDeckRank != 0
                                     ?   ( highestLeadDeckRank != 0 ? Math.min(highestChildDeckRank, highestLeadDeckRank) : highestChildDeckRank )
                                     :   highestLeadDeckRank
                                    );
                if (DECK_RANK_TO_STRING_MAP.containsKey(deckRank)){
                    newAccount.Deck_Rank__c = DECK_RANK_TO_STRING_MAP.get(deckRank);
                }
            }
        }
    }

    /**
    * @author Tia Xuan
    * @date 2019-06
    *
    * @description BZAP-3901 Convert PB to Trigger (Create Dx Marketing Case On Create/Update)
    */
    public static void DxMarketingCase(List<Account> newAccountList, Map<Id, Account> oldMap){
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        // if(runOnce && ranDxMarketingCase) {
        //     return;
        // }

        Id accRTId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Consumer or Dasher')
            .getRecordTypeId();
        List<DDDesZipCodeExclusion__c> excludedZipsObj =  DDDesZipCodeExclusion__c.getAll().values();
        Set<String> excludedZips = new Set<String>();
        for (DDDesZipCodeExclusion__c setting: excludedZipsObj){
            excludedZips.add(setting.ZipCode__c);
        }

        List<Case> casesToAdd = new List<Case>();
        List<SKU_Mapping__mdt> skuMappingList = [SELECT Account_Field_API_Name__c, Case_SKU_Picklist_Value__c FROM SKU_Mapping__mdt Order by Sort_Order__c ];
        for (Account acc : newAccountList){
            if (acc.RecordTypeId == accRTId && (!excludedZips.contains(acc.PersonMailingPostalCode))){
                Account oldAccount = null;
                if (oldMap != null){
                    oldAccount = oldMap.get(acc.Id);
                }
                //BASD-51991
                Boolean allFalse = !((Boolean)(acc.get(skuMappingList[0].Account_Field_API_Name__c)));
                for (SKU_Mapping__mdt val : skuMappingList) {

                    allFalse = allFalse && !((Boolean)(acc.get(val.Account_Field_API_Name__c)));

                    if ((acc.Checkr_Report_ID__c != null &&
                         acc.get(val.Account_Field_API_Name__c) == true)
                        && (oldAccount == null
                            || oldAccount.get(val.Account_Field_API_Name__c)
                            != acc.get(val.Account_Field_API_Name__c))){

                                Case c = CreateMarketingCase(acc, val.Case_SKU_Picklist_Value__c);
                                casesToAdd.add(c);
                                allFalse = false;
                                break;

                            }
                }
                if(allFalse
                  && oldAccount != null
                  && acc.Checkr_Report_ID__c != null
                  && acc.Dasher_Kit_Ordered__c == false){

                           Case c = CreateMarketingCase(acc, 'DDK400');
                           acc.Dasher_Kit_Ordered__c = true;
                           casesToAdd.add(c);

                       }
            }
            ranDxMarketingCase = true;
        }

        if (casesToAdd.isEmpty()){
            return;
        }
        try{
            insert casesToAdd;
        }catch(Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'Dx marketing case creation exception: ' + ex.getMessage()}, 'CDdAccountHelperMethods',
                                             'DxMarketingCase', LoggingLevel.ERROR);
            throw ex;
        }
    }

    /**
    * @author Tia Xuan
    * @date 2019-06
    *
    * @description BZAP-3901 helper method to create marketing case
    */
    private static Case CreateMarketingCase(Account acct, String sku){
        BusinessHours bh = [select Id from BusinessHours where Name = 'San Francisco Business Hours'];
        Id caseRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Dasher / Merchant Kits')
            .getRecordTypeId();
        Group ownerGroup = [select Id from Group Where Name = 'Dasher / Merchant Kits'];

        Case c = new Case();
        c.BusinessHoursId = bh.Id;
        c.AccountId = acct.Id;
        c.Billing_Address__c = acct.PersonMailingStreet;
        c.Billing_City__c = acct.PersonMailingCity;
        c.Billing_Country__c = acct.PersonMailingCountry;
        c.Billing_State_Province__c = acct.PersonMailingState;
        c.Billing_Zip_Postal_Code__c = acct.PersonMailingPostalCode;
        c.Origin = 'Dasher Apply';
        c.Overture_Request_Type__c = 'Dasher Onboarding';
        c.OwnerId = ownerGroup.Id;
        c.RecordTypeId = caseRTId;
        c.SKU__c = sku;
        c.Status = 'Approved';
        return c;
    }

    /**
    * @author: Jeegar
    * @date: 2019-07
    * @Description: BZAP-4283 Merge duplicate leads and send the surviving lead back to the invoking function.
    * @params:      List<Lead>
    *
    */
    public static Set<Lead> findAndMergeDuplicateLeads(List<Lead> leads) {
        return findAndMergeDuplicateLeads(leads, new Set<Id>());
    }
    public static Set<Lead> findAndMergeDuplicateLeads(List<Lead> leads, Set<Id> survivingLeadIds) {
        Set<Lead> leadsToReturn = new Set<Lead>();
        List<Lead> duplicateLeadsToSort = new List<Lead>();
        List<Lead> leadsToMerge;
        Lead tempLead;
        Lead survivingLead;
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>();
        Map<String, Lead> emailLeadMap = new Map<String, Lead>();
        Map<Id, Lead> idLeadMap = new Map<Id,Lead>();
        Boolean addOnce = false;

        for(Lead currLead : leads) {
            emailLeadMap.put(currLead.email, currLead);
        }
        List<Datacloud.FindDuplicatesResult> duplicateResults = Datacloud.FindDuplicates.findDuplicates(emailLeadMap.values());
        Integer count = 0;
        if(duplicateResults != null && !duplicateResults.isEmpty()){
            for(Datacloud.FindDuplicatesResult result : duplicateResults) {
                addOnce = false;
                for (Datacloud.DuplicateResult dupeResult : result.getDuplicateResults()) {
                    // run this rule only for 'Phone_Number_Match' rule, not for account rule.
                    // convert to use custom settings.
                    errorMessages.add('><> Rule Name = ' + dupeResult.getDuplicateRule());
                    if(dupeResult.getDuplicateRule().equals('SelfServe_Lead_phone_Number_and_company_AND_street_match')) {
                        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                            errorMessages.add('><> Inside match Result : records = ' + matchResult.getMatchRecords());
                            duplicateLeadsToSort = new List<Lead>();
                            for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                if(matchRecord.getRecord().getSobjectType().getDescribe().getName().equals('Lead')){
                                    errorMessages.add('Adding Lead');
                                    tempLead = (Lead) matchRecord.getRecord();
                                    duplicateLeadsToSort.add(tempLead);
                                }
                                if(!addOnce) {
                                    // add the lead which was used to find duplicates.
                                    errorMessages.add('><> Adding original lead');
                                    duplicateLeadsToSort.add(emailLeadMap.values()[0]);
                                    addOnce = true;
                                }
                            }
                        }
                    }
                }

                // query duplicate leads again to get fields for comparision.
                // Match results does not return all fields.
                // this is a query in loop, but since this method is only used by a self serve user, we do not expect
                // bulkified data.
                if(duplicateLeadsToSort.isEmpty()) {
                    leadsToReturn.addAll(leads);
                    return leadsToReturn;
                }
                duplicateLeadsToSort = [SELECT Id, Name, Email, Phone, IsConverted, SDR_Owner__c, Deck_Rank__c,
                                        Address, OwnerId, Recent_Qualified_Activity_Date__c, createdDate,
                                        Owner.Type, CreatedById
                                        FROM Lead where id in :duplicateLeadsToSort
                                        OR Id IN :survivingLeadIds];
                errorMessages.add('><> Duplicates to Sort =  ' + duplicateLeadsToSort);
                if(duplicateLeadsToSort != null && duplicateLeadsToSort.size() >1 ) {

                    duplicateLeadsToSort = sortLead(duplicateLeadsToSort, survivingLeadIds);
                    // create a new lead instance because if you try to merge leads with Name, CreatedDate, etc
                    // it tries to write to those fields. Since they are system fields, an excepition is thrown.
                    survivingLead = new Lead(Id = duplicateLeadsToSort[0].Id);
                    // Put the leads in idLeadMap so that they can be retrieved later to fetch the surviving lead.
                    idLeadMap.put(duplicateLeadsToSort[0].id, duplicateLeadsToSort[0]);
                    leadsToMerge = new List<Lead>();

                    // Commented below section for BZAP-8092
                    /*
                    for(Integer i = 1; i < duplicateLeadsToSort.size(); i ++) {
                        // create a new lead instance because if you try to merge leads with Name, CreatedDate, etc
                        // it tries to write to those fields. Since they are system fields, an excepition is thrown.
                        leadsToMerge.add(New Lead(Id = duplicateLeadsToSort[i].id));
                        errorMessages.add('><> Leads to Merge = '+ leadsToMerge);
                        // Put the leads in idLeadMap so that they can be retrieved later to fetch the surviving lead.
                        idLeadMap.put(duplicateLeadsToSort[i].id, duplicateLeadsToSort[i]);
                        if(Math.mod(i,2) == 0) {
                            mergeResults.addAll(Database.Merge(survivingLead, leadsToMerge, false));
                            leadsToMerge = new List<Lead>();
                        }
                    }
                    if(leadsToMerge != null && !leadsToMerge.isEmpty()) {
                        mergeResults.addAll(Database.Merge(survivingLead, leadsToMerge, false));
                        leadsToMerge = new List<Lead>();
                    }
                    for(Database.MergeResult mergeResult : mergeResults) {
                        if(!mergeResult.isSuccess()) {
                            for(Database.Error err: mergeResult.getErrors()) {
                                errorMessages.add('Fields = ' + err.getFields() + 'Error Message = ' + err.getMessage());
                            }
                        } else {
                            errorMessages.add('><> Survivor Id = ' + mergeResult.getId());
                            leadMergePerformed = true;
                        }
                    }
                    */
                } else if(duplicateLeadsToSort != null && duplicateLeadsToSort.size() > 0) {
                    survivingLead = duplicateLeadsToSort[0];
                }
                // add the original instance of lead which queried fields so that it can be returned to the calling function.
                leadsToReturn.add(idLeadMap.get(survivingLead.id));
                count ++;
            }

        }
        errorMessages.add('><> ' + leadsToReturn);
        return leadsToReturn;
    }

    /*
    * @author : Jeegar
    * @date 2019-07
    * @description : Sort Leads based on custom sort.
    * @params:      List<Lead>
    */
    public static List<Lead> sortLead(List<Lead> leads, Set<Id> survivingLeadIds) {
        List<Lead> sortedLeads = new List<Lead>();
        List<CDdLeadSortWrapper> wrapperList = new List<CDdLeadSortWrapper>();
        CDdLeadSortWrapper currWrapper;
        for(Lead currLead : leads) {
            if(survivingLeadIds != null && survivingLeadIds.contains(currLead.Id)){
                sortedLeads.add(currLead);
                continue;
            }
            currWrapper = new CDdLeadSortWrapper(currLead);
            wrapperList.add(currWrapper);
        }
        wrapperList.sort();
        for (CDdLeadSortWrapper sortedWrapper : wrapperList) {
            sortedLeads.add(sortedWrapper.currLead);
        }
        return sortedLeads;
    }

    /**
    * @author Sriram
    * @date 08/05/2019
    *
    * @description BZAP-4113 Dial Count And Email Count
    */
    public static void updateTaskCount(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranUpdateTaskCount) {
            return;
        }

        List<Update_Task_Count_Event__e> updateTaskCountEvents = new List<Update_Task_Count_Event__e>();
        for (Account newAccount : newMap.values()){
            if (oldMap!=null && !oldMap.isEmpty() && oldMap.containsKey(newAccount.Id)){
                Account oldAccount = oldMap.get(newAccount.Id);
                if (!newAccount.OwnerId.equals(oldAccount.OwnerId)){
                    updateTaskCountEvents.add(new Update_Task_Count_Event__e(
                        SObject_Record_Id__c = newAccount.Id
                        , SObject_Type__c = SOBJECT_TYPE_ACCOUNT
                    ));
                }
            }
        }
        if (!updateTaskCountEvents.isEmpty()) {
            ranUpdateTaskCount = true;
            EventBus.publish(updateTaskCountEvents);
        }
    }

    /**
    * @author Knick
    * @description BZAP-6347 Move Rollup and Lookup Helper to Trigger - do Rollups from Account to Account
    */
    public static void doAccountRollups (List<Account> accounts, Map<Id, Account> oldMap, Boolean isDeleteOrUndelete) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if (runOnce && ranDoAccountRollups) {
            return;
        }
        if (CDdCustomMetaData.isDisabled('CDdAccountHelperMethods_doAccountRollups')) return;

        Set<Id> parentAccountIds = new Set<Id>();
        for (Account a : accounts) {
            if (isDeleteOrUndelete && a.ParentId != null) {
                parentAccountIds.add(a.ParentId);
                processAccountRollups(parentAccountIds);
                return;
            } else if (oldMap == null) {
                if (a.ParentId != null) {
                    parentAccountIds.add(a.ParentId);
                }
            } else {
                Account oldAccount = oldMap.get(a.Id);
                if ((a.ParentId != oldAccount.ParentId) ||                          // Parent has changed OR
                    (a.Amount__c != oldAccount.Amount__c) ||                        // Amount has changed
                    (a.Currently_Active__c != oldAccount.Currently_Active__c) ||    // Currently Active has changed
                    (a.Has_nTam__c != oldAccount.Has_nTam__c) ||                    // Has nTam has changed
                    (a.Deck_Rank__c != oldAccount.Deck_Rank__c) ||                  // Underlying Deck Rank has changed
                    (a.of_CW_MP_Opps__c != oldAccount.of_CW_MP_Opps__c) ||          // # of CW MP Opps has changed
                    (a.of_Locations__c != oldAccount.of_Locations__c)) {            // # of Locations has changed
                        if (a.ParentId != null) {
                            parentAccountIds.add(a.ParentId);                           // ... recalculate for Parent
                        }
                        if (oldAccount.ParentId != null) {
                            parentAccountIds.add(oldAccount.ParentId);                  // ... recalculate for old Parent
                        }
                    }
            }
        }

        if (parentAccountIds.size() > 0) {
            ranDoAccountRollups = true;
            CDdGenericPlatformEventHelper.publishEvents(
                CDdGenericPlatformEventHelper.PlatformEventType.ACCOUNT_ROLLUP,
                parentAccountIds
            );
        }
    }

    /**
    * BZAP-8484: Move to Platform Event to avoid Apex errors
    * @param rollupEvents
    */
    public static void handleAccountRollupEvents(List<Generic_Platform_Event__e> rollupEvents) {
        Set<Id> parentAccountIds = new Set<Id>();
        for (Generic_Platform_Event__e rollupEvent : rollupEvents) {
            parentAccountIds.add(rollupEvent.sObjectId__c);
        }
        processAccountRollups(parentAccountIds);
    }

    /**
    * BZAP-8484: Move to Platform Event to avoid SELF_REFERENCE_FROM_TRIGGER on Account merge
    * @param parentAccountIds
    */
    public static void processAccountRollups(Set<Id> parentAccountIds) {
        AggregateResult[] initialResults = [
            SELECT ParentId,
            AVG(Amount__c) avgAmount,
            SUM(Has_nTam__c) sumNtam,
            COUNT(Id) countChildren,
            MIN(Deck_Rank_Number__c) minDeckRankNumber,
            SUM(Amount__c) sumAmount,
            SUM(of_CW_MP_Opps__c) sumCwMpOpps,
            SUM(of_Locations__c) sumLocations
            FROM Account
            WHERE IsDeleted = false AND isPersonAccount = false AND ParentId IN :parentAccountIds
            GROUP BY ParentId
        ];

        AggregateResult[] activeChildResults = [
            SELECT ParentId, count(Id) numberOfActiveChildren
            FROM Account
            WHERE IsDeleted = false AND isPersonAccount = false AND ParentId = :parentAccountIds
            AND Currently_Active__c = 'Yes'
            GROUP BY ParentId
        ];

        Map<Id, Integer> numberOfActiveChildrenMap = new Map<Id, Integer>();
        for (AggregateResult ar : activeChildResults) {
            numberOfActiveChildrenMap.put((Id) ar.get('ParentId'), (Integer) ar.get('numberOfActiveChildren'));
        }

        Map<Id, Account> accountToUpdateMap = new Map<Id, Account>();
        if (initialResults.size() == 0) {
            // Update values when removing the last child
            for (Id id : parentAccountIds) {
                Account account = new Account();
                account.Id = id;
                account.Average_of_Account_nTam__c = null;
                account.of_Accounts_w_nTam__c = null;
                account.of_child_accounts__c = null;
                account.of_Active_Child_Accounts__c = null;
                account.Highest_Child_Deck_Rank__c = null;
                account.Sum_of_NTAM__c = null;
                account.Total_MK_Opps__c = null;
                account.Number_of_Stores_Partner__c = null;
                accountToUpdateMap.put(account.Id, account);
            }
        } else {
            for (AggregateResult ar : initialResults) {
                Account account = new Account();
                account.Id = (Id)ar.get('ParentId');
                account.Average_of_Account_nTam__c = (Decimal)ar.get('avgAmount');
                account.of_Accounts_w_nTam__c = (Decimal)ar.get('sumNtam');
                account.of_child_accounts__c = (Decimal)ar.get('countChildren');
                account.of_Active_Child_Accounts__c = numberOfActiveChildrenMap.get((Id) ar.get('ParentId'));
                account.Highest_Child_Deck_Rank__c = (Decimal)ar.get('minDeckRankNumber');
                account.Sum_of_NTAM__c = (Decimal)ar.get('sumAmount');
                account.Total_MK_Opps__c = (Decimal)ar.get('sumCwMpOpps');
                account.Number_of_Stores_Partner__c = (Decimal)ar.get('sumLocations');
                accountToUpdateMap.put(account.Id, account);
            }
            ranDoAccountRollups = true;
            try{
                update accountToUpdateMap.values();
            }catch(Exception ex){
                CDdErrorUtilities.createApexLogs(new List<String>{'Account Rollup exception: ' + ex.getMessage()}, 'CDdAccountHelperMethods',
                                                 'doAccountRollups', LoggingLevel.ERROR);
                throw ex;
            }
        }
    }

    /**
    * @author Tia Xuan
    * @description  BZAP-5697 Add Account Owner field to Opportunity Object
    *               BZAP-6900 0 batches for account without opportunities
    */
    public static void copyAccountOwnerToOpportunity(List<Account> accounts, Map<Id, Account> oldMap) {
        if (!ENABLE_PLATFORM_EVENT_COPY_ACCT_TO_OPP || fieldCopyToOpportunityFlag) return;

        List<Copy_Parent_Account_Event__e> copyParentAccountEvents = new List<Copy_Parent_Account_Event__e>();
        List<String> parentAccountCopyFields = accountFieldCopyToAccountObj.sourceFields;

        List<Id> accountIds = new List<Id>();

        for (Account newAcct : accounts) {
            if (oldMap == null ||
                (newAcct.OwnerId != oldMap.get(newAcct.Id).OwnerId)) {
                    accountIds.add(newAcct.Id);
                }
        }

        List<AggregateResult> accToOppCount = [ select AccountId, Count(Id)oppCount
                                               from Opportunity
                                               where AccountId =: accountIds
                                               group by AccountId];

        for (AggregateResult ar : accToOppCount){
            Integer oppCount = (Integer) ar.get('oppCount');
            String accountId = (String) ar.get('AccountId');
            if (oppCount > 0){
                copyParentAccountEvents.add(new Copy_Parent_Account_Event__e(Parent_Account_Id__c = accountId, Copy_To_Opportunity__c = true ));
            }
        }

        if (!copyParentAccountEvents.isEmpty()) {
            EventBus.publish(copyParentAccountEvents);
            fieldCopyToOpportunityFlag = true;
        }
    }

    /**
    * @author: Tia Xuan
    * @date 03/2020
    * @description: BZAP-6950 Changing PB to Trigger -- Update Opp Amount from Account
    *               BZAP-7265 Updated for lead convert and add deck rank
    *
    */
    public static void updateOppAmount(List<Account> accounts, Map<Id, Account> oldMap){

        if (!ENABLE_PLATFORM_EVENT_COPY_ACCT_TO_OPP || copyAccountAmountToOpportunityFlag) return;

        List<Copy_Parent_Account_Event__e> copyParentAccountEvents = new List<Copy_Parent_Account_Event__e>();
        List<String> parentAccountCopyFields = accountFieldCopyToAccountObj.sourceFields;

        Map<Id, Account> accMap = new Map<Id, Account>();

        for (Account newAcct : accounts) {
            if (oldMap == null ||
                (newAcct.Amount__c != oldMap.get(newAcct.Id).Amount__c) ||
                (newAcct.Deck_Rank__c != oldMap.get(newAcct.Id).Deck_Rank__c) ||
                (newAcct.Converted_Lead_ID__c != null)) {
                    accMap.put(newAcct.Id, newAcct);
                }
        }

        if (accMap.size() > 0){
            List<AggregateResult> accToOppCount = [ select AccountId, Count(Id)oppCount
                                                   from Opportunity
                                                   where AccountId =: accMap.keySet()
                                                   group by AccountId];

            Set<Id> accWithEvents = new Set<Id>();
            for (AggregateResult ar : accToOppCount){
                Integer oppCount = (Integer) ar.get('oppCount');
                Id accountId = (Id) ar.get('AccountId');
                Account acc = accMap.containsKey(accountId) ? accMap.get(accountId) : new Account();
                if (oppCount > 0){
                    copyParentAccountEvents.add(new Copy_Parent_Account_Event__e(Parent_Account_Id__c = accountId, Copy_To_Opportunity__c = true ));
                    accWithEvents.add(accountId);
                }
            }

            // Added for lead conversion when the opportunity is not created yet
            for (Account acc : accMap.values()){
                if (!accWithEvents.contains(acc.Id)
                    && acc.Converted_Lead_ID__c != null){
                        copyParentAccountEvents.add(new Copy_Parent_Account_Event__e(Parent_Account_Id__c = acc.Id, Copy_To_Opportunity__c = true ));
                    }
            }

            if (!copyParentAccountEvents.isEmpty()) {
                EventBus.publish(copyParentAccountEvents);
                copyAccountAmountToOpportunityFlag = true;
            }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 03/2020
    * @description: BZAP-6950 Changing PB to Trigger -- Create Lead when Lead Creation Approval Completed
    *
    */
    public static void createLeadOnLeadCreationApproval(List<Account> accounts, Map<Id, Account> oldMap){
        if (ranCreateLeadOnLeadCreationApproval) return;

        Id marketplaceRTId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Marketplace')
            .getRecordTypeId();
        Id masterLeadRTId = Schema.SObjectType.Lead
            .getRecordTypeInfosByName()
            .get('Master Lead')
            .getRecordTypeId();

        List<Account> affectedAccounts = new List<Account>();
        for (Account newAcct : accounts) {
            if (oldMap == null ||
                (newAcct.Lead_Creation_Approval_Completed__c != oldMap.get(newAcct.Id).Lead_Creation_Approval_Completed__c)) {
                    if (newAcct.Lead_Creation_Approval_Completed__c
                        && newAcct.RecordTypeId == marketplaceRTId){
                            affectedAccounts.add(newAcct);
                            newAcct.Lead_Creation_Approval_Completed__c = false;
                        }
                }
        }

        List<Lead> leadsToInsert = new List<Lead>();
        for (Account acc : affectedAccounts){
            Lead l = new Lead();
            l.LastName = '[Unknown]';
            l.Account__c = acc.Id;
            l.Amount__c = acc.Amount__c;
            l.City = acc.BillingCity;
            l.Company = acc.Name;
            l.Country = acc.BillingCountry;
            l.Deck_Rank__c = acc.Deck_Rank__c;
            l.OwnerId = UserInfo.getUserId();
            l.Phone = acc.Phone;
            l.PostalCode = acc.BillingPostalCode;
            l.RecordTypeId = masterLeadRTId;
            l.State = acc.BillingState;
            l.Status = 'Untouched';
            l.Street = acc.BillingStreet;
            leadsToInsert.add(l);
        }

        if (leadsToInsert.isEmpty()){
            return;
        }
        ranCreateLeadOnLeadCreationApproval = true;
        try{
            insert leadsToInsert;
        }catch(Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'Lead creation exception' + ex.getMessage()}, 'CDdAccountHelperMethods',
                                             'createLeadOnLeadCreationApproval', LoggingLevel.ERROR);
            throw ex;
        }
    }

    /**
    * @author: Tia Xuan
    * @date 04/2020
    * @description: BZAP-7194 Clean the EIN (Encrypted), Account Number (Encrypted),
    *                          Routing Number (Encrypted), Institution Number (Encrypted) fields on Accounts
    *
    */
    public static void cleanEncryptedFields(List<Account> accounts, Map<Id, Account> oldMap){

        for (Account newAcct : accounts) {
            if (oldMap == null ||
                (newAcct.EIN_Encrypted__c != oldMap.get(newAcct.Id).EIN_Encrypted__c) ||
                (newAcct.Bank_Account_Number_Encrypted__c != oldMap.get(newAcct.Id).Bank_Account_Number_Encrypted__c) ||
                (newAcct.Bank_Institution_Number_Encrypted__c != oldMap.get(newAcct.Id).Bank_Institution_Number_Encrypted__c) ||
                (newAcct.Bank_Routing_Number_Encrypted__c != oldMap.get(newAcct.Id).Bank_Routing_Number_Encrypted__c)) {
                    newAcct.EIN_Encrypted__c = replaceChars(newAcct.EIN_Encrypted__c);
                    newAcct.Bank_Account_Number_Encrypted__c = replaceChars(newAcct.Bank_Account_Number_Encrypted__c);
                    newAcct.Bank_Institution_Number_Encrypted__c = replaceChars(newAcct.Bank_Institution_Number_Encrypted__c);
                    newAcct.Bank_Routing_Number_Encrypted__c = replaceChars(newAcct.Bank_Routing_Number_Encrypted__c);
                }
        }
    }

    public static void updateADR(List<Account> accounts, Map<Id, Account> oldMap){
        Set<Id> transferredAccountsOwnerIds = new Set<Id>();
        List<Account> transferredAccounts = new List<Account>();
        for (Account acc : accounts) {
            if (acc.OwnerId != oldMap.get(acc.Id).OwnerId) {
                transferredAccountsOwnerIds.add(acc.OwnerId);
                transferredAccounts.add(acc);
            }
        }
        if(transferredAccounts.isEmpty()){
            return;
        }
        Map<Id, User> newOwners = new Map<Id, User>(
            UsersSelector.newInstance().selectById(transferredAccountsOwnerIds)
        );
        for(Account acc: transferredAccounts){
            String adr = newOwners.get(acc.OwnerId).ADR__c;
            acc.ADR_Owner_Actual__c = (adr instanceof Id) ? adr : null;
        }
    }

    private static string replaceChars(String origVal){
        String retVal = origVal;
        if (String.isNotBlank(retVal)){
            retVal = retVal.replaceAll('-', '');
            retVal = retVal.replaceAll(' ', '');
        }
        return retVal;
    }

    /**
    * BZAP-8652: Set preferred language for account based on BillingCountryCode and BillingStateCode.
    * Note, BillingCountryCode and BillingStateCode are dependent picklists that set the values of
    * BillingState and BillingCountry, and Trigger.new does not see these changes in a before update.
    *
    * @param newList
    * @param oldMap
    */
    public static void setLanguage(List<Account> newList, Map<Id, Account> oldMap) {
        Boolean isInsert = oldMap == null ? true : false;
        Boolean isSame;

        Map<String, String> preferredLanguageMap = getPreferredLanguages();

        for (Account a : newList) {
            isSame = !isInsert
                && a.BillingCountryCode == oldMap.get(a.Id).BillingCountryCode
                && a.BillingStateCode == oldMap.get(a.Id).BillingStateCode;

            if (a.Language__c == null && !isSame) {
                if (preferredLanguageMap.get(a.BillingCountryCode + '-' + a.BillingStateCode) != null) {
                    // Use preferred language for state
                    a.Language__c = preferredLanguageMap.get(a.BillingCountryCode + '-' + a.BillingStateCode);
                } else {
                    // Use preferred language for country, **if any**
                    a.Language__c = preferredLanguageMap.get(a.BillingCountryCode + '-' + null);
                }
            }
        }
    }

    //map latin address to Kanji for JP Profiles
    public static void latinToKanjiMapping(List<Account> newList) {

        //map for StateCode to State Name
        Map<String, String> MapStateCodeToStateName = new Map<String, String>();

        //map for CountryCode to Country name
        Map<String, String> MapCountryCodeToCountryName = new Map<String, String>();

        Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            MapStateCodeToStateName.put(f.getValue(), f.getLabel());
        }
        Map<String, String> latinToKanjiStateMap = CDdI18nUtility.getLatinToKanjiStateMap();

        Schema.DescribeFieldResult fieldResult2 = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
        for( Schema.PicklistEntry f : ple2){
            MapCountryCodeToCountryName.put(f.getValue(), f.getLabel());
        }

        for(Account l: newList){
            String latinCountry = MapCountryCodeToCountryName.get(l.billingcountryCode);
            String latinState = MapStateCodeToStateName.get(l.billingstateCode);
            String kanjiState = String.isEmpty(latinToKanjiStateMap.get(latinState)) ? '' : latinToKanjiStateMap.get(latinState);
            if(latinCountry == 'Japan' && l.Kanji_Address_Verified__c == false){
                if(l.billingstreet != null && l.billingstreet != '' ){
                    l.Kanji_Street__c =  l.billingstreet;
                }
                if(l.billingcity != null && l.billingcity != '' ){
                    l.Kanji_City__c = l.billingcity;
                }
                if(kanjiState != null && kanjiState != ''){
                    l.Kanji_State__c = kanjiState;
                }
                if(l.billingpostalcode != null && l.billingpostalcode != ''){
                    l.Kanji_Zip__c  = l.billingpostalcode;
                }
                if(latinCountry != null && latinCountry != ''){
                    l.Kanji_Country__c = latinCountry;
                }
                if(l.address2__c != null && l.address2__c != ''){
                    l.Kanji_Address2__c = l.address2__c;
                }
            }
        }
    }

    //map latin address to Kanji for JP Profiles on Update
    public static void latinToKanjiMappingBeforeUpdate(List<Account> newList,Map<id,Account> oldMap) {

        //map for StateCode to State Name
        Map<String, String> MapStateCodeToStateName = new Map<String, String>();

        //map for CountryCode to Country name
        Map<String, String> MapCountryCodeToCountryName = new Map<String, String>();

        Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            MapStateCodeToStateName.put(f.getValue(), f.getLabel());
        }
        Map<String, String> latinToKanjiStateMap = CDdI18nUtility.getLatinToKanjiStateMap();

        Schema.DescribeFieldResult fieldResult2 = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
        for( Schema.PicklistEntry f : ple2){
            MapCountryCodeToCountryName.put(f.getValue(), f.getLabel());
        }

        for(Account l: newList){
            String latinCountry = MapCountryCodeToCountryName.get(l.billingcountryCode);
            String latinState = MapStateCodeToStateName.get(l.billingstateCode);
            String kanjiState = String.isEmpty(latinToKanjiStateMap.get(latinState)) ? '' : latinToKanjiStateMap.get(latinState);
            if(latinCountry == 'Japan' && l.smartystreets__Billing_Last_Verified__c == oldMap.get(l.id).smartystreets__Billing_Last_Verified__c  ){
                if(l.billingstreet != null && l.billingstreet != '' && (oldmap.get(l.id).billingstreet !=l.billingstreet || String.isBlank(l.Kanji_Street__c) )){
                    l.Kanji_Street__c =  l.billingstreet;
                    l.Kanji_Address_Verified__c = false;
                }
                if(l.billingcity != null && l.billingcity != '' && (oldmap.get(l.id).billingcity !=l.billingcity || String.isBlank(l.Kanji_City__c) ) ){
                    l.Kanji_City__c = l.billingcity;
                    l.Kanji_Address_Verified__c = false;
                }
                if(kanjiState != null && kanjiState != '' && (oldmap.get(l.id).billingstateCode !=l.billingstateCode || String.isBlank(l.Kanji_State__c) )){
                    l.Kanji_State__c = kanjiState;
                    l.Kanji_Address_Verified__c = false;
                }
                if(l.billingpostalcode != null && l.billingpostalcode != '' && (oldmap.get(l.id).billingpostalcode !=l.billingpostalcode || String.isBlank(l.Kanji_Zip__c) )){
                    l.Kanji_Zip__c  = l.billingpostalcode;
                    l.Kanji_Address_Verified__c = false;
                }
                if(latinCountry != null && latinCountry != '' && (oldmap.get(l.id).billingcountryCode !=l.billingcountryCode || String.isBlank(l.Kanji_Country__c) )){
                    l.Kanji_Country__c = latinCountry;
                    l.Kanji_Address_Verified__c = false;
                }
                if(l.Address2__c != null && l.Address2__c != '' && (oldmap.get(l.id).Address2__c !=l.Address2__c || String.isBlank(l.Kanji_Address2__c) ) ){
                    l.Kanji_Address2__c = l.Address2__c;
                    l.Kanji_Address_Verified__c = false;
                }
                if(l.Kanji_Address_Verified__c == false)
                {

                    l.Kanji_Address_Footnotes__c='';
                    l.Kanji_Address_Return_Code__c='';
                    l.Kanji_Address_Last_Verified__c=null;

                }
            }
        }
    }

    public static void populateBankAccountPrefix(List<Account> newList, Map<Id, Account> oldMap) {
        for (Account a : newList) {
            if ((CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId().equals(a.RecordTypeId) || CDdSchemaUtils.ACCOUNT_RT.prospectId().equals(a.RecordTypeId)) &&
                !String.isBlank(a.Bank_Account_Number_Encrypted__c) &&
                !a.Bank_Account_Number_Encrypted__c.startsWithIgnoreCase('DE') &&
                a.BillingCountry == 'Germany') {
                a.Bank_Account_Number_Encrypted__c = 'DE' + a.Bank_Account_Number_Encrypted__c;
            }
        }
    }

    /**
    * BZAP-8652: Provide fixed mapping for testing since we can't control what values actually exist.
    *
    * @return
    */
    private static Map<String, String> getPreferredLanguages() {
        Map<String, String> preferredLanguageMap = new Map<String, String>();
        if (Test.isRunningTest()) {
            preferredLanguageMap.put('CA-QB', 'French');
            preferredLanguageMap.put('CA-null', 'English');
        } else {
            for (Preferred_Language__mdt preferredLanguage : [select Billing_Country_Code__c, Billing_State_Code__c, Language__c from Preferred_Language__mdt]) {
                preferredLanguageMap.put(
                    preferredLanguage.Billing_Country_Code__c + '-' + preferredLanguage.Billing_State_Code__c,
                    preferredLanguage.Language__c);
            }
        }
        return preferredLanguageMap;
    }

    /**
     * BZAP-9825
     *
     * @param List<Account> newList
     * @return
     */
    public static void checkAccountCoverage(List<Account> newList) {
        if (CDdCustomMetaData.isDisabled('CDdAccountHelperMethods_accountCoverage')) return;

        Set<String> allowedRecordTypes = new Set<String>{
            'Prospect', 'Enterprise_Marketplace', 'DoorDash_Drive', 'Enterprise_Drive', 'Vendor'
        };
        Set<Id> recordIds = new Set<Id>();
        for (Account accRec: newList) {
            if (allowedRecordTypes.contains(accRec.RecordType.DeveloperName) &&
                accRec.BillingStreet != null &&
                accRec.BillingPostalCode != null &&
                (accRec.In_Coverage__c == null || accRec.In_Coverage__c == 'Unknown') &&
                (accRec.Starting_Point__c == null || accRec.Starting_Point_ID__c == null)
                ) {
                    recordIds.add(accRec.Id);
                }

        }

        if (!recordIds.isEmpty()) {
            CDdGenericPlatformEventHelper.publishEvents(
                CDdGenericPlatformEventHelper.PlatformEventType.CHECK_ACCOUNT_COVERAGE,
                recordIds
            );
        }
    }

    /**
     * BZAP-9825
     *
     * @param List<Account> newList
     * @return
     */
    public static void handleCheckAccountCoverage(List<Generic_Platform_Event__e> dtEvents){
        List<Id> trAccountIds = new List<Id>();

        for (Generic_Platform_Event__e e : dtEvents) {
            trAccountIds.add(e.sObjectId__c);
        }

        if (!Test.isRunningTest()){
            handleFutureCheckAccountCoverage(trAccountIds);
        }
    }

    @future (callout=true)
    public static void handleFutureCheckAccountCoverage(List<Id> accountIds) {
        CDdCoverageCheckSvcV2.checkAcctCoverage(accountIds);
    }


    /**
    * @author Ed
    * @date 2021-06
    * @description BZAP-11027
    */
    public static void handleMerchantCategories(List<Account> newList, Map<Id, Account> oldMap) {
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Account.sObjectType);
        vertCatHelper.handleMerchantCategories(newList, oldMap);

        if (oldMap != null) {
            vertCatHelper.handlePrimaryCategoryUpdate(newList, oldMap);
        }
    }

    public static void deleteAllMxCategories(Map<Id, Account> oldMap) {
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Account.sObjectType);
        vertCatHelper.deleteAllMxCategories(oldMap);
    }

    /**
    * @author Ed
    * @date 2021-06
    * @description BZAP-11027
    */
    public static void handleMxCategoryMerge(List<Account> oldList) {
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Account.sObjectType);
        vertCatHelper.handleMxCategoryMerge(oldList);
    }

    /**
    * @date 2021-08
    * @description BZAP-11404 - When Parent Account (Record Type) “Top Mx” flag is changed, propagate the value down to all child accounts records.
     * @param List<Account> Collection of new Account records
     * @param List<Account> Collection of old Account records
     * @return
    */
    public static void updateTopMxHighAov(Map<Id,Account> newMap,Map<Id,Account> oldMap) {
        if(!CDdRecursionUtils.isRunnable('CDdAccountHelperMethods_updateTopMxHighA')){
            return;
        }

        Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
        List<Account> updatedParentAccounts = new List<Account>();
        for(Account newAcct:newMap.values()){
            if(parentAccountRecordTypeId.equals(newAcct.RecordTypeId) &&
                (newAcct.Top_Mx__c != oldMap.get(newAcct.Id).Top_Mx__c || newAcct.High_AOV__c != oldMap.get(newAcct.Id).High_AOV__c)){
                    updatedParentAccounts.add(newAcct);
            }
        }

        if(updatedParentAccounts.size() > 0){
            List<Account> childAccounts = [Select Id,ParentId from Account WHERE ParentId IN :updatedParentAccounts];
            if(childAccounts.size() > 0){
                for(Account childAcct:childAccounts){
                    childAcct.Top_Mx__c = newMap.get(childAcct.ParentId).Top_Mx__c;
                    childAcct.High_AOV__c = newMap.get(childAcct.ParentId).High_AOV__c;
                }

                Database.SaveResult[] accUpdateresults = Database.update(childAccounts,false);

                for (Database.SaveResult sr : accUpdateresults) {
                    for (Database.Error error : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'updateTopMxHighAov, error: ' + error);
                    }
                }
            }
        }
    }

    /**
    * @author Lathika
    * @date 2021-10
    * @description BZAP-11406: this method concatenates the BusinessVertical's(Menu_UI_Type__c,Name,Business_Vertical_Id__c) on Account's Business_Vertical_Details__c field
    * This applies to Parent Accounts Only
    * Perform for Insert operation or Update operation where the Business Vertical has changed
    * @param List<Account> Collection of new Account records
    * @param Map<Id,Account> Collection of old Account records
    * @return
    */
    public static void setBusinessVerticalDetails(List<Account> newList, Map<Id, Account> oldMap) {
        if (ranBusinessVerticalDetails){
            return;
        }
        Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
        for (Account newAccount : newList) {
            if (parentAccountRecordTypeId.equals(newAccount.RecordTypeId)) {
                if(oldMap == null || (newAccount.Business_Vertical__c != oldMap.get(newAccount.Id).Business_Vertical__c)){
                    if(newAccount.Business_Vertical__c != null && BUSINESS_VERTICAL_MAP.containsKey(newAccount.Business_Vertical__c)){
                        newAccount.Business_Vertical_Details__c = BUSINESS_VERTICAL_MAP.get(newAccount.Business_Vertical__c).Menu_UI_Type__c + ' UI - ' +
                                                                  BUSINESS_VERTICAL_MAP.get(newAccount.Business_Vertical__c).Name + ' - ' +
                                                                  BUSINESS_VERTICAL_MAP.get(newAccount.Business_Vertical__c).Business_Vertical_Id__c;
                    } else {
                        newAccount.Business_Vertical_Details__c = null;
                    }
                }
                ranBusinessVerticalDetails = true;
            }
        }
    }

    /**
    * @author Cory Bartholomew (ATG)
    * @description BZAP-11884 Fire a platform event to handle updating the ultimate parent lookup
    */
    public static void setUltimateParentAfterInsert(List<Account> accounts) {
        Set<Id> accountIdsForUpdate = new Set<Id>();
        for (Account account : accounts) {
            if (String.isBlank(account.Ultimate_Parent_Account__c) && isHierarchyAccount(account.RecordTypeId)){
                accountIdsForUpdate.add(account.Id);
            }
        }
        if(!accountIdsForUpdate.isEmpty()){
            setUltimateParent(accountIdsForUpdate);
        }
    }

    /**
    * @author Cory Bartholomew (ATG)
    * @description BZAP-11884 Fire a platform event to handle updating the ultimate parent lookup
    */
    public static void setUltimateParentAfterUpdate(Map<Id,Account> accountsMap, Map<Id, Account> oldMap) {
        Set<Id> accountIdsForUpdate = new Set<Id>();
        for (Account account : accountsMap.values()) {
            Account oldAccount = oldMap.get(account.Id);
            if (
                (
                    String.isBlank(account.Ultimate_Parent_Account__c) ||
                    account.Ultimate_Parent_Id__c != oldAccount.Ultimate_Parent_Id__c
                ) &&
                (
                    account.Ultimate_Parent_Id__c != account.Id  && //The account cannot reference itself directly in a lookup
                    isHierarchyAccount(account.RecordTypeId)
                )
            ) {
                accountIdsForUpdate.add(account.Id);
            }
        }
        if(!accountIdsForUpdate.isEmpty()){
            setUltimateParent(accountIdsForUpdate);
        }
    }

    /**
    * @author Cory Bartholomew (ATG)
    * @description BZAP-11884 Fire a platform event to handle updating the ultimate parent lookup
    */
    public static void setUltimateParent(Set<Id> accountIdsForUpdate) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if (ranUltimateParent || CDdCustomMetaData.isDisabled('CDdAccountHelperMethods_UltimateParent')) {
            return;
        }
        if(!accountIdsForUpdate.isEmpty()) {
            CDdGenericPlatformEventHelper.publishEvents(
                CDdGenericPlatformEventHelper.PlatformEventType.ACCOUNT_ULTIMATE_PARENT,
                accountIdsForUpdate
            );
        }
    }

    public static Boolean isHierarchyAccount(Id recordTypeId){
        if(
            recordTypeId == RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_GRANDPARENT_ACCOUNT).getRecordTypeId() ||
            recordTypeId == RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId() ||
            recordTypeId == RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_MARKETPLACE).getRecordTypeId() ||
            recordTypeId == RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_ENTERPRISE_MARKETPLACE).getRecordTypeId()
        ){
            return true;
        } else {
            return false;
        }
    }
    /**
    * @author Cory Bartholomew (ATG)
    * @description BZAP-11884 Set the Ultimate parent account based on the Ultimate_Parent_Id__c formula field
    * Ultimate_Parent_Id__c will always have a value
    */
    public static void processUltimateParentEvents(List<Generic_Platform_Event__e> ultimateParentEvents) {
        Set<Id> accountIdsForUpdate = new Set<Id>();
        for (Generic_Platform_Event__e ultimateParentEvent : ultimateParentEvents) {
            accountIdsForUpdate.add(ultimateParentEvent.sObjectId__c);
        }

        List<Account> accounts = [
            SELECT Id, Name, Ultimate_Parent_Id__c, Ultimate_Parent_Account__c,
                (
                    SELECT Id, Name, Ultimate_Parent_Id__c, Ultimate_Parent_Account__c
                    FROM ChildAccounts
                )
            FROM Account
            WHERE Id IN :accountIdsForUpdate
        ];

        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> childAccountIds = new Set<Id>();
        for(Account acct : accounts){
            if(
                (
                    String.isBlank(acct.Ultimate_Parent_Account__c) ||
                    acct.Ultimate_Parent_Id__c != acct.Ultimate_Parent_Account__c
                ) &&
                (
                    acct.Ultimate_Parent_Id__c != acct.Id  //The account cannot reference itself directly in a lookup
                )
            ){
                acct.Ultimate_Parent_Account__c = acct.Ultimate_Parent_Id__c;
                accountsToUpdate.add(acct);
            }
            //If the updated accounts were parents, the children also need to be updated.  Get their Ids to fire new events for them to be updated
            if(!acct.ChildAccounts.isEmpty()){
                for(Account childAcct : acct.ChildAccounts){
                    childAccountIds.add(childAcct.Id);
                }
            }
        }

        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }

        //fire off another round of events to update the children that may need to be updated
        if(!childAccountIds.isEmpty()){
            setUltimateParent(childAccountIds);
        }
    }

   /**
    * @author Sriram
    * @date 2021-10
    * @description BZAP-11417: Track Setup Catalog milestone for Parent Account Business Vertical of Retail
    * Following is the criteria to track Setup Catalog milestone
    * 1. Account being processed is a Parent Account (i.e. account of record type 'Parent Account')
    * 2. Account has a valid reference to a Business Vertical record
    * 3. Account is either being inserted OR Account is being updated for Business Vertical (i.e change in Business Vertical)
    * 4. And Menu UI Type on new account referenced Business Vertical record is 'Retail'
    * @param List<Account> Collection of new Account records
    * @param Map<Id,Account> Collection of old Account records
    * @return
    */
    public static void setupCatalogMilestoneForBusinessVerticalRetail(List<Account> newList, Map<Id, Account> oldMap) {
        if (ranSetupCatalogMilestoneForBusinessVerticalRetail){
            return;
        }
        Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
        Set<Id> parentAccountIds = new Set<Id>();
        for (Account newAccount : newList) {
            if  (   parentAccountRecordTypeId.equals(newAccount.RecordTypeId)
                    && String.isNotBlank(newAccount.Business_Vertical__c)
                    && (oldMap == null || (newAccount.Business_Vertical__c != oldMap.get(newAccount.Id).Business_Vertical__c))
                    && BUSINESS_VERTICAL_MAP.containsKey(newAccount.Business_Vertical__c)
                    && MENU_UI_TYPE_RETAIL.equals(BUSINESS_VERTICAL_MAP.get(newAccount.Business_Vertical__c).Menu_UI_Type__c)
                ) {
                parentAccountIds.add(newAccount.Id);
            }
        }
        if (!parentAccountIds.isEmpty()){
            CDdMilestoneGeneratorSetting.createCaseMilestonesForMxAccounts(parentAccountIds);
            ranSetupCatalogMilestoneForBusinessVerticalRetail = true;
        }
    }
   /**
    * @author Sriram
    * @date 2021-10
    * @description BZAP-12136: Perform account reparent
    * @param List<Generic_Platform_Event__e> Collection of generic platform events
    * @return
    */
    public static void handleAccountReparent(List<Generic_Platform_Event__e> events){
        Set<Id> childAccountIds = new Set<Id>();
        for (Generic_Platform_Event__e event : events) {
            childAccountIds.add(event.sObjectId__c);
        }
        Map<Id, Account> childAccountsMap = new Map<Id, Account>();
        Map<Id, Account> newParentAccountsByChildAccountId = new Map<Id, Account>();
        Map<Decimal, Account> childAccountsByBusinessId = new Map<Decimal, Account>();
        Map<Decimal, Account> parentAccountsByBusinessId = new Map<Decimal, Account>();
        Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
        // Process accounts that
        // - have a non-null Business Id
        // - exclude records with Business Id as found in the Collection BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS
        //      accounts with any of this business id (see variable BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS)
        //      are not supposed to have a parent account
        for (Account a : [  SELECT Id, Account_Type__c, Business_ID__c, Deck_Rank__c, Name, OwnerId, RecordTypeId, ParentId
                            FROM Account
                            WHERE Id IN :childAccountIds]){
            if ((a.Business_ID__c != null)
                && (!BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS.contains(a.Business_ID__c.stripTrailingZeros()))
            ){
                childAccountsMap.put(a.Id, a);
                childAccountsByBusinessId.put(a.Business_ID__c.stripTrailingZeros(), a);
            }
        }
        for (Account a : [  SELECT Id, Account_Type__c, Business_ID__c, Deck_Rank__c, Name, OwnerId, RecordTypeId
                            FROM Account
                            WHERE RecordTypeId = :parentAccountRecordTypeId
                            AND Business_ID__c != null
                            AND Business_ID__c IN :childAccountsByBusinessId.keySet()]){
            parentAccountsByBusinessId.put(a.Business_ID__c.stripTrailingZeros(), a);
        }
        // Walk through the child account Collection (a collection with Business Id as the key)
        // Determine if each child account has a corresponding parent account
        // - Perform this by using the Business Id key to retrieve a parent account from the Parent Account Collection
        // If a corresponding parent account is found,
        // - populate the Parent Id reference on the Child Account with the Parent Account Identifier
        // If a corresponding parent account is not found
        // - populate the newParentAccountsByChildAccountId with a new Parent Account and use the child Account Id as the key
        //   within the Collection
        for (Decimal businessId : childAccountsByBusinessId.keySet()){
            Account childAccount = childAccountsByBusinessId.get(businessId);
            if (parentAccountsByBusinessId.containsKey(businessId)){
                childAccount.ParentId = parentAccountsByBusinessId.get(businessId).Id;
            } else {
                String childAccountName = childAccount.Name.substringBefore('(');
                String newParentAccountName = childAccountName
                +   (childAccountName.endsWith(' ') ? '' : ' ')
                + '[Parent-' + childAccount.Business_ID__c.stripTrailingZeros().toPlainString() + ']';
                newParentAccountsByChildAccountId.put(childAccount.Id,
                    new Account(
                        Name = newParentAccountName
                        , Account_Type__c = childAccount.Account_Type__c
                        , Business_ID__c = childAccount.Business_ID__c
                        , Deck_Rank__c = childAccount.Deck_Rank__c
                        , OwnerId = childAccount.OwnerId
                        , RecordTypeId = parentAccountRecordTypeId
                    )
                );
            }
        }
        try{
            // Create Parent Accounts, if Collection newParentAccountsByChildAccountId is not empty
            // Walk through newParentAccountsByChildAccountId Collection to put back the Parent Account Id reference on the Child Account
            // Note: Use the Child Account Id key to identify the corresponding Child Account in the newParentAccountsByChildAccountId Map Collection
            if (!newParentAccountsByChildAccountId.isEmpty()){
                insert newParentAccountsByChildAccountId.values();
                for (Id childAccountId : newParentAccountsByChildAccountId.keySet()){
                    Account childAccount = childAccountsMap.get(childAccountId);
                    childAccount.ParentId = newParentAccountsByChildAccountId.get(childAccountId).Id;
                }
            }
            update childAccountsMap.values();
        }catch(Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'Exception during handling the reparenting of the child accounts: ' + ex.getMessage()}, 'CDdAccountHelperMethods',
                                            'handleAccountReparent', LoggingLevel.ERROR);
            throw ex;
        }
    }

    /**
    * @author: Neha Arora
    * @description BASD-15028 Update Child Account Information to match Parent Account Information if the Child Account qualifies when new child account is created
    */
    public static void updateChildAcctsInformationAfterInsert(List<Account> newList){

        List<Copy_Parent_Account_Event__e> copyParentAccountEvents = new List<Copy_Parent_Account_Event__e>();
        Set<String> childRecordTypeDevNames = accountFieldCopyToAccountObj.targetRecordTypeDeveloperNames;
        Set<String> childRecordIds = new Set<String>();
        String childAccountRecordTypeId;
        for(String currRecDevName:childRecordTypeDevNames){
            childAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(currRecDevName).getRecordTypeId();
            childRecordIds.add(childAccountRecordTypeId);
        }
        for(Account currAcc :newList){
            if(currAcc.ParentId!=null && childRecordIds.contains(currAcc.RecordTypeId)){
                copyParentAccountEvents.add(new Copy_Parent_Account_Event__e(Parent_Account_Id__c = currAcc.ParentId));
            }
        }
        if (!copyParentAccountEvents.isEmpty()) {
            EventBus.publish(copyParentAccountEvents);
        }
    }

    /**
    * @author Nathalie Mendezona
    * @description Parses phone numbers and returns a string without spaces. This applies to non-US/Canada phone numbers
    */
    public static void updateInternationalPhoneNumbers(List<Account> newList, Map<Id, Account> oldMap) {
        Boolean isInsert = oldMap == null ? true : false;

        CDdI18nUtility.updateInternationalPhoneNumbers(newList, oldMap, 'Account', isInsert);
        for (Account newAccount : newList) {
            if (newAccount.Phone == null || oldMap != null && newAccount.Phone == oldMap.get(newAccount.Id).Phone) {
                continue;
            }
            if (!excludeCountryCodePhoneFormatting.contains(newAccount.BillingCountryCode) && !String.isBlank(newAccount.BillingCountryCode)) {
                if (!String.isEmpty(newAccount.Phone)) {
                    newAccount.Phone = newAccount.Phone.replace(' ', '');
                }
            }
        }
    }

    /*
    * @author abhi k
    * @date 2021-10
    * @description BZAP-12607:  if "Deck Rank" (Deck_Rank_c) is blank, default it to be the same value as "Launch Deck Rank" (Launch_Deck_Rank_c)
    * @param List<Account> Collection of account records
    * @return
    */
    public static void populateDeckRankIfBlank(List<Account> newList) {
        Set<String> validDeckRankValues = new Set<String> { 'Ace','King','Queen','Jack','Joker'};
        for(Account accountObj: newList) {
            Boolean isMarketplaceRT = accountObj.RecordTypeId == RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_MARKETPLACE).getRecordTypeId();
            Boolean isNZRecord = accountObj.BillingCountryCode == 'NZ';
            if(isMarketplaceRT && isNZRecord && String.isBlank(accountObj.Deck_Rank__c) && validDeckRankValues.contains(accountObj.Launch_Deck_Rank__c)) {
                accountObj.Deck_Rank__c = accountObj.Launch_Deck_Rank__c;
            }
        }
    }

    /**
    * @author Sanidhya Jain
    * @date 2021-11
    * @description BASD-15255: this method calls Queueable handleEnrichmentAccountJuctionCHDID on Account CHD ID Update
    * @param Map<Id,Account> Collection of new Account records
    * @param Map<Id,Account> Collection of old Account records
    * @return
    */
    public static void handleAccountChdId(Map<Id,Account> newMap, Map<Id, Account> oldMap) {
        Map<id,Account> updatedAccMap = new Map<id,Account>();

        for(Account accRec: newMap.values()){
            if(oldMap == null && String.isnotBlank(accRec.CHD_ID__c)){
                updatedAccMap.put(accRec.id, accRec);
            }
            else if(oldMap != null && oldMap.containsKey(accRec.Id) && oldMap.get(accRec.Id).CHD_ID__c <> accRec.CHD_ID__c){
                updatedAccMap.put(accRec.id, accRec);
            }
        }

        if(!updatedAccMap.values().isEmpty()){
            System.enqueueJob(new CDdEnrichmentQueueable(updatedAccMap,oldMap));
        }
    }

     /**
    * @author Veera Maddukuri
    * @description BZAP-12548 - To keep the Old street when smarty street tries to replace special characters
    */
    public static void handleSpecialCharsOnAddressChange(List<Account> newList, Map<Id, Account> oldMap){
        for(Account acc : newList){
            Boolean keepOldAddress = CDdI18nUtility.handleSpecialCharsOnLeadChange(acc.billingcountryCode, oldMap.get(acc.Id).BillingStreet, acc.BillingStreet);
            if(keepOldAddress){
                acc.BillingStreet = oldMap.get(acc.Id).BillingStreet;
            }
        }
    }

    /**
    * @description BZAP-13012 Changing PB to Trigger -- PostSale Account Owner Approval Process
    * @author Jose Vega | 01-12-2022
    * @param List<Account> newList
    * @param Map<Id Account> oldMap
    **/
    public static void handlePostSaleAccountOwnerApprovalProcess(List<Account> newList, Map<Id, Account> oldMap) {
        if (ranPostSaleAccountOwnerApprovalProcess) return;

        Id parentAccountRecordTypeId = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();
        for(Account acc : newList){
            if (oldMap != null){
                Account oldAccount = oldMap.get(acc.Id);
                if (parentAccountRecordTypeId.equals(acc.RecordTypeId) && !String.isBlank(acc.Requested_Account_Owner__c) && acc.Requested_Account_Owner__c != oldAccount.Requested_Account_Owner__c) {
                        Id accountOwnerId = acc.OwnerId;
                        if (accountOwnerId != SPM_HOLDING_USER && accountOwnerId != PM_HOLDING_USER && accountOwnerId != HOLDING_USER) {
                            acc.Requester__c = UserInfo.getUserId();
                            submitForApproval(acc, 'SPM_Account_Transfer_Approval_Process');
                        } else if (accountOwnerId == HOLDING_USER) {
                            acc.OwnerId = acc.Requested_Account_Owner__c;
                            acc.Requested_Account_Owner__c = null;
                            acc.Why_should_account_ownership_be_changed__c = null;
                        } else if (accountOwnerId == PM_HOLDING_USER) {
                            acc.Requester__c = UserInfo.getUserId();
                            submitForApproval(acc, 'Post_Post_Sale_PM_Holding_User');
                        } else if (accountOwnerId == SPM_HOLDING_USER) {
                            acc.Requester__c = UserInfo.getUserId();
                            submitForApproval(acc, 'Post_Post_Sale_SPM_Holding_User');
                        } else if ((acc.Owner.UserRoleId == SPM_ROLE && acc.Requested_Account_Owner__r.UserRoleId == PARTNER_MANAGER_ROLE) || (acc.Owner.UserRoleId == PARTNER_MANAGER_ROLE && acc.Requested_Account_Owner__r.UserRoleId == SPM_ROLE)) {
                            acc.Requester__c = UserInfo.getUserId();
                            submitForApproval(acc, 'Post_Post_Sale_SPM_to_PM_PM_to_SPM2');
                        }
               }
            }
        }
        ranPostSaleAccountOwnerApprovalProcess = true;
    }

    public static void submitForApproval(Account acc, String processDefinitionName ){
        // Create an approval request for  Account
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setSkipEntryCriteria(true);
        req.setSubmitterId(UserInfo.getUserId());
        req.setProcessDefinitionNameOrId(processDefinitionName);
        req.setObjectId(acc.id);
        // Submit the approval request for the Account
        Approval.ProcessResult result = Approval.process(req);
    }

    /**
    * @description BZAP-13012 Changing PB to Trigger -- PostSale Account Owner Approval Process- AccountOwnershipRejected Rejected(runs on both insert and update)
    * @author lathika | 02-4-2022
    * @param List<Account> newList
    * @param Map<Id Account> oldMap
    **/
    public static void handlePostSaleAccountOwnershipRejected(List<Account> newList, Map<Id, Account> oldMap) {
        if (ranPostSaleAccountOwnershipRejected) return;

        for(Account acc : newList){
           if (acc.Account_Ownership_Rejected__c){
                    // Update Owner
                    if(acc.Requested_Account_Owner__c != null){
                        acc.OwnerId = acc.Requested_Account_Owner__c;
                    }
                    // Updated Requested Fields
                    acc.Requested_Account_Owner__c = null;
                    acc.Requested_Account_Owner_Manager__c = null;
                    // Reset Fields
                    acc.Requester__c = null;
                    acc.Why_should_account_ownership_be_changed__c = null;
            }
        }
        ranPostSaleAccountOwnershipRejected = true;
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-20183, BASD-28825: Update Lead Created from Contact whenever State, PMC Fields values change
    * @param Map<Id, Account> new Account Map
    * @param Map<Id, Account> old Account Map
    */
    public static void updateLeadCreatedFromContact(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        Map<Id,Account> accMapWithPersonConAsKey = new Map<Id,Account>();
        Set<Id> updateAddressSet = new Set<Id>();
        Set<Id> updatePMCSet = new Set<Id>();
        List<Lead> leadList = new List<Lead>();

        for(Account currAcc : newMap.values()){
            Account oldAcc = (oldMap != null && oldMap.containsKey(currAcc.id)) ? oldMap.get(currAcc.id) : null;
            if(oldAcc != null && (currAcc.PersonMailingCity != oldAcc.PersonMailingCity ||
              currAcc.PersonMailingCountry != oldAcc.PersonMailingCountry ||
              currAcc.PersonMailingPostalCode != oldAcc.PersonMailingPostalCode ||
              currAcc.PersonMailingState != oldAcc.PersonMailingState ||
              currAcc.PersonMailingStreet != oldAcc.PersonMailingStreet) &&
              UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)){
                accMapWithPersonConAsKey.put(currAcc.PersonContactId,currAcc);
                updateAddressSet.add(currAcc.PersonContactId);
            }
            if(oldAcc != null && currAcc.Primary_Merchant_Category__pc != oldAcc.Primary_Merchant_Category__pc && UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)){
                accMapWithPersonConAsKey.put(currAcc.PersonContactId,currAcc);
                updatePMCSet.add(currAcc.PersonContactId);
            }
        }
        if(!accMapWithPersonConAsKey.isEmpty()){
            leadList = [Select id,State,City,Country,PostalCode,Street,Primary_Merchant_Category__c,Created_from_Contact__c From Lead Where Created_from_Contact__c =: accMapWithPersonConAsKey.keyset() AND Created_from_Contact__c != null];
        }
        for(Lead currLead : leadList){
            if(updateAddressSet.contains(currLead.Created_from_Contact__c) && UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)){
                currLead.City = accMapWithPersonConAsKey.get(currLead.Created_from_Contact__c).PersonMailingCity;
                currLead.Country = accMapWithPersonConAsKey.get(currLead.Created_from_Contact__c).PersonMailingCountry;
                currLead.PostalCode = accMapWithPersonConAsKey.get(currLead.Created_from_Contact__c).PersonMailingPostalCode;
                currLead.State = accMapWithPersonConAsKey.get(currLead.Created_from_Contact__c).PersonMailingState;
                currLead.Street = accMapWithPersonConAsKey.get(currLead.Created_from_Contact__c).PersonMailingStreet;
            }
            if(updatePMCSet.contains(currLead.Created_from_Contact__c) && UserInfo.getUserEmail().contains(hubspotIntegrationUserEmail)){
                currLead.Primary_Merchant_Category__c = accMapWithPersonConAsKey.get(currLead.Created_from_Contact__c).Primary_Merchant_Category__pc;
            }
        }

        if(leadList.size()>0){
            update leadList;
        }
    }


    /**
     * @author : Abhijeet K
     * @description BZAP-12749 - Set Account Default Values
     */
    public static void setDefaultValuesByCountry(List<Account> newAccounts) {
        CDdI18nDefaultValueMappingUtil.setDefaultValuesBasedOnCountry(newAccounts);
    }

     /**
   * @author Lathika
   * @date 2022-01
   * @description BZAP - 13012 Account Feature Flag
   * @param String
   * @return Boolean Value of the checkbox
   */
  public static Boolean getAccountFeatureFlag(String flagName){
    Account_Feature_Flag__c accFeatureSetting = Account_Feature_Flag__c.getInstance();
        if (accFeatureSetting != null){
            return (Boolean) accFeatureSetting.get(flagName) != null ? (Boolean) accFeatureSetting.get(flagName) : false;
        } else {
            return false;
        }
    }

    /**
     * @author : Abhijeet K
     * @description BZAP-13592 : SSMO: Phone number format update
     */
    public static void formatPhoneNumber(List<Account> newAccounts) {
        if(CDdUtilities.isCurrentUserAnIntegrationUser(CDdCoreConstants.INTEGRATION_USER_TYPE_MULESOFT)) {
            for(Account accObj: newAccounts) {
                if(CDdI18nUtility.isCountryJAPAN(accObj.BillingCountry)) {
                    accObj.Phone = CDdI18nUtility.formatJPPhoneNumber(accObj.Phone);
                }
            }
        }
    }

    /**
     * @author Swedhaa Sri M
     * @date 05/2022
     * @description: BASD-29431 Update Merchant Categories based on Primary Merchant Category on Account
     */
    public static void updateHubspotMerchantCategories(List<Account> newList, Map<Id, Account> oldMap) {
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Account.sObjectType);
        vertCatHelper.updateHubspotMerchantCategories(newList, oldMap);
    }

    /**
     * @author Ila Maheshwari
     * @date 10/2022
     * @description: BASD-29430 Keep Primary_Merchant_Categories__c and Primary_Merchant_Category__c field value in sync
     */
    public static void syncPrimaryMerchantCategoryFields(List<Account> newList, Map<Id, Account> oldMap) {
		CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Account.sObjectType);
        vertCatHelper.syncPrimaryMerchantCategoryFields(newList, oldMap);
    }
    /**
     * @author Nishant Sharda
     * @date 04/2023
     * @description: LEM-5360 Create an UUID value in the Mulesoft External Id field when Lemonade Record
     * id gets populated
     * @param newAccts
     */
    public static void updateMuelsoftExtId(List<Account> newAccts){
        for(Account acc : newAccts){
            if(string.isNotBlank(acc.Lemonade_Record_ID__c) && string.isBlank(acc.Mulesoft_External_Id__c)){
                acc.Mulesoft_External_Id__c = generateUUIDUtil.NewGuid();
            }

        }
    }


}