/**
 * @author: Tia Xuan
 * @date: 04-2021
 * @description:  Queue Monitor V2 Controller
 */
public class CDdQueueMonitorController {
    // Queue for the cache 
    public static final String QM_CACHE_KEY = CDdSupportConstants.QUEUE_MONITOR_PREFIX + UserInfo.getUserId();
    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description initialize the queue monitor 
    */
    @AuraEnabled
    public static QueueMonitorWrapper initQM(){
        Support_Settings__c supportSetting = Support_Settings__c.getInstance();
        QueueMonitorWrapper wrp = new QueueMonitorWrapper();
        wrp.isLiveAgentUser = getLiveAgentPermission();
        wrp.queueMemberships = getCurrentQueueMembership();
        wrp.qmIntervalTime = supportSetting.QM_Interval_Time__c;
        wrp.qmIntervalCacheTime = supportSetting.QM_Interval_Cache_Time__c;
        return wrp;
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description get if queue membership has changed from cache, if so fetch queue memberships
    */
    @AuraEnabled
    public static String checkCurrentQueueMembership(String currentMemberships) {
        Boolean qmChange = (Boolean) CDdCacheService.getFromOrgCache(QM_CACHE_KEY);
        if (qmChange != null && qmChange){
            String memberships = getCurrentQueueMembership();

            if (currentMemberships != memberships){
                CDdCacheService.putInOrgCache(QM_CACHE_KEY, false);
                return memberships;
            }
        }
        return currentMemberships;
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description fetch queue memberships
    */
    @AuraEnabled
    public static String getCurrentQueueMembership() {
        List<ID> res = new List<ID>();

        List<String> queueIds = getQueueIds();

        for(GroupMember m : [select Id 
                            from GroupMember
                            where UserOrGroupId = :UserInfo.getUserId()
                            and GroupId =:queueIds]) {

            res.add(m.Id);
        }

        return String.join(res, ',');
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description get all Queue Management queues
    */
    @TestVisible
    private static List<String> getQueueIds() {
        List<QM_Queue_Setting__c> queues = QM_Queue_Setting__c.getAll().values();
        List<String> queueIdList = new List<String>();
        for (QM_Queue_Setting__c q : queues){
            queueIdList.add(q.Queue_Id__c);
        }
        return queueIdList;
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description is Live agent user
    */
    @TestVisible
    private static Boolean getLiveAgentPermission() {
        User u = [select Id, UserPermissionsLiveAgentUser from User where ID = :UserInfo.getUserId()];
        return u.UserPermissionsLiveAgentUser;
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description queue monitor wrapper class
    */
    public class QueueMonitorWrapper{
        @AuraEnabled
        public String queueMemberships {get; set;}

        @AuraEnabled
        public String currentUserId {get; set;}

        @AuraEnabled
        public Boolean isLiveAgentUser {get; set;}

        @AuraEnabled
        public Double qmIntervalTime {get; set;}
        
        @AuraEnabled
        public Double qmIntervalCacheTime {get; set;}

        public QueueMonitorWrapper(){
            this.currentUserId = UserInfo.getUserRoleId();
        }
    }
}