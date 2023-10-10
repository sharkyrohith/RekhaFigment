public interface IRoutingAttributeDefinationSelector extends fflib_ISObjectSelector {
     /**
    * @description This method is used for getting Sobject type Id
    * @param setConfigIds
    * @return List<Routing_Attribute_Defination__mdt>
    */
    List<Routing_Attribute_Defination__mdt> selectActiveDefinationById(Set<String> setConfigIds);

}