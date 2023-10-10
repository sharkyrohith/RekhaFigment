/**
 * @author Sugan
 * @date Feb 2022
 * @description Test class for EmailgeneratorServiceImpl
 */
@isTest
public with sharing class EmailGeneratorServiceImplTest {
    @isTest
    static void testEmailGeneratorService(){
        EmailGeneratorServiceImpl.isTestContext = true;
        Messaging.SingleEmailMessage testMail = new Messaging.SingleEmailMessage();
        testMail.subject = 'testingSubject';
        testMail.HTMLBody = 'Testing Body with test val TEST1';
        String updatedBody = 'Testing Body with test val TEST2';
        Map<String,String> mergeMAP = new Map<String,String>{'TEST1' => 'TEST2'};

        EmailGeneratorServiceImpl.testEmailMsg = testMail;
        Messaging.SingleEmailMessage emailResult = EmailGeneratorService.getEmailToSend('testTemplateId','testwhatId',new String[]{'test@test.com'}, mergeMap, true);
        System.assertEquals(emailResult.Subject, testMail.Subject, 'Email not prepped as expected');
        //the email generator also performs custom merging which is asserted below
        System.assertEquals(emailResult.HTMLBody, updatedBody,'Merging not happening as expected');
    }
    @isTest
    static void testCoverageForEmailWFAlert(){
        EmailGeneratorServiceImpl.isTestContext = true;
        Id caseId = Fake.generateId(Case.SObjectType);
        System.assertNotEquals(caseId, null);
        EmailGeneratorService.sendWFEmailAlert(caseId, 'Case', 'TEST_EMAIL_ALERT');
    }
}