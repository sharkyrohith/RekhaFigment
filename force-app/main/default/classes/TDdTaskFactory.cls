/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/02/2019
*
* @group Task Factory
*
* @description Task factory for task object
**************************************************************************************************************************************/
public class TDdTaskFactory {
    /** 
    * @description Create tasks for Accounts
    */
    public static List<Task> createTaskForAccounts(List<Account> accounts, Integer numberOfTasks, String taskType) {
        List<Task> tasksToBeCreated = new List<Task>();
        for (Account a : accounts){
            for (Integer i=0; i < numberOfTasks; i++){
                tasksToBeCreated.add(new Task(
                        Type = taskType
                        , WhatId = a.Id
                        , Subject = a.Name + ' Task ' + i
                        , Priority = 'High'
                        , Status = 'Open'
                        , Description = a.Name + ' Task ' + i + ' Description '
                    ));
            }
        } 
        return tasksToBeCreated;
    }
    /** 
    * @description Create tasks for Leads
    */
    public static List<Task> createTaskForLeads(List<Lead> leads, Integer numberOfTasks, String taskType) {
        List<Task> tasksToBeCreated = new List<Task>();
        for (Lead l : leads){
            for (Integer i=0; i < numberOfTasks; i++){
                tasksToBeCreated.add(new Task(
                        Type = taskType
                        , WhoId = l.Id
                        , Subject = l.Name + ' Task ' + i
                        , Priority = 'High'
                        , Status = 'Open'
                        , Description = l.Name + ' Task ' + i + ' Description '
                    ));
            }
        } 
        return tasksToBeCreated;
    }   
    /** 
    * @description Create tasks for Cases
    */
    public static List<Task> createTaskForCases(List <Case> cases, Integer numberOfTasks, String taskType) {
        List<Task> tasksToBeCreated = new List<Task>();
        for (Case c : cases){
            for (Integer i=0; i < numberOfTasks; i++){
                tasksToBeCreated.add(new Task(
                        Type = taskType
                        , WhatId = c.Id
                        , Subject = ' Task ' + i
                        , Priority = 'High'
                        , Status = 'Open'
                        , Description =  ' Task ' + i + ' Description '
                    ));
            }
        } 
        return tasksToBeCreated;
    }  
}