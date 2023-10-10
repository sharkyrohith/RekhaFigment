/**
 *
 * @author: Tia Xuan
 * @date: 2020-07
 * @description Ctonroller for Solve case button
 *
 */
public with sharing class CDdCloseOnSolvedController {

    public static final set<String> SET_ISSUE_TYPES = new set<String>{
                                                                    CDdSupportConstants.ISSUETYPE_LIVE_ORDER_MX,
                                                                    CDdSupportConstants.ISSUETYPE_LIVE_ORDER_CX,
                                                                    CDdSupportConstants.ISSUETYPE_DOORDASH_DRIVE_MX,
                                                                    CDdSupportConstants.ISSUETYPE_DOORDASH_DRIVE_CX
                                                                };
    public static final set<String> LIVE_ORDER_SET_ISSUE_TYPES= new set<String>{
																	CDdSupportConstants.ISSUETYPE_LIVE_ORDER_MX,
																	CDdSupportConstants.ISSUETYPE_LIVE_ORDER_CX
																};
	public static final set<String> DRIVE_ORDER_SET_ISSUE_TYPES= new set<String>{
																	CDdSupportConstants.ISSUETYPE_DOORDASH_DRIVE_MX,
																	CDdSupportConstants.ISSUETYPE_DOORDASH_DRIVE_CX
																};
    @AuraEnabled
    public static void setCaseToSolved(String caseId){
        Case c = [  select  Id,
                            Status,
                            ChatKey__c,issue__c,
                            Issue_Type__c,DeliveryUUID__c
                    from Case
                    where Id =: caseId];

        /*Sugan: BASD-46840 - new method in supporthelper to identify live order issues
        and mandate delivery uuid based on this */
        if (c.Status != CDdSupportConstants.SOLVED_STATUS){
            if(CDdSupportHelper.isLiveOrderIssue(c) && String.isBlank(c.DeliveryUUID__c)){
                AuraHandledException auraException = new AuraHandledException(System.Label.Case_Notes_Require_Delv_for_LiveOrder);
                auraException.setMessage(System.Label.Case_Notes_Require_Delv_for_LiveOrder);//this is required for us tovalidate in test classes
                throw auraException;
            }
            c.Status = CDdSupportConstants.SOLVED_STATUS;
            update c;
        }
    }

}