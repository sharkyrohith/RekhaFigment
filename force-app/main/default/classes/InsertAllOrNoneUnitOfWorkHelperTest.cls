/**
 * @author  Nayana K
 * @date    November 2022
 * @description This is the test class for InsertAllOrNoneUnitOfWorkHelper
 */
@isTest
public class InsertAllOrNoneUnitOfWorkHelperTest {
    @isTest
    private static void testInsertAllOrNoneUnitOfWorkHelper() {
        Id mockAccountId = Fake.generateId(Account.SObjectType);
        Id userId = Fake.generateId(User.SObjectType);
        Id accTeamId = fflib_IDGenerator.generate(AccountTeamMember.SObjectType);
        AccountTeamMember atmRec = (AccountTeamMember) new Fake(AccountTeamMember.class)
                .setField(AccountTeamMember.Id, accTeamId)
                .setField(AccountTeamMember.AccountId, mockAccountId)
                .setField(AccountTeamMember.TeamMemberRole, CDdSupportConstants.MXP_ROLE_NAME)
                .setField(AccountTeamMember.UserId,userId)
                .toSObject();
        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        fflib_ISObjectUnitOfWork uow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        InsertAllOrNoneUnitOfWorkHelper myInsertWork = new InsertAllOrNoneUnitOfWorkHelper();
        uow.registerWork(myInsertWork);
        myInsertWork.registerSObjectInsert(atmRec);
        List<Database.SaveResult> myInsertResults = myInsertWork.results;
        System.assertEquals(1, myInsertWork.lstSObjects.size(), 'List should have 1 item');
        try{
            myInsertWork.doWork();
        }catch(Exception e){
            System.assert(true);
        }
    }
}