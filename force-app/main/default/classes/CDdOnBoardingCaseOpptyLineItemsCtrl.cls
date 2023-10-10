public with sharing class CDdOnBoardingCaseOpptyLineItemsCtrl {
    
    @AuraEnabled
    public static Response getOpportunityLineItems(String recordId) {
        //input parameter validation
        if(String.isBlank(recordId)){
            return new Response(false, 'Case Id is blank');
        }

        List<OpportunityLineItem> oppLineItems;
        try {
            Case recCase = [ SELECT Opportunity_Name__c FROM Case where Id =:recordId ];
            
            oppLineItems = [
                SELECT Product2Id, Product2.Name, ServiceDate, UnitPrice
                FROM OpportunityLineItem
                WHERE OpportunityId =: recCase.Opportunity_Name__c
            ];
            return new Response(true,oppLineItems);
        } catch (Exception exp) {
           return new Response(false, 'Error while fetching the opportunity line items '+exp.getMessage());
        }
    }

    public class Response {

        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Object data;

        public Response(Boolean isSuccess, String message){
            this.isSuccess = isSuccess;
            this.message = message;
        }

        public Response(Boolean isSuccess, Object data){
            this.isSuccess = isSuccess;
            this.data = data;
        }
    } 
}