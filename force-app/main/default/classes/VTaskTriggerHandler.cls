public class VTaskTriggerHandler {

    public void onBeforeInsert(List<Task> newList){
        
        List<Id> whatIdList = new List<Id>();
        List<Task> callTaskList = new List<Task>();
        for (Task curTask : newList){
            if (curTask.WhatId != null) {
                if (curTask.Status == 'Completed' &&
                    curTask.Subject.toLowerCase().contains('call')==true){
                        whatIdList.add(curTask.WhatId);
                        callTaskList.add(curTask);
                }
            }   
        }
        
        List<Case> whatCaseList = new List<Case>();
        if (whatIdList.size() > 0){
            whatCaseList = [SELECT Id, LoggedCallCount__c
                            FROM Case
                          	WHERE Id in: whatIdList];
        }
        
        if (whatCaseList.size() > 0){
            for (Case curCase : whatCaseList){
                Integer callCount = 0;
                for (Task curTask : callTaskList){
                    if (curTask.WhatId == curCase.Id){
                        callCount++;
                    }
                }
                
                if (curCase.LoggedCallCount__c == null){
                    curCase.LoggedCallCount__c = callCount;
                } else {
                    curCase.LoggedCallCount__c += callCount;
                }
                
                if (callCount != 0){
                    curCase.Last_Phone_Call__c = System.now();
                }
            }
            
            update whatCaseList;
        }
    }

    public void onBeforeUpdate(Map<Id,Task> newMap, Map<Id,Task> oldMap){
        
        List<Id> whatIdList = new List<Id>();
        List<Task> callTaskList = new List<Task>();
        
        for (Id curId : newMap.keySet()){
            Task newTask = newMap.get(curId);
            Task oldTask = oldMap.get(curId);
            
            if (newTask.WhatId != null) {
                if ((newTask.Status  != oldTask.Status) &&
                    (newTask.Status == 'Completed') &&
                    (newTask.Subject.toLowerCase().contains('call')==true)){
                        whatIdList.add(newTask.WhatId);
                        callTaskList.add(newTask);
                }
            }   
        }
        
        List<Case> whatCaseList = new List<Case>();
        if (whatIdList.size() > 0){
            whatCaseList = [SELECT Id, LoggedCallCount__c
                            FROM Case
                          	WHERE Id in: whatIdList];
        }
        
        if (whatCaseList.size() > 0){
            for (Case curCase : whatCaseList){
                Integer callCount = 0;
                for (Task curTask : callTaskList){
                    if (curTask.WhatId == curCase.Id){
                        callCount++;
                    }
                }
                if (curCase.LoggedCallCount__c == null){
                    curCase.LoggedCallCount__c = callCount;
                } else {
                    curCase.LoggedCallCount__c += callCount;
                }
                
                if (callCount != 0){
                    curCase.Last_Phone_Call__c = System.now();
                }
            }
            
            update whatCaseList;
        }
         
    }
}