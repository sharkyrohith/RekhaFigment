/**
* @author: Pradeep Kumar Reddy Katigari
* @date: 11-2022
* @description: This controller class is used in lwcDdVoidPrebot LWC component.
                It is used to make callout to Tray, get Opportunity Details and get Custom Metadata.
*/
public with sharing class CDdVoidPrebotController {
    public static final String Prebot_Total_Waiting_Time_Interval_Sec = 'Prebot_Total_Waiting_Time_Interval_Sec';
    public static final String Prebot_Time_Interval_Sec = 'Prebot_Time_Interval_Sec';

    /**
     * @description this function is to get the Set Time Interval Values from Custom Metadata
     * Ticket BZAP-18510
     */
    @AuraEnabled
    public static Map<String, Integer> getSetTimeIntervalValues(){
        Map<String, Integer> setIntervalMap = New Map<String, Integer>();
        setIntervalMap.put(Prebot_Total_Waiting_Time_Interval_Sec, CDdNameValuePairHelper.getIntegerValue(Prebot_Total_Waiting_Time_Interval_Sec));
        setIntervalMap.put(Prebot_Time_Interval_Sec, CDdNameValuePairHelper.getIntegerValue(Prebot_Time_Interval_Sec));
        return setIntervalMap;
    }

    /**
     * @description this function is to Recall Approval for the Quote
     * @param quotes Id = Quote Id
     * Ticket BZAP-18510
     */
    @AuraEnabled
    public static Boolean recallApprovalQuote(String recordId){
        try {
            if (recordId != null) {
                SBAA.ApprovalAPI.recall(recordId, SBAA__Approval__c.AQS_Quote__c);
            }
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return true;
    }

    /**
     * @description this function is to get the Prebot Link and Prebot Error from Opportunity
     * @param quotes Id = OpportunityId
     * Ticket BZAP-18510
     */
    @AuraEnabled
    public static Opportunity getOpportunity(Id opportunityId){
        try {
            Set<Id> opportunityIds = new Set<Id>{opportunityId};
            List<Opportunity> oppList = OpportunitiesSelector.newInstance().selectById(opportunityIds);
            return oppList[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description this function is to make callout to Tray
     * @param quotes String = Quote Id
     * Ticket BZAP-18510
     */
    @AuraEnabled
    public static Boolean callOuttoTray(String recordId){
        try {
            Boolean ack = false;
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Tray_Void_Prebot?quoteid='+recordId);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200) {
                String body = response.getBody();
                String acknowledgement = body.substringBetween('<Ack>', '</Ack>');
                ack = Boolean.valueof(acknowledgement);
            }
            return ack;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}