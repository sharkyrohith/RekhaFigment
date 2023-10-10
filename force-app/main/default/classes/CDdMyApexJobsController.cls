/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 11/29/2020
*
* @group Apex Jobs
*
* @description This Lightning Controller is to query and return apex job information as found in AsyncApexJob
* 
**************************************************************************************************************************************/
public class CDdMyApexJobsController {

    public class CDdMyApexJobsControllerException extends Exception{}

    @AuraEnabled(cacheable=true)
    public static List<AsyncApexJob> getMyApexJobs(String userId, String apexClassName){
        try {
            List<AsyncApexJob> jobs = new List<AsyncApexJob>();
            for (AsyncApexJob job : [SELECT Id, CreatedDate, Status, TotalJobItems, JobItemsProcessed, NumberOfErrors, CompletedDate 
                                    FROM AsyncApexJob 
                                    WHERE CreatedById = :userId
                                    AND ApexClass.Name = :apexClassName
                                    ORDER BY CreatedDate DESC
                                    LIMIT 10]){
                jobs.add(job);                        
            }
            if (jobs.isEmpty()){
                throw new CDdMyApexJobsControllerException(System.Label.DDS2N_ApexJobController_NoJobs_Error);
            }
            return jobs;          
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}