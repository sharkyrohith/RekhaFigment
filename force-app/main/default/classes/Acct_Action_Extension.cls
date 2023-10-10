public class Acct_Action_Extension {
    
    public String evtNotes {get;set;}
    private Account acct;
    Id acctId;
    
    public Acct_Action_Extension(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
        acctId = stdController.getRecord().id;
    }
    
    public PageReference dropInEvent(){
        List<Account> acctList = [SELECT Id, Name FROM Account WHERE Id = :acctId];
    
    	List<Event> evList = new List<Event>();
        
        for(Account a : acctList){
        	Event evt = new Event();
        	evt.StartDateTime = system.Datetime.now();
        	evt.DurationInMinutes = 60;
        	evt.OwnerId = Userinfo.getUserId();
        	evt.Subject = 'Drop In Meeting: '+a.name;
        	evt.WhatId = a.id;
            evt.Type = 'Meeting';
            evt.Description = evtNotes;
        	evList.add(evt);
            System.debug('------------evt-------'+evt);
        }
        
        if(evList.size() > 0){
            insert evList;
        }
        
        PageReference pg = new PageReference('com.salesforce.salesforce1://entity/view?entityId='+acct.id);
        pg.setRedirect(true);
        return pg;
    }
}