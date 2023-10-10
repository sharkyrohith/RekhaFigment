/**
  * @author:Mahesh C
  * @date  08/05/2021
  * @decription: Test class of Handler for User Nesting Platform Event.
  */
  @isTest
  public class CDdUserNestingPlatformEventHelperTest {
  
      /**
      * @author:Mahesh C
      * @description This method is to test the User Nesting Platform Event for Manual Add or Remove
      **/
      @isTest
      public static void testUserNestingPlatformEvent() {
          Test.startTest();
          CDdUserNestingPlatformEventHelper.publishEvent(new List<PresenceUserConfigUser>{}, new List<Id>{});
          Test.getEventBus().deliver();
          Test.stopTest();
          List<AsyncApexJob> queuedJobs = [SELECT ApexClass.Name, Id, JobItemsProcessed, JobType, Status, NumberOfErrors, MethodName 
                                          FROM AsyncApexJob];
          
          System.assertEquals(1, queuedJobs.size(), 'Queueable Job is not scheduled as expected.');
          System.assertEquals('CDdPresenceConfigQueueable', queuedJobs[0].ApexClass.Name, 'CDdPresenceConfigQueueable Job is not scheduled as expected.');
      }
      
      /**
      * @author:Mahesh C
      * @description This method is to test the User Nesting Platform Event for Bulk Add or Remove
      **/
      @isTest
      public static void testUserNestingPlatformEventWithBulkUpload() {
          Blob bodyBlob=Blob.valueOf('UserId,PresenceUserConfigId,Action\n 0051a000002KDEbAAO,0Nd2L000000GnVFSA0,Remove'); 
          
          ContentVersion bulkUploadFile = new ContentVersion(
              Title='BulkUpload', 
              PathOnClient ='BulkUpload.csv',
              VersionData = bodyBlob
          );
          insert bulkUploadFile;
          
          List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
          
          Test.startTest();
          CDdUserNestingPlatformEventHelper.publishEvent(documents[0].Id);
          Test.getEventBus().deliver();
          Test.stopTest();
          List<AsyncApexJob> queuedJobs = [SELECT ApexClass.Name, Id, JobItemsProcessed, JobType, Status, NumberOfErrors, MethodName 
                                           FROM AsyncApexJob];
          
          System.assertEquals(1, queuedJobs.size(), 'Queueable Job is not scheduled as expected.');
          System.assertEquals('CDdPresenceConfigQueueable', queuedJobs[0].ApexClass.Name, 'CDdPresenceConfigQueueable Job is not scheduled as expected.');
      }
  }