/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 11/29/2020
*
* @group Apex Jobs, Apex Test Class
*
* @description This Lightning Controller is to query and return apex job information as found in AsyncApexJob
* 
**************************************************************************************************************************************/
@isTest
public class CDdMyApexJobsControllerTest {

    @isTest
    public static void testGetMyApexJobs() {
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            try {
                Object retObj = CDdMyApexJobsController.getMyApexJobs(UserInfo.getUserId(), 'TestBatchJobClass');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }           
            Test.stopTest();
        }
    }
}