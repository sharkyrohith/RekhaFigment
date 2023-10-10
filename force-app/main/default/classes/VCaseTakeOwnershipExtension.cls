public class VCaseTakeOwnershipExtension 
{
    private ApexPages.StandardController ctrl;
    
    public Case caseRec {get;set;}
    public String errorMessage {get;set;}
    
    public VCaseTakeOwnershipExtension(ApexPages.StandardController controller)
    {
        ctrl = controller;
        caseRec = (Case)controller.getRecord();
        errorMessage = '';
    }
    
    public PageReference changeOwnershipToCurrentUser()
    {
        Savepoint sp = Database.setSavepoint();
        
        try
        {
            caseRec.OwnerId = UserInfo.getUserId();
        	update caseRec;
            
            return ctrl.view();
        }
        catch(DmlException de) {errorMessage = de.getMessage(); System.debug('#### Error: '+de.getMessage()); }
        
        return null;
    }
}