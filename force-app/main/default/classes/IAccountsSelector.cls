/**
 * @description Interface for the AccountsSelector
 *
 * @author Scott McClung
 */
public interface IAccountsSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Account records when you know their ids
     *
     * @param ids The ids of the records to be returned
     * @return A list of Account records
     */
    List<Account> selectById(Set<Id> ids);

    /**
     * @description Method for querying Account records when you know their ids
     *
     * @param ids The business Ids of the records to be returned
     * @return A list of Account records
     */
    List<Account> selectAccountsByBusinessId( Set<Decimal> businessIds );

     /**
     * @description This method is used for getting Database.QueryLocator 
     * @param businessIds
     * @return Database.QueryLocator
     */
    Database.QueryLocator queryLocatorSelectAccountsByBusinessId(Set<Decimal> businessIds);

    /**
        @author: Dan Thoreson
        @date: 03-Nov-2022
        @description: Retrieves Accounts related to a given ParentId
    **/    
    List<Account> selectAccountsForParent(Id parentId);    
    /** 
     * @description: Retrieves Accounts related to a given restuarentId
    **/ 
    List<Account> selectAccountsByStoreId(Set<String> storeId);   
}