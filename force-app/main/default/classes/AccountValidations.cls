/**
 * @description AccountValidations abstract domain Class for Account SObject.
 * Provides a location for domain validation methods on hero objects that would
 * otherwise end up with a bloated domain class.  Accounts domain class inherits
 * behavior from this class.
 *
 * @author Scott McClung
 * @date 2022/08/17
 */
public abstract class AccountValidations
    extends AccountFilters
    implements IAccountValidations {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public AccountValidations( List<Account> records ) {
        super( records );
    }
}