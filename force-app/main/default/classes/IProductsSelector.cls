/********************************************************************************************************************
* @author Sriram
* @date 10/08/2022
*
* @group fflib
*
* @description Interface for Products Selector
* 
**************************************************************************************************************************************/
public interface IProductsSelector extends ISObjectsSelector {
    /**
     * @description Method for querying User records when you know their ids
     * @param productIds The ids of the records to be returned
     * @return A list of Product2 records
     */
    List<Product2> selectById( Set<Id> productIds );
    /**
     * @description Return a Collection of product records for input DD Custom Ids
     * @param Set<String> ddCustomIds
     * @return A list of Product2 records
     */
    List<Product2> selectByDDCustomId( Set<String> ddCustomIds );    
}