/**
* @author: Tia Xuan
* @date: 2022-01
* @description Create Surveys from AC to survey object scheduler
*/ 
public class CDdACSurveySched implements Schedulable {
    public void execute(SchedulableContext sc) {
        Support_Settings__c setting = Support_Settings__c.getInstance();
        Integer batchSize = setting.AC_Survey_Batch_Size__c == null ? 1 : Integer.valueOf(setting.AC_Survey_Batch_Size__c);   
        CDdACSurveyBatch batch = new CDdACSurveyBatch();
        Database.executeBatch(batch, batchSize);
    }
}