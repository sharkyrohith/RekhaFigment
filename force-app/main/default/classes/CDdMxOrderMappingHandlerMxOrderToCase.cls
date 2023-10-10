/********************************************************************************************************************
* @author Sriram
* @date 03/16/2022
*
* @group Merchant Services
*
* @description Mapping handler implementation
*              Apex Handler Class that implements specific logic to copy over field values from Source to Target sObject
* 
**************************************************************************************************************************************/
public class CDdMxOrderMappingHandlerMxOrderToCase implements CDdMxOrderMappingHandlerInterface {
    private static final Set<String> SOURCE_SOBJECT_API_FIELDS = new Set<String>{
        'Case__c',
        'Order_Id__c',
        'Vendor__c',
        'Shipping_Method__c',
        'Shipping_Carrier__c',
        'Shipping_Tracking_Number__c',
        'Country_Code__c'
    };
    private static final Set<String> TARGET_SOBJECT_API_FIELDS = new Set<String>{
        'Id',
        //'Denali_Record_ID__c', //Do not set Social Mobile Order Id on this Case field. Denali may run into integration issues
        'Shipping_Type__c',
        'Tablet_Tracking_FedEx__c',
        'Tablet_Tracking_UPS__c',
        'USPS_Tracking_Number__c',
        'Tablet_Tracking__c',
        'Tracking_StarTrack__c'
    };
    public Set<String> getSourceSObjectApiFields(){
        return SOURCE_SOBJECT_API_FIELDS;
    }
    public Set<String> getTargetSObjectApiFields(){
        return TARGET_SOBJECT_API_FIELDS;
    }    
    public Boolean copyFields(CDdMxOrderEventEnum event, SObject sourceSObject, SObject targetSObject, String targetSObjectDmlOperation){
        Boolean isUpdated = ('INSERT'.equals(targetSObjectDmlOperation));
        if (String.isNotBlank(this.getVendor(sourceSObject)) && CDdMxSxConstants.MX_VENDOR_DENALI.equals(this.getVendor(sourceSObject))) { return isUpdated; }
        switch on event {
            when UPDATE_CASE_FOR_MX_ORDER_DELIVERED, UPDATE_CASE_FOR_MX_ORDER_LABELED, UPDATE_CASE_FOR_MX_ORDER_SHIPPED,UPDATE_CASE_FOR_MX_ORDER_PARTIALLY_DELIVERED {
                isUpdated = (this.handleShippingMethod(sourceSObject, targetSObject) || isUpdated);
                isUpdated = (this.handleShippingCarrierAndTracking(sourceSObject, targetSObject) || isUpdated);               
            }            
            when else {}
        }
        return isUpdated;
    }
    private Boolean handleShippingMethod(SObject sourceSObject, SObject targetSObject){
        Boolean isUpdated = false;
        if (isNotNull(sourceSObject, 'Shipping_Method__c')){
            if (!isEquals(sourceSObject, targetSObject, 'Shipping_Method__c', 'Shipping_Type__c')){
                targetSObject.put('Shipping_Type__c', sourceSObject.get('Shipping_Method__c'));
                isUpdated = true;
            }
        }
        return isUpdated;
    }
    private Boolean handleShippingCarrierAndTracking(SObject sourceSObject, SObject targetSObject){
        Boolean isUpdated = false;
        if (isNotNull(sourceSObject, 'Country_Code__c')){
            if (isNotNull(sourceSObject, 'Shipping_Carrier__c')){
                String shippingCarrier = String.valueOf(sourceSObject.get('Shipping_Carrier__c'));                
                if (isNotNull(sourceSObject, 'Shipping_Tracking_Number__c')){
                    switch on CDdMxSxConstants.MX_SHIPPING_CARRIER_STRING_TO_ENUM.get(shippingCarrier) {
                        when DHLEXPRESS, SAGAWA_EXPRESS {
                            if (!isEquals(sourceSObject, targetSObject, 'Shipping_Tracking_Number__c', 'Tablet_Tracking__c')){
                                targetSObject.put('Tablet_Tracking__c', sourceSObject.get('Shipping_Tracking_Number__c'));
                                isUpdated = true;
                            }                            
                        }                        
                        when FEDEX {
                            if (!isEquals(sourceSObject, targetSObject, 'Shipping_Tracking_Number__c', 'Tablet_Tracking_FedEx__c')){
                                targetSObject.put('Tablet_Tracking_FedEx__c', sourceSObject.get('Shipping_Tracking_Number__c'));
                                isUpdated = true;
                            }
                        }
                        when STARTRACK {
                            if (!isEquals(sourceSObject, targetSObject, 'Shipping_Tracking_Number__c', 'Tracking_StarTrack__c')){
                                targetSObject.put('Tracking_StarTrack__c', sourceSObject.get('Shipping_Tracking_Number__c'));
                                isUpdated = true;
                            }                            
                        }                                                
                        when UPS {
                            if (!isEquals(sourceSObject, targetSObject, 'Shipping_Tracking_Number__c', 'Tablet_Tracking_UPS__c')){
                                targetSObject.put('Tablet_Tracking_UPS__c', sourceSObject.get('Shipping_Tracking_Number__c'));
                                isUpdated = true;
                            }                            
                        }
                        when USPS {
                            if (!isEquals(sourceSObject, targetSObject, 'Shipping_Tracking_Number__c', 'USPS_Tracking_Number__c')){
                                targetSObject.put('USPS_Tracking_Number__c', sourceSObject.get('Shipping_Tracking_Number__c'));
                                isUpdated = true;
                            }                            
                        }
                        when else {}
                    }
                }
            }
        }
        return isUpdated;
    }
    private String getVendor(SObject sourceSObject){
        String vendor = null;
        if (isNotNull(sourceSObject, 'Vendor__c')){
            vendor = (String)sourceSObject.get('Vendor__c');
        }
        return vendor;
    }    
    private Boolean isEquals(SObject sourceSObject, SObject targetSObject, String sourceSObjectFieldApiName, String targetSObjectFieldApiName){
        return isNotNull(sourceSObject, sourceSObjectFieldApiName) && isNotNull(targetSObject, targetSObjectFieldApiName) && (sourceSObject.get(sourceSObjectFieldApiName) == targetSObject.get(targetSObjectFieldApiName));
    }    
    private Boolean isNotNull(SObject sObj, String fieldApiName){
        return sObj.isSet(fieldApiName) && sObj.get(fieldApiName) != null;
    }
}