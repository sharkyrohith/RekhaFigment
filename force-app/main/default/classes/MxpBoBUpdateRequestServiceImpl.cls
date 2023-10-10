/**
 * @author  Raju L
 * @date    October 2022
 * @description This is the service implementation class for MXP Book of Business Update Request tool
 */
public inherited sharing class MxpBoBUpdateRequestServiceImpl implements IMxpBobUpdateRequestService {
    /**
    * @description : Method to remove old MXP to add new MXP for BoB transfer
    * @param String errorMsg
    */
    public String transferBoBRequest(Map<Id,Id>mapOldMxpIdNewMxpId,List<AccountTeamMember> lstAccTeamMemberDel){
        String errorMsg = '';
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
         //Loop over accounts to process
        for(AccountTeamMember actTeamMember : lstAccTeamMemberDel){
            //new ATM for new MxP
            SObject atm = new AccountTeamMember(AccountId=actTeamMember.AccountId,TeamMemberRole= CDdSupportConstants.MXP_ROLE_NAME,
                                                    UserId=mapOldMxpIdNewMxpId.get(actTeamMember.UserId),Source__c = MxpBoBUpdateRequest.ACCOUNT_TEAM_MEMBER_SOURCE);
            uow.registerNew(atm);
            //Check if Case Routing Override set if not then set
            if(String.isBlank(actTeamMember.Account.Case_Routing_Override__c)){
                actTeamMember.Account.Case_Routing_Override__c = CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE;
                uow.registerDirty(actTeamMember.Account);
            }
        }
        try {
            uow.registerDeleted(lstAccTeamMemberDel);
            uow.commitWork();
        }catch (Exception e) {
            errorMsg = CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e);
        }
        return errorMsg;
    }

    /**
    * @description : Method to assign MXP for Accounts under same Business Ids
    * @param String errorMsg
    */
    public String processBusinessIdBobRequests(Map<Decimal,Id>mapBusinessIdNewMxpId,List<Account> lstAccsToProcess){
        String errorMsg = '';
        Set<Id> setAccIds =  new Set<Id>();

        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        //Loop over accounts to process
        for(Account acc : lstAccsToProcess){
            setAccIds.add(acc.Id);
            //Get the New Mxp Assigned to business Id
            Integer businessId = acc.Business_Id__c!=null ? Integer.valueOf(acc.Business_Id__c): 0;
            if(mapBusinessIdNewMxpId.containsKey(businessId)){
                SObject atm = new AccountTeamMember(AccountId=acc.Id,TeamMemberRole= CDdSupportConstants.MXP_ROLE_NAME,
                                                    UserId=mapBusinessIdNewMxpId.get(businessId),
                                                    Source__c = MxpBoBUpdateRequest.ACCOUNT_TEAM_MEMBER_SOURCE);
                uow.registerNew(atm);
            }
            //Check if Case Routing Override set if not then set
            if(String.isBlank(acc.Case_Routing_Override__c)){
                acc.Case_Routing_Override__c = CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE;
                uow.registerDirty(acc);
            }
        }

        //Find the existing ATM for Accounts to delete
        List<AccountTeamMember> lstAccTeamMemberDel = AccountTeamMembersSelector.newInstance().
                                                       selectByAccountId(setAccIds);
        try {
            uow.registerDeleted(lstAccTeamMemberDel);
            uow.commitWork();
        }catch (Exception e) {
            errorMsg = CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e);
        }
        return errorMsg;
    }

    /**
     * @description : Method to fetch information about the request...
    * @param Id - the Id of the MXP BOB Update Request
    * @return List<String> - Information gathered about the request.
    */
    public List<String> getAdditionalInformationAboutMxpBobUpdateRequest(Id mxpBobRequestId){
        List<String> retVal = new List<String>();
        List<MXP_BoB_Update_Request__c> requestList = MxpBobUpdateRequestSelector.newInstance().selectByIdExtraFields(
            new Set<Id>{mxpBobRequestId}
        );
        if (requestList.isEmpty()) {
            return retVal;
        }

        MXP_BoB_Update_Request__c request = requestList[0];
        Id currentMxp = null;
        String navType = null;
        if (request.Merchant__c != null) {
            List<AccountTeamMember> atmList =
                AccountTeamMembersSelector.newInstance().selectByAccountIdAndRoles(new Set<Id>{request.Merchant__c}, new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});
            if (!atmList.isEmpty()) {
                navType = CDdLightningUtils.getNavType();
                retVal.add('The current MXP for this merchant: ' + (navType == 'Console' ?
                    CDdUtilities.createLink('/' + atmList[0].UserId,atmList[0].User.Name) :
                    CDdUtilities.createLink('/' + atmList[0].UserId,atmList[0].User.Name,CDdUtilities.CREATELINK_PROPS.ANCHOR_BLANK_TARGET)
                ));
                currentMxp = atmList[0].UserId;
            } else {
                retVal.add('This merchant is not supported by any MXP.');
            }
        }

        Set<Id> userIdsForAggregateQuery = new Set<Id>();
        Map<Id,String> userIdsToNameMap = new Map<Id,String>();
        addToUserIdsForAggregateQuery(userIdsForAggregateQuery,userIdsToNameMap,currentMxp,null);
        addToUserIdsForAggregateQuery(userIdsForAggregateQuery,userIdsToNameMap,request.MXP__c,request.MXP__r.Name);
        addToUserIdsForAggregateQuery(userIdsForAggregateQuery,userIdsToNameMap,request.New_MXP__c,request.New_MXP__r.Name);
        addToUserIdsForAggregateQuery(userIdsForAggregateQuery,userIdsToNameMap,request.Previous_MXP__c,request.Previous_MXP__r.Name);

        String mxpBoBUpdateToolReportLink = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.MXP_BOB_UPDATE_TOOL_REPORT_LINK);
        if (!userIdsForAggregateQuery.isEmpty()) {
            navType = String.isBlank(navType) ? CDdLightningUtils.getNavType() : navType;
            Aggregate[] aggResults = AccountTeamMembersSelector.newInstance().selectCountOfAccountsSupportedGroupedByUserIdAndRoles(
                userIdsForAggregateQuery,new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});

            for (Aggregate aggResult : aggResults) {
                Id userId = (Id)aggResult.get('UserId');
                String mxpName = (String)aggResult.get('userName');
                String countOfMerchants = ((Integer)aggResult.get('cnt')).format();
                retVal.add('Number of merchants supported by ' + mxpName + ': ' + countOfMerchants);
                if (String.isNotBlank(mxpBoBUpdateToolReportLink)) {
                    retVal.add(mxpName + '\'s Book of Business report: ' + (navType == 'Console' ?
                        CDdUtilities.createLink(mxpBoBUpdateToolReportLink + mxpName, 'Click here') :
                        CDdUtilities.createLink(mxpBoBUpdateToolReportLink + mxpName, 'Click here',CDdUtilities.CREATELINK_PROPS.ANCHOR_BLANK_TARGET)
                    ));
                }
                userIdsToNameMap.remove(userId);
            }
        }
        for (Id userId : userIdsToNameMap.keySet()) {
            retVal.add(userIdsToNameMap.get(userId) + ' does not support any merchants.');
        }
        return retVal;
    }

    private void addToUserIdsForAggregateQuery(Set<Id> userIdsForAggregateQuery, Map<Id,String> userIdsToNameMap, Id userId, String userName) {
        if (userId != null) {
            userIdsForAggregateQuery.add(userId);
            if (String.isNotBlank(userName)) {
                userIdsToNameMap.put(userId,userName);
            }
        }
    }
}