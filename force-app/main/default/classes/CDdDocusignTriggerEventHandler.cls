/**
 * @description       : 
 * @author            : Ganesh Dheekonda
 * @group             : 
 * @last modified on  : 08-04-2022
 * @last modified by  : Ganesh Dheekonda
**/
public class CDdDocusignTriggerEventHandler{
    
    public static void afterInsert(List<Docusign_Trigger_Event__e> newList){
        
        Set<Id> docSignContractUpdate = new Set<Id>();
        Set<Id> docSignOppUpdate = new Set<Id>();
        for(Docusign_Trigger_Event__e docSign:newList)
        {
            if(docSign.Event_Type__c == CDdDocusignStatusTriggerHandler.FULLY_EXECUTED_STATUS )
            {
                docSignContractUpdate.add(docSign.DocusignId__c);
            }
            if(docSign.Event_Type__c == CDdDocusignStatusTriggerHandler.CONTRACT_SIGNED_STAGE)
            {
                docSignOppUpdate.add(docSign.DocusignId__c);
            }
        }
        
        if(!docSignContractUpdate.isEmpty()){
            updateContractAgreements(docSignContractUpdate);
        }
        
        if(!docSignOppUpdate.isEmpty()){
            updateOpportunities(docSignOppUpdate);
        }
    }
    
    public static void updateContractAgreements(Set<Id> docSignContractUpdate){
        Set<Id> contractAgreementIdSet = new Set<Id>();
        for(dsfs__DocuSign_Status__c docStatus:[SELECT Id, DocuSign_Status__c FROM dsfs__DocuSign_Status__c 
                                                    WHERE Id IN:docSignContractUpdate]){
                                                    
            contractAgreementIdSet.add(docStatus.DocuSign_Status__c);
        }
        
        if(contractAgreementIdSet.isEmpty()){
            return ;
        }
        
        List<APXT_Redlining__Contract_Agreement__c> contractAgreementList = [SELECT Id, APXT_Redlining__Status__c 
                                            FROM APXT_Redlining__Contract_Agreement__c
                                            WHERE Id IN:contractAgreementIdSet
                                            AND APXT_Redlining__Status__c =:CDdDocusignStatusTriggerHandler.OUT_FOR_SIGNATURE_STATUS];
        if(!contractAgreementList.isEmpty()){
            for(APXT_Redlining__Contract_Agreement__c agreement:contractAgreementList){
                agreement.APXT_Redlining__Status__c = CDdDocusignStatusTriggerHandler.FULLY_EXECUTED_STATUS;
            }  
            
            update contractAgreementList;
        }  
    }
    
    public static void updateOpportunities(Set<Id> docSignOppUpdate){
        Set<Id> opportunityIdSet = new Set<Id>();
        for(dsfs__DocuSign_Status__c docStatus:[SELECT Id, dsfs__Opportunity__c FROM dsfs__DocuSign_Status__c 
                                                        WHERE Id IN:docSignOppUpdate]){
                                                        
            opportunityIdSet.add(docStatus.dsfs__Opportunity__c);
        }
        
        if(opportunityIdSet.isEmpty()){
            return ;
        }
        
        List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity 
                                            WHERE Id IN:opportunityIdSet 
                                            AND StageName =:CDdDocusignStatusTriggerHandler.OUT_FOR_SIGNATURE_STATUS];
           
        if(!oppList.isEmpty()){
        
            for(Opportunity opp:oppList){
                opp.StageName = CDdDocusignStatusTriggerHandler.CONTRACT_SIGNED_STAGE;
            }
            
            update oppList;
        }    
    }
    
}