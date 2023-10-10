/**
 * @author  Sanidhya Jain L
 * @date    January 2023
 * @description This is the service implementation class for closing the cases.
 */

 public inherited sharing class CloseOpenCasesRequestServiceImpl implements ICloseOpenCasesRequestService   {

    Public static final String caseCloseNote = '\n Aging case closed by DoorDash due to backlog. See ticket: https://doordash.atlassian.net/servicedesk/customer/portal/45/BASD-40135';
    @TestVisible
    public static final String INACTIVE_AGENT_CASE_DESCRIPTION = '\n Case triaged due to inactive agent. See ticket: https://doordash.atlassian.net/servicedesk/customer/portal/45/BASD-40357';

    /*
    * @description : Method to update cases which were not updated from last six months
    * @return String errorMsg
    */
    public List<String> updateOpenCasestoClose(List<Case> caseList){

        CaseDmlResultsHandler myCaseDmlHan = new CaseDmlResultsHandler();
        List<String> errorMessages = new List<String>();
         fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance(
            new UnitOfWorkPartialSaveDml(myCaseDmlHan));

        try{
            for(Case caseobj :caseList){
                String description = '';
                if(String.isNotBlank(caseobj.Description)){
                    description = caseobj.Description;
                }
                uow.registerDirty(closeCases(caseobj, description + caseCloseNote));
            }
            uow.commitWork();
        }catch (Exception e) {
            errorMessages.add(CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e));
        }
        errorMessages.addAll(myCaseDmlHan.errorMessages);
        return errorMessages;
    }

    /*
    * @description : Method to update cases which are owned by Inactive users
    * @return String errorMsg list
    */
    public List<String> handleCasesWithInactiveOwner(List<Case> caseList){
        CaseDmlResultsHandler myCaseDmlHan = new CaseDmlResultsHandler();
        List<String> errorMessages = new List<String>();
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance(new UnitOfWorkPartialSaveDml(myCaseDmlHan));

        try{
            for(Case cs : caseList){
                String description = '';
                if(String.isNotBlank(cs.Description)){
                    description = cs.Description;
                }
                switch on cs.Origin {
                    when 'Phone', 'Chat' {
                        if(cs.Previous_Queue_ID__c == null || CDdSupportHelper.isLiveQueue(cs.Previous_Queue_ID__c)){
                            uow.registerDirty(closeCases(cs, description + INACTIVE_AGENT_CASE_DESCRIPTION));
                        }
                        else {
                            //If Previous Queue is Non-live Queue
                            cs.OwnerId = cs.Previous_Queue_ID__c;
                            cs.Description = description + INACTIVE_AGENT_CASE_DESCRIPTION;
                            uow.registerDirty(cs);
                        }
                    }
                    when 'Web', 'Email', 'API' {
                        cs.OwnerId = cs.Previous_Queue_ID__c != null ? cs.Previous_Queue_ID__c : cs.Initial_Queue__c;
                        cs.Description = description + INACTIVE_AGENT_CASE_DESCRIPTION;
                        uow.registerDirty(cs);
                    }
                }
            }
            CDdCaseTransferValidationHelper.BYPASS_CASE_TRANSFER_VALIDATION_FOR_THIS_TXN = true;
            uow.commitWork();
            CDdCaseTransferValidationHelper.BYPASS_CASE_TRANSFER_VALIDATION_FOR_THIS_TXN = false;
        }catch (Exception e) {
            errorMessages.add(CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e));
        }
        errorMessages.addAll(myCaseDmlHan.errorMessages);
        return errorMessages;
    }

    /*
    * @description : Update Case with fields required for Closing
    * @return Case caseRecord
    */
    private static Case closeCases(Case cs, String caseNote){
        switch on cs.Customer_Type__c {
            when 'Consumer' {
                cs.Issue_Type__c  = 'Other - CX';
                cs.Resolution_Type__c = 'Other - CX';
            }
            when 'Merchant' {
                cs.Issue_Type__c  = 'Other - MX';
                cs.Resolution_Type__c = 'Other - MX';
            }
            when 'Dasher' {
                cs.Issue_Type__c  = 'Other - DX';
                cs.Resolution_Type__c = 'Other - DX';
            }
        }
        cs.Issue__c = 'Unresolved Contact: Dropped';
        cs.Resolution__c  = 'Other';
        cs.Status = 'Closed';
        if(String.isNotBlank(caseNote)){
            cs.Description = caseNote;
        }
        return cs;
    }

    /*
    * @description : Method to overirde IhandleDmlResult interface
    * @return List<String> errorMsg
    */
    public class CaseDmlResultsHandler extends HandleDmlResults {
        public List<String> errorMessages = new List<String>();

        public override void handle(Database.SaveResult[] results) {
            for(Database.SaveResult sr : results) {
                if(sr.isSuccess()){
                    continue;
                }
                for(Database.Error err : sr.getErrors()) {
                    errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + 'RecordID : ' + sr.getID() +  ' : Fields : ' + err.getFields());
                }
            }
        }
    }
}