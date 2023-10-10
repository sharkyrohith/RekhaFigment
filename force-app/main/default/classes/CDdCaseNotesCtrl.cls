public with sharing class CDdCaseNotesCtrl {

    @AuraEnabled
    public static List<Chatter_Post_Notes_Template__c> getTemplateOptions(){        
        return [Select Id, Name, Body__c From Chatter_Post_Notes_Template__c Where Active__c = true Order By Name];
    }

    @AuraEnabled
    public static String postFeed(String body, String caseId, String templateName){               
            
        body = body.Replace('<br>', '<p>&nbsp;</p>');
        body = body.Replace('<br/>', '<p>&nbsp;</p>');
        body = body.Replace('<br />', '<p>&nbsp;</p>');
        body = body.replaceAll('style=[^>]*>','>');
        body = body.replaceAll('<span','<p');
        body = body.replaceAll('</span>','</p>');
        
        String bodyWithoutSpaces = body.replaceAll('\\s+|<[/a-zAZ0-9]*>|&nbsp;','');        

        Case caseRec = [select  Id,
                                Case_Notes_Initial_Count__c,
                                Case_Notes_Count__c,
                                CaseNotesCommentCount__c
                        from Case
                        where Id =: caseId];
                    
        if(caseRec.Case_Notes_Initial_Count__c ==null){
            caseRec.Case_Notes_Initial_Count__c = bodyWithoutSpaces.length();
            caseRec.Case_Notes_Count__c = 1;
            caseRec.CaseNotesCommentCount__c = bodyWithoutSpaces.length();
        }else{
            caseRec.Case_Notes_Count__c =  (caseRec.Case_Notes_Count__c + 1);
            caseRec.CaseNotesCommentCount__c = (caseRec.CaseNotesCommentCount__c + bodyWithoutSpaces.length());
        }
        
        caseRec.CaseNoteTemplate__c = templateName;


        FeedItem fi = new FeedItem();
        fi.ParentId = caseId;
        fi.IsRichText = true;
        fi.Body = body;
        insert fi;
    
        update caseRec;

        return null;
    }
}