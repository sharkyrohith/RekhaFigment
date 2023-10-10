/**
 * CDdProcessMxpAccountsBatchTest
 *
 * @author     Sahil
 * @date  2022-04-04
 * @decription Test class for CDdProcessMxpAccountsBatch
 */
@isTest(seeAllData=false)
public class CDdProcessMxpAccountsBatchTest {
    private static List<Account> accountsToInsert = new List<Account>();
    private static List<Load_Request_Item__c> mxpRecs = new List<Load_Request_Item__c>();
    private static List<User> testUserList = new List<User>();
    /**
    * @author     Sahil
    * @date  2022-04-04
    * @decription create test data
    * @param   None
    * @return  None
    */
    static void makeData() {
        accountsToInsert = TDdAccountFactory.createAccounts('testAcct', 4, 'Marketplace');
        insert accountsToInsert;
        Id opProfileId = [SELECT Id FROM Profile WHERE Name = 'Operations Team' LIMIT 1].Id;
        testUserList = [SELECT Id FROM User WHERE IsActive = TRUE AND ProfileId =:opProfileId LIMIT 4];
        List<AccountTeamMember> testAtmList = new  List<AccountTeamMember>();
        for (Integer i = 0; i < 3; i++) {
            AccountTeamMember atmObj = returnMXP(accountsToInsert[i].Id,testUserList[i].Id);
            testAtmList.add(atmObj);
        }
        insert testAtmList;
        //inserted accounts, fetched users and inserted atms. Now insert staging records
        mxpRecs = new List<Load_Request_Item__c>();
        for (Integer i = 0; i < 6; i++) {
            if (i == 0) {
                //delete existing ATM
                Load_Request_Item__c lriDeleteMxp = new Load_Request_Item__c();
                lriDeleteMxp.Account_ID__c = accountsToInsert[i].Id;
                lriDeleteMxp.User_ID__c = null;
                lriDeleteMxp.Operation__c = CDdSupportConstants.OPERATION_MXP_MAPPING;
                mxpRecs.add(lriDeleteMxp);
            } else if (i == 1) {
                //update existing ATM
                Load_Request_Item__c lriUpdMxp = new Load_Request_Item__c();
                lriUpdMxp.Account_ID__c = String.valueOf(accountsToInsert[i].Id);
                lriUpdMxp.User_ID__c = String.valueOf(testUserList[i+1].Id);
                lriUpdMxp.Operation__c = CDdSupportConstants.OPERATION_MXP_MAPPING;
                mxpRecs.add(lriUpdMxp);
            } else if (i == 2) {
                //same ATM, update account
                Load_Request_Item__c lriInsMxp = new Load_Request_Item__c();
                lriInsMxp.Account_ID__c = String.valueOf(accountsToInsert[i].Id);
                lriInsMxp.User_ID__c = String.valueOf(testUserList[i].Id);
                lriInsMxp.Operation__c = CDdSupportConstants.OPERATION_MXP_MAPPING;
                lriInsMxp.Error__c = true;
                mxpRecs.add(lriInsMxp);
            } else if (i == 3) {
                //invalid account
                Load_Request_Item__c lriInvAcc = new Load_Request_Item__c();
                lriInvAcc.Account_ID__c = String.valueOf(i);
                lriInvAcc.User_ID__c = String.valueOf(testUserList[i].Id);
                lriInvAcc.Operation__c = CDdSupportConstants.OPERATION_MXP_MAPPING;
                mxpRecs.add(lriInvAcc);
            } else if (i == 4) {
                //invalid user
                Load_Request_Item__c lriInvUsr = new Load_Request_Item__c();
                lriInvUsr.Account_ID__c = String.valueOf(accountsToInsert[2].Id);
                lriInvUsr.User_ID__c = String.valueOf(i);
                lriInvUsr.Operation__c = CDdSupportConstants.OPERATION_MXP_MAPPING;
                mxpRecs.add(lriInvUsr);
            }
        }
        insert mxpRecs;
    }

    /**
    * @author     Sahil
    * @date  2022-04-04
    * @decription test batch execution
    * @param   None
    * @return  None
    */
    @isTest
    static void testBatch() {
        makeData();
        Test.startTest();
        Database.executeBatch(new CDdProcessMxpAccountsBatch());
        Test.stopTest();

        //assert that MXP got deleted
        Account accFromDBDelMxp = [SELECT Id, (SELECT Id from AccountTeamMembers) FROM Account WHERE Id =:accountsToInsert[0].Id LIMIT 1];
        System.assertEquals(0, accFromDBDelMxp.AccountTeamMembers.size(), 'Team Members should be deleted');

        //assert MXP updated
        AccountTeamMember atmFromDBUpMxp = [SELECT UserId FROM AccountTeamMember WHERE AccountId =:accountsToInsert[1].Id LIMIT 1];
        System.assertEquals(testUserList[2].Id, atmFromDBUpMxp.UserId, 'Account Team Member Should be changed');

        //assert invalid account on staging object
        Load_Request_Item__c mxpLriErrAcc = [SELECT Error__c FROM Load_Request_Item__c WHERE Id =:mxpRecs[3].Id];
        System.assertEquals(true, mxpLriErrAcc.Error__c, 'Staging record should be marked as error');
    }

     /**
     * @author      Sahil Chaudhry
     * @date        2022-04-04
     * @decription  return account team member
     * @param       accountid and userid
     * @return      
    */
    private static AccountTeamMember returnMXP(Id accId, Id userId) {
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = accId;
        atm.UserId = userId;
        atm.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
        return atm;
    }
}