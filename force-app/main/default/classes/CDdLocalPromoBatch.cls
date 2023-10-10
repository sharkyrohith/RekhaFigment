/**
* @author: ed-kim
* @date: 2019-03
* @description In Store Promos Batch
*/ 
public class CDdLocalPromoBatch { //implements Database.Batchable<sObject>, Database.AllowsCallouts {
    // String limitStr;
    // String queryParam;
    // CDdLocalPromoSvc localPromoSvc = new CDdLocalPromoSvc();

    // public CDdLocalPromoBatch() {
    //     this(0);
    // }

    // public CDdLocalPromoBatch(Integer limitNum) {
    //     this(limitNum, '');
    // }

    // public CDdLocalPromoBatch(Integer limitNum, String queryParam) {
    //     this.limitStr = limitNum != 0 ? 'LIMIT ' + String.valueOf(limitNum) : '';
    //     this.queryParam = String.isBlank(queryParam) ? '' : queryParam;
    // }


    // public Database.QueryLocator start(Database.BatchableContext BC) {
    //     String soql = 'SELECT Id, Restaurant_Id__c, ParentId ' + 
    //                   'FROM Account ' + 
    //                   'WHERE (RecordType.DeveloperName = \'Prospect\' ' +
    //                   'OR RecordType.DeveloperName = \'Enterprise_Marketplace\') ' +
    //                   'AND PAP__c = true ' +
    //                   queryParam +
    //                   this.limitStr;
    //     System.debug(soql);
    //     return Database.getQueryLocator(soql);
    // }
    
    // public void execute(Database.BatchableContext BC, List<Account> scope) {
    //     localPromoSvc.createLocalPromo(scope);
    // }

    // public void finish(Database.BatchableContext BC) {
        
    // }
}