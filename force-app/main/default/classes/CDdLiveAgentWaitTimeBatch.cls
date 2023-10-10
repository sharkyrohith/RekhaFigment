/**
* @author: Tia Xuan
* @date: 2019-09
* @description Get Estimated Wait Time
*/ 
public class CDdLiveAgentWaitTimeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    public List<Service_Statistics__c> statList = new List<Service_Statistics__c>();
    public List<String> transSessions = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String soql =   'SELECT Id, Live_Agent_Button_ID__c, Live_Agent_Deployment_ID__c, ' +
                        '       Live_Agent_Estimated_Wait_Time__c, Live_Agent_Session_ID__c, ' + 
             			'       Live_Agent_Org_ID__c ' + 
                        'FROM Service_Statistics__c ' + 
                        'WHERE RecordType.Name = \'Live Agent\' ';
        return Database.getQueryLocator(soql);

    }
    
    public void execute(Database.BatchableContext BC, List<Service_Statistics__c> scope) {
        for (Service_Statistics__c stat : scope){
            Service_Statistics__c s = CDdLiveAgentHelper.getLiveAgentWaitTime(stat);
            if (s != null){
                statList.add(s);
                transSessions.add(s.Live_Agent_Session_ID__c);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (statList.size() > 0){
            update statList;
        }

        if (transSessions.size() > 0){
            List<LiveChatTranscript> transToDelete = [  select Id 
                                                        from LiveChatTranscript
                                                        where ChatKey =: transSessions];
            delete transToDelete;
        }
        
    }
}