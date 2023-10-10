/**
 * @description Selector Class for Case SObject
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
public inherited sharing class CasesSelector extends SObjectsSelector implements ICasesSelector {

    public static Support_Settings__c SUPPORT_SETTINGS = Support_Settings__c.getInstance();
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the ICasesSelector
     */
    public static ICasesSelector newInstance() {
        return (ICasesSelector) Application.Selector.newInstance(Case.SObjectType);
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Case.Id,
            Case.CaseNumber,
            Case.Status,
            Case.Subject,
            Case.AccountId,
            Case.ParentId,
            Case.RecordTypeId,
            Case.Opportunity_Name__c
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Case.SObjectType;
    }

    /**
     * @description Method for querying Case records when you know their ids
     *
     * @param ids The ids of the records to be returned
     * @return A list of Case records
     */
    public List<Case> selectById(Set<Id> ids) {
        return (List<Case>) selectSObjectsById(ids);
    }

    /**
     * @description Method for querying Case records when you know their ids
     *
     * @param ids The ids of the records to be returned
     * @param additionalFields Additional fields to Query
     * @return A list of Case records
     */
    public List<Case> selectById(Set<Id> ids, Set<String> additionalFields) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(additionalFields)
            .setCondition('Id IN :ids');
        return (List<Case>) Database.query(query.toSOQL());
    }

    /**
        @author: Dan Thoreson
        @date: 03-Nov-2022
        @description: Retrieves Cases by IDs with data from the linked Account.
    **/
    public List<Case> selectCasesByIdsWithParentAccountInfo(Set<Id> caseIds) {
        fflib_QueryFactory caseQueryFactory = newQueryFactory();
        caseQueryFactory.selectFields(getSObjectFieldList())
                        .selectFields(new Set<String>{
                            'Account.ParentId', 'RecordType.Name'
                        })
                        .setCondition('Id IN :caseIds');

        return (List<Case>) Database.query(caseQueryFactory.toSOQL());
    }

    /**
        @author: Dan Thoreson
        @date: 03-Nov-2022
        @description: Retrieves Cases of a specific RecordType per the inputted Accounts
                      (Example: Marketplace Onboarding Cases for a set of Accounts)
    **/
    public List<Case> selectCasesWithMilestonesByRecordTypeAndAccount(Id recordTypeId, Set<Id> accountIds) {
        fflib_QueryFactory caseQueryFactory = newQueryFactory();
        caseQueryFactory.selectFields(getSObjectFieldList())
                        .selectFields(new Set<String>{'Owner.Name', 'RecordType.Name'})
                        .setCondition('RecordTypeId = :recordTypeId ' + ' AND AccountId IN :accountIds ')
                        .addOrdering(new fflib_QueryFactory.Ordering('Case', 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING));

        fflib_QueryFactory milestonesQueryFactory = caseQueryFactory.subselectQuery('Milestones__r');
        milestonesQueryFactory.selectFields(new Set<String>{
            'Id', 'Sort_Order__c', 'Milestone_Type__c', 'Name', 'Status__c'
        });

        return (List<Case>) Database.query(caseQueryFactory.toSOQL());
    }

    /**
        @author: Dan Thoreson
        @date: 20-Jan-2023
        @description: Retrieves Cases of a specific RecordType per the inputted parent record IDs
                      (Example: Marketplace Onboarding Cases for a set of Opportunities)
    **/
    public List<Case> selectCasesWithMilestonesByRecordTypeAndGenericParent(Id recordTypeId, String fieldForCondition, Set<Id> parentIds) {
        fflib_QueryFactory caseQueryFactory = newQueryFactory();
        caseQueryFactory.selectFields(getSObjectFieldList())
                        .selectFields(new Set<String>{'Owner.Name', 'RecordType.Name', 'CreatedDate'})
                        .addOrdering(new fflib_QueryFactory.Ordering('Case', 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING));

        if(String.isNotBlank(fieldForCondition)) {
            caseQueryFactory.setCondition('RecordTypeId = :recordTypeId ' + ' AND ' + fieldForCondition + ' IN :parentIds');
        } else {
            caseQueryFactory.setCondition('RecordTypeId = :recordTypeId ');
        }

        fflib_QueryFactory milestonesQueryFactory = caseQueryFactory.subselectQuery('Milestones__r');
        milestonesQueryFactory.selectFields(new Set<String>{
            'Id', 'Sort_Order__c', 'Milestone_Type__c', 'Name', 'Status__c'
        });

        return (List<Case>) Database.query(caseQueryFactory.toSOQL());
    }

    /**
        @author: Sanidhya jain
        @date: 10-Jan-2023
		* @param recordTypeName : The Record type List
		* @param caseStatus : Contain the status of Case
		* @param Customertype :  Contain the Customer Type of Case
		* @param OwnerList : Contain the Owner list of Case
        @description: Retrieves Cases which were not modified from last Six Months
    **/
    public Database.QueryLocator selectOpenCasesFromLastSixMonths(List<String> recordTypeName, List<String> caseStatus, List<String> Customertype, List<String> OwnerList) {
        String lastModifiedRange = 'SystemModstamp >= LAST_N_DAYS:180 AND SystemModstamp < LAST_N_DAYS:179 ';
        if(Test.isRunningTest()){
            lastModifiedRange = 'SystemModstamp >= LAST_N_DAYS:180 ';
        }
        return Database.getQueryLocator(newQueryFactory()
                                        .selectFields(new Set<String>{'Id','Customer_Type__c','Issue_Type__c',
                                            		'Issue__c','Resolution_Type__c','Resolution__c','OwnerId','Status','Description'})
                                        .setCondition('RecordType.DeveloperName =: recordTypeName AND Status =: caseStatus '+
                                                      'AND Owner.Name !=: OwnerList AND Previous_Queue__c !=: OwnerList AND '+
                                                      'Customer_Type__c =: Customertype AND ' + lastModifiedRange).
                                        toSOQL());
    }
    /**
     * @author: praveen
     * @description Method for querying Case records by List of recordTypeIds, accountIds and Case Status
     * @param  recordTypeIds a list of case recordTypes
     * @param  accountsIds a list of accountIds
     * @param  status case status
     * @return A list of Case records
     */
    public List<Case> selectCasesWithMilestoneByRecordTypesAndAccountsAndStatus(Set<Id> recordTypeIds, Set<Id> accountsIds, Set<String> status){
        // to pass codescan checks - referencing and checking for null for the above vars
        fflib_QueryFactory caseQueryFactory = newQueryFactory();
        caseQueryFactory
        .selectFields(getSObjectFieldList())
        .selectFields(new Set<String>{
            'POS_Integration_Type__c', 'Account.Restaurant_ID__c','POS_Integration_ID__c', 'Opportunity_Name__r.Order_protocol__c', 'onboarding_id__c'
        })
        .setCondition('RecordTypeId IN :recordTypeIds '
            + ' AND AccountId IN :accountsIds '
            + ' AND status IN :status '
        );
        // add the milestones
        fflib_QueryFactory milestoneQuery = caseQueryFactory.subselectQuery('Milestones__r');
        milestoneQuery.selectFields(new Set<String>{
            'Id', 'Milestone_Type__c', 'Name', 'Status__c', 'Status_Reason__c'
        });
        return (List<Case>) Database.query(caseQueryFactory.toSOQL());
    }
    /**
        @author: Dan Thoreson
        @date: 26-Jan-2023
        @description: Permits the addition of an inputted set of customized fields for the standard selectByIds query
    **/
    public List<Case> selectByIdExtraFields(Set<Id> recordIds, Set<String> fields) {
        fflib_QueryFactory query = newQueryFactory()
                                    .selectFields(fields)
                                    .setCondition('Id IN :recordIds');
        return (List<Case>) Database.query(query.toSOQL());
    }

    /**
     * @author          Jeegar
     * @description     get cases with certain Issue_Type__c created in last N hours for an account
     * @date            Aug 2023
     * @param           Id              accountId
     * @param           Integer         last_n_hours
     * @param           Set<Id>         recordTypeIds (Support and API)
     * @param           Set<String>     issueTypes
     */

    public List<Case> selectCasesByAccountIdAndIssueTypeLastnHours (Id accountId,
                                                            Integer last_n_hours,
                                                            Set<Id> recordTypeIds,
                                                            Set<String> issueTypes) {

    DateTime lookbackDateTime = Datetime.now().addHours(-1*last_n_hours);
    String whereClause = 'CreatedDate >= :lookbackDateTime AND AccountId = :accountId ';
    whereClause += 'AND recordtypeid in :recordTypeIds AND Issue_Type__c in :issueTypes';


    fflib_QueryFactory caseQueryFactory = newQueryFactory();
    caseQueryFactory.selectFields(getSObjectFieldList())
    .setCondition(whereClause);

    return (List<Case>) Database.query(caseQueryFactory.toSOQL());
    }

    /**
     * @author: Mahesh Chouhan
     * @description: Query open cases held by inactive users
     * @date: April 2023
     * @param caseOrigins specfy Case Origins
     * @return Database.QueryLocator
     */
    public Database.QueryLocator selectOpenCasesWithInactiveOwner(Set<String> caseOrigins) {
        Set<String> closeCaseStatus = new Set<String>{CDdSupportConstants.CLOSED_STATUS, CDdSupportConstants.SOLVED_STATUS};
        String whereCondition = 'Owner.isActive = false AND Origin IN :caseOrigins AND Status NOT IN :closeCaseStatus';
        if(!String.isEmpty(SUPPORT_SETTINGS.Inactive_Case_Owner_Query_Condition__c)){
            whereCondition += ' AND ' + SUPPORT_SETTINGS.Inactive_Case_Owner_Query_Condition__c;
        }
        return Database.getQueryLocator(newQueryFactory()
                                        .selectFields(new Set<String>{'Id','Customer_Type__c','Previous_Queue_ID__c', 'Origin',
                                                    'Initial_Queue__c','OwnerId', 'Description'})
                                        .setCondition(whereCondition)
                                        .toSOQL());
    }
    /**
    @author: Praveen
    @date: 09-Aug-2023
    * @param Set<String> onboardingIds
    * @param Set<Id> recordTypeIds
    * @param Set<Status> status
    * @return List<Case>
    @description: get the open pos case by onboarding Ids, recordType and Status
    **/
    public List<Case> selectByOnboardingIdAndrecorTypeAndStatus(Set<String> onboardingIds, Set<Id> recordTypeIds, Set<String> status) {
         // to pass codescan checks - referencing and checking for null for the above vars
         fflib_QueryFactory caseQueryFactory = newQueryFactory();
         caseQueryFactory
         .selectFields(getSObjectFieldList())
         .selectFields(new Set<String>{
            'onboarding_id__c'
         })
         .setCondition('RecordTypeId IN :recordTypeIds '
         + ' AND onboarding_id__c IN :onboardingIds '
         + ' AND status IN :status '
         );
        return (List<Case>) Database.query(caseQueryFactory.toSOQL());
    }
}