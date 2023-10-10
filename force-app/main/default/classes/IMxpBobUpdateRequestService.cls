public interface IMxpBobUpdateRequestService {

    String transferBoBRequest(Map<Id,Id>mapOldMxpIdNewMxpId,List<AccountTeamMember> lstAccTeamMemberDel);
    
    String processBusinessIdBobRequests(Map<Decimal,Id>mapBusinessIdNewMxpId,List<Account> lstAccsToProcess);

    List<String> getAdditionalInformationAboutMxpBobUpdateRequest(Id mxpBobRequestId);
}