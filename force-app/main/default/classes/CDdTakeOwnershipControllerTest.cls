/**
 * 
 * @author: Tia Xuan
 * @date: 2021/02
 * @description test class for CDdTakeOwnershipController
 * 
 */
@isTest
public class CDdTakeOwnershipControllerTest {
    /**
    * @description test the TakeOwnership
    **/
    @isTest static void TakeOwnership_testMethod() {
        Case testCase = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        insert testCase;
               
        Test.startTest();

        CDdTakeOwnershipController.TakeOwnership(testCase.Id);
        Case cse = [select Id, OwnerId from Case where Id =: testCase.Id];
        System.assert(cse.OwnerId == userInfo.getUserId());
           
        Test.stopTest();
    }

}