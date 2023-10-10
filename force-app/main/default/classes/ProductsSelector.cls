/********************************************************************************************************************
* @author Sriram
* @date 10/08/2022
*
* @group fflib
*
* @description Selector class for Product2 sObject type
* 
**************************************************************************************************************************************/
public virtual inherited sharing class ProductsSelector extends SObjectsSelector implements IProductsSelector {
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     * @return A concrete or mock implementation of the IProductsSelector
     */
    public static IProductsSelector newInstance() {
        return (IProductsSelector) Application.Selector.newInstance( Product2.SObjectType );
    }
    /**
     * @description Method for defining the default fields that are included in the query results.
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Product2.DD_Custom_ID__c,
            Product2.Description,
            Product2.Id,
            Product2.IsActive,
            Product2.Name,
            Product2.Package_Name__c,
            Product2.Platform__c,
            Product2.ProductCode,
            Product2.Family
        };
    }
    /**
     * @description Defines the SObject to be queried by this selector
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Product2.SObjectType;
    }
    /**
     * @description Method for querying Product2 records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Product2 records
     */
    public List<Product2> selectById( Set<Id> ids ) {
        return (List<Product2>) selectSObjectsById( ids );
    }
    /**
     * @description Return a Collection of product records for input DD Custom Ids
     * @param Set<String> ddCustomIds
     * @return A list of Product2 records
     */
    public List<Product2> selectByDDCustomId( Set<String> ddCustomIds ) {
        String query = String.format(' SELECT {0} FROM {1} WHERE DD_Custom_ID__c IN :ddCustomIds ', new List<String>{ getFieldListString(), getSObjectName() });
        return (List<Product2>) Database.query(query);
    }
}