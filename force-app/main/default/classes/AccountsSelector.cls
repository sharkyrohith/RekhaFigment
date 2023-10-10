/**
 * @description Selector Class for Account SObject
 * @author Scott McClung
 * @date 2022/08/16
 */
public inherited sharing class AccountsSelector extends SObjectsSelector implements IAccountsSelector {
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     * @return A concrete or mock implementation of the IAccountsSelector
     */
    public static IAccountsSelector newInstance() {
        return (IAccountsSelector) Application.Selector.newInstance( Account.SObjectType );
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Account.Id,
            Account.Name,
            Account.ParentId,
            Account.ADR_Owner_Actual__c,
            Account.OwnerId,
            Account.Restaurant_ID__c
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Account.SObjectType;
    }

    /**
     * @description Method for querying Account records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Account records
     */
    public List<Account> selectById( Set<Id> ids ) {
        return (List<Account>) selectSObjectsById( ids );
    }

    /**
     * @description Method for querying Account records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Account records
     */
    public List<Account> selectAccountsByBusinessId( Set<Decimal> businessIds ) {
        fflib_QueryFactory query = newQueryFactory()
        .selectFields(new Set<String> {'Business_ID__c','Case_Routing_Override__c'})
        .setCondition('Business_ID__c IN :businessIds');        
        return (List<Account>) Database.query(query.toSOQL());
    }

    /**
     * @description This method is used for getting Database.QueryLocator 
     * @param businessIds
     * @return Database.QueryLocator
     */
    public Database.QueryLocator queryLocatorSelectAccountsByBusinessId(Set<Decimal> businessIds){
        return Database.getQueryLocator(newQueryFactory()
            .selectFields(new Set<String> {'Business_ID__c','Case_Routing_Override__c'})
            .setCondition('Business_ID__c IN :businessIds').
            toSOQL());
    }

    /**
        @author: Dan Thoreson
        @date: 03-Nov-2022
        @description: Retrieves Accounts related to a given ParentId
    **/
    public List<Account> selectAccountsForParent(Id parentId) { 
        fflib_QueryFactory accountQueryFactory = newQueryFactory();
        accountQueryFactory.selectFields(getSObjectFieldList())
                           .setCondition('ParentId = :parentId');

        return (List<Account>) Database.query(accountQueryFactory.toSOQL());
    }    

     /**
     * @description This method is used for getting accounts By restaurant Ids.
     * @param restaurentIds
     * @return A list of Account records
     */
    public List<Account> selectAccountsByStoreId(Set<String> storeIds) {
        fflib_QueryFactory accountQueryFactory = newQueryFactory();
        accountQueryFactory.selectFields(getSObjectFieldList())
                           .setCondition('Restaurant_ID__c IN :storeIds');

        return (List<Account>) Database.query(accountQueryFactory.toSOQL());
    }
}