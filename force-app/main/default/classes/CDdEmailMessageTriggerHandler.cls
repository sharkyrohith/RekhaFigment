/********************************************************************************************************************
* @Updated Raja (Criticalriver)
* @date 07/28/2021
*
* @group Trigger Handler
*
* @description Trigger handler for emailmessage object
**************************************************************************************************************************************/

public class CDdEmailMessageTriggerHandler {

    /**@author    | Raja  (Criticalriver)
     * @date       | 2021-07-29
     * @ticket     | BIZS-273
     * @param List<EmailMessage> emailrecordList
     * @return void **/

      public static void handleAfterInsertEmailMessage(List<EmailMessage> emailMessageList){

          Set<Case> caseSet = new Set<Case>();
          List<Case> casesToUpdateList = new List<Case>();
          List<Case> listOfCasesToInsert = new List<Case>();
          Map<Id,Case> mapEmailMsgToCase = new Map<Id,Case>();
          Map<Id,Case> finalMapCaseToProcess = new Map<Id,Case>();

          CDdEmailMessageHelper emailMessageHelper = new  CDdEmailMessageHelper();

          Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();
          Boolean isUpdateEmailCountOnCaseEnabled = featureFlag.Enable_updateEmailCountonCases__c;
          Boolean isEnablereopenCaseFromEmailMessage = featureFlag.Enable_reopenCaseFromEmailMessage__c ;
          Boolean isCreateEscalationCasesEnabled = featureFlag.Enable_createEscalationcases__c;
          Boolean isRedirectClosedCasesToWebEnabled = featureFlag.Redirect_Closed_Cases_to_Web__c;
          Boolean createChildCaseForClosedEmailCase = featureFlag.Auto_Create_Closed_Case_Response__c;

              if(!emailMessageList.isEmpty() && emailMessageList != null ){
                  //query cases and assign to Map
                  mapEmailMsgToCase.putAll(emailMessageHelper.queryCases(emailMessageList));
              }
              finalMapCaseToProcess.putAll(emailMessageHelper.updateLastEmail(emailMessageList,mapEmailMsgToCase));


              if (isUpdateEmailCountOnCaseEnabled){

                  finalMapCaseToProcess.putAll(emailMessageHelper.updateEmailCountonCases(emailMessageList,mapEmailMsgToCase));
              }
              if (isCreateEscalationCasesEnabled){

                  listOfCasesToInsert = emailMessageHelper.createEscalationcases(emailMessageList,mapEmailMsgToCase);

              }
              if (createChildCaseForClosedEmailCase){
                listOfCasesToInsert = emailMessageHelper.autoCreateClosedCaseResponse(emailMessageList,mapEmailMsgToCase);
              }
              if (isEnablereopenCaseFromEmailMessage){

                  finalMapCaseToProcess.putAll(emailMessageHelper.caseReopens(emailMessageList, mapEmailMsgToCase));

              }
              if (isRedirectClosedCasesToWebEnabled){

                  finalMapCaseToProcess.putAll(emailMessageHelper.redirectCasesToWeb(emailMessageList,mapEmailMsgToCase));

              }

              finalMapCaseToProcess.putAll(emailMessageHelper.populatePlatformOnCaviarMxCases(emailMessageList,mapEmailMsgToCase));

              // Call DML operation method
              if(!listOfCasesToInsert.isEmpty() && listOfCasesToInsert != null){

                  emailMessageHelper.InsertRecords(listOfCasesToInsert);
              }
              if (!finalMapCaseToProcess.isEmpty()){
                  casesToUpdateList.addAll(finalMapCaseToProcess.values());

                  emailMessageHelper.updateRecords(casesToUpdateList);
              }
      }

      public static void handleBeforeDeleteEmailmessage(List<EmailMessage> emailMessageList){

          CDdEmailMessageHelper.preventemailmessageDeletion(emailMessageList);

      }
  }