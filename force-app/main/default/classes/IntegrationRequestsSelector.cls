/********************************************************************************************************************
* @author Praveen
* @description selector class for integration object.
**************************************************************************************************************************************/

public with sharing class IntegrationRequestsSelector extends SObjectsSelector implements IIntegrationRequestsSelector {
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the IIntegrationRequestsSelector
     */
    public static IIntegrationRequestsSelector newInstance() {
        return (IIntegrationRequestsSelector) Application.Selector.newInstance(Integration_Request__x.SObjectType);
    }
    /**
     * @description Method for defining the default fields that are included in the query results.
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField>{
            Integration_Request__x.Id,
            Integration_Request__x.Store_Id__c,
            Integration_Request__x.Sfdc_status__c,
            Integration_Request__x.Sfdc_Org__c,
            Integration_Request__x.Onboarding_Id__c,
            Integration_Request__x.Integration_Provider__c,
            Integration_Request__x.Integration_Id__c,
            Integration_Request__x.Business_Id__c,
            Integration_Request__x.Previous_Integration_ID__c,
            Integration_Request__x.Previous_Integration_Provider__c,
            Integration_Request__x.Notes__c,
            Integration_Request__x.Activation_Date__c,
            Integration_Request__x.Onboarding_Type__c,   
            Integration_Request__x.Decision_Maker_Email__c,
            Integration_Request__x.Provider_Account_Owner_Email__c, 
            Integration_Request__x.Request_Owner_Email__c,
            Integration_Request__x.Action__c,
            Integration_Request__x.Exclusion_Code__c,
            Integration_Request__x.Target_Status__c,
            Integration_Request__x.Error_Message__c,
            Integration_Request__x.Integration_Type__c
        };
    }
    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Integration_Request__x.SObjectType;
    }
     /**
     * @description Method for querying integration records records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of integration requests records records.using CDdMxIntegrationObject becuase the return type having objects or classes end with __x cannot be mocked.
     */
    public CDdMxIntegrationObject selectById(Set<Id> ids) {
        return new CDdMxIntegrationObject((List<Integration_Request__x>) selectSObjectsById(ids));
    }
    /**
     * @description Method for querying integration records records when you know their status and org to process. 
     * @param Set<String> status of the integration request record
     * @param Set<String> sfdcOrg org to process the integration requests.
     * @return A list of integration requests records records.using CDdMxIntegrationObject becuase the return type having objects or classes end with __x cannot be mocked.
     */
    public CDdMxIntegrationObject selectIntegrationRequestsByStatusAndOrg(Set<String> status, Set<String> sfdcOrg, Integer days) {
        fflib_QueryFactory IntgrationRequestsQueryFactory = newQueryFactory();
        intgrationRequestsQueryFactory
        .selectFields(getSObjectFieldList())
        .setCondition('Sfdc_status__c IN :status AND Sfdc_Org__c IN: sfdcOrg AND systemmodstamp__c >= last_N_Days:'+days)
        .addOrdering(new fflib_QueryFactory.Ordering('Integration_Request__x', 'systemmodstamp__c', fflib_QueryFactory.SortOrder.ASCENDING));
        return new CDdMxIntegrationObject((List<Integration_Request__x>) Database.query(intgrationRequestsQueryFactory.toSOQL()));
    }
    /**
     * @description Method for querying integration records records when you know onboarding Id and status
     * @param Set<String> status of the integration request record
     * @param Set<String> onboardingIds.
     * @return A list of integration requests records records.using CDdMxIntegrationObject becuase the return type having objects or classes end with __x cannot be mocked.
     */
    public CDdMxIntegrationObject selectIntegrationRequestsByOnboardingIds(Set<String> onboardingIds) {
        fflib_QueryFactory IntgrationRequestsQueryFactory = newQueryFactory();
        intgrationRequestsQueryFactory
        .selectFields(getSObjectFieldList())
        .setCondition('onboarding_Id__C IN: onboardingIds')
        .addOrdering(new fflib_QueryFactory.Ordering('Integration_Request__x', 'systemmodstamp__c', fflib_QueryFactory.SortOrder.ASCENDING));
        return new CDdMxIntegrationObject((List<Integration_Request__x>) Database.query(intgrationRequestsQueryFactory.toSOQL()));
    }
}