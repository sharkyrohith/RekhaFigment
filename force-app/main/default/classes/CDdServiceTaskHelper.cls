/**
 * 
 * @author: Jeegar Brahmakshatriya
 * @date: 2019-12
 * @description Helper class for Service Task Trigger. 
 * 
 */

public with sharing class CDdServiceTaskHelper {

    /* 
     * Allow only one active task at any given time on a case. 
     */
    public static void checkForActiveTasks(List<Service_Task__c> newList) {
        Map<Id,Integer> caseIdTaskCountMap = new Map<Id,Integer>(); 
        String idString; 
        Set<Id> caseIdSet = new Set<Id>(); 
        List<Service_Task__c> queriedServiceTasks = new List<Service_Task__c>(); 
        Integer count = 0; 
        for(Service_Task__c serviceTask : newList) {
            if(serviceTask.Case__c != null) {
                caseIdSet.add(serviceTask.Case__c);
            }
        }

        queriedServiceTasks = [SELECT Id, Case__c 
                                FROM Service_Task__c 
                                WHERE Case__c in: caseIdSet 
                                    AND (Status__c =: Label.ServiceTaskStatusInProgress 
                                    OR Status__c =: Label.ServiceTaskStatusPaused) ];

        for (Service_Task__c servTask : queriedServiceTasks ) {
            if(caseIdTaskCountMap.containsKey(servTask.Case__c)) {
                count = caseIdTaskCountMap.get(servTask.Case__c) + 1;
                caseIdTaskCountMap.put(servTask.Case__c, count);
            } else {
                caseIdTaskCountMap.put(servTask.Case__c, 1);
            }
        }

        for(Service_Task__c serviceTask : newList) {

            if(caseIdTaskCountMap.containsKey(serviceTask.Case__c) 
                   && caseIdTaskCountMap.get(serviceTask.Case__c) > 1) {
                serviceTask.addError(Label.Service_Task_Error_Message_One_Active_Task);
            }
        }
    }

    /* 
     * Calculate time spent and update fields when the status changes. 
     */ 
    public static void calculateTimeSpent(List<Service_Task__c> newList, Map<Id,Service_Task__c> oldMap) {
        
        Double actualHandleTime;
        for(Service_Task__c serviceTask : newList) {
            if(serviceTask.Status__c == Label.ServiceTaskStatusPaused 
                    && oldMap.get(serviceTask.Id).Status__c == Label.ServiceTaskStatusInProgress) {
                serviceTask = pauseCompleteTaskUpdates(serviceTask);
            }
            else if(serviceTask.Status__c == Label.ServiceTaskStatusInProgress 
                    && oldMap.get(serviceTask.Id).Status__c == Label.ServiceTaskStatusPaused) {
                serviceTask = resumeTaskUpdates(serviceTask);
            }
            else if(serviceTask.Status__c == Label.ServiceTaskStatusCompleted 
                    && oldMap.get(serviceTask.Id).Status__c == Label.ServiceTaskStatusInProgress) {
                serviceTask = pauseCompleteTaskUpdates(serviceTask);
            }
            else if(serviceTask.Status__c == Label.ServiceTaskStatusCancelled 
                    && oldMap.get(serviceTask.Id).Status__c == Label.ServiceTaskStatusInProgress) {
                serviceTask = pauseCompleteTaskUpdates(serviceTask);
            }
            else if(serviceTask.Status__c == Label.ServiceTaskStatusCompleted 
                    && oldMap.get(serviceTask.Id).Status__c == Label.ServiceTaskStatusPaused) {
                serviceTask.Completed_Date_Time__c = System.now(); 
            }
            else if(serviceTask.Status__c == Label.ServiceTaskStatusCancelled 
                    && oldMap.get(serviceTask.Id).Status__c == Label.ServiceTaskStatusPaused) {
                serviceTask.Completed_Date_Time__c = System.now(); 
            }
            
        }
    }

    /*
     * Update fields when a serviceTask moves to Completed Paused or Canceled. 
     *
     */
    private static Service_Task__c pauseCompleteTaskUpdates(Service_Task__c serviceTask) {
        serviceTask.Time_Entry_Stop__c = System.now(); 
        serviceTask.Actual_Handle_Time__c = calculateHandleTime(serviceTask.Time_Entry_Start__c, serviceTask.Actual_Handle_Time__c);
        if(serviceTask.Status__c == Label.ServiceTaskStatusCompleted || serviceTask.Status__c == Label.ServiceTaskStatusCancelled) {
            serviceTask.Completed_Date_Time__c = System.now(); 
        }
        return serviceTask; 
    }
    
    /*
     * Updates fields when a Service Task goes from Paused to In Progress. 
     */

    private static Service_Task__c resumeTaskUpdates(Service_Task__c serviceTask) {
        serviceTask.Time_Entry_Start__c = System.now(); 
        serviceTask.Time_Entry_Stop__c = null; 

        return serviceTask; 
    }    

    /*
     * Calculate time between start time and now in minutes. 
     * had to break down the math so that the minutes are not rounded and we get a 2 digit decimal. 
     */
    private static Decimal calculateHandleTime(DateTime startTime, Decimal handleTime) {
        Decimal currentHandleTime;
        handletime = handleTime == null ? 0 : handletime;
        currentHandleTime = (System.now().getTime() - startTime.getTime());
        currentHandleTime = currentHandleTime/60000;
        handletime = handletime + currentHandleTime; 
        return handleTime; 
    }

    /* 
     * When a Service Task is completed, Create a new task if the Next Task is populate. 
     */ 
    public static void createNextTasks(List<Service_Task__c> newList, Map<Id,Service_Task__c> oldMap) {
        List<Service_Task__c> serviceTasksToInsert = new List<Service_Task__c>(); 
        Set<Id> taskTemplateIds = new Set <Id>(); 
        Map<Id,Id> caseTaskTemplateIdMap = new Map<Id,Id>(); 
        Map<Id, Service_Task_Template__c> taskTemplateIdMap= new Map<Id, Service_Task_Template__c>(); 
        Service_Task__c newServiceTask; 
        Service_Task_Template__c tempTaskTemplate; 
        Map<Id,String> taskTeamName = new Map<Id,String>();
        for(Service_Task__c serviceTask : newList) {
            if(serviceTask.Status__c == Label.ServiceTaskStatusCompleted 
                    && oldMap.get(serviceTask.Id).Status__c != Label.ServiceTaskStatusCompleted) {
                
                taskTemplateIds.add(serviceTask.Next_Task__c);
                caseTaskTemplateIdMap.put(serviceTask.Case__c, serviceTask.Next_Task__c);
                if(String.isNotBlank(serviceTask.Team_Name__c)){
                   taskTeamName.put(serviceTask.Case__c,serviceTask.Team_Name__c);
                }
            }
        }

        taskTemplateIdMap = new Map<Id, Service_Task_Template__c> (
                [SELECT Id, Case_Record_Type_Id__c, Estimated_Handle_Time_Minutes__c, Is_Active__c, 
                        Name, OwnerId 
                    FROM Service_Task_Template__c
                    WHERE Id in: taskTemplateIds
                    AND Is_Active__c = true]);

        if(taskTemplateIdMap != null && taskTemplateIdMap.keySet().size() > 0) {
            for(Id caseId : caseTaskTemplateIdMap.keySet()) {
                tempTaskTemplate = taskTemplateIdMap.get(caseTaskTemplateIdMap.get(caseId)); 
                if(tempTaskTemplate != null) {
                    newServiceTask = new Service_Task__c(); 
                    newServiceTask.Case__c = caseId; 
                    newServiceTask.Status__c = Label.ServiceTaskStatusInProgress;
                    newServiceTask.OwnerId = UserInfo.getUserId(); 
                    newServiceTask.Time_Entry_Start__c = System.now(); 
                    newServiceTask.Start_Date_Time__c = System.now(); 
                    newServiceTask.Name = tempTaskTemplate.Name; 
                    newServiceTask.Estimated_Handle_Time_Minutes__c = tempTaskTemplate.Estimated_Handle_Time_Minutes__c; 
                    newServiceTask.Task_Type__c = tempTaskTemplate.Id; 
                    if(taskTeamName.containsKey(caseId)){
                        newServiceTask.Team_Name__c = taskTeamName.get(caseId);
                    }
                    serviceTasksToInsert.add(newServiceTask);
                }
            }
        }
        if(serviceTasksToInsert.size() > 0 ) {
            Database.insert(serviceTasksToInsert, false);
        }
    }
}