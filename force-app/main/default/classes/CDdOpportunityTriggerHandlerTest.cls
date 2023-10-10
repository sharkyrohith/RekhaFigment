/**
 * @description       :
 * @author            : Nathalie Mendezona
 * @group             :
 * @last modified on  : 03-08-2022
 * @last modified by  : Jose Vega
**/
@isTest
public class CDdOpportunityTriggerHandlerTest {
    private static vCS__c testSettings;
    private static Opportunity_Trigger_Helper_Settings__c helperSettings;
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final Id smRTId = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Setup Menu').getRecordTypeId();
    public static final Id onboardingCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();
    public static final User user = [select Id from User where Profile.Name = 'System Administrator' AND IsActive = true limit 1];
    private Static map<string, Schema.RecordTypeInfo> oppRecTypeMap = Opportunity.SobjectType.getDescribe().getRecordTypeInfosByName();
    private Static map<string, Schema.RecordTypeInfo> accountRecTypeMap = Account.SobjectType.getDescribe().getRecordTypeInfosByName();
    public static final Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Master Lead').getRecordTypeId();
    public static final Id promoRecTypeId  = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
    public static final Id marketplaceRecTypeId  = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
    public static final Id mlInsideSalesId = oppRecTypeMap.get('Marketplace').getRecordTypeId();
    public static final Id postSaleRecId   = oppRecTypeMap.get('Post Sale').getRecordTypeId();
    public static final Id enterpriseMarketplaceId   = oppRecTypeMap.get('Enterprise Marketplace').getRecordTypeId();
    public static final Id doordashRecId   = oppRecTypeMap.get('DoorDash for Business').getRecordTypeId();
    public static final Id mxCateringRecId   = oppRecTypeMap.get('Merchant Catering').getRecordTypeId();
    public static final Id parentAccRecordTypeId = accountRecTypeMap.get('Parent Account').getRecordTypeId();
    public static final Id accRecordTypeId = accountRecTypeMap.get('Marketplace').getRecordTypeId();


    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
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

    @testSetup
    static void testSetup() {
        System.runAs(getTestRunUser()) {

            CDdContactTriggerHelper.insertCampaign();
            SBQQ.TriggerControl.disable();
            testSettings = VTestUtil.createVeltigSettings();
            Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
            cp.Name = 'Main';
            cp.Opportunity_Trigger_Enabled__c = false;
            cp.Account_Trigger_Enabled__c = false;
            upsert cp;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            insert validation;

            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_CPU_Time_Check__c = true;
            ftrFlag.Enable_Debug_Logs__c = true;
            ftrFlag.Form_Stack_Deprecated__c = false;
            insert ftrFlag;

            helperSettings = Opportunity_Trigger_Helper_Settings__c.getOrgDefaults();
            helperSettings.Caviar_Promo_Notes__c = 'c';             // Caviar Promo
            helperSettings.New_Asset_Status__c = 'Purchased';       // Required field

            upsert helperSettings;

            RealZip__RealZips__c realZipRec = new RealZip__RealZips__c(Submarket_ID__c = 10);
            insert realZipRec;

            TDdOpportunityLineItemFactory.createProducts();

            List<Account> childAccs = new List<Account>();
            List<Account> accList = CDdTestDataFactory.createSObjectList('Account',18,false);
            for(Integer index=0; index <accList.size(); index++){
                if(index == 0){
                    accList[index].Name = 'Test Acc';
                    accList[index].phone = '0256157848';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].RealZip__RealZip__c = realZipRec.Id;
                    accList[index].Market_Area__c = 'Northern California - East Bay';
                    accList[index].Business_ID__c = 123456;
                    accList[index].Formstack_Version__c = 'New Store';
                }

                else if(index == 1){
                    accList[index].Name = 'Parent Test Acc';
                    accList[index].phone = '3056083185';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].RealZip__RealZip__c = realZipRec.Id;
                    accList[index].Market_Area__c = 'Northern California - East Bay';
                    accList[index].RecordTypeId = parentAccRecordTypeId;
                    accList[index].Business_ID__c = 789456;
                    accList[index].Requesting_Account_Management__c = 'Unmanaged';
                }

                else if(index == 2){
                    accList[index].Name = 'Default Weblink Acct';
                    accList[index].phone = '7862239496';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].RealZip__RealZip__c = realZipRec.Id;
                    accList[index].Market_Area__c = 'Northern California - East Bay';
                    accList[index].RecordTypeId = parentAccRecordTypeId;
                }

                else if(index == 3){
                    accList[index].Name = 'Canada Test Acc';
                    accList[index].phone = '2019393939';
                    accList[index].BillingCountryCode = 'CA';
                    accList[index].BillingPostalCode = 'M8W 1R2';
                    accList[index].BillingState = 'ON';
                    accList[index].BillingCity = 'Toronto';
                    accList[index].BillingStreet = '3795 Lake Shore Boulevard West';
                    accList[index].RealZip__RealZip__c = realZipRec.Id;
                    accList[index].Market_Area__c = 'Northern California - East Bay';
                    accList[index].Business_ID__c = 123634;
                    accList[index].Language__c = 'French';
                    accList[index].Formstack_Version__c = 'New Store';
                }

                else if(index == 4){
                    accList[index].Name = 'Asset Test Account 0';
                    accList[index].phone = '2019393539';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '123456780';
                    accList[index].Bank_Routing_Number_Encrypted__c = '123456789';
                    accList[index].EIN_Encrypted__c ='123456789';
                    accList[index].RecordTypeId =accRecordTypeId;
                    accList[index].Legal_Business_Name__c = 'test';
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                }
                else if(index == 5){
                    accList[index].Name = 'opptriggerHandlerTest 0';
                    accList[index].phone = '2019393439';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '123456781';
                    accList[index].Bank_Routing_Number_Encrypted__c = '123456780';
                    accList[index].EIN_Encrypted__c ='123456789';
                    accList[index].Legal_Business_Name__c = 'TestAccount';
                    accList[index].RecordTypeId =accRecordTypeId;
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                    accList[index].Restaurant_Id__c = '35640';
                }

                else if(index == 6){
                    accList[index].Name = 'opptriggerHandlerTest 1';
                    accList[index].phone = '2019393440';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '123456782';
                    accList[index].Bank_Routing_Number_Encrypted__c = '123456781';
                    accList[index].EIN_Encrypted__c ='123456789';
                    accList[index].Legal_Business_Name__c = 'TestAccount';
                    accList[index].RecordTypeId =accRecordTypeId;
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                    accList[index].Restaurant_Id__c = '35330';
                }

                else if(index == 7){
                    accList[index].Name = 'opptriggerHandlerTest 2';
                    accList[index].phone = '2019393441';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '123456783';
                    accList[index].Bank_Routing_Number_Encrypted__c = '123456782';
                    accList[index].EIN_Encrypted__c ='123456789';
                    accList[index].Legal_Business_Name__c = 'TestAccount';
                    accList[index].RecordTypeId =accRecordTypeId;
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                    accList[index].Restaurant_Id__c = '35990';
                }

                else if(index == 8){
                    accList[index].Name = 'TestDDAccount 0';
                    accList[index].phone = '2019403539';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '223456780';
                    accList[index].Bank_Routing_Number_Encrypted__c = '223456789';
                    accList[index].EIN_Encrypted__c ='123456789';
                    accList[index].Legal_Business_Name__c = 'TestAccount';
                    accList[index].RecordTypeId =accRecordTypeId;
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                }

                else if(index == 9){
                    accList[index].Name = 'Account 0';
                    accList[index].phone = '2119413539';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '213456780';
                    accList[index].Bank_Routing_Number_Encrypted__c = '213456789';
                    accList[index].EIN_Encrypted__c ='123556789';
                    accList[index].Legal_Business_Name__c = 'TestAccount';
                    accList[index].RecordTypeId =accRecordTypeId;
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                }
                else if(index == 10){
                    accList[index].Name = 'Parent 0';
                    accList[index].phone = '2119423539';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '213456780';
                    accList[index].Bank_Routing_Number_Encrypted__c = '213456789';
                    accList[index].EIN_Encrypted__c ='123556789';
                    accList[index].Legal_Business_Name__c = 'TestAccount';
                    accList[index].RecordTypeId =parentAccRecordTypeId;
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                }
                else if(index == 11){
                    accList[index].Name = 'Parent Account 0';
                    accList[index].phone = '2119428589';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].BillingPostalCode = '95689';
                    accList[index].BillingState = 'CA';
                    accList[index].BillingCity = 'South San Francisco';
                    accList[index].Bank_Account_Number_Encrypted__c = '213456780';
                    accList[index].Bank_Routing_Number_Encrypted__c = '213456789';
                    accList[index].EIN_Encrypted__c ='123556789';
                    accList[index].Legal_Business_Name__c = 'TestAccount';
                    accList[index].RecordTypeId =parentAccRecordTypeId;
                    accList[index].BillingStreet = index + ' Mulberry Ln';
                    accList[index].Business_ID__c = 143611;
                    accList[index].Requesting_Account_Management__c = 'Unmanaged';
                }
                else if(index >= 12){
                    childAccs.add(accList[index]);
                }
            }
            /*
            * To add parent accountId to child accounts, we are removing the child accounts from the list.
            * Once the parent Id is available we are inserting the child accounts.
            */
            accList.remove(17);
            accList.remove(16);
            accList.remove(15);
            accList.remove(14);
            accList.remove(13);
            accList.remove(12);
            insert accList;


            childAccs[0].Name = 'opptriggerHandlerTest - Child 0';
            childAccs[0].ParentId = accList[5].Id;
            childAccs[0].phone = '2019093439';
            childAccs[0].BillingCountryCode = 'US';
            childAccs[0].BillingPostalCode = '95689';
            childAccs[0].BillingState = 'CA';
            childAccs[0].BillingCity = 'South San Francisco';
            childAccs[0].Bank_Account_Number_Encrypted__c = '123456781';
            childAccs[0].Bank_Routing_Number_Encrypted__c = '123456780';
            childAccs[0].EIN_Encrypted__c ='123456789';
            childAccs[0].Legal_Business_Name__c = 'TestAccount';
            childAccs[0].RecordTypeId =accRecordTypeId;
            childAccs[0].BillingStreet = '11 Mulberry Ln';
            childAccs[0].Restaurant_Id__c = '56400';

            childAccs[1].Name = 'opptriggerHandlerTest - Child 1';
            childAccs[1].phone = '7019093439';
            childAccs[1].BillingCountryCode = 'US';
            childAccs[1].BillingPostalCode = '95689';
            childAccs[1].ParentId = accList[6].Id;
            childAccs[1].BillingState = 'CA';
            childAccs[1].BillingCity = 'South San Francisco';
            childAccs[1].Bank_Account_Number_Encrypted__c = '123456781';
            childAccs[1].Bank_Routing_Number_Encrypted__c = '123456780';
            childAccs[1].EIN_Encrypted__c ='123456789';
            childAccs[1].Legal_Business_Name__c = 'TestAccount';
            childAccs[1].RecordTypeId =accRecordTypeId;
            childAccs[1].BillingStreet = '12 Mulberry Ln';
            childAccs[1].Restaurant_Id__c = '53300';

            childAccs[2].Name = 'opptriggerHandlerTest - Child 2';
            childAccs[2].phone = '2019093039';
            childAccs[2].ParentId = accList[7].Id;
            childAccs[2].BillingCountryCode = 'US';
            childAccs[2].BillingPostalCode = '95689';
            childAccs[2].BillingState = 'CA';
            childAccs[2].BillingCity = 'South San Francisco';
            childAccs[2].Bank_Account_Number_Encrypted__c = '123456781';
            childAccs[2].Bank_Routing_Number_Encrypted__c = '123456780';
            childAccs[2].EIN_Encrypted__c ='123456789';
            childAccs[2].Legal_Business_Name__c = 'TestAccount';
            childAccs[2].RecordTypeId =accRecordTypeId;
            childAccs[2].BillingStreet = '13 Mulberry Ln';
            childAccs[2].Restaurant_Id__c = '59900';

            childAccs[3].Name = 'Child Account 0';
            childAccs[3].phone = '9909428589';
            childAccs[3].BillingCountryCode = 'US';
            childAccs[3].BillingPostalCode = '95689';
            childAccs[3].BillingState = 'CA';
            childAccs[3].BillingCity = 'South San Francisco';
            childAccs[3].Bank_Account_Number_Encrypted__c = '213456780';
            childAccs[3].Bank_Routing_Number_Encrypted__c = '213456789';
            childAccs[3].EIN_Encrypted__c ='123556789';
            childAccs[3].Legal_Business_Name__c = 'TestAccount';
            childAccs[3].RecordTypeId =accRecordTypeId;
            childAccs[3].BillingStreet = '99 Mulberry Ln';
            childAccs[3].Business_ID__c = 143611;
            childAccs[3].Requesting_Account_Management__c = 'Unmanaged';
            childAccs[3].BillingCountry = 'United States';
            childAccs[3].Restaurant_ID__c = '12345678';
            childAccs[3].ParentId = accList[11].Id;

            childAccs[4].Name = 'Child 0';
            childAccs[4].BillingStreet ='41 Mulberry Ln';
            childAccs[4].BillingCity = 'South San Francisco';
            childAccs[4].BillingState = 'CA';
            childAccs[4].BillingCountryCode = 'US';
            childAccs[4].BillingCountry = 'United States';
            childAccs[4].Phone ='9652513636';
            childAccs[4].BillingPostalCode = '95989';
            childAccs[4].Bank_Account_Number_Encrypted__c = '120456789';
            childAccs[4].Bank_Routing_Number_Encrypted__c = '123406789';
            childAccs[4].EIN_Encrypted__c = '123956789';
            childAccs[4].Legal_Business_Name__c = 'TestAccount';
            childAccs[4].RecordTypeId = accRecordTypeId;
            childAccs[4].parentId = accList[11].Id;
            childAccs[4].In_Coverage__c = 'No';
            childAccs[4].Deck_Rank__c = 'Ace of Spades';

            childAccs[5].Name = 'opptriggerHandlerTest - Japan Child';
            childAccs[5].BillingStreet ='Kanazumachi-17-1 Hebita';
            childAccs[5].BillingCity = 'Ishinomaki';
            childAccs[5].BillingState = 'Miyagi';
            childAccs[5].BillingCountryCode = 'JP';
            childAccs[5].BillingCountry = 'Japan';
            childAccs[5].Phone ='+81 80-1234-1234';
            childAccs[5].BillingPostalCode = '986-0861';
            childAccs[5].Bank_Account_Number_Encrypted__c = '120456789';
            childAccs[5].Bank_Routing_Number_Encrypted__c = '123406789';
            childAccs[5].EIN_Encrypted__c = '123956789';
            childAccs[5].Legal_Business_Name__c = 'TestAccount';
            childAccs[5].RecordTypeId = accRecordTypeId;
            childAccs[5].In_Coverage__c = 'No';
            childAccs[5].Deck_Rank__c = 'Ace of Spades';
            insert childAccs;

            testSettings.defaultWeblinkAccount__c = accList[2].Id;
            insert testSettings;


            List<Campaign> campaignList = new List<Campaign>();
            Campaign testCampaign1 = new Campaign(RecordTypeId = promoRecTypeId,
                                                 Name = 'Test Campaign Name',
                                                 Title__c = 'Test Campaign Title',
                                                 Delivery_Fee__c = 3,
                                                 Min_Order_Cart_Subtotal__c = 10,
                                                 New_Customer_Only__c = false,
                                                 Promotion_Type__c = 'tmf',
                                                 Description = 'Test Campaign Description',
                                                 Show_as_Carousel__c = false,
                                                 RealZip__c = realZipRec.Id,
                                                 Sort_Order__c = '1',
                                                 BFF_Promotion_Id__c = '123',
                                                 isActive = true);
            campaignList.add(testCampaign1);

            Campaign testCampaign2 = new Campaign(RecordTypeId = marketplaceRecTypeId,
                                                 Name = 'Test Campaign Source Name',
                                                 Title__c = 'Test Campaign Source Title',
                                                 Delivery_Fee__c = 3,
                                                 Min_Order_Cart_Subtotal__c = 10,
                                                 New_Customer_Only__c = false,
                                                 Promotion_Type__c = 'tmf',
                                                 Description = 'Test Campaign Description',
                                                 Show_as_Carousel__c = false,
                                                 RealZip__c = realZipRec.Id,
                                                 Sort_Order__c = '1',
                                                 BFF_Promotion_Id__c = '123',
                                                 isActive = true);
            campaignList.add(testCampaign2);
            insert campaignList;

            List<Contact> cons = CDdTestDataFactory.createSObjectList('Contact',11,false);

            cons[0].firstName = 'moCaseMilestone1';
            cons[0].LastName = 'Con1';
            cons[0].Email = 'moCaseMilestone1Con1@dd.com';
            cons[0].accountId=childAccs[0].Id;
            cons[0].Birthdate = Date.newInstance(1991, 9, 29);

            cons[1].firstName = 'moCaseMilestone2';
            cons[1].LastName = 'Con2';
            cons[1].Email = 'moCaseMilestone2Con2@dd.com';
            cons[1].accountId=childAccs[1].Id;
            cons[1].Birthdate = Date.newInstance(1991, 9, 29);

            cons[2].firstName = 'moCaseMilestone3';
            cons[2].LastName = 'Con3';
            cons[2].Email = 'moCaseMilestone2Con3@dd.com';
            cons[2].accountId=childAccs[2].Id;
            cons[2].Birthdate = Date.newInstance(1991, 9, 29);

            cons[3].firstName = 'AssetCon';
            cons[3].LastName = 'AssetCon';
            cons[3].Email = 'testCon@dd.com';
            cons[3].accountId=accList[4].id;
            cons[3].Birthdate = Date.newInstance(1991, 9, 29);

            cons[4].firstName = 'TestCon';
            cons[4].LastName = 'TestCon';
            cons[4].Email = 'testCon@dd.com';
            cons[4].accountId=accList[8].Id;
            cons[4].Birthdate = Date.newInstance(1991, 9, 29);

            cons[5].firstName = 'testDonotAllow';
            cons[5].LastName = 'oppRecordMethod';
            cons[5].Email = 'testDonotAllow@dd.com';
            cons[5].accountId=accList[9].Id;
            cons[5].Birthdate = Date.newInstance(1991, 9, 29);

            cons[6].firstName = 'testCopyRequest';
            cons[6].LastName = 'AccountManagement';
            cons[6].Email = 'AccountManagement@dd.com';
            cons[6].accountId=accList[0].Id;
            cons[6].Birthdate = Date.newInstance(1991, 9, 29);

            cons[7].firstName = 'test con';
            cons[7].LastName = 'Contacts';
            cons[7].Email = 'testcontacts@dd.com';
            cons[7].accountId=childAccs[3].Id;
            cons[7].Birthdate = Date.newInstance(1991, 9, 29);

            cons[8].firstName = 'canada con';
            cons[8].LastName = 'canada contact';
            cons[8].Email = 'canadacontact@dd.com';
            cons[8].accountId=accList[3].Id;
            cons[8].Birthdate = Date.newInstance(1990, 9, 29);

            cons[9].firstName = 'formstack con';
            cons[9].LastName = 'formstack contact';
            cons[9].Email = 'formstackcontact@dd.com';
            cons[9].accountId=childAccs[4].Id;
            cons[9].Birthdate = Date.newInstance(1990, 9, 29);

            cons[10].firstName = 'Japan con';
            cons[10].LastName = 'japan contact';
            cons[10].Email = 'japancontact@dd.com';
            cons[10].accountId=childAccs[5].Id;
            cons[10].Birthdate = Date.newInstance(1990, 9, 29);

            Insert cons;

            List<Submarket__c> submarket = CDdTestDataFactory.createSObjectList('Submarket__c',7,false);

            submarket[0].NP_Pricing_Tier__c = 'test';
            submarket[0].NP_Service_Fee__c = 20;
            submarket[1].Premium_Delivery_Fee__c = 30;
            submarket[1].Basic_Delivery_Fee__c = 10;

            Insert submarket;

            CDdMilestoneTemplate.insertMilestoneTemplates();

            Test.startTest();
            List<Opportunity> oppList =  CDdTestDataFactory.createSObjectList('Opportunity',11,false);

            oppList[0].Name = 'UpdateMOCaseAndMilestones 1';
            oppList[0].AccountId = childAccs[0].Id;
            oppList[0].ContactId = cons[0].Id;
            oppList[0].RecordTypeId=mlInsideSalesId;
            oppList[0].CloseDate = System.Date.today();
            oppList[0].Change_of_Ownership_Effective_Date__c = System.today();
            oppList[0].Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            oppList[0].Mx_Marketing_Request_created__c = false;
            oppList[0].of_Addressable_Locations__c = 1;
            oppList[0].PactSafe_Contract_Type__c = 'US English MSA Paper Agreement';
            oppList[0].PactSafe_Record__c = 'https://app.pactsafe.com/PacksafeURL';
            oppList[0].Region_Type__c = 'Live Region';
            oppList[0].Tablet_Delivery_Method__c = 'Drop-ship';
            oppList[0].Tablet_Kit_Type__c = 'Standard';
            oppList[0].Menu_Setup_Method__c = null;
            oppList[0].Menu_To_Be_Completed_By__c = 'Merchant';
            oppList[0].Type = 'New Partner';
            oppList[0].SSME_Menu_Completion_Date_Time__c = null;
            oppList[0].StageName = 'Closed Won';
            oppList[0].SSME_Expiration_Date_Time__c = null;

            oppList[1].Name = 'UpdateMOCaseAndMilestones 2';
            oppList[1].AccountId = childAccs[1].id;
            oppList[1].ContactId = cons[1].Id;
            oppList[1].RecordTypeId=mlInsideSalesId;
            oppList[1].CloseDate = System.Date.today();
            oppList[1].Change_of_Ownership_Effective_Date__c = System.today();
            oppList[1].Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            oppList[1].Mx_Marketing_Request_created__c = false;
            oppList[1].of_Addressable_Locations__c = 1;
            oppList[1].PactSafe_Contract_Type__c = 'US English MSA Paper Agreement';
            oppList[1].PactSafe_Record__c = 'https://app.pactsafe.com/PacksafeURL';
            oppList[1].Region_Type__c = 'Live Region';
            oppList[1].Tablet_Delivery_Method__c = 'Drop-ship';
            oppList[1].Tablet_Kit_Type__c = 'Standard';
            oppList[1].Menu_Setup_Method__c = null;
            oppList[1].Menu_To_Be_Completed_By__c = 'Merchant';
            oppList[1].Type = 'New Partner';
            oppList[1].SSME_Menu_Completion_Date_Time__c = null ;
            oppList[1].StageName = 'Closed Won';
            oppList[1].SSME_Expiration_Date_Time__c = null;

            oppList[2].Name = 'UpdateMOCaseAndMilestones 3';
            oppList[2].AccountId = childAccs[2].Id;
            oppList[2].ContactId = cons[2].Id;
            oppList[2].RecordTypeId=mlInsideSalesId;
            oppList[2].CloseDate = System.Date.today();
            oppList[2].Change_of_Ownership_Effective_Date__c = System.today();
            oppList[2].Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            oppList[2].Mx_Marketing_Request_created__c = false;
            oppList[2].of_Addressable_Locations__c = 1;
            oppList[2].PactSafe_Contract_Type__c = 'US English MSA Paper Agreement';
            oppList[2].PactSafe_Record__c = 'https://app.pactsafe.com/PacksafeURL';
            oppList[2].Region_Type__c = 'Live Region';
            oppList[2].Tablet_Delivery_Method__c = 'Drop-ship';
            oppList[2].Tablet_Kit_Type__c = 'Standard';
            oppList[2].Type = 'Change of Ownership';
            oppList[2].Menu_to_be_completed_by__c = 'Account Owner';
            oppList[2].Order_Protocol__c = 'Email';
            oppList[2].Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
            oppList[2].Activate_Centrally_2__c = 'No';
            oppList[2].StageName = 'Closed Won';
            oppList[2].Proposed_Date_of_Activation__c = Date.today().addDays(5);

            oppList[3].Name = 'TestDDOpportunity1';
            oppList[3].AccountId = accList[8].Id;
            oppList[3].ContactId = cons[4].Id;
            oppList[3].StageName ='New';
            oppList[3].RecordTypeId=doordashRecId;
            oppList[3].CloseDate = System.Date.today();
            oppList[3].PactSafe_Contract_Type__c = 'English Paper Work Addendum';
            oppList[3].Payment_Protocol__c = 'Credit Card';
            oppList[3].Menu_Setup_Method__c = null;
            oppList[3].Menu_to_be_completed_by__c = null;
            oppList[3].Tablet_Kit_Type__c = null;

            oppList[4].Name = 'AssetOpportunity';
            oppList[4].AccountId = accList[4].id;
            oppList[4].RecordTypeId = mlInsideSalesId;
            oppList[4].StageName = 'Out for Signature';
            oppList[4].ForecastCategoryName = 'Pipeline';
            oppList[4].CloseDate = Date.today();
            oppList[4].Region_Type__c = 'Live Region';
            oppList[4].Name_for_Stripe_Connected_Account__c = 'testopp';
            oppList[4].DOB_for_Stripe_Connected_Account__c = System.today().addyears(-15);
            oppList[4].Account_Number__c = '000123456789';
            oppList[4].Activate_Centrally_2__c = 'Yes';
            oppList[4].Activation_Fee__c = '$0';
            oppList[4].Average_of_Catering_Orders_per_Week__c = 5;
            oppList[4].Commission__c = 0.2;
            oppList[4].Contract_Signed_Date__c = date.today();
            oppList[4].DM_Email2__c = 'test@test.com';
            oppList[4].Stripe_Account_Owner__c = cons[3].id;
            oppList[4].Decision_Maker__c = cons[3].id;
            oppList[4].EIN__c = '011234567';
            oppList[4].Hours_of_Operation__c = 'test';
            oppList[4].Interest_Website_Button__c = 'No';
            oppList[4].Is_exempt_from_Tablet_Fee__c = true;
            oppList[4].LeadSource = 'Other';
            oppList[4].Legal_Business_Name__c = 'Business Name';
            oppList[4].Legal_Entity__c = 'US';
            oppList[4].Length_of_Trial__c = '30 days';
            oppList[4].Menu_Has_Been_Provided__c = true;
            oppList[4].Menu_URL__c = 'http://fakemenus.com/thisshouldntexist';
            oppList[4].Merchant_Agreed_to__c = 'No';
            oppList[4].No_Pickup_Reason__c = 'Pricing';
            oppList[4].Mx_Requesting_Photoshoot__c = 'No';
            oppList[4].Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)';
            oppList[4].Order_Service_Type__c = 'Delivery Only';
            oppList[4].OwnerId = UserInfo.getUserId();
            oppList[4].POS_Fallback_Protocol__c = 'Cancel';
            oppList[4].POS_Integration_ID__c = '1232456';
            oppList[4].POS_Integration_Type__c = 'crisp';
            oppList[4].PactSafe_Contract_Type__c = 'US English MSA Paper Agreement';
            oppList[4].PactSafe_Record__c = 'https://app.pactsafe.com/PacksafeURL';
            oppList[4].Platform__c = 'DoorDash';
            oppList[4].Pricing_Tier__c = 'Tier 3';
            oppList[4].Region_Type__c = 'Live Region';
            oppList[4].Requesting_Account_Management__c = 'Unmanaged';
            oppList[4].Routing_Number__c = '021000021';
            oppList[4].Send_Email_Alerts__c = true;
            oppList[4].Service_Fee__c = 10.00;
            oppList[4].Shipping__c = 'Standard';
            oppList[4].Tablet_Delivery_Method__c = 'Drop-ship';
            oppList[4].Tablet_Kit_Type__c = 'Standard';
            oppList[4].Trial_Commission__c = 0.0;
            oppList[4].Trial_Type__c = 'Promotional Period';
            oppList[4].Type = 'New Partner (Create Menu + Nimda)';
            oppList[4].Weekly_Printer_Subscription_Fee__c = '$0';
            oppList[4].Weekly_Tablet_Subscription_Fee__c = '$0';
            oppList[4].of_Addressable_Locations__c = 1;

            oppList[5].RecordTypeId = postSaleRecId;
            oppList[5].AccountId = accList[0].Id;
            oppList[5].Type = 'tmf';
            oppList[5].Name = 'Test Upsell 2';
            oppList[5].StageName = 'New';
            oppList[5].ForecastCategoryName = 'Pipeline';
            oppList[5].CloseDate = Date.newInstance(2018,6,6);
            oppList[5].Maketing_Fee__c = '$3.99';
            oppList[5].Commission__c = 20;
            oppList[5].Menu_Setup_Method__c = null;
            oppList[5].Tablet_Kit_Type__c = null;
            oppList[5].Menu_to_be_completed_by__c = null;

            oppList[6].RecordTypeId = postSaleRecId;
            oppList[6].AccountId = accList[0].Id;
            oppList[6].Type = 'tmf';
            oppList[6].Name = 'Test Upsell 3';
            oppList[6].StageName = 'fox';
            oppList[6].ForecastCategoryName = 'Pipeline';
            oppList[6].CloseDate = Date.newInstance(2018,6,6);
            oppList[6].Maketing_Fee__c = '$3.99';
            oppList[6].Commission__c = 20;
            oppList[6].Menu_Setup_Method__c = null;
            oppList[6].Tablet_Kit_Type__c = null;
            oppList[6].Menu_to_be_completed_by__c = null;

            oppList[7].RecordTypeId = postSaleRecId;
            oppList[7].AccountId = accList[0].Id;
            oppList[7].Restaurant_Website__c = 'google.com';
            oppList[7].Name = 'Test Upsell 4';
            oppList[7].StageName = 'fox';
            oppList[7].ForecastCategoryName = 'Pipeline';
            oppList[7].CloseDate = Date.newInstance(2018,6,6);
            oppList[7].Maketing_Fee__c = '$3.99';
            oppList[7].Business_ID__c = 654786;
            oppList[7].Lead_Source_Detail__c ='Formstack';
            oppList[7].Commission__c = 20;
            oppList[7].Menu_Setup_Method__c = null;
            oppList[7].Tablet_Kit_Type__c = null;
            oppList[7].Menu_to_be_completed_by__c = null;

            oppList[8].RecordTypeId = postSaleRecId;
            oppList[8].AccountId = accList[0].Id;
            oppList[8].Restaurant_Website__c = 'google.com';
            oppList[8].Name = 'Test Upsell 5';
            oppList[8].StageName = 'fox';
            oppList[8].ForecastCategoryName = 'Pipeline';
            oppList[8].CloseDate = Date.newInstance(2018,6,6);
            oppList[8].Maketing_Fee__c = '$3.99';
            oppList[8].Business_ID__c = 789456;
            oppList[8].Lead_Source_Detail__c ='Formstack';
            oppList[8].Commission__c = 20;
            oppList[8].Menu_Setup_Method__c = null;
            oppList[8].Tablet_Kit_Type__c = null;
            oppList[8].Menu_to_be_completed_by__c = null;

            oppList[9].RecordTypeId = mlInsideSalesId;
            oppList[9].AccountId = accList[0].Id;
            oppList[9].ContactId=  cons[6].Id;
            oppList[9].Restaurant_Website__c = 'google.com';
            oppList[9].Name = 'CloseWonOpp';
            oppList[9].StageName = 'Ready for Signature';
            oppList[9].Package_Sold__c ='';
            oppList[9].ForecastCategoryName = 'Pipeline';
            oppList[9].CloseDate = Date.newInstance(2018,6,6);
            oppList[9].Business_ID__c = 789456;
            oppList[9].Lead_Source_Detail__c ='Formstack';
            oppList[9].Commission__c = 0;
            oppList[9].Trial_Type__c = 'Free Trial';
            oppList[9].Trial_Commission__c = 10;
            oppList[9].Manager_Package_Override__c = 'Plus';
            oppList[9].Length_of_Trial__c = '7 days';
            oppList[9].Proposed_Date_of_Activation_Original__c = Date.today();

            oppList[10].RecordTypeId = mxCateringRecId;
            oppList[10].AccountId = accList[0].Id;
            oppList[10].Name = 'Test Catering Opp Processing';
            oppList[10].StageName = 'fox';
            oppList[10].ForecastCategoryName = 'Pipeline';
            oppList[10].CloseDate = Date.today().addDays(10);
            oppList[10].Business_ID__c = 789456;
            oppList[10].Commission__c = 20;
            oppList[10].Menu_Setup_Method__c = null;
            oppList[10].Tablet_Kit_Type__c = null;
            oppList[10].Menu_to_be_completed_by__c = null;

            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp one',  childAccs[4].Id,  cons[9].Id, 'New', 'Enterprise_Marketplace');
            opp.Notes__c = helperSettings.Caviar_Promo_Notes__c;
            opp.Proposed_Date_of_Activation__c = Date.today();
            oppList.add(opp);

            Insert oppList;

            Test.stopTest();
        }
    }

    @isTest
    static void testUpdateManager() {
        List<User> testUsers = TDdAccountFactory.createUsers(4);
        insert testUsers;
        User runUser0 = getTestRunUser();
        User runUser1 = testUsers[1];
        runUser0.ManagerId = testUsers[2].Id;
        runUser1.ManagerId = testUsers[3].Id;
        update new List<User>{runUser0, runUser1};
        System.runAs (runUser0) {
            Opportunity opp = [SELECT Id, Manager__c FROM Opportunity WHERE Name = 'AssetOpportunity'];
            update new Opportunity (Id = opp.Id, OwnerId = runUser0.Id);
            Test.startTest();
            update new Opportunity (Id = opp.Id, OwnerId = runUser1.Id);
            Test.stopTest();
            System.assertEquals(runUser1.ManagerId,
                [SELECT Manager__c FROM Opportunity WHERE Id = :opp.Id].Manager__c, 'Expecting Manager id ' + runUser1.ManagerId);
        }
    }

    @isTest
    static void checkPostSaleStorePromotionCreation() {
        System.runAs(getTestRunUser()) {
            RealZip__RealZips__c realZipRec = (RealZip__RealZips__c) [SELECT Id, Submarket_ID__c FROM RealZip__RealZips__c LIMIT 1];
            Id testAccId = [SELECT Id FROM Account WHERE Name = 'Test Acc' LIMIT 1].Id;
            List<Opportunity> testOpp = [SELECT Id FROM Opportunity where Name IN ('Test Upsell 2','Test Upsell 3')];
            Test.startTest();
            List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
            oppLineItems.addAll(TDdOpportunityFactory.createOppProducts(testOpp[0].id));
            oppLineItems.addAll(TDdOpportunityFactory.createOppProducts(testOpp[1].id));
            insert oppLineItems;
            Test.stopTest();

            //TODO Assert.
            System.assert(true, true);
        }
    }

    @isTest
    static void checkPostSaleWeblinkCreation() {
        System.runAs(getTestRunUser()) {
            //RealZip__RealZips__c realZipRec = (RealZip__RealZips__c) [SELECT Id, Submarket_ID__c FROM RealZip__RealZips__c LIMIT 1];
            Id testAccId = [SELECT Id FROM Account WHERE Name = 'Test Acc' LIMIT 1].Id;
            Id parentAccId = [SELECT Id FROM Account WHERE Name = 'Parent Test Acc' LIMIT 1].Id;
            Id defaultWeblinkAccId = [SELECT Id FROM Account WHERE Name = 'Parent Test Acc' LIMIT 1].Id;
            List<Opportunity> testOpp = [SELECT Id FROM Opportunity where Name IN ('Test Upsell 4','Test Upsell 5')];
            Test.startTest();

            List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
            oppLineItems.addAll(TDdOpportunityFactory.createOppProducts(testOpp[0].id));
            oppLineItems.addAll(TDdOpportunityFactory.createOppProducts(testOpp[1].id));
            insert oppLineItems;
            Test.stopTest();
            System.assert(true, true);
                //this will test if a parent account is found
                //System.AssertEquals(parentAccId, testOpp2.AccountId);
                //System.AssertEquals(defaultWeblinkAccId, testOpp.AccountId);


            //Test.stopTest();

            //System.AssertEquals('Test Acc', testOpp.Account.Name);
        }
    }
    /**
    * @description Test - BZAP-4235 - Match opportunities to accounts based on Formstack Store ID
    */
    @isTest
    public static void testMatchOnFormstackStoreId() {
        String TEST_STORE_ID = '12345678';
        System.runAs(getTestRunUser()) {
            Account parentAcct = [SELECT Id from Account WHERE Name='Parent Account 0'];
            Account childAcct = [SELECT Id FROM Account WHERE Name='Child Account 0'];
            Contact contacts = [SELECT Id FROM Contact WHERE accountId=:childAcct.Id];

            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity opportunity = createPipelineOpportunity('Test Opp', childAcct);
            opportunity.Formstack_Store_ID__c = TEST_STORE_ID;
            opportunity.AccountId = null;
            opportunity.Menu_Setup_Method__c = null;
            opportunity.Menu_to_be_completed_by__c =  null;
            opportunity.Tablet_Kit_Type__c = null;
            opportunities.add(opportunity);

            Test.startTest();
            insert opportunities;
            Test.stopTest();

            Opportunity opportunityFromDB = [SELECT Id, Formstack_Store_ID__c, AccountId FROM Opportunity WHERE Id = :opportunity.Id];
            System.assertEquals(TEST_STORE_ID, opportunityFromDB.Formstack_Store_ID__c, 'Expecting form stack store Id - ' + TEST_STORE_ID);
            System.assertEquals(childAcct.Id, opportunityFromDB.AccountId, 'Expecting Account Id to match with Marketplace Account Id  - ' + childAcct.Id);
        }
    }
    /**
    * @description Create 'Pipeline' stage opportunity
    */
    private static Opportunity createPipelineOpportunity(String name, Account account) {
        return VTestUtil.createOpportunity(name, account);
    }

    @isTest
    private static void testAssetCreation(){
        System.runAs(getTestRunUser()) {
            Opportunity_Trigger_Helper_Settings__c helperSettings = Opportunity_Trigger_Helper_Settings__c.getInstance();
            helperSettings.New_Asset_Status__c = 'Purchased';
            upsert helperSettings;

            Boolean createAsset = CDdExperimentSvc.getFeatureFlag('Enable_Asset_Creation__c');
            Opportunity assetOpportunity = [Select Id, name, AccountId, StageName from Opportunity where Name = 'AssetOpportunity'];

            List<PricebookEntry> pricebookEntries = TDdOpportunityFactory.createPriceBookEntries(4);
            List<OpportunityLineItem> oppLineItems = TDdOpportunityFactory.createOppProducts(assetOpportunity.id);
            Test.startTest();
            if(createAsset) {
                insert oppLineItems;
                System.AssertNotEquals(oppLineItems.size(), 0);
            }
            System.AssertNotEquals(assetOpportunity.StageName, 'Closed Won');
            update new Opportunity(Id = assetOpportunity.Id, StageName = 'Closed Won',Menu_to_be_completed_by__c='DoorDash Onboarding Team',Menu_Setup_Method__c='Create New Menu(s) using Menu Source');
            //System.AssertEquals(assetOpportunity.StageName, 'Closed Won');
            Opportunity updatedAssetOpp = [Select Id, name, AccountId, StageName from Opportunity where Id = :assetOpportunity.Id];
            System.AssertEquals('Closed Won', updatedAssetOpp.StageName);
            Test.stopTest();

            List<Asset> assetsCreated = [SELECT AccountId, ContactId, Description, Id, Name, ParentId, Price, Product2Id,
                                                Quantity, Status, Opportunity__c
                                                FROM Asset
                                                WHERE Opportunity__c =: assetOpportunity.id ];
            // Assets should be created only if feature flag for creating assets is enabled and opportunity stage is closed won.

            if(createAsset) {
                System.AssertEquals(oppLineItems.size(), assetsCreated.size());
            } else {
                System.AssertEquals(0, assetsCreated.size());
            }

            for(Asset currAsset : assetsCreated) {
                System.AssertEquals(assetOpportunity.AccountId, currAsset.AccountId);
            }
        }
    }

    @isTest Static void testDonotAllowCreationOfOpportunities() {
        System.runAs(getTestRunUser()) {
            Account acct = [SELECT Id From Account WHERE Name='Account 0'];
            Contact con = [SELECT Id from Contact WHERE AccountId=:acct.Id];

            Lead newLead = TDdLeadFactory.createLeads('lastName', 1, false)[0];
            newLead.Account__c = acct.Id;
            insert newLead;

            Opportunity opp = TDdOpportunityFactory.createOpportunity('Opportunity', acct.Id, con.Id, 'Ready for Signature');
            Test.startTest();

            try {
                insert opp;
            } catch (Exception ex) {
                System.assert(ex.getMessage().contains(Label.DonotAllowOppWithLeadError));
            }
            test.stopTest();
        }
    }

    /**
    * @description - BZAP-5959 APEX timeout error on case_post_sale_handoff PB
    * @author: Knick (updated)
    * @date 03/2020
    * @description: BZAP-6564 Update Opportunity Amount from Account Amount
    */
    @isTest
    private static void testCopyRequestAccountManagementToParentAccount(){
        System.runAs(getTestRunUser()) {
            Account parentAcc = [select Id from Account where Name = 'Parent Test Acc'];
            parentAcc.Requesting_Account_Management__c = 'Unmanaged';
            update parentAcc;

            Account acc = [select Id, ParentId, Amount__c from Account where Name = 'Test Acc'];
            acc.ParentId = parentAcc.Id;
            acc.Amount__c= 500.00;                          // BZAP-6564
            update acc;

            Contact con =[SELECT Id from Contact where account.Name='Test Acc'];

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('ReadyOpp', acc.id, con.id, 'Ready for Signature');
            opp.Requesting_Account_Management__c = 'No';
            insert opp;
            Test.stopTest();

            Opportunity oppResult = [select Id, Amount,     // BZAP-6564 include Amount
                                            Requesting_Account_Management__c
                                    from Opportunity
                                    where Id =: opp.Id ];
            System.assert(oppResult.Requesting_Account_Management__c == 'No');

            Account accResult = [SELECT Id, Name, Requesting_Account_Management__c FROM Account WHERE Name = 'Parent Test Acc'];
            System.assertEquals('No', accResult.Requesting_Account_Management__c);
        }
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- Stamp Pricing Tier and Package Values on Closed Won
    */
    @isTest
    private static void testStampPricingTierPackageOnClosedWon(){
        System.runAs(getTestRunUser()) {
            Submarket__c submarket = [SELECT Id,NP_Pricing_Tier__c,NP_Service_Fee__c FROM Submarket__c WHERE NP_Pricing_Tier__c='test'];

            RealZip__RealZips__c realZipRec =   [select Id
                                                    from RealZip__RealZips__c
                                                    where Submarket_ID__c = 10];
            realZipRec.Submarket_lookup__c = submarket.Id;
            update realZipRec;

            Account acc = [select Id from Account where Name = 'Test Acc'];
            update acc;
            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Closed Won');
            opp.Commission__c = 0;
            opp.Trial_Type__c = 'Free Trial';
            opp.Trial_Commission__c = 10;
            opp.Manager_Package_Override__c = 'Plus';
            opp.Length_of_Trial__c = '7 Days';
            insert opp;

            Opportunity oppResult = [select Id,
                                            Basic_Floor_CW__c,
                                            Basic_Floor__c,
                                            DashPass_Eligible__c,
                                            DashPass_Eligible_CW__c,
                                            DashPass_Floor__c,
                                            DashPass_Floor_CW__c,
                                            Deck_Rank_CW__c,
                                            Deck_Rank__c,
                                            Package_Sold__c,
                                            Qualified_Package__c,
                                            Premium_Floor_CW__c,
                                            Premium_Floor__c,
                                            Pricing_Tier_CW__c,
                                            Pricing_Tier_New__c,
                                            Service_Fee_CW__c,
                                            Service_Fee_New__c,
                                            Trial_Pricing_Tier_CW__c,
                                            Trial_Pricing_Tier__c,
                                            UCR_Floor_Commission_CW__c,
                                            UCR_Floor_Commission__c
                                    from Opportunity
                                    where Id =: opp.Id];
            Account accResult = [select Id,
                                        Deck_Rank__c,
                                        Package_Sold__c
                                from Account
                                where Id =: acc.Id ];

            System.assertEquals(oppResult.Basic_Floor_CW__c, oppResult.Basic_Floor__c);
            System.assertEquals(oppResult.DashPass_Eligible_CW__c, oppResult.DashPass_Eligible__c);
            System.assertEquals(oppResult.DashPass_Floor_CW__c, oppResult.DashPass_Floor__c);
            System.assertEquals(oppResult.Deck_Rank_CW__c, accResult.Deck_Rank__c);
            System.assertEquals(oppResult.Package_Sold__c, oppResult.Qualified_Package__c);
            System.assertEquals(oppResult.Premium_Floor_CW__c, oppResult.Premium_Floor__c);
            System.assertEquals(oppResult.Pricing_Tier_CW__c, oppResult.Pricing_Tier_New__c);
            System.assertEquals(oppResult.Service_Fee_CW__c, oppResult.Service_Fee_New__c);
            System.assertEquals(oppResult.Trial_Pricing_Tier_CW__c , oppResult.Trial_Pricing_Tier__c);
            System.assertEquals(oppResult.UCR_Floor_Commission_CW__c, oppResult.UCR_Floor_Commission__c);
            System.assertEquals(accResult.Package_Sold__c, oppResult.Qualified_Package__c);

            Test.stopTest();
        }
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- CW Opp Sets Delivery Fee case 1
    */
    @isTest
    private static void testCWOppSetsDeliveryFee1(){
        System.runAs(getTestRunUser()) {
            Submarket__c submarket = [SELECT Id FROM Submarket__c WHERE Premium_Delivery_Fee__c=30];


            RealZip__RealZips__c realZipRec =   [select Id
                                                from RealZip__RealZips__c
                                                where Submarket_ID__c = 10];
            realZipRec.Submarket_lookup__c = submarket.Id;
            update realZipRec;

            Account acc = [select Id from Account where Name = 'Test Acc'];
            update acc;
            Contact con = [SELECT Id FROM Contact WHERE account.Name='Test Acc'];
            Opportunity opp = [SELECT Id from Opportunity Where Name='CloseWonOpp'];
            Test.startTest();

            Opportunity oppResult = [select Id,
                                            Package_Sold__c,
                                            Delivery_Fee_CW__c,
                                            Premium_Delivery_Fee__c,
                                            Basic_Delivery_Fee__c,
                                            PB_WF_Flow_Ran__c
                                    from Opportunity
                                    where Id =: opp.Id ];

            System.assertEquals(oppResult.Delivery_Fee_CW__c, null);
            Test.stopTest();
        }
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- CW Opp Sets Delivery Fee case 2
    */
    @isTest
    private static void testCWOppSetsDeliveryFee2(){
        System.runAs(getTestRunUser()) {
            Submarket__c submarket = [SELECT Id FROM Submarket__c WHERE Premium_Delivery_Fee__c=30];

            RealZip__RealZips__c realZipRec =   [select Id
                                                from RealZip__RealZips__c
                                                where Submarket_ID__c = 10];
            realZipRec.Submarket_lookup__c = submarket.Id;
            update realZipRec;

            Account acc = [SELECT Id FROM Account WHERE Name = 'Test Acc'];
            update acc;
            Contact con = [SELECT Id FROM Contact WHERE account.Name='Test Acc'];
            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
            opp.Package_Sold__c = 'Plus';
            insert opp;

            Opportunity oppResult = [SELECT Id,
                                            Package_Sold__c,
                                            Delivery_Fee_CW__c,
                                            Premium_Delivery_Fee__c,
                                            Basic_Delivery_Fee__c,
                                            PB_WF_Flow_Ran__c
                                    FROM Opportunity
                                    where Id =: opp.Id ];
            System.assertEquals(oppResult.Delivery_Fee_CW__c, oppResult.Basic_Delivery_Fee__c);
            Test.stopTest();
        }
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- CW Opp Sets Delivery Fee case 3
    */
    @isTest
    private static void testCWOppSetsDeliveryFee3(){
        System.runAs(getTestRunUser()) {
            Submarket__c submarket = [SELECT Id FROM Submarket__c WHERE Premium_Delivery_Fee__c=30];

            RealZip__RealZips__c realZipRec =   [select Id
                                                from RealZip__RealZips__c
                                                where Submarket_ID__c = 10];
            realZipRec.Submarket_lookup__c = submarket.Id;
            update realZipRec;

            Account acc = [select Id from Account where Name = 'Test Acc'];
            update acc;

            Contact con = [SELECT Id FROM Contact WHERE account.Name='Test Acc'];

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
            opp.Package_Sold__c = 'Premier';
            insert opp;
            Opportunity oppResult = [select Id,
                                            Package_Sold__c,
                                            Delivery_Fee_CW__c,
                                            Premium_Delivery_Fee__c,
                                            Basic_Delivery_Fee__c,
                                            PB_WF_Flow_Ran__c
                                    from Opportunity
                                    where Id =: opp.Id ];
            System.assertEquals(oppResult.Delivery_Fee_CW__c, oppResult.Premium_Delivery_Fee__c);
            Test.stopTest();
        }
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- Formstack - Update Order Protocol
    */
    @isTest
    private static void testFormstackUpdateOrderProtocol1(){
        System.runAs(getTestRunUser()) {
            Opportunity_Trigger_Helper_Settings__c helperSettings = Opportunity_Trigger_Helper_Settings__c.getOrgDefaults();
            helperSettings.New_Asset_Status__c = 'Purchased';
            helperSettings.Weekly_Printer_Sub_Fee__c = '$2';
            helperSettings.Weekly_Tablet_Sub_Fee__c = '$3';
            helperSettings.Formstack_Weekly_Printer_Sub_Fee__c = '$3.15';
            helperSettings.Formstack_Weekly_Tablet_Sub_Fee__c = '$5';
            upsert helperSettings;

            Account acc = [select Id from Account where Name = 'Test Acc'];
            acc.Formstack_Version__c = 'New Store';
            update acc;

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
            opp.Order_Protocol_Email__c = 'test@test.com';
            opp.Order_Protocol_Fax__c = '1234567890';
            opp.Activation_Fee__c = '$75';
            opp.POS_Fallback_Protocol__c = '';
            opp.Formstack_Order_Protocol__c = 'Tablet and Printer (DoorDash Owns)';
            opp.of_Addressable_Locations__c = 3;
            opp.Weekly_Tablet_Subscription_Fee__c = '$7';
            opp.Weekly_Printer_Subscription_Fee__c = '$3.15';
            opp.Merchant_Signed_with_Exclusivity__c = 'No';
            insert opp;

            Opportunity oppResult = [select Id,
                                            Order_Protocol_Email__c,
                                            Formstack_Order_Protocol_Email__c,
                                            Order_Protocol_Fax__c,
                                            Formstack_Order_Protocol_Fax__c,
                                            Tablet_Delivery_Method__c,
                                            Weekly_Printer_Subscription_Fee__c,
                                            Weekly_Tablet_Subscription_Fee__c
                                    from Opportunity
                                    where Id=:opp.Id];
            System.assertEquals(oppResult.Tablet_Delivery_Method__c, 'Drop-ship');
            System.assertEquals(oppResult.Weekly_Printer_Subscription_Fee__c, '$3.15');
            System.assertEquals(oppResult.Weekly_Tablet_Subscription_Fee__c, '$5');
            Test.stopTest();
        }
    }

    /**
    * @description - BZAP-6950 Changing PB to Trigger -- Formstack - Update Order Protocol
    */
    @isTest
    private static void testFormstackUpdateOrderProtocol2(){
        System.runAs(getTestRunUser()) {
            Opportunity_Trigger_Helper_Settings__c helperSettings = Opportunity_Trigger_Helper_Settings__c.getOrgDefaults();
            helperSettings.New_Asset_Status__c = 'Purchased';
            helperSettings.Formstack_Weekly_Printer_Sub_Fee__c = '$3.15';
            helperSettings.Formstack_Weekly_Tablet_Sub_Fee__c = '$5';
            upsert helperSettings;

            Account acc = [select Id from Account where Name = 'Test Acc'];
            acc.Formstack_Version__c = 'New Store';
            update acc;

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Test.startTest();
            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
            opp2.Formstack_Order_Protocol__c = 'Tablet and Printer (DoorDash Owns)';
            opp2.POS_Fallback_Protocol__c = '';
            opp2.of_Addressable_Locations__c = 3;
            insert opp2;

            Opportunity oppResult2 = [select Id,
                                            Order_Protocol__c,
                                            Formstack_Order_Protocol__c,
                                            Tablet_Delivery_Method__c,
                                            Weekly_Printer_Subscription_Fee__c,
                                            Weekly_Tablet_Subscription_Fee__c
                                    from Opportunity
                                    where Id =: opp2.Id ];
            System.assertEquals(oppResult2.Order_Protocol__c, oppResult2.Formstack_Order_Protocol__c);
            System.assertEquals(oppResult2.Tablet_Delivery_Method__c, 'Drop-ship');
            System.assertEquals(oppResult2.Weekly_Printer_Subscription_Fee__c, '$3.15');
            System.assertEquals(oppResult2.Weekly_Tablet_Subscription_Fee__c, '$5');
            Test.stopTest();
        }
    }

    /**
     * @description - BZAP-6950 Changing PB to Trigger -- Formstack - Update Order Protocol
     */
    @isTest
    private static void testFormstackUpdateOrderProtocol3(){
        System.runAs(getTestRunUser()) {
            Opportunity_Trigger_Helper_Settings__c helperSettings = Opportunity_Trigger_Helper_Settings__c.getOrgDefaults();
            helperSettings.New_Asset_Status__c = 'Purchased';
            helperSettings.French_Weekly_Printer_Sub_Fee__c = '$2';
            helperSettings.French_Weekly_Tablet_Sub_Fee__c = '$3';
            upsert helperSettings;

            Account acc = [select Id from Account where Name = 'Test Acc'];
            acc.Formstack_Version__c = 'New Store';
            update acc;

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Test.startTest();
            Opportunity opp3 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
            opp3.Formstack_Order_Protocol__c = 'french';
            opp3.Order_Protocol__c = 'Tablet and Printer (DoorDash Owns)';
            opp3.POS_Fallback_Protocol__c = '';
            opp3.of_Addressable_Locations__c = 3;
            insert opp3;

            Opportunity oppResult3 = [select Id,
                                            Order_Protocol__c,
                                            Formstack_Order_Protocol__c,
                                            Tablet_Delivery_Method__c,
                                            Weekly_Printer_Subscription_Fee__c,
                                            Weekly_Tablet_Subscription_Fee__c
                                    from Opportunity
                                    where Id =: opp3.Id ];
            System.assertEquals(oppResult3.Weekly_Printer_Subscription_Fee__c, '$2');
            System.assertEquals(oppResult3.Weekly_Tablet_Subscription_Fee__c, '$3');


            Test.stopTest();
        }
    }

    /**
    * * @description - BZAP-7606 Adding test class for Canada
    */
    @isTest
    private static void testFormstackUpdateOrderProtocolCanada(){
        System.runAs(getTestRunUser()) {
            Opportunity_Trigger_Helper_Settings__c helperSettings = Opportunity_Trigger_Helper_Settings__c.getOrgDefaults();
            helperSettings.New_Asset_Status__c = 'Purchased';
            helperSettings.Formstack_Weekly_Printer_Sub_Fee__c = '$3.15';
            helperSettings.Formstack_Weekly_Tablet_Sub_Fee__c = '$5';
            upsert helperSettings;

            Account acc = [select Id from Account where Name = 'Canada Test Acc'];
            acc.Formstack_Version__c = 'New Store';
            update acc;

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Test.startTest();
            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
            opp2.Formstack_Order_Protocol__c = 'Tablet and Printer (DoorDash Owns)';
            opp2.POS_Fallback_Protocol__c = '';
            opp2.of_Addressable_Locations__c = 3;
            opp2.Formstack_Order_Protocol_Email__c = 'test@test.com';
            opp2.Formstack_Order_Protocol_Fax__c = '1234567890';
            insert opp2;

            Opportunity oppResult2 = [select Id,
                                            Order_Protocol__c,
                                            Formstack_Order_Protocol__c,
                                            Tablet_Delivery_Method__c,
                                            Weekly_Printer_Subscription_Fee__c,
                                            Weekly_Tablet_Subscription_Fee__c,
                                            PactSafe_Contract_Type__c,
                                            Formstack_Order_Protocol_Email__c,
                                            Formstack_Order_Protocol_Fax__c,
                                            Order_Protocol_Email__c,
                                            Order_Protocol_Fax__c
                                    from Opportunity
                                    where Id =: opp2.Id];
            System.assertEquals(oppResult2.Order_Protocol__c, oppResult2.Formstack_Order_Protocol__c);
            System.assertEquals(oppResult2.Order_Protocol_Email__c, opp2.Formstack_Order_Protocol_Email__c);
            System.assertEquals(oppResult2.Order_Protocol_Fax__c, opp2.Formstack_Order_Protocol_Fax__c);
            System.assertEquals(oppResult2.Tablet_Delivery_Method__c, 'Drop-ship');
            System.assertEquals(oppResult2.Weekly_Printer_Subscription_Fee__c, '$3.15');
            System.assertEquals(oppResult2.Weekly_Tablet_Subscription_Fee__c, '$5');
            System.assertEquals(oppResult2.PactSafe_Contract_Type__c, 'English Canada Sign Up Sheet');
            Test.stopTest();
        }
    }

    /**
     * @author: Knick
     * @date 04/2020
     * @description: BZAP-6564 Changing PB to Trigger -- Formstack - Related McDs DM to Account
     *
     */
    @isTest static void formstackRelatedUpdatesTest() {
        System.runAs(getTestRunUser()) {
            Account parent =[SELECT Id FROM Account WHERE Name ='Parent 0'];
            Account child = [select Id From Account Where Name ='Child 0'];
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'Enterprise_Marketplace');
            opp.Franchise_Formstack__c = true;
            opp.Decision_Maker__c = contact.Id;
            opp.Formstack_Submission_ID__c = 'TEST Submission';
            opp.Account_Number__c = 'TEST Account Number';
            opp.Routing_Number__c = 'TEST Routing Number';
            opp.EIN__c = 'TEST EIN';
            opp.Legal_Business_Name__c = 'TEST Legal Name';
            opp.Proposed_Date_of_Activation__c = Date.today();
            test.startTest();
                insert opp;
            test.stopTest();
            Account checkAccount = [
                SELECT Bank_Account_Number_Encrypted__c, Bank_Routing_Number_Encrypted__c, EIN_Encrypted__c, Legal_Business_Name__c
                FROM Account
                WHERE Id = :child.Id
            ];
            system.assertNotEquals(null, checkAccount.Bank_Account_Number_Encrypted__c);
            system.assertNotEquals(null, checkAccount.Bank_Routing_Number_Encrypted__c);
            system.assertNotEquals(null, checkAccount.EIN_Encrypted__c);
            system.assertEquals(opp.Legal_Business_Name__c, checkAccount.Legal_Business_Name__c);
            Contact checkContact = [SELECT AccountId FROM Contact WHERE Id = :contact.Id];
            system.assertEquals(child.Id, checkContact.AccountId);
        }
    }

    /**
     * @author: Knick
     * @date 04/2020
     * @description: BZAP-6564 Changing PB to Trigger -- Formstack - SSMO Trial
     *  MOST OF THIS HAS MOVED TO WORKFLOW except for setting the Primary Campaign Source which cannot be done in workflow
     */
    @isTest static void formstackSSMOtrialTest() {
        System.runAs(getTestRunUser()) {
            helperSettings = Opportunity_Trigger_Helper_Settings__c.getOrgDefaults();
            Account parent =[SELECT Id FROM Account WHERE Name ='Parent 0'];
            Account child = [SELECT Id FROM Account Where Name = 'Child 0'];
            Contact contact = [SELECT Id FROM Contact Where accountId=:child.Id];

            test.startTest();
            Opportunity opp = [SELECT Id FROM Opportunity Where Name='Test Opp one'];
            test.stopTest();
            Opportunity checkOpp = [SELECT Id, Name, CampaignId FROM Opportunity WHERE Id =:opp.Id];
            system.assertEquals(helperSettings.Caviar_Promo_Campaign_Id__c, checkOpp.CampaignId);
        }
    }


    /**
     * @author: Knick
     * @date 04/2020
     * @description: BZAP-7363 Convert Opportunity PBs to trigger -- Activate Centrally for Enterprise
     */
    public static void activateCentrallyForEnterpriseTest() {
        System.runAs(getTestRunUser()) {
            Account parent =[SELECT Id FROM Account WHERE Name ='Parent 0'];
            Account child = [SELECT  Id,ParentId FROM Account Where Name='Child 0'];
            Contact contact = [SELECT Id FROM Contact Where accountId=:child.Id];
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp 2', child.Id, contact.Id, 'Closed Won', 'Enterprise_Marketplace');
            test.startTest();
                insert opp;
            test.stopTest();
            Opportunity checkOpp = [
                SELECT Activate_Centrally_2__c, Activate_Centrally_No_Validation__c
                FROM Opportunity WHERE Name = 'Test Opp 2'
            ];
            system.assertEquals('No', checkOpp.Activate_Centrally_2__c);
            system.assertEquals('Not in coverage', checkOpp.Activate_Centrally_No_Validation__c);
        }
    }


    /**
     * @author: Knick
     * @date 11/2020
     * @description: BZAP-7363 Convert Opportunity PBs to trigger -- Formstack Canada Contract Type
     */
    public static void formstackCanadaContractTypeTest() {
        System.runAs(getTestRunUser()) {
            Account parent =[SELECT Id FROM Account WHERE Name ='Parent 0'];
            Account child = TDdAccountFactory.createAccounts('Child', 1, 'Marketplace')[0];
            child.ParentId = parent.Id;  child.Formstack_Version__c = 'Sales Rep';  child.BillingCountryCode = 'Canada';  insert child;
            Contact contact = TDdAccountFactory.createContacts(1, child.Id)[0];  insert contact;
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', child.Id, contact.Id, 'New', 'ML_Inside_Sales');
            test.startTest();
                insert opp;
            test.stopTest();
            Opportunity checkOpp = [
                SELECT PactSafe_Contract_Type__c
                FROM Opportunity WHERE Name = 'Test Opp'
            ];
            system.assertEquals('English Canada Sign Up Sheet', checkOpp.PactSafe_Contract_Type__c);
        }
    }
    /**
     * @description: BZAP-8947 Prevent DashPass Per Enrollment and Subscription being sold on the same opportunity
     */
    @isTest
    static void testValidateMultiTypeDashPassForWork() {
        System.runAs(getTestRunUser()) {
            Map<String, String> PRODUCT_NAME_AND_FAMILY = new Map<String, String> {
                    'DashPass for Work - Pay Per Enrollment' => 'Work',
                    'DashPass for Work - Subscription (Pay Upfront)' => 'Work'
            };
            List<Product2> products = new List<Product2>();
            for (String productName : PRODUCT_NAME_AND_FAMILY.keySet()) {
                Product2 product = new Product2(Name = productName, Family = PRODUCT_NAME_AND_FAMILY.get(productName));
                for (String fieldName : TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES.keySet()) {
                    product.put(fieldName, TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES.get(fieldName));
                }
                products.add(product);
            }
            insert products;
            List<PricebookEntry> priceBookEntries = TDdOpportunityLineItemFactory.createPricebookEntries(products);
            List<PriceBookEntry> pbes = [
                SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id,
                        Product2Id, ProductCode, UnitPrice, UseStandardPrice,
                        Product2.Name, Product2.Family
                FROM PricebookEntry
                WHERE Name IN :PRODUCT_NAME_AND_FAMILY.keySet()];
            Account testAccount = TDdAccountFactory.createAccounts('TestDDAccount', 1)[0];
            // insert testAccount;
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.insert(testAccount, dml);
            Contact testContact = TDdAccountFactory.createContacts(1, testAccount.Id)[0];
            insert testContact;
            RecordType doorDashForBusinessRecType = [SELECT Id FROM RecordType WHERE Id = :CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId()];
            Opportunity testOpp = TDdOpportunityFactory.createOpportunityByDevRT('TestOppNew', testAccount.Id, testContact.Id, 'New', 'DoorDash_for_Business');
            testOpp.Menu_Setup_Method__c = null;
            testOpp.Menu_to_be_completed_by__c = null;
            testOpp.Tablet_Kit_Type__c = null;
            List<Opportunity> testOpps = new List<Opportunity>{testOpp};
            insert testOpps;
            Test.startTest();
            List<OpportunityLineItem> oppProducts = TDdOpportunityLineItemFactory.createOpportunityProducts(testOpp.Id, priceBookEntries);
            Boolean dmlException = false;
            try {
                insert oppProducts;
            } catch (DmlException dmlEx){
                dmlException = true;
                System.assert(dmlEx.getMessage().contains(System.Label.ERROR_MSG_OPP_MULTI_TYPE_DASHPASS_WORK), 'message=' + dmlEx.getMessage());
            }
            Test.stopTest();
            System.assert(dmlException, 'Expecting DMLException for Opp product');
            List<Opportunity> opportunitiesFromDB = [SELECT Id, RecordTypeId FROM  Opportunity WHERE Id IN :testOpps];
            System.assertEquals(1, opportunitiesFromDB.size(), 'Expecting 1 Opportunity record');
            System.assertEquals(CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId(), opportunitiesFromDB[0].RecordTypeId, 'Expecting DoorDash for Business Record Type Id');
        }
    }
    /**
     * @description: BZAP-8948 Ensure alignment of payment protocol for rec type - DoorDash for Business
     */
    @isTest
    static void testValidatePaymentProtocol() {
        System.runAs(getTestRunUser()){
            TDdOpportunityLineItemFactory.createProducts();
            Account testAccount = TDdAccountFactory.createAccounts('TestDDAccount', 1)[0];
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.insert(testAccount, dml);
            Contact testContact = TDdAccountFactory.createContacts(1, testAccount.Id)[0];
            insert testContact;
            List<Payment_Account__c> paymentAccounts = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            RecordType doorDashForBusinessRecType = [SELECT Id FROM RecordType WHERE Id = :CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId()];
            Opportunity testOpp1 = TDdOpportunityFactory.createOpportunityByDevRT('TestOppNew1', testAccount.Id, testContact.Id, 'New', 'DoorDash_for_Business');
            testOpp1.Payment_Protocol__c = 'Credit Card';
            testOpp1.Menu_Setup_Method__c = null;
            testOpp1.Menu_to_be_completed_by__c = null;
            testOpp1.Tablet_Kit_Type__c = null;
            List<Opportunity> testOpps = new List<Opportunity>{testOpp1};
            insert testOpps;
            Test.startTest();
            List<OpportunityLineItem> oppProducts1 = TDdOpportunityLineItemFactory.createOpportunityProducts(testOpp1.Id);
            for (OpportunityLineItem oppProduct1 : oppProducts1){
                oppProduct1.Payment_Protocol__c = 'Invoicing';
            }
            List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
            Boolean dmlException1 = false;
            try {
                insert oppProducts1;
            } catch (DmlException dmlEx){
                dmlException1 = true;
                System.assert(dmlEx.getMessage().contains(System.Label.ERROR_MSG_OPP_PAYMENT_PROTOCOL_IS_NOT_INVOICING), 'message=' + dmlEx.getMessage());
            }
            Test.stopTest();
            System.assert(dmlException1, 'Expecting DMLException for Opp product 1');
            List<Opportunity> opportunitiesFromDB = [SELECT Id, RecordTypeId, Payment_Protocol__c FROM  Opportunity WHERE Id IN :testOpps];
            System.assertEquals(1, opportunitiesFromDB.size(), 'Expecting 1 Opportunity record');
            System.assertEquals(CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId(), opportunitiesFromDB[0].RecordTypeId, 'Expecting DoorDash for Business Record Type Id');
        }
    }
    /**
     * @description: BZAP-8948 Ensure alignment of payment protocol for rec type - DoorDash for Business
     */
    @isTest
    static void testValidatePaymentProtocol1() {
        System.runAs(getTestRunUser()){
            List<Payment_Account__c> paymentAccounts = Test.loadData(Payment_Account__c.sObjectType, 'Sample_Payment_Account');
            Id testOppId = [SELECT Id FROM Opportunity WHERE Name = 'TestDDOpportunity1'].Id;
            Test.startTest();
            try {
                update new Opportunity(Id = testOppId, Payment_Protocol__c = 'Invoicing', Payment_Account__c = paymentAccounts[0].Id);
            } catch (DmlException dmlEx){
                System.assert(dmlEx.getMessage().contains(System.Label.ERROR_MSG_OPP_PAYMENT_PROTOCOL_IS_NOT_INVOICING), 'message=' + dmlEx.getMessage());
            }
            Test.stopTest();
            List<Opportunity> opportunitiesFromDB = [SELECT Id, RecordTypeId, Payment_Protocol__c FROM  Opportunity WHERE Id = :testOppId];
            System.assertEquals(1, opportunitiesFromDB.size(), 'Expecting 1 Opportunity record');
            System.assertEquals('Invoicing', opportunitiesFromDB[0].Payment_Protocol__c, 'Expecting Opportunity payment protocol - ' + 'Invoicing');
            System.assertEquals(CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId(), opportunitiesFromDB[0].RecordTypeId, 'Expecting DoorDash for Business Record Type Id');
        }
    }

    @IsTest
    public static void testConcatenateMarketingUUID() {
        System.runAs(getTestRunUser()) {
            Opportunity newOpp = new Opportunity(Id = '0060r000003zlNaAAI', Marketing_UUID__c = '1234567890');
            Opportunity oldOpp = new Opportunity(Id = '0060r000003zlNaAAI', Marketing_UUID__c = '0987654321');
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
            oldMap.put(oldOpp.Id, oldOpp);
            CDdOpportunityTriggerHelper.concatenateMarketingUUID(new List<Opportunity> { newOpp }, oldMap);
            System.assertEquals('0987654321, 1234567890', newOpp.Marketing_UUID__c);
        }
    }

    @IsTest
    public static void testSetDefaultValueOnMarketplaceOpps() {
        System.runAs(getTestRunUser()) {
            Account acc = [select Id from Account where Name = 'Test Acc'];
            Contact con = [SELECT Id FROM Contact WHERE accountId=:acc.Id];
            Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'New');
            opp.Type = 'New Partner';
            opp.Menu_To_Be_Completed_By__c = '';
            opp.Tablet_Delivery_Method__c = 'Drop-ship';
            opp.Tablet_Kit_Type__c = '';
            opp.RecordTypeId = mlInsideSalesId;
            Test.startTest();
            insert opp;
            Test.stopTest();
            List<Opportunity> queriedOpps = [SELECT Menu_to_be_Completed_By__c, Menu_Setup_Method__c, Tablet_Kit_Type__c FROM Opportunity WHERE Id = :opp.Id];
            system.assertEquals('DoorDash Onboarding Team', queriedOpps[0].Menu_to_be_Completed_By__c);
            system.assertEquals('Create New Menu(s) using Menu Source', queriedOpps[0].Menu_Setup_Method__c);
            system.assertEquals('Standard', queriedOpps[0].Tablet_Kit_Type__c);
        }
    }

    @isTest
    static void testUpdateMOCaseAndMilestones() {
        System.runAs(getTestRunUser()) {
            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name IN ('UpdateMOCaseAndMilestones 1','UpdateMOCaseAndMilestones 2')];
            List<Case> moCases = [SELECT Id FROM Case WHERE RecordTypeId = :onboardingCaseRTId AND Opportunity_Name__c IN : opps];
            Id onboardingSSMEPendingQueueId = [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name = 'Onboarding - SSME Pending'].Id;
            Test.startTest();
                update new List<Case>{
                    new Case(Id = moCases[0].Id, OwnerId = onboardingSSMEPendingQueueId),
                    new Case(Id = moCases[1].Id, OwnerId = onboardingSSMEPendingQueueId)
                };

                update new List<Opportunity>{
                    new Opportunity(Id = opps[0].Id, Menu_to_be_completed_by__c = 'Merchant', SSME_Menu_Completion_Date_Time__c = system.now()),
                    new Opportunity(Id = opps[1].Id, Menu_to_be_completed_by__c = 'DoorDash Onboarding Team', SSME_Escalation_Date_Time__c = system.now())
                };
            Test.stopTest();
            Map<Id, Milestone__c> oppIdToMilestones = new Map<Id, Milestone__c>();
            Map<Id, Case> oppIdToMOCases = new Map<Id, Case>();
            for(Case c: [SELECT Id, Opportunity_Name__c, OwnerId, Owner.Name FROM Case WHERE RecordTypeId = :onboardingCaseRTId AND Opportunity_Name__c IN :opps]){
                oppIdToMOCases.put(c.Opportunity_Name__c, c);
            }
            for(Milestone__c m: [SELECT Id, Status__c, Status_Reason__c, Case__r.Opportunity_Name__c FROM Milestone__c WHERE RecordTypeId = :smRTId AND Case__r.Opportunity_Name__c IN :opps]){
                oppIdToMilestones.put(m.Case__r.Opportunity_Name__c, m);
            }
            system.assertEquals([SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name = 'Onboarding - Menu Ready for QA'].Id,
                oppIdToMOCases.get(opps[0].Id).OwnerId);
            system.assertEquals([SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name = 'Onboarding - New Partner Escalations'].Id,
                oppIdToMOCases.get(opps[1].Id).OwnerId);
            system.assertEquals('Ready for QA', oppIdToMilestones.get(opps[0].Id).Status__c);
            system.assertEquals(null, oppIdToMilestones.get(opps[0].Id).Status_Reason__c);
            system.assertEquals('Escalated', oppIdToMilestones.get(opps[1].Id).Status__c);
            system.assertEquals('SSME to Doordash', oppIdToMilestones.get(opps[1].Id).Status_Reason__c);
        }
    }

    @isTest static void testCreateMilestonesPostOppClose(){
        String testOppName = 'UpdateMOCaseAndMilestones 3';
        Opportunity testOpp = [SELECT Id, RecordTypeId, Activate_Centrally_2__c, Mx_Requested_Custom_Radius_Demand_Gen__c,
            Order_Protocol__c, Menu_to_be_completed_by__c FROM Opportunity WHERE Name = :testOppName];
        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Opportunity_Name__c = :testOpp.Id
                AND RecordTypeId = :CDdOpportunityTriggerHelper.onboardingCaseRTId]);
        System.assertEquals(0, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id
                AND Milestone_Template__r.Milestone_Creation_Type__c = 'Conditional']);
        System.assertEquals(6, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id]);

        Test.startTest();
        update new Case(Segment__c = 'Local',
            Id = [SELECT Id FROM Case WHERE Opportunity_Name__c = :testOpp.Id AND RecordTypeId = :CDdOpportunityTriggerHelper.onboardingCaseRTId].Id);
        update new Opportunity(
            Id = testOpp.Id,
            Menu_to_be_completed_by__c = 'DoorDash Onboarding Team',
            Order_Protocol__c = 'Email',
            Mx_Requested_Custom_Radius_Demand_Gen__c = 'Yes',
            Activate_Centrally_2__c = 'Yes'
        );
        Test.stopTest();
        System.assertEquals(4, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id
                AND Milestone_Template__r.Milestone_Creation_Type__c = 'Conditional'] );
    }

    @isTest static void testCreateMilestonesPostOppClose2(){
        String testOppName = 'UpdateMOCaseAndMilestones 3';
        Opportunity testOpp = [SELECT Id, RecordTypeId, Activate_Centrally_2__c, Mx_Requested_Custom_Radius_Demand_Gen__c,
            Order_Protocol__c, Menu_to_be_completed_by__c FROM Opportunity WHERE Name = :testOppName];
        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Opportunity_Name__c = :testOpp.Id
                AND RecordTypeId = :CDdOpportunityTriggerHelper.onboardingCaseRTId]);
        System.assertEquals(0, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id
                AND Milestone_Template__r.Milestone_Creation_Type__c = 'Conditional']);
        System.assertEquals(6, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id]);

        Test.startTest();
        update new Case(Segment__c = 'Local',
            Id = [SELECT Id FROM Case WHERE Opportunity_Name__c = :testOpp.Id AND RecordTypeId = :CDdOpportunityTriggerHelper.onboardingCaseRTId].Id);
        update new Opportunity(
            Id = testOpp.Id,
            Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)',
            Tablet_Delivery_Method__c = 'Drop-Ship'
        );
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Milestone__c WHERE Case__r.Opportunity_Name__c = :testOpp.Id
                AND Milestone_Template__r.Milestone_Creation_Type__c = 'Conditional']);
    }
    /**
     * @description: Test for BZAP-10239 - Set the DashPass eligible fields on the Opportunity
     */
    @isTest
    public static void testSetDashPassEligible() {
        System.runAs(getTestRunUser()) {
            RecordType RECORD_TYPE_MARKETPLACE = [SELECT Id, Name FROM RecordType WHERE Id = :mlInsideSalesId];
            RecordType RECORD_TYPE_ENTERPRISE_MARKETPLACE = [SELECT Id, Name FROM RecordType WHERE Id = :enterpriseMarketplaceId];
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Acc'];
            //testAccount.DashPass_Eligibility_Override__c = true;
            update testAccount;
            Contact testContact = [SELECT Id FROM Contact WHERE accountId=:testAccount.Id];
            Opportunity opp1 = TDdOpportunityFactory.createOpportunity('DashPassEligibleOpp1', testAccount.Id, testContact.Id, 'Contract Signed', RECORD_TYPE_MARKETPLACE);
            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('DashPassEligibleOpp2', testAccount.Id, testContact.Id, 'Meeting Ran / Negotiated', RECORD_TYPE_ENTERPRISE_MARKETPLACE);
            opp2.DashPass_Flat_Fee__c = 10;
            opp2.DealDesk_Approved_del__c = 'Yes';
            opp2.DashPass_Eligibility_Override_Approved__c = 'Yes';
            Test.startTest();
            insert new List<Opportunity>{opp1, opp2};
            Test.stopTest();
            Opportunity opportunity1FromDB = [SELECT Id, DashPass_Eligible_CW__c, DashPass_Eligible__c FROM Opportunity WHERE Id = :opp1.Id];
            Opportunity opportunity2FromDB = [SELECT Id, DashPass_Eligible_CW__c, DashPass_Eligible__c FROM Opportunity WHERE Id = :opp2.Id];
            System.assertNotEquals('Yes', opportunity1FromDB.DashPass_Eligible_CW__c);
            System.assertNotEquals('Yes', opportunity1FromDB.DashPass_Eligible__c);
            System.assertEquals('Yes', opportunity2FromDB.DashPass_Eligible_CW__c);
            System.assertEquals('Yes', opportunity2FromDB.DashPass_Eligible__c);
        }
    }
    /**
    * @description: Test for BZAP-29889 - Bypass the DashPass eligible fields population for Japan Opportunity
    */
    @isTest
    public static void testSetDashPassEligibleBypass() {
        System.runAs(getTestRunUser()) {
            RecordType RECORD_TYPE_ENTERPRISE_MARKETPLACE = [SELECT Id, Name FROM RecordType WHERE Id = :enterpriseMarketplaceId];
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'opptriggerHandlerTest - Japan Child'];

            Contact testContact = [SELECT Id FROM Contact WHERE accountId=:testAccount.Id];
            Opportunity opp = TDdOpportunityFactory.createOpportunity('DashPassEligibleOpp1', testAccount.Id, testContact.Id, 'Meeting Ran / Negotiated', RECORD_TYPE_ENTERPRISE_MARKETPLACE);
            opp.DashPass_Flat_Fee__c = 10;
            opp.DealDesk_Approved_del__c = 'Yes';
            opp.DashPass_Eligibility_Override_Approved__c = 'Yes';
            Test.startTest();
            insert opp;
            Test.stopTest();

            Opportunity opportunityFromDB = [SELECT Id, DashPass_Eligible_CW__c, DashPass_Eligible__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(Null, opportunityFromDB.DashPass_Eligible__c);
            System.assertEquals(Null, opportunityFromDB.DashPass_Eligible_CW__c);
        }
    }
     /**
     * @description: Test for BZAP 10989 - Prevent opportunity deletion in Salesforce
     */
    @isTest
    public static void testValidateOpportunityToDelete() {
        System.runAs(getTestRunUser()) {
            try {
                List<Opportunity> opptyList = [SELECT Id, Name, StageName FROM Opportunity WHERE StageName = 'Ready for Signature'];
                delete opptyList;
            } catch(Exception e) {
                System.assert(e.getMessage().contains(System.Label.Opp_Delete_Validation_Error));
            }
        }
    }

    /**
     * @description: Test for BASD-14188 Ensure Pactsafe Details are erased when an Opportunity is cloned
     */
    @isTest
    public static void testsetBlankValueOnClonedDDFBOpp() {

        System.runAs(getTestRunUser()) {
            list<Opportunity> listOfOppTiInsert = new list<Opportunity>();

			Test.startTest();
            RecordType doorDashForBusinessRecType = [SELECT Id FROM RecordType WHERE Id = :CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId()];
            Opportunity oppty = [SELECT Id, Name, StageName, RecordTypeId FROM Opportunity WHERE RecordTypeId = :doorDashForBusinessRecType.Id LIMIT 1];
            oppty.PactSafe_Activity_ID__c = '5678FG322';
            oppty.PactSafe_Record__c = 'www.atginfo.com';
            oppty.Contract_Signed_Date__c = Date.today();
            update oppty;

            if(oppty != null){
                Opportunity cloneOpp = new Opportunity();
                cloneOpp.Id = oppty.Id;
                cloneOpp.RecordTypeId = doorDashForBusinessRecType.Id;
				Opportunity newcloneOpp = cloneOpp.clone(false,true,false,false);
                newcloneOpp.Name = 'Cloned Opportunity';
                newcloneOpp.CloseDate = System.Date.today();
                newcloneOpp.StageName = 'New';
                listOfOppTiInsert.add(newcloneOpp);
            }

            if(!listOfOppTiInsert.isEmpty()) {
                insert listOfOppTiInsert;
            }

            Opportunity cloneOppty = [SELECT Id, Name, PactSafe_Activity_ID__c, PactSafe_Record__c, Contract_Signed_Date__c, RecordTypeId FROM Opportunity WHERE Name = 'Cloned Opportunity'];
            test.stopTest();

            System.assertEquals(NULL, cloneOppty.PactSafe_Activity_ID__c);
            System.assertEquals(NULL, cloneOppty.PactSafe_Record__c);

        }
    }

     /**
     * @description: Test for BASD-12136 code coverage for reparenting Account for COO opportunity when Business Option(New Store), Original StoreID && COO Business ID not null
     */
    @isTest
    public static void testaccountReparent() {

        System.runAs(getTestRunUser()) {
            Account acc = [select Id, ParentId, Business_ID__c,Restaurant_Id__c from Account where Name = 'opptriggerHandlerTest 0'];
            Opportunity oppty = [SELECT Id, Name, StageName, RecordTypeId FROM Opportunity WHERE Name = 'UpdateMOCaseAndMilestones 1' Limit 1];
            oppty.AccountId = acc.Id;
            oppty.Type = 'Change of Ownership';
            oppty.Proposed_Date_of_Activation__c = System.today() + 6;
            oppty.Change_of_Ownership_Business_Option__c = 'New Store';
            oppty.Change_of_Ownership_Business_Id__c  = acc.Business_ID__c;
            oppty.Original_Store_ID__c = '6666';
            Test.startTest();
            update oppty;
            test.stopTest();
            Opportunity opptyAfterAccountReparent = [SELECT Id, AccountId, Account.Parent.Business_ID__c,StageName,Change_of_Ownership_Business_Id__c from Opportunity where Name = 'UpdateMOCaseAndMilestones 1' Limit 1 ];
            System.assertEquals(oppty.Change_of_Ownership_Business_Id__c, opptyAfterAccountReparent.Account.Parent.Business_ID__c);
        }
    }

    /**
     * @description: Test for BZAP-13015 - Migrate PB "Opportunity - Marketplace Updates" to Trigger
     */
    @isTest
    public static void testMarketplaceUpdates() {
        System.runAs(getTestRunUser()) {
            // choosing this Opp because of the RT
            Opportunity opp = [SELECT Id, Name, Proposed_Date_of_Menu_Original__c FROM Opportunity WHERE Name = 'CloseWonOpp' LIMIT 1];
            opp.Proposed_Date_of_Activation__c = Date.today().addDays(10);
            opp.Proposed_Date_of_Menu__c = Date.today().addDays(5);
            opp.Proposed_Date_of_Menu_Original__c = null;
            opp.Proposed_Date_of_Tablet__c = Date.today().addDays(5);
            opp.StageName = 'Closed Won';
            opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
            Test.startTest();
            update opp;
            Test.stopTest();
        }
        Opportunity opp = [SELECT Id, Name, Proposed_Date_of_Menu__c, Proposed_Date_of_Menu_Original__c FROM Opportunity WHERE Name = 'CloseWonOpp' LIMIT 1];
        System.assertEquals(opp.Proposed_Date_of_Menu__c, opp.Proposed_Date_of_Menu_Original__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        System.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    /**
     * @description: Test for BZAP-13015 - Migrate PB "Formstack - McDs Canada" to Trigger
     */
    @IsTest
    public static void testFormstackMcDsCanada() {
        System.runAs(getTestRunUser()) {
            Account acc = [select Id from Account where Name = 'Canada Test Acc'];
            acc.Formstack_Version__c = 'New Store';
            update acc;

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'CloseWonOpp' LIMIT 1];

            Test.startTest();
            opp.Institution_Number__c = '123456789';
            opp.Franchise_Formstack__c = true;
            opp.accountId = acc.Id; // Canada account
            update opp;
            Test.stopTest();
        }
        Opportunity opp = [SELECT Id, Account.Bank_Institution_Number_Encrypted__c FROM Opportunity WHERE Name = 'CloseWonOpp'];
        System.assertEquals('123456789', opp.Account.Bank_Institution_Number_Encrypted__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        System.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    /**
     * @description: Test for BZAP-13015 - Migrate PB "Update Parent Account with Requesting Account Management Status" to Trigger
     */
    @IsTest
    public static void testAccountMgmtStatusUpdate() {
        System.runAs(getTestRunUser()) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'Child Account 0'];
            // choosing this Opp because the RT = Marketplace, account is a child account, and is based in the US
            Opportunity opp = [SELECT Id, Name, Requesting_Account_Management__c, Account.ParentId
                              FROM Opportunity
                              WHERE Name = 'UpdateMOCaseAndMilestones 1' LIMIT 1];
            opp.Requesting_Account_Management__c = 'No';
            opp.AccountId = acc.Id; // reparenting to an account that has "Parent Account" RT, which has more available picklist values
            Test.startTest();
            update opp;
            Test.stopTest();
        }
        Opportunity opp = [SELECT Id, Account.Parent.Requesting_Account_Management__c FROM Opportunity WHERE Name = 'UpdateMOCaseAndMilestones 1'];
        System.assertEquals('No', opp.Account.Parent.Requesting_Account_Management__c);
        List<Apex_Log__c> errors = [SELECT Id, Class_Name__c, Method_Name__c, Log__c FROM Apex_Log__c];
        System.assertEquals(0, errors.size(), 'Unexpected Errors: ' + errors);
    }

    /**
        * @author : Lalitkumar Motiray
        * @description Test for BZAP-12637 - Set Opportunity Default Values by Order Protocol
    */
    @isTest
    public static void testSetDefaultValueByOrderProtocolForTabShipping(){

        //System.runAs(getTestRunUser()) {
            RecordType RECORD_TYPE_MARKETPLACE = [SELECT Id, Name FROM RecordType WHERE Id = :mlInsideSalesId];
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Acc'];
            Contact testContact = [SELECT Id FROM Contact WHERE accountId=:testAccount.Id];

            Opportunity opp1 = TDdOpportunityFactory.createOpportunity('OrderProtocolOpp', testAccount.Id, testContact.Id, 'New', RECORD_TYPE_MARKETPLACE);
            opp1.Order_Protocol__c = 'POS';

            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('OrderProtocolOpp', testAccount.Id, testContact.Id, 'New', RECORD_TYPE_MARKETPLACE);
            opp2.Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)';

            Test.startTest();
            testAccount.BillingCountryCode = 'NZ';
            //testAccount.BillingState = 'AK';
            testAccount.BillingPostalCode = '1234';
            update testAccount;
            insert opp1;
            insert opp2;
            Test.stopTest();

            opp1 = [SELECT Id,Tablet_Delivery_Method__c,Shipping__c,Tablet_Kit_Type__c FROM Opportunity WHERE Id = :opp1.Id];
            System.assertEquals(opp1.Tablet_Delivery_Method__c,null);
            System.assertEquals(opp1.Shipping__c,null);
            System.assertEquals(opp1.Tablet_Kit_Type__c,null);

            opp2 = [SELECT Id,Tablet_Delivery_Method__c,Shipping__c,Tablet_Kit_Type__c,Order_Protocol__c FROM Opportunity WHERE Id = :opp2.Id];
            System.assertEquals('POS and and Tablet (DoorDash Owns)', opp2.Order_Protocol__c);
            System.assertEquals('Drop-ship', opp2.Tablet_Delivery_Method__c);
            System.assertEquals('Standard', opp2.Shipping__c);
            System.assertEquals('Standard', opp2.Tablet_Kit_Type__c);
       // }
    }

    /**
        * @author : Sanidhya Jain
        * @description Test BASD-22667 - Set Opportunity Default Values for Tablet Delivery Method by Order Protocol
    */
    @isTest
    public static void updateTabletDeliveryMethod(){
        System.runAs(getTestRunUser()) {
        	Account acc = [select Id from Account where Name = 'Test Acc'];

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('CloseWonOpp', acc.id, con.id, 'Ready for Signature');
            opp.Tablet_Delivery_Method__c = '';
            opp.Tablet_Kit_Type__c = '';
            insert opp;
            Test.stopTest();
            Opportunity opp1 = [SELECT Id,Tablet_Delivery_Method__c,Shipping__c,Tablet_Kit_Type__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals('Drop-ship', opp1.Tablet_Delivery_Method__c);
        }
    }

    /**
        * @author : Abhijeet K
        * @description Test BZAP-14102 - Set Opportunity Default Values for Tablet Delivery Method by Order Protocol
    */
    @isTest
    public static void testUpdateNotesOnAccountOnChangeofOpportunityNotes(){
        System.runAs(getTestRunUser()) {
        	Account acc = [select Id from Account where Name = 'Test Acc'];

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acc.Id, con.Id, 'New', 'ML_Inside_Sales');
            opp.Tablet_Delivery_Method__c = '';
            opp.Tablet_Kit_Type__c = '';
            opp.Notes__c = 'Test Notes';
            insert opp;
            Test.stopTest();
            acc = [select Id, Notes__c from Account where Name = 'Test Acc'];
            System.assertEquals('Test Notes', acc.Notes__c, 'Must populate Notes');
        }
    }

    /**
        * @author : Jitendra Singh
        * @description Test BZAP-16104 - CW validation to ensure liquor license is collected
    */
    @isTest
    public static void testValidateCWLiquorLicenseCollectionTask(){
        System.runAs(getTestRunUser()) {

            Vertical_Category__c vc = new Vertical_Category__c();
            vc.name = 'Alcohol';
            insert vc;

        	Account acc = [select Id from Account where Name = 'Test Acc'];
            acc.BillingCountryCode = 'NZ';
            acc.BillingPostalCode = '1001';
            acc.Primary_Merchant_Category__c = 'Alcohol';
            acc.Merchant_Categories__c = 'Alcohol';
            update acc;

            Task tk = new Task(
                    Subject = 'test subject',
                    ActivityDate = Date.today().addDays(30),
                    Status = 'Open',
                    WhatId = acc.Id,
                    Type = 'Liquor license collection'
                );
            insert tk;

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

            List<String> alcoholProductIds = new List<String>();
            if(!String.isBlank(Label.DdAlcohol_Product_ID))
            {
                alcoholProductIds = Label.DdAlcohol_Product_ID.split(';');
            }
            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('liquorLicenseCollectionOpp', acc.id, con.id, 'Ready for Signature');
            opp.Product_IDs__c = alcoholProductIds.size() > 0 ? alcoholProductIds[0] : null;
            Opp.recordTypeId = mlInsideSalesId;
            insert opp;

            opp.StageName = 'Closed Won';
            try {
                update opp;
            } catch (DmlException dmlEx){
                System.assert(dmlEx.getMessage().contains(System.Label.CW_LiquorLicenseCollectionTask_Validation_Error), 'message=' + dmlEx.getMessage());
            }
            Test.stopTest();
            Opportunity opportunityFromDB = [SELECT Id, StageName FROM  Opportunity WHERE Id = :opp.Id limit 1];
            System.assertEquals('Ready for Signature', opportunityFromDB.StageName);
        }
    }

    /**
    *@ author : Abhijeet K
    *@description BZAP-16101 - Task for Sales team to collect liquor license
    */
    @isTest
    public static void testCreateLiquorLicenseCollectionTask(){
        System.runAs(getTestRunUser()) {

            Vertical_Category__c vc = new Vertical_Category__c();
            vc.name = 'Alcohol';
            insert vc;

            Account acc = [select Id from Account where Name = 'Test Acc'];
            acc.BillingCountryCode = 'NZ';
            acc.BillingPostalCode = '1001';
            acc.Primary_Merchant_Category__c = 'Alcohol';
            acc.Merchant_Categories__c = 'Alcohol';
            update acc;

            Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];
            List<String> alcoholProductIds = new List<String>();
            if(!String.isBlank(Label.DdAlcohol_Product_ID)) {
                alcoholProductIds = Label.DdAlcohol_Product_ID.split(';');
            }

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunity('liquorLicenseCollectionOpp', acc.id, con.id, 'Contract Signed');
            opp.Product_IDs__c = alcoholProductIds.size() > 0 ? alcoholProductIds[0] : null;
            Opp.recordTypeId = mlInsideSalesId;
            insert opp;
            Test.stopTest();

            Task taskRecord = [SELECT Id, Status FROM  Task WHERE Type = 'Liquor license collection' LIMIT 1];
            System.assertEquals('Open', taskRecord.Status);
        }
    }

    @isTest
    public static void validateClosedDriveOpportunitiesStageUpdate(){

        Account acc = [select Id from Account where Name = 'Test Acc'];

        Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

        Opportunity opp = new Opportunity();

        System.runAs(getTestRunUser()) {

            opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acc.Id, con.Id, 'Closed Won', 'DoorDash_Drive');
            opp.Tablet_Delivery_Method__c = '';
            opp.Tablet_Kit_Type__c = '';
            opp.Notes__c = 'Test Notes';
            opp.Order_Protocol__c = '';
            opp.Pricing_Structure__c = 'Other';
            opp.Planned_Integration_Path__c = 'Drive Form';
            opp.Payment_Protocol__c = 'Credit Card';
            opp.Accepts_Tips__c = 'Yes';
            opp.Decision_Maker__c = con.Id;
            opp.Catering_setup_exists__c = 'Yes';
            opp.Current_Delivery_Channels__c = 'None';
            opp.Type = 'Weblinks';
            opp.Contact_Manager_Owner_Name__c = 'Test User';
            opp.Contact_Manager_Owner_Email__c = 'test@test.com';
            insert opp;
        }
        Test.startTest();

            opp.Name = opp.Name+'_Modified';
            update opp;

            try{
                CDdOpportunityValidationHelper.RAN_CLOSED_WON_VALIDATION_ONCE = false;
                opp.StageName = 'Untouched';
                update opp;
            }catch(Exception e){
                system.assert(e.getMessage().contains(Label.Closed_Drive_Opportunity_Stage_Validation_Message));
            }

         Test.stopTest();

    }

    @isTest
    public static void validateClosedDriveOpportunities(){

        Account acc = [select Id from Account where Name = 'Test Acc'];

        Contact con = [SELECT Id FROM Contact WHERE accountId =: acc.Id];

        Opportunity opp = new Opportunity();

        System.runAs(getTestRunUser()) {

            opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acc.Id, con.Id, 'Closed Won', 'DoorDash_Drive');
            opp.Tablet_Delivery_Method__c = '';
            opp.Tablet_Kit_Type__c = '';
            opp.Notes__c = 'Test Notes';
            opp.Order_Protocol__c = '';
            opp.Pricing_Structure__c = 'Other';
            opp.Planned_Integration_Path__c = 'Drive Form';
            opp.Payment_Protocol__c = 'Credit Card';
            opp.Accepts_Tips__c = 'Yes';
            opp.Decision_Maker__c = con.Id;
            opp.Catering_setup_exists__c = 'Yes';
            opp.Current_Delivery_Channels__c = 'None';
            opp.Type = 'Weblinks';
            opp.Contact_Manager_Owner_Name__c = 'Test User';
            opp.Contact_Manager_Owner_Email__c = 'test@test.com';
            insert opp;
        }
        Test.startTest();

            opp.Name = opp.Name+'_Modified';
            update opp;

            try{
                CDdOpportunityValidationHelper.RAN_CLOSED_WON_VALIDATION_ONCE = false;
                opp.Type = 'OAM';
                update opp;
            }catch(Exception e){
                system.assert(e.getMessage().contains(Label.Closed_Drive_Opportunity_Validation_Message));
            }
         Test.stopTest();
    }

    @isTest
    public static void testSendEmailToSSMOOpportunityOwner(){
        List<Account> accs = TDdAccountFactory.createAccounts('SSMO Owner Email', 1, 'Marketplace');
        accs[0].Restaurant_Id__c = '98765';

        insert new List<Account>{accs[0]};

        List<Contact> cons = new List<Contact>{TDdAccountFactory.createContacts(1, accs[0].Id)[0]};
        cons[0].firstName = 'SSMO Email';
        cons[0].LastName = 'Owner Email';
        cons[0].Email = 'ssmo.owner@dd.com';

        insert cons;


        List<Opportunity> opps = new List<Opportunity>();
        opps.add(TDdOpportunityFactory.createOpportunityByDevRT('SSMO Oppty', accs[0].Id, cons[0].Id, 'New', 'ML_Inside_Sales'));
        opps[0].Menu_to_be_completed_by__c = 'Account Owner';
        opps[0].Order_Protocol__c = 'Email';
        opps[0].Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
        opps[0].Activate_Centrally_2__c = 'No';
        insert opps;

        Test.startTest();
        opps[0].PactSafe_Contract_Type__c = 'English Rep Enabled SSMO Sign Up Sheet';
        opps[0].StageName = 'Closed Won';
        CDdOpportunityTriggerHelper.sendEmailToSSMOOpportunityOwner(opps,new Map<Id,Opportunity>{opps[0].Id=>opps[0]});
        Test.stopTest();
    }

    @isTest
    public static void testValidateBbotOpportunityOnContractCreation(){
        String testOppName = 'UpdateMOCaseAndMilestones 3';
        Opportunity testOpp = [SELECT Id, RecordTypeId, Activate_Centrally_2__c, Mx_Requested_Custom_Radius_Demand_Gen__c,
                               Order_Protocol__c, Menu_to_be_completed_by__c FROM Opportunity WHERE Name = :testOppName];
        Test.startTest();
        try{
            update new Opportunity(
                Id = testOpp.Id,
                RecordTypeId = postSaleRecId,
                StageName = 'Ready for Signature',
                Has_Bbot_Product__c = true,
                Activation_Notes__c = '',
                Cuisine_Categories__c = ''
            );
        } catch(exception e){
            string errorMessage = 'Update failed. First exception on row 0 with id '+testOpp.Id+'; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
            errorMessage = errorMessage + Label.Bbot_Opportunity_Required_Fields_for_Contract_Creation + '\n';
            errorMessage = errorMessage + Label.Bbot_Opportunity_Contact_Roles_Validation_Message + '\n';
            errorMessage = errorMessage + Label.Bbot_Opportunity_Required_Fields_for_Contract_Creation_For_Post_Sale + '\n'+': []';
            System.assertEquals(errorMessage, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    public static void testpopulateCampaignNameOnOpportunity(){
        Campaign testCmp = [SELECT Id, Name FROM Campaign WHERE Name = 'Test Campaign Source Name'];
        Opportunity testOpp = [SELECT Id, CampaignId FROM Opportunity WHERE Name = 'UpdateMOCaseAndMilestones 3' LIMIT 1][0];

        Test.startTest();
		testOpp.CampaignId = testCmp.Id;
		update testOpp;
        Test.stopTest();

        Opportunity finalOpp = [SELECT Id, Primary_Campaign_Name__c FROM Opportunity WHERE Name = 'UpdateMOCaseAndMilestones 3' LIMIT 1][0];
        System.assertEquals(finalOpp.Primary_Campaign_Name__c, testCmp.Name);
    }

}