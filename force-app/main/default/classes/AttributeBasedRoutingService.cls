public inherited sharing class AttributeBasedRoutingService {

    /**
     * @description : Method to push cases for Skill based routing
     * @param mapCaseIdCase - Map of Case Id and Case Data
     * @return None
    */
    public static void pushCasesForAttributeBasedRouting(Map<Id,Case> mapCaseIdCase) {
        service().pushCasesForAttributeBasedRouting(mapCaseIdCase);
    }
     /**
     * @description It creates instance of IAttributeBasedRoutingServiceImpl class.
     * @return  - return instance of IAttributeBasedRoutingService
     */
    private static IAttributeBasedRoutingService service() {
        return (IAttributeBasedRoutingService) Application.Service.newInstance(
            IAttributeBasedRoutingService.class
        );
    }
}