/*
*@Description: Test class to test OCUS API Classes
* CDdOCUSAPIService, CDdOCUSAPIServiceHelper, CDdAPICredentialData, CDdOCUSAPIConstants, CDdOCUSAPIHandler
@Author : Veera Maddukuri
@Date : 2021-11
*/
@isTest
private with sharing class CDdOCUSAPIHandlerTest {

    public static final String photoshootRecordTypeId = CDdRecordTypeCase.photoshootProcessing();
    public static String responseBody = '{"data":{"type":"mission","id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","attributes":{"reference_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","name":"test","current_status":"WAITING_MEDIA_TREATMENT","public_status":"DELIVERED","description":"null,gooogle.commmm","product_types":["PHOTO"],"short_id":94730378,"is_legacy":false,"approved_appointment":"2021-11-30T00:00:00+00:00","internal_reference":"5000r000006tGYTAA2","operator_density":null,"expires_in":33119,"selected_at":"2021-11-24T10:55:33+00:00","attributed_at":"2021-11-24T10:55:34+00:00","started_at":"2021-11-23T16:25:34+00:00","created_at":"2021-11-23T16:25:33+00:00","updated_at":"2021-11-24T11:10:35+00:00","assignment_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16"},"relationships":{"archives":{"data":[{"type":"mission_media_file_archives","id":"953d3110-4d15-11ec-9210-7af2e1e241cd","attributes":{"type":"announcer_delivery","current_status":"DONE","built_at":"2021-11-24T10:59:23+00:00","url":"https://ocus-app-fs-testing-media.s3-accelerate.amazonaws.com/sandbox-customer/organizations/d3a64e90-9dfd-11eb-affe-8a094ca0282a/missions/53f96fba-40e6-11ec-b9e5-0eb76324be16/archive/953d3110-4d15-11ec-9210-7af2e1e241cd.zip?response-content-disposition=attachment%3Bfilename%3Dphotos_94730378_1637751563.zip&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJz%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCWV1LXdlc3QtMyJHMEUCIQDYhhhe6OctmJjEDh%2F%2B4RPKdUW7aYj2teGrGn0knYRpgQIgB5CK1IOpeXrQgxp3sSlpjbIoEj5NZjhWHyVwZF8I8HQq9AMIZRADGgw3NTk5MjY2NzYxNzAiDMeYXsD8wTb8%2Fkf7wCrRA15dVqVKnzg7nwOVidhIB5y2cwKUAxje0jD%2FpFOP%2FCWXRyFCS7FdwdNCm98WWqBXgTdJSv7nQx3sVQHTzLezzYivwe6bc3UYTgUiZNzgcIsrAgOkOnQ5Z50RMR%2BgS7kZVigh4iGd3t8C0IwRlX7l2NVT%2BJTeyubnBL9wqnAT6XlVqGkik%2B%2BSozjq3nMWTpKojKw6Bqcys6zxEm1ia3LyZ8xg7Qe0Qjogl4YG%2F3qfbMa%2FH1a1sqJdB1SuiPGQYgzinj1zeq69mStgIiUf0jawMgbchPuga2hoPCWUQ8ZOxcRgTYEif8danj4zG%2B0SO4C%2BHRCSb%2FHlqEzJUenzSEsfymlBnEjSJdcMm8Yg8QemB4oOV3k6TN0iL7Cz%2FN%2BjbCG9xvbCiR5prk5VWEq6MuLv2%2FShsA%2FZFhmT77XCIsGSk4pFhtCvyTDVWcYQN7LO53Ns820oWJohyZf%2Bg6WBNhh4Mov6zcj8OBcXkvccxmAIzTr%2B0nmB4K689%2FhMPbbV%2FdxxsppXwClSCbyA6QJt3bzr8CtgC5NFClRZXNyNHsjZm4M144Mg%2FD%2F53%2BHntIBN%2F8z4K7SYtoKb7o0m9tGYVtUIBr63PZHe21BbA%2BBdm29WJpw49zD2sfqMBjqlAS9PQRULRnZDa43Ru8e256vntREwgMuknEuVOoNdCbPqIWZoqAOPeyBLhMIFw1Od3XfN3t6%2BrH318wtjkQU5lwo0pEvMSywmCEYJO78VwwuOIR6ndMxZPPyiWq%2BLWkoizXqGEycoV3wuZTzT1s0qhBvYN9m9tBD7Uxze%2B2pxPoGPl09Bfg8vh0JR61nRgQAolXv0vBc18836h4%2FMcwQPyB6sNH5OBw%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA3B3ZI3LFCDXHK4NE%2F20211124%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20211124T202233Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604799&X-Amz-Signature=c6a3cdbd70ebefd10202aa99fe69c81ad26aa1c4a59562631ffca9e9c883eb9b"}},{"type":"mission_media_file_archives","id":"952822d4-4d15-11ec-99b1-7af2e1e241cd","attributes":{"type":"customer_delivery","current_status":"DONE","built_at":"2021-11-24T10:59:23+00:00","url":"https://ocus-app-fs-testing-media.s3-accelerate.amazonaws.com/sandbox-customer/organizations/d3a64e90-9dfd-11eb-affe-8a094ca0282a/missions/53f96fba-40e6-11ec-b9e5-0eb76324be16/archive/952822d4-4d15-11ec-99b1-7af2e1e241cd.zip?response-content-disposition=attachment%3Bfilename%3Dphotos_94730378_1637751563.zip&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJz%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCWV1LXdlc3QtMyJHMEUCIQDYhhhe6OctmJjEDh%2F%2B4RPKdUW7aYj2teGrGn0knYRpgQIgB5CK1IOpeXrQgxp3sSlpjbIoEj5NZjhWHyVwZF8I8HQq9AMIZRADGgw3NTk5MjY2NzYxNzAiDMeYXsD8wTb8%2Fkf7wCrRA15dVqVKnzg7nwOVidhIB5y2cwKUAxje0jD%2FpFOP%2FCWXRyFCS7FdwdNCm98WWqBXgTdJSv7nQx3sVQHTzLezzYivwe6bc3UYTgUiZNzgcIsrAgOkOnQ5Z50RMR%2BgS7kZVigh4iGd3t8C0IwRlX7l2NVT%2BJTeyubnBL9wqnAT6XlVqGkik%2B%2BSozjq3nMWTpKojKw6Bqcys6zxEm1ia3LyZ8xg7Qe0Qjogl4YG%2F3qfbMa%2FH1a1sqJdB1SuiPGQYgzinj1zeq69mStgIiUf0jawMgbchPuga2hoPCWUQ8ZOxcRgTYEif8danj4zG%2B0SO4C%2BHRCSb%2FHlqEzJUenzSEsfymlBnEjSJdcMm8Yg8QemB4oOV3k6TN0iL7Cz%2FN%2BjbCG9xvbCiR5prk5VWEq6MuLv2%2FShsA%2FZFhmT77XCIsGSk4pFhtCvyTDVWcYQN7LO53Ns820oWJohyZf%2Bg6WBNhh4Mov6zcj8OBcXkvccxmAIzTr%2B0nmB4K689%2FhMPbbV%2FdxxsppXwClSCbyA6QJt3bzr8CtgC5NFClRZXNyNHsjZm4M144Mg%2FD%2F53%2BHntIBN%2F8z4K7SYtoKb7o0m9tGYVtUIBr63PZHe21BbA%2BBdm29WJpw49zD2sfqMBjqlAS9PQRULRnZDa43Ru8e256vntREwgMuknEuVOoNdCbPqIWZoqAOPeyBLhMIFw1Od3XfN3t6%2BrH318wtjkQU5lwo0pEvMSywmCEYJO78VwwuOIR6ndMxZPPyiWq%2BLWkoizXqGEycoV3wuZTzT1s0qhBvYN9m9tBD7Uxze%2B2pxPoGPl09Bfg8vh0JR61nRgQAolXv0vBc18836h4%2FMcwQPyB6sNH5OBw%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA3B3ZI3LFCDXHK4NE%2F20211124%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20211124T202233Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604800&X-Amz-Signature=3a0e7215fb832ce3c4be38f9a357aeb0cdcc1ce32c08767973704284b5c69b97"}}]},"organization":{"type":"organization","id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a","attributes":{"name":"DoorDash - Japan","short_id":49062109,"country_code":"JP","vertical":"FOOD","url":null,"description":null,"created_at":"2021-04-15T15:18:26+00:00","updated_at":"2021-10-22T01:37:35+00:00","parent_organization_id":null,"missions_visibility":false,"ready":false,"next_available_appointment":"2021-11-29T20:22:33+00:00"},"relationships":{"owner":{"type":"member","id":"2af9bb7c-d83d-11eb-9ef7-d251dd0c4c88","attributes":{"firstname":"Arun","lastname":"manjappan","email":"amanjappan@doordash.com","email_verified_at":"2021-06-28T18:17:59+00:00","email_unreachable":false,"hubspot_id":null,"locale":"en","position":null,"rate":null,"role":"owner"},"relationships":{"roles":{"data":[{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}]}}},"roles":{"data":[{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}]},"role":{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}}}}}}';
    public static String webhookResponse = '{"type":"event","id":"mission.status.updated","attributes":{"mission_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","mission_reference_id"  :"53f96fba-40e6-11ec-b9e5-0eb76324be16","organization_id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a","public_status":"DELIVERED"}}';
    public static string missionId = '53f96fba-40e6-11ec-b9e5-0eb76324be16';
    public static String responseBodyWithAddress = '{"data":{"type":"mission","id":"f9863c0c-496e-11ec-b771-d66d4d4e40aa","attributes":{"reference_id":"f9863c0c-496e-11ec-b771-d66d4d4e40aa","name":"Japan Account Business Name","current_status":"WAITING_ATTRIBUTION","public_status":"ORDERED","description":"Sales Notes for Menu Team","product_types":["PHOTO"],"short_id":32017969,"is_legacy":false,"approved_appointment":"2021-12-08T13:00:00+00:00","internal_reference":"5008B000000gmnDQAQ","operator_density":null,"expires_in":null,"selected_at":null,"attributed_at":null,"started_at":"2021-11-19T19:29:12+00:00","created_at":"2021-11-19T19:29:12+00:00","updated_at":"2021-11-21T18:39:42+00:00","assignment_id":"f9863c0c-496e-11ec-b771-d66d4d4e40aa"},"relationships":{"address":{"type":"address","id":"f9988470-496e-11ec-9125-d66d4d4e40aa","attributes":{"city":"West","city_en":"West","country_code":"DE","created_at":"2021-11-19T19:29:12+00:00","google_place_id":"ChIJuelpp0PbmUcRHo7axIEZ_yM","lat":48.770829,"lng":9.159632,"location_type":"ROOFTOP","place_name":null,"state":null,"street1":"Rotebühlstraße 121","street2":null,"timezone":"Europe/Berlin","updated_at":"2021-11-19T19:29:13+00:00","zip_code":"70178"}},"organization":{"type":"organization","id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a","attributes":{"name":"DoorDash - Japan","short_id":49062109,"country_code":"JP","vertical":"FOOD","url":null,"description":null,"created_at":"2021-04-15T15:18:26+00:00","updated_at":"2021-10-22T01:37:35+00:00","parent_organization_id":null,"missions_visibility":false,"ready":false,"next_available_appointment":"2021-11-25T06:37:14+00:00"},"relationships":{"owner":{"type":"member","id":"2af9bb7c-d83d-11eb-9ef7-d251dd0c4c88","attributes":{"firstname":"Arun","lastname":"manjappan","email":"amanjappan@doordash.com","email_verified_at":"2021-06-28T18:17:59+00:00","email_unreachable":false,"hubspot_id":null,"locale":"en","position":null,"rate":null,"role":"owner"},"relationships":{"roles":{"data":[{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}]}}},"roles":{"data":[{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}]},"role":{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}}}}}}';
    public static String blockerResponse = '{"data":{"type":"mission","relationships":{"organization":{"type":"organization","relationships":{"organization":null,"offers":null,"media":null,"events":null,"contacts":null,"archives":null,"address":null},"id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","attributes":{"vertical":"FOOD","url":null,"updated_at":"2021-12-07T08:18:25+00:00","started_at":null,"short_id":49062109,"selected_at":null,"reference_id":null,"ready":false,"public_status":null,"product_types":null,"parent_organization_id":null,"operator_density":null,"next_available_appointment":"2021-12-16T03:04:32+00:00","name":"DoorDash - Japan","missions_visibility":false,"is_legacy":null,"internal_reference":null,"expires_in":null,"description":null,"current_status":null,"created_at":"2021-04-15T15:18:26+00:00","country_code":"JP","attributed_at":null,"assignment_id":null,"approved_appointment":null}},"offers":null,"media":null,"events":{"data":[{"type":"mission_event","relationships":[],"id":"84b1fb3a-5910-11ec-8479-7e67691156e2","attributes":{"version":null,"url":null,"uploaded":null,"type":null,"status":"processed","size":null,"relationships":null,"public_status":null,"payload":null,"original_filename":null,"organization_id":null,"name":null,"mission_reference_id":null,"mission_id":null,"mime_type":null,"md5":null,"internal_reference":null,"extension":null,"description":null,"deliverable":null,"current_status":null,"code":"WA:ACTIVATION","blocker_id":null,"blocked_by":null,"assignment_id":null,"approved_appointment":null}},{"type":"mission_event","relationships":[],"id":"84c3c752-5910-11ec-9066-7e67691156e2","attributes":{"version":null,"url":null,"uploaded":null,"type":null,"status":"processed","size":null,"relationships":null,"public_status":null,"payload":null,"original_filename":null,"organization_id":null,"name":null,"mission_reference_id":null,"mission_id":null,"mime_type":null,"md5":null,"internal_reference":null,"extension":null,"description":null,"deliverable":null,"current_status":null,"code":"WA:WAITING_ATTRIBUTION","blocker_id":null,"blocked_by":null,"assignment_id":null,"approved_appointment":null}},{"type":"mission_event","relationships":[],"id":"8e6d76c2-5910-11ec-bd1c-3ea3f095e279","attributes":{"version":null,"url":null,"uploaded":null,"type":null,"status":"processed","size":null,"relationships":null,"public_status":null,"payload":"{comments:写真有る、DDの件伝えた}","original_filename":null,"organization_id":null,"name":null,"mission_reference_id":null,"mission_id":null,"mime_type":null,"md5":null,"internal_reference":null,"extension":null,"description":null,"deliverable":null,"current_status":null,"code":"SP:REFUSAL","blocker_id":"8e7363f2-5910-11ec-9aa6-3ea3f095e279","blocked_by":{"type":"member","id":"fe56c48e-d8af-11eb-afa9-d251dd0c4c88","attributes":{"version":null,"url":null,"uploaded":null,"type":null,"status":null,"size":null,"relationships":null,"public_status":null,"payload":null,"original_filename":null,"organization_id":null,"name":null,"mission_reference_id":null,"mission_id":null,"mime_type":null,"md5":null,"internal_reference":null,"extension":null,"description":null,"deliverable":null,"current_status":null,"code":null,"blocker_id":null,"blocked_by":null,"assignment_id":null,"approved_appointment":null}},"assignment_id":null,"approved_appointment":null}}]},"contacts":null,"archives":null,"address":null},"id":"847dc2fc-5910-11ec-8319-7e67691156e2","attributes":{"version":null,"url":null,"uploaded":null,"type":null,"status":null,"size":null,"relationships":null,"public_status":"ORDERED","payload":null,"original_filename":null,"organization_id":null,"name":"あじひろ","mission_reference_id":null,"mission_id":null,"mime_type":null,"md5":null,"internal_reference":"1016064","extension":null,"description":"https://www.doordash.com/store/2576745/2547568?preview=1 Monday: 17:00:00 - 21:00:00 &#124;<br> Tuesday: 17:00:00 - 21:00:00 &#124;<br> Wednesday: 17:00:00 - 21:00:00 &#124;<br> Thursday: 17:00:00 - 21:00:00 &#124;<br> Friday: 17:00:00 - 21:00:00 &#124;<br> Saturday: 17:00:00 - 21:00:00 &#124;<br> Sunday: 17:00:00 - 21:00:00","deliverable":null,"current_status":"WAITING_ATTRIBUTION","code":null,"blocker_id":null,"blocked_by":null,"assignment_id":"847dc2fc-5910-11ec-8319-7e67691156e2","approved_appointment":null}}}';
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }

    /**
	* @description Prepare and return the test running user
	*/
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    @TestSetup
    static void testSetup() {
        System.runAs(getTestRunUser()){
            CDdContactTriggerHelper.insertCampaign();

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Case_Validations__c  = true;
            insert validation;

            List<Account> accountsToInsert = CDdTestDataFactory.createSObjectList('Account', 3, false);
            accountsToInsert[0].Name = 'Test Acc Germany';
            accountsToInsert[0].BillingStreet = 'Rotebühlstraße 121';
            accountsToInsert[0].BillingCity = 'Stuttgart';
            accountsToInsert[0].BillingPostalCode = '70178';
            accountsToInsert[0].BillingCountryCode = 'DE';
            accountsToInsert[0].BillingCountry = 'Germany';
            accountsToInsert[0].Legal_Business_Name__c = 'German';
            accountsToInsert[0].Market_Area__c = 'Northern California - East Bay';
            accountsToInsert[0].Business_ID__c = 123456;
            accountsToInsert[0].Language__c = 'German';
            accountsToInsert[0].RecordTypeId = CDdRecordTypeAccount.prospect();

            accountsToInsert[1].Name = 'Test Acc US';
            accountsToInsert[1].BillingStreet = '27-EA Tilo Ave Comerio Los Almendros';
            accountsToInsert[1].BillingCity = 'Bayamon';
            accountsToInsert[1].BillingPostalCode = '00981';
            accountsToInsert[1].BillingState = 'Puerto Rico';
            accountsToInsert[1].BillingCountryCode = 'US';
            accountsToInsert[1].BillingCountry = 'United States';
            accountsToInsert[1].Legal_Business_Name__c = 'PuertoRico';
            accountsToInsert[1].Market_Area__c = 'Northern California - East Bay';
            accountsToInsert[1].Business_ID__c = 123452;
            accountsToInsert[1].Language__c = 'English';
            accountsToInsert[1].RecordTypeId = CDdRecordTypeAccount.prospect();


            accountsToInsert[2].Name = 'Test Acc Caviar US';
            accountsToInsert[2].BillingStreet = '20 Cooper Square';
            accountsToInsert[2].BillingCity = 'New York';
            accountsToInsert[2].BillingPostalCode = '10003';
            accountsToInsert[2].BillingCountryCode = 'US';
            accountsToInsert[2].BillingCountry = 'United States';
            accountsToInsert[2].Legal_Business_Name__c = 'NewYork';
            accountsToInsert[2].Market_Area__c = 'Northern California - East Bay';
            accountsToInsert[2].Business_ID__c = 123453;
            accountsToInsert[2].Language__c = 'English';
            accountsToInsert[2].RecordTypeId = CDdRecordTypeAccount.prospect();
            accountsToInsert[2].Deck_Rank__c = 'Ace of Spades';
            insert accountsToInsert;

            List<Contact> conToInsert = new List<Contact>();
            Contact con1 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => accountsToInsert[0].Id
                    }, false);
            conToInsert.add(con1);

            Contact con2 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => accountsToInsert[1].Id
                    }, false);
            conToInsert.add(con2);
            insert conToInsert;

            List<Opportunity> oppToInsert = new List<Opportunity>();

            Opportunity opp1 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con1.AccountId, con1.id, 'Closed Won');
            opp1.Tablet_Received_Date__c = null;
            opp1.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ML_Inside_Sales').getRecordTypeId();
            oppToInsert.add(opp1);

            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con2.AccountId, con2.id, 'Closed Won');
            opp2.Tablet_Received_Date__c = null;
            opp2.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ML_Inside_Sales').getRecordTypeId();
            oppToInsert.add(opp2);

            Opportunity opp3 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con2.AccountId, con2.id, 'Closed Won');
            opp2.Tablet_Received_Date__c = null;
            opp3.Platform__c = 'Caviar';
            opp3.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ML_Inside_Sales').getRecordTypeId();
            oppToInsert.add(opp3);
            insert oppToInsert;

            List<Case> caseToInsert = CDdTestDataFactory.createSObjectList('Case', 3, false);
            caseToInsert[0].Store_ID__c = '11';
            caseToInsert[0].BusinessHours =null;
            caseToInsert[0].Subject = 'setAccountIdUpdateTest1';
            caseToInsert[0].RecordTypeId = photoshootRecordTypeId;
            caseToInsert[0].Photo_Provider__c = 'OCUS';
            caseToInsert[0].Photo_Review_Notes__c = 'OCUS';
            caseToInsert[0].Language__c = 'German';
            caseToInsert[0].Menu_Preview_Links__c = 'Menu preview links';
            caseToInsert[0].AccountId = accountsToInsert[0].Id;
            caseToInsert[0].Opportunity_Name__c = opp1.Id;

            caseToInsert[1].Store_ID__c = '22';
            caseToInsert[1].BusinessHours =null;
            caseToInsert[1].Subject = 'setAccountIdUpdateTest2';
            caseToInsert[1].RecordTypeId = photoshootRecordTypeId;
            caseToInsert[1].Photo_Provider__c = 'OCUS';
            caseToInsert[1].Photo_Review_Notes__c = 'OCUS';
            caseToInsert[1].Language__c = 'English';
            caseToInsert[1].Menu_Preview_Links__c = 'Menu preview links';
            caseToInsert[1].AccountId = accountsToInsert[1].Id;
            caseToInsert[1].Opportunity_Name__c = opp2.Id;

            caseToInsert[2].Store_ID__c = '33';
            caseToInsert[2].BusinessHours =null;
            caseToInsert[2].Subject = 'setAccountIdUpdateTest3';
            caseToInsert[2].RecordTypeId = photoshootRecordTypeId;
            caseToInsert[2].Photo_Provider__c = 'OCUS';
            caseToInsert[2].Photo_Review_Notes__c = 'OCUS';
            caseToInsert[2].Language__c = 'English';
            caseToInsert[2].Menu_Preview_Links__c = 'Menu preview links';
            caseToInsert[2].AccountId = accountsToInsert[2].Id;
            caseToInsert[2].Opportunity_Name__c = opp3.Id;
            insert caseToInsert;
        }
    }

    @isTest
    static void testCreateMilestone() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        CDdRestJSONObj.OCUSMissionResponse res = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        res.data.attributes.internal_reference = cs.Id;
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(res));
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.createOCUSPhotoshoot(new List<Id>{cs.Id});
        Test.stopTest();

        cs = [SELECT Id, Kodakit_Job_Id__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertNotEquals(null, cs.Kodakit_Job_Id__c);
    }

    @isTest
    static void testCreateMilestonePuertoRico() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId AND Subject = 'setAccountIdUpdateTest2' LIMIT 1];
        CDdRestJSONObj.OCUSMissionResponse res = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        res.data.attributes.internal_reference = cs.Id;
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(res));
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.createOCUSPhotoshoot(new List<Id>{cs.Id});
        Test.stopTest();

        cs = [SELECT Id, Kodakit_Job_Id__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertNotEquals(null, cs.Kodakit_Job_Id__c);
    }

    @isTest
    static void testCreateMilestoneError() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        String responseBody = '{"message":"The given data was invalid.","errors":{"data.relationships.offers.data":["The mission must have an offer with a product."]}}';
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(responseBody,500);
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.createOCUSPhotoshoot(new List<Id>{cs.Id});

        cs = [SELECT Id, Kodakit_Job_Id__c,Error_Exception__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assert(cs.Error_Exception__c.contains('The mission must have an offer with a product'));
        CDdOCUSAPIHandler.handleOCUSPhotoshoot(new Set<Id>{cs.Id},true);
        CDdOCUSAPIHandler.handleOCUSPhotoshoot(new Set<Id>{cs.Id},false);
        Test.stopTest();
    }

    @isTest
    static void testCreateMilestoneErrorPuertoRico() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId AND Subject = 'setAccountIdUpdateTest2' LIMIT 1];
        String responseBody = '{"message":"The given data was invalid.","errors":{"data.relationships.offers.data":["The mission must have an offer with a product."]}}';
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(responseBody,500);
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.createOCUSPhotoshoot(new List<Id>{cs.Id});

        cs = [SELECT Id, Kodakit_Job_Id__c,Error_Exception__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assert(cs.Error_Exception__c.contains('The mission must have an offer with a product'));
        CDdOCUSAPIHandler.handleOCUSPhotoshoot(new Set<Id>{cs.Id},true);
        CDdOCUSAPIHandler.handleOCUSPhotoshoot(new Set<Id>{cs.Id},false);
        Test.stopTest();
    }

    @isTest
    static void testCreateMilestoneCaviar() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId AND Subject = 'setAccountIdUpdateTest3' LIMIT 1];
        CDdRestJSONObj.OCUSMissionResponse res = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        res.data.attributes.internal_reference = cs.Id;
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(res));
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.createOCUSPhotoshoot(new List<Id>{cs.Id});
        Test.stopTest();

        cs = [SELECT Id, Kodakit_Job_Id__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertNotEquals(null, cs.Kodakit_Job_Id__c);
    }

    @isTest
    static void testUpdateCaseMediaURLFromOCUS() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        cs.Kodakit_Job_Id__c = missionId;
        update cs;
        CDdRestJSONObj.OCUSMissionResponse res = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        CDdRestJSONObj.OCUSWebhookResponse webhookResp = (CDdRestJSONObj.OCUSWebhookResponse)JSON.deserialize(webhookResponse, CDdRestJSONObj.OCUSWebhookResponse.class);
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(res));
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.updateCaseMediaURLFromOCUS(webhookResp);
        Test.stopTest();

        cs = [SELECT Id, Kodakit_Job_Id__c,Kodakit_Event__c,Kodakit_Pictures_URL__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertEquals('DELIVERED', cs.Kodakit_Event__c);
    }

    @isTest
    static void testUpdateCaseAppointmentDateFromOCUS() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        cs.Kodakit_Job_Id__c = missionId;
        update cs;
        CDdRestJSONObj.OCUSMissionResponse res = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBodyWithAddress, CDdRestJSONObj.OCUSMissionResponse.class);
        res.data.attributes.internal_reference = cs.Id;
        CDdRestJSONObj.OCUSWebhookResponse webhookResp = (CDdRestJSONObj.OCUSWebhookResponse)JSON.deserialize(webhookResponse, CDdRestJSONObj.OCUSWebhookResponse.class);
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(res));
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.updateCaseAppointmentDateFromOCUS(webhookResp);

        cs = [SELECT Id, Kodakit_Job_Id__c,Kodakit_Event__c,Photoshoot_Date__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertNotEquals(null, cs.Photoshoot_Date__c);
        Test.stopTest();
    }

    @isTest
    static void testupdateCaseStatusFromOCUS() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        cs.Kodakit_Job_Id__c = missionId;
        update cs;

        CDdRestJSONObj.OCUSWebhookResponse webhookResp = (CDdRestJSONObj.OCUSWebhookResponse)JSON.deserialize(webhookResponse, CDdRestJSONObj.OCUSWebhookResponse.class);
        webhookResp.attributes.public_status = 'COMPLETED';
        Test.startTest();
        CDdOCUSAPIHandler.updateCaseStatusFromOCUS(webhookResp);

        cs = [SELECT Id,Status, Kodakit_Job_Id__c,Kodakit_Event__c,Kodakit_Pictures_URL__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertEquals('COMPLETED', cs.Kodakit_Event__c);
        System.assertEquals('Closed', cs.Status);
        Test.stopTest();
    }


    @isTest
    static void testUpdateSalesNotesOnOCUS() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        String responseBody = '{ "message": "No query results for uid"}';
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(responseBody,500);
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.updateSalesNotesOnOCUS(new Set<Id>{cs.Id});

        cs = [SELECT Id, Kodakit_Job_Id__c,Error_Exception__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertNotEquals('No query results for uid', cs.Error_Exception__c);
        Test.stopTest();
    }


    @isTest
    static void testServiceHelperCatchBlocks() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        Test.startTest();
        CDdOCUSAPIHandler.createOCUSPhotoshoot(new List<Id>{cs.Id});

        cs = [SELECT Id, Kodakit_Job_Id__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertEquals(null, cs.Kodakit_Job_Id__c);
        Test.stopTest();
    }

    @isTest
    static void testServiceCatchBlocks() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        Test.startTest();
        CDdOCUSAPIHandler.createOCUSPhotoshoot(new List<Id>{cs.Id});
        CDdOCUSAPIService.getOCUSMilestoneAPI('dummy token','URL'+missionId);
        cs = [SELECT Id, Kodakit_Job_Id__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertEquals(null, cs.Kodakit_Job_Id__c);
        Test.stopTest();
    }

    @isTest
    static void testUpdateCaseBlockedStatusFromOCUS() {
        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        String blockerWebhook = '{"type":"event","id":"mission.blocker.set","attributes":{"mission_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","mission_reference_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","organization_id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a"}}';
        cs.Kodakit_Job_Id__c = missionId;
        update cs;
        blockerResponse.replaceAll('\"', '\\"');
        CDdRestJSONObj.OCUSMissionResponse res = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(blockerResponse, CDdRestJSONObj.OCUSMissionResponse.class);
        res.data.attributes.internal_reference = cs.Id;
        CDdRestJSONObj.OCUSWebhookResponse webhookResp = (CDdRestJSONObj.OCUSWebhookResponse)JSON.deserialize(blockerWebhook, CDdRestJSONObj.OCUSWebhookResponse.class);
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(res));
        Test.setMock(HttpCalloutMock.class, mock);
        CDdOCUSAPIHandler.updateCaseBlockedStatusFromOCUS(webhookResp);

        cs = [SELECT Id, Kodakit_Job_Id__c,Kodakit_Event__c,Photoshoot_Date__c,Kodakit_Message__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertNotEquals(null, cs.Kodakit_Message__c);
        Test.stopTest();
    }

    /*
    * @author Abhijeet
    * @date 2021-12
    * @description BZAP-14111 : OCUS: Prefix +1 to all canada phone numbers Test
    */
    @isTest
    static void testCanadaPhoneNumberSentToOCUS() {
        System.runAs(getTestRunUser()){
            List<Account> accountsToInsert = new List<Account>();
            Test.startTest();
            List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1, false);
            for (Integer i = 0; i < acclist.size(); i++) {
                acclist[i].Name = 'Test Account CANADA OCUS';
                acclist[i].BillingStreet = 'Test Street';
                acclist[i].BillingCity = 'Test City';
                acclist[i].BillingPostalCode = '70148';
                acclist[i].BillingCountryCode = 'CA';
                acclist[i].BillingCountry = 'Canada';
                acclist[i].Legal_Business_Name__c = 'Canada';
                acclist[i].Business_ID__c = 123456;
                acclist[i].Language__c = 'English';
                acclist[i].RecordTypeId = CDdRecordTypeAccount.prospect();
                accountsToInsert.add(acclist[i]);
            }
            insert accountsToInsert;

            Contact con1 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => accountsToInsert[0].Id,
                'Phone' => '3322114455',
                'Email' => 'test@test.testeam'
                    }, false);
            insert con1;
            System.debug(con1);

            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con1.AccountId, con1.id, 'Closed Won');
            opp2.Tablet_Received_Date__c = null;
            opp2.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ML_Inside_Sales').getRecordTypeId();
            insert opp2;

            List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 1, false);
            for(Integer i = 0; i < 1; i++){
                cslist1[i].Store_ID__c = '' +i;
                cslist1[i].BusinessHours =null;
                cslist1[i].Subject = 'setAccountIdUpdateTest'+i;
                cslist1[i].RecordTypeId = photoshootRecordTypeId;
                cslist1[i].Photo_Provider__c = 'OCUS';
                cslist1[i].Photo_Review_Notes__c = 'OCUS';
                cslist1[i].Language__c = 'English';
                cslist1[i].Menu_Preview_Links__c = 'Menu preview links';
                cslist1[i].AccountId = accountsToInsert[0].Id;
                cslist1[i].Opportunity_Name__c = opp2.Id;
                cslist1[i].ContactId = con1.Id;
            }
            insert cslist1;
            List<Case> onboardingCaseList = CDdOCUSAPIHandler.getCases(new Set<Id> {cslist1[0].Id});

            CDdRestJSONObj.OCUSAPIRequest request = CDdOCUSAPIServiceHelper.prepareOCUSMilestoneRequest(onboardingCaseList[0]);
            Test.stopTest();
            System.assertEquals(true, request?.data?.relationships?.contacts?.data[0]?.attributes?.phone_1.startsWith('+1'), 'Canada Phone number does not have prefix +1');
        }
    }

    /*
    * @author Swedhaa Sri M
    * @date Feb,2023
    * @description BASD-42481 : OCUS: Formatting Photoshoot Date/Time
    */
    @isTest
    static void testFormatPhotoshootDate() {
        System.runAs(getTestRunUser()){
            Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Acc Germany' LIMIT 1];

            Contact con1 = [SELECT Id FROM Contact WHERE AccountId =: testAcc.Id LIMIT 1];

            Opportunity opp2 = [SELECT Id, Photoshoot_Date__c, Photoshoot_Time__c FROM Opportunity WHERE Name = 'CloseWonOpp' AND AccountId =: testAcc.Id LIMIT 1];
            opp2.Photoshoot_Date__c = Date.newInstance(2023, 1, 20);
            opp2.Photoshoot_Time__c = '10:00 AM';
            update opp2;

            List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 1, false);
            for(Integer i = 0; i < 1; i++){
                cslist1[i].Store_ID__c = '' +i;
                cslist1[i].BusinessHours =null;
                cslist1[i].Subject = 'setAccountIdInsertTest'+i;
                cslist1[i].RecordTypeId = photoshootRecordTypeId;
                cslist1[i].Photo_Provider__c = 'OCUS';
                cslist1[i].Photo_Review_Notes__c = 'OCUS';
                cslist1[i].Photoshoot_Date__c = opp2.Photoshoot_Date__c;
                cslist1[i].Photoshoot_Time__c = opp2.Photoshoot_Time__c;
                cslist1[i].Language__c = 'English';
                cslist1[i].Menu_Preview_Links__c = 'Menu preview links';
                cslist1[i].AccountId = testAcc.Id;
                cslist1[i].Opportunity_Name__c = opp2.Id;
                cslist1[i].ContactId = con1.Id;
            }
            insert cslist1;
            List<Case> onboardingCaseList = CDdOCUSAPIHandler.getCases(new Set<Id> {cslist1[0].Id});

            Test.startTest();
            CDdRestJSONObj.OCUSAPIRequest request = CDdOCUSAPIServiceHelper.prepareOCUSMilestoneRequest(onboardingCaseList[0]);
            Test.stopTest();
            System.assertEquals('2023-01-20T10:00:00-0800', CDdOCUSAPIServiceHelper.formatOCUSPhotoshootDate(onboardingCaseList[0]));
            System.assertEquals('2023-01-20T10:00:00-0800', request?.data?.attributes?.approved_appointment, 'Appointment Date/Time is not formatted as per ISO-8601 format');
        }
    }

    /*
    * @author Swedhaa Sri M
    * @date Feb,2023
    * @description BASD-42481 : OCUS: test for Validating Photoshoot Case Data
    */
    @isTest
    static void testValidateOCUSPhotoshootData() {
        System.runAs(getTestRunUser()){
            String photoshootDateTimeErrorMessage = CDdNameValuePairHelper.getTextValue('OCUSPhotoshootDateError');
            Map<String,Id> queueNameVsIdMap = CDdOCUSAPIHandler.getQueuesByDeveloperName(CDdOCUSAPIConstants.queueDeveloperNames);
            Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Acc Germany' LIMIT 1];

            Contact con1 = [SELECT Id FROM Contact WHERE AccountId =: testAcc.Id LIMIT 1];

            Opportunity opp2 = [SELECT Id, Photoshoot_Date__c, Photoshoot_Time__c FROM Opportunity WHERE Name = 'CloseWonOpp' AND AccountId =: testAcc.Id LIMIT 1];

            List<Case> cs = [SELECT Id, RecordtypeId, Photoshoot_Date__c, Photoshoot_Time__c, Kodakit_Error__c, OwnerId, Opportunity_Name__c, Menu_Preview_Links__c, Shipping_Address_Country__c, Return_Shipping_Address_State__c, Photo_Provider__c
                             FROM Case WHERE RecordTypeId = :photoshootRecordTypeId AND Opportunity_Name__c =: opp2.Id LIMIT 1];
            cs[0].Shipping_Address_Country__c = 'Germany';
            cs[0].Photoshoot_Date__c = Date.newInstance(2023, 1, 20);

            Test.startTest();
            CDdCaseTriggerHelperV2.validateOCUSPhotoshootData(cs, null);
            update cs;
            Test.stopTest();

            Case caseToCheck = [SELECT Id, Kodakit_Error__c, Photoshoot_Date__c, Photoshoot_Time__c, OwnerId FROM Case WHERE Opportunity_Name__c = : opp2.Id AND RecordTypeId =: photoshootRecordTypeId];
            System.assertEquals('Missing the Photoshoot date/time', caseToCheck.Kodakit_Error__c);
            System.assertEquals(queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_Germany'), caseToCheck.OwnerId);
        }
    }
}