/* Created by Veltig Consulting
 * Copyright 2017
 * 
 */
@isTest
public class vNewCaseFromEmailTest {
    
    static testMethod void vNewCaseFromEmailTest(){
        
        User u = [SELECT Id FROM User WHERE Id =: System.UserInfo.getUserId()];
        RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND IsActive = true LIMIT 1];
        
        Case c = new Case();
        c.Origin = 'Email';
        c.Priority = 'Normal';
        c.Status = 'Closed';
        c.Customer_Type__c = 'Consumer';
        c.Subject = 'Test';
        c.Issue__c = 'Other';
        c.Issue_Type__c = 'Other - CX';
        c.Resolution__c = 'Other';
        c.Resolution_Type__c = 'Other - CX';
        c.Description = 'Test';
        c.SuppliedName = 'Test Name';
        c.SuppliedEmail = 'sfadmin+test@veltig.com';
        
        insert c;
        
        //Messaging.InboundEmail email = new Messaging.InboundEmail();
        //Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        //Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();

        //Messaging.EmailAttachment emAttachment = new Messaging.EmailAttachment();
        //emAttachment.
        
        EmailMessage em = new EmailMessage();
        em.FromAddress = 'sfadmin+test@veltig.com';
       	em.FromName = 'Test Name';
        em.Incoming = True;
        em.Subject = 'Test Subject';
        em.HtmlBody = 'Test';
        em.TextBody = 'Test';
        em.ParentId = c.Id;
        em.Status = '0';
        em.ToAddress = 'sfadmin+test@veltig.com';
        
        insert em;
        
        Attachment a = new Attachment();
        a.ParentId = em.Id;
        a.Name = 'Test Attachment';
        a.Body = Blob.valueOf('Test');
        a.ContentType = 'plain/txt';
        
        Insert a;
        
        SET<Id> setIds = new SET<Id>();
        
        EmailMessage em2 = new EmailMessage();
        em2.FromAddress = 'sfadmin+test@veltig.com';
       	em2.FromName = 'Test Name';
        em2.Incoming = True;
        em2.Subject = 'Test Subject';
        em2.HtmlBody = 'Test';
        em2.TextBody = 'Test';
        em2.ParentId = c.Id;
        em2.Status = '0';
        em2.ToAddress = 'sfadmin+test@veltig.com';
        em2.ReplyToEmailMessageId = em.Id;
        
        insert em2;
        
        setIds.add(em2.Id);
        
        LIST<vNewCaseFromEmail.vNCFE> emails = new LIST<vNewCaseFromEmail.vNCFE>();
        vNewCaseFromEmail.vNCFE vTest = new vNewCaseFromEmail.vNCFE();
        vTest.email = em;
        vTest.caseStatus = 'New';
        vTest.casePriority = 'Medium';
        vTest.caseOwnerId = u.Id;
        vTest.caseRecordTypeId = rt.Id;
        
        emails.add(vTest);
        
        Test.startTest();
        vNewCaseFromEmail.vNewCaseFromEmail(emails);
        vNewCaseFromEmail.vEmailAttachments(setIds);
        Test.stopTest();
        
    }

}