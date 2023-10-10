/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/05/2019
*
* @group Trigger Handler
*
* @description This trigger handler is a subscriber to the 'Update Task Count' platform event
* 
**************************************************************************************************************************************/
public class CDdUpdateTaskCountEventHandler {

    public static final String SOBJECT_TYPE_LEAD = 'Lead';
    public static final String SOBJECT_TYPE_ACCOUNT = 'Account';

    /**
    * @description fire this method after the 'Update Task Count' event is published
    */
    public void afterInsert(List<Update_Task_Count_Event__e> newList) {
        Set<Id> leadIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Update_Task_Count_Event__e e : newList){
            if (SOBJECT_TYPE_LEAD.equals(e.SObject_Type__c)){
                leadIds.add((Id)e.SObject_Record_Id__c);
            }
            if (SOBJECT_TYPE_ACCOUNT.equals(e.SObject_Type__c)){
                accountIds.add((Id)e.SObject_Record_Id__c);
            }            
        }
        if (!leadIds.isEmpty()){
            CDdTaskHelperMethods.applyTaskCountForLeads(leadIds);
        }
        if (!accountIds.isEmpty()){
            CDdTaskHelperMethods.applyTaskCountForAccounts(accountIds);
        }
    }
}