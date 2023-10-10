/********************************************************************************************************************
* @author Praveen
* @date 1/17/2023
*
* @group Merchant Services
*
* @description This class is queries the pending pos integration records from the external object and publish the mxsx events for processing.
**************************************************************************************************************************************/

public class CDdMxSxIntegrationRequestScheduler implements Schedulable{
    private static final String INTEGRATION_TYPE_POS = 'POS Requests';
    private static final String ACTION_UPDATE = 'UPDATE';
    private static final String ACTION_CREATE = 'CREATE';
    private static final String STATUS_FAILED = 'Failed';


    /**
    * @description execute the process.
    **/
    public void execute(SchedulableContext sc){
            Set<String> status = new Set<String>{CDdMxSxConstants.POS_INTEGRATION_REQUESTS_STATUS_PENDING};
            Set<String> sfdcOrg = new Set<String>{CDdMxSxConstants.POS_INTEGRATION_REQUESTS_ORG_FIGMENT};
            CDdMxIntegrationObject integrationRequests = integrationRequestsSelector.newInstance().selectIntegrationRequestsByStatusAndOrg(status, sfdcOrg, 2);
            List<Integration_Request__x> posIntRequests = new  List<Integration_Request__x>();
            for(Integration_Request__x eachInt: integrationRequests.integrationRequests){
                if(INTEGRATION_TYPE_POS.equals(eachInt.Integration_Type__c)){
                    posIntRequests.add(eachInt);
                }
            }
            publishBatPosEvents(posIntRequests);
            delSchedule(); //delete this instance of the job
            setSchedule(); //schedule new instance of the job

    }

    public void publishBatPosEvents(List<Integration_Request__x> posIntReqs){
        Set<String> validRequests = new Set<String>();
        Set<String> updateOnboardingIds = new Set<String>();
        List<Integration_Request__x> failedIntRequests =  new List<Integration_Request__x>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Case.fields.getMap().get('POS_Integration_Type__c').getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Set<String> providerTypes = new Set<String>();
        for (Schema.PicklistEntry picklistEntry : picklistValues) {
            providerTypes.add(picklistEntry.getValue());
        }
        for(Integration_Request__x request: posIntReqs){
            if(request.Action__c == ACTION_CREATE){
                if(providerTypes.contains(request.Integration_Provider__c)){
                    validRequests.add(Request.onboarding_Id__C);
                }else{
                    request.sfdc_status__c = STATUS_FAILED;
                    request.Error_Message__c = 'Provider type not exists in salesforce';
                    failedIntRequests.add(request);
                }
            }
            if(request.Action__c == ACTION_UPDATE){
                updateOnboardingIds.add(Request.onboarding_Id__C);
            }
        }
        for(Case eachCase: CasesSelector.newInstance().selectByOnboardingIdAndrecorTypeAndStatus(updateOnboardingIds, new Set<Id>{CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS}, CDdMxSxConstants.OB_CASE_OPEN_STATUS)){
            validRequests.add(eachCase.onboarding_id__c);
        }
        CDdMxSxEventPublisher.publishMxSxEventsForPosIntegrationRequestsFromBat(CDdMxSxConstants.SOBJECT_TYPE_POS_INTEGRATION_REQUEST, validRequests);
        if(!test.isrunningTest() && !failedIntRequests.isEmpty()){
            Database.updateAsync(failedIntRequests);
        }
    }

    /**
    * @description  delete the current schedule
    **/
    public static void delSchedule(){
        try{
            ApexClass self = [SELECT Id FROM ApexClass WHERE Name = 'CDdMxSxIntegrationRequestScheduler'];  //get the ID of this class
            for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name like 'IntegrationRequest%' OR CronJobDetail.Name = :self.Id]){
                system.abortjob(ct.id); //cancel all scheduled runs of this class
            }
        }catch (Exception ex) {
            CDdErrorUtilities.publishException('IntegrationRequest','CDdMxSxIntegrationRequestScheduler', ex);
        }
    }
    /**
    * @description  add the schedule for the next iteration
    **/
    public static void setSchedule(){
        try{
            DateTime nextRun = System.now().addMinutes(CDdMxSxConfigHelper.INTEGRATION_REQUEST_SCHEDULER_FREQUENCY_MIN);
            String cronExp = '0 ' + nextRun.minute() + ' ' + nextRun.hour() + ' * * ?';
            String jobName = 'IntegrationRequest ' + nextRun.format('hh:mm a');
            CDdMxSxIntegrationRequestScheduler job = new CDdMxSxIntegrationRequestScheduler();
            System.schedule(jobName, cronExp, job);
        }catch (Exception ex) {
            CDdErrorUtilities.publishException('IntegrationRequest','CDdMxSxIntegrationRequestScheduler', ex);
        }
    }
}