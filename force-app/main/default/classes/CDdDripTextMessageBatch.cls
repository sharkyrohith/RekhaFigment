/********************************************************************************************************************
* @author Tia Xuan (Perficient, Inc.)
* @date 06/2019
*
* @description A Batch job for drip text message
*
**************************************************************************************************************************************/

global class CDdDripTextMessageBatch implements Database.Batchable<sObject> {
    
    /** 
    * @description Getting the affected opportunities 
    */    	
	global Database.QueryLocator start(Database.BatchableContext BC) {
        // hardcode this so new opportunities are pulled.
        DateTime startDate = DateTime.newInstance(2019,06,24,0,0,0);
        if (Test.isRunningTest()){
            startDate = DateTime.Now().addDays(-14);
        }
		String qry = ' select 	Id, ' +	
            		 '			Protocol_Type__c, ' +
					 '			AutoSMS_TabletDelivered__c, ' +
					 '			AutoSMS_MenuComplete__c, ' +
					 '			Account_is_activated__c, ' +
					 '			Drip_Opt_in__c, ' +
					 '			Drip_Start_Date__c, ' +
					 '			Drip_End_Date__c, ' +
					 '			Send_Drip_Text__c, ' +
					 '			AutoSMS_GoLive__c ' +
			 		 ' from Opportunity ' +
			 		 ' where Protocol_Type__c != \'Other\' ' +
				 	 '	and (AutoSMS_TabletDelivered__c != null ' +
				 	 '		or (AutoSMS_MenuComplete__c != null ' +
            		 '			and AutoSMS_MenuComplete__c >=: startDate)) ' +
            		 '	and  Activation_Date__c = null ' +
        			 '	and  SMS_Opt_out__c = \'Opt-in\''+
            		 '	and  AutoSMS_GoLive__c = null '+
        			 '	and  StageName = \'Closed Won\' ';
		
        // for testing
        //qry += ' and Id = \'0061a00000PwVXlAAN\'';
        //System.debug('qry:' + qry);
		return Database.getQueryLocator(qry);
	}
    
    /** 
    * @description Execute the batch 
    */  
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
    	List<Opportunity> oppList = (List<Opportunity>) scope;
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        Date dToday = Date.today();
        
        
        for (Opportunity opp: oppList){
            
            Date dStartDate = null;
            if (opp.Drip_Start_Date__c != null){
                dStartDate = opp.Drip_Start_Date__c.date();
            }
            Date dEndDate = null;
            if (opp.Drip_End_Date__c != null){
                dEndDate = opp.Drip_End_Date__c.date();
            }
            
            if ((opp.Protocol_Type__c == 'Tablet' 
                && opp.AutoSMS_TabletDelivered__c != null)
                || (opp.Protocol_Type__c == 'NonTablet' 
                    && opp.AutoSMS_MenuComplete__c != null)){
				
                // This process is for the drip
                if (opp.Account_is_activated__c != null
                    && opp.Account_is_activated__c == 'No'
                    && opp.Drip_Opt_in__c != null
                    && opp.Drip_Opt_in__c == true
                    && dStartDate != null
                    && dStartDate <= dToday
                    && dEndDate != null
                    && dEndDate > dToday
                    && (opp.Send_Drip_Text__c == null
                       || opp.Send_Drip_Text__c == false)
                    && opp.AutoSMS_GoLive__c == null){
                    opp.Send_Drip_Text__c = true;
                    oppToUpdate.add(opp);
                 // This is process is for once the drip ends, they get a go live text
                 } else if (opp.Account_is_activated__c != null
                    && opp.Account_is_activated__c == 'No'
                    && opp.Drip_Opt_in__c != null
                    && opp.Drip_Opt_in__c == true 
                    && dEndDate != null
                    && dEndDate == dToday
                    && opp.AutoSMS_GoLive__c == null){
                    opp.AutoSMS_GoLive__c  = DateTime.now();
                    oppToUpdate.add(opp);
                 // This is process if during the drip, they self activate, 
                 // which means we end the drip and send them the go live message.
                 } else if (opp.Account_is_activated__c != null
                    && opp.Account_is_activated__c == 'Yes'
                    && opp.Drip_Opt_in__c != null
                    && opp.Drip_Opt_in__c == true
                    && dStartDate != null
                    && dStartDate <= dToday
                    && dEndDate != null
                    && dEndDate >= dToday
                    && opp.AutoSMS_GoLive__c == null){
                    opp.AutoSMS_GoLive__c  = DateTime.now();
                    oppToUpdate.add(opp);
                 // This is process if for those opps that sent 
                 // sms messages but are not included in the drip.
                 } else if (opp.Account_is_activated__c != null
                    && opp.Account_is_activated__c == 'Yes' 
                    && opp.Drip_Opt_in__c != null
                    && opp.Drip_Opt_in__c == false
                    && opp.AutoSMS_GoLive__c == null){
                    opp.AutoSMS_GoLive__c = DateTime.now();
                    oppToUpdate.add(opp);
                 }
                        
             }
                
        }
                    
        //System.debug('oppToUpdate:' + oppToUpdate);
        if (oppToUpdate.size() > 0){
            update oppToUpdate;
        }
        
    
    }
    
	/** 
    * @description Finish the batch operation
    */ 	
	global void finish(Database.BatchableContext BC) {
		
	}
}