/**
 * @author: Nayana Kapse
 * @date: Feb 2022
 * @description Case Detail Trigger Handler
 */
public inherited sharing class CDdCaseDetailTriggerHandler extends CDdTriggerHandler {
    private List<Case_Detail__c> triggerNew;
    private List<Case_Detail__c> triggerOld;
    private Map<Id, Case_Detail__c> triggerMapNew;
    private Map<Id, Case_Detail__c> triggerMapOld;

    public CDdCaseDetailTriggerHandler() {
        this.triggerOld = (List<Case_Detail__c>) Trigger.old;
        this.triggerNew = (List<Case_Detail__c>) Trigger.new;
        this.triggerMapNew = (Map<Id, Case_Detail__c>) Trigger.newMap;
        this.triggerMapOld = (Map<Id, Case_Detail__c>) Trigger.oldMap;
    }

    override public void beforeInsert() {
        assignCaseId();
    }

    override public void beforeUpdate() {
        assignCaseId();
    }

    override public void afterInsert() {
        assignCaseDetailToCase();
    }

    override public void afterUpdate() {
        assignCaseDetailToCase();
    }

    /**
     * @description  When new Case detail record is created/Case is updated assign Unique Id field to maintain 1:1 
     * @param   Case_Detail__c newCaseDetail - Case in trigger.new
     *          Map<Id, Case_Detail__c> oldMap - trigger.oldMap
     * @return  Boolean
     */
    private void assignCaseId(){
        if (CDdCustomMetaData.isDisabled('CDdCaseDetailTriggerHandler_assignCaseId')) {
            return;
        }
        for(Case_Detail__c cDetail:triggerNew){
            if(isNewOrFieldUpdated(cDetail,'Case__c')){
                cDetail.Case_Unique_Id__c =  cDetail.Case__c;
            }
        }
    }

    /**
     * @description  When new Case detail record is created/Case is updated update Case Detail Id back on Case
     * @param   Case_Detail__c newCaseDetail - Case in trigger.new
     *          Map<Id, Case_Detail__c> oldMap - trigger.oldMap
     *          operationType - Trigger operation type
     * @return  Boolean
     */
    private void assignCaseDetailToCase(){
        if (CDdCustomMetaData.isDisabled('CDdCaseDetailTriggerHandler_asgnCaseDet')) {
            return;
        }
        List<Case> lstCaseToUpdate = new List<Case>();
        Case_Detail__c oldCaseDetail = new Case_Detail__c();
        for(Case_Detail__c cDetail:triggerNew){
            if(isNewOrFieldUpdated(cDetail,'Case__c')){
                lstCaseToUpdate.add(new Case(Id =cDetail.Case__c,Case_Detail__c = cDetail.Id));
                //If update then make Case Detail null for old case
                if (getTriggerContext() == CDdTriggerHandler.TriggerContext.AFTER_UPDATE){
                    oldCaseDetail = triggerMapOld.get(cDetail.Id);
                    lstCaseToUpdate.add(new Case(Id =oldCaseDetail.Case__c,Case_Detail__c = null));
                }
                
            }
        }
        if(!lstCaseToUpdate.isEmpty()){
            List<Database.SaveResult> results = Database.update(lstCaseToUpdate,false);
            CDdErrorUtilities.publishException('CDdCaseDetailTriggerHandler','assignCaseDetailToCase',results);
        }
    }
}