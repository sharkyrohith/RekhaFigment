/**
 * @description Interface for AccountFilters.
 * Composed to define the interface for IAccounts
 */
public interface IAccountFilters extends IAccountSetters {
    IAccounts filterByOwnerId(Set<Id> setIds);
    IAccounts filterByParentId(Set<Id> setIds);
    IAccounts whereParentIdBlank();
    IAccounts whereParentIdNotBlank();
}