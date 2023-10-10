/********************************************************************************************************************
* @author Veera
* @date 04/26/2022
*
* @group Merchant Services
*
* @description to handle database operations for Mx Support Event Configuration Custom Object
*
*
* @usage:    Create a record in the Mx_Support_Event_Config__c Object and schedule the class.
*           1. Apex_Class__c                    :  Apex Class to get query and should be instance of CDdMxSupportEventInterface
*           2. Batch_Size__c                    :   Batch size to execute the data fetched using the script
            3. Event_Name__c                    :   Event Name for the record
            4. Query_Last_N_Days__c             :   String parameter to consider Last N Days
                                                    SELECT Id from contact WHERE AccountId IN : {0} and LAST_N_DAYS =:{1}
            6. Query_SObject_Type__c            :   Sobject Type to crete event
            7. Sequence__c                      :   Sequence of the Config record
            8. Is_Active__c                     :   To include/Exclude the script for Batch execution
            9. Send_Email__c                    :   To active/deactivate send emails to users
           10. Email_Addresses_To_Notify__c     :   User Email addresses to receive emails after batch job/publishing events 
**************************************************************************************************************************************/
public class CDdMxSupportEventBatch implements Database.Batchable<sObject> {
    
    private CDdMxSupportEventEnum eventEnum;

    public CDdMxSupportEventBatch(CDdMxSupportEventEnum event){
        this.eventEnum = event;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return CDdMxSupportEventConfig.getMxSupportInstance(this.eventEnum).getQueryLocator();
     }
  
     public void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Id> sObjectIds = new Set<Id>();
        for(SObject obj : scope){
            sObjectIds.add(obj.Id);
        }

        CDdMxSupportEventConfig.getMxSupportInstance(this.eventEnum).publishEvents(CDdMxSupportEventConfig.getQuerySObjectType(this.eventEnum), sObjectIds);
     }
  
     public void finish(Database.BatchableContext BC) {
        if(CDdMxSupportEventConfig.isNotififyUsers(this.eventEnum)){
            sendJobStatusEmail(BC.getJobId(),this.eventEnum.name(), CDdMxSupportEventConfig.emailAddressesToNotify(this.eventEnum));
        }

       if(CDdMxSupportEventConfig.hasNextMxSupportEvent(this.eventEnum)){
            CDdMxSupportEventEnum nextEventEnum = CDdMxSupportEventConfig.getNextMxSupportEvent(this.eventEnum);
            Database.executeBatch(new CDdMxSupportEventBatch(nextEventEnum), CDdMxSupportEventConfig.getBatchSize(nextEventEnum));
       }

    }

    private static void sendJobStatusEmail(String jobId, String eventEnum, List<String> toEmailAddressList){
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                                FROM AsyncApexJob WHERE Id =: jobId];

        String body = 'The CDdMxSupportEventBatch job for '+eventEnum+' processed ' + apexJob.TotalJobItems + ' batches with '+ apexJob.NumberOfErrors + ' failures.\n';
        if(apexJob.ExtendedStatus != null){
            body += apexJob.ExtendedStatus;
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        mail.setToAddresses(toEmailAddressList);
        mail.setSubject('Mx Support Job status is ' + apexJob.Status);
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}