/**
 * @description Interface for the OpportunitiesSelector
 *
 * @author Scott McClung
 */
public interface IOpportunitiesSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Opportunity records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Opportunity records
     */
    List<Opportunity> selectById(Set<Id> ids);
    /**
     * @description Method for querying Onboarding Opportunity records when you know their ids
     * This method will also return child relationship records namely Opportunity Line Items and Cases
     * @param opportunityIds The ids of the opportunity records to be returned
     * @return A list of Opportunity records with related Opportunity Line Items and Cases
     */
    List<Opportunity> selectOnboardingOpportunitiesWithLineItemsAndCases(Set<Id> opportunityIds);
     /**
     * @description Method for querying the opportunities using accountIds.
     * @param Set<Id> accountId Opportunity accountId sfor opportunity search.
     * @return List<Opportunity> A list of Opportunity records
     */     
    List<Opportunity> getOpportunitiesByAccountIds(Set<Id> accountIds);
    /**
     * @description Method for searching the opportunities using search term and accountIds.
     * @param String searchTerm Opportunity name search ** Opportunity Name **
     * @param Set<Id> accountId Opportunity accountId for opportunity search.
     * @return List<List<sObject>> of Opportunity records
     */     
    List<List<sObject>> searchOpportunitiesBysearchTermAndAccountIds(String searchTerm, Set<Id> accountIds);
    
    /**
        @author: Dan Thoreson
        @date: 10-Jan-2023
        @description: Retrieves Opportunities with children Product Details
    **/
    List<Opportunity> selectOpportunitiesWithProductDetails(Set<Id> opportunityIds);

    /**
        @author: Dan Thoreson
        @date: 26-Jan-2023
        @description: Permits the selection of Opportunities with a customized set of additional fields
    **/
    List<Opportunity> selectByIdExtraFields(Set<Id> recordIds, Set<String> fields);
}