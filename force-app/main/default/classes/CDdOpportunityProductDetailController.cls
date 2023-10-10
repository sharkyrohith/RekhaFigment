/**
    @author: Dan Thoreson
    @date: 22-Sep-2022
    @group: Mx Services
    @description: Controller class for the LWC which is a form of Product Details (Product_Detail__c), 
                  intended for Storefront or related processes.
    @test class: CDdOpportunityProductDetailCtrlTest
**/
public class CDdOpportunityProductDetailController {

    public static final String STOREFRONT_RT_NAME = 'Storefront';
    public static final Id STOREFRONT_RT_ID = Schema.SObjectType.Product_Detail__c.getRecordTypeInfosByDeveloperName().get(STOREFRONT_RT_NAME).getRecordTypeId();

    /**
        @author: Dan Thoreson
        @date: 03-Oct-2022
        @description: Inserts or updates the Product Details from the lightning web component.
    **/
    @AuraEnabled
    public static Product_Detail__c upsertProductDetail(Id opportunityId, Product_Detail__c details) {
        // First time
        if(details.Id == null) {
            details.Opportunity__c = opportunityId;
            details.RecordTypeId = STOREFRONT_RT_ID; // For now, everything is a Storefront RT from this component
        }

        try {
            upsert details;
        } catch (Exception ex) {
            insert new Apex_Log__c(Class_Name__c = 'CDdOpportunityProductDetailController', 
                                    Method_Name__c = 'upsertProductDetail', 
                                    Log__c = ex.getMessage() + ' | ' + ex.getStackTraceString(), 
                                    Log_Level__c = 'Error');

            throw new AuraHandledException(ex.getMessage());
        }

        return details;
    }

    /**
        @author: Dan Thoreson
        @date: 03-Oct-2022
        @description: Retrieves the Product Details record, or initializes a new one, for a given Opportunity Id. 
    **/
    @AuraEnabled
    public static Product_Detail__c getProductDetailsForOpportunity(Id recordId) {
        Product_Detail__c details;

        // Try to get Product Detail record from Opportunity
        try {
            details = [SELECT Id, Billing_Country__c, CreatedById, DoorDash_Implementation_Owner__c, Implementation_Owner__c, 
                            Implementation_Type__c, LastModifiedById, Mx_Website_Link__c, Opportunity__c, 
                            Opportunity__r.Account.BillingCountry, Partnership_Type__c, Name, RecordTypeId,
                            RecordType.Name, Storefront_Proposed_Date_of_Activation__c, Storefront_Sales_Segment__c,
                            Web_Provider__c, Website_Creation_Needed__c, Opportunity__r.DRN__c, Opportunity__r.Parent_Account_Deck_Rank__c
                        FROM Product_Detail__c
                        WHERE Opportunity__c = :recordId
                        ORDER BY CreatedDate DESC LIMIT 1];
        
        // Doesn't exist - create a new one if we are on a Storefront Onboarding Opportunity
        } catch (QueryException qe) {
            details = new Product_Detail__c(Billing_Country__c=getBillingCountryFromAccount(recordId));
        }

        return details;
    }

    /**
        @author: Dan Thoreson
        @date: 03-Oct-2022
        @description: Gets the applicable Account-level BillingCountry from the child Opportunity
    **/
    public static String getBillingCountryFromAccount(Id opportunityId) {
        Opportunity oppDetails = [SELECT Account.BillingCountry FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        return oppDetails.Account.BillingCountry;
    }

    /**
        @author: Dan Thoreson
        @date: 19-Sep-2022
        @description: Retrieves the RecordType details for this Product Details object - note that Schema.RecordTypeInfo is not returnable in 
                      Aura methods, so using the regular RecordType SObject.
    **/
    @AuraEnabled(cacheable=true)
    public static RecordType getProductDetailRecordTypeInfo(Id opportunityId) {
        // For now, everything will be in this Storefront RT. 
        List<RecordType> storefrontRecordTypes = [SELECT Id, DeveloperName, Name FROM RecordType WHERE Id = :STOREFRONT_RT_ID];
        return !storefrontRecordTypes.isEmpty() ? storefrontRecordTypes[0] : null;
    }
}