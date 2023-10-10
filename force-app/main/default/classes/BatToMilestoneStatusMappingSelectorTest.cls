/**
 * @author DoorDash
 * @date 03/21/2023
 * @description Test class for IntegrationRequests class.
 */
@isTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.NcssTypeCount')
public class BatToMilestoneStatusMappingSelectorTest {
    private static final String ASSERT_MESSAGE_COUNT_NOT_MATCHING = 'assert count not matching';
    private static final String BAT_STATUS_MENU_BLOCK = 'MENU_BLOCK';
    private static final String EXCLUSION_CODE_MENU_FAILURE = 'MENU_COMPLIANCE_FAILURE';
    private static final String EXCLUSION_CODE_NONE = 'NONE';
    private static final String MILESTONE_INGEST_MENU = 'Ingest Menu';
    private static final String MILESTONE_QA_MENU = 'QA Menu';
    private static final String MILESTONE_STATUS_ESCALATED = 'Escalated';
    private static final String STATUS_REASON_MENU_FAILURE = 'Menu Compliance failure';
    private static final String STATUS_REASON_POS_INGESTION_FAILURE = 'POS Ingestion failure';
    private static final String POS_INGESTION_FAILURE = 'POS Ingestion failure';
    private static final String ASSERT_MESSAGE_MISMATCH_IN_FIELDS_LIST = 'Unexpected result: there is a mismatch in fields list.';
	private static final String ASSERT_MESSAGE_MISMATCH_IN_OBJECT_TYPE = 'Unexpected result: the object type must be BatToMilestoneStatusMapping custom metadata';

    /**
     * @description testWhenSelectorMethodsCalledThenReturnAppropriateValues.
     */
    @isTest
    private static void testWhenSelectorMethodsCalledThenReturnAppropriateValues() {
        List<Schema.SObjectField> sObjectFieldsMock = new List<Schema.SObjectField>{
            Bat_To_Milestone_Status_Mapping__mdt.Bat_Status__c,
            Bat_To_Milestone_Status_Mapping__mdt.Exclusion_Code__c,
            Bat_To_Milestone_Status_Mapping__mdt.Milestone_Status__c,
           	Bat_To_Milestone_Status_Mapping__mdt.Milestone_Type__c,
            Bat_To_Milestone_Status_Mapping__mdt.Status_Reason__c,
            Bat_To_Milestone_Status_Mapping__mdt.Case_Status__c
        };
        BatToMilestoneStatusMappingSelector BatToMilestoneStatusMappingSelectorInstance = new BatToMilestoneStatusMappingSelector();
        Schema.SObjectType typeOfObject = BatToMilestoneStatusMappingSelectorInstance.SObjectType();
        List<Schema.SObjectField> sObjectFields = BatToMilestoneStatusMappingSelectorInstance.getSObjectFieldList();
        System.assertEquals(
            typeOfObject,
            Bat_To_Milestone_Status_Mapping__mdt.SObjectType,
            ASSERT_MESSAGE_MISMATCH_IN_OBJECT_TYPE
        );
        System.assertEquals(
            sObjectFields,
            sObjectFieldsMock,
            ASSERT_MESSAGE_MISMATCH_IN_FIELDS_LIST
        );
    }

    @isTest
    private static void testWhenUpdateIntegrationRequestReceivedUpdateTheMilestone() {
        List<Bat_To_Milestone_Status_Mapping__mdt> settingList = getBatToWorkStepMapping();
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(
        fflib_ISObjectUnitOfWork.class
        );
        IBatToMilestoneStatusMappingSelector metaDataMappingSelector = 
        (IBatToMilestoneStatusMappingSelector) mocks.mock(BatToMilestoneStatusMappingSelector.class);

        mocks.startStubbing();
        mocks.when(metaDataMappingSelector.SObjectType()).thenReturn(Bat_To_Milestone_Status_Mapping__mdt.SObjectType);
        mocks.when(metaDataMappingSelector.getAllValues()).thenReturn(settingList);
        mocks.stopStubbing();
        Application.SELECTOR.setMock(metaDataMappingSelector);
        Application.UnitOfWork.setMock(mockUow);

        List<Bat_To_Milestone_Status_Mapping__mdt> settingResult = BatToMilestoneStatusMappingSelector.newInstance().getAllValues();
            System.assertEquals(
                2,
                settingResult.size(),
                ASSERT_MESSAGE_COUNT_NOT_MATCHING
            );
    }
    private static List<Bat_To_Milestone_Status_Mapping__mdt> getBatToWorkStepMapping(){
        return new List<Bat_To_Milestone_Status_Mapping__mdt>{
            new Bat_To_Milestone_Status_Mapping__mdt(
                Label = 'Work Plan Mapping',
                DeveloperName = 'Work_Pan_Mapping_1',
                Bat_Status__c = BAT_STATUS_MENU_BLOCK,
                Exclusion_Code__c = '',
                Status_Reason__c = STATUS_REASON_POS_INGESTION_FAILURE,
                Milestone_Status__c = MILESTONE_STATUS_ESCALATED,
                Milestone_Type__c = MILESTONE_INGEST_MENU
            ),
            new Bat_To_Milestone_Status_Mapping__mdt(
                Label = 'Work Plan Mapping',
                DeveloperName = 'Work_Pan_Mapping_2',
                Bat_Status__c = BAT_STATUS_MENU_BLOCK,
                Exclusion_Code__c = EXCLUSION_CODE_MENU_FAILURE,
                Status_Reason__c = STATUS_REASON_MENU_FAILURE,
                Milestone_Status__c = MILESTONE_STATUS_ESCALATED,
                Milestone_Type__c = MILESTONE_QA_MENU
            )
        };
    }  
}