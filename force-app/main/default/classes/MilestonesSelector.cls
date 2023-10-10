/**
 * @description Selector Class for Milestone__c SObject
 *
 * @author Krishna Sanisetty
 * @date 10/07/2022
 */
public inherited sharing class MilestonesSelector extends SObjectsSelector implements IMilestonesSelector{
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the IMilestonesSelector
     */
    public static IMilestonesSelector newInstance() {
        return (IMilestonesSelector) Application.Selector.newInstance(Schema.Milestone__c.SObjectType);
    }

     /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Milestone__c.Id,
            Milestone__c.Case__c,
            Milestone__c.Status__c
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Milestone__c.SObjectType;
    }

    /**
     * @description Method for querying Milestone records by case id(s) and record Type Name(s)
     *
     * @param caseIds set of associated case id(s)
     * @param recordTypeNames set of milestone record type Name(s)
     * @return A list of Milestone records
     */
    public List<Milestone__c> selectByCaseIdAndRecordTypeName(Set<Id> caseIds, Set<String> recordTypeNames) {
        return (List<Milestone__c>) Database.query(
            newQueryFactory()
            	.selectField('RecordType.Name')
                .setCondition('Case__c IN :caseIds AND recordtype.Name IN :recordTypeNames')
                .toSoql()
        );
    }

    /**
        @author: Dan Thoreson
        @date: 12-Jan-2023
        @description: Retrieves Milestones of specific RT Developer Names for the inputted Case ID(s)
    **/
    public List<Milestone__c> selectByCaseIdAndRecordTypeDeveloperName(Set<Id> caseIds, Set<String> recordTypeNames) {
        return (List<Milestone__c>) Database.query(
            newQueryFactory()
                .setCondition('Case__c IN :caseIds AND RecordType.DeveloperName IN :recordTypeNames')
                .toSoql()
        );
    }
}