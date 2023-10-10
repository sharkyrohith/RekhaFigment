/********************************************************************************************************************
* @author Sriram
* @date 10/08/2022
*
* @group fflib
*
* @description Apex test class for CDdMxSxOpportunityHelper
* 
**************************************************************************************************************************************/
@isTest
public class CDdMxSxOpportunityHelperTest {      

	@isTest
	private static void testOpportunityHelperWithMockData() {

        MxSxApexMockTestDataFactory mockTestDataFactory = new MxSxApexMockTestDataFactory();     

        // Given mocks environment
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        
        // Given mock Selector
        IOpportunitiesSelector mockOpportunitiesSelector = (IOpportunitiesSelector) mocks.mock(OpportunitiesSelector.class);
        IOrdersSelector mockOrdersSelector = (IOrdersSelector) mocks.mock(OrdersSelector.class);
        
        // Given mock response
        Order mockOrder = mockTestDataFactory.marketplaceOrder;
        List<Order> mockOrders =  new List<Order>{ mockOrder };            
        Opportunity mockOpportunity = mockTestDataFactory.marketplaceOpportunity;
        List<Opportunity> mockOpportunities =  new List<Opportunity>{ mockOpportunity };
        Set<Id> mockOpportunityIds = new Set<Id>{ mockOpportunity.Id };

        // Given mocks response
        mocks.startStubbing();
        mocks.when(mockOpportunitiesSelector.sObjectType()).thenReturn(Opportunity.SObjectType);
        mocks.when(mockOpportunitiesSelector.selectOnboardingOpportunitiesWithLineItemsAndCases(mockOpportunityIds)).thenReturn(mockOpportunities); 
        mocks.when(mockOrdersSelector.sObjectType()).thenReturn(Order.SObjectType);
        mocks.when(mockOrdersSelector.selectOrderAndOrderItemsByOpportunityId(mockOpportunityIds)).thenReturn(mockOrders);  
        mocks.stopStubbing();

        // Given mocks injected
        Application.Selector.setMock(mockOpportunitiesSelector);
        Application.Selector.setMock(mockOrdersSelector);
        
        CDdMxSxOpportunityHelper opportunityHelper = new CDdMxSxOpportunityHelper(mockOpportunityIds);
        System.assert(opportunityHelper.getOpportunity(mockOpportunity.Id)!=null, 'Expecting an opportunity record with record id ' + mockOpportunity.Id);
        System.assert(opportunityHelper.isClosedWon(mockOpportunity.Id), 'Expecting the opportunity to be in closed won');
        System.assert(opportunityHelper.getStoreAccountId(mockOpportunity.Id)!=null, 'Expecting the account on the opportunity to be a store account');
        System.assert(opportunityHelper.getParentAccountId(mockOpportunity.Id)!=null, 'Expecting a parent account for the opportunity on the store account');
        System.assert(!opportunityHelper.getParentAccountIds().isEmpty(), 'Expecting Collection of parent accounts');
        System.assert(opportunityHelper.getCloseDate(mockOpportunity.Id)!=null, 'Expecting the Opportunity to have a close date');
        System.assert(!opportunityHelper.isSelfServe(mockOpportunity.Id), 'Expecting the Opportunity to not originate via self serve');
        System.assert(CDdMxSxConstants.SEGMENT_LOCAL.equals(opportunityHelper.getSegment(mockOpportunity.Id)), 'Expecting the Opportunity to be associated with an Account in segment ' + CDdMxSxConstants.SEGMENT_LOCAL);
        System.assert(opportunityHelper.hasProducts(mockOpportunity.Id), 'Expecting the opportunity to have products');
        System.assert(opportunityHelper.hasCPQProducts(mockOpportunity.Id), 'Expecting the opportunity to have cpq products');
        System.assert(!opportunityHelper.getCPQProducts(mockOpportunity.Id).isEmpty(), 'Expecting the opportunity to have cpq products');
        System.assert(opportunityHelper.getStorefrontPackage(mockOpportunity.Id)!=null, 'Expecting CPQ Storefront Package for the Opportunity');
        System.assert(opportunityHelper.getCPQStorefrontPackage(mockOpportunity.Id)!=null, 'Expecting CPQ Storefront Package for the Opportunity');
        System.assert(!opportunityHelper.hasLegacyProducts(mockOpportunity.Id), 'Not expecting the Opportunity to have Opportunity Line Items');
        System.assert(opportunityHelper.getLegacyStorefrontPackage(mockOpportunity.Id)==null, 'Not expecting the Opportunity to have Legacy Storefront package');
        System.assert(opportunityHelper.hasStorefrontPricing(mockOpportunity.Id), 'Expecting the Opportunity to have Storefront Pricing');
        System.assert(opportunityHelper.hasNetNewStorefrontPricing(mockOpportunity.Id), 'Expecting the Opportunity to have Net-New Storefront Pricing');
        System.assert(!opportunityHelper.hasRenegotiatedStorefrontPricing(mockOpportunity.Id), 'Expecting the Opportunity to not have Re-negotiated Storefront Pricing');
        System.assert(opportunityHelper.hasCases(mockOpportunity.Id), 'Expecting the opportunity to have storefront case');
        System.assert(!opportunityHelper.getCases(mockOpportunity.Id, CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING, opportunityHelper.getStorefrontPackage(mockOpportunity.Id).Id).isEmpty(), 'Expecting the opportunity to have storefront case');
        System.assert(!opportunityHelper.hasPostSalesActivationCases(mockOpportunity.Id), 'Expecting the opportunity to not have Post Sale storefront case');
        System.assert(!opportunityHelper.hasPostSalesActivationCaseForStorefrontBundle(mockOpportunity.Id), 'Expecting the opportunity to not have Post Sale storefront case');
        System.assert(!opportunityHelper.isPactSafeContractTypeSSMOSignUpSheet(mockOpportunity.Id), 'Expecting the opportunity pactsafe contract to not be SSMO SignUp Sheet');
        System.assert(!opportunityHelper.isCurrentUserSelfServe(), 'Expecting the current user to not be self-serve user');
        System.assert(opportunityHelper.isSMB(mockOpportunity.Id), 'Expecting the Opportunity to be an SMB Opportunity');
        System.assert(!opportunityHelper.isOpportunityofTypeChangeofOwnership(mockOpportunity.Id), 'Expecting the Opportunity to not be Change of Ownership');        
    }    

}