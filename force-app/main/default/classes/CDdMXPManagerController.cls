/**
 * CDdMXPManagerController
 * @ticketNo BIZS - 167
 * @author Pranil Nimase
 * @date  15 July 2021
 * @decription Controller for LwcDdmxpManager Lightning Web Component
 */
public without sharing class CDdMXPManagerController {
    
    public static final String ACCOUNTS_LABEL = 'accounts';
    public static final String USERS_LABEL = 'users';
    public static final String ADD_OPERATION = 'Add';
    public static final String REMOVE_OPERATION = 'Remove';
    public static final String ADD_REMOVE_OPERATION = 'mix';
    public static final String ATM_STR = 'atmStr';
    public static final String DELETE_ACCOUNTTEAMS = 'deletedATM';
    public static final String ACCOUNT_RECORD_UPDATE = 'UpdatedAccRec';
    public static final String REQUEST = 'request';
    public static final String RESPONSE = 'response1';
    public static final String RESPONSE2 = 'response2';
    public static final String RESPONSE2_1 = 'response2.1';
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription update the user records and returns the user records which are updated.
     * @params users records in string format.
     * @return returns the user records which are updated.
     */    
    @AuraEnabled
    public static Map<String, Object> updateUsersOOO(String usersDataString){
        //Key is USERS_LABEL and Value is User List
        Map<String, Object> userRecordsResultMap = new Map<String, Object>();
        try {
            List<User> userRecordsList = (List<User>) JSON.deserialize(usersDataString, List<User>.class);
            if(!userRecordsList.isEmpty()){
                update userRecordsList;
            }
            
            List<User> userList = new List<User>();
            userList = [
                SELECT Id, Profile.Id, 
                    Profile.Name, UserRole.Name,
                    Username, FirstName, LastName, 
                    Name, Is_Out_Of_Office__c, Out_Of_Office_End_Date__c, 
                    IsActive
                FROM User
                WHERE Id IN :userRecordsList
            ];
            userRecordsResultMap.put(USERS_LABEL, userList);
        }catch(DmlException e){
            handleDMLException(e);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return userRecordsResultMap;
    }
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription This method will update the account related case routing override field value and return tha data.
     * @param 
     * @return returns the account records which are updated.
     */    
    @AuraEnabled
    public static Map<String, Object> updateAccountsCRO(String accountRecordString){
        //Key is ACCOUNTS_LABEL and Value is Account List
        Map<String, Object> accountRecordresultMap = new Map<String, Object>();
        try {
            List<Account> accountsRecList = (List<Account>) JSON.deserialize(accountRecordString, List<Account>.class);
            if(!accountsRecList.isEmpty()){           
                update accountsRecList;
            }
            
            List<Account> accountList = new List<Account>();
            accountList = [
                SELECT Id, Name, Business_ID__c, Restaurant_ID__c, Case_Routing_Override__c
                FROM Account
                WHERE Id IN :accountsRecList
            ];
            accountRecordresultMap.put(ACCOUNTS_LABEL, accountList);
        }catch(DmlException e){
            handleDMLException(e);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return accountRecordresultMap;
    }
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription based on the operation type this method perform upsert, delete operations on account team member records.
     * @params accountTeamMember records in string format, and operations like add, remove will pass as operation param.
     * @return returns the records which are upserted or deleted based on the operation we passed as param.
     */
    @AuraEnabled
    public static Map<String, Object> upsertOrRemoveAccountTeams(String accTeamMembStr, String operation){
        Map<String, Object> accTeamMembresultMap = new Map<String, Object>();
        try {
            if(operation == ADD_OPERATION){
                List<AccountTeamMember> accountTeamMembersList = (List<AccountTeamMember>) JSON.deserialize(accTeamMembStr, List<AccountTeamMember>.class);
                upsert accountTeamMembersList;
                accTeamMembresultMap.put(ATM_STR, accountTeamMembersList);
            }else if(operation == ADD_REMOVE_OPERATION){
                List<AccountTeamMemberWrapper> accountTeamMemberWrappers = (List<AccountTeamMemberWrapper>) JSON.deserialize(accTeamMembStr, List<AccountTeamMemberWrapper>.class);
                List<AccountTeamMember> removeAccTeamMembToList = new List<AccountTeamMember>();
                List<AccountTeamMember> saveAccTeamMembList = new List<AccountTeamMember>();
                
                for(AccountTeamMemberWrapper wrapper : accountTeamMemberWrappers){
                    if( wrapper.change == ADD_OPERATION ){
                        saveAccTeamMembList.add(new AccountTeamMember(userId = wrapper.userId, accountId = wrapper.accountId, TeamMemberRole = wrapper.teamMemberRole));
                    }else if( wrapper.change == REMOVE_OPERATION ){
                        removeAccTeamMembToList.add(new AccountTeamMember(userId = wrapper.userId, accountId = wrapper.accountId, TeamMemberRole = wrapper.teamMemberRole));
                    }
                }
                
                List<AccountTeamMember> deleteATMrecords = new List<AccountTeamMember>();
                if(removeAccTeamMembToList.size() > 0){
                    List<Id> userIdsList = new List<Id>();
                    List<Id> accountIdsList = new List<Id>();
                    Set<String> userIdAccountIdSet = new Set<String>();
                    
                    for(AccountTeamMember atm : removeAccTeamMembToList){
                        userIdsList.add(atm.UserId);
                        accountIdsList.add(atm.AccountId);
                        userIdAccountIdSet.add(atm.UserId + CDdCoreConstants.BLANK_STRING + atm.AccountId);
                    }
                    
                    List<AccountTeamMember> accTeamMembRecList = new List<AccountTeamMember>();
                    accTeamMembRecList = [
                        SELECT Id, UserId, AccountId 
                        FROM AccountTeamMember 
                        WHERE AccountId IN :accountIdsList 
                        AND UserId IN :userIdsList
                    ];
                    for(AccountTeamMember atmRec : accTeamMembRecList){
                        if( userIdAccountIdSet.contains(atmRec.UserId + CDdCoreConstants.BLANK_STRING + atmRec.accountId)){
                            deleteATMrecords.add(new AccountTeamMember(Id = atmRec.Id));
                        }
                    }
                }
                
                if(saveAccTeamMembList.size() > 0){
                    insert saveAccTeamMembList;
                }
                if(deleteATMrecords.size() > 0){
                    delete deleteATMrecords;
                }   
                accTeamMembresultMap.put(RESPONSE, saveAccTeamMembList);
                accTeamMembresultMap.put(RESPONSE2, removeAccTeamMembToList);
                accTeamMembresultMap.put(RESPONSE2_1, deleteATMrecords);
                accTeamMembresultMap.put(REQUEST, accTeamMembStr);
            }   
        }catch(DmlException e){
            handleDMLException(e);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return accTeamMembresultMap;
    }
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription This method will delete the account team members based on the list of ids passed as params.
     * @param List of AccountTeamMember Ids provided as params.
     * @return returns the records which are deleted.
     */
    @AuraEnabled
    public static Map<String, Object> removeAccountTeams(List<Id> accountTeamIds){ 
        //Key is DELETE_ACCOUNTTEAMS and Value is AccountTeamMember List       
        Map<String, Object> accTeamMembresultMap = new Map<String, Object>();
        List<AccountTeamMember> accTeamLists = new List<AccountTeamMember>();
        if(!accountTeamIds.isEmpty()){
            for(Id atmId : accountTeamIds){
                accTeamLists.add(new AccountTeamMember(Id = atmId));
            }   
        }
        if(!accTeamLists.isEmpty()){
            try {
                delete accTeamLists;
            }catch(DmlException e){
                handleDMLException(e);
            }
        }
        accTeamMembresultMap.put(DELETE_ACCOUNTTEAMS, accTeamLists);
        return accTeamMembresultMap;       
    }
    
    
    public class AccountTeamMemberWrapper{
        public String accountId;
        public String userId;
        public String change;
        public String teamMemberRole;
    }
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription This method is to check the existing account team members based on userId and accountId.
     * @params UserId and accountId combination as params.
     * @return returns the existing accountTeamMembers.
     */
    @AuraEnabled
    public static Map<String, AccountTeamMember> getExistingAcccountTeams(List<String> userId, List<String> accountId){    
        //Key is User Id and Value is Account Team Member record  
        Map<String, AccountTeamMember> userIdToAccountTeamMap = new Map<String, AccountTeamMember>();
        if(!userId.isEmpty() && !accountId.isEmpty()){
            for(AccountTeamMember acc: [
                SELECT Id, AccountId, UserId, Title, TeamMemberRole    
                FROM AccountTeamMember
                WHERE AccountId IN :accountId 
                AND UserId IN :userId
            ])
            {
                userIdToAccountTeamMap.put(acc.UserId + CDdCoreConstants.BLANK_STRING + acc.AccountId,acc);
            }
        }
        return  userIdToAccountTeamMap;       
    }
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription This method returns true if user has permission otherwise false.
     * @params none
     * @return Boolean value.
     */
    @AuraEnabled(cacheable=true)
    public static Boolean getUserPerm(){
        Boolean doesUserHavePermisssion;
        try {
            String userProfileName = [
                SELECT Name
                FROM Profile 
                WHERE Id = :UserInfo.getProfileId()].Name;
            if(userProfileName == CDdSupportConstants.SYSADMIN_PROFILE || userProfileName == CDdSupportConstants.BIZAPPS_TEAM_PROFILE){
                doesUserHavePermisssion = true;
            }else{
                List<PermissionSetAssignment> permSetList = [
                    SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Name 
                    FROM PermissionSetAssignment 
                    WHERE AssigneeId = :UserInfo.getUserId() 
                    AND PermissionSet.Name = :CDdSupportConstants.MXP_TEAM_MANAGER
                ];

                doesUserHavePermisssion = permSetList.size() > 0 ? true : false;
            }
        }catch(Exception e){
            //throw all other exception message
            throw new AuraHandledException(e.getMessage());
        }
        return doesUserHavePermisssion;
    }
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription This method returns the Existing account records based on the Ids provides as params.
     * @params accountId as params.
     * @return existing account records with accountId and account combination.
     */
    @AuraEnabled
    public static Map<String, Account> getExistingAccountRecords(List<String> accountIds){
        //Key is Account ID and Value is Account record
        Map<String, Account> accountMap = new Map<String, Account>();
        
        if(!accountIds.isEmpty()){
            accountMap = new Map<String, Account>([SELECT Id, Name 
                                                   FROM Account 
                                                   WHERE Id IN :accountIds]);
        }
        return accountMap;  
    }
    
    /**
     * @author Pranil Nimase
     * @date  15 July 2021
     * @decription This method will update the account records case routing override value based on the records provides as param.
     * @params account records in string format
     * @return returns updated account records.
     */
    @AuraEnabled
    public static Map<String, Object> updateMxAccountRecords(String mxAccRecStr){
        try {
            //Key is ACCOUNT_RECORD_UPDATE and Value is Account list
            Map<String, Object> updatedAccRecordMap = new Map<String, Object>();
            List<AccountWrapper> accountWrappersList = (List<AccountWrapper>) JSON.deserialize(mxAccRecStr, List<AccountWrapper>.class);
            List<Account> updateAccountsList = new List<Account>();
            for(AccountWrapper wrapper : accountWrappersList){
                updateAccountsList.add(new Account(Id = wrapper.AccountId, Case_Routing_Override__c = wrapper.CaseRouting));
            }
            if(!updateAccountsList.isEmpty()){
                updatedAccRecordMap.put(ACCOUNT_RECORD_UPDATE, updateAccountsList);
                update updateAccountsList; 
            }         
            return updatedAccRecordMap;
        }catch(DmlException e){
            String msg = CDdCoreConstants.BLANK_STRING;
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg =+ e.getDmlMessage(i) +  CDdCoreConstants.NEW_LINE ;
            }
            throw new AuraHandledException(msg);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void handleDMLException(DmlException e){
        String msg = CDdCoreConstants.BLANK_STRING;
        for (Integer i = 0; i < e.getNumDml(); i++) {
            msg =+ e.getDmlMessage(i) +  CDdCoreConstants.NEW_LINE ;
        }
        throw new AuraHandledException(msg);
    }

    public class AccountWrapper{
        public String accountId;
        public String caserouting;
    }  
}