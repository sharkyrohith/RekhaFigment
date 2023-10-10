/**
 * 
 * @author: Tia Xuan
 * @date: 2019-09
 * @description class for Scheduling five 9 and Live agent wait times
 * 
 */
global class CDdServiceStatisticsSched implements Schedulable {

    /**
    * @description  execute the schedule for Five and Live agent
    *               then reschedule it for another 2 minutes after
    **/
    global void execute(SchedulableContext sc) {
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name = 'CDdLiveAgentWaitTimeBatch'];  //get the ID of this class
        List<AsyncApexJob> jobs = [ SELECT    Id
                                    FROM AsyncApexJob
                                    WHERE ApexClassId = :batchClass.Id
                                        and JobType = 'BatchApex'
                                        and Status IN ('Holding', 'Queued', 'Preparing', 'Processing')];
        if (jobs.size() == 0){
            CDdLiveAgentWaitTimeBatch batch = new CDdLiveAgentWaitTimeBatch();
            Database.executeBatch(batch, 1);
        }
        delSchedule(); //delete this instance of the job 
        setSchedule(); //schedule new instance of the job 
    }

    /**
    * @description  delete the current schedule
    **/
    public static void delSchedule(){
        ApexClass self = [SELECT Id FROM ApexClass WHERE Name = 'CDdServiceStatisticsSched'];  //get the ID of this class
        for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'CDdServiceStatisticsSched' OR CronJobDetail.Name = :self.Id]){
            system.abortjob(ct.id); //cancel all scheduled runs of this class
        }
    }
    
    /**
    * @description  add the schdule for 2 minutes after
    **/
    public static void setSchedule(){
        DateTime lNow = system.now();
        lNow = lNow.addMinutes(5);
        String schedule = '0 '+lNow.minute()+ ' ' + lNow.hour() + ' * * ?'; //at zero seconds two minutes from now
        system.schedule('CDdServiceStatisticsSched', schedule, new CDdServiceStatisticsSched()); //set schedule
    }
}