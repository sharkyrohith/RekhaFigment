@IsTest
private class CDdOpportunityProductDetailCtrlTest {

    @TestSetup
    static void initData() {
        CDdCaseMilestoneTest.initializeTestSettings();
        TDdOpportunityLineItemFactory.createProducts();

        List<Account> accounts = TDdAccountFactory.createAccounts('StoreFrontCaseParentAccount', 1, 'Marketplace');
        accounts[0].Restaurant_Id__c = '579128';

        insert new List<Account>{accounts[0]};

        List<Account> childAccounts = TDdAccountFactory.createAccounts('StorefrontCaseChildAccount', 1, 'Marketplace');
        childAccounts[0].Restaurant_Id__c = '65748929';  
        childAccounts[0].ParentId = accounts[0].Id;  
        insert childAccounts;
        
        List<Contact> contacts = new List<Contact>{ TDdAccountFactory.createContacts(1, childAccounts[0].Id)[0] };  
        insert contacts;            
        
        List<Opportunity> opportunities = new List<Opportunity>{
            TDdOpportunityFactory.createOpportunityByDevRT('Storefront_Case_Opportunity', childAccounts[0].Id, contacts[0].Id, 'New', 'ML_Inside_Sales')
        };

        opportunities[0].Region_Type__c	= 'Live Region';
        opportunities[0].Menu_to_be_completed_by__c = 'Account Owner';
        opportunities[0].Order_Protocol__c = 'Email';
        opportunities[0].Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
        opportunities[0].Activate_Centrally_2__c = 'No';
        opportunities[0].StageName = 'Closed Won';
        insert opportunities;
    }

    @IsTest
    static void testUpsertProductDetailError() {
        Opportunity storefrontOpp = [SELECT Id FROM Opportunity LIMIT 1];

        // Test Case - success insertion
        Product_Detail__c prodDetails = CDdOpportunityProductDetailController.getProductDetailsForOpportunity(storefrontOpp.Id);
        
        // Pre-insertion assertsions
        System.assertEquals(null, prodDetails.Id, 'The Product Detail record should not yet be inserted.');

        Test.startTest();
            CDdOpportunityProductDetailController.upsertProductDetail(storefrontOpp.Id, prodDetails);
            // prodDetails = CDdOpportunityProductDetailController.getProductDetailsForOpportunity(storefrontOpp.Id);
        Test.stopTest();

        // Post-insertion assertions
        System.assertNotEquals(null, prodDetails.Id);
        System.assertEquals(storefrontopp.Id, prodDetails.Opportunity__c);
        System.assertEquals(CDdCaseMilestoneStorefrontOnboarding.PRODUCT_DETAILS_STOREFRONT_RT, prodDetails.RecordTypeId);

        
        // Test Case 2 -- error insertion
        Boolean errorThrown = false;

        try {
            CDdOpportunityProductDetailController.upsertProductDetail(null, new Product_Detail__c());
        } catch(Exception ex) {
            errorThrown = true;
        }

        System.assert(errorThrown);
        System.assert(![SELECT Id FROM Apex_Log__c].isEmpty());
    }

    @IsTest
    static void testGetProductDetailsForOpportunity() {
        Opportunity storefrontOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Product_Detail__c resultForOppWhereProdDetailDoesNotExist;
        Product_Detail__c resultForOppWithProdDetail;

        Test.startTest();
            // Test Case where there is no existing Product Detail
            resultForOppWhereProdDetailDoesNotExist = CDdOpportunityProductDetailController.getProductDetailsForOpportunity(storefrontOpp.Id);

            // Test Case where there IS an existing Product Detail
            createProductDetail(storefrontOpp.Id);
            resultForOppWithProdDetail = CDdOpportunityProductDetailController.getProductDetailsForOpportunity(storefrontOpp.Id);
        Test.stopTest();

        // A new Product Detail record should have been initialized, but not inserted
        System.assertNotEquals(null, resultForOppWhereProdDetailDoesNotExist, 'A new Product Detail should be returned, value should not be null.');
        System.assertEquals(null, resultForOppWhereProdDetailDoesNotExist.Id, 'A new Product Detail record should be returned, which is not yet in DB.');

        // Product Detail should be pulled from the database, as one already exists. 
        System.assertNotEquals(null, resultForOppWithProdDetail.Id, 'This Product Detail should be pulled from the database.');
        System.assertEquals(CDdCaseMilestoneStorefrontOnboarding.GOOGLE_FOOD, resultForOppWithProdDetail.Implementation_Type__c);
        System.assertEquals(storefrontOpp.Id, resultForOppWithProdDetail.Opportunity__c);

        // Record Type validation
        System.assertEquals(CDdOpportunityProductDetailController.STOREFRONT_RT_NAME, 
                            CDdOpportunityProductDetailController.getProductDetailRecordTypeInfo(storefrontOpp.Id).DeveloperName);
    }

    private static Product_Detail__c createProductDetail(Id opportunityId) {
        Product_Detail__c storefrontDetails = new Product_Detail__c();
        storefrontDetails.RecordTypeId = CDdCaseMilestoneStorefrontOnboarding.PRODUCT_DETAILS_STOREFRONT_RT;
        storefrontDetails.Opportunity__c = opportunityId;
        storefrontDetails.Implementation_Type__c = CDdCaseMilestoneStorefrontOnboarding.GOOGLE_FOOD;
        insert storefrontDetails;
        
        return storefrontDetails;
    }
}