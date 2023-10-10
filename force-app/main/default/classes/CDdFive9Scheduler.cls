/**
 * 
 * @author: Tia Xuan
 * @date: 2019-08
 * @description class for Five 9 scheduler
 * 
 */
global class CDdFive9Scheduler implements Schedulable {

    /**
    * @description  execute the schedule for ACDStatus
    *               then reschedule it for another 2 minutes after
    **/
    global void execute(SchedulableContext sc) {
        CDdFive9Helper.getFive9Stats('ACDStatus'); 
        delSchedule(); //delete this instance of the job 
        setSchedule(); //schedule new instance of the job 
    }

    /**
    * @description  delete the current schedule
    **/
    public static void delSchedule(){
        ApexClass self = [SELECT Id FROM ApexClass WHERE Name = 'CDdFive9Scheduler'];  //get the ID of this class
        for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'CDdFive9Scheduler' OR CronJobDetail.Name = :self.Id]){
            system.abortjob(ct.id); //cancel all scheduled runs of this class
        }
    }
    
    /**
    * @description  add the schdule for 2 minutes after
    **/
    public static void setSchedule(){
        DateTime lNow = system.now();
        lNow = lNow.addMinutes(2);
        String schedule = '0 '+lNow.minute()+ ' ' + lNow.hour() + ' * * ?'; //at zero seconds two minutes from now
        system.schedule('CDdFive9Scheduler', schedule, new CDdFive9Scheduler()); //set schedule
    }
}