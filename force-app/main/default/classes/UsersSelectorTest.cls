/**
 * @description Test Class for UsersSelector class
 * @author Mahesh Chouhan
 * @date Nov 2022
 */

@isTest
public class UsersSelectorTest {

    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name =: CDdSupportConstants.PROFILE_SYS_ADM].Id;
    }

    @TestSetup
    static void testSetup(){
        List<User> users = TDdUserFactory.createUsers(1, SYSTEM_ADMIN_PROFILE_ID, TEST_ROLE_ID, false);
        users[0].Username = TEST_DD_RUN_USERNAME;
        insert users;
    }

    /**
     * @description Test method for selectByNameEmailProfileRole method
     */
    @isTest
    static void testSelectByNameEmailProfileRole(){
        List<User> result = UsersSelector.newInstance().selectByNameEmailProfileRole('TestUser','','','COO',10);
        System.assertEquals(1, result.size(), 'No User found on selecting by where Clause');
    }
    
    /**
     * @description Test method for selectById method
     */
    @isTest
    static void testSelectById(){
        List<User> users = [SELECT Id FROM User WHERE Username =: TEST_DD_RUN_USERNAME];
        List<User> result = UsersSelector.newInstance().selectById(new Set<Id>{users[0].Id});
        System.assertEquals(1, result.size(), 'No User found on selecting by User Id');
    }
     /**
     * @description Test method for selectUserIdsByEmailAddress
     */
    @isTest
    static void testSelectUserIdsByEmailAddress(){
        List<User> users = [SELECT Id,email FROM User WHERE Username =: TEST_DD_RUN_USERNAME];
        List<User> result = UsersSelector.newInstance().SelectUserIdsByEmailAddress(new Set<String>{users[0].email});
        System.assertEquals(1, result.size(), 'No User found on selecting by User Email');
    }
}