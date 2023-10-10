/**
 * @description Interface for the ContactsSelector
 *
 * @author Scott McClung
 */
public interface IContactsSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Contact records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Contact records
     */
    List<Contact> selectById(Set<Id> ids);
}