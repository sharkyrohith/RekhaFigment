public class VDispatchCaseCalloutQueueable implements Queueable, Database.AllowsCallouts {
    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit    
    public static final Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();

	//public static final Integer RESPONSE_FIELD_LENGTH =  Schema.SObjectType.Case.fields.DispatchRQResponse__c.getLength();
	public Set<ID> caseIds { get; private set; }
	public Boolean trapExceptions { get; private set; }
	public Boolean throwTestException { get; set; } // provided for coverage
    public Boolean runAlways { get; set; }

	public VDispatchCaseCalloutQueueable(Set<ID> caseIds) {
		this(caseIds, true, false);
		
	}

	public VDispatchCaseCalloutQueueable(Set<ID> caseIds, Boolean trapExceptions, Boolean runAlways) {
		this.caseIds = caseIds;
		this.trapExceptions = trapExceptions;
        this.runAlways = runAlways;
		this.throwTestException = false;
	}

	public void execute(QueueableContext context) {
        if(!apiSettings.Case_Object_Send_To_Dispatch__c) return;
        
		List<Case> casesToUpdate = new List<Case>();
		
		List<Case> casesToSend = VCaseSelector.retrieveUsingDispatchAPIMappings(caseIds, new List<String> { 'IsSentToDispatch__c' });

        for(Case c : casesToSend) {
            if(runAlways || (c.Status == 'New' || c.Status == 'Solved' || (!c.IsSentToDispatch__c && c.Origin == 'Chat'))) {
                // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                if(c.DeliveryNo__c != null || String.isNotBlank(c.DeliveryUUID__c)) {
                	VDispatchCaseCallout caseCallout = new VDispatchCaseCallout(c);

                	try {
                		caseCallout.makeCaseCallout();

                		if(!c.IsSentToDispatch__c) {
                			c.IsSentToDispatch__c = true;
                			casesToUpdate.add(c);
                		}
                	} catch(Exception e) {
                		System.debug(e.getMessage());
                		System.debug(e.getStackTraceString());
                	}
                }
            }
        }

        if(casesToUpdate.size() > 0) {
        	try {
        		update casesToUpdate;
    		} catch(Exception e) {
    			if(!trapExceptions) throw e;
    		}
        }
	}
}