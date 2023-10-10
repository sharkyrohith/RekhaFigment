/**
 * @author:      Jeegar
 * @date:        2021-04
 * @description: Utilities class for CDdLiveChatTranscriptTriggerHandler
 * @jira:        BZAPSUP-1746
 * @JIRA         Map<IssueCategory, List<Issue_Based_Routing_Map__mdt>>
 */

     public with sharing class CDdChatTranscriptUtilities {
    /**
     * @author:      Jeegar
     * @date:        2021-04
     * @description: Retuns a Map of Issue Category and Issue_Based_Routing_Map__mdt
     * @jira:        BZAPSUP-1746
     * @JIRA         Map<IssueCategory, List<Issue_Based_Routing_Map__mdt>>
     */

    public static Map<String, List<Issue_Based_Routing_Map__mdt>> getIssueBasedRoutingMap() { 
        Map<String, List<Issue_Based_Routing_Map__mdt>> issueCategoryRoutingMap = new Map<String, List<Issue_Based_Routing_Map__mdt>>(); 
        List<Issue_Based_Routing_Map__mdt> ibRoutings = Issue_Based_Routing_Map__mdt.getAll().values();
        List<Issue_Based_Routing_Map__mdt> tempIBRList; 
        for(Issue_Based_Routing_Map__mdt ibRouting : ibRoutings) {
            if(ibRouting.Is_Active__c) {
                if(issueCategoryRoutingMap.containsKey(ibRouting.Issue_Category__c)) {
                    tempIBRList = issueCategoryRoutingMap.get(ibRouting.Issue_Category__c); 
                } else {
                    tempIBRList = new List<Issue_Based_Routing_Map__mdt>(); 
                }
                tempIBRList.add(ibRouting);
                issueCategoryRoutingMap.put(ibRouting.Issue_Category__c, tempIBRList);
            }
        }
        return issueCategoryRoutingMap; 
    }
}