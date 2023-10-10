/**
 * @description Interface for AccountSetters.
 * Composed to define the interface for IAccounts
 */
public interface IAccountSetters extends IAccountGetters {
    IAccounts setNames( String value );
    IAccounts setOwnerIds( Id value );
    IAccounts setParentIds( Id value );
}