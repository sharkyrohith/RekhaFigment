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
public class CDdMxOrderMappingHandlerCaseToMxOrder implements CDdMxOrderMappingHandlerInterface { 
    private static final Set<String> SOURCE_SOBJECT_API_FIELDS = new Set<String>{
        'Denali_Record_ID__c',
        'Shipping_Type__c',
        'Tablet_Tracking_FedEx__c',
        'Tablet_Tracking_UPS__c',
        'USPS_Tracking_Number__c',
        'Tablet_Tracking__c',
        'Tracking_StarTrack__c',
        'Account.BillingCountryCode',
        'Account.Deck_Rank_Number__c',
        'Account.BillingStateCode'
    };
    private static final Set<String> TARGET_SOBJECT_API_FIELDS = new Set<String>{
        'Order_Id__c',
        'Vendor__c',
        'Shipping_Method__c',
        'Shipping_Carrier__c',
        'Shipping_Tracking_Number__c',
        'Country_Code__c',
        'Mx_Order_Request__c',
        'Is_Tablet_Included__c',
        'State__c'
    };
    public Set<String> getSourceSObjectApiFields(){
        return SOURCE_SOBJECT_API_FIELDS;
    }
    public Set<String> getTargetSObjectApiFields(){
        return TARGET_SOBJECT_API_FIELDS;
    }    
    public Boolean copyFields(CDdMxOrderEventEnum event, SObject sourceSObject, SObject targetSObject, String targetSObjectDmlOperation){
        Boolean isUpdated = ('INSERT'.equals(targetSObjectDmlOperation));
        switch on event {
            when GENERATE_MX_ORDER, UPDATE_NONQUEUED_MX_ORDER_FOR_CASE_UPDATE {
                isUpdated = (this.handleNonQueuedOrderRequest(sourceSObject, targetSObject, targetSObjectDmlOperation) || isUpdated);
                isUpdated = (this.handleQueuedOrderRequest(sourceSObject, targetSObject) || isUpdated);
                isUpdated = (this.handleShippingState(sourceSObject, targetSObject) || isUpdated);
                isUpdated = (this.handleShippingMethod(sourceSObject, targetSObject) || isUpdated);
            }
            when UPDATE_MX_ORDER_FOR_CASE_SHIPPED, UPDATE_MX_ORDER_FOR_CASE_RECEIVED {
                isUpdated = (this.handleQueuedOrderRequest(sourceSObject, targetSObject) || isUpdated);
                isUpdated = (this.handleShippingState(sourceSObject, targetSObject) || isUpdated);
                isUpdated = (this.handleShippingMethod(sourceSObject, targetSObject) || isUpdated);
                isUpdated = (this.handleShippingCarrierAndTracking(sourceSObject, targetSObject) || isUpdated);
            }            
            when else {}
        }
        return isUpdated;
    }
    private Boolean handleNonQueuedOrderRequest(SObject sourceSObject, SObject targetSObject, String targetSObjectDmlOperation){
        Boolean isUpdated = false;
        if (isNotNull(sourceSObject, 'Request_Type__c')){
            String requestType = String.valueOf(sourceSObject.get('Request_Type__c'));
            String stateCode = String.valueOf(getFieldValue(sourceSObject, 'Account.BillingStateCode'));
            String countryCode = String.valueOf(getFieldValue(sourceSObject, 'Account.BillingCountryCode'));
            Object deckRankNumber = getFieldValue(sourceSObject, 'Account.Deck_Rank_Number__c');
            String denaliRecordId = isNotNull(sourceSObject, 'Denali_Record_ID__c') ? String.valueOf(sourceSObject.get('Denali_Record_ID__c')) : null;
            // Set Mx Order Request that determines what products will be fulfilled for this order
            Mx_Order_Request__c mxOrderRequest = CDdMxOrderEventHelper.getMxOrderRequest(requestType, countryCode);
            Id sourceMxOrderRequestId = ( (mxOrderRequest != null) ? mxOrderRequest.Id : null );
            Id targetMxOrderRequestId = (Id)(targetSObject.get('Mx_Order_Request__c'));
            if ( ('INSERT'.equals(targetSObjectDmlOperation)) || (sourceMxOrderRequestId != targetMxOrderRequestId) ){
                targetSObject.put('Mx_Order_Request__c', sourceMxOrderRequestId);
                isUpdated = true;
            }
            String typeOfMxOrder =  String.valueOf(getFieldValue(sourceSObject, 'Type_Of_Mx_Order__c')); 
            // Set Vendor who will fulfill this order, AKA - routing logic            
            String sourceVendor = CDdMxOrderRoutingHandler.getMxOrderVendor(denaliRecordId, mxOrderRequest, countryCode, stateCode, deckRankNumber,typeOfMxOrder,targetSObject);
            String targetVendor = (String)(targetSObject.get('Vendor__c'));
            if ( ('INSERT'.equals(targetSObjectDmlOperation)) || (sourceVendor != targetVendor) ){
                targetSObject.put('Vendor__c', sourceVendor);
                isUpdated = true;
            }
            // Set the flag that determines whether a tablet is included within the order. 
            // If so, MuleSoft will validate the tablet credentials prior to sending the order to the vendor
            Boolean sourceIsTabletIncluded = CDdMxSxConstants.REQUEST_TYPES_THAT_INCLUDE_TABLET.contains(requestType);
            Boolean targetIsTabletIncluded = (isNotNull(targetSObject, 'Is_Tablet_Included__c') ? (Boolean)(getFieldValue(targetSObject, 'Is_Tablet_Included__c')) : false);                         
            if (('INSERT'.equals(targetSObjectDmlOperation)) || (sourceIsTabletIncluded != targetIsTabletIncluded)){
                targetSObject.put('Is_Tablet_Included__c', sourceIsTabletIncluded);
                isUpdated = true;
            }            
        }
        return isUpdated;        
    }
    private Boolean handleQueuedOrderRequest(SObject sourceSObject, SObject targetSObject){
        Boolean isUpdated = false;
        if (isNotNull(sourceSObject, 'Denali_Record_ID__c') && isNotNull(targetSObject, 'Vendor__c') && (((String)targetSObject.get('Vendor__c')).equals(CDdMxSxConstants.MX_VENDOR_DENALI))){
            if (!isEquals(sourceSObject, targetSObject, 'Denali_Record_ID__c', 'Order_Id__c')){
                targetSObject.put('Order_Id__c', sourceSObject.get('Denali_Record_ID__c'));
                isUpdated = true;
            }                            
        }        
        return isUpdated;
    }    
    private Boolean handleShippingState(SObject sourceSObject, SObject targetSObject){
        Boolean isUpdated = false;
        String sourceValue = String.valueOf(getFieldValue(sourceSObject, 'Account.BillingStateCode'));
        if (String.isNotBlank(sourceValue)){
            if (!isNotNull(targetSObject, 'State__c') || (!sourceValue.equals(String.valueOf(targetSObject.get('State__c'))))){
                targetSObject.put('State__c', sourceValue);
                isUpdated = true;
            }
        }
        return isUpdated;
    }        
    private Boolean handleShippingMethod(SObject sourceSObject, SObject targetSObject){
        Boolean isUpdated = false;
        if (isNotNull(sourceSObject, 'Shipping_Type__c')){
            if (!isEquals(sourceSObject, targetSObject, 'Shipping_Type__c', 'Shipping_Method__c')){
                String sourceValue = String.valueOf(sourceSObject.get('Shipping_Type__c'));
                switch on sourceValue {
                    when 'Expedited' {
                        targetSObject.put('Shipping_Method__c', CDdMxSxConstants.MX_SHIPPING_METHOD_EXPEDITED);
                    }
                    when else {
                        targetSObject.put('Shipping_Method__c', CDdMxSxConstants.MX_SHIPPING_METHOD_STANDARD);
                    }
                }
                isUpdated = true;
            }
        }
        return isUpdated;
    }
    private Boolean handleShippingCarrierAndTracking(SObject sourceSObject, SObject targetSObject){
        Boolean isUpdated = false;
        String countryCode = String.valueOf(getFieldValue(sourceSObject, 'Account.BillingCountryCode'));
        if (String.isNotBlank(countryCode)){
            switch on countryCode {
                when 'US', 'CA', 'AU' {
                    if (isNotNull(sourceSObject, 'Tablet_Tracking_FedEx__c')){
                        if (!isEquals(sourceSObject, targetSObject, 'Tablet_Tracking_FedEx__c', 'Shipping_Tracking_Number__c')){
                            targetSObject.put('Shipping_Carrier__c', CDdMxSxConstants.MX_SHIPPING_CARRIER_FEDEX);
                            targetSObject.put('Shipping_Tracking_Number__c', sourceSObject.get('Tablet_Tracking_FedEx__c'));
                            isUpdated = true;
                        }
                    }
                    if (isNotNull(sourceSObject, 'Tablet_Tracking_UPS__c')){
                        if (!isEquals(sourceSObject, targetSObject, 'Tablet_Tracking_UPS__c', 'Shipping_Tracking_Number__c')){
                            targetSObject.put('Shipping_Carrier__c', CDdMxSxConstants.MX_SHIPPING_CARRIER_UPS);
                            targetSObject.put('Shipping_Tracking_Number__c', sourceSObject.get('Tablet_Tracking_UPS__c'));
                            isUpdated = true;
                        }
                    }
                    if (isNotNull(sourceSObject, 'USPS_Tracking_Number__c')){
                        if (!isEquals(sourceSObject, targetSObject, 'USPS_Tracking_Number__c', 'Shipping_Tracking_Number__c')){
                            targetSObject.put('Shipping_Carrier__c', CDdMxSxConstants.MX_SHIPPING_CARRIER_USPS);
                            targetSObject.put('Shipping_Tracking_Number__c', sourceSObject.get('USPS_Tracking_Number__c'));
                            isUpdated = true;
                        }                            
                    }
                    if (isNotNull(sourceSObject, 'Tracking_StarTrack__c')){
                        if (!isEquals(sourceSObject, targetSObject, 'Tracking_StarTrack__c', 'Shipping_Tracking_Number__c')){
                            targetSObject.put('Shipping_Carrier__c', CDdMxSxConstants.MX_SHIPPING_CARRIER_STARTRACK);
                            targetSObject.put('Shipping_Tracking_Number__c', sourceSObject.get('Tracking_StarTrack__c'));
                            isUpdated = true;
                        }                            
                    }                                         
                }
                when 'DE', 'NZ' {
                    if (isNotNull(sourceSObject, 'Tablet_Tracking__c')){
                        if (!isEquals(sourceSObject, targetSObject, 'Tablet_Tracking__c', 'Shipping_Tracking_Number__c')){
                            targetSObject.put('Shipping_Carrier__c', CDdMxSxConstants.MX_SHIPPING_CARRIER_DHL_EXPRESS);
                            targetSObject.put('Shipping_Tracking_Number__c', sourceSObject.get('Tablet_Tracking__c'));
                            isUpdated = true;
                        }                        
                    }                                      
                }
                when 'JP' {
                    if (isNotNull(sourceSObject, 'Tablet_Tracking__c')){
                        if (!isEquals(sourceSObject, targetSObject, 'Tablet_Tracking__c', 'Shipping_Tracking_Number__c')){
                            targetSObject.put('Shipping_Carrier__c', CDdMxSxConstants.MX_SHIPPING_CARRIER_SAGAWA_EXPRESS);
                            targetSObject.put('Shipping_Tracking_Number__c', sourceSObject.get('Tablet_Tracking__c'));
                            isUpdated = true;
                        }                             
                    }                                      
                }
                when else {}                                
            }
        }
        return isUpdated;
    }
    private Boolean isEquals(SObject sourceSObject, SObject targetSObject, String sourceSObjectFieldApiName, String targetSObjectFieldApiName){
        return isNotNull(sourceSObject, sourceSObjectFieldApiName) && isNotNull(targetSObject, targetSObjectFieldApiName) && (sourceSObject.get(sourceSObjectFieldApiName) == targetSObject.get(targetSObjectFieldApiName));
    }
    private Boolean isNotNull(SObject sObj, String fieldApiName){
        return sObj.isSet(fieldApiName) && sObj.get(fieldApiName) != null;
    }
    /**
     * @description Extracts the field value from the Api field name
     * @param sObject obj
     * @param String fieldAPI
     * @return String value
     */
    private Object getFieldValue(sObject obj, String fieldAPI){
        Object value = null;
        List<String> fieldAPIs = fieldAPI.split('\\.');    
        if(!fieldAPIs.isEmpty()){
            for(Integer i = 0; i<fieldAPIs.Size(); i++){
                if(obj != null){
                    if( i == (fieldAPIs.Size() - 1)){
                        value = obj.get(fieldAPIs[i]);
                    }else{
                        obj = (sObject)obj.getSobject(fieldAPIs[i]);
                    } 
                }
           } 
        }
        return value ;
    }    
}