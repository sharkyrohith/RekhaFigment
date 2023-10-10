/********************************************************************************************************************
* @author Praveen
* @date 29/06/2022
*
* @group Merchant Services
*
* @description test class for CDdMxAccountModel for equipment reqest UI.
*
**************************************************************************************************************************************/

public with sharing class CDdMxAccountModel {
    @AuraEnabled
    public Id AccountId;
    @AuraEnabled
    public String Name;
    @AuraEnabled
    public String opportunityId;
    @AuraEnabled
    public String Addressline1;
    @AuraEnabled
    public String Addressline2;
    @AuraEnabled
    public String City;
    @AuraEnabled
    public String State;
    @AuraEnabled
    public String Country;
    @AuraEnabled
    public String PostalCode;
    @AuraEnabled
    public String BillingCountryCode;
    @AuraEnabled
    public Boolean isFirstRequest;
    @AuraEnabled
    public String storeId;
    @AuraEnabled
    public Boolean isLemonadeAccount;
    @AuraEnabled
    public String language;


    public CDdMxAccountModel(){}
    public CDdMxAccountModel(String actModel) {
        CDdMxAccountModel actDetails = (CDdMxAccountModel)JSON.deserializeStrict(actModel, CDdMxAccountModel.class);
        this.AccountId = actDetails.AccountId;
        this.Name = actDetails.Name;
        this.opportunityId = actDetails.opportunityId;
        this.Addressline1 = actDetails.Addressline1;
        this.Addressline2 = actDetails.Addressline2;
        this.City = actDetails.City;
        this.State = actDetails.State;
        this.Country = actDetails.Country;
        this.PostalCode = actDetails.PostalCode;
        this.BillingCountryCode = actDetails.BillingCountryCode;
        this.isFirstRequest = actDetails.isFirstRequest;
        this.storeId = actDetails.StoreId;
        this.isLemonadeAccount =actDetails.isLemonadeAccount;
        this.language = actDetails.language;
    }
    
}