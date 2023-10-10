/**
 * @description Interface for the MilestonesSelector
 *
 * @author Krishna Sanisetty
 * @date 10/07/2022
 */
public interface IMilestonesSelector extends ISObjectsSelector{
    List<Milestone__c> selectByCaseIdAndRecordTypeName(Set<Id> caseIds, Set<String> recordTypeNames);

    /**
        @author: Dan Thoreson
        @date: 12-Jan-2023
        @description: Retrieves Milestones of specific RT Developer Names for the inputted Case ID(s)
    **/
    List<Milestone__c> selectByCaseIdAndRecordTypeDeveloperName(Set<Id> caseIds, Set<String> recordTypeNames);
}