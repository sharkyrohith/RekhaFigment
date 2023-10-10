/**
 * @name			CDdDenaliV2Sched
 * @author			Jose Vega <jose.vega@doordash.com>
 * @created			01 / 27 / 2021
 * @description		Mimicks the DenaliSched class written by Tia
 *
**/
 // to schedule rescue jobs at 2pm and 10pm run CDdDenaliSched.setSchedule(new List<String>{'0 12 14,22 * * ?'});
 global class CDdDenaliV2Sched implements Schedulable {

    global static final List<String> CRON_STRINGS = new List<String>{'0 12 * * * ?', '0 42 * * * ?'};

    /**
    * @description  execute the schedule for Denali cases
    **/
    global void execute(SchedulableContext sc) {
        CDdDenaliV2Batch batch = new CDdDenaliV2Batch();
        Database.executeBatch(batch, 1);
    }

    /**
    * @description  delete the current schedule
    **/
    @testVisible static void delSchedule(){
        ApexClass self = [SELECT Id FROM ApexClass WHERE Name = 'CDdDenaliV2Sched'];  //get the ID of this class
        for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name like 'CDdDenaliV2Sched%' OR CronJobDetail.Name = :self.Id]){
            system.abortjob(ct.id); //cancel all scheduled runs of this class
        }
    }
    
    /**
    * @description  add the schedule for the next iteration
    **/
    public static void setSchedule(){
        setSchedule(CRON_STRINGS);
    }

    public static void setSchedule(List<String> cronStrings){
        try {
            delSchedule();
            for(String cronString: cronStrings){
                system.schedule('CDdDenaliV2Sched/'+ cronString, cronString, new CDdDenaliV2Sched());
            }
        } catch(Exception e){
            CDdErrorUtilities.publishException('CDdDenaliV2Sched','setSchedule', e);
        }
    }
}