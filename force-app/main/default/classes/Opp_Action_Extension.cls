public class Opp_Action_Extension {
    
    public String evtNotes {get;set;}
    private Opportunity opp;
    Id oppId;
    
    public Opp_Action_Extension(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
        oppId = stdController.getRecord().id;
    }
    
    public PageReference dropInEvent(){
        List<Opportunity> oppList = [SELECT Id, Name FROM Opportunity WHERE Id = :oppId];
    
    	List<Event> evList = new List<Event>();
        
        for(Opportunity o : oppList){
        	Event evt = new Event();
        	evt.StartDateTime = system.Datetime.now();
        	evt.DurationInMinutes = 60;
        	evt.OwnerId = Userinfo.getUserId();
        	evt.Subject = 'Drop In Meeting: '+o.name;
        	evt.WhatId = o.id;
            evt.Type = 'Meeting';
            evt.Description = evtNotes;
        	evList.add(evt);
            System.debug('------------evt-------'+evt);
        }
        
        if(evList.size() > 0){
            insert evList;
        }
        
        PageReference pg = new PageReference('com.salesforce.salesforce1://entity/view?entityId='+opp.id);
        pg.setRedirect(true);
        return pg;
    }

}