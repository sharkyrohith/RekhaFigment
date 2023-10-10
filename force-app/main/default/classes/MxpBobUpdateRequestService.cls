// Service Facade for MxpBoBUpdateRequest
public inherited sharing class MxpBobUpdateRequestService {

    /**
     * @description : Method to fetch information about the request...
    * @param Id - the Id of the MXP BOB Update Request
    * @return List<String> - Information gathered about the request.
    */
    public static List<String> getAdditionalInformationAboutMxpBobUpdateRequest(Id mxpBobRequestId) {
        return service().getAdditionalInformationAboutMxpBobUpdateRequest(mxpBobRequestId);
    }

    /**
    * @description : Method to remove old MXP to add new MXP for BoB transfer
    * @param String errorMsg
    */
    public static String transferBoBRequest(Map<Id,Id>mapOldMxpIdNewMxpId,List<AccountTeamMember> lstAccTeamMemberDel){
        return service().transferBoBRequest(mapOldMxpIdNewMxpId,lstAccTeamMemberDel);
    }

     /**
    * @description : Method to assign MXP for Accounts under same Business Ids
    * @param String errorMsg
    */
    public static String processBusinessIdBobRequests(Map<Decimal,Id>mapBusinessIdNewMxpId,List<Account> lstAccsToProcess){
        return service().processBusinessIdBobRequests(mapBusinessIdNewMxpId,lstAccsToProcess);
    }

    /**
     * @description It creates instance of ExternalNotifierEventsServiceImpl class.
     * @return  - return instance of IMxpBobUpdateRequestService
     */

    private static IMxpBobUpdateRequestService service() {
        return (IMxpBobUpdateRequestService) Application.Service.newInstance(
            IMxpBobUpdateRequestService.class
        );
    }
}