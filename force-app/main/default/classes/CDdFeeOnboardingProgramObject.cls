/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/12/2021
*
* @group Fee Onboarding
*
* @description  A representation of Fee Onboarding Program Object 
* 
**************************************************************************************************************************************/
public class CDdFeeOnboardingProgramObject {
    @AuraEnabled
    public String storeId {get; private set;}
    @AuraEnabled
    public Id opportunityId {get; private set;}        
    @AuraEnabled
    public Id programId {get; private set;}
    @AuraEnabled
    public String displayName {get; private set;}
    @AuraEnabled
    public String apiType {get; private set;}
    @AuraEnabled
    public String audience {get; private set;}
    @AuraEnabled
    public String channel {get; private set;}
    @AuraEnabled
    public String experience {get; private set;}
    @AuraEnabled
    public String fulfillmentType {get; private set;}
    @AuraEnabled
    public String productDDCustomId {get; private set;}
    @AuraEnabled
    public Date startDate {get; private set;}
    @AuraEnabled
    public Date endDate  {get; private set;}
    @AuraEnabled
    public Decimal storeTimezoneGmtOffset  {get; private set;}    
    @AuraEnabled
    public List<CDdFeeOnboardingFeeObject> fees  {get; private set;}                        

    public CDdFeeOnboardingProgramObject(Fee_Onboarding_CPQ_Program__mdt programCustomMetadataRec, OrderItem orderItem) {
        this.storeId = orderItem.Order.Account.Restaurant_Id__c;
        this.opportunityId = orderItem.Order.OpportunityId;
        this.programId = programCustomMetadataRec.Id;
        this.displayName = programCustomMetadataRec.MasterLabel;
        this.apiType = programCustomMetadataRec.Api_Type__c;
        this.audience = programCustomMetadataRec.Audience__c;
        this.channel = programCustomMetadataRec.Channel__c;
        this.experience = programCustomMetadataRec.Experience__c;
        this.fulfillmentType = programCustomMetadataRec.Fulfillment_Type__c;
        this.productDDCustomId = orderItem.Product2.DD_Custom_ID__c;
        this.storeTimezoneGmtOffset = orderItem.Order.Account.RealZip__RealZip__r!=null ? orderItem.Order.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c : null;
        this.fees = new List<CDdFeeOnboardingFeeObject>();
    }
    /**
     * @description Add fee to the fee Collection of fee onboarding program object
     * @param Fee_Onboarding_CPQ_Fee__mdt fee custom metadata record
     * @param OrderItem order item record
     * @param Decimal fee value
     * @param Date fee start date
     * @param Date fee end date
     * @return 
     */     
    public void addFee(Fee_Onboarding_CPQ_Fee__mdt feeCustomMetadataRec, OrderItem orderItem, Decimal feeValue, Date startDt, Date endDt) {
        this.fees.add(new CDdFeeOnboardingFeeObject(feeCustomMetadataRec, orderItem, feeValue, startDt, endDt));
        if ((startDt != null) && (this.startDate == null || this.startDate > startDt)){
            this.startDate = startDt;
        }
    }
}