/**
 * 
 * @author: Tia Xuan
 * @date: 2021-02
 * @description Class to attach call for Amazon connect
 * 
 */
public class CDdCaseAttachCallCtrl {
    @AuraEnabled
    public static void postFeed(String caseId, String callType){
        
        AC_Outbound_Call__c oc = new AC_Outbound_Call__c();
        oc.Agent_Username__c = UserInfo.getUserEmail();
        oc.Call_Type__c = callType;
        oc.Case__c = caseId;
        insert oc;
        
    }
}