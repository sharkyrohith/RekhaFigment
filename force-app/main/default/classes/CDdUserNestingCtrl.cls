/**
  * @author:Naren K
  * @date  07/14/2021
  * @decription: This class is used as controller to LWCDdUserNesting lwc component.
  */
public class CDdUserNestingCtrl {
   // Using Label "User_Nesting_Manual_Limit" to set the records limit. If label value is more than 1000, then following error will shown
    public static final String LIMIT_ERROR_MSG  = 'Allowed records limit is high, please contact system admin.';
    public static final String NO_NESTING_PROFILE  = 'No profile added for nesting, please contact system admin.';
    public static final String NESTING_CLSNAME  = 'CDdUserNestingCtrl';
    public static final String PRESUSER_MTHD  = 'getPresUserConfigUser';
    public static final String CHNL_MTHD  = 'getChannelNames';
    public static final String USER_MTHD  = 'getUsers';
    public static final String RMVUSER_FRM_CHNL  = 'removeUserFromChannel';
    
   /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: gets current user permission to show or not show the lwc component LWCDdUserNesting to current user
    * @param   None
    * @return  Boolean value
    */
    @AuraEnabled(Cacheable=true)
    Public static boolean getUserPerm(){
        String userProfileName = [
            select Name
            From profile 
            Where id =: userinfo.getProfileId()].Name;
        if(userProfileName == CDdSupportConstants.SYSTEMADMIN_PROFILE_LABEL || userProfileName == CDdSupportConstants.BIZAPPSTEAM_PROFILE_LABEL
            || userProfileName == CDdSupportConstants.BIZAPPSADMIN_PROFILE_LABEL) {
            return true;
        }else{
            List<PermissionSetAssignment> permSetList = [
                SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId=:userinfo.getUserId() 
                AND PermissionSet.Name=:System.Label.UserNesting_Manager
            ];
            If(permSetList.size()>0){
                return true;
                
            } else{
                return false;
            }
        } 
        
        
    }
    
   /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: reads csv file uplaoded by user and return if any errors
    * @param   Id of conentdocument uplaoded by user
    * @return  map of string list to show the errors if any in csv files 
    */  
    @AuraEnabled
    public static Map<String,List<String>> readCSVFile(Id idContentDocument){  
        Map<String,List<String>> retStatus = CDdBulkAPIUtility.importBulkdata(idContentDocument, true);
        if(retStatus.containsKey(CDdSupportConstants.SUCCESS_LABEL)){
            CDdUserNestingPlatformEventHelper.publishEvent(idContentDocument);
        }
        return retStatus;
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: returns the presenceUserConfig (channel names)
    * @param   None
    * @return  List of presenceUserConfig
    */
    @AuraEnabled(Cacheable=true)
    public static List<presenceUserConfig> getChannelNames(){
        List<presenceUserConfig> prsUsrConfigLst = new List<presenceUserConfig>();
        try{
            prsUsrConfigLst = [
                SELECT Id, DeveloperName, MasterLabel
                FROM presenceUserConfig
                ORDER BY  DeveloperName];
        }
        Catch(Exception ex){
            System.debug('Error Message....'+ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, NESTING_CLSNAME, CHNL_MTHD, LoggingLevel.ERROR);
        }
        return  prsUsrConfigLst;  
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: returns the list of users based on search terms 
    * @param   string of search terms
    * @return  List of users
    */
    @AuraEnabled(Cacheable=true)
    public static List<User> getUsers(string nameSerchVal, string emailSearchVal, string profileSearchVal, string roleSeachVal){
        List<User> userListToReturn = new List<User>();
        List<String> nestingProfileLst = new List<String>();
        String filter;
        String query;
        try{
            if(CDdSupportConstants.MAX_MANUAL_LIMIT< Integer.valueOf(System.Label.User_Nesting_Manual_Limit)){
                String errorMsg = LIMIT_ERROR_MSG; 
                throw new userNestingException(errorMsg);
            }else{
                if(String.isNotBlank(System.Label.Profile_Available_For_Nesting)){
                    nestingProfileLst = System.Label.Profile_Available_For_Nesting.split(';');
                }
                
                String nestingProf ='';
                for(String profile : nestingProfileLst){
                    if(String.isNotBlank(nestingProf)){
                        nestingProf = nestingProf+','+'\''+profile+'\''; 
                    }
                    else{
                        nestingProf = '\''+profile+'\'';
                    }
                }
                if(String.isNotBlank(nestingProf)){
                    filter = ' Where Profile.Name IN ('+nestingProf+')';
                    
                    if(String.isNotBlank(nameSerchVal)){
                        filter = filter+' AND Name LIKE '+'\'%'+nameSerchVal+'%\'';
                    }
                    if(String.isNotBlank(emailSearchVal)){
                        filter = filter+' AND Email LIKE '+'\'%'+emailSearchVal+'%\'';
                    }
                    if(String.isNotBlank(profileSearchVal)){
                        filter = filter+' AND Profile.Name LIKE '+'\'%'+profileSearchVal+'%\'';
                    }
                    if(String.isNotBlank(roleSeachVal)){
                        filter = filter+' AND UserRole.Name LIKE '+'\'%'+roleSeachVal+'%\''; 
                    }
                }
                
                system.debug('filter.....'+filter);
                
                if(String.isNotBlank(filter)){
                    query = 'Select Id, Name, Email,UserProfile__c,UserRole__c FROM User'+filter+' LIMIT '+System.Label.User_Nesting_Manual_Limit;
                } 
                else{
                    throw new userNestingException(NO_NESTING_PROFILE);
                }
                system.debug('query.....'+query);
                if(String.isNotBlank(query)){
                    userListToReturn = Database.query(query);
                }
                system.debug('userListToReturn.....'+userListToReturn.size());
            }
            return userListToReturn;
        }
        Catch(Exception ex){
            System.debug('Error Message....'+ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, NESTING_CLSNAME, USER_MTHD, LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: manual add channel users to presence config 
    * @param   List of slected users from lwc component and a selected presenceUserConfig (channel name) 
    * @return  boolean values to show success or error msg
    */
    @AuraEnabled
    public static boolean addUserToChannel(List<User>userList , string channelIdStr){
        system.debug('selected channel Name'+channelIdStr);
        system.debug('selected users list size'+userList.size());
        boolean result = CDdBulkAPIUtility.addUserToChannelData(userList,channelIdStr);
        return result;
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: manual remove usersfrom channel (presence config) 
    * @param   List of slected PresenceUserConfigUser from lwc component
    * @return  boolean values to show success or error msg
    */
    @AuraEnabled
    public static boolean removeUserFromChannel(List<PresenceUserConfigUser> presUserConUserList){
        system.debug('presUserConUserList....'+presUserConUserList);
        List<Id> presUserIdList = new List<Id>();
        List<Id> presUserConfigIdLst = new List<Id>();
        boolean result = false;
        
        try{
            // Userid is not working directly, that's why first we took recordid then retrived the userids
            for(PresenceUserConfigUser puserconrec : presUserConUserList){
                presUserConfigIdLst.add(puserconrec.Id);
                system.debug('puserconrec....'+puserconrec);
                system.debug('userId....'+puserconrec.userId);
            }
            for(PresenceUserConfigUser purec : [
                SELECT userId 
                FROM PresenceUserConfigUser 
                WHERE id IN :presUserConfigIdLst]){
                    system.debug('purec.userId....'+purec.userId);
                    presUserIdList.add(purec.userId);
                }
            system.debug('userids....'+presUserIdList);
            
            if(!presUserIdList.isEmpty()){
                CDdUserNestingPlatformEventHelper.publishEvent(new List<PresenceUserConfigUser>(), presUserIdList);
                result = true;
            }
        }
        Catch(Exception ex){
            System.debug('Error Message....'+ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, NESTING_CLSNAME, RMVUSER_FRM_CHNL, LoggingLevel.ERROR);
        }
        // need to send true or false once delete jobs are queued
        return result;
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: fetches PresenceUserConfigUser based on search terms
    * @param   Strings of search terms
    * @return  List of PresenceUserConfigUser
    */
    @AuraEnabled(Cacheable=true)
    public static List<PresenceUserConfigUser> getPresUserConfigUser(string nameSerchVal, string emailSearchVal, string profileSearchVal, string roleSeachVal, string channelNameVal){
        // need to have dynamic querry on PresenceUserConfigUser but based on search terms need to form dynamic querry with relationship fields of user name, email profile and role along with searching object channel id
        
        system.debug('nameSerchVal....'+nameSerchVal);
        system.debug('emailSearchVal....'+emailSearchVal);
        system.debug('profileSearchVal....'+profileSearchVal);
        system.debug('roleSeachVal....'+roleSeachVal);
        system.debug('channelNameVal....'+channelNameVal);
        
        List<PresenceUserConfigUser> pucuListToReturn = new List<PresenceUserConfigUser>();
        String filter;
        String query;
        
        try{
            if(CDdSupportConstants.MAX_MANUAL_LIMIT< Integer.valueOf(System.Label.User_Nesting_Manual_Limit)){
                String errorMsg = LIMIT_ERROR_MSG; 
                throw new userNestingException(errorMsg);
            }else{
                if(String.isNotBlank(channelNameVal)){
                    PresenceUserConfig puconfig = [
                        SELECT Id 
                        FROM PresenceUserConfig 
                        WHERE DeveloperName=:channelNameVal];
                    filter = ' WHERE PresenceUserConfigId ='  + '\'' +puconfig.Id+ '\'';
                }
                
                if(String.isNotBlank(nameSerchVal)){
                    if(String.isNotBlank(filter)){
                        filter = filter+' AND User.Name LIKE '+'\'%'+nameSerchVal+'%\''; 
                    }
                    else{
                        filter = ' Where User.Name LIKE '+'\'%'+nameSerchVal+'%\''; 
                    }
                }
                
                if(String.isNotBlank(emailSearchVal)){
                    if(String.isNotBlank(filter)){
                        filter = filter+' AND User.Email LIKE '+'\'%'+emailSearchVal+'%\''; 
                    }
                    else{
                        filter = ' Where User.Email LIKE '+'\'%'+emailSearchVal+'%\''; 
                    }
                }
                
                if(String.isNotBlank(profileSearchVal)){
                    if(String.isNotBlank(filter)){
                        filter = filter+' AND User.Profile.Name LIKE '+'\'%'+profileSearchVal+'%\''; 
                    }
                    else{
                        filter = ' Where User.Profile.Name LIKE '+'\'%'+profileSearchVal+'%\'';
                    }
                }
                
                if(String.isNotBlank(roleSeachVal)){
                    if(String.isNotBlank(filter)){
                        filter = filter+' AND User.UserRole.Name LIKE '+'\'%'+roleSeachVal+'%\''; 
                    }
                    else{
                        filter = ' Where User.UserRole.Name LIKE '+'\'%'+roleSeachVal+'%\''; 
                    }
                }
                
                if(String.isNotBlank(filter)){
                    query = 'SELECT Id, PresenceUserConfigId,PresenceUserConfig.MasterLabel, UserId, user.Name, user.UserProfile__c , user.UserRole__c FROM PresenceUserConfigUser'+filter+' LIMIT '+System.Label.User_Nesting_Manual_Limit;
                } 
                else{
                    query =  'SELECT Id, PresenceUserConfigId,PresenceUserConfig.MasterLabel, UserId, user.Name,user.UserProfile__c , user.UserRole__c FROM PresenceUserConfigUser Limit '+System.Label.User_Nesting_Manual_Limit;
                }
                system.debug('query.....'+query);
                system.debug('filter.....'+filter);
                pucuListToReturn = Database.query(query);
                system.debug('pucuListToReturn....'+pucuListToReturn.size());
            }
            return pucuListToReturn;
        }
        Catch(Exception ex){
            System.debug('Error Message....'+ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, NESTING_CLSNAME, PRESUSER_MTHD, LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
        
    }
    
    public class userNestingException extends Exception {
    }
    
}