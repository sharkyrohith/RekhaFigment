@isTest
public class InstantActivationTest {
    static final String ENDPOINT = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/InstantActivation/';
    @TestSetup
    static void createTestData(){
        List<Account> accs = TDdAccountFactory.createAccounts('InstantActivation', 3, 'Marketplace');
        accs[0].Restaurant_Id__c = '3564';
        accs[1].Restaurant_Id__c = '3533';
        accs[2].Restaurant_Id__c = '3533';
        insert accs;
        List<Contact> cons = new List<Contact>{
            TDdAccountFactory.createContacts(1, accs[0].Id)[0],
            TDdAccountFactory.createContacts(1, accs[1].Id)[0],
            TDdAccountFactory.createContacts(1, accs[2].Id)[0]
        };
        insert cons;
        List<Opportunity> opps = new List<Opportunity>{
            TDdOpportunityFactory.createOpportunityByDevRT('InstantActivation Opp 1', accs[0].Id, cons[0].Id, 'New', 'ML_Inside_Sales'),
            TDdOpportunityFactory.createOpportunityByDevRT('InstantActivation Opp 2', accs[1].Id, cons[1].Id, 'New', 'ML_Inside_Sales'),
            TDdOpportunityFactory.createOpportunityByDevRT('InstantActivation Opp 3', accs[1].Id, cons[1].Id, 'New', 'ML_Inside_Sales'),
            TDdOpportunityFactory.createOpportunityByDevRT('InstantActivation Opp 4', accs[2].Id, cons[2].Id, 'New', 'ML_Inside_Sales')
        };
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(opps, dml);
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true; insert validation;
    }
    
    @isTest static void testPatchOpportunity(){
        
        String oppId = [SELECT Id, Name, StageName, SSME_Escalation_Date_Time__c, SSME_Expiration_Date_Time__c, 
            SSME_Menu_Completion_Date_Time__c, Menu_to_be_completed_by__c FROM Opportunity 
            WHERE Account.Restaurant_Id__c = '3564' AND RecordType.Name IN ('Marketplace','Enterprise Maketplace') LIMIT 1].Id;
        RestRequest req1 = new RestRequest(); 
        RestResponse res1 = new RestResponse();
        req1.requestURI = ENDPOINT+'001000000000000';  
        req1.requestBody = Blob.valueOf('{}');
        req1.httpMethod = 'PATCH';
        RestRequest req2 = new RestRequest(); 
        RestResponse res2 = new RestResponse();
        req2.requestURI = ENDPOINT+oppId;  
        req2.requestBody = Blob.valueOf('{"Id":"invalid_object","Menu_to_be_completed_by__c":"Merchant"}'); // this is successful because api will ignore update to unauthorized fields
        req2.httpMethod = 'PATCH';
        RestRequest req3 = new RestRequest(); 
        RestResponse res3 = new RestResponse();
        req3.requestURI = ENDPOINT+oppId;  
        req3.requestBody = Blob.valueOf('{"SSME_Menu_Completion_Date_Time__c": \'hello\'}'); // expect failure by custom VR, error log created and needs human resolution
        req3.httpMethod = 'PATCH';
        Test.startTest();
        RestContext.request = req1;
        RestContext.response = res1;
        InstantActivation.patchOpportunity();
        RestContext.request = req2;
        RestContext.response = res2;
        InstantActivation.patchOpportunity();
        res2 = RestContext.response;
        RestContext.request = req3;
        RestContext.response = res3;
        InstantActivation.patchOpportunity();
        res3 = RestContext.response;
        Test.stopTest();
        system.assertEquals(404, res1.statusCode);
        system.assertEquals(Blob.valueOf('Resource Id is not a valid Opportunity record Id.'), res1.responseBody);
        system.assertEquals(200, res2.statusCode);
        system.assertEquals(500, res3.statusCode);
        System.assertEquals(true, [SELECT count() FROM Opportunity_Error_Log__c WHERE Parent_Id__c = :oppId] > 0);
    }

}