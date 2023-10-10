@isTest
public class CDdCaseAdsAndPromoListControllerTest {
    public static final Id ADS_AND_PROMOS_RT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get(CDdCaseAdsAndPromoListController.ADS_PROMO_TYPE).getRecordTypeId();
    public static final Id ACTIVATE_STORE_RT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get(CDdCaseAdsAndPromoListController.ACTIVATE_STORE_TYPE).getRecordTypeId();
    public static final Id ACTIVATIONS_CHECKLIST_RT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get(CDdCaseAdsAndPromoListController.ACTIVATIONS_CHECKLIST_TYPE).getRecordTypeId();

    @TestSetup
    static void createData(){
        Account account = TDdAccountFactory.createAccount();
        insert account;

        Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
        insert contact;

        Opportunity opportunity = TDdOpportunityFactory.createOpportunity('Test', account.Id, contact.Id, 'New', 'Pipeline',UserInfo.getUserId());
        insert opportunity;

        Id onboardingCaseRT  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();
        List<Case> caseRecord = CDdTestDataFactory.createSObjectList('Case', 1, false);
        caseRecord[0].Store_ID__c = '0';
        caseRecord[0].BusinessHours =null;
        caseRecord[0].Subject = 'setAccountIdUpdateTest0';
        caseRecord[0].RecordTypeId = onboardingCaseRT;
        caseRecord[0].Photo_Review_Notes__c = 'OCUS';
        caseRecord[0].Language__c = 'English';
        caseRecord[0].AccountId = account.Id;
        caseRecord[0].Opportunity_Name__c = opportunity.Id;
        caseRecord[0].stage__c = 'Ready for Activation';
        insert caseRecord[0];

        List<Id> milestoneIds = new List<Id>{ADS_AND_PROMOS_RT, ACTIVATE_STORE_RT, ACTIVATIONS_CHECKLIST_RT};
        List<Milestone__c> milestones = new List<Milestone__c>();
        string status = 'Not Started';
        for(Id milestoneId: milestoneIds){
            Milestone__c mil = new Milestone__c();
            mil.recordtypeid = milestoneId;
            mil.Status__c = status;
            mil.case__c = caseRecord[0].Id;
            milestones.add(mil);
        }
        insert milestones;

        SBQQ.TriggerControl.disable();

        Product2 product = TDdCPQTestDataFactory.createProduct(false);
        product.Family = 'Advertisement';
        insert product;

        PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, 'USD', true);

        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opportunity, account, null, true);
        SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
        quoteLine.Trial_Period__c = '60';
        insert quoteLine;

        Order order = TDdCPQTestDataFactory.createOrder(account, opportunity, quote, false);
        order.EndDate = null;
        insert order;

        OrderItem orderProduct = TDdCPQTestDataFactory.createOrderItem(order, quoteLine, pbe.Id, true);
        SBQQ.TriggerControl.enable();
    }

    @isTest
    static void test_validateComponentVisibility_false(){
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseRec.Id);
        Test.stopTest();
        System.assertEquals(false, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should not be visible');
    }

    @isTest
    static void test_validateComponentVisibility_store_true(){
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Milestone__c milestone = [SELECT Id, Status__c FROM Milestone__c WHERE recordtypeid =: ACTIVATE_STORE_RT];
        milestone.status__c = CDdCaseAdsAndPromoListController.MILESTONE_STATUS;
        update milestone;
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseRec.Id);
        Test.stopTest();
        System.assertEquals(true, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should be visible');
    }

    @isTest
    static void test_validateComponentVisibility_checklist_false(){
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Milestone__c milestone = [SELECT Id, Status__c FROM Milestone__c WHERE recordtypeid =: ACTIVATIONS_CHECKLIST_RT];
        milestone.status__c = CDdCaseAdsAndPromoListController.MILESTONE_STATUS;
        update milestone;
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseRec.Id);
        Test.stopTest();
        System.assertEquals(false, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should not be visible');
    }

    @isTest
    static void test_validateComponentVisibility_checklist_true(){
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Milestone__c storeMilestone = [SELECT Id, Status__c FROM Milestone__c WHERE recordtypeid =: ACTIVATE_STORE_RT];
        delete storeMilestone;
        Milestone__c milestone = [SELECT Id, Status__c FROM Milestone__c WHERE recordtypeid =: ACTIVATIONS_CHECKLIST_RT];
        milestone.status__c = CDdCaseAdsAndPromoListController.MILESTONE_STATUS;
        update milestone;
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseRec.Id);
        Test.stopTest();
        System.assertEquals(true, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should be visible');
    }

    @isTest
    static void test_getOrderItems(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<OrderItem> orderItems = CDdCaseAdsAndPromoListController.getOrderItems(opp.Id);
        Test.stopTest();
        System.assertEquals(1, orderItems.size(),'Order Items are not retrieved as expected');
    }
}