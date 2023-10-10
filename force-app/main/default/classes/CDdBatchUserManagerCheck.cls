public class CDdBatchUserManagerCheck implements Database.Batchable<sObject>, Schedulable {
 
    public void execute(SchedulableContext sc) {
        Set<String> runningStatus = new Set<String> {'Holding', 'Processing', 'Queued', 'Preparing'};
        ApexClass thisClass = [SELECT Id FROM ApexClass WHERE Name = 'CDdBatchUserManagerCheck' LIMIT 1];
        AsyncApexJob[] runningJobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClassId = :thisClass.Id
            AND Status IN :runningStatus
        ];
        if (runningJobs.size() == 0) {
            CDdBatchUserManagerCheck batch = new CDdBatchUserManagerCheck();
            Database.executeBatch(batch, CDdCustomMetadata.getBatchSize('CDdBatchUserManagerCheck'));
        }
    }
 
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, ManagerId, Manager_Id__c, Manager_Valid__c FROM User WHERE Manager_Valid__c = \'Fix\'';
        if (test.isRunningTest()) query += ' AND LastName LIKE \'TestUser%\'';
        Database.QueryLocator ql = Database.getQueryLocator(query);
        return ql;
    }
    
    public void execute(Database.BatchableContext BC, List<User> scope) {
        // Obtain Manager IDs
        Set<String> ManagerIDs = new Set<String>();
        for (User u : scope) if ((u.Manager_ID__c != null) && (u.Manager_ID__c != '')) ManagerIDs.add(u.Manager_Id__c);
        Map<String, User> Managers = new Map<String, User>();
        for (User u : [SELECT Id, Bamboo_Employee_Id__c FROM User WHERE Bamboo_Employee_Id__c IN :ManagerIDs])
            Managers.put(u.Bamboo_Employee_Id__c, u);
        // Determine User Updates
        List<User> usersToUpdate = new List<User>();
        for (User u : scope) {
            if ((u.Manager_Id__c != null)
            &&  (u.Manager_ID__c != '')
            &&  (Managers.get(u.Manager_Id__c) != null)) {
                usersToUpdate.add(new User(Id = u.Id, ManagerId = Managers.get(u.Manager_Id__c).Id));
            }
        }
        // Make User Updates
        if (usersToUpdate.size() > 0) update usersToUpdate;
    }
    
    public void finish(Database.BatchableContext BC) {
        // Nothing to do in the finish method ...
    }
}