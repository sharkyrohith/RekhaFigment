/**
 * CDdMXPSearchRecordsCtrl
 * @author     Pranil Nimase
 * @date  15 July 2021
 * @decription Controller for lwcDdsearchdatatable Lightning Web Component
 * 
 */
public without sharing class CDdMXPSearchRecordsCtrl {
    
  /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
    private static final String USER_OBJECT = 'User';
    private static final String ACCOUNT_OBJECT = 'Account';
    private static final String CASE_OBJECT = 'Case';
    private static final String ACCOUNT_TEAM_MEMBER_OBJECT = 'AccountTeamMember';
    private static final String ORDER_BY = ' ORDER BY ';
    private static final String WHERE_CLAUSE = ' WHERE ';
    private static final String QUERY_LIMIT = ' LIMIT ';
    private static final String OFF_SET = ' OFFSET ';
    private static final String AND_OPERATOR = ' AND ';
    private static Set<Id> mxpTeamMembers = new Set<Id>();
    private static Integer totalNumberOfRecords;
    private static Set<Id> userIds = new Set<Id>();
    private static Set<Id> accountIds = new Set<Id>();
    
    static {
        List<PermissionSetAssignment> permissionsetAssList = [SELECT Id,
                                                                PermissionSetId,
                                                                PermissionSet.Name,
                                                                AssigneeId,
                                                                Assignee.Name, 
                                                                IsActive 
                                                            FROM PermissionSetAssignment 
                                                            WHERE PermissionSet.Name =: CDdSupportConstants.MXP_TEAM_MEMBER];
        
        for(PermissionSetAssignment per:permissionsetAssList){
            if(per.AssigneeId != null){
                mxpTeamMembers.add(per.AssigneeId);
            }
        }
    }

    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /** 
     * @author     Pranil Nimase
     * @date  15 July 2021
     * @decription Returns object records on the basis of various search parameters
     * @param   searchParameters containing different parameters for querying records          
     * @return  RecordWrapper instance containing offset, total number of record count and object records
     */
    @AuraEnabled(cacheable=true)
    public static RecordWrapper findRecords(CDdSearchParameterWrapper searchParameters) {
        try {
            RecordWrapper recordWrapper;
            searchParameters.usernameSearchKey = String.isNotBlank(searchParameters.usernameSearchKey) ? searchParameters.usernameSearchKey.trim() : searchParameters.usernameSearchKey;
            searchParameters.accountnameSearchKey = String.isNotBlank(searchParameters.accountnameSearchKey) ? searchParameters.accountnameSearchKey.trim() : searchParameters.accountnameSearchKey;
            searchParameters.statusSearchKey = String.isNotBlank(searchParameters.statusSearchKey) ? searchParameters.statusSearchKey.trim() : searchParameters.statusSearchKey;
            searchParameters.businessIdSearchKey = String.isNotBlank(searchParameters.businessIdSearchKey) ? searchParameters.businessIdSearchKey.trim() : searchParameters.businessIdSearchKey;
            searchParameters.mxpUserSearchKey = String.isNotBlank(searchParameters.mxpUserSearchKey) ? searchParameters.mxpUserSearchKey.trim() : searchParameters.mxpUserSearchKey;
            searchParameters.emailSearchKey = String.isNotBlank(searchParameters.emailSearchKey) ? searchParameters.emailSearchKey.trim() : searchParameters.emailSearchKey;
            searchParameters.profileSearchKey = String.isNotBlank(searchParameters.profileSearchKey) ? searchParameters.profileSearchKey.trim() : searchParameters.profileSearchKey;
            searchParameters.roleSearchKey = String.isNotBlank(searchParameters.roleSearchKey) ? searchParameters.roleSearchKey.trim() : searchParameters.roleSearchKey;
            
            if(searchParameters.objectApiName == CASE_OBJECT) {
                recordWrapper = getCaseRecords(searchParameters);
            }
            else if(searchParameters.objectApiName == ACCOUNT_TEAM_MEMBER_OBJECT) {
                recordWrapper = getAccountTeamMemberRecords(searchParameters);
            }
            else if(searchParameters.objectApiName == USER_OBJECT) {
                recordWrapper = getUserRecords(searchParameters);
            }
            else if(searchParameters.objectApiName == ACCOUNT_OBJECT) {
                recordWrapper = getAccountRecords(searchParameters);
            }
            return recordWrapper;
        }catch(Exception e){
            //throw all other exception message
            throw new AuraHandledException(e.getMessage());
        }
    }

    /** 
     * @author     Mahesh Chouhan
     * @date  2 Sept 2021
     * @decription Returns Case records on the basis of various search parameters
     * @param   searchParameters containing different parameters for querying records
     * @return  RecordWrapper instance containing offset, total number of record count and Case records with MXP Names
     */
    private static RecordWrapper getCaseRecords(CDdSearchParameterWrapper searchParameters) {
        //Key is AccountId and Value is User Name
        Map<Id, String> mxpUserMap = new Map<Id, String>();
        Set<Id> mxpUsers = new Set<Id>();
        String isCaseOwnerMXPClause = CDdCoreConstants.BLANK_STRING;
        String caseAccountQuery = '';
        Map<String, String> mxpNames = new Map<String, String>();
        String caseStatusWhereClause = String.isNotBlank(searchParameters.statusSearchKey) ?
            'Status LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.statusSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : 'Status != \'Closed\'';
        String businessIdWhereClause = String.isNotBlank(searchParameters.businessIdSearchKey) ?
            'Account.Business_Id__c = ' + searchParameters.businessIdSearchKey : CDdCoreConstants.BLANK_STRING;
        String accountTeamMemberQuery = 'SELECT ID, AccountID, User.Name, UserId FROM AccountTeamMember WHERE TeamMemberRole = \'\'{0}\'\' AND User.Name LIKE \'%{1}%\'';
        String mxpUserWhereClause = String.isNotBlank(searchParameters.mxpUserSearchKey) ? searchParameters.mxpUserSearchKey : UserInfo.getName();

        if(String.isNotBlank(mxpUserWhereClause)) {
            for(AccountTeamMember accTeamMember : Database.query(String.format(accountTeamMemberQuery, new List<String>{CDdSupportConstants.MXP_ROLE_NAME, mxpUserWhereClause}))) {
                mxpUserMap.put(accTeamMember.AccountId, accTeamMember.User.Name);
                mxpUsers.add(accTeamMember.UserId);
            }
        }

        List<Group> mxsxQueue = [SELECT ID 
                                 FROM Group 
                                 WHERE DeveloperName = :CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK];

        if(!mxsxQueue.isEmpty()) {
            userIds.add(mxsxQueue[0].Id);
        }

        if(searchParameters.showSelectedUsers && String.isNotBlank(searchParameters.mxpUserSearchKey)) {
            userIds.addAll(mxpUsers);
            isCaseOwnerMXPClause = 'OwnerId IN :userIds';
        }
        else if(searchParameters.showSelectedUsers && String.isBlank(searchParameters.mxpUserSearchKey)){
            userIds.add(UserInfo.getUserId());
            isCaseOwnerMXPClause = 'OwnerId IN :userIds';
        }

        accountIds = mxpUserMap.keySet();
        if(String.isNotBlank(searchParameters.mxpUserSearchKey) || (String.isBlank(businessIdWhereClause) && 
        String.isBlank(searchParameters.statusSearchKey) && String.isBlank(searchParameters.mxpUserSearchKey))) {
            caseAccountQuery = 'AccountId IN :accountIds';
        }
        
        List<String> queryConditions = new List<String>{isCaseOwnerMXPClause, caseStatusWhereClause, businessIdWhereClause, caseAccountQuery};
        List<SObject> records = queryRecords(queryConditions, searchParameters);

        if((String.isNotBlank(businessIdWhereClause) || String.isNotBlank(searchParameters.statusSearchKey)) && 
            String.isBlank(searchParameters.mxpUserSearchKey)) {
            Set<Id> caseAccountIds = new Set<Id>();
            for(Case record : (List<Case>) records) {
                caseAccountIds.add(record.AccountId);
            }
            List<AccountTeamMember> accountTeamMembers = [SELECT Id, AccountId, User.Name 
                                                          FROM AccountTeamMember 
                                                          WHERE AccountId IN :caseAccountIds AND TeamMemberRole = :CDdSupportConstants.MXP_ROLE_NAME];

            Map<Id, List<String>> multiMxpUserMap = new Map<Id, List<String>>();
            for(AccountTeamMember accTeamMember : accountTeamMembers) {
                if(!multiMxpUserMap.containsKey(accTeamMember.AccountId)) {
                    multiMxpUserMap.put(accTeamMember.AccountId, new List<String>{});
                }
                multiMxpUserMap.get(accTeamMember.AccountId).add(accTeamMember.User.Name);
            }

            for(Case record : (List<Case>) records) {
                if(multiMxpUserMap.containsKey(record.AccountId)) {
                    mxpNames.put(record.Id, String.join(multiMxpUserMap.get(record.AccountId), CDdCoreConstants.DELIMITER_COMMA));
                }
                else {
                    mxpNames.put(record.Id, CDdCoreConstants.DELIMITER_HYPHEN);
                }
            }
        }
        else {
            for(Case record : (List<Case>) records) {
                if(mxpUserMap.containsKey(record.AccountId)) {
                    mxpNames.put(record.Id, mxpUserMap.get(record.AccountId));
                }
                else {
                    mxpNames.put(record.Id, CDdCoreConstants.DELIMITER_HYPHEN);
                }
            }
        }

        return new RecordWrapper(totalNumberOfRecords, searchParameters.offSet, records, mxpNames);
    }

    /** 
     * @author     Mahesh Chouhan
     * @date  2 Sept 2021
     * @decription Returns AccountTeamMember records on the basis of various search parameters
     * @param   searchParameters containing different parameters for querying records
     * @return  RecordWrapper instance containing offset, total number of record count and AccountTeamMember records
     */
    private static RecordWrapper getAccountTeamMemberRecords(CDdSearchParameterWrapper searchParameters) {
        String usernameWhereClause = String.isNotBlank(searchParameters.usernameSearchKey) ?
            'User.Name LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.usernameSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        String emailWhereClause = String.isNotBlank(searchParameters.emailSearchKey) ?
            'User.Email LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.emailSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        String profileWhereClause = String.isNotBlank(searchParameters.profileSearchKey) ?
            'User.Profile.Name LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.profileSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        String roleWhereClause = String.isNotBlank(searchParameters.roleSearchKey) ?
            'User.UserRole.Name LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.roleSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        List<String> queryConditions = new List<String>{usernameWhereClause, emailWhereClause, profileWhereClause, roleWhereClause};
        List<SObject> records = queryRecords(queryConditions, searchParameters);
        return new RecordWrapper(totalNumberOfRecords, searchParameters.offSet, records);
    }

    /** 
     * @author     Mahesh Chouhan
     * @date  2 Sept 2021
     * @decription Returns User records on the basis of various search parameters
     * @param   searchParameters containing different parameters for querying records
     * @return  RecordWrapper instance containing offset, total number of record count and User records
     */
    private static RecordWrapper getUserRecords(CDdSearchParameterWrapper searchParameters) {
        String usernameWhereClause = String.isNotBlank(searchParameters.usernameSearchKey) ?
            'Name LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT+ searchParameters.usernameSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        String emailWhereClause = String.isNotBlank(searchParameters.emailSearchKey) ?
            'Email LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.emailSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        String profileWhereClause = String.isNotBlank(searchParameters.profileSearchKey) ?
            'Profile.Name LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.profileSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        String roleWhereClause = String.isNotBlank(searchParameters.roleSearchKey) ?
            'UserRole.Name LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.roleSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;
        String isUserActiveMXPMemberClause = 'IsActive = true AND Id IN :mxpTeamMembers';

        List<String> queryConditions = new List<String>{usernameWhereClause, emailWhereClause, profileWhereClause, roleWhereClause, isUserActiveMXPMemberClause};
        List<SObject> records = queryRecords(queryConditions, searchParameters);
        return new RecordWrapper(totalNumberOfRecords, searchParameters.offSet, records);
    }

    /** 
     * @author     Mahesh Chouhan
     * @date  2 Sept 2021
     * @decription Returns Account records on the basis of various search parameters
     * @param   searchParameters containing different parameters for querying records
     * @return  RecordWrapper instance containing offset, total number of record count and Account records
     */
    private static RecordWrapper getAccountRecords(CDdSearchParameterWrapper searchParameters) {
        String accountNameWhereClause = String.isNotBlank(searchParameters.accountnameSearchKey) ?
            'Name LIKE \'' + CDdCoreConstants.DELIMITER_PERCENT + searchParameters.accountnameSearchKey + CDdCoreConstants.DELIMITER_PERCENT + '\'' : CDdCoreConstants.BLANK_STRING;

        List<String> queryConditions = new List<String>{accountNameWhereClause};
        List<SObject> records = queryRecords(queryConditions, searchParameters);
        return new RecordWrapper(totalNumberOfRecords, searchParameters.offSet, records);
    }

    /** 
     * @author     Mahesh Chouhan
     * @date  2 Sept 2021
     * @decription Returns sobject records on the basis of various parameters
     * @param   queryConditions containing where clause queries
     * @param   searchParameters containing different parameters for querying records
     * @return  List<SObject> containing different type of sobject record
     */
    private static List<SObject> queryRecords(List<String> queryConditions, CDdSearchParameterWrapper searchParameters) {
        String query = 'SELECT ID, {0} FROM {1} {2}';
        String sortOrder = String.isNotBlank(searchParameters.orderBy) ? 
        ORDER_BY + searchParameters.orderBy + CDdCoreConstants.DELIMITER_SPACE + searchParameters.sortOrder : CDdCoreConstants.BLANK_STRING;
        String whereClause = CDdCoreConstants.BLANK_STRING;
        String finalQuery = CDdCoreConstants.BLANK_STRING;
        String queryLimit = QUERY_LIMIT + searchParameters.pageSize;
        String queryOffset = OFF_SET + searchParameters.offSet;

        for(String queryCondition : queryConditions) {
            if(String.isNotBlank(queryCondition)) {
                whereClause += queryCondition + AND_OPERATOR;
            }
        }
        
        if(String.isNotBlank(whereClause)) {
            whereClause = WHERE_CLAUSE + whereClause.substring(0, whereClause.length()-5);
            finalQuery = String.format(query, new List<String>{String.join(searchParameters.selectFields, CDdCoreConstants.DELIMITER_COMMA), searchParameters.objectApiName, whereClause});
            totalNumberOfRecords = Database.countQuery('SELECT COUNT() FROM '+ searchParameters.objectApiName + whereClause);
        }
        else {
            finalQuery = String.format(query, new List<String>{String.join(searchParameters.selectFields, CDdCoreConstants.DELIMITER_COMMA), searchParameters.objectApiName, whereClause});
            totalNumberOfRecords = Database.countQuery('SELECT COUNT() FROM '+ searchParameters.objectApiName);
        }
        
        List<SObject> records = Database.query(finalQuery + sortOrder + queryLimit + queryOffset);
        return records;
    }
    
    /**
    * RecordWrapper
    *
    * @author     Pranil Nimase
    * @date  15 July 2021
    * @decription Wrapper class containing containing offset, total number of record count and object records
    * 
    */
    public class RecordWrapper {
        @AuraEnabled
        public Integer totalNumberOfRecords {get; set;}
        @AuraEnabled
        public Integer offSet {get; set;}
        @AuraEnabled
        public List<SObject> records {get; set;}
        @AuraEnabled
        public Map<String, String> mxpNames {get; set;}
        
        public RecordWrapper(Integer totalNumberOfRecords, Integer offSet, List<SObject> records, Map<String, String> mxpNames) {
            this.totalNumberOfRecords = totalNumberOfRecords;
            this.offSet = offSet;
            this.records = records;
            this.mxpNames = mxpNames;
        }

        public RecordWrapper(Integer totalNumberOfRecords, Integer offSet, List<SObject> records) {
            this.totalNumberOfRecords = totalNumberOfRecords;
            this.offSet = offSet;
            this.records = records;
        }
    }
}