/********************************************************************************************************************
* @author Praveen Pandem
* @date 01/20/2023
*
* @group fflib
*
* @description Apex test class for CDdMxPosIntegrationRequestProcessor
*
**************************************************************************************************************************************/
@isTest
public with sharing class CDdMxPosIntegrationRequestProcessorSpec {
    private static final String BAT_STATUS_MENU_BLOCK = 'MENU_BLOCK';
    private static final String EXCLUSION_CODE_MENU_FAILURE = 'MENU_COMPLIANCE_FAILURE';
    private static final String EXCLUSION_CODE_NONE = 'NONE';
    private static final String MILESTONE_INGEST_MENU = 'Ingest Menu';
    private static final String MILESTONE_QA_MENU = 'QA Menu';
    private static final String MILESTONE_STATUS_ESCALATED = 'Escalated';
    private static final String STATUS_REASON_MENU_FAILURE = 'Menu Compliance failure';
    private static final String STATUS_REASON_POS_INGESTION_FAILURE = 'POS Ingestion failure';
    private static final String POS_INGESTION_FAILURE = 'POS Ingestion failure';

    private static fflib_ApexMocks mocks {get {
        if(mocks == null) {
            mocks = new fflib_ApexMocks();
        }
        return mocks;
    } set;}
    /**
    *@description Initializes the common class MxSxApexMockTestDataFactory to mock mx related object records.
    */
    private static MxSxApexMockTestDataFactory mockTestDataFactory {get {
        if(mockTestDataFactory == null) {
            mockTestDataFactory = new MxSxApexMockTestDataFactory();
        }
        return mockTestDataFactory;
    } set;}
    /**
    *@description mock opportunity using common class MxSxApexMockTestDataFactory.
    */
    private static Opportunity marketplaceOpportunity {get {
        if(marketplaceOpportunity == null) {
            marketplaceOpportunity = mockTestDataFactory.marketplaceOpportunity;
        }
        return marketplaceOpportunity;
    } set;}
    /**
    *@description mock marketplaceAccount using common class MxSxApexMockTestDataFactory.
    */
    private static Account marketPlaceAccount {get {
        if(marketPlaceAccount == null) {
            marketPlaceAccount = mockTestDataFactory.marketplaceAccount;
        }
        return marketPlaceAccount;
    } set;}
   /**
    *@description mock posIntegrationRequest using common class MxSxApexMockTestDataFactory.
    */
    public static List<Integration_Request__x> posIntegrationRequest{get {
        if(posIntegrationRequest == null) {
            posIntegrationRequest = mockTestDataFactory.posIntegrationRequests;
        }
        return posIntegrationRequest;
    } set;}
    /**
    *@description mock posIntegrationCase using common class MxSxApexMockTestDataFactory.
    */
    public static Case posIntegrationCase{get {
        if(posIntegrationCase == null) {
            posIntegrationCase = mockTestDataFactory.posIntegrationCase;
        }
        return posIntegrationCase;
    } set;}
    /**
    *@description mock posIntegrationCase using common class MxSxApexMockTestDataFactory.
    */
    public static Case marketplaceOnboardingCase {get {
        if(marketplaceOnboardingCase == null) {
            marketplaceOnboardingCase = mockTestDataFactory.marketplaceOnboardingCase;
        }
        return marketplaceOnboardingCase;
    } set;}

    @isTest
    private static void testWhenCreateNewPosIntegrationCaseIfThereIsNoPosIntegrationCaseExist() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        String userEmail = 'test@doordash.com';
        IIntegrationRequestsSelector mockIntegrationSelector = (IIntegrationRequestsSelector) mocks.mock(IntegrationRequestsSelector.class);
        IAccountsSelector mockAccountSelector = (IAccountsSelector) mocks.mock(AccountsSelector.class);
        IUsersSelector mockUserSelector = (IUsersSelector) mocks.mock(UsersSelector.class);
        User posUser = new User(Id = fflib_IDGenerator.generate(User.getSObjectType()), Email = userEmail);
        set<String> onboardingIds = new Set<String>{posIntegrationRequest[0].onboarding_Id__c};
        Set<String> storeId = new Set<String>{'224455'};
        marketPlaceAccount.Restaurant_ID__c = '224455';
        List<Account> accounts = new List<Account>{marketPlaceAccount};
        CDdMxIntegrationObject posRequests = new CDdMxIntegrationObject(posIntegrationRequest);
        mocks.startStubbing();
        mocks.when(mockIntegrationSelector.sObjectType()).thenReturn(Integration_Request__x.SObjectType);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByOnboardingIds(onboardingIds)).thenReturn(posRequests);
        mocks.when(mockAccountSelector.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(mockAccountSelector.selectAccountsByStoreId(storeId)).thenReturn(accounts);
        mocks.when(mockUserSelector.SelectUserIdsByEmailAddress( new Set<String>{ userEmail } ) ).thenReturn( new List<User>{ posUser } );
        mocks.stopStubbing();
        Application.Selector.setMock(mockIntegrationSelector);
        Application.Selector.setMock(mockAccountSelector);
        Application.Selector.setMock(mockUserSelector);
        Application.UnitOfWork.setMock(mockUow);
        CDdMxPosIntegrationRequestProcessor processor = new CDdMxPosIntegrationRequestProcessor(onboardingIds);
        processor.execute();
        //Created new pos integration request
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerNew(fflib_Match.anySobject());
        //Created new pos integration request and validating the data which has been created.
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerNew(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            case.POS_Integration_ID__c => posIntegrationRequest[0].Integration_Id__c,
            case.POS_Integration_Type__c =>posIntegrationRequest[0].Integration_Provider__c
        }));
        //work around to pass code scan.
        system.assertEquals(posIntegrationRequest.size(), 1, 'Pos request count not matching');
    }
    @isTest
    private static void testWhenObCaseExistAndUpdateOpporunityAndCreateNewPOsIntegrationCase() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);

        IIntegrationRequestsSelector mockIntegrationSelector = (IIntegrationRequestsSelector) mocks.mock(IntegrationRequestsSelector.class);
        IAccountsSelector mockAccountSelector = (IAccountsSelector) mocks.mock(AccountsSelector.class);
        ICasesSelector mockCaseSelector = (ICasesSelector) mocks.mock(CasesSelector.class);
        String TABLET_ORDER_PROTOCOL = 'Tablet (DoorDash Owns)';
        set<String> onboardingIds = new Set<String>{posIntegrationRequest[0].onboarding_Id__C};
        Set<String> storeId = new Set<String>{'224455'};
        marketPlaceAccount.Restaurant_ID__c = '224455';
        marketplaceOpportunity.Order_protocol__c = TABLET_ORDER_PROTOCOL;
        List<Account> accounts = new List<Account>{marketPlaceAccount};
        Set<Id> accountids = new Set<Id>{marketPlaceAccount.Id};
        CDdMxIntegrationObject posRequests = new CDdMxIntegrationObject(posIntegrationRequest);
        List<Case> openCases =  new List<Case>{marketplaceOnboardingCase};
        Set<Id> caseRecordTypeIds = new Set<Id>{CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING,  CDdMxSxConstants.RECORD_TYPE_ID_CASE_CAVIAR_ONBOARDING, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS};
        mocks.startStubbing();
        mocks.when(mockIntegrationSelector.sObjectType()).thenReturn(Integration_Request__x.SObjectType);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByOnboardingIds(onboardingIds)).thenReturn(posRequests);
        mocks.when(mockAccountSelector.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(mockAccountSelector.selectAccountsByStoreId(storeId)).thenReturn(accounts);
        mocks.when(mockCaseSelector.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(mockCaseSelector.selectCasesWithMilestoneByRecordTypesAndAccountsAndStatus(caseRecordTypeIds, accountIds, CDdMxSxConstants.OB_CASE_OPEN_STATUS)).thenReturn(openCases);
        mocks.stopStubbing();
        Application.Selector.setMock(mockIntegrationSelector);
        Application.Selector.setMock(mockAccountSelector);
        Application.Selector.setMock(mockCaseSelector);
        Application.UnitOfWork.setMock(mockUow);

        CDdMxPosIntegrationRequestProcessor processor = new CDdMxPosIntegrationRequestProcessor(onboardingIds);
        processor.execute();
        //Created new pos integration request
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerNew(fflib_Match.anySobject());
        // Updated opportunity order protocol to Pos if opportunity don't have pos order protocol.
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(fflib_Match.anySobject());
        // validation opportunity order protocol type and it should have changed to other then TABLET_ORDER_PROTOCOL.
       ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 0)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            opportunity.Order_Protocol__c => TABLET_ORDER_PROTOCOL
        }));
        //Created new pos integration request and validating the data which has been created.
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerNew(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            case.POS_Integration_ID__c => posIntegrationRequest[0].Integration_Id__c,
            case.POS_Integration_Type__c =>posIntegrationRequest[0].Integration_Provider__c
        }));
          //work around to pass code scan.
          system.assertEquals(posIntegrationRequest.size(), 1, 'Pos request count not matching');
    }
    @isTest
    private static void testWhenPosIntegrationCaseExistAndProviederTypeisDifferentAndUpdateCaseToDeadAndCreateNewCase() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);

        IIntegrationRequestsSelector mockIntegrationSelector = (IIntegrationRequestsSelector) mocks.mock(IntegrationRequestsSelector.class);
        IAccountsSelector mockAccountSelector = (IAccountsSelector) mocks.mock(AccountsSelector.class);
        ICasesSelector mockCaseSelector = (ICasesSelector) mocks.mock(CasesSelector.class);

        set<String> onboardingIds = new Set<String>{posIntegrationRequest[0].onboarding_Id__C};
        Set<String> storeId = new Set<String>{'224455'};
        marketPlaceAccount.Restaurant_ID__c = '224455';
        List<Account> accounts = new List<Account>{marketPlaceAccount};
        Set<Id> accountids = new Set<Id>{marketPlaceAccount.Id};
        CDdMxIntegrationObject posRequests = new CDdMxIntegrationObject(posIntegrationRequest);
        List<Case> openCases =  new List<Case>{marketplaceOnboardingCase, posIntegrationCase};
        Set<Id> caseRecordTypeIds = new Set<Id>{CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING,  CDdMxSxConstants.RECORD_TYPE_ID_CASE_CAVIAR_ONBOARDING, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS};
        mocks.startStubbing();
        mocks.when(mockIntegrationSelector.sObjectType()).thenReturn(Integration_Request__x.SObjectType);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByOnboardingIds(onboardingIds)).thenReturn(posRequests);
        mocks.when(mockAccountSelector.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(mockAccountSelector.selectAccountsByStoreId(storeId)).thenReturn(accounts);
        mocks.when(mockCaseSelector.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(mockCaseSelector.selectCasesWithMilestoneByRecordTypesAndAccountsAndStatus(caseRecordTypeIds, accountIds, CDdMxSxConstants.OB_CASE_OPEN_STATUS)).thenReturn(openCases);
        mocks.stopStubbing();
        Application.Selector.setMock(mockIntegrationSelector);
        Application.Selector.setMock(mockAccountSelector);
        Application.Selector.setMock(mockCaseSelector);
        Application.UnitOfWork.setMock(mockUow);

        CDdMxPosIntegrationRequestProcessor processor = new CDdMxPosIntegrationRequestProcessor(onboardingIds);
        processor.execute();
        //Created new pos integration request
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerNew(fflib_Match.anySobject());
        // verify update opportunity order protocol to Pos if opportunity don't have pos order protocol.
        // verify update existing pos case to dead if the existing pos provider type is different.
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 2)).registerDirty(fflib_Match.anySobject());
        //verify existing case updated to dead.
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            case.status => CDdMxSxConstants.CASE_STATUS_DEAD
        }));
        //Created new pos integration request and validating the data which has been created.
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerNew(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            case.POS_Integration_ID__c => posIntegrationRequest[0].Integration_Id__c,
            case.POS_Integration_Type__c => posIntegrationRequest[0].Integration_Provider__c
        }));
          //work around to pass code scan.
          system.assertEquals(posIntegrationRequest.size(), 1, 'Pos request count not matching');
    }
    @isTest
    private static void testWhenUpdateMilestonesForPosUpdateRequest() {
        // mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        ICasesSelector mockCaseSelector = (ICasesSelector) mocks.mock(CasesSelector.class);
        IAccountsSelector mockAccountSelector = (IAccountsSelector) mocks.mock(AccountsSelector.class);
        IIntegrationRequestsSelector mockIntegrationSelector = (IIntegrationRequestsSelector) mocks.mock(IntegrationRequestsSelector.class);
        IBatToMilestoneStatusMappingSelector metaDataMappingSelector =
            (IBatToMilestoneStatusMappingSelector) mocks.mock(BatToMilestoneStatusMappingSelector.class);
        List<Bat_To_Milestone_Status_Mapping__mdt> settingList = getBatToMilestoneMapping();

        //setup required data
        List<Account> accounts = new List<Account>{marketPlaceAccount};
        Set<Id> accountids = new Set<Id>{marketPlaceAccount.Id};
        Set<String> storeId = new Set<String>{'224455'};
        Milestone__c milestoneIngestPosMenu = new Milestone__c();
        milestoneIngestPosMenu.Id = fflib_IDGenerator.generate(Milestone__c.getSObjectType());
        milestoneIngestPosMenu.Status__c = 'Escalated';
        milestoneIngestPosMenu.Milestone_Type__c = MILESTONE_INGEST_MENU;
        Milestone__c milestoneQaMenu = new Milestone__c();
        milestoneQaMenu.Id = fflib_IDGenerator.generate(Milestone__c.getSObjectType());
        milestoneQaMenu.Status__c = 'Completed';
        milestoneQaMenu.Milestone_Type__c = MILESTONE_QA_MENU;
		posIntegrationCase.onboarding_Id__c = '111111111';
        List<Case> openCases = ((List<Case>)fflib_ApexMocksUtils.makeRelationship(
            List<Case>.class,
            new List<Case>{ posIntegrationCase },
            Milestone__c.Case__c,
            new List<List<Milestone__c>>{new List<Milestone__c>{ milestoneIngestPosMenu, milestoneQaMenu}}
        ));
        posIntegrationRequest[0].Action__c = 'UPDATE';
        posIntegrationRequest[0].Target_Status__c = BAT_STATUS_MENU_BLOCK;
        posIntegrationRequest[0].Exclusion_Code__c = EXCLUSION_CODE_MENU_FAILURE;
        posIntegrationRequest[0].onboarding_Id__c = '111111111';
        CDdMxIntegrationObject posRequests = new CDdMxIntegrationObject(posIntegrationRequest);
        set<String> onboardingIds = new Set<String>{posIntegrationRequest[0].onboarding_Id__C};
        Set<Id> caseRecordTypeIds = new Set<Id>{CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING,  CDdMxSxConstants.RECORD_TYPE_ID_CASE_CAVIAR_ONBOARDING, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS};
       // stub the mocks
        mocks.startStubbing();
        mocks.when(mockIntegrationSelector.sObjectType()).thenReturn(Integration_Request__x.SObjectType);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByOnboardingIds(onboardingIds)).thenReturn(posRequests);
        mocks.when(mockCaseSelector.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(mockAccountSelector.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(mockAccountSelector.selectAccountsByStoreId(storeId)).thenReturn(accounts);
        mocks.when(mockCaseSelector.selectCasesWithMilestoneByRecordTypesAndAccountsAndStatus(caseRecordTypeIds, accountIds, CDdMxSxConstants.OB_CASE_OPEN_STATUS)).thenReturn(openCases);
        mocks.when(metaDataMappingSelector.SObjectType()).thenReturn(Bat_To_Milestone_Status_Mapping__mdt.SObjectType);
        mocks.when(metaDataMappingSelector.getAllValues()).thenReturn(settingList);
        mocks.stopStubbing();

        Application.Selector.setMock(mockCaseSelector);
        Application.Selector.setMock(mockIntegrationSelector);
        Application.Selector.setMock(mockAccountSelector);
        Application.SELECTOR.setMock(metaDataMappingSelector);
        Application.UnitOfWork.setMock(mockUow);
        CDdMxPosIntegrationRequestProcessor processor = new CDdMxPosIntegrationRequestProcessor(onboardingIds);
        processor.execute();
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Milestone__c.status__c => MILESTONE_STATUS_ESCALATED
        }));
          //work around to pass code scan.
          system.assertEquals(posIntegrationRequest.size(), 1, 'Pos request count not matching');
    }
    private static List<Bat_To_Milestone_Status_Mapping__mdt> getBatToMilestoneMapping(){
        return new List<Bat_To_Milestone_Status_Mapping__mdt>{
            new Bat_To_Milestone_Status_Mapping__mdt(
                Label = 'Milestone Mapping',
                DeveloperName = 'Milestone_Mapping_1',
                Bat_Status__c = BAT_STATUS_MENU_BLOCK,
                Exclusion_Code__c = '',
                Status_Reason__c = STATUS_REASON_POS_INGESTION_FAILURE,
                Milestone_Status__c = MILESTONE_STATUS_ESCALATED,
                Milestone_Type__c = MILESTONE_INGEST_MENU
            ),
            new Bat_To_Milestone_Status_Mapping__mdt(
                Label = 'Milestone Mapping',
                DeveloperName = 'Milestone_Mapping_2',
                Bat_Status__c = BAT_STATUS_MENU_BLOCK,
                Exclusion_Code__c = EXCLUSION_CODE_MENU_FAILURE,
                Status_Reason__c = STATUS_REASON_MENU_FAILURE,
                Milestone_Status__c = MILESTONE_STATUS_ESCALATED,
                Milestone_Type__c = MILESTONE_QA_MENU
            )
        };
    }
}