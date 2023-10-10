/**
* @author Tia Xuan
* @date 2022-03
*
* @description Test class for CDdAttachmentTriggerHandler
*/
@isTest
public class CDdAttachmentTriggerTest {

    /**
	* @description test treatFormstackPhotoAttachment
	*/
	@isTest static void testTreatFormstackPhotoAttachment() {

        Test.startTest();
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Account', 1);
        insert accounts;

        List<Case> cases = TDdCaseFactory.createCaseRecords(1, 'Support');
        cases[0].Origin = 'Chat';
        cases[0].AccountId = accounts[0].Id;
        insert cases;

        Attachment a = new Attachment();
        a.ParentId = cases[0].Id;
        a.Body = Blob.valueOf('test');
        a.Name = CDdAttachmentTriggerHandler.GOOGLE_DRIVE_URL + CDdAttachmentTriggerHandler.DOWNLOAD_LINK_PORTION;
        insert a;

        Attachment attAfter = [ select Id, Name, Description
                                from Attachment
                                where Id =: a.Id];
        System.assert(attAfter.Name.contains('Test Account 0 - Chat'), 'Name contains Origin and account');
        System.assert(attAfter.Description == CDdAttachmentTriggerHandler.GOOGLE_DRIVE_URL, 'Description should be the same as name');

        Test.stopTest();
    }
}