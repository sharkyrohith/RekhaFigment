/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/15/2020
*
* @group SObject Field Copy
*
* @description This is the SObject Copy Config Object that holds configuration information such as 
* - Threshold Size (Threshold size of the records that determines whether the processing may occur within the same transaction vs processing via a batch job)
* - Batch Size (Default size of the records to be processed within a single batch transaction)
* 
**************************************************************************************************************************************/
public class CDdSObjectCopyConfigObj {

    private static final String COPY_TO_PATTERN_BATCH_SIZE = 'Copy_To_{0}_Batch_Size__c';
    private static final String COPY_TO_PATTERN_THRESHOLD_SIZE = 'Copy_To_{0}_Threshold_Size__c';

    private static final SObject_Copy_Config__mdt sObjectCopyConfig;

    static {
        for (SObject_Copy_Config__mdt d :   [SELECT Id, MasterLabel, DeveloperName,
                                            Copy_To_Account_Batch_Size__c, Copy_To_Account_Threshold_Size__c,
                                            Copy_To_Contact_Batch_Size__c, Copy_To_Contact_Threshold_Size__c,
                                            Copy_To_Lead_Batch_Size__c, Copy_To_Lead_Threshold_Size__c,
                                            Copy_To_Opportunity_Batch_Size__c, Copy_To_Opportunity_Threshold_Size__c                                            
                                            FROM SObject_Copy_Config__mdt]){
            sObjectCopyConfig = d;
        }
    }
    /**
    * @description Return the configured batch size for the input SObject Type
    * @param <String> sObjectType Example: Account, Contact, Opportunity, Lead
    * @return Return the configured batch size
    */
    public Integer getBatchSize(String sObjectType){
        return Integer.valueOf(sObjectCopyConfig.get(String.format(COPY_TO_PATTERN_BATCH_SIZE, new String[]{sObjectType})));
    }
    /**
    * @description Return the configured threshold size for the input SObject Type
    * @param <String> sObjectType Example: Account, Contact, Opportunity, Lead
    * @return Return the configured threshold size
    */
    public Integer getThresholdSize(String sObjectType){
        return Integer.valueOf(sObjectCopyConfig.get(String.format(COPY_TO_PATTERN_THRESHOLD_SIZE, new String[]{sObjectType})));
    }       
}