/**
 * CDdSendbirdRESTServiceHelper
 *
 * @author     Sahil (sahil.chaudhry@doordash.com)
 * @date       2022-11-02
 * @decription helper methods for sendbird REST webservice
*/
public with sharing class CDdSendbirdRESTServiceHelper {
    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        11/2022
     * @decription
     * @param
     * @return
    */
    public static Object createSendbirdChatCase(Blob requestPayload) {
        try {
            //stringify request payload
            String payloadString = requestPayload.toString();
            //prepare a case object to insert to database
            Case caseObj = (Case)JSON.deserialize(payloadString, Case.class);
            Id caseIdFromDB;
            Map<Id,Queue_Overflow_Configuration__c> caseIdOverflowConfigMap =
                                            new Map<Id,Queue_Overflow_Configuration__c>();
            CreateCaseResponse caseRespObj = new CreateCaseResponse();
            //insert case into database
            Database.SaveResult caseInsertResult = Database.insert(caseObj);
            //get Id of inserted case. Use it to get case owner
            if (caseInsertResult != null && caseInsertResult.isSuccess()) {
                caseIdFromDB = caseInsertResult.getId();
                caseRespObj.caseId = caseIdFromDB;
            } else {
                for (Database.Error err : caseInsertResult.getErrors()) {
                    throw new CDdSendbirdRESTServiceHelperException(err.getMessage());
                }
            }
            //get wait time of inserted case's owner
            List<Case> caseObjFromDB = [SELECT OwnerId
                                         FROM Case
                                         WHERE Id =:caseIdFromDB];
            if (caseObjFromDB.isEmpty()) {
                throw new CDdSendbirdRESTServiceHelperException('No Case found in Salesforce Database');
            } else {
                Id caseOwnerId = caseObjFromDB[0].OwnerId;
                caseRespObj.caseOwnerId = caseOwnerId;
                //if owner is group then process further to get wait time of the assigned group
                if (CDdUtilities.idIsGroup(caseOwnerId)) {
                    List<Queue_Overflow_Configuration__c> qOFloConfigList =
                                                        [SELECT Average_Wait_Time__c
                                                            FROM Queue_Overflow_Configuration__c
                                                            WHERE Queue_Id__c =:caseOwnerId];
                    for (Queue_Overflow_Configuration__c qOFCVar : qOFloConfigList) {
                        caseRespObj.avgWaitTime = qOFCVar.Average_Wait_Time__c;
                    }
                }
            }
            return caseRespObj;
        } catch (Exception ex) {
            throw new CDdSendbirdRESTServiceHelperException(ex.getMessage());
        }
    }

    public class CreateCaseResponse {
        public String caseId;
        public String caseOwnerId;
        public Decimal avgWaitTime;
    }

    public class CDdSendbirdRESTServiceHelperException extends Exception{}
}