/**
 * @description Interface for the LeadsSelector
 *
 * @author Scott McClung
 */
public interface ILeadsSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Lead records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Lead records
     */
    List<Lead> selectById(Set<Id> ids);

    List<Lead> selectLeadsByCreatedFromContact(Set<Id> contactIds);
}