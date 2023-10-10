/**
 * @author      Raju Lakshman
 * @date        Nov 2021
 * @decription  BIZS-666 - Case Trigger Optimization -
 *
 *              This class allows for 3 things to optimize the case trigger
 *              1. Query and store in static variables - Account, Contact, Opportunity, User And Queue records related to the case
 *                  > Opportunity - map by id
 *                  > Account - map by id
 *                  > User - map by id
 *                  > Contact - map by id and email
 *              2. Data structure to do single DML for each object from the case trigger...
 *                 The Data structure stores the data of opportunity/account etc which need to be updated across various case trigger methods and does the DML at the end of after insert/after update
 *              3. Storing Record Type Ids Map by Name and Developer name in static variables for performance.
 *
 */

public without sharing class CDdCaseTriggerOptimizationHelper {

    private static Map<String,List<String>> relatedObjectFieldsMap = null;
    public static Map<String,List<String>> getRelatedObjectFieldsMap() {
        if (relatedObjectFieldsMap != null) {
            return relatedObjectFieldsMap;
        }
        relatedObjectFieldsMap = CDdIssueBasedRoutingHelper.getRelatedObjectFieldsMap('Case');
        Map<String,List<String>> fieldsFromShield = CDdCaseTransferValidationHelper.getRelatedObjectFieldsMap();
        Map<String,List<String>> fieldsFromProjecHorizon = CDdWorkflowConfigEvaluator.getRelatedObjectFieldsMap('Case');
        mergeRelatedObjectFieldsMap(relatedObjectFieldsMap,fieldsFromShield);
        Map<String,List<String>> fieldsFromProactiveCaseConfig = CDdProactiveCaseCreationHelper.getRelatedObjectFieldsMap();
        mergeRelatedObjectFieldsMap(relatedObjectFieldsMap,fieldsFromProactiveCaseConfig);
        mergeRelatedObjectFieldsMap(relatedObjectFieldsMap,fieldsFromProjecHorizon);
        return relatedObjectFieldsMap;
    }

    private static void mergeRelatedObjectFieldsMap(Map<String,List<String>> mergeInto,Map<String,List<String>> toMerge) {
        for (String objectName : toMerge.keySet()) {
            Set<String> fieldsToAdd = new Set<String>(toMerge.get(objectName));
            if (mergeInto.containsKey(objectName)) {
                fieldsToAdd.addAll(mergeInto.get(objectName));
            }
            mergeInto.put(objectName,new List<String>(fieldsToAdd));
        }
    }

    public static final List<String> caseFields = new List<String> {
        'Id',
        'ContactId',
        'AccountId',
        'Opportunity_Name__c',
        'OwnerId',
        'RecordTypeId',
        'RecordType.Name',
        'Requester__c'
    };

    public static final List<String> caseFeedFields = new List<String> {
        'Id',
        'ParentId',
        'CreatedById',
        'CreatedBy.UserRoleId',
        'CreatedBy.UserRole.Name',
        'CreatedBy.ProfileId',
        'CreatedBy.Profile.Name',
        'Body'
    };


    private static List<String> accountFields = null;
    public static List<String> getAccountFields() {
        if (accountFields != null) {
           return accountFields;
        }
        Set<String> accFields = new Set<String> {
            'id',
            'address2__c',
            'billingstreet',
            'billingcity',
            'billingstate',
            'billingpostalcode',
            'billingcountrycode',
            'billingcountry',
            'billingstatecode',
            'business_vertical__c',
            'business_vertical__r.menu_ui_type__c',
            'case_routing_override__c',
            'createddate',
            'decision_maker__c',
            'decision_maker_email__c',
            'deck_rank__c',
            'ispersonaccount',
            'kanji_street__c',
            'kanji_city__c',
            'kanji_state__c',
            'kanji_country__c',
            'kanji_zip__c',
            'kanji_address2__c',
            'legal_business_name__c',
            'language__c',
            'lastmodifieddate',
            'local_premium__c',
            'name',
            'notes__c',
            'parentid',
            'parent.recordtypeid',
            'parent.deck_rank__c',
            'personcontactid',
            'photoshootcasecreated__c',
            'primary_merchant_category__c',
            'realzip__realzip__c',
            'realzip__realzip__r.submarket_lookup__c',
            'realzip__realzip__r.submarket_lookup__r.region__c',
            'recordtypeid',
            'restaurant_id__c',
            'support_priority_rank__c',
            'realzip__realzip__r.submarket_lookup__r.photoshoot_vendor__c',
            'realzip__realzip__r.realzip__state__c',
            'inbound_count__c'
        };
        List<String> accFieldsFromFrameworks = getRelatedObjectFieldsMap().get('Account');
        if (accFieldsFromFrameworks != null) {
            accFields.addAll(accFieldsFromFrameworks);
        }
        accountFields = new List<String>(accFields);
        return accountFields;
    }

    private static List<String> opportunityFields = null;
    public static List<String> getOpportunityFields() {
        if (opportunityFields != null) {
           return opportunityFields;
        }
        Set<String> oppFields = new Set<String> {
            'id',
            'ac_pb_change__c',
            'accountid',
            'activation_date__c',
            'createddate',
            'decision_maker__c',
            'lastmodifieddate',
            'mx_requesting_photoshoot__c',
            'name',
            'notes_for_menu_team__c',
            'photoshoot_date__c',
            'photoshoot_time__c',
            'platform__c',
            'preferred_language__c',
            'recordtypeid',
            'rescue_status__c',
            'send_marketing_kit__c',
            'stagename',
            'tablet_delivered__c',
            'tablet_received_date__c',
            'trial_adjusted_date__c',
            'type',
            'ownerid',
            'DRN__c'
        };
        List<String> oppFieldsFromFrameworks = getRelatedObjectFieldsMap().get('Opportunity');
        if (oppFieldsFromFrameworks != null) {
            oppFields.addAll(oppFieldsFromFrameworks);
        }
        opportunityFields = new List<String>(oppFields);
        return opportunityFields;
    }

    private static List<String> contactFields = null;
    public static List<String> getContactFields() {
        if (contactFields != null) {
           return contactFields;
        }
        Set<String> conFields = new Set<String> {
            'id',
            'accountid',
            'account.ispersonaccount',
            'customerno__c',
            'createddate',
            'dasherno__c',
            'email',
            'firstname',
            'ispersonaccount',
            'lastmodifieddate',
            'lastname',
            'name',
            'phone'
        };
        List<String> conFieldsFromFrameworks = getRelatedObjectFieldsMap().get('Contact');
        if (conFieldsFromFrameworks != null) {
            conFields.addAll(conFieldsFromFrameworks);
        }
        contactFields = new List<String>(conFields);
        return contactFields;
    }

    private static List<String> userFields = null;
    public static List<String> getUserFields() {
        if (userFields != null) {
           return userFields;
        }
        Set<String> usrFields = new Set<String> {
            'id',
            'companyname',
            'email',
            'firstname',
            'lastname',
            'name',
            'profileid',
            'profile.name',
            'userroleid',
            'userrole.name'
        };
        List<String> userFieldsFromFrameworks = getRelatedObjectFieldsMap().get('User');
        if (userFieldsFromFrameworks != null) {
            usrFields.addAll(userFieldsFromFrameworks);
        }
        userFields = new List<String>(usrFields);
        return userFields;
    }

    //Setting Case Detail field set
    private static List<String> caseDetailFields = null;
    public static List<String> getCaseDetailFields() {
        if (caseDetailFields != null) {
           return caseDetailFields;
        }
        Set<String> cdFields = new Set<String> {
            'id',
            'Primary_Incident_Type__c',
            'Secondary_Incident_Type__c',
            'Reporter__c',
            'Incident_History__c',
            'Actions_Taken__c',
            'Transfered_De_Escalated__c',
            'Destination__c',
            'Account_Sharing_Not_My_Dasher__c',
            'Case_Owner_ID__c',
            'Case__c'
        };
        List<String> caseDetailFieldsFromFrameworks = getRelatedObjectFieldsMap().get('Case_Detail__c');
        if (caseDetailFieldsFromFrameworks != null) {
            cdFields.addAll(caseDetailFieldsFromFrameworks);
        }
        caseDetailFields = new List<String>(cdFields);
        return caseDetailFields;
    }

    private static Map<String,String> fieldsCache = new Map<String,String>();
    public static String getFields(String objectName, String prefix) {
        String cacheKey = objectName + (String.isBlank(prefix) ? CDdCoreConstants.BLANK_STRING : CDdCoreConstants.DELIMITER_HYPHEN + prefix);
        if (fieldsCache.containsKey(cacheKey)) {
            return fieldsCache.get(cacheKey);
        }
        List<String> fieldNames;
        switch on objectName {
            when 'Case' {
                fieldNames = caseFields;
            }
            when 'Opportunity' {
                fieldNames = getOpportunityFields();
            }
            when 'Account' {
                fieldNames = getAccountFields();
            }
            when 'Contact' {
                fieldNames = getContactFields();
            }
            when 'User' {
                fieldNames = getUserFields();
            }
            when 'CaseFeed' {
                fieldNames = caseFeedFields;
            }
            when 'Case_Detail__c' {
                fieldNames = getCaseDetailFields();
            }
        }
        if (fieldNames == null) {
            return CDdCoreConstants.BLANK_STRING;
        }
        String retVal = CDdCoreConstants.BLANK_STRING;
        if (String.isBlank(prefix)) {
            prefix = CDdCoreConstants.BLANK_STRING;
        } else {
            prefix = prefix.endsWith(CDdCoreConstants.DELIMITER_DOT) ? prefix : prefix + CDdCoreConstants.DELIMITER_DOT;
        }
        for (String field : fieldNames) {
            retVal += prefix + field + CDdCoreConstants.DELIMITER_COMMA;
        }
        retVal = retVal.removeEnd(CDdCoreConstants.DELIMITER_COMMA);
        fieldsCache.put(cacheKey,retVal);
        return retVal;
    }

    /********************** CASE ADDITIONAL RELATIONSHIPS QUERY OPTIMIZATION **********************/
    private static Map<Id,Case> caseMap = new Map<Id,Case>();
    /**
     * @description  Getter for the case map in memory
     * @param   None
     * @return  Map<Id, Case>
     */
    public static Map<Id, Case> getCaseMap() {
        return caseMap;
    }
    /**
     * @description  Get the case base query of all the fields needed from an Case; if using outside the this class, use in conjuction with addToCaseMap
     * @param   None
     * @return  String
     */
    private static String caseBaseQuery = null;
    public static String getCaseBaseQuery() {
        if (caseBaseQuery == null) {
            caseBaseQuery = 'SELECT ' +
                getFields('Case', null) + CDdCoreConstants.DELIMITER_COMMA +
                getFields('Account', 'Account') + CDdCoreConstants.DELIMITER_COMMA +
                getFields('Contact', 'Contact') + CDdCoreConstants.DELIMITER_COMMA +
                getFields('Opportunity', 'Opportunity_Name__r') + CDdCoreConstants.DELIMITER_COMMA +
                ' TYPEOF Owner WHEN User THEN ' + getFields('User', null ) + ' END ' + CDdCoreConstants.DELIMITER_COMMA +
                getFields('User', 'Requester__r') +
                ' FROM Case ';
        }
        return caseBaseQuery;
    }
    /**
     * @description  Setter for the opportunity map in memory
     * @param   Set<Id> ids - Id of case to query
     * @return  None
     */
    public static void setCaseMap(Set<Id> ids) {
        if (ids.isEmpty()) {
            return;
        }
        List<Case> cases = Database.query(getCaseBaseQuery() + ' WHERE Id IN :ids');
        caseMap.putAll(new Map<Id, Case>(cases));
        Map<Id,Opportunity> linkedOppties = new Map<Id,Opportunity>();
        Map<Id,Account> linkedAccounts = new Map<Id,Account>();
        Map<Id,Contact> linkedContacts = new Map<Id,Contact>();
        Map<Id,User> linkedUsers = new Map<Id,User>();
        for (Case c : cases) {
            if (c.Opportunity_Name__c != null) {
                linkedOppties.put(c.Opportunity_Name__c,c.Opportunity_Name__r);
            }
            if (c.AccountId != null) {
                linkedAccounts.put(c.AccountId,c.Account);
            }
            if (c.ContactId != null) {
                linkedContacts.put(c.ContactId,c.Contact);
            }
            if (c.OwnerId != null && String.valueOf(c.OwnerId).startsWith('005')) {
                User u = (User)c.Owner;
                linkedUsers.put(c.OwnerId,u);
            }
            if (c.Requester__c != null) {
                linkedUsers.put(c.Requester__c,c.Requester__r);
            }
        }
        if (!linkedOppties.isEmpty()) {
            addToOpportunityMap(linkedOppties.values());
        }
        if (!linkedAccounts.isEmpty()) {
            addToAccountMap(linkedAccounts.values());
        }
        if (!linkedContacts.isEmpty()) {
            addToContactMap(linkedContacts.values());
        }
        if (!linkedUsers.isEmpty()) {
            addToUserMap(linkedUsers.values());
        }
    }
    /**
     * @description  Add Case queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getCaseBaseQuery() to add the fields needed across the transaction
     * @param   List<Case> opptys - Case to add to the static map
     * @return  None
     */
    public static void addToCaseMap(List<Case> cases) {
        if (!cases.isEmpty()) {
            caseMap.putAll(new Map<Id, Case>(cases));
        }
    }
    /**
     * @description  Refreshes the static variable caseMap
     * @param   None
     * @return  None
     */
    public static void refreshCaseMap() {
        Set<Id> caseIds = caseMap.keySet();
        if (caseIds.isEmpty()) {
            return;
        }
        caseMap = new Map<Id, Case>((List<Case>)Database.query(getCaseBaseQuery() + ' WHERE Id IN :caseIds'));
    }

    /********************** OPPORTUNITY QUERY OPTIMIZATION **********************/
    // Static map which will allow any method in the case trigger access to the opportunity record associate to the case
    private static Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    /**
     * @description  Getter for the opportunity map in memory
     * @param   None
     * @return  Map<Id, Opportunity>
     */
    public static Map<Id, Opportunity> getOpportunityMap() {
        return oppMap;
    }
    /**
     * @description  Get the base query of all the fields needed from an Opportunity; if using outside the this class, use in conjuction with addToOpportunityMap
     * @param   None
     * @return  String
     */
    private static String opportunityBaseQuery = null;
    public static String getOpportunityBaseQuery() {
        if (opportunityBaseQuery == null) {
            opportunityBaseQuery = 'SELECT ' + getFields('Opportunity', null) + ' FROM Opportunity ';
        }
        return opportunityBaseQuery;
    }
    /**
     * @description  Setter for the opportunity map in memory
     * @param   Set<Id> ids - Id of opportunities to query
     * @return  None
     */
    public static void setOpportunityMap(Set<Id> ids) {
        // Query only whats needed... if already queried previously, then no need to query again.
        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(oppMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        oppMap.putAll(new Map<Id, Opportunity>((List<Opportunity>)Database.query(getOpportunityBaseQuery() + ' WHERE Id IN :idsToQuery')));
    }
    /**
     * @description  Add opportunities queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getOpportunityBaseQuery() to add the fields needed across the transaction
     * @param   List<Opportunity> opptys - Opportunities to add to the static map
     * @return  None
     */
    public static void addToOpportunityMap(List<Opportunity> opptys) {
        if (!opptys.isEmpty()) {
            oppMap.putAll(new Map<Id, Opportunity>(opptys));
        }
    }
    /**
     * @description  Refreshes the static variable oppMap
     * @param   None
     * @return  None
     */
    public static void refreshOpportunityMap() {
        Set<Id> opptyIds = oppMap.keySet();
        if (opptyIds.isEmpty()) {
            return;
        }
        oppMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(getOpportunityBaseQuery() + ' WHERE Id IN :opptyIds'));
    }

    /********************** ACCOUNT QUERY OPTIMIZATION **********************/
    // Static map which will allow any method in the case trigger access to the account record associate to the case
    private static Map<Id, Account> accMap = new Map<Id, Account>();
    /**
     * @description  Getter for the Account map in memory
     * @param   None
     * @return  Map<Id, Account>
     */
    public static Map<Id, Account> getAccountMap() {
        return accMap;
    }
    /**
     * @description  Get the base query of all the fields needed from an Account; if using outside the this class, use in conjuction with addToAccountMap
     * @param   None
     * @return  String
     */
    private static String accountBaseQuery = null;
    public static String getAccountBaseQuery() {
        if (accountBaseQuery == null) {
            accountBaseQuery = 'SELECT ' + getFields('Account', null) + ' FROM Account ';
        }
        return accountBaseQuery;
    }
    /**
     * @description  Setter for the Account map in memory
     * @param   Set<Id> ids - Id of account to query
     * @return  None
     */
    public static void setAccountMap(Set<Id> ids) {
        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(accMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        accMap.putAll(new Map<Id, Account>((List<Account>)Database.query(getAccountBaseQuery() + ' WHERE Id IN :idsToQuery')));
    }
    /**
     * @description  Add accounts queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getAccountBaseQuery() to add the fields needed across the transaction
     * @param   List<Account> - accounts to add to the static map
     * @return  None
     */
    public static void addToAccountMap(List<Account> accounts) {
        if (!accounts.isEmpty()) {
            accMap.putAll(new Map<Id, Account>(accounts));
        }
    }
    /**
     * @description  Refreshes the static variable accMap
     * @param   None
     * @return  None
     */
    public static void refreshAccountMap() {
        Set<Id> accountIds = accMap.keySet();
        if (accountIds.isEmpty()) {
            return;
        }
        accMap = new Map<Id, Account>((List<Account>)Database.query(getAccountBaseQuery() + ' WHERE Id IN :accountIds'));
    }

    /********************** User QUERY OPTIMIZATION **********************/
    // Static map which will allow any method in the case trigger access to the user record associate to the case
    private static Map<Id, User> userMap = new Map<Id, User>();
    /**
     * @description  Getter for the User map in memory
     * @param   None
     * @return  Map<Id, User>
     */
    public static Map<Id, User> getUserMap() {
        return userMap;
    }
    /**
     * @description  Get the base query of all the fields needed from an User; if using outside the this class, use in conjuction with addToUserMap
     * @param   None
     * @return  String
     */
    private static String userBaseQuery = null;
    public static String getUserBaseQuery() {
        if (userBaseQuery == null) {
            userBaseQuery = 'SELECT ' + getFields('User', null) + ' FROM User ';
        }
        return userBaseQuery;
    }
    /**
     * @description  Setter for the User map in memory
     * @param   Set<Id> ids - Id of users to query
     * @return  None
     */
    public static void setUserMap(Set<Id> ids) {
        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(userMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        userMap.putAll(new Map<Id, User>((List<User>)Database.query(getUserBaseQuery() + ' WHERE Id IN :idsToQuery')));
    }
    /**
     * @description  Add users queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getUserBaseQuery() to add the fields needed across the transaction
     * @param   List<User> - users to add to the static map
     * @return  None
     */
    public static void addToUserMap(List<User> users) {
        if (!users.isEmpty()) {
            userMap.putAll(new Map<Id, User>(users));
        }
    }
    /**
     * @description  Refreshes the static variable userMap
     * @param   None
     * @return  None
     */
    public static void refreshUserMap() {
        Set<Id> userIds = userMap.keySet();
        if (userIds.isEmpty()) {
            return;
        }
        userMap = new Map<Id, User>((List<User>)Database.query(getUserBaseQuery() + ' WHERE Id IN :userIds'));
    }

    /********************** CONTACT QUERY OPTIMIZATION **********************/
    // Static map which will allow any method in the case trigger access to the contact record associate to the case by Id
    private static Map<Id, Contact> contactMap = new Map<Id, Contact>();
    // Static map which will allow any method in the case trigger access to the contact record associate to the case by Email
    private static Map<String, List<Contact>> contactEmailMap = new Map<String, List<Contact>>();
    /**
     * @description  Getter for the Contact By Id map in memory
     * @param   None
     * @return  Map<Id, User>
     */
    public static Map<Id, Contact> getContactByIdMap() {
        return contactMap;
    }
    /**
     * @description  Getter for the Contact by Email map in memory - Note that an email is not unique, hence you get a list of contacts for that email
     * @param   None
     * @return  Map<String, List<Contact>>
     */
    public static Map<String, List<Contact>> getContactByEmailMap() {
        return contactEmailMap;
    }
    /**
     * @description  Get the base query of all the fields needed from an Contact; if using outside the this class, use in conjuction with addToContactMap
     * @param   None
     * @return  String
     */
    private static String contactBaseQuery = null;
    public static String getContactBaseQuery() {
        if (contactBaseQuery == null) {
            contactBaseQuery = 'SELECT ' + getFields('Contact', null) + ' FROM Contact ';
        }
        return contactBaseQuery;
    }
    /**
     * @description  Setter for the Contact maps (both id and email) in memory
     * @param   Set<Id> ids - Id of contacts to query
     * @return  None
     */
    public static void setContactMap(Set<Id> ids) {
        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(contactMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        List<Contact> contacts = Database.query(getContactBaseQuery() + ' WHERE Id IN :idsToQuery ORDER BY LastModifiedDate DESC');
        for (Contact c : contacts) {
            if (String.isNotBlank(c.Email)) {
                // NOTE - email is forced lowercase to maintain proper keys in map
                if (!contactEmailMap.containsKey(c.Email.toLowerCase())) {
                    contactEmailMap.put(c.Email.toLowerCase(),new List<Contact>());
                }
                contactEmailMap.get(c.Email.toLowerCase()).add(c);
            }
            contactMap.put(c.Id,c);
        }
    }
    /**
     * @description  Setter for the Contact maps (both id and email) in memory
     * @param   List<String> emails - Emails of contacts to query
     * @return  None
     */
    public static void setContactMap(List<String> emails) {
        Support_Feature_Flag__c supportFeaFlag = Support_Feature_Flag__c.getInstance();
        List<String> apexLogging = new List<String>();
        // NOTE - email is forced lowercase to maintain proper keys in map
        try{
            if(supportFeaFlag.Disable_Apex_log_SetContactMap__c){
                apexLogging.add('Count of Row Retrived Through Query before setContactMap method run : ' + Integer.valueOf(Limits.getQueryRows()));
            }
            Set<String> emailsToQuery = new Set<String>();
            for (String email : emails) {
                if (!contactEmailMap.containsKey(email.toLowerCase())) {
                    emailsToQuery.add(email.toLowerCase());
                }
            }
            if (emailsToQuery.isEmpty()) {
                return;
            }
            List<Contact> contacts = Database.query(getContactBaseQuery() + ' WHERE Email IN :emailsToQuery ORDER BY LastModifiedDate DESC');
            for (Contact c : contacts) {
                if (String.isNotBlank(c.Email)) {
                    // NOTE - email is forced lowercase to maintain proper keys in map
                    if (!contactEmailMap.containsKey(c.Email.toLowerCase())) {
                        contactEmailMap.put(c.Email.toLowerCase(),new List<Contact>());
                    }
                    contactEmailMap.get(c.Email.toLowerCase()).add(c);
                }
                contactMap.put(c.Id,c);
            }
        }
        catch(Exception ex){
            apexLogging.add(ex.getMessage());
        }
        if(!apexLogging.isEmpty()){
            CDdErrorUtilities.createApexLogs(apexLogging,'CDdCaseTriggerOptimizationHelper','setContactMap',LoggingLevel.ERROR);
        }
    }
    /**
     * @description  Add contacts queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getContactBaseQuery() to add the fields needed across the transaction
     * @param   List<Contact> - contacts to add to the static map
     * @return  None
     */
    public static void addToContactMap(List<Contact> contacts) {
        for (Contact c : contacts) {
            if (String.isNotBlank(c.Email)) {
                // NOTE - email is forced lowercase to maintain proper keys in map
                if (!contactEmailMap.containsKey(c.Email.toLowerCase())) {
                    contactEmailMap.put(c.Email.toLowerCase(),new List<Contact>());
                }
                List<Contact> cachedContacts = contactEmailMap.get(c.Email.toLowerCase());
                Boolean isPresent = false;
                for (Contact cachedContact : cachedContacts) {
                    if (cachedContact.Id == c.Id) {
                        isPresent = true;
                        break;
                    }
                }
                if (!isPresent) {
                    cachedContacts.add(c);
                }
            }
            contactMap.put(c.Id,c);
        }
    }
    /**
     * @description  Refreshes the static variable contactMap and contactEmailMap
     * @param   None
     * @return  None
     */
    public static void refreshContactMap() {
        contactMap = new Map<Id,Contact>();
        contactEmailMap = new Map<String,List<Contact>>();
        Set<Id> contactIds = contactMap.keySet();
        if (contactIds.isEmpty()) {
            return;
        }
        List<Contact> contacts = Database.query(getContactBaseQuery() + ' WHERE Id IN :contactIds ORDER BY LastModifiedDate DESC');
        for (Contact c : contacts) {
            if (String.isNotBlank(c.Email)) {
                // NOTE - email is forced lowercase to maintain proper keys in map
                if (!contactEmailMap.containsKey(c.Email.toLowerCase())) {
                    contactEmailMap.put(c.Email.toLowerCase(),new List<Contact>());
                }
                contactEmailMap.get(c.Email.toLowerCase()).add(c);
            }
            contactMap.put(c.Id,c);
        }
    }

    /**
     * @description  Gives you last (i.e. most recent) contact by any datetime field (like CreatedDate, LastModifiedDate)
     * @param   List<Contact> contacts
     *          String fieldToCheck - DateTime field to check...
     * @return  Contact - Last contact as checked by the date
     */
    public static Contact getLastContactByDate(List<Contact> contacts, String fieldToCheck) {
        if (contacts.isEmpty()) {
            return null;
        }
        Contact retVal = null;
        for (Contact c : contacts) {
            if (retVal == null || ((DateTime)retVal.get(fieldToCheck)) < ((DateTime)c.get(fieldToCheck))) {
                retVal = c;
            }
        }
        return retVal;
    }


    /********************** Case Notes Optimization **********************/
    // Static map which will allow any method in the case trigger access to the Case notes records associated to the case
    private static Map<Id, List<CaseFeed>> caseFeedMap = new Map<Id, List<CaseFeed>>();
    /**
     * @description  Getter for the CaseFeed map in memory
     * @param   None
     * @return  Map<Id, List<CaseFeed>>
     */
    public static Map<Id, List<CaseFeed>> getCaseFeedMap() {
        return caseFeedMap;
    }

    /**
     * @description  get the case feed records related to the case
     * @param   caseId {Id}
     * @return List<CaseFeed>
     */
    public static List<CaseFeed> getCaseFeeds(Id caseId) {
        return caseFeedMap.get(caseId);
    }
    /**
     * @description  Get the base query of all the fields needed from an CaseFeed; if using outside the this class, use in conjuction with addToCaseFeedMap
     * @param   None
     * @return  String
     */
    private static String caseFeedBaseQuery = null;
    public static String getCaseFeedBaseQuery() {
        if (caseFeedBaseQuery == null) {
            caseFeedBaseQuery = 'SELECT ' + getFields('CaseFeed', null) + ' FROM CaseFeed WHERE Type = \'' + CDdSupportConstants.CASEFEED_TYPE_TEXTPOST + '\' ';
        }
        return caseFeedBaseQuery;
    }
    /**
     * @description  Setter for the CaseFeed map in memory
     * @param   Set<Id> ids - Id of cases whose case feeds to query
     * @return  None
     */
    public static void setCaseFeedMap(Set<Id> caseIds) {
        Set<Id> idsToQuery = caseIds.clone();
        idsToQuery.removeAll(caseFeedMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        caseFeedMap.putAll(convertCaseFeedListToMap((List<CaseFeed>)Database.query(getCaseFeedBaseQuery() + ' AND ParentId IN :idsToQuery ORDER BY CreatedDate Desc')));
    }

    /**
     * @description  Add Case Feeds queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getCaseFeedBaseQuery() to add the fields needed across the
     *               Ensure you order by CreatedDate desc
     * @param   List<CaseFeed> - CaseFeed Records to add to the static map
     * @return  None
     */
    public static void addToCaseFeedMap(List<CaseFeed> caseFeedList) {
        if (!caseFeedList.isEmpty()) {
            caseFeedMap.putAll(convertCaseFeedListToMap(caseFeedList));
        }
    }

    /**
     * @description  Convert a CaseFeed List to a Map where key is the parent Case id
     * @param   List<CaseFeed> - list to convert to map
     * @return  Map<Id,List<CaseFeed>> - map where key is the Parent Case id
     */
    private static Map<Id,List<CaseFeed>> convertCaseFeedListToMap(List<CaseFeed> caseFeedList) {
        Map<Id,List<CaseFeed>> retVal = new Map<Id,List<CaseFeed>>();
        for (CaseFeed cf : caseFeedList) {
            if (!retVal.containsKey(cf.ParentId)) {
                retVal.put(cf.ParentId, new List<CaseFeed>());
            }
            retVal.get(cf.ParentId).add(cf);
        }
        return retVal;
    }

    /**
     * @description  Refreshes the static variable caseFeedMap
     * @param   None
     * @return  None
     */
    public static void refreshCaseFeedMap() {
        Set<Id> caseIds = caseFeedMap.keySet();
        if (caseIds.isEmpty()) {
            return;
        }
        caseFeedMap = convertCaseFeedListToMap((List<CaseFeed>)Database.query(getCaseFeedBaseQuery() + ' AND ParentId IN :caseIds ORDER BY CreatedDate Desc'));
    }

    /********************** AC Contact Trace **********************/
    // Not a generic case optimization scenario, but used for Project Shield
    private static Map<Id, Set<String>> acContactTraceTransferMap = new Map<Id, Set<String>>();
    /**
     * @description  Getter for the AC Contact Trace Transfer queues map in memory
     * @param   None
     * @return  Map<Id, Set<String>>
     */
    public static Map<Id, Set<String>> getAcContactTraceTransferMap() {
        return acContactTraceTransferMap;
    }

    /**
     * @description  get the AC Contact Trace Transfer queues related to the case
     * @param   caseId {Id}
     * @return Set<String>
     */
    public static Set<String> getAcContactTraceTransfers(Id caseId) {
        return acContactTraceTransferMap.get(caseId);
    }
    /**
     * @description  Query for AC Contact Trace Records Transfer queues
     * @param   None
     * @return  String
     */
    private static String acContactTraceTransferBaseQuery = null;
    public static String getAcContactTraceTransferBaseQuery() {
        if (acContactTraceTransferBaseQuery == null) {
            acContactTraceTransferBaseQuery = 'SELECT Case__c,amazonconnect__QueueName__c FROM amazonconnect__AC_ContactTraceRecord__c ' +
                ' WHERE amazonconnect__Initiation_Method__c = \'TRANSFER\' AND amazonconnect__QueueName__c != null ';
        }
        return acContactTraceTransferBaseQuery;
    }
    /**
     * @description  Setter for the AC Contact Trace Transfer queue map in memory
     * @param   Set<Id> ids - Id of cases whose amazonconnect__AC_ContactTraceRecord__c to query
     * @return  None
     */
    public static void setAcContactTraceTransferMap(Set<Id> caseIds) {
        Set<Id> idsToQuery = caseIds.clone();
        idsToQuery.removeAll(acContactTraceTransferMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        acContactTraceTransferMap.putAll(convertAcContactTraceListToMap((List<amazonconnect__AC_ContactTraceRecord__c>)Database.query(getAcContactTraceTransferBaseQuery() + ' AND Case__c IN :idsToQuery')));
    }

    /**
     * @description  Add Case Feeds queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getCaseFeedBaseQuery() to add the fields needed across the transaction
     * @param   List<CaseFeed> - CaseFeed Records to add to the static map
     * @return  None
     */
    public static void addToAcContactTraceTransferMap(List<amazonconnect__AC_ContactTraceRecord__c> acContactTraceList) {
        if (!acContactTraceList.isEmpty()) {
            acContactTraceTransferMap.putAll(convertAcContactTraceListToMap(acContactTraceList));
        }
    }

    /**
     * @description  Convert a amazonconnect__AC_ContactTraceRecord__c List to a Map where key is the parent Case id
     * @param   List<CaseFeed> - list to convert to map
     * @return  Map<Id,Set<String>> - map where key is the Parent Case id and value is the list of transfer queues
     */
    private static Map<Id,Set<String>> convertAcContactTraceListToMap(List<amazonconnect__AC_ContactTraceRecord__c> acContactTraceList) {
        Map<Id,Set<String>> retVal = new Map<Id,Set<String>>();
        for (amazonconnect__AC_ContactTraceRecord__c rec : acContactTraceList) {
            if (rec.Case__c == null || String.isBlank(rec.amazonconnect__QueueName__c)) {
                continue;
            }
            if (!retVal.containsKey(rec.Case__c)) {
                retVal.put(rec.Case__c, new Set<String>());
            }
            retVal.get(rec.Case__c).add(rec.amazonconnect__QueueName__c);
        }
        return retVal;
    }

    /**
     * @description  Refreshes the static variable acContactTraceTransferMap
     * @param   None
     * @return  None
     */
    public static void refreshAcContactTraceTransferMap() {
        Set<Id> caseIds = acContactTraceTransferMap.keySet();
        if (caseIds.isEmpty()) {
            return;
        }
        acContactTraceTransferMap.putAll(convertAcContactTraceListToMap((List<amazonconnect__AC_ContactTraceRecord__c>)Database.query(getAcContactTraceTransferBaseQuery() + ' AND Case__c IN :caseIds')));
    }

    /********************** Case Detail **********************/
    // Not a generic case optimization scenario, but used for Case Detail
    private static Map<Id, Case_Detail__c> caseDetailMap = new Map<Id, Case_Detail__c>();
    private static Map<String, Case_Detail__c> caseDetailCaseMap = new Map<String, Case_Detail__c>();
    /**
     * @description  Getter for the Case Detail Record
     * @param   None
     * @return  Map<Id, Case_Detail__c>
     */
    public static Map<Id, Case_Detail__c> getcaseDetailMap() {
        return caseDetailMap;
    }

    /**
     * @description  get the specific Case Details Record Based on the Id
     * @param   caseDetailId {String}
     * @return Map<Id, Case_Detail__c>
     */
    public static Case_Detail__c getcaseDetailMapById(String caseDetailId) {
        return caseDetailMap.get(caseDetailId);
    }

    /**
     * @description  Getter for the Case Detail Record with the case Id as key
     * @param   None
     * @return  Map<String, Case_Detail__c>
     */
    public static Map<String, Case_Detail__c> getcaseDetailCaseMap() {
        return caseDetailCaseMap;
    }

    /**
     * @description  get the specific Case Details Record Based on the case id
     * @param   caseId {String}
     * @return Map<String, Case_Detail__c>
     */
    public static Case_Detail__c getcaseDetailCaseMapById(String caseId) {
        return caseDetailCaseMap.get(caseId);
    }

    /**
     * @description  Query for Case Detail Records
     * @param   None
     * @return  String
     */
    private static String caseDetailBaseQueryBaseQuery = null;
    public static String getCaseDetailBaseQuery() {
        if (acContactTraceTransferBaseQuery == null) {
            caseDetailBaseQueryBaseQuery = 'SELECT ' + getFields('Case_Detail__c' , null) +
                						   ' FROM Case_Detail__c WHERE ';
        }
        return caseDetailBaseQueryBaseQuery;
    }

    /**
     * @description  Setter for the Case Detail map in memory
     * @param   Set<Id> ids - Id of Case Detail whose record needs to query
     * @return  None
     */
    public static void setCaseDetailMap(Set<Id> caseDetailIds) {
        Set<Id> idsToQuery = caseDetailIds.clone();
        idsToQuery.removeAll(caseDetailMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        List<Case_Detail__c> cdLstRet = (List<Case_Detail__c>)Database.query(getCaseDetailBaseQuery() + ' id IN :idsToQuery');
        if(cdLstRet != null && !cdLstRet.isEmpty()){
        	caseDetailMap.putAll(convertCaseDetailListToMap(cdLstRet));
            caseDetailCaseMap.putAll(convertCaseDetailListToCaseMap(cdLstRet));
        }
    }

    /**
     * @description  Convert a Case_Detail__c List to a Map where key is the id
     * @param   List<Case_Detail__c> - list to convert to map
     * @return  Map<Id,Case_Detail__c> - map where key is the id and value is the record of case detail
     */
    private static Map<Id,Case_Detail__c> convertCaseDetailListToMap(List<Case_Detail__c> caseDetailList) {
        Map<Id,Case_Detail__c> retVal = new Map<Id,Case_Detail__c>();
        for (Case_Detail__c rec : caseDetailList) {
            retVal.put(rec.id,rec);
        }
        return retVal;
    }

    /**
     * @description  Convert a Case_Detail__c List to a Map where key is the Case Record Id
     * @param   List<Case_Detail__c> - list to convert to Case, CaseDetail map
     * @return  Map<String,Case_Detail__c> - map where key is the Case ID and value is the record of case detail
     */
    private static Map<String,Case_Detail__c> convertCaseDetailListToCaseMap(List<Case_Detail__c> caseDetailList) {
        Map<String,Case_Detail__c> retVal = new Map<String,Case_Detail__c>();
        for (Case_Detail__c rec : caseDetailList) {
            retVal.put(rec.Case__c ,rec);
        }
        return retVal;
    }

    /**
     * @description  Refreshes the static variable caseDetailMap
     * @param   None
     * @return  None
     */
    public static void refreshcaseDetailMap() {
        Set<Id> caseDetailIds = caseDetailMap.keySet();
        if (caseDetailIds.isEmpty()) {
            return;
        }
        List<Case_Detail__c> cdLstRet = (List<Case_Detail__c>)Database.query(getCaseDetailBaseQuery() + ' id IN :idsToQuery');
        if(cdLstRet != null && !cdLstRet.isEmpty()){
        	caseDetailMap.putAll(convertCaseDetailListToMap(cdLstRet));
            caseDetailCaseMap.putAll(convertCaseDetailListToCaseMap(cdLstRet));
        }
    }

    /********************** DML OPTIMIZATION **********************
     * This framework stores all the updates to related entities like opportunities and account in memory and does one final DML in after insert/after update
     */

    // Static map<SobjectName,map<id,Sobject to update>> which will allow for single DMLs instead of each method doing its own dml on related entities
    private static Map<String,Map<Id,Sobject>> sObjectToUpdateMap = new Map<String,Map<Id,Sobject>>();
    /**
     * @description Sets the update needed in the sObjectToUpdateMap Map
     * @param   String sObjectName - Object Name to update
     *          Id objId - Record Id to Update
     *          String fieldName - Field API Name to set
     *          Object fieldVal - value to set on the field.
     * @return  None
     *
     * @example CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Opportunity',opp.Id,'Trial_Adjusted_Date__c', c.Trial_Adjustment_Date__c);
     */
    public static void setSobjectToUpdate(String sObjectName,Id objId,String fieldName,Object fieldVal) {
        if (String.isBlank(sObjectName) || objId == null) {
            return;
        }
        if (!sObjectToUpdateMap.containsKey(sObjectName)) {
            sObjectToUpdateMap.put(sObjectName,new Map<Id,SObject>());
        }
        Map<Id,Sobject> sObjectMap = sObjectToUpdateMap.get(sObjectName);
        if (!sObjectMap.containsKey(objId)) {
            Sobject obj = objId.getSobjectType().newSobject(objId);
            sObjectMap.put(objId,obj);
        }
        sObjectMap.get(objId).put(fieldName,fieldVal);
    }
    /**
     * @description Sets the update needed in the sObjectToUpdateMap Map - use if you have multiple fields to update
     * @param   String sObjectName - Object Name to update
     *          Id objId - Record Id to Update
     *          Map<String,Object> fieldValues - Map<Field API Name,Value>
     * @return  None
     *
     * @example Map<String,Object> fieldVal = new Map<String,Object>{
                    'BypassValidationForProcessBuilder__c' => true,
                    'OwnerId' => c.Post_Sale_Owner__c
                };
                CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Account',c.AccountId,fieldVal);
     */
    public static void setSobjectToUpdate(String sObjectName,Id objId,Map<String,Object> fieldValues) {
        if (String.isBlank(sObjectName) || objId == null) {
            return;
        }
        if (!sObjectToUpdateMap.containsKey(sObjectName)) {
            sObjectToUpdateMap.put(sObjectName,new Map<Id,SObject>());
        }
        Map<Id,Sobject> sObjectMap = sObjectToUpdateMap.get(sObjectName);
        if (!sObjectMap.containsKey(objId)) {
            Sobject obj = objId.getSobjectType().newSobject(objId);
            sObjectMap.put(objId,obj);
        }
        Sobject obj = sObjectMap.get(objId);
        for (String fieldName : fieldValues.keySet()) {
            obj.put(fieldName,fieldValues.get(fieldName));
        }
    }

    /*****************************************************************************************************************************/
    /********** Use this only if you can wait till the end of the transaction (after insert/after update) to do the DML **********/
    /*        If you need the id from the inserted record immediately after insert, do not use this optimization technique       */
    /*****************************************************************************************************************************/
    // Static map<SobjectName,List<Sobject to insert>> which will allow for single DMLs instead of each method doing its own dml on related entities
    private static Map<String,List<Sobject>> sObjectToInsertMap = new Map<String,List<Sobject>>();
    /**
     * @description Sets the list needed in the sObjectToInsertMap Map
     * @param   String sObjectName - Object Name to update
     *          List<SObject> - Sobjects to Insert
     * @return  None
     *
     */
    public static void setSObjectToInsert(String sObjectName,List<SObject> sObjectList) {
        if (String.isBlank(sObjectName) || sObjectList.isEmpty()) {
            return;
        }
        if (!sObjectToInsertMap.containsKey(sObjectName)) {
            sObjectToInsertMap.put(sObjectName,new List<SObject>());
        }
        sObjectToInsertMap.get(sObjectName).addAll(sObjectList);
    }

    /**
     * @description Execute the Insert and Update DMLs at the end of the transaction.
     * @param   None
     * @return  None
     **/
    public static void executeSObjectDML() {
        if (sObjectToInsertMap.isEmpty() && sObjectToUpdateMap.isEmpty()) {
            return;
        }
        Savepoint sp = Database.setSavepoint();
        try {
            if (!sObjectToInsertMap.isEmpty()) {
                Set<String> objectNames = sObjectToInsertMap.keySet().clone();
                // Dont worry about DML in a for loop, code is collecting insert requests from the trigger and executing it here
                // instead of multiple DML calls within the trigger itself to the same object.
                // Overall number of DML Calls will be <= traditional trigger coding where dml happens within the trigger methods.
                for (String objectName : objectNames) {
                    List<SObject> toInsert = sObjectToInsertMap.get(objectName);
                    sObjectToInsertMap.remove(objectName);
                    if (toInsert != null && !toInsert.isEmpty()) {
                        insert toInsert;
                    }
                }
            }
            if (!sObjectToUpdateMap.isEmpty()) {
                Set<String> objectNames = sObjectToUpdateMap.keySet().clone();
                // Dont worry about DML in a for loop, code is collecting update requests from the trigger and executing it here
                // instead of multiple DML calls within the trigger itself to the same object
                // Overall number of DML Calls will be <= traditional trigger coding where dml happens within the trigger methods.
                for (String objectName : objectNames) {
                    Map<Id,Sobject> toUpdate = sObjectToUpdateMap.get(objectName);
                    sObjectToUpdateMap.remove(objectName);
                    if (toUpdate != null && !toUpdate.isEmpty()) {
                        update toUpdate.values();
                    }
                    // Refreshing cache
                    switch on objectName {
                        when 'Opportunity' {
                            refreshOpportunityMap();
                        } when 'Account' {
                            refreshAccountMap();
                        } when 'Contact' {
                            refreshContactMap();
                        }
                    }
                }
            }
        } catch(Exception e) {
            Database.rollback( sp );
            throw e;
        }
    }
}