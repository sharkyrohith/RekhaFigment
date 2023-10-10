/********************************************************************************************************************
* @author lathika
* @date
*
*  @group Merchant Services
*
* @description
* Class which handles the methods to create shipment records.
*  
**************************************************************************************************************************************/
public class CDdMxOrderShipmentService {
    /**
     * Define static variables here
     */
    public static Map<String, Mx_Order_Shipment_Config__mdt> MX_ORDER_SHIPMENT_CONFIG_BY_SHIPPING_CARRIER_VENDOR_AND_COUNTRY;
    private static Map<String, Id> SHIPPING_PREFERENCE_ID_BY_SHIPPING_CARRIER_ACCOUNT_NUMBER;
    private static final String ZK_MULTI_MODE_KEY = 'ZKMULTI2016';
    private static String SHIPPING_PREFERENCE_CARRIER_VENDOR_COUNTRY_KEY = '{0} - {1} - {2}';

    static {
        SHIPPING_PREFERENCE_ID_BY_SHIPPING_CARRIER_ACCOUNT_NUMBER = new Map<String, Id>();
        MX_ORDER_SHIPMENT_CONFIG_BY_SHIPPING_CARRIER_VENDOR_AND_COUNTRY = new Map<String,Mx_Order_Shipment_Config__mdt>();
        Set<String> shippingCarrierAccountNumbers = new Set<String>();
        for (Mx_Order_Shipment_Config__mdt config : [   SELECT Id,Country_Code__c , Shipping_Carrier_Account_Number__c, Shipping_Carrier__c, Vendor__c
                                                        FROM Mx_Order_Shipment_Config__mdt
                                                        WHERE Is_Active__c = TRUE]){
            shippingCarrierAccountNumbers.add(config.Shipping_Carrier_Account_Number__c);                                              
            MX_ORDER_SHIPMENT_CONFIG_BY_SHIPPING_CARRIER_VENDOR_AND_COUNTRY.put(String.format(SHIPPING_PREFERENCE_CARRIER_VENDOR_COUNTRY_KEY, new List<Object>{config.Shipping_Carrier__c,config.Vendor__c,config.Country_Code__c}), config);
        }
        for (zkmulti__MCShipmate_Preference__c pref : [ SELECT Id, zkmulti__AccountNumber__c 
                                                        FROM zkmulti__MCShipmate_Preference__c 
                                                        WHERE zkmulti__AccountNumber__c IN :shippingCarrierAccountNumbers]){
            SHIPPING_PREFERENCE_ID_BY_SHIPPING_CARRIER_ACCOUNT_NUMBER.put(pref.zkmulti__AccountNumber__c, pref.Id);
        }                                    
    }
    /**
     * Define class variables here
     */    
    private List<zkmulti__MCShipment__c> shipmentsToProcess;
    /**
  	 * @description Default Constructor - inject the  mxOrder records and initialize any member variables
  	 * @param List<Mx_Order__c> mxOrders
     * @return 	
  	 */
    public CDdMxOrderShipmentService(List<Mx_Order__c> mxOrders){ 
        this.setShipmentsToProcess(mxOrders);
    }
    /**
     * @description Prepare Shipment Records for specific Merchant Orders only
     * 1. Extract the Case Record Ids from the Merchant Order records
     * 2. Use the Case Record Ids to determine the Shipment Records that are already created for certain Case records
     * 3. Process only the Merchant Orders that do not have a corresponding Shipment record (determined by Case Id from Step 2)
     *      a. Process Merchant Order that have a tracking number set on the record
     *      b. Merchant Order based on Shipping Carrier and Vendor must have a corresponding configured Shipping Preference record
     * @param List<Mx_Order__c> mxOrders
     * @return 
     */
    private void setShipmentsToProcess(List<Mx_Order__c> mxOrders){
        this.shipmentsToProcess = new List<zkmulti__MCShipment__c>();
        Set<Id> caseIds = new Set<Id>();
        // 1. Extract the Case Record Ids from the Merchant Order records
        for (Mx_Order__c mxOrder : mxOrders){
            if (String.isNotBlank(mxOrder.Case__c)){
                caseIds.add(mxOrder.Case__c);
            }
        }
        Map<Id, zkmulti__MCShipment__c> existingShipmentRecordsForCaseIds = this.getExistingShipmentRecordsForCaseIds(caseIds);
        for (Mx_Order__c mxOrder : mxOrders){
            if (!existingShipmentRecordsForCaseIds.containsKey(mxOrder.Case__c) 
                    && String.isNotBlank(mxOrder.Shipping_Tracking_Number__c)
                    && hasShippingPreference(mxOrder.Shipping_Carrier__c, mxOrder.Vendor__c,mxOrder.Country_Code__c)){
                this.shipmentsToProcess.add(
                    new zkmulti__MCShipment__c(
                        Case__c = mxOrder.Case__c,
                        Mx_Order__c = mxOrder.Id,
                        zkmulti__Shipmate_Preference__c = getShippingPreferenceId(mxOrder.Shipping_Carrier__c, mxOrder.Vendor__c,mxOrder.Country_Code__c),
                        zkmulti__Mod_Key__c = ZK_MULTI_MODE_KEY,
                        zkmulti__Tracking_Number__c = mxorder.Shipping_Tracking_Number__c
                    )
                );
            }
        }
    }
    /**
     * @description Retrieve existing shipping records for input Case Ids
     * Query is performant when retrieved for input Case Ids as the field Case__c (lookup) is indexed
     * @param Set<Id> caseIds
     * @return Map<Id, zkmulti__MCShipment__c>
     */
    public Map<Id, zkmulti__MCShipment__c> getExistingShipmentRecordsForCaseIds(Set<Id> caseIds){
        Map<Id, zkmulti__MCShipment__c> existingShipmentRecordsForCaseIds = new Map<Id, zkmulti__MCShipment__c>();
        for (zkmulti__MCShipment__c shipment : [SELECT Id, zkmulti__Tracking_Number__c, Case__c, Mx_Order__c 
                                                FROM zkmulti__MCShipment__c
                                                WHERE Case__c IN :caseIds]){
            existingShipmentRecordsForCaseIds.put(shipment.Case__c, shipment);
        }
        return existingShipmentRecordsForCaseIds;
    }
    /** 
     * @description Create Shipment records
     * @param 
     * @return void
     */
    public void createShipments() {
        try{
            insert this.shipmentsToProcess;
        }catch(Exception e){
            CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()}, 'CDdMxOrderShipmentService');
        }
    }
    private Boolean hasShippingPreference(String shippingCarrier, String vendor,String countryCode){
         return MX_ORDER_SHIPMENT_CONFIG_BY_SHIPPING_CARRIER_VENDOR_AND_COUNTRY.containsKey(String.format(SHIPPING_PREFERENCE_CARRIER_VENDOR_COUNTRY_KEY, new List<Object>{shippingCarrier,vendor,countryCode}));
    }
    private Id getShippingPreferenceId(String shippingCarrier, String vendor, String countryCode){
         return hasShippingPreference(ShippingCarrier, vendor, countryCode ) 
                    ? SHIPPING_PREFERENCE_ID_BY_SHIPPING_CARRIER_ACCOUNT_NUMBER
            .get(MX_ORDER_SHIPMENT_CONFIG_BY_SHIPPING_CARRIER_VENDOR_AND_COUNTRY.get(String.format(SHIPPING_PREFERENCE_CARRIER_VENDOR_COUNTRY_KEY, new List<Object>{shippingCarrier,vendor,countryCode})).Shipping_Carrier_Account_Number__c)
                    : null;
    }
 }