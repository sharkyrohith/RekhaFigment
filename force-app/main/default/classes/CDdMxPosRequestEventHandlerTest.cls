/**
    @author: Dan Thoreson
    @date: 20-Jan-2023
    @group: Mx Services
    @description: Test class for CDdMxPosRequestEventHandler
**/
@IsTest
private class CDdMxPosRequestEventHandlerTest {

    private static fflib_ApexMocks mocks {get {
        if(mocks == null) {
            mocks = new fflib_ApexMocks();
        }

        return mocks;
    } set;}

    private static MxSxApexMockTestDataFactory mockDataFactory {get {
        if(mockDataFactory == null) {
            mockDataFactory = new MxSxApexMockTestDataFactory();
        }

        return mockDataFactory;
    } set;}

    private static ICasesSelector casesSelectorMock {get {
        if(casesSelectorMock == null) {
            casesSelectorMock = (ICasesSelector) mocks.mock(ICasesSelector.class);
        }

        return casesSelectorMock;
    } set;}

    private static IOpportunitiesSelector oppsSelectorMock {get {
        if(oppsSelectorMock == null) {
            oppsSelectorMock = (IOpportunitiesSelector) mocks.mock(IOpportunitiesSelector.class);
        }

        return oppsSelectorMock;
    } set;}

    private static Opportunity defaultTestOpportunity {get {
        if(defaultTestOpportunity == null) {
            defaultTestOpportunity = mockDataFactory.marketplaceOpportunity;
            defaultTestOpportunity.POS_Fallback_Protocol__c = 'Cancel';
            defaultTestOpportunity.Proposed_Date_of_Activation__c = System.today().addDays(14);
        }

        return defaultTestOpportunity;
    } set;}

    @IsTest
    static void testPosIntegrationsCaseQueueId() {
        Id expectedQueueId = [SELECT Id FROM Group
                            WHERE Type = 'Queue'
                            AND DeveloperName = :CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION
                            LIMIT 1].Id;

        // Verify that we get the POS Integrations Queue ID from our getter, and verify that, no matter how many times it's called, we only use one query.
        Id actualQueueId;
        Integer queriesBefore = Limits.getQueries();

        for(Integer i = 0; i < 100; i++) {
            actualQueueId = CDdMxPosRequestEventHandler.posIntegrationsCaseQueueId;
        }

        Integer queriesAfter = Limits.getQueries();

        System.assertEquals(expectedQueueId, actualQueueId, 'The POS Integrations Queue ID was not correctly returned.');
        System.assert((queriesAfter - queriesBefore) <= 1, 'The Queue ID retrieval code should be optimized where, at most, one query should be used to get the POS Integrations Queue ID');
    }

    @IsTest
    static void testUnpackPosRequestEvents() {
        List<Opportunity> opportunities = new List<Opportunity>{ defaultTestOpportunity };

        mocks.startStubbing();
            mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
            mocks.when(casesSelectorMock.selectCasesWithMilestonesByRecordTypeAndGenericParent(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(),
                                                                                                'Opportunity_Name__c',
                                                                                                new Set<Id>{ defaultTestOpportunity.Id }))
                                        .thenReturn(new List<Case>{ mockDataFactory.marketplaceOnboardingCase });

            mocks.when(oppsSelectorMock.sObjectType()).thenReturn(Opportunity.SObjectType);
            mocks.when(oppsSelectorMock.selectByIdExtraFields(new Set<Id>{ defaultTestOpportunity.Id }, new Set<String> { 'Activation_Case_Created__c' }))
                                        .thenReturn(new List<Opportunity>{ defaultTestOpportunity });
        mocks.stopStubbing();

        Application.Selector.setMock(casesSelectorMock);
        Application.Selector.setMock(oppsSelectorMock);

        // Mock POS Request Platform Events (MxSx_Event__e)
        List<MxSx_Event__e> mockPosEvents = mockPosRequestEvents(opportunities);

        mocks.startStubbing();
            mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
            mocks.when(casesSelectorMock.selectCasesWithMilestonesByRecordTypeAndGenericParent(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(),
                                                                                                'Opportunity_Name__c',
                                                                                                new Set<Id>{ defaultTestOpportunity.Id }))
                                        .thenReturn(new List<Case>{ mockDataFactory.marketplaceOnboardingCase });
        mocks.stopStubbing();

        fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);

        Application.UnitOfWork.setMock(mockUow);

        // Call method which processes the POS Request Events
        Test.startTest();
            CDdMxPosRequestEventHandler.unpackPosRequestEvents(mockPosEvents);
        Test.stopTest();

        verifyPosCaseCreation(mockUow);
        System.assertNotEquals(null, mockUow);
    }

    @IsTest
    static void testHandleEventsForPosRequests() {
        fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUow);

        mocks.startStubbing();
            mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);

            mocks.when(casesSelectorMock.selectById(new Set<Id>{ mockDataFactory.marketplaceOnboardingCase.Id })).thenReturn(new List<Case>{ mockDataFactory.marketplaceOnboardingCase });

            mocks.when(casesSelectorMock.selectCasesWithMilestonesByRecordTypeAndGenericParent(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(),
                                                                                                'Opportunity_Name__c',
                                                                                                new Set<Id>{ defaultTestOpportunity.Id }
                                                                                               )).thenReturn(new List<Case>{ mockDataFactory.marketplaceOnboardingCase });

            mocks.when(oppsSelectorMock.sObjectType()).thenReturn(Opportunity.SObjectType);
            mocks.when(oppsSelectorMock.selectByIdExtraFields(new Set<Id>{ defaultTestOpportunity.Id }, new Set<String> { 'Activation_Case_Created__c' }))
                                        .thenReturn(new List<Opportunity>{ defaultTestOpportunity });
        mocks.stopStubbing();

        Application.Selector.setMock(casesSelectorMock);
        Application.Selector.setMock(oppsSelectorMock);

        List<MxSx_Event__e> mockPosEvents = mockPosRequestEvents(new List<Opportunity>{ defaultTestOpportunity });

        Test.startTest();
            CDdMxSxEventHandler.handleEventsForPosRequests(mockPosEvents);
        Test.stopTest();

        verifyPosCaseCreation(mockUow);
        System.assertNotEquals(null, mockUow);
    }

    @IsTest
    static void testHandleEventsForPosRequestsForCaviarCases() {
        fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUow);

        Case caviarOnboardingCase = new Case(Id = fflib_IDGenerator.generate(Case.getSObjectType()),
                                                Opportunity_Name__c = defaultTestOpportunity.Id,
                                                RecordTypeId=CDdSchemaUtils.CASE_RT.caviarOnboardingId(),
                                                Status = CDdSupportConstants.NEW_STATUS,
                                                Priority = CDdSupportConstants.MEDIUM_PRIORITY,
                                                Origin = CDdMxSxConstants.CASE_ORIGIN_OPP_CLOSED_WON);

        mocks.startStubbing();
            mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);

            mocks.when(casesSelectorMock.selectById(new Set<Id>{ caviarOnboardingCase.Id })).thenReturn(new List<Case>{ caviarOnboardingCase });

            Set<String> extraFields = new Set<String>{
                'Order_Protocol__c',
                'Store_ID__c',
                'POS_Integration_Type__c',
                'POS_Integration_ID__c',
                'Opportunity_Account_Name__c',
                'Notes__c',
                'Decision_Maker__c',
                'Proposed_Date_of_Activation__c',
                'POS_Fallback_Protocol__c',
                'CreatedById'
            };

            mocks.when(oppsSelectorMock.sObjectType()).thenReturn(Opportunity.SObjectType);
            mocks.when(oppsSelectorMock.selectByIdExtraFields(new Set<Id>{ defaultTestOpportunity.Id }, extraFields))
                                        .thenReturn(new List<Opportunity>{ defaultTestOpportunity });

            mocks.when(oppsSelectorMock.selectByIdExtraFields(new Set<Id>{ defaultTestOpportunity.Id }, new Set<String> { 'Activation_Case_Created__c' }))
                                        .thenReturn(new List<Opportunity>{ defaultTestOpportunity });

        mocks.stopStubbing();

        Application.Selector.setMock(casesSelectorMock);
        Application.Selector.setMock(oppsSelectorMock);

        List<MxSx_Event__e> mockPosEvents = mockPosRequestEvents(new List<Case>{ caviarOnboardingCase });

        Test.startTest();
            CDdMxSxEventHandler.handleEventsForPosRequests(mockPosEvents);
        Test.stopTest();

        verifyCase(mockUow, defaultTestOpportunity, caviarOnboardingCase);
        System.assertNotEquals(null, mockUow);
    }

    private static void verifyPosCaseCreation(fflib_ISObjectUnitOfWork mockUow) {
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).commitWork();

        verifyCase(mockUow, defaultTestOpportunity, mockDataFactory.marketplaceOnboardingCase);

        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Opportunity.Activation_Case_Created__c => true,
            Opportunity.Id => defaultTestOpportunity.Id
        }));
    }

    private static void verifyCase(fflib_ISObjectUnitOfWork mockUow, Opportunity thisOpp, Case parentCase) {
        // Verify the values are set properly
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerNew(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Case.RecordTypeId => CDdSchemaUtils.CASE_RT.posIntegrationsId(),
            Case.AccountId => thisOpp.AccountId,
            Case.Opportunity_Name__c => thisOpp.Id,
            Case.OwnerId => CDdMxPosRequestEventHandler.posIntegrationsCaseQueueId,
            Case.Priority => 'Normal',
            Case.POS_Integration_Type__c => thisOpp.POS_Integration_Type__c,
            Case.ParentId => parentCase.Id,
            Case.POS_Integration_ID__c => thisOpp.POS_Integration_ID__c,
            Case.POS_Fallback_Protocol__c => thisOpp.POS_Fallback_Protocol__c,
            Case.Due_Date__c => thisOpp.Proposed_Date_of_Activation__c,
            Case.Go_Live_Date__c => thisOpp.Proposed_Date_of_Activation__c,
            Case.OwnerId => CDdMxSxOpportunityHelper.isSelfServe(thisOpp) && ('square'.equalsIgnoreCase(thisOpp.POS_Integration_Type__c) || 'toast'.equalsIgnoreCase(thisOpp.POS_Integration_Type__c))?
        CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Onboarding_SSMO_Square_POS'): CDdMxPosRequestEventHandler.posIntegrationsCaseQueueId,
            Case.Origin => CDdMxSxOpportunityHelper.isSelfServe(thisOpp)? CDdMxSxConstants.SELF_SERVE_CASE_ORIGIN : CDdSupportConstants.ORIGIN_PROTOCOL_CHANGE
        }));
    }

    private static List<MxSx_Event__e> mockPosRequestEvents(List<SObject> records) {
        List<MxSx_Event__e> posEvents = new List<MxSx_Event__e>();

        if(records == null || records.isEmpty()) {
            return posEvents;
        }

        Boolean fromCase = records instanceof List<Case>;

        if(fromCase) {
            CDdMxSxPOSRequestWrappers.setOpportunityIdsAndMarketplaceCaseIds((List<Case>) records);
        } else {
            CDdMxSxPOSRequestWrappers.setMarketplaceOpportunityIdsForCaseRetrieval(new Map<Id, Opportunity>((List<Opportunity>) records).keySet());
        }

        for(SObject thisRecord : records) {
            if(fromCase) {
                posEvents.add(initMxSxPosEvent((Case) thisRecord));
            } else {
                posEvents.add(initMxSxPosEvent((Opportunity) thisRecord));
            }
        }

        return posEvents;
    }

    private static MxSx_Event__e initMxSxPosEvent(SObject record) {
        MxSx_Event__e thisEvent = new MxSx_Event__e();
        thisEvent.Event_Name__c = String.valueOf(CDdMxSxConstants.MXSX_EVENT.POS_INTEGRATION_REQUEST).toUpperCase();
        return setEventValuesFromSObjectRecord(thisEvent, record);
    }

    private static MxSx_Event__e setEventValuesFromSObjectRecord(MxSx_Event__e thisEvent, SObject record) {
        if(record instanceof Case) {
            Case thisCase = (Case) record;

            thisEvent.SObject_Id__c = thisCase?.Id;
            thisEvent.SObject_Type__c = CDdMxSxConstants.SOBJECT_TYPE_CASE;
            thisEvent.Payload__c = (thisCase != null) ? JSON.serialize(new CDdMxSxPOSRequestWrappers.POSRequest(thisCase)) : '{}';
        } else {
            Opportunity thisOpp = (Opportunity) record;

            thisEvent.SObject_Id__c = thisOpp?.Id;
            thisEvent.SObject_Type__c = CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY;
            thisEvent.Payload__c = (thisOpp != null) ? JSON.serialize(new CDdMxSxPOSRequestWrappers.POSRequest(thisOpp)) : '{}';
        }

        return thisEvent;
    }
}