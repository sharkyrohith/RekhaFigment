/**
 * @author:      Dan Meseroll (ATG)
 * @date:        2021-12
 * @description: BZAP-13129 Helper class for the Commission_Rate__c Trigger
 */
public with sharing class CDdCommissionRateTriggerHelper {

    /**
     * @author:      Dan Meseroll (ATG)
     * @date:        2021-12
     * @description: BZAP-12728 Set Search Key and Start and End date fields correctly.
     *               BZAP-13182 Do not default a null Primary Merchant Category
     */
    public void generateSearchKey(List<Commission_Rate__c> commissionRates){
        for(Commission_Rate__c rate : commissionRates){
            if ((String.isEmpty(rate.Submarket__c)) && (!String.isEmpty(rate.Product__c)) &&
                (!String.isEmpty(rate.Package__c)) && (!String.isEmpty(rate.CurrencyIsoCode)) &&
                (!String.isEmpty(rate.Primary_Merchant_Category__c))) {
                rate.Search_Key__c = genKey(rate.Product__c, rate.Package__c, rate.CurrencyIsoCode, rate.Primary_Merchant_Category__c);
            } else { 
                rate.Search_Key__c = null;
            }
            if (rate.Start__c == null) {
                rate.Start__c = Date.newInstance(2000, 1, 1);
            }
            if (rate.End__c == null) {
                rate.End__c = Date.newInstance(3000, 12, 31);
            }
        }
    }

    /**
     * @author:      Dan Meseroll (ATG)
     * @date:        2021-12
     * @description: BZAP-12728 Generate Search key by concatenating fields.
     *               BZAP-13182 Do not default a null Primary Merchant Category
     */
    public static String genKey(Id productId, Id packageId, String currencyCode, String mxCategory){
        //Use empty string to convince apex that this is concat and not math
        String key = '';
        if(!String.isEmpty(productId)){
            key += productId;
        }
        if(!String.isEmpty(packageId)){
            key += packageId;
        }
        if(!String.isEmpty(currencyCode)){
            key += currencyCode;
        } 
        if(!String.isEmpty(mxCategory)){
            key += mxCategory;
        } 
        return key;
    }
}