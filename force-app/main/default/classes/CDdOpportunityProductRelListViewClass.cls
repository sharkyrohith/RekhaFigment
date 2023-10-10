public with sharing class CDdOpportunityProductRelListViewClass {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getLimitRecords(String oppId){
        return [
            SELECT OpportunityId, Id, Order_Service_Type__c, Name, Target_Cx_Audience__c, Marketing_Flat_Fee__c, Product_Name__c,
            Order_Cart_Minimum__c, Flat_Discount_Amount_for_Consumer__c, Discount_Percentage__c, SBQQ__QuoteLine__c,
            SBQQ__QuoteLine__r.Name
            FROM OpportunityLineItem
            WHERE OpportunityId =: oppId
            ORDER BY SBQQ__QuoteLine__c ASC
            LIMIT 3
        ];
	}
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getAllRecords(String oppId){
        return [
            SELECT OpportunityId, Id, Order_Service_Type__c, Name, Target_Cx_Audience__c, Marketing_Flat_Fee__c, Product_Name__c,
            Order_Cart_Minimum__c, Flat_Discount_Amount_for_Consumer__c, Discount_Percentage__c, SBQQ__QuoteLine__c,
            SBQQ__QuoteLine__r.Name, Opportunity.Opportunity_Name_External_Use__c
            FROM OpportunityLineItem
            WHERE OpportunityId =: oppId
            ORDER BY SBQQ__QuoteLine__c ASC
        ];
	}
}