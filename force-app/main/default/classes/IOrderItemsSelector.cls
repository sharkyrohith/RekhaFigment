/**
 * @description Interface for the OrderItemsSelector
 *
 * @author Krishna Sanisetty
 * @date 10/07/2022
 */
public interface IOrderItemsSelector extends ISObjectsSelector{
    List<OrderItem> selectByOrderIdAndProductFamily(Set<Id> orderIds, Set<String> productFamily);

    List<OrderItem> selectItemsWithStorefrontProducts(Set<Id> opportunityIds);
}