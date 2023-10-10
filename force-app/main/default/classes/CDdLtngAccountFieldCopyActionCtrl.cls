/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/23/2019
*
* @group SObject Field Copy
*
* @description This is a Apex (and Lightning) controller class for 'Account Field Copy' action.
* The user is expected to be in Parent Account detail record page to invoke this quick action 'Account Field Copy'
* - The input record identifier is evaluated for SObject type Account
* - Batch job(s) are submitted for the parent record identifier
* - Batch job identifier(s) are returned to the Lightning Component for further monitoring 
* 
**************************************************************************************************************************************/
public class CDdLtngAccountFieldCopyActionCtrl {
    /**
    * @description Copy fields for input record identifiers
    * @param recordIds A List Collection of Identifiers  
    * @return Id return the submitted batch job identifier(s)
    **/
    @AuraEnabled
    public static String copyFields(Id recordId) {
        String sObjectType = recordId.getSObjectType().getDescribe().getName();
        return  ( (sObjectType.equals('Account')) 
                ? Database.executeBatch(new CDdAccountFieldCopyToAccountBatch(new List<Id>{recordId}))
                    +	','
                    +	Database.executeBatch(new CDdAccountFieldCopyToLeadBatch(new List<Id>{recordId}))
                : null );       
    }    
}