/**
 * @author: Tia Xuan
 * @date: 04-2021
 * @description:  Queue Manager V2 Controller
 */
public without sharing class CDdQueueManagerController {

    // type for group object search
    static final String GROUP_TYPE_QUEUE = 'Queue';

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description get the list of roles and queues for filter criteria on page
    */
    @AuraEnabled
    public static QueueManagerWrapper getFilterCriteria(){
        QueueManagerWrapper wrp = new QueueManagerWrapper();
        wrp.roleList = getRoleFilter();
        wrp.queueList = getQueueFilter();
        return wrp;
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description search for users based on roles or emails, the active tab is used to see which list to fetch from
    */
    @AuraEnabled
    public static List<UserWrapper> getUsers(List<String> roles, List<String> emails,List<String> userIds, String activeTab) {
        Map<String,UserWrapper> resultMap = new Map<String,UserWrapper>();
        Set<ID> setQueueId = getQueueIds();
        String qry = '  select Id, Name, UserRole.Name, Email ';
        qry += '        from User ';
        qry += '        where IsActive = true ';
        if (activeTab  ==  'role'){
            qry += '        and UserRole.Name in :roles ';
        } else if(activeTab == 'file'){
            qry += '        and Email in :emails ';
        }else if(activeTab  ==  'refreshData' || !userIds.isEmpty()){
            qry += '        and  Id in :userIds ';
        }

        for(User u : Database.query(qry)) {
            UserWrapper wrp = new UserWrapper(u);
            resultMap.put(u.Id, wrp);
        }

        AggregateResult ag = [  select COUNT(Id)CountGM
                                from GroupMember
                                where UserOrGroupId in :resultMap.keySet()];

        Integer limitRows = Limits.getLimitQueryRows();

        if ((Integer)ag.get('CountGM') > limitRows){
            throw new CDdQueueManagerException('Too many group memberships are found, please narrow down your search');
        }
        for(GroupMember memb : [select Id, UserOrGroupId, Group.Name
                                from GroupMember
                                where UserOrGroupId in :resultMap.keySet()
                                and GroupId in :setQueueId
                                order By Group.Name
                                limit: limitRows]) {
            if (resultMap.containsKey(memb.UserOrGroupId)){
                UserWrapper wrp = resultMap.get(memb.UserOrGroupId);
                if(wrp != null) {
                    wrp.addQueue(memb.Group.Name);
                }
            }
        }

        return resultMap.values();
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description deletes all QM memberships for users passed in and then resubscribes them to the queues passed in
    */
    @AuraEnabled
    public static void updateQueues(List<String> userIds, List<String> queueList) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<OptionWrapper> queueOpts = getQueueFilter();
            Map<String, String> queueMap = new Map<String, String>();
            for (OptionWrapper opt : queueOpts){
                queueMap.put(opt.value, opt.label);
            }

            List<Queue_Manager_Audit__c> qmAuditToInsert = new List<Queue_Manager_Audit__c>();

            List<GroupMember> gmList = [select Id, UserOrGroupId, Group.Name, GroupId
                                        from GroupMember
                                        where UserOrGroupId in :userIds
                                            and GroupId in :queueMap.keySet()];
            for (GroupMember gm : gmList){
                Queue_Manager_Audit__c audit = new Queue_Manager_Audit__c();
                audit.User__c = gm.UserOrGroupId;
                audit.Removed_From_Queue_ID__c = gm.GroupId;
                if (queueMap.containsKey(gm.GroupId)){
                    audit.Removed_From_Queue_Name__c = queueMap.get(gm.GroupId);
                }
                qmAuditToInsert.add(audit);
            }
            delete gmList;

            List<GroupMember> membersToInsert = new List<GroupMember>();

            for(String uId : userIds) {
                for(String qId: queueList) {
                    GroupMember m = new GroupMember(
                        GroupId = qId,
                        UserOrGroupId = uId
                    );
                    membersToInsert.add(m);

                    Queue_Manager_Audit__c audit = new Queue_Manager_Audit__c();
                    audit.User__c = uId;
                    audit.New_Queue_ID__c = qId;
                    if (queueMap.containsKey(qId)){
                        audit.New_Queue_Name__c = queueMap.get(qId);
                    }
                    qmAuditToInsert.add(audit);
                }
            }

            if(membersToInsert.size() > 0) {
                insert membersToInsert;
                auditMembership(JSON.serialize(qmAuditToInsert));
            }
        } catch(Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description audits the queue memberships and also adds it to the org cache
    */
    @future
    private static void auditMembership(String auditsString){
        try {
            List<Queue_Manager_Audit__c> audits = (List<Queue_Manager_Audit__c>) JSON.deserialize(auditsString, List<Queue_Manager_Audit__c>.class);
            for (Queue_Manager_Audit__c qma : audits){
                CDdCacheService.putInOrgCache(CDdSupportConstants.QUEUE_MONITOR_PREFIX + qma.User__c, true);
            }

            if(audits.size() > 0) {
                insert audits;
            }
        } catch (Exception e){
            CDdErrorUtilities.publishException('CDdQueueManagerController','auditMembership',e);
        }
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description gets the role filter based on the QM Role setting custom setting
    */
    private static List<OptionWrapper> getRoleFilter(){
        List<OptionWrapper> resList = new List<OptionWrapper>();
        if (String.isNotBlank(UserInfo.getUserRoleId())){
            UserRole ur = [select Id, Name from UserRole where Id =: UserInfo.getUserRoleId()];
            List<QM_Role_Setting__c> roles = QM_Role_Setting__c.getAll().values();
            for (QM_Role_Setting__c rs : roles){
                if (rs.Parent_Role_Name__c == ur.Name){
                    OptionWrapper opt =  new OptionWrapper(rs.Role_Name__c, rs.Role_Name__c);
                    resList.add(opt);
                }
            }
        }
        resList.sort();
        return resList;
    }

    /**
     * @author: Ravali Tummala
     * @date: 08-2021
     * @description gets the queue filter based on the QM queue setting custom setting
    */
    @TestVisible
    private static Set<ID> getQueueIds() {
        Set<Id> setQueueId = new Set<Id>();
        List<OptionWrapper> queueOpts = getQueueFilter();
        Map<String, String> queueMap = new Map<String, String>();
        for (OptionWrapper opt : queueOpts){
            if(String.isNotBlank(opt.value)){
                setQueueId.add(opt.value);
            }
        }
        return setQueueId;
    }

    /**
     * @author: Tia Xuan
     * @date: 04-2021
     * @description gets the queue filter based on the QM queue setting custom setting
    */
    //thinking to remomve this setting and use queue management object to get the values????
    private static List<OptionWrapper> getQueueFilter(){
        List<QM_Queue_Setting__c> queues = QM_Queue_Setting__c.getAll().values();
        List<OptionWrapper> resList = new List<OptionWrapper>();
        for (QM_Queue_Setting__c q : queues){
            OptionWrapper opt =  new OptionWrapper(q.Name, q.Queue_Id__c,q.Queue_Id__c);
            resList.add(opt);
        }
        resList.sort();
        return resList;
    }

    // wrapper class for the options (role and queue)

    public class OptionWrapper implements Comparable {
        @auraEnabled
        public String label {get; set;}
        @auraEnabled
        public String value {get; set;}
        @auraEnabled
        public String id {get; set;}

        public OptionWrapper(String lbl, String val) {
            this.label = lbl;
            this.value = val;
        }

        public OptionWrapper(String lbl, String val,String id) {
            this.label = lbl;
            this.value = val;
            this.id = id;
        }

        public Integer compareTo(Object objToCompare) {
            return label.compareTo(((OptionWrapper)objToCompare).label);
        }
    }

    // wrapper class for Queue Manager initialization
    public class QueueManagerWrapper {
        @auraEnabled
        public List<OptionWrapper> roleList {get; set;}
        @auraEnabled
        public List<OptionWrapper> queueList {get; set;}
        @auraEnabled
        public String email {get; set;}
        @auraEnabled
        public String activeTab {get; set;}

        public QueueManagerWrapper() {
            this.email = '';
            this.activeTab = '';
        }
    }

    // wrapper class for user search result
    public class UserWrapper {
        @auraEnabled
        public String id {get; set;}
        @auraEnabled
        public String email {get; set;}
        @auraEnabled
        public String role {get; set;}
        @auraEnabled
        public String currentQueues { get { return String.join(this.queueList, ','); } }

        private List<String> queueList = new List<String>();

        public void addQueue(String queueName){
            queueList.add(queueName);
        }

        public UserWrapper(User usr) {
            this.id = usr.Id;
            this.email = usr.Email;
            this.role = usr.UserRole.Name;
        }
    }

    // exception class for Queue Manager
    public class CDdQueueManagerException extends Exception { }
}