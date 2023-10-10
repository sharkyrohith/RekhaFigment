/**
 * 
 * @author: Jeegar Brahmakshatriya
 * @date: 2019-12
 * @description Controller for taskTracking LWC component
 * 
 */

public with sharing class CDdTaskTrackingController {

    /**
    * @author Rahul Mohan
    * @description BASD-13607: This method to to get list of Team
    * @param String caseRecorTypeId
    * return List<String> return list of Team Name
    */
    @AuraEnabled(Cacheable=true)
    public static List<String> retrieveTeamDetails(String caseRecordTypeId) {
      Set<String> setOfTeams = new Set<String>();
      setOfTeams.add('All');

        for( Service_Task_Template__c sttRecord: [SELECT Case_Record_Type_Id__c, Team__c, Id, Is_Active__c FROM Service_Task_Template__c 
                                                    WHERE Case_Record_Type_Id__c =: caseRecordTypeId
                                                        AND Is_Active__c = true AND Team__c!=null order by Sort_Order__c asc]){
            setOfTeams.addAll(new Set<String>(sttRecord.Team__c.split(';')));                                           
        }
        return new List<String>(setOfTeams); 
    }

    @AuraEnabled(Cacheable=true)
    public static Service_Task_Template__c[] retrieveTaskTemplates(String caseRecordTypeId, String selectedTeam) {
        String selectClause = ' SELECT Case_Record_Type_Id__c, CreatedById, CreatedDate, Estimated_Handle_Time_minutes__c, Id, Is_Active__c, Name,Team__c '+
                              ' FROM Service_Task_Template__c ';

        String whereClause = ' WHERE Case_Record_Type_Id__c =: caseRecordTypeId AND Is_Active__c = true ';
        whereClause = ( String.isBlank(selectedTeam) || selectedTeam == 'All'  ? whereClause : whereClause + ' AND Team__c INCLUDES(:selectedTeam) ' );

        String orderClause = ' order by Sort_Order__c asc ';

        String query = selectClause + whereClause + orderClause;
        /*
        Service_Task_Template__c[] records = [SELECT Case_Record_Type_Id__c, CreatedById, CreatedDate, Estimated_Handle_Time_minutes__c, Id, Is_Active__c, Name
                 FROM Service_Task_Template__c 
                 WHERE Case_Record_Type_Id__c =: caseRecordTypeId
                    AND Is_Active__c = true order by Sort_Order__c asc];
        */
        return Database.query(query); 
    }

    @AuraEnabled(Cacheable=true)
    public static String checkForActiveTasks(String caseId){
        List<Service_Task__c> serviceTasks = [SELECT Id 
                                                FROM Service_Task__c
                                                WHERE Case__c =: caseId 
                                                AND (Status__c =: Label.ServiceTaskStatusInProgress 
                                                    OR Status__C =: Label.ServiceTaskStatusPaused) ]; 
        if (serviceTasks.size() == 1) {
            System.debug('Service Tasks Queried and got 1 result'); 
            return String.valueOf(serviceTasks[0].id);
        } else {
            System.debug('Service Tasks Queried and did not get 1 result'); 
            return 'No values available'; 
        }
    }
}