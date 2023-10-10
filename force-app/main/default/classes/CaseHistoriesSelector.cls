/**
 * @description Selector for the Case History Object
 *
 * @author Mahesh Chouhan
 * @date May 2023
 */
public inherited sharing class CaseHistoriesSelector extends SObjectsSelector implements ICaseHistoriesSelector{
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the ICaseHistoriesSelector
     */
    public static ICaseHistoriesSelector newInstance() {
        return (ICaseHistoriesSelector) Application.Selector.newInstance(CaseHistory.SObjectType);
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            CaseHistory.Id,
            CaseHistory.Field,
            CaseHistory.OldValue,
            CaseHistory.NewValue,
            CaseHistory.DataType,
            CaseHistory.CaseId
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return CaseHistory.SObjectType;
    }

    /**
     * @description Method for querying Case History records when you know their ids
     *
     * @param ids The ids of the records to be returned
     * @return A list of Case History records
     */
    public List<CaseHistory> selectById(Set<Id> ids) {
        return (List<CaseHistory>) selectSObjectsById(ids);
    }

    /**
     * @description Method for querying Case History records with Id and Field
     * @param ids The ids of the records to be returned
     * @param fields Set of field names
     * @return A list of Case History records
     */
    public List<CaseHistory> selectByCaseIdAndFields(Set<Id> caseIds, Set<String> fields) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(getSObjectFieldList())
            .setCondition('CaseId IN :caseIds AND Field IN :fields');
        return (List<CaseHistory>) Database.query(query.toSOQL());
    }
}