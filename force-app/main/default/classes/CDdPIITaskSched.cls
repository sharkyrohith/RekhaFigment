/**
 * 
 * @author: Tia Xuan
 * @date: 2021-10
 * @description class for Scheduling PII Privacy Service Batch
 * 
 */
global class CDdPIITaskSched implements Schedulable {

    /**
    * @description  execute the schedule for PII Privacy Service
    *               then reschedule it for another interval in  minutes after
    **/
    global void execute(SchedulableContext sc) {
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name = 'CDdPIITaskBatch'];  //get the ID of this class
        List<AsyncApexJob> jobs = [ SELECT    Id
                                    FROM AsyncApexJob
                                    WHERE ApexClassId = :batchClass.Id
                                        and JobType = 'BatchApex'
                                        and Status IN ('Holding', 'Queued', 'Preparing', 'Processing')];
        if (jobs.size() == 0){
            CDdPIITaskBatch batch = new CDdPIITaskBatch();
            Database.executeBatch(batch, 50);
        }
        delSchedule(); //delete this instance of the job 
        setSchedule(); //schedule new instance of the job 
    }

    /**
    * @description  delete the current schedule
    **/
    public static void delSchedule(){
        ApexClass self = [SELECT Id FROM ApexClass WHERE Name = 'CDdPIITaskSched'];  //get the ID of this class
        for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'CDdPIITaskSched' OR CronJobDetail.Name = :self.Id]){
            system.abortjob(ct.id); //cancel all scheduled runs of this class
        }
    }
    
    /**
    * @description  add the schedule for a defined minutes after
    **/
    public static void setSchedule(){
        DateTime lNow = system.now();
        lNow = lNow.addMinutes(Integer.valueOf(CDdPIIHelper.SUPPORT_SETTINGS.PII_Batch_Interval__c));
        String schedule = '0 '+lNow.minute()+ ' ' + lNow.hour() + ' * * ?'; //at zero seconds two minutes from now
        system.schedule('CDdPIITaskSched', schedule, new CDdPIITaskSched()); //set schedule
    }
}