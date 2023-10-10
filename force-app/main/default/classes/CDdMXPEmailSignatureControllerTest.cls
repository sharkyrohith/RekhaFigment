/**
 * @author Mahesh Chouhan
 * @date Jan 2022
 * @description Test class for controller of CDdMXPEmailSignature Visualforce Component
 */

@isTest
public class CDdMXPEmailSignatureControllerTest {

    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
     *****************************************************************************************************************************/
    private static final Map<String, Schema.RecordTypeInfo> ACCOUNT_RECTYPE_MAP = Account.SobjectType.getDescribe().getRecordTypeInfosByName();

    /*****************************************************************************************************************************
     *
     * Public/Global Variables
     *
     *****************************************************************************************************************************/
    public static final Id ACCOUNT_RECORDTYPE_ID = ACCOUNT_RECTYPE_MAP.get(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE).getRecordTypeId();
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

    static {
        TEST_ROLE_ID = TDdUserFactory.getUserRole('COO');
    }
    
    /** 
     * @description Prepare and return the test running user with System Admin Profile
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        for(User u : [ SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if(testRunUser == null){
            testRunUser = TDdUserFactory.createUsers(1, null, TEST_ROLE_ID, false)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    /** 
     * @description Prepare test data
     */ 
    @testSetup
    static void testSetUpData(){
        List<User> testUsers = TDdUserFactory.createUsers(1);
        testUsers[0].Signature = 'Kind Regards,\n TestUser 0';
        insert testUsers;
        System.runAs(getTestRunUser()){
            List<Account> accList = CDdTestDataFactory.createSObjectList('Account', 1, false);
            for(Integer index = 0; index < accList.size(); index++){
                if(index == 0){
                    accList[index].Name = 'Test Acc';
                    accList[index].phone = '0256157848';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].Case_Routing_Override__c = 'Mx Success Associate Queue';
                    accList[index].Market_Area__c = 'Northern California - East Bay';
                    accList[index].Business_ID__c = 123456;
                    accList[index].Formstack_Version__c = 'New Store';
                    accList[index].RecordTypeId = ACCOUNT_RECORDTYPE_ID;
                }
            }
            insert accList;
            
            AccountTeamMember accTeamMember= new AccountTeamMember();
            accTeamMember.AccountId = accList[0].Id;
            accTeamMember.UserId = testUsers[0].Id;
            accTeamMember.TeamMemberRole = 'MXP';
            insert accTeamMember;
        }
    }

    /**
     * @description Test method for getUserSignature method
     */
    @isTest
    static void testGetUserSignature(){
        List<Account> testAccounts = [SELECT ID FROM Account];
        CDdMXPEmailSignatureController emailSignatureController = new CDdMXPEmailSignatureController();
        emailSignatureController.accountId = testAccounts[0].Id;

        String userSignature = emailSignatureController.getUserSignature();
        System.assertEquals('Kind Regards,<br/> TestUser 0', userSignature, 'MXP User Email Signature is not same as expected.');
    }
}