/**
 * @author  Nayana K
 * @date    October 2022
 * @description This is the Batch job for MXP Book of Business Transfer
 */
public class MxpBobBusinessBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful{
    /*****************************************************************************************************************************
    *
    * Public Variables & Fields
    *
    *****************************************************************************************************************************/
    public Set<MXP_BoB_Update_Request__c> successfulProcessedBobRecs = new Set<MXP_BoB_Update_Request__c>();
    public Set<Id> successfulProcessedBobIds = new Set<Id>();
    public List<MXP_BoB_Update_Request__c> bobRecordsToProcess = new List<MXP_BoB_Update_Request__c>();
    public Map<Decimal,Id> mapBusinessIdNewMxpId = new Map<Decimal,Id>();
    String errorMsg = '';
    /*****************************************************************************************************************************
    *
    * Default Constructor
    *
    *****************************************************************************************************************************/
    public MxpBobBusinessBatch(){
    }

    /*****************************************************************************************************************************
    *
    * Overriden Constructor
    *
    *****************************************************************************************************************************/
    public MxpBobBusinessBatch(Set<Id> bobRecIds){
        bobRecordsToProcess = MxpBobUpdateRequestSelector.newInstance().selectByIdExtraFields(bobRecIds);
    }


    /*****************************************************************************************************************************
    *
    * Start
    *
    ****************************************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        for(MXP_BoB_Update_Request__c mxpBob:bobRecordsToProcess){
            if(mxpBob.Business_Id__c!=null && mxpBob.New_Mxp__c!=null){
                mapBusinessIdNewMxpId.put(Decimal.valueOf(mxpBob.Business_Id__c),mxpBob.New_Mxp__c);
            }
        }
        return AccountsSelector.newInstance().queryLocatorSelectAccountsByBusinessId(mapBusinessIdNewMxpId.keySet());
    }

    /*****************************************************************************************************************************
    *
    * execute
    *
    ****************************************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        try{
            //call the transfer request method
        	errorMsg = MxpBobUpdateRequestService.processBusinessIdBobRequests(mapBusinessIdNewMxpId,scope);
        }catch(Exception e){
            CDdErrorUtilities.publishException('MxpBobBusinessBatch', 'execute', e);
        }
    }

    /*****************************************************************************************************************************
    *
    * Finish
    *
    ****************************************************************************************************************************/
    public void finish(Database.BatchableContext bc) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
         //If error then reprocess else change status to completed
        if(String.isNotBlank(errorMsg)){
            for (MXP_BoB_Update_Request__c mxpBobRec: bobRecordsToProcess) {
                mxpBobRec.Batch_Job_Status__c = 'Error';
                mxpBobRec.Batch_Job_Errors__c = errorMsg;
                uow.registerDirty(mxpBobRec);
            }
        }
        else{
            for(MXP_BoB_Update_Request__c mxpBobRec: bobRecordsToProcess){
                mxpBobRec.Batch_Job_Status__c = 'Completed';
                uow.registerDirty(mxpBobRec);
                successfulProcessedBobRecs.add(mxpBobRec);
                successfulProcessedBobIds.add(mxpBobRec.Id);
            }
        }
        if(!successfulProcessedBobRecs.isEmpty()){
            Map<Id,String> mapMxPIdApproverEmail = ProcessInstanceSelector.newInstance().
                                getMapParentApprovalEmail(successfulProcessedBobIds);
            String subjectStr = '';
            String bodyStr = '';
            for(MXP_BoB_Update_Request__c mxpRec: successfulProcessedBobRecs){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String> {mxpRec.CreatedBy.Email,
                                    mxpRec.New_MXP__r.Email,mapMxPIdApproverEmail.get(mxpRec.Id)});

                subjectStr = 'Mxp Book of Business Update request data job has been completed - ' + mxpRec.Name;
                bodyStr = 'The data job to process the Mxp Book of Business update request has been completed successfully.\n\n' +
                    'Request #: ' + mxpRec.Name + CDdCoreConstants.NEW_LINE +
                    'Type: Transfer Single Business Id \n' +
                    'Description: MXP ' +  mxpRec.New_MXP__r.Name + ' has been successfully assigned to Business Id  ' + mxpRec.Business_Id__c;

                mail.setSubject(subjectStr);
                mail.setPlainTextBody(bodyStr);
                uow.registerEmail(mail); // let UnitOfWork know mail is part of Txn
            }
        }
        try {
            uow.commitWork(); // send the mail
        } catch (Exception e) {
            CDdErrorUtilities.publishException('MxpBobBusinessBatch', 'finish', e);
        }
    }

    /*****************************************************************************************************************************
     *
     * Schedular Execute
     *
     ****************************************************************************************************************************/
    public void execute(SchedulableContext sc) {
        MxpBobBusinessBatch batch = new MxpBobBusinessBatch();
        Database.executeBatch(batch);
    }
}