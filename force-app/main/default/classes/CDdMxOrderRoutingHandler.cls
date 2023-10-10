/********************************************************************************************************************
* @author Praveen
* @date 08/10/2022
*
* @group Merchant Services
*
* @description CDdMxOrderRoutingHandler class will be used to assign the vendor to the mx order based on country and other detilas.
*
**************************************************************************************************************************************/

public class CDdMxOrderRoutingHandler {
    private static final Set<String> REQUEST_TYPE_NEW_TABET = new Set<String>{'Ship to Merchant (New Tablet)'};
    /**
    * @description Method will be called from CDdMxOrderMappingHandlerCaseToMxOrder to assign the vendor for mx Order.
    * @param String denaliRecordId
    * @param Mx_Order_Request__c mxOrderRequest
    * @param String countryCode
    * @param String stateCode
    * @return
    */
    public static String getMxOrderVendor(String denaliRecordId, Mx_Order_Request__c mxOrderRequest, String countryCode, String stateCode, Object deckRankNumber, String typeOfOrder,SObject targetSObject){
        String Language = isNotNull(targetSObject, 'Language__c')? String.valueOf(targetSObject.get('Language__c')):'English';  
        Map<String,Map<String,String>> mxReturnRoutingMap  =  CDdMxSxConstants.getMxReturnRoutingConfig();
        // Mapping to the vendor details. 
        String vendor='';
        // return vendor as denali if routing is not enabled.
        												// label temporary enable the routing for specific user. 
        set<string> allowRoutingForUsers = String.isNotEmpty(System.label.Mx_allow_order_routing)? new set<string>(System.label.Mx_allow_order_routing.split(',')): new set<string>();
        if((!CDdMxSxConstants.ENABLE_MX_ORDER_ROUTING || mxOrderRequest == null || !mxOrderRequest.Is_Routing_Enabled__c || String.isNotBlank(denaliRecordId)) && !allowRoutingForUsers.contains(userinfo.getuserName())){
            return CDdMxSxConstants.MX_VENDOR_DENALI;
        }
        // Below logic will be triggered only if order request type and routing is enabled.
        // get custom metadata and assign the vendor for return order.
        if(CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN == typeOfOrder){
            switch on countryCode {
                when 'CA' {		
                     vendor = CDdMxSxConstants.MX_VENDOR_SOCIAL_MOBILE;     
                }	
                when 'US' {
                    vendor = getVendorForUSA(stateCode, deckRankNumber);
                }               
            }     
        }else{
            switch on countryCode {
                when 'CA' {
                    // route french language orders to Denali because SM doesn't have french collateral Kits. 
                    Boolean frenchOrder = 'French'.equals(Language) && REQUEST_TYPE_NEW_TABET.contains(mxOrderRequest.Request_Type__c); 
                    vendor = !frenchOrder ? CDdMxSxConstants.MX_VENDOR_SOCIAL_MOBILE:CDdMxSxConstants.MX_VENDOR_DENALI;
                }	
                when 'US' {
                    vendor = getVendorForUSA(stateCode, deckRankNumber);
                }               
            }    
        }
        return vendor; 
     }
     public static String getVendorForUSA(String stateCode , Object deckRankNumber){
          return ('PR'.equals(stateCode)) || ('FL'.equals(stateCode)) || deckRankNumber == null || (Integer.valueOf(deckRankNumber) > 4) ?  CDdMxSxConstants.MX_VENDOR_SOCIAL_MOBILE : CDdMxSxConstants.MX_VENDOR_DENALI;           
     }
     private static Boolean isNotNull(SObject sObj, String fieldApiName){
        return sObj.isSet(fieldApiName) && sObj.get(fieldApiName) != null;
    }
    
}