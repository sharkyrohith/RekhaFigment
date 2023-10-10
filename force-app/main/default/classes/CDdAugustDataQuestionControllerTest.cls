/**
 * @author Mahesh Chouhan
 * @date 2022-08
 *
 * @description Test class for CDdAugustDataQuestionController
*/

@isTest
public class CDdAugustDataQuestionControllerTest {

    public static final Id TEST_ROLE_ID;

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        2022-08
     * @description Data setup method
     */
    @testSetup
    static void testSetup() {
        Account account = TDdAccountFactory.createAccounts('Test Person Account', 1, 'Consumer or Dasher')[0];
        account.Phone = '1234567891';
        account.PersonEmail = 'test@test.com';
        insert account;

        August_Data_Question__c adq = new August_Data_Question__c(Email__c = 'test@test.com', Phone__c = '1234567891');
        insert adq;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        2022-08
     * @description test method for checkAccountImpact with Exception
     */
    @isTest
    static void testCheckAccountImpactException() {
        List<Account> accounts = [SELECT ID FROM Account];
        Boolean isAccountImpacted;
        Boolean exceptionThrown;
        try{
            isAccountImpacted = CDdAugustDataQuestionController.checkAccountImpact(accounts[0].Id);
        }
        catch(Exception ex){
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception should be thrown as expected.');
    }

    /**
     * @author      Mahesh Chouhan
     * @date        2022-08
     * @description test method for checkAccountImpact
     */
    @isTest
    static void testCheckAccountImpactPositive() {
        User testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
        insert testRunUser;

        List<PermissionSet> augustDataQuestionPS = [SELECT ID FROM PermissionSet WHERE Name = :CDdAugustDataQuestionController.AUGUST_DATA_QUESTION_PS];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testRunUser.Id, PermissionSetId = augustDataQuestionPS[0].Id);
        insert psa;

        List<Account> accounts = [SELECT ID FROM Account];
        Boolean isAccountImpacted;
        System.runAs(testRunUser){
            isAccountImpacted = CDdAugustDataQuestionController.checkAccountImpact(accounts[0].Id);
        }
        System.assert(isAccountImpacted, 'Account Email or Phone is not present in August Data Question record.');
    }
}