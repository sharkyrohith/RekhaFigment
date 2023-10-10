/*
 *		Name:		sched_SendNPSEmails 
 * 		Date:		3/2016
 * 		Author:		Cole Conroy - RoyCon Technologies
 * 		Desc:		Schedulable class to send NPS emails to Contacts indicated on Accounts.
 * 					Sends based on increment indicated in custom setting. 
 * 
 */

global class batch_SendNPSEmails implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
		string query = 'SELECT Id, OwnerId, Owner.Email, Last_NPS_Email_Sent__c, General_Manager__c, General_Manager__r.Email, Decision_Maker__c, Decision_Maker__r.Email FROM Account WHERE Receive_NPS_Email__c = True AND Last_NPS_Email_Sent__c != null AND (Account_Status__c = \'Active\' OR Account_Status__c = \'Active (non-preferred)\')';       
       	return Database.getQueryLocator(query);
   	}
    
	global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<NPS_Emails__c> nps = NPS_Emails__c.getall().values();
        Date dt = system.date.today();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> mails2 = new List<Messaging.SingleEmailMessage>();
        List<Account> aList = new List<Account>();
        List<Account> aList2 = new List<Account>();
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name = 'NPS Survey' LIMIT 1];
        for(Account acc : (List<Account>) scope){
            if(acc.Last_NPS_Email_Sent__c.daysBetween(dt) == nps[0].Email_Frequency__c && nps[0].Send_NPS_Emails__c == True && (acc.Decision_Maker__c != null || acc.General_Manager__c != null)){
                if(acc.General_Manager__r.Email != null || acc.Decision_Maker__r.Email != null){
                	Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                	msg.setTemplateId(et.id);
                    msg.setSaveAsActivity(True);
                	if(acc.General_Manager__c != null && acc.General_Manager__r.Email != null){
                		msg.setTargetObjectId(acc.General_Manager__c);
                    	if(acc.Decision_Maker__c != null && acc.Decision_Maker__r.Email != null){
                        	List<String> tos = new List<String>{acc.Decision_Maker__r.Email};
                    		msg.setToAddresses(tos);
                    	}
                	}
                	else if(acc.Decision_Maker__c != null){
                    	msg.setTargetObjectId(acc.Decision_Maker__c);
                	}
                    if(mails.size() <= 99){
                		mails.add(msg);
                        acc.Last_NPS_Email_Sent__c = system.date.today();
                		aList.add(acc);
                    }
                    else if(mails.size() >= 100 && mails.size() <= 200){
                        mails2.add(msg);
                        acc.Last_NPS_Email_Sent__c = system.date.today();
                		aList2.add(acc);
                    }
            	}
            }
        }
        
        system.debug('-----mail 1 size-----'+mails.size());
        system.debug('-----mail 2 size-----'+mails2.size());
        //Send Email is limited to 100 per sendEmail method so its separated into 2 lists if it goes over 100   
        if(mails.size() > 0){
            //Messaging.sendEmail(mails);
            List<messaging.SendEmailResult> emailResults = Messaging.sendEmail(mails);
            system.debug('------emailResults---------'+emailResults[0]);
            if(emailResults[0].isSuccess() == True){
            	update aList;
            }
            else{
                List<Task> tskList = new List<Task>();
                for(Account a : aList){
                    Task tsk = new Task();
                    tsk.WhatId = a.id;
                    tsk.ActivityDate = date.today();
                    tsk.Subject = 'Failed to Send NPS email';
                    tsk.Status = 'Completed';
                    tskList.add(tsk);
                }
                if(tskList.size() > 0){
                    insert tskList;
                }
            }
        }
        
        if(mails2.size() > 0){
            List<messaging.SendEmailResult> emailResults2 = Messaging.sendEmail(mails2);
            if(emailResults2[0].isSuccess() == True){
            	update aList2;
            }
            else{
                List<Task> tskList = new List<Task>();
                for(Account a : aList2){
                    Task tsk = new Task();
                    tsk.WhatId = a.id;
                    tsk.ActivityDate = date.today();
                    tsk.Subject = 'Failed to Send NPS email';
                    tsk.Status = 'Completed';
                    tskList.add(tsk);
                }
                if(tskList.size() > 0){
                    insert tskList;
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        Datetime sysTime = System.now().addDays(1);
		String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
		system.schedule('sched_SendNPSEmails - ' + sysTime.getTime(), chronExpression, new sched_batchSendNPSEmails());
    }
}