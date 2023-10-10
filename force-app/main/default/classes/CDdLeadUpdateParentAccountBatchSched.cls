/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 09/12/2019
*
* @group Apex Schedulable
*
* @description A batch job schedulable class that executes the batch for leads that do not have a Parent Account associated 
*   A valid Business Id is required to be present on the Lead record and the Lead record must be of record type 'Master Lead' 
*   The batch job will firstly look for an existing Parent Account (using Business Id as the foreign key) to associate with 
*   the Lead record. If not found, a new Parent Account is created ((using Business Id as the foreign key) and 
*   associated with the Lead record 
*
**************************************************************************************************************************************/
public class CDdLeadUpdateParentAccountBatchSched implements Schedulable {
    private Integer recordSize;        
    public static final Integer DEFAULT_RECORD_SIZE = 50;                                                
    /** 
    * @description A single argument constructor
    * @param recordSize - What is the value of the processing batch size?    
    */
    public CDdLeadUpdateParentAccountBatchSched(Integer recordSize) {
        this.recordSize = ((recordSize!=null && recordSize > 0 && recordSize < 200) ? recordSize : DEFAULT_RECORD_SIZE);
    }        
    /** 
    * @description Execute method for the schedulable class
    */  
    public void execute(SchedulableContext sc) {
        Database.executebatch(new CDdLeadUpdateParentAccountBatch(), this.recordSize);
    }
}