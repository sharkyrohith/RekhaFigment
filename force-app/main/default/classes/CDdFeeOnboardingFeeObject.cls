/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/12/2021
*
* @group Fee Onboarding
*
* @description  A representation of Fee Onboarding Fee Object 
* 
**************************************************************************************************************************************/
public class CDdFeeOnboardingFeeObject {
    @AuraEnabled
    public Id feeId {get; private set;}
    @AuraEnabled
    public String feeName {get; private set;}
    @AuraEnabled
    public String displayName {get; private set;}
    @AuraEnabled
    public String feeType {get; private set;}
    @AuraEnabled
    public Boolean isFeeRate {get; private set;}
    @AuraEnabled
    public Decimal feeValue {get; private set;} 
    @AuraEnabled
    public Boolean isTrialFee {get; private set;}           
    @AuraEnabled
    public String feeRateChargingTarget {get; private set;}
    @AuraEnabled
    public String productDDCustomId {get; private set;} 
    @AuraEnabled
    public String packageName {get; private set;}            
    @AuraEnabled
    public Date startDate {get; private set;}
    @AuraEnabled
    public Date endDate  {get; private set;}
    @AuraEnabled
    public Decimal storeTimezoneGmtOffset  {get; private set;}
    @AuraEnabled
    public Id orderItemId  {get; private set;}
    @AuraEnabled
    public Datetime orderItemLastModifiedDate  {get; private set;}                   
    @AuraEnabled
    public String billingCountryCode  {get; private set;}                        

    public CDdFeeOnboardingFeeObject(Fee_Onboarding_CPQ_Fee__mdt feeCustomMetadataRec, OrderItem orderItem, Decimal feeValue, Date startDate, Date endDate) {
        this.feeId = feeCustomMetadataRec.Id;
        this.feeName = feeCustomMetadataRec.Fee_Name__c;
        this.displayName = feeCustomMetadataRec.Fee_Display_Name__c;
        this.feeType = feeCustomMetadataRec.Fee_Type__c;
        this.isFeeRate = feeCustomMetadataRec.Is_Fee_Rate__c;
        this.isTrialFee = feeCustomMetadataRec.Is_Trial_Fee__c;
        this.feeRateChargingTarget = feeCustomMetadataRec.Fee_Rate_Charging_Target__c;
        this.productDDCustomId = orderItem.Product2.DD_Custom_ID__c;
        this.packageName = String.isNotBlank(feeCustomMetadataRec.Package_Name__c) ? orderItem.SBQQ__RequiredBy__r.Product2.Package_Name__c : null;
        this.storeTimezoneGmtOffset = orderItem.Order.Account.RealZip__RealZip__r!=null ? orderItem.Order.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c : null;
        this.feeValue = feeValue;
        this.startDate = startDate;
        this.endDate = endDate;
        this.orderItemId = orderItem.Id;
        this.orderItemLastModifiedDate = orderItem.LastModifiedDate;               
        this.billingCountryCode = orderItem.Order.Account.BillingCountryCode;               
    }
}