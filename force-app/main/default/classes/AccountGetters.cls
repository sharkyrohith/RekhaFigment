/**
 * @description AccountGetters abstract domain Class for Account SObject.
 * Provides a location for domain getter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Accounts domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/08/17
 */
public abstract class AccountGetters
    extends SObjects
    implements IAccountGetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public AccountGetters( List<Account> records ) {
        super( records, Account.SObjectType );
    }

    /**
     * @description Extracts a properly typed list records from the collection
     * @return List of all records
     */
    public virtual List<Account> getAccounts() {
        return (List<Account>) getRecords();
    }

    /**
     * @description Extracts all records in the collection grouped by their record Id
     * @return Map of all records grouped by Id
     */
    public virtual Map<Id, Account> getAccountsById() {
        return (Map<Id, Account>) getSObjectsByIdField( Account.Id );
    }

    /**
     * @description Extracts all Names from the collection
     * @return List of all Names
     */
    public virtual List<String> getNames() {
        return getStringFieldValues( Account.Name );
    }

    /**
     * @description Extracts all OwnerIds from the collection
     * @return Set of OwnerIds
     */
    public virtual Set<Id> getOwnerIds() {
        return getIdFieldValues( Account.OwnerId );
    }

    /**
     * @description Extracts all ParentIds from the collection
     * @return Set of ParentIds
     */
    public virtual Set<Id> getParentIds() {
        return getIdFieldValues( Account.ParentId );
    }
}