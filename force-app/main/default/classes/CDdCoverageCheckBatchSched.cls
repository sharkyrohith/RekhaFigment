/************************************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 5/16/2019
*
* @group Coverage Check
*
* @description The purpose of this Apex batch scheduler is to execute the coverage check on Account and Lead records 
* Where the input In Coverage Option is one of the following
* - In Coverage is Null or Unknown (value 0)
* - In Coverage is Yes or 'No' (value 1)
* - In Coverage is 'No' (value 2) for Account only
* - In Coverage is 'No' (value 3) for Lead only
* 
**************************************************************************************************************************************/
public class CDdCoverageCheckBatchSched implements Schedulable {
    private Integer inCoverageOption;
    private Integer accountBatchSize;  
    private Integer leadBatchSize;      
    public enum InCoverageOptionType {IN_COVERAGE_OPTION_NULL_OR_UNKNOWN, IN_COVERAGE_OPTION_YES_OR_NO, IN_COVERAGE_OPTION_NO, IN_COVERAGE_OPTION_NO_LEAD}
    public static final Set<Integer> IN_COVERAGE_OPTIONS = new Set<Integer>{
                                                                InCoverageOptionType.IN_COVERAGE_OPTION_NULL_OR_UNKNOWN.ordinal(),
                                                                InCoverageOptionType.IN_COVERAGE_OPTION_YES_OR_NO.ordinal(),
                                                                InCoverageOptionType.IN_COVERAGE_OPTION_NO.ordinal(),
                                                                InCoverageOptionType.IN_COVERAGE_OPTION_NO_LEAD.ordinal() 
                                                            };    
    public static final String ERROR_MSG_INVALID_IN_COVERAGE_OPTION = 'Please select a valid In Coverage option.'
                                                + ' Use value 0 for In Coverage options Null or Unknown. '
                                                + ' Use value 1 for In Coverage option \'Yes\' or \'No\'. '
                                                + ' Use value 2 for In Coverage option \'No\'. '
                                                + ' Use value 3 for Lead In Coverage option \'No\'. ';        
   /** 
    * @description A single argument constructor
    * @param inCoverageOption - What type of In Coverage option do you want to schedule the batch job for?
    * Valid options are value 0 for IN_COVERAGE_OPTION_NULL_OR_UNKNOWN, value 1 for IN_COVERAGE_OPTION_YES_OR_NO, value 2 for IN_COVERAGE_OPTION_NO
    */
    public CDdCoverageCheckBatchSched(Integer inCoverageOption) {
        this(inCoverageOption, CDdCoverageCheckConstants.DEFAULT_BATCH_SIZE, CDdCoverageCheckConstants.DEFAULT_BATCH_SIZE);
    }
   /** 
    * @description Overriding constructor
    * @param inCoverageOption - What type of In Coverage option do you want to schedule the batch job for?
    * @param accountBatchSize - Size of batch transaction to process for Account Coverage Check
    * @param leadBatchSize - Size of batch transaction to process for Lead Coverage Check     
    * Valid options are value 0 for IN_COVERAGE_OPTION_NULL_OR_UNKNOWN, value 1 for IN_COVERAGE_OPTION_YES_OR_NO, value 2 for IN_COVERAGE_OPTION_NO
    */
    public CDdCoverageCheckBatchSched(Integer inCoverageOption, Integer accountBatchSize, Integer leadBatchSize) {
        if (inCoverageOption==null || !IN_COVERAGE_OPTIONS.contains(inCoverageOption)){
            throw new CDdCoverageCheckBatchSchedException(ERROR_MSG_INVALID_IN_COVERAGE_OPTION);
        }
        this.inCoverageOption = inCoverageOption;
        this.accountBatchSize = accountBatchSize;
        this.leadBatchSize = leadBatchSize;
    }        
    /** 
    * @description Execute method for the schedulable class
    * Coverage check batch is queued for Account and Lead records
    */	
    public void execute(SchedulableContext sc) {
        if (InCoverageOptionType.IN_COVERAGE_OPTION_NULL_OR_UNKNOWN.ordinal() == inCoverageOption){
            database.executebatch(new CDdLeadCoverageCheckBatch(
                                        CDdLeadCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN,
                                        10000, False),
                                this.leadBatchSize);
            database.executebatch(new CDdAcctCoverageCheckBatch(
                                        CDdAcctCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_NULL_OR_UNKNOWN,
                                        10000),
                                this.accountBatchSize);            
        } else if (InCoverageOptionType.IN_COVERAGE_OPTION_YES_OR_NO.ordinal() == inCoverageOption){
            database.executebatch(new CDdLeadCoverageCheckBatch(
                                        CDdLeadCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_YES_OR_NO,
                                        null, False),
                                this.leadBatchSize);
            database.executebatch(new CDdAcctCoverageCheckBatch(
                                        CDdAcctCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_YES_OR_NO,
                                        null),
                                this.accountBatchSize);            
        } else if (InCoverageOptionType.IN_COVERAGE_OPTION_NO.ordinal() == inCoverageOption){
            database.executebatch(new CDdAcctCoverageCheckBatch(
                                        CDdAcctCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_NO,
                                        null),
                                this.accountBatchSize);
        } else if (InCoverageOptionType.IN_COVERAGE_OPTION_NO_LEAD.ordinal() == inCoverageOption){	
            database.executebatch(new CDdLeadCoverageCheckBatch(	
                                        CDdLeadCoverageCheckBatch.QUERY_FILTER_IN_COVERAGE_NO,	
                                        null, System.isScheduled()),	
                                this.leadBatchSize);	
        }       
    }
   /**
    * @description Custom Exception 
    **/     
    public class CDdCoverageCheckBatchSchedException extends Exception {}     
}