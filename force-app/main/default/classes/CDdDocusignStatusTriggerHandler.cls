/**
 * CDdDocusignStatusTriggerHandler
 *
 * @author     Ganesh Dheekonda
 * @date  3/8/2022
 * @decription Trigger handler for Docusign status Trigger.
 */
public class CDdDocusignStatusTriggerHandler{
    
    public static final String DS_ENVELOPE_STATUS_COMPLETED = 'Completed';
    public static final String OUT_FOR_SIGNATURE_STATUS = 'Out for Signature';
    public static final String FULLY_EXECUTED_STATUS = 'Fully Executed';
    public static final String CONTRACT_SIGNED_STAGE = 'Contract Signed';
    
    public static void afterInsert(List<dsfs__DocuSign_Status__c> newList){
        updateContract_OpportunityWhenDSCompleted(newList, null);
    }
    
    public static void afterUpdate(List<dsfs__DocuSign_Status__c> newList, Map<Id, dsfs__DocuSign_Status__c> oldMap){
        updateContract_OpportunityWhenDSCompleted(newList, oldMap);
    }
    
    /**
     *@ author : Ganesh Dheekonda
     *@purpose : BZAP-15837 - Update Opportunity or contract agreement when status is completed.     
     */
    public static void updateContract_OpportunityWhenDSCompleted(List<dsfs__DocuSign_Status__c> newList, 
                                                                    Map<Id, dsfs__DocuSign_Status__c> oldMap){
        
        List<Docusign_Trigger_Event__e> docSignEventList = new List<Docusign_Trigger_Event__e>();
        
        for(dsfs__DocuSign_Status__c docStatus:newList){
        
            dsfs__DocuSign_Status__c oldDoc = oldMap!=null ? oldMap.get(docStatus.Id) : null;
            
            if(docStatus.dsfs__Envelope_Status__c == DS_ENVELOPE_STATUS_COMPLETED){
                
                if(docStatus.DocuSign_Status__c != null
                    && (oldDoc == null 
                        || (docStatus.dsfs__Envelope_Status__c != oldDoc.dsfs__Envelope_Status__c
                            || docStatus.DocuSign_Status__c != oldDoc.DocuSign_Status__c)
                        )                       
                ){
                    Docusign_Trigger_Event__e docSignEvent = new Docusign_Trigger_Event__e();
                    docSignEvent.DocusignId__c = docStatus.Id;
                    docSignEvent.Event_Type__c = CDdDocusignStatusTriggerHandler.FULLY_EXECUTED_STATUS;
                    docSignEventList.add(docSignEvent);
                    
                
                }else if(docStatus.dsfs__Opportunity__c != null
                        && (oldMap == null 
                            || docStatus.dsfs__Envelope_Status__c != oldDoc.dsfs__Envelope_Status__c)
                ){
                    
                    Docusign_Trigger_Event__e docSignEvent = new Docusign_Trigger_Event__e();
                    docSignEvent.DocusignId__c = docStatus.Id;
                    docSignEvent.Event_Type__c = CDdDocusignStatusTriggerHandler.CONTRACT_SIGNED_STAGE;
                    docSignEventList.add(docSignEvent);
                    
                }
                
            }
        }
        
        if(docSignEventList.size()>0)
        {
            List<Database.SaveResult> results = EventBus.publish(docSignEventList);
            CDdErrorUtilities.publishException('CDdDocusignStatusTriggerHandler', 'updateContract_OpportunityWhenDSCompleted', results);
        }
    }
    
}