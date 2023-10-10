/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/10/2019
*
* @group SObject Field Copy
*
* @description This is a Apex (and Lightning) controller class for 'Account Field Copy' mass action.
* The user may select one or more records (Accounts) from the List View for 'Account Field Copy'
* - The input record identifiers are evaluated for SObject type Account
* - A batch job is submitted for the Collection of record identifiers
* - The batch job identifier is returned to the Lightning Component for further monitoring 
* 
**************************************************************************************************************************************/
public class CDdAccountFieldCopyCtrl {
    public ApexPages.StandardSetController setCon;
    public String selectedIdsSerializedString {get; set;}
    public String retURL {get; set;}
    /**
    * @description Constructor for a Colection of records
    * @param controller the Standard Set Controller is injected.
    * @return 
    **/    
    public CDdAccountFieldCopyCtrl(ApexPages.StandardSetController controller){
    	this.setCon = controller;
    	this.setSelectedIdsSerializedString();
        this.setRetURL();
    }
    /**
    * @description The selected record identifiers are stored as a serialized array string
    * @param 
    * @return 
    **/ 
    public void setSelectedIdsSerializedString(){
    	List<String> selectedIds = new List<String>();
    	for (SObject obj : this.setCon.getSelected()){
    		selectedIds.add((String)obj.get('Id'));
    	}
    	this.selectedIdsSerializedString = JSON.serialize(selectedIds);
    }
    /**
    * @description The return URL. This is of any significance if the Account Field Copy is executed in Salesforce Classic
    * @param 
    * @return 
    **/ 
    public void setRetURL(){
        this.retURL = System.currentPageReference().getParameters().get('retURL');
    }    
    /**
    * @description Copy fields for input record identifiers
    * @param recordIds A List Collection of Identifiers  
    * @return Id return the submitted batch job identifier
    **/
    @AuraEnabled
    public static Id copyFields(List<Id> recordIds) {
        String sObjectType = recordIds.get(0).getSObjectType().getDescribe().getName();
        return  ( (sObjectType.equals('Account')) ? Database.executeBatch(new CDdAccountFieldCopyToAccountBatch(recordIds)): null );       
    }    
}