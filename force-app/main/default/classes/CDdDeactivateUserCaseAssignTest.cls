/**
* @author CrticalRiver
* @date 2022-06
*
* @description Test class for CDdDeactivateUserCaseAssign
*/

@isTest
public class CDdDeactivateUserCaseAssignTest {

    @isTest static void testBatch() {

        Id previousQueueId=[SELECT ID FROM Group WHERE DeveloperName = :CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK].Id;
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Case> caseList = TDdCaseFactory.createCaseRecords(2,CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        for(Integer i = 0; i < caseList.size(); i++){
            caseList[i].Status = CDdSupportConstants.NEW_STATUS;
            caseList[i].ownerId=UserInfo.getUserId();
            if(i == 0){
                caseList[i].Previous_Queue_ID__c = previousQueueId;
                caseList[i].Previous_Queue__c = 'Test Queue';
            }
            if(i == 1){
                caseList[i].Initial_Queue__c = previousQueueId;
                caseList[i].Previous_Queue_ID__c = null;
            }
            caseRecordsToBeInserted.add(caseList[i]);
        }
         test.startTest();
        Insert caseRecordsToBeInserted;

        CDdDeactivateUserCaseAssign batch = new CDdDeactivateUserCaseAssign(new list<Id>{UserInfo.getUserId()});
        Database.executeBatch(batch);
        test.stopTest();
    }

    @isTest static void testBatchTabletCases() {

        Id previousQueueId=[SELECT ID FROM Group WHERE DeveloperName = :CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK].Id;
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Case> caseList = TDdCaseFactory.createCaseRecords(2,CDdSupportConstants.RECORDTYPE_NAME_TABLET_REQUESTS);
        for(Integer i = 0; i < caseList.size(); i++){
            caseList[i].ownerId=UserInfo.getUserId();
            if(i == 0){
                caseList[i].Status = CDdSupportConstants.RECEIVED_STATUS;
                caseList[i].Previous_Queue_ID__c = previousQueueId;
                caseList[i].Previous_Queue__c = 'Test Queue';
            }
            if(i == 1){
                caseList[i].Status = CDdSupportConstants.OPEN_STATUS;
                caseList[i].Initial_Queue__c = previousQueueId;
                caseList[i].Previous_Queue_ID__c = null;
            }
            caseRecordsToBeInserted.add(caseList[i]);
        }
         test.startTest();
        insert caseRecordsToBeInserted;

        CDdDeactivateUserCaseAssign batch = new CDdDeactivateUserCaseAssign(new list<Id>{UserInfo.getUserId()});
        Database.executeBatch(batch);
        test.stopTest();

        for(Case c:[SELECT Id,OwnerId,Status FROM Case WHERE CreatedDate=Today]){
            if(c.Status == CDdSupportConstants.RECEIVED_STATUS){
                System.assertEquals(c.OwnerId,UserInfo.getUserId(),'Ownerid should not change');
            }else{
                System.assertEquals(c.OwnerId,previousQueueId,'Ownerid should change');
            }
        }
    }
}