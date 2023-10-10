/**
 * @description Selector Class for Opportunity SObject
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
public inherited sharing class OpportunitiesSelector extends SObjectsSelector implements IOpportunitiesSelector {
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the IOpportunitiesSelector
     */
    public static IOpportunitiesSelector newInstance() {
        return (IOpportunitiesSelector) Application.Selector.newInstance(Opportunity.SObjectType);
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Opportunity.AccountId,
            Opportunity.CloseDate,
            Opportunity.Id,
            Opportunity.Name,
            Opportunity.OwnerId,
            Opportunity.RecordTypeId,
            Opportunity.StageName,
            Opportunity.Type,
            Opportunity.SBQQ__PrimaryQuote__c,
            Opportunity.Prebot_Link__c,
            Opportunity.Prebot_Error__c,
            Opportunity.Proposed_Date_of_Activation__c
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Opportunity.SObjectType;
    }

    /**
     * @description Method for querying Opportunity records when you know their ids
     *
     * @param ids The ids of the records to be returned
     * @return A list of Opportunity records
     */
    public List<Opportunity> selectById(Set<Id> ids) {
        return (List<Opportunity>) selectSObjectsById(ids);
    }

    /**
     * @description Method for querying Onboarding Opportunity records when you know their ids
     * This method will also return child relationship records namely Opportunity Line Items and Cases
     * @param opportunityIds The ids of the opportunity records to be returned
     * @return A list of Opportunity records with related Opportunity Line Items and Cases
     */
    public List<Opportunity> selectOnboardingOpportunitiesWithLineItemsAndCases(Set<Id> opportunityIds) {
        Set<Id> MXSX_OPPORTUNITY_RECORD_TYPE_IDS = CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS;
        Id RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT = CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT;
        Set<String> OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE = CDdMxSxConstants.OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE;
        // to pass codescan checks - referencing and checking for null for the above vars
        if (MXSX_OPPORTUNITY_RECORD_TYPE_IDS == null || RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT == null || OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE == null) { return null; }
        fflib_QueryFactory opportunityQueryFactory = newQueryFactory();
        opportunityQueryFactory
        .selectFields(getSObjectFieldList())
        .selectFields(new Set<String>{
            'Store_Manager__c', 'Bulk_Activation__c', 'Notes__c', 'PactSafe_Contract_Type__c', 'Decision_Maker__c', 'Lead_Source_Detail__c', 'CreatedBy.Id',
            'Account.RecordTypeId', 'Account.ParentId', 'Account.Parent.RecordTypeId', 'Account.Parent.Deck_Rank__c',
            'Account.Is_Test_Store__c', 'Account.Business_ID__c', 'Account.Deck_Rank__c', 'Account.Launch_Deck_Rank__c', 'Platform__c'
        })
        .setCondition('Id IN :opportunityIds '
            + ' AND RecordTypeId IN :MXSX_OPPORTUNITY_RECORD_TYPE_IDS '
            + ' AND AccountId != NULL '
            + ' AND Account.Is_Test_Store__c = false '
            + ' AND ( '
                    + ' Account.ParentId = NULL '
                    + ' OR Account.RecordTypeId = :RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT '
                    + ' OR Account.Parent.RecordTypeId = :RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT '
            + ' ) '
            + ' AND Type NOT IN :OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE '
        );
        // add the Opportunity Items
        fflib_QueryFactory opportunityLineItemsFactory = opportunityQueryFactory.subselectQuery('OpportunityLineItems');
        opportunityLineItemsFactory.selectFields(new Set<String>{
            'Id', 'Name', 'Product2Id', 'Product2.Id', 'Product2.Family',
            'Product2.Name', 'Product2.Priority_for_Activation__c', 'Quantity',
            'Delay_after_Activation_days__c', 'Length_of_Term__c'
        });
        // add the related Cases
        fflib_QueryFactory casesFactory = opportunityQueryFactory.subselectQuery('Cases__r');
        casesFactory.selectFields(new Set<String>{
            'Id', 'RecordTypeId', 'AccountId', 'Opportunity_Name__c', 'ProductId'
        })
        .addOrdering(new fflib_QueryFactory.Ordering('Case', 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING))
        .addOrdering(new fflib_QueryFactory.Ordering('Case', 'ClosedDate', fflib_QueryFactory.SortOrder.DESCENDING));
        return (List<Opportunity>) Database.query(opportunityQueryFactory.toSOQL());
    }

    /**
     * @description Method for querying the opportunities using accountIds.
     * @param Set<Id> accountId Opportunity accountId sfor opportunity search.
     * @return List<Opportunity> A list of Opportunity records
     */
    public List<Opportunity> getOpportunitiesByAccountIds(Set<Id> accountIds) {
        fflib_QueryFactory opportunityQueryFactory = newQueryFactory();
        opportunityQueryFactory
        .selectFields(getSObjectFieldList())
        .selectFields(new Set<String>{
              'RecordType.Name', 'Order_Protocol__c', 'platform__c'
        })
        .setCondition('AccountId = :accountIds ')
        .addOrdering(new fflib_QueryFactory.Ordering('opportunity','AccountId', fflib_QueryFactory.SortOrder.DESCENDING));
        return (List<Opportunity>) Database.query(opportunityQueryFactory.toSOQL());
    }
     /**
     * @description Method for searching the opportunities.As we cannot use fflib_QueryFactory for SOSL used standard query for search.
     * Search Method returns maximum of 2000 records.
     * @param String searchTerm Opportunity name search ** Opportunity Name **
     * @param Set<Id> accountId Opportunity accountId for opportunity search.
     * @return List<List<sObject>> of Opportunity records
     */
    public List<List<sObject>> searchOpportunitiesBysearchTermAndAccountIds(String searchTerm, Set<Id> accountIds) {
        String searchQuery = 'FIND :searchTerm IN ALL FIELDS '
            + ' RETURNING Opportunity(Id, stageName ,CloseDate ,Name, RecordType.Name, Order_Protocol__c, platform__c '
            + ' WHERE AccountId IN: accountIds '
            + ' ORDER BY AccountId DESC)';
        return search.query(searchQuery);
    }

    /**
        @author: Dan Thoreson
        @date: 06-Jan-2023
        @description: Retrieves Opportunities with child Product Details
    **/
    public List<Opportunity> selectOpportunitiesWithProductDetails(Set<Id> opportunityIds) {
        fflib_QueryFactory opportunitiesFactory = newQueryFactory();

        opportunitiesFactory.selectFields(getSObjectFieldList()).setCondition('Id IN :opportunityIds');

        fflib_QueryFactory productDetailsFactory = opportunitiesFactory.subselectQuery('Product_Details__r');
        productDetailsFactory.selectFields(new Set<String>{ 'Id' });

        return (List<Opportunity>) Database.query(opportunitiesFactory.toSOQL());
    }

    /**
        @author: Dan Thoreson
        @date: 26-Jan-2023
        @description: Permits the addition of an inputted set of customized fields for the standard selectByIds query
    **/
    public List<Opportunity> selectByIdExtraFields(Set<Id> recordIds, Set<String> fields) {
        fflib_QueryFactory query = newQueryFactory()
                                    .selectFields(fields)
                                    .setCondition('Id IN :recordIds');
        return (List<Opportunity>) Database.query(query.toSOQL());
    }
}