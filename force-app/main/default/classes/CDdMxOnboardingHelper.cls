/********************************************************************************************************************
* @author Lathika
* @date 08/25/2022
* @group Merchant Services
* @description Implementation class for MxOnboarding Updates from Mx portal
*
**************************************************************************************************************************************/
public abstract class CDdMxOnboardingHelper {
/**
 * @description Retrieve the eligible sObject records for Updation in Trigger
 * @return  Map<Id, sObject>
*/   
public abstract Map<Id, sObject> getsObjectsToUpdate(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap);
/**
 * * @description Retrieve the eligible sObject records for Updation from Batch /Platform Events implementation
 * @return  Map<Id, sObject>
*/
public abstract Map<Id, sObject> getsObjectsToUpdate(List<Mx_Onboarding__c> mxOnboardingRecords);    
}