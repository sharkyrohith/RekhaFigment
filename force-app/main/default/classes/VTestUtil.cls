@isTest
public with sharing class VTestUtil {
    public static final String DISPATCH_DELIVERY_MESSAGE = '{"active_date": "2021-01-14","delivery_uuid": "8c3e7902-6e4e-4abe-8ad4-bf5cbc8c293d","consumer": {"phone_number": "(424) 345-7410","first_name": "David","last_name": "Little","experience": "doordash","email": "jehorowitz@gmail.com","phone_number_components": {"formatted_national_number": "(310) 314-7275","national_number": "8594322705","formatted_international_number": "+1 310-314-7275","country_code": "1","international_number": "+13103147275","country_shortname": "US"},"id": 425853154},"id": "","store": {"phone_number": "(310)314-7275","name": "Zaxby\'s (31301)","business": {"description": "Chicken fingers, wings, salads & more","id": 12704,"name": "Zaxby\'s"},"address": {"city": "Lexington","subpremise": "","id": 18782833,"printable_address": "1772 Sharkey Way, Lexington, KY 40511, USA","state": "KY","street": "1772 Sharkey Way","country": "United States","lat": 38.0692046,"lng": -84.5307175,"shortname": "1772 Sharkey Way","zip_code": "40511"},"submarket": {"id": 80,"name": "Lexington"},"order_protocol": "POINT_OF_SALE","id": 781741,"is_partner": true},"dasher": {"phone_number": "(812) 595-4426","first_name": "Dennis","last_name": "Delisser","email": "ddelisser55@gmail.com","phone_number_components": {"formatted_national_number": "(812) 595-4426","national_number": "8125954426","formatted_international_number": "+1 310-314-7275","country_code": "1","international_number": "+13103147275","country_shortname": "US"},"id": 10605493}}';
    public static final String ERS_DISPATCH_DELIVERY_MESSAGE = '{"salesforceAudienceInfoBulkResponse":[{"customerType":0,"audience":{"consumerAudience":{"id":"425853154","firstName":"David","lastName":"Little","email":"little.david7607@gmail.com","phoneNumber":"+18594322705","country":"US","experience":0,"cxUnavailLast3OrdersFlag":9999,"isVip":false,"vipTier":0,"language":"en-US","address":{"id":"86577017","street":"2309 Frankfort Court","createdAt":"2020-04-01T16:18:31.919Z","zipCode":"40510","lat":38.0684768,"lng":-84.5501061,"establishment":"","subpremise":"","neighborhood":"","country":"United States","formattedAddress":"2309 Frankfort Ct, Lexington, KY 40510, USA","administrativeAreaLevel1":"KY","administrativeAreaLevel2":"Fayette County","locality":"Lexington","countryShortname":"US","googlePlaceId":"ChIJ40ufkKZDQogR2QPvS9csxks","isGeneric":false,"name":"2309 Frankfort Ct","city":"Lexington","postalCode":"40510","languageCode":"en"},"isSubscribedConsumer":true,"phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 859-432-2705","formattedNationalNumber":"(859) 432-2705","internationalNumber":"+18594322705","nationalNumber":"8594322705"},"consumerSubscriptionPlan":{"id":20731631},"consumerDeliveryStatus":1,"availableConsumerCredits":0,"submarketId":"80","submarketName":"Lexington","availableConsumerCreditsMonetaryFields":{"unitAmount":0,"currency":"USD","displayString":"$0.00","decimalPlaces":2,"sign":true,"symbol":"$"}},"dasherAudience":{"id":"10605493","firstName":"Dennis","lastName":"Delisser","email":"ddelisser55@gmail.com","address":{},"experience":0,"phoneNumberComponents":{},"language":"en-US","dasherDeliveryStatus":6},"store":{"id":"781741","name":"Zaxbys (31301)","business":{"id":"12704","name":"Zaxbys", "businessVerticalId": "123456"},"phoneNumber":"+18592260011","address":{"id":"18782833","street":"1772 Sharkey Way","createdAt":"2018-05-31T20:20:20.716Z","zipCode":"40511","lat":38.0692046,"lng":-84.5307175,"establishment":"","subpremise":"","neighborhood":"","country":"United States","formattedAddress":"1772 Sharkey Way, Lexington, KY 40511, USA","administrativeAreaLevel1":"KY","administrativeAreaLevel2":"Fayette County","locality":"Lexington","countryShortname":"US","googlePlaceId":"ChIJ5Q4djoRDQogRkzVvM6g_Cr8","isGeneric":false,"name":"1772 Sharkey Way","city":"Lexington","postalCode":"40511","postalCodeSuffix":"2028","languageCode":"en"},"orderProtocol":"POINT_OF_SALE","phoneNumberComponents":{"countryCode":"1","countryShortname":"US","formattedInternationalNumber":"+1 859-226-0011","formattedNationalNumber":"(859) 226-0011","internationalNumber":"+18592260011","nationalNumber":"8592260011"},"isPartner":false}},"delivery":{"mostRecentDeliveryUuid":"8c3e7902-6e4e-4abe-8ad4-bf5cbc8c293d","totalCost":{"unitAmount":2147,"currency":"USD","displayString":"$21.47","decimalPlaces":2,"sign":true,"symbol":"$"},"orderSource":"mp","deliveryUuid":"8c3e7902-6e4e-4abe-8ad4-bf5cbc8c293d","currency":"USD","statusOfCreditRefund":[{"id":161997428,"category":"missing","createdAt":"2021-01-14T17:23:18.200Z","consumerRefund":{"unitAmount":350,"currency":"USD","displayString":"$3.50","decimalPlaces":2,"sign":true,"symbol":"$"},"consumerCredits":{"unitAmount":0,"currency":"USD","displayString":"$0.00","decimalPlaces":2,"sign":true,"symbol":"$"},"consumerCharge":{"unitAmount":0,"currency":"USD","displayString":"$0.00","decimalPlaces":2,"sign":true,"symbol":"$"},"storeCharge":{"unitAmount":225,"currency":"USD","displayString":"$2.25","decimalPlaces":2,"sign":true,"symbol":"$"},"paymentAction":"PENDING_REFUND_UPON_CAPTURE","storeRefund":{"unitAmount":0,"currency":"USD","displayString":"$0.00","decimalPlaces":2,"sign":true,"symbol":"$"}}],"activeDate":"2021-01-14T17:08:53.942Z","address":{},"isDeliveryCurrent":true},"requestingInfo":"Delivery"}],"salesforceAudienceInfoBulkResponseErrors":[]}';
    
    public static void allowDuplicates() {
        //this will only allow you to bypass Alert type duplicate rules
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true; 
    }
    
    public static Account createAccount(String name) {
        return createAccount(name, false, false);
    }
    
    public static Account createAccount(String name, boolean detailed) {
        return createAccount(name, detailed, false);
    }
    
    public static Account createFormstackAccount(String name) {
        return createAccount(name, true, true);
    }
    
    public static Account createAccount(String name, boolean detailed, boolean formstack) {
        allowDuplicates();
        if (!detailed) {
            return new Account(Name = name);
        } 
        Account acct = new Account(
            Name = name, 
            BillingStreet = '123 Mulberry Ln',
            BillingCity = 'South San Francisco',
            BillingState = 'CA',
            BillingPostalCode = '94108', 
            Phone = '(800) 555-1238',
            //Market_Area__c = 'Northern California - San Francisco',
            L30_Total_Sales__c = 50
        );
        if (formstack) {
            acct.Formstack_Mobile_Phone__c = '(800) 555-1238';
            acct.Formstack_Email__c = 'test@thisisfake.com';
            acct.Account_Type__c = 'Auto-Onboard';
        }
        return acct;
    }
    
    public static Account createPersonAccount(String firstName, String lastName) {
        allowDuplicates();
        return new Account(FirstName = firstName, LastName = lastName);
    }
    
    public static Lead createLead(String fname, String lname) {
        return createLead(fname, lname, false);
    }
    
    public static Lead createLead(String fname, String lname, boolean bypassValidation) {
        allowDuplicates(); 
        Lead ld = new Lead(
            FirstName = fname, 
            LastName = lname,
            Street = '123 Mulberry Ln',
            City = 'South San Francisco',
            State = 'CA',
            PostalCode = '94108', 
            Phone = '(800) 555-1238',
            Email = 'test@thisisfake.com'
        );
        if (bypassValidation) {
            ld.Validation_Bypass__c = true;
        }
        return ld;
    }
    
    public static Opportunity createOpportunity(String name, Account acct) {
        return createOpportunity(name, acct, 'Contacted', 'Pipeline', null);    
    }
    
    public static Opportunity createClosedWonOpportunity(String name, Account acct, Contact dm) {
        return createOpportunity(name, acct, 'Closed Won', 'Closed', dm);    
    }
    
    public static Opportunity createOpportunity(String name, Account acct, String stage, String forecastCat, Contact dm) {
        allowDuplicates();
        RecordType rt = [SELECT Id FROM RecordType WHERE Name ='Marketplace' AND sObjectType = 'Opportunity'];
        Opportunity opp = new Opportunity(
            Name = name, 
            AccountId = acct.Id,
            RecordTypeId = rt.Id, 
            StageName = stage,
            ForecastCategoryName = forecastCat, 
            CloseDate = Date.today(), 
            Region_Type__c = 'Live Region',
            Platform__c = 'DoorDash'
        );
        if (stage.equals('Closed Won')) {
            opp.LeadSource = 'Other';
            opp.Average_of_Catering_Orders_per_Week__c = 5;
            opp.Mx_Requesting_Photoshoot__c = 'No';
            opp.Decision_Maker__c = dm.Id;
            opp.Type = 'New Partner (Create Menu + Nimda)';
            opp.Service_Fee__c = 10.00;
            opp.Contract_Signed_Date__c = date.today();
            opp.Pricing_Tier__c = 'Tier 3';
            opp.Activate_Centrally_2__c = 'Yes';
            opp.Menu_Has_Been_Provided__c = true;
            opp.Menu_URL__c = 'http://fakemenus.com/thisshouldntexist';
            opp.Hours_of_Operation__c = 'test';
            opp.Send_Email_Alerts__c = true;
            opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
            opp.Tablet_Delivery_Method__c = 'Drop-ship';
            opp.Shipping__c = 'Standard';
            opp.Weekly_Tablet_Subscription_Fee__c = '$0';
            opp.Account_Number__c = '000123456789';
            opp.Routing_Number__c = '021000021';
            opp.EIN__c = '011234567';
            opp.Legal_Business_Name__c = 'Business Name';
            opp.Region_Type__c = 'Live Region';
            opp.Order_Service_Type__c = 'Delivery Only';
            opp.Interest_Website_Button__c = 'No';
            opp.Is_exempt_from_Tablet_Fee__c = true;
            opp.Commission__c = 0.2;
            opp.PactSafe_Record__c = 'https://app.pactsafe.com/requests/5d6564c4f964b579a6176fe1';
            opp.PactSafe_Contract_Type__c = 'English US Mx Sign Up Sheet';
            opp.of_Addressable_Locations__c = 10;
        }
        // TODO Fix this later
        opp.OwnerId = UserInfo.getUserId();
        return opp;
    }
    
    public static Contact createContact(String firstName, String lastName, Account acct) {
        CDdContactTriggerHelper.insertCampaign();
        allowDuplicates();
        return new Contact (
            FirstName = firstName,
            LastName = lastName, 
            AccountId = acct.Id, 
            Email = 'abc@thisisfake.com',
            Birthdate = Date.newInstance(1991, 9, 29)
        );
    }
    
    public static vCS__c createVeltigSettings() {
        allowDuplicates();
        insert createTCPSettings();

        Account acc = createAccount('DoorDash HQ Account', true);
        acc.Phone = '(800) 535-5698';
        acc.BillingStreet = '854 Mulberry Ln';
        insert acc;
        
        Entitlement ent = new Entitlement(AccountId = acc.Id, Name='Test');
        insert ent;
        
        vCS__c res = new VCS__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            LiveChatTranscriptEventObj__c = true,
            DasherPAUpsert__c = true,
            CreateCaseRecord__c = true,
            CaseObjectSendToDispatch__c = true,
            DispatchEndpointPrefix__c = 'https://api.doordash.com/v2/deliveries/',
            CaseRecordType__c = '0121a0000006Qog',
            CaseAPIRecordType__c = '0121a0000006Qoq',
            DispatchRetries__c = 3,
            DispatchToken__c = 'test',
            DispatchCaseUpdateEndpoint__c = 'https://api.doordash.com/v1/support_salesforce_case_records',
            MerchantUpsert__c = true,
            AvailablePresenceStatusId__c = '0N51a000000GnU9',
            CasePopulateContact__c = true,
            CustomerPAUpsert__c = true,
            DeliveryUpsert__c = true,
            DispatchCallout__c = true,
            DispatchEndpointSuffix__c = '/salesforce_info',
            CaseDefaultBusinessHours__c = '01m1a000000Hru1',
            DispatchCaseUpdateRetries__c = 3,
            MerchantAccountRecordType__c = '0121a000000Qg1V',
            CasePopulatePersonAccount__c = true,
            DoorDashHQAccountId__c = acc.Id,
            CaseTrigger__c = true,
            APICaseCallOutAtInsert__c = true,
            DoorstepEndpointPrefix__c = 'https://api.doordash.com'
        );
        
        return res;
    }

    public static Dispatch_Settings__c createDispatchSettings() {
        allowDuplicates();
        insert createTCPSettings();
        
        Dispatch_Settings__c res = new Dispatch_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            API_Case_Callout_At_Insert__c = false,
            Case_API_Record_Type_ID__c = '0121a0000006Qoq',
            Case_Object_Send_To_Dispatch__c	 = true,
            Case_Record_Type_ID__c = '0121a0000006Qog',	
            Caviar_Case_Record_Type_ID__c = '0122L000000sc46',	
            Caviar_Deployment_IDs__c = '5722L000000k9bNQAQ;5726C000000Kz15QAC',
            Caviar_Diner_Chat_Button_ID__c = '5732L000000blJOQAY',
            Caviar_Diner_Web_Chat_Button_ID__c = '5732L000000blJO',
            Disabled__c = false,
            Dispatch_Case_Update_Endpoint__c  = 'https://api.doordash.com/v1/support_salesforce_case_records',
            Dispatch_ID_Endpoint_Prefix__c = 'https://api.doordash.com/v2/deliveries/',	
            Dispatch_ID_Endpoint_Suffix__c = '/salesforce_info/',	
            Dispatch_Token__c = 'Bearer',
            Dispatch_Token_Prefix__c = 'test',
            Dispatch_UUID_Endpoint_Prefix__c = 'https://api.doordash.com/v4/deliveries/',
            Dispatch_UUID_Endpoint_Suffix__c = '/salesforce_info/',
            Fire_On_Omni_Events__c = true,
            Get_From_Dispatch_Retries__c = 3,
            Send_To_Dispatch_Retries__c = 3,
            Use_UUID__c = false,
            Create_Case_Record__c = true,
            Customer_PA_Upsert__c = true,
            Dasher_PA_Upsert__c = true,
            Delivery_Upsert__c = true,
            Merchant_Account_Record_Type_ID__c = '0121a000000Qg1V',
            Merchant_Upsert__c = true,
            Case_Default_Business_Hours__c = '01m1a000000Hru1'
        );
        
        return res;
    }
    
    public static Trigger_Control_Panel__c createTCPSettings() {
        allowDuplicates();
        Trigger_Control_Panel__c res = new Trigger_Control_Panel__c(
            Name = 'Control Panel',
            Account_Trigger_Enabled__c = false,
            Opportunity_Trigger_Enabled__c = false
        );
        
        return res;
    }
    
    public static Case createCase() {
        allowDuplicates();
        Case res = new Case(
            Subject = 'Test',
            Description = 'Test',
            DeliveryNo__c = -100,
            DeliveryUUID__c = '-100',
            Origin = 'Chat'
        );
        
        return res;
    }
    
    public static LiveChatTranscript createTranscript() {
        allowDuplicates();
        LiveChatVisitor v = new LiveChatVisitor();
        insert v;
        
        return new LiveChatTranscript(
            LiveChatVisitorId = v.Id,
            ChatKey = 'Test'
        );
    }
    
    public static User createSupervisorUserHierarchy() {
        allowDuplicates();
        ID profileId = [select Id from Profile where Id = :UserInfo.getProfileId()].Id;
        
        User supervisorUser = createUser('supervisor12315555555555555@test.com', '1', [select Id from UserRole where DeveloperName = 'Belfast_Supervisor'].Id, profileId);
        insert supervisorUser;
        
        User agentUser = createUser('agen51241241441211111t@test.com', '2', [select Id from UserRole where DeveloperName = 'Belfast_Agent'].Id, profileId);
        agentUser.ManagerId = supervisorUser.Id;
        
        insert agentUser;
        
        return supervisorUser;
    }
    
    public static User createUser(String username, String uniqId, ID userRoleId, ID profileId) {
        allowDuplicates();
        return new User(
            FirstName = 'Test', LastName = 'User', Email=username, Alias='test',
            CommunityNickname='testnic2313081'+uniqId, TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = profileId, Username=username, UserRoleId = userRoleId
        );
    }
    
    public class TestException extends Exception {}
}