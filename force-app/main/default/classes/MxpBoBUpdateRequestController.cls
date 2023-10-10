public with sharing class MxpBoBUpdateRequestController {

    @AuraEnabled(cacheable=true)
    public static List<String> getAdditionalInformation(Id mxpBobRequestId){
        return MxpBobUpdateRequestService.getAdditionalInformationAboutMxpBobUpdateRequest(mxpBobRequestId);
    }
}