/**
 * @description : CloseOpenCasesRequestService is a service class to update the records which are not modified from last Six months
 * @date 2023/02/02
 */
public inherited sharing class CloseOpenCasesRequestService {

    /**
    * @description : Method to update Cases which were Last Modified Six Months Ago
    * @param String errorMsg
    */
    public static List<String> updateOpenCasestoClose(List<Case> caseList){
        return service().updateOpenCasestoClose(caseList);
    }

    /**
    * @description : Method to handle cases owned by inactive agents
    * @param String errorMsg
    */
    public static List<String> handleCasesWithInactiveOwner(List<Case> caseList){
        return service().handleCasesWithInactiveOwner(caseList);
    }

    /**
     * @description It creates instance of ExternalNotifierEventsServiceImpl class.
     * @return  - return instance of ICDdCloseOpenCasesRequestService
     */

    private static ICloseOpenCasesRequestService service() {
        return (ICloseOpenCasesRequestService) Application.Service.newInstance(
            ICloseOpenCasesRequestService.class
        );
    }

}