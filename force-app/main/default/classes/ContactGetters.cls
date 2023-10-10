/**
 * @description ContactGetters abstract domain Class for Contact SObject.
 * Provides a location for domain getter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Contacts domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class ContactGetters
    extends SObjects
    implements IContactGetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public ContactGetters( List<Contact> records ) {
        super( records, Contact.SObjectType );
    }

    /**
     * @description Extracts a properly typed list records from the domain collection
     * @return List of all records
     */
    public virtual List<Contact> getContacts() {
        return (List<Contact>) getRecords();
    }
}