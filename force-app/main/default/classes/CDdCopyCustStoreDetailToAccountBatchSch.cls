/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 10/07/2020
*
* @group SObject Field Copy
*
* @description A batch job schedulable class that executes the batch for one of the following options
*   Copy fields from Customer detail to Account
*   Copy fields from Store detail to Account
*
**************************************************************************************************************************************/
public class CDdCopyCustStoreDetailToAccountBatchSch implements Schedulable {
    private Integer fieldCopyOption;
    private Integer recordSize;        
    public enum fieldCopyOptionType {COPY_CUST_DETAIL_TO_ACCOUNT, COPY_STORE_DETAIL_TO_ACCOUNT}
    public static final Set<Integer> FIELD_COPY_OPTIONS = new Set<Integer>{
                                                                fieldCopyOptionType.COPY_CUST_DETAIL_TO_ACCOUNT.ordinal()
                                                                , fieldCopyOptionType.COPY_STORE_DETAIL_TO_ACCOUNT.ordinal()
                                                            };    
    public static final String ERROR_MSG_INVALID_FIELD_COPY_OPTION = 'Please select a valid field copy option.'
                                                + ' Use value 0 for field copy of customer detail to account. '
                                                + ' Use value 1 for field copy of store detail to account. ';
    public static final Integer DEFAULT_RECORD_SIZE = 50;                                                
   /** 
    * @description A single argument constructor
    * @param fieldCopyOption - What field copy option do you want to schedule the batch job for?
    * Valid options are value 0 for COPY_CUST_DETAIL_TO_ACCOUNT, value 1 for COPY_STORE_DETAIL_TO_ACCOUNT
    */
    public CDdCopyCustStoreDetailToAccountBatchSch(Integer fieldCopyOption) {
        if (fieldCopyOption==null || !FIELD_COPY_OPTIONS.contains(fieldCopyOption)){
            throw new CDdCopyCustStoreDetailToAccountBatchSchException(ERROR_MSG_INVALID_FIELD_COPY_OPTION);
        }
        this.fieldCopyOption = fieldCopyOption;
        this.recordSize = DEFAULT_RECORD_SIZE;
    }
   /** 
    * @description A two argument constructor
    * @param fieldCopyOption - What field copy option do you want to schedule the batch job for?
    * Valid options are value 0 for COPY_CUST_DETAIL_TO_ACCOUNT, value 1 for COPY_STORE_DETAIL_TO_ACCOUNT
    * @param recordSize - What is the value of the processing batch size?    
    */
    public CDdCopyCustStoreDetailToAccountBatchSch(Integer fieldCopyOption, Integer recordSize) {
        this(fieldCopyOption);
        this.recordSize = ((recordSize!=null && recordSize > 0 && recordSize < 200) ? recordSize : DEFAULT_RECORD_SIZE);
    }        
    /** 
    * @description Execute method for the schedulable class
    */  
    public void execute(SchedulableContext sc) {
    	switch on fieldCopyOption {
    		when 0 {
    			Database.executebatch(new CDdCopyCustStoreDetailToAccountBatch(CDdCopyCustStoreDetailToAccountBatch.SOBJECT_TYPE_CUSTOMER_DETAIL), recordSize);
    		}
    		when 1 {
    			Database.executebatch(new CDdCopyCustStoreDetailToAccountBatch(CDdCopyCustStoreDetailToAccountBatch.SOBJECT_TYPE_STORE_DETAIL), recordSize);
    		}
    	}
    }
   /**
    * @description Custom Exception 
    **/     
    public class CDdCopyCustStoreDetailToAccountBatchSchException extends Exception {}                                                    
}