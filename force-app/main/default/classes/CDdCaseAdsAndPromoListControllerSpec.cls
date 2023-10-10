/*
@author: Krishna Sanisetty
@date: 10/07/2022
@description: created this test class as a Unit Test for the CDdCaseAdsAndPromoListController class.
*/
@isTest
private class CDdCaseAdsAndPromoListControllerSpec {
    static final string NOT_STARTED_STATUS = 'Not Started';
    static Milestone__c getMilestoneMock(String status, String recordTypeName){
        Milestone__c milestoneFake = (Milestone__c)new Fake(Milestone__c.class)
            .setFakeId()
            .setField(Milestone__c.status__c, status)
            .setParent('RecordType', new Fake(RecordType.class).setField(RecordType.Name,recordTypeName))
            .toSObject();
        return milestoneFake;
    }

    @isTest
    static void testWhenTheAdsAndPromosMilestoneAloneExistsThenItShouldReturnFalse(){
        Id caseId = Fake.generateId(Case.SObjectType);

        List<Milestone__c> milestones = new List<Milestone__c>{
            getMilestoneMock(NOT_STARTED_STATUS, CDdCaseAdsAndPromoListController.ADS_PROMO_TYPE)
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IMilestonesSelector selectorMock = (IMilestonesSelector) mocks.mock(IMilestonesSelector.class);
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Milestone__c.SObjectType);
        mocks.when(
            	selectorMock.selectByCaseIdAndRecordTypeName(new Set<Id>{caseId},CDdCaseAdsAndPromoListController.RECORDTYPE_SET)
        	)
            .thenReturn(milestones);
        mocks.stopStubbing();

        Application.SELECTOR.setMock(selectorMock);

        Test.startTest();
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseId);
        Test.stopTest();

        System.assertEquals(false, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should not be visible');
    }

    @isTest
    static void testWhenTheAdsAndPromosAndActivateStoreTypeMilestonseInCompleteStatusExistsThenItShouldReturnTrue(){
        Id caseId = Fake.generateId(Case.SObjectType);
        List<Milestone__c> milestones = new List<Milestone__c>{
            getMilestoneMock(NOT_STARTED_STATUS, CDdCaseAdsAndPromoListController.ADS_PROMO_TYPE),
            getMilestoneMock(CDdCaseAdsAndPromoListController.MILESTONE_STATUS, CDdCaseAdsAndPromoListController.ACTIVATE_STORE_TYPE)
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IMilestonesSelector selectorMock = (IMilestonesSelector) mocks.mock(IMilestonesSelector.class);
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Milestone__c.SObjectType);
        mocks.when(
            	selectorMock.selectByCaseIdAndRecordTypeName(new Set<Id>{caseId},CDdCaseAdsAndPromoListController.RECORDTYPE_SET)
        	)
            .thenReturn(milestones);
        mocks.stopStubbing();

        Application.SELECTOR.setMock(selectorMock);

        Test.startTest();
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseId);
        Test.stopTest();

        System.assertEquals(true, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should be visible');
    }

    @isTest
    static void testWhenAllThreeTypesOfMilestonesExistsAndActivationsChecklistInCompleteStatusExistsThenItShouldReturnTrue(){
        Id caseId = Fake.generateId(Case.SObjectType);
        List<Milestone__c> milestones = new List<Milestone__c>{
            getMilestoneMock(NOT_STARTED_STATUS, CDdCaseAdsAndPromoListController.ADS_PROMO_TYPE),
            getMilestoneMock(NOT_STARTED_STATUS, CDdCaseAdsAndPromoListController.ACTIVATE_STORE_TYPE),
            getMilestoneMock(CDdCaseAdsAndPromoListController.MILESTONE_STATUS, CDdCaseAdsAndPromoListController.ACTIVATIONS_CHECKLIST_TYPE)
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IMilestonesSelector selectorMock = (IMilestonesSelector) mocks.mock(IMilestonesSelector.class);
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Milestone__c.SObjectType);
        mocks.when(
            	selectorMock.selectByCaseIdAndRecordTypeName(new Set<Id>{caseId},CDdCaseAdsAndPromoListController.RECORDTYPE_SET)
        	)
            .thenReturn(milestones);
        mocks.stopStubbing();

        Application.SELECTOR.setMock(selectorMock);

        Test.startTest();
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseId);
        Test.stopTest();

        System.assertEquals(false, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should not be visible');
    }

    @isTest
    static void testWhenAdsAndPromoExistsAndActivationsChecklistMilstoneAloneExistsInCompleteStatusThenItShouldReturnTrue(){
        Id caseId = Fake.generateId(Case.SObjectType);
        List<Milestone__c> milestones = new List<Milestone__c>{
            getMilestoneMock(NOT_STARTED_STATUS, CDdCaseAdsAndPromoListController.ADS_PROMO_TYPE),
            getMilestoneMock(CDdCaseAdsAndPromoListController.MILESTONE_STATUS, CDdCaseAdsAndPromoListController.ACTIVATIONS_CHECKLIST_TYPE)
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IMilestonesSelector selectorMock = (IMilestonesSelector) mocks.mock(IMilestonesSelector.class);
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Milestone__c.SObjectType);
        mocks.when(
            	selectorMock.selectByCaseIdAndRecordTypeName(new Set<Id>{caseId},CDdCaseAdsAndPromoListController.RECORDTYPE_SET)
        	)
            .thenReturn(milestones);
        mocks.stopStubbing();

        Application.SELECTOR.setMock(selectorMock);

        Test.startTest();
        Map<String, boolean> isComponentVisibleMap = CDdCaseAdsAndPromoListController.validateComponentVisibility(caseId);
        Test.stopTest();

        System.assertEquals(true, isComponentVisibleMap.get(CDdCaseAdsAndPromoListController.VALIDITY_MAP_KEY_NAME), 'Datatable component should be visible');
    }

    @isTest
    static void test_getOrderItems(){
        Id opportunityId = Fake.generateId(Opportunity.SObjectType);
        String fakeProductName = 'Fake Name';

        Order fakeOrder = (Order)new Fake(order.class)
            .setFakeId()
            .setField(Order.opportunityId, opportunityId)
            .toSObject();

        OrderItem fakeOrderItem = (OrderItem)new Fake(OrderItem.class)
            .setFakeId()
            .setField(OrderItem.orderId, fakeOrder.Id)
            .setField(OrderItem.Product2Id, Fake.generateId(Product2.SObjectType))
            .setParent('Product2', new Fake(Product2.class).setField(Product2.Name,fakeProductName))
            .toSObject();

        List<OrderItem> orderItems = new List<OrderItem>{fakeOrderItem};

        fflib_ApexMocks mocks = new fflib_ApexMocks();

        IOrderItemsSelector orderItemsSelectorMock = (IOrderItemsSelector) mocks.mock(IOrderItemsSelector.class);
		mocks.startStubbing();
        mocks.when(orderItemsSelectorMock.sObjectType()).thenReturn(OrderItem.SObjectType);
        mocks.when(
                orderItemsSelectorMock.selectByOrderIdAndProductFamily(new Set<Id>{opportunityId}, CDdCaseAdsAndPromoListController.PRODUCT_FAMILY)
            )
            .thenReturn(orderItems);
        mocks.stopStubbing();
        Application.SELECTOR.setMock(orderItemsSelectorMock);

        Test.startTest();
        List<OrderItem> orderItemsRes = CDdCaseAdsAndPromoListController.getOrderItems(opportunityId);
        Test.stopTest();

        ((IOrderItemsSelector) mocks.verify(orderItemsSelectorMock,1)).selectByOrderIdAndProductFamily(new Set<Id>{opportunityId}, CDdCaseAdsAndPromoListController.PRODUCT_FAMILY);
        System.assertEquals(1, orderItemsRes.size(),'Order Items are not retrieved as expected');
    }
}