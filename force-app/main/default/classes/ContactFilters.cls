/**
 * @description ContactFilters abstract domain Class for Contact SObject.
 * Provides a location for domain filter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Contacts domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class ContactFilters
    extends ContactSetters
    implements IContactFilters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public ContactFilters( List<Contact> records ) {
        super( records );
    }
}