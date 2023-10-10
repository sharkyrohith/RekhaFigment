/**
  * @author:Narender K
  * @date  07/14/2021
  * @decription: This class is used as helper class to CDdUserNestingCtrl class.
  */
public class CDdBulkAPIUtility {
    public static final String ERROR_MESSAGE  = 'There is an error in uplaoding csv file, Please uplaod once again or contact system admin.';
    public static final String SUCCESS_MESSAGE  = 'We have processed the sheet for nesting.';
    public static final String INVALID_USER_ID  = 'User id Invalid on row';
    public static final String INVALID_PRESENCEUSERCONFIG_ID  = 'PresenceUserConfig id Invalid on row';
    public static final String INVALID_ACTION  = 'Action is Invalid on row';
    public static final String ADD_LABEL  = 'Add';
    public static final String REMOVE_LABEL  = 'Remove';
    public static final String MAXIMUM_LABEL  = 'Maximum ';
    public static final String MAXIMUM_LIMIT_LABEL  = ' rows can be processed in single time.';
    public static final String BLK_API_CLSNAME = 'CDdBulkAPIUtility';
    public static final String IMPT_BLK_DATA_MTHD = 'importBulkdata';
    public static final String ADD_USER_TO_CHNL_MTHD = 'addUserToChannelData';

   /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: imports bulk data from the uplaoded content document from lwc component
    * @param   Id content document Id
    * @return  Map of List of strings to indicate if any errors in uplaoded csv file
    */
    public static Map<String,List<String>> importBulkdata(Id conId, Boolean onlyValidateDocument) {
        System.debug('conId.....'+conId);
        Map<String,List<String>> resRetMap = new Map<String,List<String>>();
        try{
            if(conId == null){ 
                resRetMap.put(CDdSupportConstants.ERROR_LABEL,New List<string>{ERROR_MESSAGE});
                return resRetMap;
            } else {
            ContentVersion objVersion = [
                SELECT Id, VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId =:conId];
            // split the file data
            list<String> lstCSVLines = objVersion.VersionData.toString().split('\n');
            system.debug('lstCSVLines.....'+lstCSVLines.size());
            if(lstCSVLines.size()>Integer.valueOf(System.Label.Maximum_Records_Processed)){
                resRetMap.put(CDdSupportConstants.ERROR_LABEL,New List<string>{MAXIMUM_LABEL+System.Label.Maximum_Records_Processed+MAXIMUM_LIMIT_LABEL}); 
                Delete [SELECT ID 
                        FROM contentDocument 
                        WHERE ID =: conId]; 
                return resRetMap;
            }
            List<PresenceUserConfigUser> preconfigUserList = new List<PresenceUserConfigUser>();
            List<Id> systemUserIdLst = new List<Id>();
            Integer rowNumber;
            for(Integer i = 1; i < lstCSVLines.size(); i++){
                rowNumber = i;
                list<String> csvRowData = lstCSVLines[i].split(',');
                Id preUserConfigId= Id.valueOf(csvRowData[1].trim());
                Id userId= Id.valueOf(csvRowData[0].trim());
                String action = csvRowData[2].trim();
                if(userId.getSObjectType().getDescribe().getName()!=CDdSupportConstants.USER_OBJECT_LABEL){
                    if(resRetMap.containskey(CDdSupportConstants.ERROR_LABEL)){
                        resRetMap.get(CDdSupportConstants.ERROR_LABEL).add(INVALID_USER_ID+i);
                    }else{
                        resRetMap.put(CDdSupportConstants.ERROR_LABEL,New List<string>{INVALID_USER_ID+i}); 
                    }
                }
                if(preUserConfigId.getSObjectType().getDescribe().getName()!=CDdSupportConstants.PRESENCEUSERCONFIG_OBJECT_LABEL){
                    if(resRetMap.containskey(CDdSupportConstants.ERROR_LABEL)){
                        resRetMap.get(CDdSupportConstants.ERROR_LABEL).add(INVALID_PRESENCEUSERCONFIG_ID+i);
                    }else{
                        resRetMap.put(CDdSupportConstants.ERROR_LABEL,New List<string>{INVALID_PRESENCEUSERCONFIG_ID+i}); 
                    }  
                }
                if(!action.equalsIgnoreCase(CDdSupportConstants.INSERT_LABEL) && !action.equalsIgnoreCase(CDdSupportConstants.DELETE_LABEL) &&
                   !action.equalsIgnoreCase(ADD_LABEL) && !action.equalsIgnoreCase(REMOVE_LABEL)){
                       if(resRetMap.containskey(CDdSupportConstants.ERROR_LABEL)){
                           resRetMap.get(CDdSupportConstants.ERROR_LABEL).add(INVALID_ACTION+i);
                       }else{
                           resRetMap.put(CDdSupportConstants.ERROR_LABEL,New List<string>{INVALID_ACTION+i}); 
                       }  
                   }
                PresenceUserConfigUser puserConfig = new PresenceUserConfigUser();
                systemUserIdLst.add(userId);
                if(action.equalsIgnoreCase(CDdSupportConstants.INSERT_LABEL) || action.equalsIgnoreCase(ADD_LABEL)){
                    puserConfig.UserId = userId;
                    puserConfig.PresenceUserConfigId = preUserConfigId;
                    preconfigUserList.add(puserConfig); 
                }
            }
            if(!resRetMap.containsKey(CDdSupportConstants.ERROR_LABEL)){
                resRetMap.put(CDdSupportConstants.SUCCESS_LABEL, New List<string>{SUCCESS_MESSAGE});
            }
            if(!onlyValidateDocument && resRetMap.containsKey(CDdSupportConstants.SUCCESS_LABEL)){
                System.enqueueJob(new CDdPresenceConfigQueueable(preconfigUserList,systemUserIdLst));
                Delete [SELECT ID 
                FROM contentDocument 
                WHERE ID =: conId];
            }
            }
        }
        Catch(Exception ex){
            resRetMap.put(CDdSupportConstants.ERROR_LABEL, New List<string>{ex.getMessage()});
            system.debug('Error....'+ex.getMessage()+'Line.....'+ex.getLineNumber());
            CDdErrorUtilities.createApexLogs(resRetMap.get(CDdSupportConstants.ERROR_LABEL), BLK_API_CLSNAME, IMPT_BLK_DATA_MTHD, LoggingLevel.ERROR);
        }
        return resRetMap;
    }
    
   /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: adding users to channel(PresenceUserConfig)
    * @param   User List and PresenceUserConfig Id 
    * @return  None
    */ 
    public static boolean addUserToChannelData(List<User>userList , string channelIdStr) {
        System.debug('userList.....'+userList.size()+'   channelIdStr.....'+channelIdStr);
        List<PresenceUserConfigUser> presUserConfigUserList = new List<PresenceUserConfigUser>();
        List<Id> selectedUserIdlst = new List<Id>();
        boolean result = false;
        try{
            if(String.isBlank(channelIdStr)){
                return result;
            }else {
                PresenceUserConfig preconfig= [
                    Select Id 
                    From PresenceUserConfig 
                    where DeveloperName=:channelIdStr];
                // split the file data
                for(User us : userList){
                    PresenceUserConfigUser presUserConfigUserRec = new PresenceUserConfigUser();
                    selectedUserIdlst.add(us.id);
                    presUserConfigUserRec.UserId = us.id;
                    presUserConfigUserRec.PresenceUserConfigId = preconfig.Id;
                    presUserConfigUserList.add(presUserConfigUserRec);
                }
                system.debug('selectedUserIdlst.....'+selectedUserIdlst.size()+'   presUserConfigUserList.....'+presUserConfigUserList.size());
                CDdUserNestingPlatformEventHelper.publishEvent(presUserConfigUserList, selectedUserIdlst);
                result = true;
            }
        }
        Catch(Exception ex){
            System.debug('Error Message....'+ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, BLK_API_CLSNAME, ADD_USER_TO_CHNL_MTHD, LoggingLevel.ERROR);
        }
        return result;
    }
    
}