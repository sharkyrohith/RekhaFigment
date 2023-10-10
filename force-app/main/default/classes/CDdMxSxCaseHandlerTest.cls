/********************************************************************************************************************
* @author Lathika
* @date 11/10/2022
*
* @group fflib
*
* @description Apex test class for CDdMxSxCaseHandler
*
**************************************************************************************************************************************/
@IsTest
public class CDdMxSxCaseHandlerTest {

    private static MxSxApexMockTestDataFactory mockTestDataFactory {
        get {
            if(mockTestDataFactory == null) {
                mockTestDataFactory = new MxSxApexMockTestDataFactory();
            }
            return mockTestDataFactory;
        }
        set;
    }
    /**
     * Test Method for CDdMxSxCaseHandler.publishMxSxEventsForMarketplaceOnboardingCaseInsert: Insert events are published
    */
    @isTest
    private static void publishMxSxEventsForMarketplaceOnboardingCaseInsertPositive() {
        Case marketplaceCaseInsert = mockTestDataFactory.marketplaceOnboardingCase;
        List<Case> newCases = new List<Case>{marketplaceCaseInsert};
        // Asserting Insert events are published
        System.assert(CDdMxSxCaseHandler.publishMxSxEventsForMarketplaceOnboardingCaseInsert(newCases));
    }
    /**
     * Test Method for CDdMxSxCaseHandler.publishMxSxEventsForMarketplaceOnboardingCaseUpdate Positive Scenario: Update events are published
    */
    @isTest
    private static void publishMxSxEventsForMarketplaceOnboardingCaseUpdateReadyForActivationPositive() {
        //Old Case
        Case marketplaceCaseInsert = mockTestDataFactory.marketplaceOnboardingCase;
        marketplaceCaseInsert.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        Map<Id,Case> oldMap = new Map<Id,Case>([SELECT id from Case Where ID = : marketplaceCaseInsert.Id]);

        // cloned the case and set Stage = Ready For Activation
        Case marketplaceCaseStageReadyForActivation = marketplaceCaseInsert.clone(false, false, false, false);
        marketplaceCaseStageReadyForActivation.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        marketplaceCaseStageReadyForActivation.Stage__c = CDdMxSxConstants.CASE_STAGE_READY_FOR_ACTIVATION;
        List<Case> newCases = new List<Case>{marketplaceCaseStageReadyForActivation};
        // Asserting Update events are published
        System.assert(CDdMxSxCaseHandler.publishMxSxEventsForMarketplaceOnboardingCaseUpdate(newCases,oldMap));
    }
    /**
     * Test Method for CDdMxSxCaseHandler.publishMxSxEventsForMarketplaceOnboardingCaseUpdate Negative Scenario:Update events are not published
    */
    @isTest
    private static void publishMxSxEventsForMarketplaceOnboardingCaseUpdateWhenCaseStageisUnderReviewNegative() {
        //Old Case
        Case marketplaceCaseInsert = mockTestDataFactory.marketplaceOnboardingCase;
        marketplaceCaseInsert.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        Map<Id,Case> oldMap = new Map<Id,Case>([SELECT id from Case Where ID = : marketplaceCaseInsert.Id]);

        // cloned the case and set Stage = Under Review
        Case marketplaceCaseUnderReview = marketplaceCaseInsert.clone(false, false, false, false);
        marketplaceCaseUnderReview.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        marketplaceCaseUnderReview.Stage__c = 'Under Review';
        List<Case> newCases = new List<Case>{marketplaceCaseUnderReview};
        // Asserting Update events are not published
        System.assert(!CDdMxSxCaseHandler.publishMxSxEventsForMarketplaceOnboardingCaseUpdate(newCases,oldMap));
    }
     /**
     * Test Method for CDdMxSxCaseHandler.publishMxSxEventsForPOSIntegrationCases events are published
    */
    @isTest
    private static void publishMxSxEventsForPublishMxSxEventsForPOSIntegrationCases() {
        //Old Case
        Case posIntegrationCaseInsert = mockTestDataFactory.posIntegrationCase;
        posIntegrationCaseInsert.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        Map<Id,Case> oldMap = new Map<Id,Case>([SELECT id from Case Where ID = : posIntegrationCaseInsert.Id]);

        // cloned the case and set Status = 'Closed'
        Case posIntegrationCaseInsertStatusClosed = posIntegrationCaseInsert.clone(false, false, false, false);
        posIntegrationCaseInsertStatusClosed.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        posIntegrationCaseInsertStatusClosed.Status = 'Closed';
        List<Case> newCases = new List<Case>{posIntegrationCaseInsertStatusClosed};
        // Asserting publishMxSxEventsForPOSIntegrationCases are published
        System.assert(CDdMxSxCaseHandler.publishMxSxEventsForPOSIntegrationCases(newCases,oldMap));
    }
    /**
     * BZAP_19404 Test Method for CDdMxSxCaseHandler.publishMxSxEventsForCaviarOnboardingCaseUpdate events are published
    */
    @isTest
    private static void publishMxSxEventsForPublishMxSxEventsForCaviarOnboardingCase() {
        //Old Case
        Case caviarOnboardingCaseInsert = mockTestDataFactory.caviarOnboardingCase;
        caviarOnboardingCaseInsert.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        caviarOnboardingCaseInsert.Activation_Date__c = System.Today();
        Map<Id,Case> oldMap = new Map<Id,Case>([SELECT id from Case Where ID = : caviarOnboardingCaseInsert.Id]);

        // cloned the case and set MxP_Handoff_Date__c
        Case caviarOnboardingCaseUpdate = caviarOnboardingCaseInsert.clone(false, false, false, false);
        caviarOnboardingCaseUpdate.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        caviarOnboardingCaseUpdate.MxP_Handoff_Date__c = System.today();
        List<Case> newCases = new List<Case>{caviarOnboardingCaseUpdate};
        // Asserting publishMxSxEventsForCaviarOnboardingCaseUpdate are published
        System.assert(CDdMxSxCaseHandler.publishMxSxEventsForCaviarOnboardingCaseUpdate(newCases,oldMap));
    }
}