/**
 * @description ContactValidations abstract domain Class for Contact SObject.
 * Provides a location for domain validation methods on hero objects that would
 * otherwise end up with a bloated domain class.  Contacts domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class ContactValidations
    extends ContactFilters
    implements IContactValidations {

    /**
 * @description Class constructor
 * @param records Collection of SObjects
 */
    public ContactValidations( List<Contact> records ) {
        super( records );
    }
}