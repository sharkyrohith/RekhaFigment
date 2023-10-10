/********************************************************************************************************************
* @author Praveen
* @date 07/14/2022
*
* @group Merchant Services
*
* @description test class for CDdMxTestDataFactory.
* 
**************************************************************************************************************************************/


public with sharing class CDdMxTestDataFactory {
    //@Description create Mx products for test classes.
    public static List<Mx_Product__c> createMxProducts() {
        List<Mx_Product__c> mxProducts = new List<Mx_Product__c>();
        mxProducts.add(new Mx_Product__c(
            Family__c = CDdMxSxConstants.MX_PRODUCT_FAMILY_TABLET,
            Name = 'Samsung Galaxy Tab A7 lite',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'TB-0000-00000000'
        ));
        mxProducts.add(new Mx_Product__c(
            Family__c = 'Marketing Kit',
            Name = 'Overture Box US English',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'MK-0000-01000000',
            Language__c = 'English'
        ));
        mxProducts.add(new Mx_Product__c(
            Family__c = 'Marketing Kit',
            Name = 'Overture Box US Spanish',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'MK-0000-02000000',
            Language__c = 'Spanish'
        ));
        mxProducts.add(new Mx_Product__c(
            Family__c = CDdMxSxConstants.MX_PRODUCT_FAMILY_PRINTER,
            Name = 'Samsung Galaxy Printer',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'PR-0000-00000000'
        ));                        
        insert mxProducts;
        return mxProducts;
    }
    //@Description create Mx Order request products for test classes.
    public static Mx_Order_Request__c createMxOrderRequest(String requestType, String countryCode, List<Mx_Product__c> mxProducts){
        Mx_Order_Request__c request = new Mx_Order_Request__c(
            Is_Active__c = TRUE,
            Request_Type__c = requestType,
            Country_Code__c = countryCode,
            Is_Routing_Enabled__c = true,
            Request_Type_Family__c = 'New'
        );
        insert request;
        List<Mx_Order_Request_Product__c> mxOrderRequestProducts = new List<Mx_Order_Request_Product__c>();
        for (Mx_Product__c mxProduct : mxProducts){
            mxOrderRequestProducts.add(new Mx_Order_Request_Product__c(
                Mx_Order_Request__c = request.Id,
                Mx_Product__c = mxProduct.Id
            ));
        }
        insert mxOrderRequestProducts;
        return request;
    }
    public static Mx_Order_Request__c createReturnMxOrderRequest(String requestType, String countryCode, List<Mx_Product__c> mxProducts){
        Mx_Order_Request__c request = new Mx_Order_Request__c(
            Is_Active__c = TRUE,
            Request_Type__c = requestType,
            Country_Code__c = countryCode,
            Is_Routing_Enabled__c = true,
            Request_Type_Family__c = 'Return Only'
        );
        insert request;
        List<Mx_Order_Request_Product__c> mxOrderRequestProducts = new List<Mx_Order_Request_Product__c>();
        for (Mx_Product__c mxProduct : mxProducts){
            mxOrderRequestProducts.add(new Mx_Order_Request_Product__c(
                Mx_Order_Request__c = request.Id,
                Mx_Product__c = mxProduct.Id
            ));
        }
        insert mxOrderRequestProducts;
        return request;
    }
}