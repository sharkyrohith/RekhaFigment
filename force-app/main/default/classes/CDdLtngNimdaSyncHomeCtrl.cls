/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/18/2020
*
* @group Nimda
*
* @description This is the Lightning Controller for Nimda Sync Home component
* Purpose of this controller is to
* - Read the custom metadata 'Nimda Onboarding Step'
* - Return a Collection object with relevant onboarding steps and corresponding step attributes for display on the Nimda Home component
* 
**************************************************************************************************************************************/
public class CDdLtngNimdaSyncHomeCtrl {
    /**
    * @description Return a Collection of Map object with Nimda steps and corresponding attributes available for display on the Nimda Home Component
    * For Change of Ownership, 
    *   If transfer of old store is complete (i.e move of old store from Account to Opportunity Original_Store_Id__c)
    *   Then
    *       storeExistsOnAccount = true (in other words the new merchant store id is created successfully and populated on the Account by MuleSoft)
    *   Else
    *       storeExistsOnAccount = false
    * If NOT Change of Ownership
    *   a) storeExistsOnAccount = true, if Opportunity.Store_Id__c is not blank
    *   b) storeExistsOnAccount = false, if Opportunity.Store_Id__c is blank
    * @param Boolean storeExistsOnAccount
    * @param Boolean isChangeOfOwnership - Is the onboarding request for Change of Ownership
    * @return <Map<String, Object>> A collection of Map object
    **/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getSendToNimdaSteps(Opportunity opportunity) {
        Boolean isChangeOfOwnership = CDdNimdaSyncStoreHelper.isChangeOfOwnership(opportunity);
        Boolean storeExistsOnAccount = isChangeOfOwnership ? String.isNotBlank(opportunity.Original_Store_Id__c) : String.isNotBlank(opportunity.Store_Id__c);
    	return CDdNimdaSyncOnboardingConfigHelper.getSendToNimdaSteps(storeExistsOnAccount, isChangeOfOwnership);
    }
    /**
    * @description Return a Collection of Map object with Nimda bulk steps and corresponding attributes available 
    * for display on the Bulk Uploader Actions component
    * @return <Map<String, Object>> A collection of Map object
    **/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getBulkSteps() {
        return CDdNimdaSyncOnboardingConfigHelper.getBulkSteps();
    }        
}