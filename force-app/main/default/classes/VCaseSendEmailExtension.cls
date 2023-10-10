public class VCaseSendEmailExtension 
{    
    public Case caseRec {get;set;}
    public String emailSubject {get;set;}
    public String emailBody {get;set;}
    public String errorMessage {get;set;}
    public Boolean hasError {get;set;}
    
	public VCaseSendEmailExtension(ApexPages.StandardController controller)
    {
        caseRec = (Case)controller.getRecord();
        emailSubject = '';
        emailBody = '';
        reset();
        loadEmailTemplate(((Case)controller.getRecord()).Id);
    }
    
    public void loadEmailTemplate(Id caseId)
    {
        if(Email_Publisher_Template__c.getInstance('Default') != null)
        {
            Email_Publisher_Template__c cs = Email_Publisher_Template__c.getInstance('Default');
            List<EmailTemplate> emailTemplateList = [Select Id From EmailTemplate Where Id = :cs.Email_Template_Id__c Limit 1];
            List<Case> caseList = [Select Id, ContactId From Case Where Id = :caseId Limit 1];
            
            Id contactId;
            
            if(!caseList.isEmpty())
            {
                contactId = caseList[0].ContactId;
            }
            
            if(!emailTemplateList.isEmpty())
            {
                Messaging.SingleEmailMessage em = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, contactId, caseId);
                emailSubject = em.getSubject();
                emailBody = em.getPlainTextBody();
            }
        }
    }
    
    public PageReference saveCase() 
    {   
        Savepoint sp = Database.setSavepoint();
        
        try
        {
        	update caseRec;
            
        	this.reset();
        }
        catch(DmlException de)
        {
            hasError = true;
            errorMessage = de.getMessage();
            
            System.debug('#### Error: '+de.getMessage());
        }
        
        return null;
    }
    
    private void reset()
    {
        hasError = false;
        errorMessage = '';
    }
}