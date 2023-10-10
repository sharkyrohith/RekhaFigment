/********************************************************************************************************************
* @author Lathika
* @date 01/30/2023
*
* @group Merchant Services BZAP-19069
*
* @description Handler class for Caviar Onboarding Cases for Turbo Charge: Ads and promo
* Scope is now only to operate on Caviar Onbaoring cases. participates in MxSx event Handler && MxSx Support event job: CAVIAR_TURBO_CHARGE_UPDATE
**************************************************************************************************************************************/
public class CDdMxSxTurboChargeHandler {
    private CDdMxSxCaviarOnboardingCaseHelper mxSxCaviarOnboardingCaseHelper;
    private List<Case> caviarOnboardingCases;
    private Map<Id, Id> caviarOnboardingCaseIdToOpportunityId;
    private List<SObject> sObjectsToUpdate;

    /**
     * @description Single argument constructor
     * @param Set<Id> caseIds - Collection of Case Ids
     * @return void
     */
    public CDdMxSxTurboChargeHandler(Set<Id> caseIds) {
        this.initialize(caseIds);
    }
    /**
     * @description setting the class variables
     * @param Set<Id> caseIds - Collection of Case Ids
     * @return void
    */
    private void initialize(Set<Id> caseIds){
        this.caviarOnboardingCaseIdToOpportunityId = new Map<Id, Id>();
        this.sObjectsToUpdate = new List<SObject>();
        this.caviarOnboardingCases = CasesSelector.newInstance().selectById(caseIds,  new Set<String>{'MxP_Handoff_Date__c','Activation_Date__c'});
        for (Case newCase : this.caviarOnboardingCases) {
            if(newCase.opportunity_name__c != null){
                this.caviarOnboardingCaseIdToOpportunityId.put(newCase.Id, newCase.opportunity_name__c);
            }
        }
        this.mxSxCaviarOnboardingCaseHelper = new CDdMxSxCaviarOnboardingCaseHelper(new Set<Id>(this.caviarOnboardingCaseIdToOpportunityId.values()));
    }

     /**
     * @description called from 1:  MxSx event Handler for
     * 2.MxSx Support event job:
     * collects the sobjects to update in a list and do a single dml
     * @param
     * @return void
    */
    public void performUpdates(){
        handleUpdatesForOrderLineitems();
        updateTheCaseOwnerAndStatus();
        if (!this.sObjectsToUpdate.isEmpty()) {
            List<Database.SaveResult> sResultsToProcess =  Database.update(sObjectsToUpdate, false);
            CDdErrorUtilities.publishException('sObject', 'CDdMxSxTurboChargeHandler performUpdates', sResultsToProcess);
        }
    }

    /**
     * @description handle the Cavair Onboarding Case updates: called from CDdMxSxEventHandler
     * checks the Case is eligible for Ads and Promo: order Line update
     * creating a map of Opportunity to order Line items
     * @param
     * @return void
    */
    private void handleUpdatesForOrderLineitems(){
        Set<Id> oppidToProcess = new Set<Id>();
        List<Case> casesToProcess = new List<Case>();
        for (Case newCase : this.caviarOnboardingCases){
            if (this.mxSxCaviarOnboardingCaseHelper.isCaseEligibleForTurboChargeUpdate(newCase)) {
                oppidToProcess.add(newCase.opportunity_name__c);
                casesToProcess.add(newCase);
            }
        }
        if (oppidToProcess.isEmpty() || casesToProcess.isEmpty()) {
            return;
        }
        Map<Id, List<OrderItem>>  orderlinetItemsByOpportunityID = this.mxSxCaviarOnboardingCaseHelper.getOrderLineItemsForOppMap(oppidToProcess);
        if(!orderlinetItemsByOpportunityID.isEmpty()){
            setOrderLineItemsForUpdate(orderlinetItemsByOpportunityID, casesToProcess);
        }
    }

    /**
     * @description Update the orderLineItems
     * OrderlineItem Start Date = case.ActivationDate + OrderlineItem.Delay_after_Activation_days__c
     * Business Hours are considered for calculating the satrt date
     * OrderlineItem End Date = OrderlineItem Start Date + OrderlineItem length of Term
     * @param  Map<Id, List<OrderItem>> orderlinetItemsByOpportunityID
     * @param  List<Case> casesToProcess
     * @return
    */
    private void setOrderLineItemsForUpdate( Map<Id, List<OrderItem>> orderlinetItemsByOpportunityID, List<Case> casesToProcess){
        for(Case c : casesToProcess){
            if (orderlinetItemsByOpportunityID.containsKey(c.opportunity_name__c)) {
                for(OrderItem orderItem : orderlinetItemsByOpportunityID.get(c.opportunity_name__c)){
                    if (CDdMxSxCaviarOnboardingCaseHelper.isOrderItemEligibleForUpdate(orderItem)
                        && orderItem.Promo_Start_Day__c == null
                        && orderItem.Promo_End_Day__c == null
                        ) {
                            orderItem.Promo_Start_Day__c = c.Activation_Date__c.addDays(Integer.valueOf(orderItem.Delay_after_Activation_days__c));
                            orderItem.Promo_Start_Day__c = Date.valueOf(BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id,orderItem.Promo_Start_Day__c));
                            orderItem.Promo_End_Day__c = orderItem.Promo_Start_Day__c.addDays(Integer.valueOf(orderItem.Length_of_Term__c));
                            this.sObjectsToUpdate.add(orderItem);
                    }
                }
            }
        }
    }

    /**
     * @description handle the Cavair Onboarding Case updates: called from CDdMxSupportTurboChargeCaviarCaseUpdate.cls
     * checks the Case is eligible for TuboCharge Update
     * filter out the orderItems whise products are defined in custom label: Mx_Ads_Promos_Products_to_Exclude
     * If the PxP_handOff date is = Today, Case Status = Ready to activate
     * Update the Case Status to : Onboarding Ads and Promo
     * Update the Case Owner to the Queue: Onboarding_Ads_Promos
     * @param
     * @return void
    */
    private void updateTheCaseOwnerAndStatus(){
        List<Case> casesToProcess = new List<Case>();
        Set<Id> oppIds = new Set<Id>();
        for (Case c : this.caviarOnboardingCases) {
            if (this.mxSxCaviarOnboardingCaseHelper.isCaseEligibleForTurboChargeUpdate(c)
                && c.MxP_Handoff_Date__c == System.Today()
                && this.mxSxCaviarOnboardingCaseHelper.getOrderLineItemsForOpp(c.opportunity_name__c) != null){
                    oppIds.add(c.opportunity_name__c);
                    casesToProcess.add(c);
            }
        }
        if (oppIds.isEmpty() || casesToProcess.isEmpty()) {
            return;
        }
        Map<Id, List<OrderItem>>  orderlinetItemsByOppID = this.mxSxCaviarOnboardingCaseHelper.getOrderLineItemsForOppMap(oppIds);
        for (Case c : casesToProcess) {
            Boolean isCaseEligibleToUpdate = false ;
            if (orderlinetItemsByOppID.containsKey(c.opportunity_name__c)) {
                for(OrderItem orderLineItem : orderlinetItemsByOppID.get(c.opportunity_name__c)){
                    if(CDdMxSxCaviarOnboardingCaseHelper.isOrderItemEligibleForUpdate(orderLineItem)){
                        isCaseEligibleToUpdate = true;
                     }
                }
                if (isCaseEligibleToUpdate) {
                    this.sObjectsToUpdate.add(
                                    new Case(Id = c.Id,
                                        Status = CDdMxSxConstants.CASE_STATUS_ONBOARDING_ADS_AND_PROMO,
                                        ownerId = CDdMxSxConstants.QUEUE_ID_ONBOARDING_ADS_PROMO,
                                        Onboarding_Ads_and_Promo_Status__c = CDdMxSxConstants.ADS_AND_PROMO_STATUS_INCOMPLETE  //BASD-52032 Onboarding - Ads & Promos automation updates
                                    )
                    );
                }
            }
        }
    }
}