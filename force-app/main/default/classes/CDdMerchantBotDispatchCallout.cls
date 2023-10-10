// ===========================================================================
// Component: CDdMerchantBotDispatchCallout
// Author: Nayana Kapse
// Purpose: Merchant Chat bot uses this class to make a dispatch callout
// ===========================================================================
public with sharing class CDdMerchantBotDispatchCallout{

    /**
    * @author  Nayana
    * @date    12/2021
    * @decription  Input from chat Bot
    * @param   merchantId : This is deliveryUUId
    */
    public class DeliveryIdInput {
        @InvocableVariable
        public String deliveryUUID;
        @InvocableVariable
        public Double merchantId;

    }

    /**
    * @author  Nayana
    * @date    12/2021
    * @decription  Input from chat Bot
    * @param   dasherInformation : Dasher Info from dispatch
    * @param   merchantId : Merchant Id
    * @param   isPartOfExperiment :Is merchant part of experiment
    */
    public class DeliveryOutput {
        @InvocableVariable
        public String dasherInformation;
        @InvocableVariable
        public Double merchantId;
        @InvocableVariable( required=true )
        public Boolean isPartOfExperiment;
    }

    /**
    * @author  Nayana
    * @date    12/2021
    * @decription  This method is called from Merchant Chat bot
    * @param   DeliveryIdInput : This is coming from Bot
    * @return DeliveryOutput
    */
    @InvocableMethod(label='Get Order Details')
    public static List <DeliveryOutput> fetchOrderDetails( List < DeliveryIdInput > lstDeliveryIds ) {
        List <DeliveryOutput> objOutputs = new List < DeliveryOutput >();
        DeliveryOutput objOutput = new DeliveryOutput();
        objOutput.isPartOfExperiment = false;
        Boolean isException = false;
        //List of Merchant store Ids which are part of this experiment
        try {
            if(String.isBlank(lstDeliveryIds[0].deliveryUUID)){
                objOutputs.add(objOutput);
                return objOutputs;
            }
            List<String> lstStoreIds = new List<String>();
            for(Merchant_Store_Ids__c mStoreId: Merchant_Store_Ids__c.getAll().values()){
                if(String.isNotBlank(mStoreId.Store_Id_1__c)){
                    lstStoreIds.addAll(mStoreId.Store_Id_1__c.replaceAll('(\\s+)', '').split(';'));
                }if(String.isNotBlank(mStoreId.Store_Id_2__c)){
                    lstStoreIds.addAll(mStoreId.Store_Id_2__c.replaceAll('(\\s+)', '').split(';'));
                }if(String.isNotBlank(mStoreId.Store_Id_3__c)){
                    lstStoreIds.addAll(mStoreId.Store_Id_3__c.replaceAll('(\\s+)', '').split(';'));
                }
            }
            for(DeliveryIdInput dId:lstDeliveryIds){
                //Decide merchant is part of experiment or not
                if(dId.merchantId!=null && lstStoreIds.contains(String.valueOf(Integer.valueOf(dId.merchantId)))){
                    objOutput = createDeliverOutput(dId,lstStoreIds);
                }else if(dId.merchantId==null || lstDeliveryIds.isEmpty()){
                    objOutput = createDeliverOutput(dId,lstStoreIds);
                }
            }
        }catch(Exception e){
            CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()+ ' ' + e.getLineNumber() + ' ' + e.getStackTraceString()}, 'CDdMerchantBotContactEmail');
            isException = true;
        }finally{
            if(isException){
                objOutput.isPartOfExperiment = false;
            }
            objOutputs.add(objOutput);
        }
        return objOutputs;
    }

    /**
    * @author  Nayana
    * @date    01/2022
    * @decription  This method is to create the outputwrapper
    * @param   DeliveryIdInput : This is coming from Bot
    * @param   lstStoreIds : List of Store Ids part of POC.If null means open to all Merchants
    * @return DeliveryOutput
    */
    private static DeliveryOutput createDeliverOutput(DeliveryIdInput dId,List<String> lstStoreIds){
        DeliveryOutput objOutput = new DeliveryOutput();
        VDispatchDeliveryCallout dispatchCallout = new VDispatchDeliveryCallout(0, dId.deliveryUUID);
        //Make dispatch callout
        VDeliveryInformation info = dispatchCallout.makeDeliveryCallout();
        if(info != null) {
            objOutput = formatDispatchInfo(info,lstStoreIds);
        }
        return objOutput;
    }
    
    /**
    * @author  Nayana
    * @date    01/2022
    * @decription  This method is to create the outputwrapper
    * @param   DeliveryIdInput : This is coming from Bot
    * @param   lstStoreIds : List of Store Ids part of POC.If null means open to all Merchants
    * @return DeliveryOutput
    */
    @testVisible
    private static DeliveryOutput formatDispatchInfo(VDeliveryInformation info,List<String> lstStoreIds){
        DeliveryOutput objOutput = new DeliveryOutput();
        String dasherName = (String.isNotBlank(info.dasherFirstName) || String.isNotBlank(info.dasherLastName)) ? info.dasherFirstName + ' ' + info.dasherLastName : '';
        String dasherPhone = String.isNotBlank(info.dasherPhoneNumber) ? info.dasherPhoneNumber : '' ;
        String dasherDeliveryStatus = String.isBlank(String.valueOf(info.dasherDeliveryStatus)) ? CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.DASHER_DELIVERY_STATUS_0) : 
                                      CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.DASHER_DELIVERY_STATUS + String.valueOf(info.dasherDeliveryStatus));
        
        if(String.isBlank(dasherName)){
            objOutput.dasherInformation = '\n'+ Label.Mx_Chat_Bot_No_Dasher +
                                '\n' + Label.Mx_Chat_Bot_PickupDate	+ ' '+ info.estPickupDateTimeFormatted +
                                '\n' + Label.Mx_Chat_Bot_Dx_Assignment_Status + ' ' + dasherDeliveryStatus;
        }else{
            objOutput.dasherInformation = '\n'+ Label.Mx_Chat_Bot_Dasher_Name + ' ' + dasherName +'\n'+
            Label.Mx_Chat_Bot_Dasher_Phone + ' ' + dasherPhone +
            '\n' + Label.Mx_Chat_Bot_PickupDate	+ ' ' + info.estPickupDateTimeFormatted +
            '\n' + Label.Mx_Chat_Bot_Dx_Assignment_Status + ' ' + dasherDeliveryStatus;
        }

        Decimal merchantId = info.merchantId!=null ? info.merchantId :0.0;
        //Fetch MercchantId from dispatch callout
        objOutput.merchantId = merchantId;
        if(lstStoreIds.isEmpty() || (!lstStoreIds.isEmpty() && lstStoreIds.contains(String.valueOf(Integer.valueOf(merchantId))))){
            objOutput.isPartOfExperiment = true;
        }
        return objOutput;
    }
}