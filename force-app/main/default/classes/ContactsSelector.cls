/**
 * @description Selector Class for Contact SObject
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
public inherited sharing class ContactsSelector extends SObjectsSelector implements IContactsSelector {
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the IContactsSelector
     */
    public static IContactsSelector newInstance() {
        return (IContactsSelector) Application.Selector.newInstance(Contact.SObjectType);
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Contact.Id,
            Contact.FirstName,
            Contact.LastName
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Contact.SObjectType;
    }

    /**
     * @description Method for querying Contact records when you know their ids
     *
     * @param ids The ids of the records to be returned
     * @return A list of Contact records
     */
    public List<Contact> selectById(Set<Id> ids) {
        return (List<Contact>) selectSObjectsById(ids);
    }
}