/**
 * 
 * @author: Tia Xuan
 * @date: 2019-09
 * @description Batch class to send tablet cases to Denali that are approved
 * 
 */
public class CDdDenaliBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Record_Type_Values__mdt caseRecordType = [SELECT QualifiedApiName, Record_Type_Id__c 
                                                        FROM Record_Type_Values__mdt
                                                        WHERE QualifiedApiName  = 'Case_Tablet_Requests'];
        String rtId = caseRecordType.Record_Type_Id__c;
        Datetime dtOneMonthBack = DateTime.now().addMonths(-1);
        String query =   'SELECT Id from Case ';
        query += ' where Send_To_Denali__c = true ';
        query += ' and Status = \'Approved\'';
        query += ' and LastModifiedDate >=: dtOneMonthBack ';
        query += ' and RecordTypeId >=: rtId ';

        Database.QueryLocator ql = Database.getQueryLocator(query);
        return ql;
    }
    
    public void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Id> caseIds = new List<Id>();
        for (Case c : scope){
            caseIds.add(c.Id);
        }
        CDdDenaliHandler.saveCasesToDenali(caseIds);
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }

}