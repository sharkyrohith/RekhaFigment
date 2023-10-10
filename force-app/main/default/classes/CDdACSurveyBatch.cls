/**
* @author: Tia Xuan
* @date: 2022-01
* @description Create Surveys from AC to survey object Batch
*/ 
public class CDdACSurveyBatch implements Database.Batchable<sObject> {
    /**
    * @description Batch to treat the AC tasks
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {      
        Support_Settings__c setting = Support_Settings__c.getInstance();
        Integer batchDays = setting.AC_Survey_Batch_Days__c == null ? 1 : Integer.valueOf(setting.AC_Survey_Batch_Days__c);   
        String soql =   '   select  Id, ' +
                        '           Body__c, ' +
                        '           Processed__c ' + 
                        '   from AC_Survey_Task__c ' +
                        '   where Processed__c = false ' +
                        '       and  CreatedDate = LAST_N_DAYS:' + batchDays;
        return Database.getQueryLocator(soql);
    }
    
    public void execute(Database.BatchableContext BC, List<AC_Survey_Task__c> scope) {
        CDdACSurveyHelper.processSurveyResponse(scope);
    }

    public void finish(Database.BatchableContext BC) {      
    }
}