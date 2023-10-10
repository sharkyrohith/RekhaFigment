/**
* @author: Tia Xuan
* @date: 2020-01
* @description Send Survey to Delighted
*/ 
public class CDdDelightedBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {        
        DateTime now = DateTime.now();
        String supportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Boolean excludeSupport = CDdExperimentSvc.getFeatureFlag('Exclude_Support_for_Delighted__c');
        String soql =   'SELECT Id, Case__c' + 
                        '       ,Case__r.ContactEmail ' + 
                        '       ,Case__r.SuppliedEmail ' + 
                        '       ,Case__r.CreatedDate ' + 
                        '       ,Case__r.User_Id__c ' + 
                        '       ,Case__r.CaseOriginFormatted__c ' + 
                        '       ,Survey__c, Sent__c ' + 
                        '       ,Error_Message__c, Survey_Provider__c ' + 
                        'FROM  Delighted_Tasks__c ' + 
                        'WHERE createddate = last_n_days:4 ' +
                        '   and Sent__c = false '+
                        '   AND Survey_Provider__c = \'' + CDdSupportConstants.SURVEY_PROVIDER_DELIGHTED + '\'' +
                        '   and ( Send_Time__c = null OR Send_Time__c <=: now) ';
        if (excludeSupport){
            soql += '   and Case__r.RecordTypeId !=: supportRTId ';
        }
        // BZAPSUP-162 Batch CSAT Send VIP first
        soql += '   ORDER BY  Delighted_Priority__c NULLS LAST ';
        return Database.getQueryLocator(soql);
    }
    
    public void execute(Database.BatchableContext BC, List<Delighted_Tasks__c> scope) {
        CDdDelightedTaskHelper.processDelightedSurveys(scope);
    }

    public void finish(Database.BatchableContext BC) {
        
    }
}