public class CDdMxSxQueryCases {   
    //private static instance of the class
    private static Map<Id, Case> cases = null;
    
    //private constructor to avoid creating an instance anywhere outside of this class
    private CDdMxSxQueryCases(){}
    
    public static Map<Id, Case> getCases(Set<Id> caseIds){
        if(cases == null || (!caseIds.isEmpty() && !caseIds.containsAll(cases.keySet()))){
            cases = getCaseData(caseIds);
        }
        return cases;
    }
    public static Map<Id, Case> getCaseData(Set<Id> caseIds){
        return new Map<Id, Case>([SELECT Id, origin, include_marketing_kit__c, Request_Type__c 
                     FROM Case
                     WHERE Id IN :caseIds]);
    }
    
    public static Set<Id> getCaseIds(List<Mx_Order__c> mxOrders){
        Set<Id> caseIds = new Set<Id>();
        for (Mx_Order__c mxOrder : mxOrders){
            if (String.isNotBlank(mxOrder.Case__c)){
                caseIds.add(mxOrder.Case__c);
            }
        }
        return caseIds;
    }
}