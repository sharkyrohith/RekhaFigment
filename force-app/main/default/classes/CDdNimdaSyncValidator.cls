/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/11/2019
*
* @group Nimda
*
* @description This class validates the input data points prior to sending the information to Nimda for data sync
* 
**************************************************************************************************************************************/
public class CDdNimdaSyncValidator {
  /**
  	* @description member variable to store the account record
  	**/
	private Account account;	
  /**
  	* @description member variable to store the opportunity record
  	**/
	private Opportunity opportunity;
  /**
  	* @description Default Constructor - inject the Account and Opportunity records and initialize any member variables
  	* @param Account input account record  	
  	* @param Opportunity input opportunity record
  	**/
	public CDdNimdaSyncValidator(Account account, Opportunity opportunity) {
		this.account = account;
		this.opportunity = opportunity;
	}
   /**
	* @description Is the Order Protocol - 'Point of Sale'?
	* @return Boolean true or false
	**/
	public Boolean isOrderProtocolPointOfSale(){
		return CDdNimdaSyncConstants.ORDER_PROTOCOL_POINT_OF_SALE
					.equals(CDdNimdaSyncConstants.SFTODSJ_STORE_ORDERPROTOCOLMAP.get(this.opportunity.Order_Protocol__c));
	}
   /**
	* @description Is the Opportunity Stage - 'Closed Won'
	* @return Boolean true or false
	**/
	public Boolean isOpportunityStageClosedWon(){
		return CDdNimdaSyncConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(this.opportunity.StageName);
	}
   /**
	* @description Is the Opportunity Type Protocol - Non Partner
	* @return Boolean true or false
	**/
	public Boolean isOpportunityTypeProtocolNP(){
		return CDdNimdaSyncConstants.OPPORTUNITY_TYPE_PROTOCOL_CHANGE_ONLY_NP.equals(this.opportunity.Type);
	}	
   /**
	* @description Validate the input opportunity record and return a Collection of error messages
	* The Collection returned is empty if the validation goes through successfully (i.e. without any errors)
	* @return List<String> Collection of error messages
	**/
	public List<String> validate(){
		List<String> errorMessages = new List<String>();
        if (CDdNimdaSyncConstants.VCS_API_SETTINGS.STN_SSMO_Validation__c && System.Label.NimdaSyncSelfServiceMerchantId.equals(String.valueOf(this.opportunity.CreatedById))) {
            errorMessages.add(System.Label.NimdaSyncSelfServiceMerchantErrorMsg);
        }		
		if (!isOpportunityStageClosedWon()){
			errorMessages.add(CDdNimdaSyncConstants.ERROR_MSG_INVALID_OPPORTUNITY_STAGE);
		}
		errorMessages.addAll(fieldValidator(this.opportunity, CDdNimdaSyncConstants.VALIDATE_FIELDS_ON_OPPORTUNITY));
		if (isOrderProtocolPointOfSale()){
			errorMessages.addAll(fieldValidator(this.opportunity, CDdNimdaSyncConstants.VALIDATE_POS_FIELDS_ON_OPPORTUNITY));
		}
		if (!Test.isRunningTest()){
			errorMessages.addAll(fieldValidator(this.account, CDdNimdaSyncConstants.VALIDATE_FIELDS_ON_ACCOUNT));
		}
		// Adddress validation - Either the addess fields or the geo location fields on the Account record are expected to be present
		// Step 1 - Capture the error messages (if any) related to address fields on the Account record
		List<String> addressOnAccountValidationMessages = fieldValidator(this.account, CDdNimdaSyncConstants.VALIDATE_ADDRESS_FIELDS_ON_ACCOUNT);
		// Step 2 - If address fields are invalid, capture the error messages (if any) related to geo location fields on the Account record
		if (!addressOnAccountValidationMessages.isEmpty()){
			List<String> geolocationOnAccountValidationMessages = fieldValidator(this.account, CDdNimdaSyncConstants.VALIDATE_GEOLOCATION_FIELDS_ON_ACCOUNT);
			// Step 3 - If geo location fields are invalid, write the error messages related to invalid address fields on the account record			
			if (!geolocationOnAccountValidationMessages.isEmpty()){
				errorMessages.addAll(addressOnAccountValidationMessages);
			}
		}
		return errorMessages;
	}
   /**
	* @description Validate the input collection of fields on the input SObject record
	* @param SObject obj input sObject record
	* @param List<String> fieldsToCheck - Collection of fields to check on the sObject record
	* @return List<String> Collection of error messages
	**/	
    public List<String> fieldValidator(SObject obj, List<String> fieldsToCheck) {
        if (obj == null || fieldsToCheck == null || fieldsToCheck.isEmpty()) {
            return new List<String>();
        }
        List<String> errorMessages = new List<String>();
        Schema.SObjectType objType = obj.getSObjectType();
        Map<String,Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        for (String fieldToCheck : fieldsToCheck) {
            String fieldLabel = fieldMap.get(fieldToCheck).getDescribe().getLabel();
            Schema.DisplayType fieldType = fieldMap.get(fieldToCheck).getDescribe().getType();
            if (obj.get(fieldToCheck) == null) {
                errorMessages.add('[' + objType.getDescribe().getName() + '] ' + fieldLabel + ' is null!');
            } else if (fieldType == Schema.DisplayType.String) {
                //This means the field is a string
                if (String.isBlank((String) obj.get(fieldToCheck))) {
                    errorMessages.add('[' + objType.getDescribe().getName() + '] ' + fieldLabel + ' is null!');
                }
            }
        }
        return errorMessages;
    }
    /**
     * @description Returns the Validation error messages for COO Opportunities
     * @return List<String>  Collection of error messages
     **/
    public List<String> validateForChangeOfOwnership() {
        List<String> errorMessages = new List<String>();
        //Is the Opportunity is a COO Opprtunity
        if (CDdNimdaSyncStoreHelper.isChangeOfOwnership(this.opportunity)){
            //checking for the Opportunity Proposed Date of Menu Greater than today
            if (System.today() < this.opportunity.Proposed_Date_of_Menu__c) {
                errorMessages.add(CDdNimdaSyncConstants.ERROR_MSG_CHANGE_OF_OWNERSHIP_PROPOSED_DATE_OF_MENU);
            }
        }
        return errorMessages;		
    }
}