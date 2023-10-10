/* Created by Veltig Consulting
 * Copyright 2017
 * 
 */
global class vNewCaseFromEmail {

    @InvocableMethod
    public static void vNewCaseFromEmail(LIST<vNCFE> records){
        
        MAP<Id,Case> emToCase = new MAP<Id,Case>();
        MAP<Id,EmailMessage> emMap = new MAP<Id,EmailMessage>();
        LIST<EmailMessage> emList = new LIST<EmailMessage>();
        LIST<EmailMessage> emListOld = new LIST<EmailMessage>();
        MAP<Id,EmailMessage> emAttachmentMap = new MAP<Id,EmailMessage>();
        MAP<Id,EmailMessage> emAttachmentMapOld = new MAP<Id,EmailMessage>();
        SET<Id> emSet = new SET<Id>();
        
        for(vNCFE ncfe : records){
        	
            	Case c = new Case(
                	Subject = ncfe.email.Subject,
                    Description = ncfe.email.TextBody,
                    Origin = 'Email',
                    Priority = ncfe.casePriority,
                    OwnerId = ncfe.caseOwnerId,
                    RecordTypeId = ncfe.caseRecordTypeId,
                    Status = ncfe.caseStatus,
                    SuppliedEmail = ncfe.email.FromAddress,
                    SuppliedName = ncfe.email.FromName,
                    ParentId = ncfe.email.ParentId,
                    Created_from_Closed_Case__c = True
                );
            
                emToCase.put(ncfe.email.Id, c);
                emMap.put(ncfe.email.Id, ncfe.email);
        }
        
        if(!emToCase.isEmpty()){
            insert emToCase.values();
            for(Id emId: emToCase.keySet()){
                Case c = emToCase.get(emId);
                EmailMessage em = emMap.get(emId);
                EmailMessage emNew = new EmailMessage();
                
                emNew.ParentId = c.Id;
                emNew.Status = '0';
                emNew.BccAddress = em.BccAddress;
                emNew.CcAddress = em.CcAddress;
                emNew.FromAddress = em.FromAddress;
                emNew.FromName = em.FromName;
                emNew.Headers = em.Headers;
                emNew.HtmlBody = em.HtmlBody;
                emNew.Incoming = em.Incoming;
                //emNew.IsExternallyVisible = em.IsExternallyVisible;
                emNew.MessageDate = em.MessageDate;
                emNew.Subject = em.Subject;
                emNew.TextBody = em.TextBody;
                emNew.ToAddress = em.ToAddress;
                emNew.ValidatedFromAddress = em.ValidatedFromAddress;
                emNew.ReplyToEmailMessageId = em.Id;
                emList.add(emNew);
                if(em.HasAttachment == True){
                    emAttachmentMap.put(em.Id,emNew);
                    emAttachmentMapOld.put(em.Id,em);
                }
                
                EmailMessage emOld = new EmailMessage();
                emOld.Id = em.Id;
                emOld.Status = '1';
                emListOld.add(emOld);
            }
            if(!emList.isEmpty()){
                insert emList;
                update emListOld;
            }
            if(!emAttachmentMap.isEmpty()){
                for(EmailMessage emAll : emList){
                	for(EmailMessage em : emAttachmentMapOld.values()){
                    	if(em.HasAttachment == True && emAll.ReplyToEmailMessageId == em.Id){
                        	emSet.add(emAll.Id);
                    	}
                	}
                }
                vEmailAttachments(emSet);
            }
        }
        
    }
    
    global class vNCFE{
        
        @InvocableVariable(required=true)
        global Id caseRecordTypeId;
        
        @InvocableVariable(required=true)
        global Id caseOwnerId;
        
        @InvocableVariable(required=true)
        global String caseStatus;
        
        @InvocableVariable(required=true)
        global EmailMessage email;
        
        @InvocableVariable(required=true)
        global String casePriority;
        
    }
    
    @future
    public static void vEmailAttachments(SET<Id> cA){
        MAP<Id,EmailMessage> emPMap = new MAP<Id,EmailMessage>();
        LIST<EmailMessage> emPList = [SELECT Id, ReplyToEmailMessageId FROM EmailMessage WHERE Id IN: cA];
        for(EmailMessage em : emPList){
			emPMap.put(em.ReplyToEmailMessageId,em);
        }
        System.debug('emPMap.keySet() is ' + emPMap.keySet());
        LIST<Attachment> aList = [SELECT Id, ParentId, Body, ContentType, Description, IsPrivate, Name, OwnerId FROM Attachment WHERE ParentId IN: emPMap.keySet()];
        LIST<Attachment> aUpdate = new LIST<Attachment>();
        for(Attachment a : aList){
        	EmailMessage em = emPMap.get(a.ParentId);
            Attachment aNew = new Attachment();
            aNew.Body = a.Body;
            aNew.ContentType = a.ContentType;
            aNew.Description = a.Description;
            aNew.IsPrivate = a.IsPrivate;
            aNew.Name = a.Name;
            aNew.OwnerId = a.OwnerId;
            aNew.ParentId = em.Id;
            aUpdate.add(aNew);
        }
        insert aUpdate;
    }
    
}