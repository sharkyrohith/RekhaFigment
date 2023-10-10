/********************************************************************************************************************
* @author Sriram
* @date 04/18/2022
*
* @group Merchant Services
*
* @description Mx Order Batch Configuration
* 
**************************************************************************************************************************************/
public class CDdMxOrderBatchConfig {
    private static Map<CDdMxOrderBatchEnum, Mx_Order_Batch_Config__mdt> MX_ORDER_BATCH_CONFIG;
    static {
        MX_ORDER_BATCH_CONFIG = new Map<CDdMxOrderBatchEnum, Mx_Order_Batch_Config__mdt>();
        for (Mx_Order_Batch_Config__mdt config : [  SELECT Batch_Event__c, SObject_Type__c, Batch_Size__c, Last_N_Days__c
                                                    FROM Mx_Order_Batch_Config__mdt
                                                ]){
            MX_ORDER_BATCH_CONFIG.put(CDdMxOrderBatchEnum.valueOf(config.Batch_Event__c), config);
        }
    }
    private CDdMxOrderBatchEnum batchEnum;
    /**
     * @description default constructor
     * @param CDdMxOrderBatchEnum batchEnum
     */
    public CDdMxOrderBatchConfig(CDdMxOrderBatchEnum batchEnum){
        this.batchEnum = batchEnum;
    }
    private Mx_Order_Batch_Config__mdt getConfig(){
        return MX_ORDER_BATCH_CONFIG.get(this.batchEnum);
    }
    /**
     * @description Return the batch size configured for the Batch Event
     * @param
     * @return Integer 
     */
    public Integer getBatchSize(){
        return Integer.valueOf(getConfig().Batch_Size__c != null ? getConfig().Batch_Size__c : CDdMxSxConstants.DEFAULT_BATCH_SIZE);
    }
    /**
     * @description Return the LAST_N_DAYS configured for the Batch Event
     * @param
     * @return Integer 
     */    
    public Integer getLastNDays(){
        return Integer.valueOf(getConfig().Last_N_Days__c != null ? getConfig().Last_N_Days__c : 1);
    }
    /**
     * @description Return the sObject Type configured for the Batch Event
     * @param
     * @return String 
     */    
    public String getSObjectType(){
        return getConfig().SObject_Type__c;
    }             
}