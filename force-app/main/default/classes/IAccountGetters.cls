/**
 * @description Interface for AccountGetters.
 * Composed to define the interface for IAccounts
 */
public interface IAccountGetters extends ISObjects {
    List<Account> getAccounts();
    Map<Id,Account> getAccountsById();
    List<String> getNames();
    Set<Id> getOwnerIds();
    Set<Id> getParentIds();
}