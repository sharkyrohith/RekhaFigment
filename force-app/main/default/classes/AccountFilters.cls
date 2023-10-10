/**
 * @description AccountFilters abstract domain Class for Account SObject.
 * Provides a location for domain filter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Accounts domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/08/17
 */
public abstract class AccountFilters
    extends AccountSetters
    implements IAccountFilters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public AccountFilters( List<Account> records ) {
        super( records );
    }

    /**
     * @description Returns a set of Accounts owned by the given user ids
     * @param setIds Set of owner ids
     * @return Accounts domain instance containing the records that match the criteria
     */
    public virtual IAccounts filterByOwnerId( Set<Id> setIds ) {
        return (IAccounts) new Accounts(
            getRecordsByFieldValues( Account.OwnerId, Ids.newInstance( setIds ).getObjectSet() )
        );
    }

    /**
     * @description Returns a set of Accounts that are the children of the given Account ids
     * @param setIds Set of account ids
     * @return Accounts domain instance containing the records that match the criteria
     */
    public virtual IAccounts filterByParentId( Set<Id> setIds ) {
        return (IAccounts) new Accounts(
            getRecordsByFieldValues( Account.ParentId, Ids.newInstance( setIds ).getObjectSet() )
        );
    }

    /**
     * @description Returns a set of Accounts that have a value in the ParentId field
     * Not blank = String.isNotBlank() = not whitespace, not empty, and not null
     * @return Accounts domain instance containing the records that match the criteria
     */
    public virtual IAccounts whereParentIdNotBlank() {
        return (IAccounts) new Accounts(
            getRecordsWithNotBlankFieldValues(new Set<SObjectField>{Account.ParentId})
        );
    }

    /**
     * @description Filter method returning a set of Accounts where the ParentId field is blank
     * Blank = String.isBlank() = whitespace, empty, or null
     * @return Accounts domain instance containing the records that match the criteria
     */
    public virtual IAccounts whereParentIdBlank() {
        return (IAccounts) new Accounts(
            getRecordsWithBlankFieldValues(new Set<SObjectField>{Account.ParentId})
        );
    }
}