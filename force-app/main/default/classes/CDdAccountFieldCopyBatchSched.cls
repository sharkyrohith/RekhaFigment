/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/05/2019
*
* @group SObject Field Copy
*
* @description A batch job schedulable class that executes the batch for one of the following options
*   Copy fields from Parent Account to child accounts
*   Copy fields from Account to Contact
*   Copy fields from Account to Opportunity
*
**************************************************************************************************************************************/
public class CDdAccountFieldCopyBatchSched implements Schedulable {
    private Integer fieldCopyOption;
    private Integer recordSize;        
    public enum fieldCopyOptionType {COPY_TO_CHILD_ACCOUNT, COPY_TO_CONTACT, COPY_TO_OPPORTUNITY}
    public static final Set<Integer> FIELD_COPY_OPTIONS = new Set<Integer>{
                                                                fieldCopyOptionType.COPY_TO_CHILD_ACCOUNT.ordinal()
                                                                , fieldCopyOptionType.COPY_TO_CONTACT.ordinal()
                                                                , fieldCopyOptionType.COPY_TO_OPPORTUNITY.ordinal()
                                                            };    
    public static final String ERROR_MSG_INVALID_FIELD_COPY_OPTION = 'Please select a valid field copy option.'
                                                + ' Use value 0 for field copy to child account. '
                                                + ' Use value 1 for field copy to contact. '
                                                + ' Use value 2 for field copy to opportunity. ';
    public static final Integer DEFAULT_RECORD_SIZE = 50;                                                
   /** 
    * @description A single argument constructor
    * @param fieldCopyOption - What field copy option do you want to schedule the batch job for?
    * Valid options are value 0 for COPY_TO_CHILD_ACCOUNT, value 1 for COPY_TO_CONTACT, value 2 for COPY_TO_OPPORTUNITY
    */
    public CDdAccountFieldCopyBatchSched(Integer fieldCopyOption) {
        if (fieldCopyOption==null || !FIELD_COPY_OPTIONS.contains(fieldCopyOption)){
            throw new CDdAccountFieldCopyBatchSchedException(ERROR_MSG_INVALID_FIELD_COPY_OPTION);
        }
        this.fieldCopyOption = fieldCopyOption;
        this.recordSize = DEFAULT_RECORD_SIZE;
    }
   /** 
    * @description A two argument constructor
    * @param fieldCopyOption - What field copy option do you want to schedule the batch job for?
    * Valid options are value 0 for COPY_TO_CHILD_ACCOUNT, value 1 for COPY_TO_CONTACT, value 2 for COPY_TO_OPPORTUNITY
    * @param recordSize - What is the value of the processing batch size?    
    */
    public CDdAccountFieldCopyBatchSched(Integer fieldCopyOption, Integer recordSize) {
        this(fieldCopyOption);
        this.recordSize = ((recordSize!=null && recordSize > 0 && recordSize < 200) ? recordSize : DEFAULT_RECORD_SIZE);
    }        
    /** 
    * @description Execute method for the schedulable class
    */  
    public void execute(SchedulableContext sc) {
        if (fieldCopyOptionType.COPY_TO_CHILD_ACCOUNT.ordinal() == fieldCopyOption){
            Database.executebatch(new CDdAccountFieldCopyToAccountBatch(), recordSize);
        } else if (fieldCopyOptionType.COPY_TO_CONTACT.ordinal() == fieldCopyOption){
            Database.executebatch(new CDdAccountFieldCopyToContactBatch(), recordSize);         
        } else if (fieldCopyOptionType.COPY_TO_OPPORTUNITY.ordinal() == fieldCopyOption){
            Database.executebatch(new CDdAccountFieldCopyToOpportunityBatch(), recordSize);         
        }      
    }
   /**
    * @description Custom Exception 
    **/     
    public class CDdAccountFieldCopyBatchSchedException extends Exception {}                                                    
}