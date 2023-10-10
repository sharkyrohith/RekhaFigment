/**
 * @description Interface for the CaseHistoriesSelector
 *
 * @author Mahesh Chouhan
 * @date May 2023
 */
public interface ICaseHistoriesSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Case History records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Case History records
     */
    List<CaseHistory> selectById(Set<Id> ids);

    /**
     * @description Method for querying Case History records with Id and Field
     * @param ids The ids of the records to be returned
     * @param fields Set of field names
     * @return A list of Case History records
     */
    List<CaseHistory> selectByCaseIdAndFields(Set<Id> ids, Set<String> fields);
}