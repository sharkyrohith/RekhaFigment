/**
    @author: Dan Thoreson
    @date: 05-Oct-2022
    @group: Mx Services
    @description: Controller for Lightning Web Component, lwcDdStorefrontAndMarketplaceCaseView
    @test class: CDdCaseLightningComponentCtrlTest
**/
public class CDdCaseLightningComponentCtrl {

    /**
        @author: Dan Thoreson
        @date: 14-Oct-2022
        @description: Returns a wrapper object with details from the related Storefront or Marketplace Onboarding Case.
    **/
    @AuraEnabled
    public static CaseDetailsWrapper getSiblingCase(Id caseId) {
        try {
            List<Case> casesList = CasesSelector.newInstance().selectCasesByIdsWithParentAccountInfo(new Set<Id>{caseId});

            if(casesList.isEmpty()) {
                return null;
            }

            Case thisCase = casesList[0];

            Boolean isMarketplace = thisCase.RecordTypeId == CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
            Boolean isStorefront = thisCase.RecordTypeId == CDdSchemaUtils.CASE_RT.storefrontOnboardingId();

            // If neither a Storefront or Marketplace Case, we don't need to do anything. 
            // The component should not be on the UI.
            if(thisCase.AccountId == null || (!isStorefront && !isMarketplace)) {
                return null;
            }

            List<Case> matchingCases = new List<Case>();

            // If we are on a Marketplace Onboarding Case, go to the Parent Account of the Account for the current Case - the Storefront Case will be there
            if(isMarketplace) {
                if(thisCase.Account.ParentId != null) {   
                    matchingCases = new CasesSelector().selectCasesWithMilestonesByRecordTypeAndAccount(CDdSchemaUtils.CASE_RT.storefrontOnboardingId(),  
                                                                                                        new CDdMxSxOpportunityHelper(new Set<Id>{thisCase.Opportunity_Name__c}).getParentAccountIds());
                }
            // If we are on a Storefront Onboarding Case, get the Parent Account (related to the Case), then find its children and the Marketplace Cases related to them.
            } else {
                Map<Id, Account> childrenAccounts = new Map<Id, Account>(AccountsSelector.newInstance().selectAccountsForParent(thisCase.AccountId));
                matchingCases = CasesSelector.newInstance().selectCasesWithMilestonesByRecordTypeAndAccount(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(),  childrenAccounts.keySet());
            }

            return (!matchingCases.isEmpty()) ? new CaseDetailsWrapper(matchingCases[0]) : null;

        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    // Wrapper to return Case/Milestone data back to lightning component
    public class CaseDetailsWrapper {
        @AuraEnabled public Case caseToDisplay;
        @AuraEnabled public List<Milestone__c> milestones;
        @AuraEnabled public Integer completedMilestones = 0;
        @AuraEnabled public Integer totalMilestones = 0;
        @AuraEnabled public String caseTypeToShow;

        public CaseDetailsWrapper(Case thisCase) {
            this.caseToDisplay = thisCase;
            this.milestones = thisCase.Milestones__r != null ? thisCase.Milestones__r : new List<Milestone__c>();
            this.totalMilestones = this.milestones.size();
            setCompletedMilestones();
            setType();
        }

        private void setCompletedMilestones() {
            for(Milestone__c thisMilestone : milestones) {
                if(thisMilestone.Status__c == CDdMxSxConstants.MILESTONE_STATUS_COMPLETE) {
                    completedMilestones++;
                }
            }
        }

        private void setType() {
            Boolean isMarketplace = caseToDisplay.RecordTypeId == CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
            
            this.caseTypeToShow = isMarketplace ? 'Marketplace' : 'Storefront';
        }
    }
}