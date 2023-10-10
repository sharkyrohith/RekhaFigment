/**
	@author: Dan Thoreson
	@date: 23-Dec-2022
	@group: Mx Services
	@description: Wrappers for the POS/BAT Requests, used for POS Cases.
**/
public class CDdMxSxPOSRequestWrappers {

	public enum RequestType {
		OPPORTUNITY_CLOSE_WON,
		BAT_POS_REQUEST
	}

	// This is a static Map of Opportunity IDs and their most recent Marketplace Onboarding Cases.
	// The purpose is to support bulkification when constructing CDdMxSxPOSRequestWrappers.POSRequest objects.
	public static Map<Id, Case> marketplaceCasesByOpportunityIds { get {
		if(marketplaceCasesByOpportunityIds == null) {
			marketplaceCasesByOpportunityIds = new Map<Id, Case>();

			List<Case> marketplaceCases = CasesSelector.newInstance().selectCasesWithMilestonesByRecordTypeAndGenericParent(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(),
																															'Opportunity_Name__c',
																															opportunityIds);

			for(Case thisCase : marketplaceCases) {
				// We got Markplace Onboarding RT Cases for the given Opportunity IDs. There could
				// theoretically be multiple, so compare and make sure we are taking the most recent.
				Case caseToCompare = marketplaceCasesByOpportunityIds.get(thisCase.Opportunity_Name__c);
				if(caseToCompare == null || thisCase.CreatedDate > caseToCompare.CreatedDate) {
					marketplaceCasesByOpportunityIds.put(thisCase.Opportunity_Name__c, thisCase);
				}
			}
		}

		return marketplaceCasesByOpportunityIds;
	} set;}

	// Map of Marketplace Case IDs as the key and the source Opportunity as the value
	public static Map<Id, Opportunity> opportuntiesByMarketplaceCaseIds {get; set;}

	// Supports the marketplaceCasesByOpportunityIds Map
	private static Set<Id> opportunityIds = new Set<Id>();

	private static Map<Id, Case> marketplaceCasesByOppIds = new Map<Id, Case>();

	public POSRequest posRequest;

	public class POSRequest {
		public RequestType reqType;

		public Boolean createPOSCase {get {
			if(createPOSCase == null) {
				createPOSCase = false;
			}

			return createPOSCase;
		} set;}

		public Boolean updateExistingCaseToDead {get {
			if(updateExistingCaseToDead == null) {
				updateExistingCaseToDead = false;
			}

			return updateExistingCaseToDead;
		} set;}

		public Boolean updateExistingCaseLocationId {get {
			if(updateExistingCaseLocationId == null) {
				updateExistingCaseLocationId = false;
			}

			return updateExistingCaseLocationId;
		} set;}

		public Boolean updateOpportunity {get {
			if(updateOpportunity == null) {
				updateOpportunity = false;
			}

			return updateOpportunity;
		} set;}

		public POSRequestAction actionDetails;
		public Opportunity sourceOpportunity;
		public Case marketplaceOnboardingCase;
		public String accountName;

		public POSRequest(Case marketplaceOnboardingCase) {
			this.marketplaceOnboardingCase = marketplaceOnboardingCase;
			this.sourceOpportunity = opportuntiesByMarketplaceCaseIds.get(marketplaceOnboardingCase.Id);
			this.reqType = RequestType.OPPORTUNITY_CLOSE_WON;
			this.actionDetails = new POSCaseCreationDetails(this.sourceOpportunity);
			this.createPOSCase = true;
			this.init();
		}

		public POSRequest(Opportunity sourceOpportunity) {
			this.sourceOpportunity = sourceOpportunity;
			this.setMarketplaceOnboardingCase();
			this.reqType = RequestType.OPPORTUNITY_CLOSE_WON;
			this.actionDetails = new POSCaseCreationDetails(sourceOpportunity);
			this.createPOSCase = true;
			this.init();
		}

		private void init() {
			setStoreId();
			setOpportunityId();
			setAccountName();
		}

		private void setStoreId() {
			this.actionDetails.storeId = sourceOpportunity.Store_Id__c;
		}

		private void setOpportunityId() {
			this.actionDetails.opportunityId = sourceOpportunity.Id;
		}

		private void setAccountName() {
			this.accountName = this.sourceOpportunity.Opportunity_Account_Name__c;
		}

		private void setMarketplaceOnboardingCase() {
			this.marketplaceOnboardingCase = CDdMxSxPOSRequestWrappers.marketplaceCasesByOpportunityIds.get(sourceOpportunity.Id);
		}
	}

	public virtual class POSRequestAction {
		public String marketplaceOnboardingCaseId;
		public String opportunityId;
		public String storeId;
	}

	public class POSCaseCreationDetails extends POSRequestAction {
		public String accountId;

		public POSCaseCreationDetails(Opportunity opp) {
			accountId = opp.AccountId;
			opportunityId = opp.Id;
		}
	}

	public class POSCaseUpdateDetails extends POSRequestAction {
		public String status;
	}

	public class LocationIdUpdateDetails extends POSRequestAction {
		public String locationId;
	}

	public class OpportunityUpdateDetails extends POSRequestAction {
		public String orderProtocol;
	}

	public static void setMarketplaceOpportunityIdsForCaseRetrieval(Set<Id> opportunityIds) {
		CDdMxSxPOSRequestWrappers.opportunityIds = opportunityIds;
	}

	public static void setOpportunityIdsAndMarketplaceCaseIds(List<Case> marketplaceCases) {
		for(Case thisCase : marketplaceCases) {
			marketplaceCasesByOppIds.put(thisCase.Opportunity_Name__c, thisCase);
		}

		setMarketplaceCasesByOpportunityIdsMap();
	}

	public static void setMarketplaceCasesByOpportunityIdsMap() {
		opportuntiesByMarketplaceCaseIds = new Map<Id, Opportunity>();

		// Fields we need in the POSRequest object
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

		// Get the Opportunities
		List<Opportunity> sourceOpps = OpportunitiesSelector.newInstance().selectByIdExtraFields(marketplaceCasesByOppIds.keySet(),
																									extraFields);

		Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>(sourceOpps);

		for(Id thisOppId : marketplaceCasesByOppIds.keySet()) {
			Case marketplaceOnboardingCase = marketplaceCasesByOppIds.get(thisOppId);
			Opportunity thisOpp = oppsMap.get(thisOppId);

			if(marketplaceOnboardingCase != null) {
				opportuntiesByMarketplaceCaseIds.put(marketplaceOnboardingCase.Id, thisOpp);
			}
		}
	}
}