/*
 * @author:         Jeegar
 * @date:           2019-08
 * @description:    Opportunity factory for test classes. 
 * 
 * Change history
 * - 03/17/2021 Shiva Pochamalla - Changes made for BZAP-9690 so validation rule doesn't fail
 * 
 */
public with sharing class TDdOpportunityFactory {
    
    //The Opportunity record types that are enabled for POS Integration Type
    public static final Set<Id> POS_INTEGRATION_TYPE_ENABLED_OPP_RECORD_TYPES = new Set<Id>{
        CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId(),
        CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId(),
        CDdSchemaUtils.OPPORTUNITY_RT.postSaleId()
    };

    public static Opportunity createOpportunity(String name, Id accountId, Id contactId, String stageName, RecordType rt) {
        return createOpportunity(name, accountId, contactId, stageName, 'Pipeline', UserInfo.getUserId(), rt);
    }

    public static Opportunity createOpportunity(String name, Id accountId, Id contactId, String stageName) {
        return createOpportunity(name, accountId, contactId, stageName, 'Pipeline', UserInfo.getUserId());
    }

    public static Opportunity createOpportunity(String name, Id accountId, Id contactId, String stageName, Id ownerId) {
        return createOpportunity(name, accountId, contactId, stageName, 'Pipeline', ownerId);
    }

    public static Opportunity createOpportunity(String name, Id accountId, Id contactId, String stageName, String forecastCat) {
        return createOpportunity(name, accountId, contactId, stageName, stageName, UserInfo.getUserId());
    }

    public static Opportunity createOpportunity(String name, Id accountId, Id contactId, String stageName,  String forecastCat, Id ownerId) {
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE Name ='Marketplace' AND sObjectType = 'Opportunity'];
        return createOpportunity(name, accountId, contactId, stageName, forecastCat, ownerId, rt);
    }

    public static Opportunity createOpportunity(String name, Id accountId, Id contactId, String stageName,  String forecastCat, Id ownerId, RecordType rt) {
        Opportunity opp = new Opportunity(
            Name = name, 
            AccountId = accountId,
            RecordTypeId = rt.Id, 
            StageName = stageName,
            ForecastCategoryName = forecastCat, 
            CloseDate = Date.today(), 
            Region_Type__c = 'Live Region'
        );
        
        if(StageName=='Closed Won'){
            
            opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
            
        }
        opp.Name_for_Stripe_Connected_Account__c = 'testopp';
        opp.DOB_for_Stripe_Connected_Account__c = System.today().addyears(-15);
        opp.Account_Number__c = '000123456789';
        opp.Activate_Centrally_2__c = 'Yes';
        opp.Activation_Fee__c = '$0';
        opp.Average_of_Catering_Orders_per_Week__c = 5;
        opp.Commission__c = 0.2;
        opp.Contract_Signed_Date__c = date.today();
        opp.DM_Email2__c = 'test@test.com';
        opp.Stripe_Account_Owner__c = contactId;
        opp.Decision_Maker__c = contactId;
        opp.EIN__c = '011234567';
        opp.Hours_of_Operation__c = 'test';
        opp.Interest_Website_Button__c = 'No';
        opp.Is_exempt_from_Tablet_Fee__c = true;
        opp.LeadSource = 'Other';
        opp.Legal_Business_Name__c = 'Business Name';
        opp.Legal_Entity__c = 'US';
        opp.Length_of_Trial__c = '30 days';
        opp.Menu_Has_Been_Provided__c = true;
        opp.Menu_URL__c = 'http://fakemenus.com/thisshouldntexist';
        opp.Merchant_Agreed_to__c = 'No';
        opp.No_Pickup_Reason__c = 'Pricing';
        opp.Mx_Requesting_Photoshoot__c = 'No';
        opp.Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)';
        opp.Order_Service_Type__c = 'Delivery Only';
        opp.OwnerId = ownerId;
        opp.POS_Fallback_Protocol__c = 'Cancel';
        opp.POS_Integration_ID__c = '1232456';
        opp.PactSafe_Contract_Type__c = 'US English MSA Paper Agreement';
        opp.PactSafe_Record__c = 'https://app.pactsafe.com/PacksafeURL';
        opp.Platform__c = 'DoorDash';
        opp.Pricing_Tier__c = 'Tier 3';
        opp.Region_Type__c = 'Live Region';
        opp.Requesting_Account_Management__c = 'Unmanaged';
        opp.Routing_Number__c = '021000021';
        opp.Send_Email_Alerts__c = true;
        opp.Service_Fee__c = 10.00;
        opp.Shipping__c = 'Standard';
        opp.Tablet_Delivery_Method__c = 'Drop-ship';
        opp.Tablet_Kit_Type__c = 'Standard';
        opp.Trial_Commission__c = 0.0;
        opp.Trial_Type__c = 'Promotional Period';
        opp.Type = 'New Partner (Create Menu + Nimda)';
        opp.Weekly_Printer_Subscription_Fee__c = '$0';
        opp.Weekly_Tablet_Subscription_Fee__c = '$0';
        opp.of_Addressable_Locations__c = 1;

        // BZAP-17551
        if(POS_INTEGRATION_TYPE_ENABLED_OPP_RECORD_TYPES.contains(rt.Id)) {
            opp.POS_Integration_Type__c = 'crisp';
        }

        return opp;
    }

    public static Opportunity createPostSaleOpportunity(String name, Id accountId, String stageName) {
        RecordType rt = [SELECT Id FROM RecordType WHERE Name ='Post Sale' AND sObjectType = 'Opportunity'];
        Opportunity opp = new Opportunity(
            Name = name,
            AccountId = accountId,
            RecordTypeId = rt.Id,
            StageName = stageName,
            CloseDate = Date.today(),
            Type = 'In-Store Marketing',
            Restaurant_Website__c  ='http://www.google.com',
            Legal_Entity__c = 'US',
            Menu_to_be_completed_by__c = 'DoorDash Onboarding Team',
            Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source'
        );

        return opp;
    }

    /*
    * @author Knick
    * @Date Mar 2020
    * @Description: Create Opportunity based on Record Type
    */
    public static Opportunity createOpportunityByDevRT(String name, Id accountId, Id contactId, String stageName, String rtName) {
        Id rtId = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Opportunity', rtName);
        
        /*
        * @author Ila Maheshwari
        * @Date 25 Aug 2021
        * @ticket BASD-12171
        * @deploywent issue fixed
        */
        if(rtName == 'Enterprise_Marketplace'){
            Account acc = new Account();
            acc.Id = accountId;
            acc.Deck_Rank__c = 'Ace of Spades';
            
            update acc; 
        }
        
        Opportunity opp = new Opportunity(Name = name, AccountId = accountId, ContactId = contactId, StageName = stageName, RecordTypeId = rtId);
        // Initialize the common data
        opp.CloseDate = System.Date.today();
        // Initialize the variant data
        switch on rtName {
            when 'DoorDash_Drive' {
                opp.Accepts_Tips__c = 'Yes';
                opp.Decision_Maker__c = contactId;
                opp.Drive_Type__c = 'Route-Based';
                opp.Integration__c = 'No';
                // opp.Menu_Setup_Method__c = 'Clone Existing Menu(s)';
                opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
                opp.Nimda_Setup_Required__c = 'Yes';
                opp.Payment_Protocol__c = 'Credit Card';
                opp.Tablet_Delivery_Method__c = 'Drop-ship';
                opp.Tablet_Kit_Type__c = 'Standard';
                opp.Third_Party_Fulfillment__c = 'No';
                opp.Type = 'Drive';
            }
            when 'Enterprise_Drive' {
                opp.Bulk_Activation__c = false;
                opp.Third_Party_Fulfillment__c = 'No';
            }
            when 'Enterprise_Marketplace', 'ML_Inside_Sales' {
                // opp.Menu_Setup_Method__c = 'Clone Existing Menu(s)';
                opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
                opp.Mx_Marketing_Request_created__c = false;
                opp.of_Addressable_Locations__c = 1;
                opp.PactSafe_Contract_Type__c = 'US English MSA Paper Agreement';
                opp.PactSafe_Record__c = 'https://app.pactsafe.com/PacksafeURL';
                opp.Region_Type__c = 'Live Region';
                opp.Tablet_Delivery_Method__c = 'Drop-ship';
                opp.Tablet_Kit_Type__c = 'Standard';
                opp.Type = 'New Partner';
                
            }
            when 'DoorDash_for_Business' {
                opp.PactSafe_Contract_Type__c = 'English Paper Work Addendum';
                opp.StageName = 'Qualification';
            }            
            when else {
                
            }
        }

        switch on opp.StageName {
            when 'Ready for Signature' {
                opp.Legal_Entity__c = 'US';
            }
            when 'Closed Won' {
                opp.Activate_Centrally_2__c = 'Yes';
                opp.Commission__c = 0.2;
                opp.Decision_Maker__c = contactId;
                opp.Hours_of_Operation__c = 'test';
                opp.Legal_Entity__c = 'US';
                opp.Menu_Has_Been_Provided__c = true; // "Menu Isn't Blurry & Contains Pricing"
                opp.Menu_URL__c = 'https://test.doordas.com/menu_url';
                opp.Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)';
                opp.Proposed_Date_of_Activation__c = System.today().addDays(20);
                opp.Proposed_Date_of_Menu__c = System.today().addDays(10);
                opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
                opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
            }
        }

        return opp;
    }
    
    public static List<OpportunityLineItem> createOppProducts(Id oppId){
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>(); 
        OpportunityLineItem oppLineItem;
        List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id, 
                                                        Product2Id, ProductCode, UnitPrice, UseStandardPrice 
                                                    FROM PricebookEntry
                                                    WHERE IsActive = true 
                                                        AND IsArchived = false];
        
        for(PriceBookEntry pbEntry : priceBookEntries ) {
            oppLineItem = new OpportunityLineItem(); 
            oppLineItem.OpportunityId = oppId;
            oppLineItem.PricebookEntryId = pbEntry.Id; 
            oppLineItem.Product2Id = pbEntry.Product2Id; 
            oppLineItem.Quantity = 1; 
            oppLineItem.UnitPrice = 1; 
            oppLineItems.add(oppLineItem); 
        }
        return oppLineItems; 
    }

    public static List<PriceBookEntry> createPriceBookEntries(Integer count) {
        List<Product2> products = new List<Product2>(); 
        List<PricebookEntry> standardPrices = new List<PricebookEntry>(); 
        Product2 prod;
        PricebookEntry standardPrice;
        for(Integer i = 1; i <= count; i++){
             prod = new Product2(Name = 'Laptop X200'+i, Family = 'Hardware');
             products.add(prod);
        }
        insert products;
        Id pricebookId = Test.getStandardPricebookId();

        for(Product2 currProd : products) {
            standardPrice = new PricebookEntry(
                Pricebook2Id = pricebookId, Product2Id = currProd.Id,
                UnitPrice = 10000, IsActive = true);
            standardPrices.add(standardPrice);

        } 
        insert standardPrices;
        return standardPrices;
    }
    public static Opportunity_Inversion_Settings__c setCustomSettings() {
        Opportunity_Inversion_Settings__c settings = Opportunity_Inversion_Settings__c.getOrgDefaults(); 
        settings.Opportunity_RT_Ids__c = '\'0121a000000QpnMAAS\'';
        settings.Reopened_Reason__c = 'Cool Down';
        settings.New_Lead_RecordType__c = 'Master Lead';
        settings.New_Lead_Status__c = 'Untouched';
        settings.New_Lead_Owner__c = '00G1a000001Om36EAC';
        settings.Inversion_Lead_Reopened_Reason__c = 'Expired';
        settings.Never_Went_Live_Reopened_Reason__c = 'Never Went Live';
        settings.New_Lead_Auto_Onboard_Valuee__c = 'Inside Sales';
        settings.Lead_RT_Ids__c = '\'0121a000000eKznAAE\'';
        settings.Lead_Status__c = '\'Not Interested - Cool Down\'';
        settings.Reopened_Lead_Owner__c = '0051a000002oztaAAA' ;
        settings.Profile_Id__c = '00e1a000000Rf6CAAS';
        settings.SI_Inversion_Opp_Lost_Reason__c = '\'SI Strategic Inversion\'';
        settings.SI_Inversion_Lead_Reopen_Reason__c = 'SI Strategic Inversion';
        upsert settings;

        return settings;
    }
}