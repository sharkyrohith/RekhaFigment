/************************************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/05/2019
*
* @group Update Task Count
*
* @description The purpose of this Apex batch scheduler is to execute the update task count on Account and Lead records 
* Where the input SObject Type Option is one of the following
* - LEAD (value 0)
* - ACCOUNT (value 1)
* 
**************************************************************************************************************************************/
public class CDdUpdateTaskCountBatchSched implements Schedulable {
    private Integer sObjectTypeOption;
    public enum SObjectOptionType {Lead, Account}
    public static final Map<Integer, String> SOBJECT_TYPE_OPTIONS = new Map<Integer, String>{
                                                                SObjectOptionType.Lead.ordinal() => SObjectOptionType.Lead.name()
                                                                , SObjectOptionType.Account.ordinal() => SObjectOptionType.Account.name()
                                                            };    
    public static final String ERROR_MSG_INVALID_SOBJECT_TYPE_OPTION = 'Please select a valid SObject Type option.'
                                                + ' Use value 0 for SObject Type Lead. '
                                                + ' Use value 1 for SObject Type Account. ';        
   /** 
    * @description Constructor
    * @param sObjectTypeOption - What SObject Type option do you want to schedule the batch job for?
    * Valid options are value 0 for LEAD, value 1 for ACCOUNT
    */
    public CDdUpdateTaskCountBatchSched(Integer sObjectTypeOption) {
        if (sObjectTypeOption==null || !SOBJECT_TYPE_OPTIONS.containsKey(sObjectTypeOption)){
            throw new CDdUpdateTaskCountBatchSchedException(ERROR_MSG_INVALID_SOBJECT_TYPE_OPTION);
        }
        this.sObjectTypeOption = sObjectTypeOption;
    }    
    /** 
    * @description Execute method for the schedulable class
    * Update task count batch is queued for SObject records (Lead or Account)
    */  
    public void execute(SchedulableContext sc) {
        Database.executebatch(new CDdUpdateTaskCountBatch(SOBJECT_TYPE_OPTIONS.get(this.sObjectTypeOption)), 200);
    }
   /**
    * @description Custom Exception 
    **/     
    public class CDdUpdateTaskCountBatchSchedException extends Exception {}     
}