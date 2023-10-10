/**
 * cDdRejectedUsersReasonControllerTest
 *
 * @author     Shiva
 * @date  2020-04-16
 * @decription Test class for cDdRejectedUsersReasonController
 */
@isTest
public class cDdRejectedUsersReasonControllerTest {
    /**
    * @author     Shiva
    * @date  2020-04-16
    * @decription test data setup for this test class
    * @param   None
    * @return  None
    */
    @testSetup
    static void createUserReviews() {
        //creating user review records in pending status
        User_Review__c ur = new User_Review__c();
        ur.User_Reviewed__c = UserInfo.getUserId();
        ur.Approval_Status__c = 'Pending';
        ur.Name = 'Test UR';
        insert ur;
        
    }
    /**
    * @author     Shiva
    * @date  2020-04-16
    * @decription test method for testing methods in cDdRejectedUsersReasonController
    * @param   None
    * @return  None
    */
    @isTest
    static void testApprovalStatus(){
        
        User_Review__c ur = [select id from User_Review__c limit 1];
        cDdRejectedUsersReasonController.saveUserReviewStatus(ur.Id,'Rejected');
        ur = [select id,Approval_Status__c from User_Review__c limit 1];
        System.assertEquals(ur.Approval_Status__c, 'Rejected');
        cDdRejectedUsersReasonController.saveUserReviewReason(ur.Id,'Not my Report');
        ur = [select id,Approval_Status__c,Rejected_Reason__c from User_Review__c limit 1];
        System.assertEquals(ur.Rejected_Reason__c, 'Not My Report');
        
    }
}