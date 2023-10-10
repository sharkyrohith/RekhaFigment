/**
 * @description AccountSetters abstract domain Class for Account SObject.
 * Provides a location for domain setter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Accounts domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/08/17
 */
public abstract class AccountSetters
    extends AccountGetters
    implements IAccountSetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public AccountSetters( List<Account> records ) {
        super( records );
    }

    /**
     * @description Sets the Account.Name field of the collection to the given value
     * @param value Value to set the field to
     * @return Accounts domain instance containing the updated records
     */
    public virtual IAccounts setNames( String value ) {
        setFieldValue( Account.Name, value );
        return newDomainInstance();
    }

    /**
     * @description Sets the Account.OwnerId field of the collection to the given value
     * @param value Value to set the field to
     * @return Accounts domain instance containing the updated records
     */
    public virtual IAccounts setOwnerIds( Id value ) {
        setFieldValue( Account.OwnerId, value );
        return newDomainInstance();
    }

    /**
     * @description Sets the Account.ParentId field of the collection to the given value
     * @param value Value to set the field to
     * @return Accounts domain instance containing the updated records
     */
    public virtual IAccounts setParentIds( Id value ) {
        setFieldValue( Account.ParentId, value );
        return newDomainInstance();
    }

    /**
     * @description Generates a new instance of Accounts with the current collection
     * @return Instance of domain object
     */
    private IAccounts newDomainInstance() {
        return new Accounts( this.getRecords() );
    }
}