public class Contact_Action_Extension {
    
    public String evtNotes {get;set;}
    private Contact con;
    Id conId;
    
    public Contact_Action_Extension(ApexPages.StandardController stdController) {
        this.con = (Contact)stdController.getRecord();
        conId = stdController.getRecord().id;
    }
    
    public PageReference dropInEvent(){
        List<Contact> conList = [SELECT Id, Name FROM Contact WHERE Id = :conId];
    
    	List<Event> evList = new List<Event>();
        
        for(Contact c : conList){
        	Event evt = new Event();
        	evt.StartDateTime = system.Datetime.now();
        	evt.DurationInMinutes = 60;
        	evt.OwnerId = Userinfo.getUserId();
        	evt.Subject = 'Drop In Meeting: '+c.name;
        	evt.WhoId = c.id;
            evt.Type = 'Meeting';
            evt.Description = evtNotes;
        	evList.add(evt);
            System.debug('------------evt-------'+evt);
        }
        
        if(evList.size() > 0){
            insert evList;
        }
        
        PageReference pg = new PageReference('com.salesforce.salesforce1://entity/view?entityId='+con.id);
        pg.setRedirect(true);
        return pg;
    }

}