/**
* @author Knick
* @date 2020-06
*
* @description Test class for CDdBatchUserManagerCheck
*/

@isTest
public class CDdBatchUserManagerCheckTest {

    public static User manager;
    public static User user1;
    public static User user2;

    static {
        List<User> users = TDdAccountFactory.createUsers(3, null, null);
        manager = users[0];
        user1 = users[1];
        user2 = users[2];
        manager.Bamboo_Employee_Id__c = 'Bamboo';
        insert manager;
        user1.Manager_Id__c = 'Bamboo';
        insert user1;
        user2.Manager_Id__c = 'No Manager';
        user2.ManagerId = user1.Id;
        insert user2;
    }

    @isTest static void testBatch() {

        User checkUser;
        checkUser = [SELECT Manager_Valid__c FROM User WHERE Id = :user1.Id];
        system.assertEquals('Fix', checkUser.Manager_Valid__c, 'The initial state of user1 should be Fix.');
        checkUser = [SELECT Manager_Valid__c FROM User WHERE Id = :user2.Id];
        system.assertEquals('Fix', checkUser.Manager_Valid__c, 'The initial state of user2 should be Fix.');

        Test.startTest();            
            CDdBatchUserManagerCheck batch = new CDdBatchUserManagerCheck();
            SchedulableContext sc = null;
            batch.execute(sc);
        Test.stopTest();
        
        checkUser = [SELECT Manager_Valid__c, ManagerId FROM User WHERE Id = :user1.Id];
        system.assertEquals('Good', checkUser.Manager_Valid__c, 'The final state of user1 should be Good.');
        system.assertEquals(manager.Id, checkUser.ManagerId, 'User1 should now have ManagerId manager');
        checkUser = [SELECT Manager_Valid__c, ManagerId FROM User WHERE Id = :user2.Id];
        system.assertEquals('Fix', checkUser.Manager_Valid__c, 'The final state of user2 should be Fix.');
        system.assertEquals(user1.Id, checkUser.ManagerId, 'User2 should still have ManagerId user1');
       
    }

}