public without sharing class VQueueManagementController {
    public VQueueManagementController() {
        
    }

    @TestVisible
    private static GetUserResult createUserResult(User u) {
        GetUserResult gur = new GetUserResult();
        gur.userId = u.Id;
        gur.isChecked = false;
        gur.userName = u.Email;
        gur.roleName = u.UserRole.Name;
        return gur;
    }

    @TestVisible
    private static Map<ID, QMRoleSetting__mdt> getQueueSettings() {
        Map<ID, QMRoleSetting__mdt> res = new Map<ID, QMRoleSetting__mdt>();

        // Tia Xuan 03/01/2021 replace for SOQL limit error
        /*for(QMRoleSetting__mdt m : [select Id, DeveloperName, MasterLabel, QueueRoleId__c, ViewAllUsers__c,
            IsSupervisorRole__c
            from QMRoleSetting__mdt]) {*/
        for(QMRoleSetting__mdt m : QMRoleSetting__mdt.getall().values()) {
            res.put(m.QueueRoleId__c, m);
        }

        return res;
    }

    @TestVisible
    private static Set<ID> getQueueIds() {
        Set<ID> res = new Set<ID>();

        // Tia Xuan 03/01/2021 replace for SOQL limit error
        /*for(QMQueueSetting__mdt m : [select Id, QueueId__c
            from QMQueueSetting__mdt]) {*/
        for(QMQueueSetting__mdt m : QMQueueSetting__mdt.getall().values()) {        
            res.add(m.QueueId__c);
        }

        return res;
    }

    @RemoteAction
    public static List<QMQueueSetting__mdt> getQueues() {
        
        // Tia Xuan 03/01/2021 replace for SOQL limit error
        /*return [select Id, MasterLabel, DeveloperName, QueueId__c
            from QMQueueSetting__mdt];*/
        return  QMQueueSetting__mdt.getall().values();
    }

    @RemoteAction
    public static List<UserRole> getUserRoles() {
       return [select Id, Name from UserRole order by Name ASC];
    }

    @RemoteAction
    @ReadOnly
    public static List<GetUserResult> getUsers(List<String> roles) {
        Map<ID, QMRoleSetting__mdt> queueSettings = getQueueSettings();
        Set<ID> queues = getQueueIds();

        List<GetUserResult> res = new List<GetUserResult>();
        Map<ID, GetUserResult> resultMap = new Map<ID, GetUserResult>();

        /*for(User u : [select Id, Name, UserRole.Name, Email 
                from User
                where UserRole.ParentRoleId = :UserInfo.getUserRoleId()
                and IsActive = true]) {

            GetUserResult gur = createUserResult(u);
            resultMap.put(u.Id, gur);
            res.add(gur);
        }*/

        //QMRoleSetting__mdt qs = queueSettings.get(UserInfo.getUserRoleId());

        //if(qs != null && qs.ViewAllUsers__c) {
        //Set<ID> userRoleIds = new Set<ID>();

        // Tia Xuan 03/01/2021 replace with sub role hierarchy
        /*for(UserRole role : [select Id
            from UserRole
            where ParentRoleId in :queueSettings.keySet()]) {
            userRoleIds.add(role.Id);
        }*/
        //userRoleIds = getAllSubRoleIds(new Set<Id>{UserInfo.getUserRoleId()});

        for(User u : [select Id, Name, UserRole.Name, Email
            from User
            where UserRoleId in :roles
            and IsActive = true]) {

            if(!resultMap.containsKey(u.Id)) {
                GetUserResult gur = createUserResult(u);
                resultMap.put(u.Id, gur);
                res.add(gur);
            }
        }
        //}

        for(GroupMember memb : [select Id, UserOrGroupId, Group.Name
            from GroupMember
            where UserOrGroupId in :resultMap.keySet()
            and GroupId in :queues
            order By Group.Name]) {

            GetUserResult gur = resultMap.get(memb.UserOrGroupId);
            if(gur != null) {
                gur.addQueue(memb.Group.Name);
            }
        }

        for(GetUserResult gur : res) {
            gur.completeQueues();
        }

        return res;
    }

    @RemoteAction
    public static void updateQueues(List<String> userIds, List<String> queueIds) {
        Savepoint sp = Database.setSavepoint();

        try {
            Set<ID> groupIds = getQueueIds();

            delete [select Id from GroupMember where UserOrGroupId in :userIds and GroupId in :groupIds];

            List<GroupMember> membersToInsert = new List<GroupMember>();

            for(String uId : userIds) {
                for(String qId : queueIds) {
                    GroupMember m = new GroupMember(
                        GroupId = qId,
                        UserOrGroupId = uId
                    );

                    membersToInsert.add(m);
                }
            }

            if(membersToInsert.size() > 0) {
                insert membersToInsert;
            }
        } catch(Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }

    private class GetUserResult {
        public Boolean isChecked;
        public ID userId;
        public String userName;
        public String queueNames;
        public String roleName;

        private List<String> queueList = new List<String>();

        public void addQueue(String queueName) {
            queueList.add(queueName);
        }

        public void completeQueues() {
            queueNames = String.join(queueList, ', ');
        }
    }

    /*
    keeping this for now but commenting this out since not in use for test coverage.
    
    private static Map<Id, UserRole> getAllSubRoleIds(Map<Id,UserRole> roleIds) {

        Map<Id, UserRole> currentRoles = new Map<Id, UserRole>();
    
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id, Name from UserRole where ParentRoleId 
             IN :roleIds.keySet() AND ParentRoleID != null]) {
                currentRoles.put(userRole.Id, userRole);
        }
    
        // go fetch some more rolls!
        if(currentRoles.size() > 0) {
            currentRoles.putAll(getAllSubRoleIds(currentRoles));
        }
    
        return currentRoles;
    }*/
}