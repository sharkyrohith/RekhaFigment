/**
 * @description Interface for the CasesSelector
 *
 * @author Scott McClung
 */
public interface ICasesSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Case records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Case records
     */
    List<Case> selectById(Set<Id> ids);

    /**
     * @description Method for querying Case records when you know their ids
     * @param ids The ids of the records to be returned
     * @param additionalFields Additional fields to Query
     * @return A list of Case records
     */
    List<Case> selectById(Set<Id> ids, Set<String> additionalFields);

    /**
        @author: Dan Thoreson
        @date: 03-Nov-2022
        @description: Retrieves Cases by IDs with data from the linked Account.
    **/
    List<Case> selectCasesByIdsWithParentAccountInfo(Set<Id> caseIds);

    /**
        @author: Dan Thoreson
        @date: 20-Jan-2023
        @description: Retrieves Cases by Parent IDs for an inputted lookup field
    **/
    List<Case> selectCasesWithMilestonesByRecordTypeAndGenericParent(Id recordTypeId, String fieldForCondition, Set<Id> parentIds);

    /**
        @author: Dan Thoreson
        @date: 03-Nov-2022
        @description: Retrieves Cases of a specific RecordType per the inputted Accounts
                      (Example: Marketplace Onboarding Cases for a set of Accounts)
    **/
    List<Case> selectCasesWithMilestonesByRecordTypeAndAccount(Id recordTypeId, Set<Id> accountIds);
     /**
        @author: praveen
        @date: 02-10-2023
        @description: Retrives the case records by list of record types
                      Accounts and status.
    **/
    List<Case> selectCasesWithMilestoneByRecordTypesAndAccountsAndStatus(Set<Id> recordTypeIds, Set<Id> accountsIds, Set<String> status);

    /**
     * @author: Sanidhya Jain
     * @description This method is used for getting Database.QueryLocator
     * @param recordTypeName
     * @param caseStatus
     * @param Customertype
     * @param OwnerList
     * @return Database.QueryLocator
     */
    Database.QueryLocator selectOpenCasesFromLastSixMonths(List<String> recordTypeName, List<String> caseStatus, List<String> Customertype, List<String> OwnerList);

    /**
        @author: Dan Thoreson
        @date: 26-Jan-2023
        @description: Permits the selection of Opportunities with a customized set of additional fields
    **/
    List<Case> selectByIdExtraFields(Set<Id> recordIds, Set<String> fields);

    /**
     * @author          Jeegar
     * @description     get cases with certain Issue_Type__c created in last N hours for an account
     * @date            Aug 2023
     * @param           Id              accountId
     * @param           DateTime        lookbackDateTime (createdDate >= lookbackDateTime)
     * @param           Set<Id>         recordTypeIds (Support and API)
     * @param           Set<String>     issueTypes
     */

    List<Case> selectCasesByAccountIdAndIssueTypeLastnHours (Id accountId,Integer last_n_hours, Set<Id> recordTypeIds,Set<String> issueTypes);
    /**
     * @author: Mahesh Chouhan
     * @description: Query open cases held by inactive users
     * @date: April 2023
     * @param caseOrigins specfy Case Origins
     * @return Database.QueryLocator
     */
    Database.QueryLocator selectOpenCasesWithInactiveOwner(Set<String> caseOrigins);
    /**
    @author: Praveen
    @date: 09-Aug-2023
    * @param Set<String> onboardingIds
    * @param Set<Id> recordTypeIds
    * @param Set<Status> status
    * @return List<Case>
    @description: get the open pos case by onboarding Ids, recordType and Status
    **/
    List<Case> selectByOnboardingIdAndrecorTypeAndStatus(Set<String> onboardingIds, Set<Id> recordTypeIds, Set<String> status);
}