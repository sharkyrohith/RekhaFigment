/************************************************************************************************************************************
* @author Ila Maheshwari
* @date 9/06/2022
*
* @group Delete SSMO Test Records
*
* @description The purpose of this Apex batch scheduler is to delete SSMO test records after 7 days of record creation 
* 
**************************************************************************************************************************************/
public class CDdDeleteSSMOTestRecordsSchd implements Schedulable{
    public Set<String> objectNames;
    public Date startDate, endDate;
    public Integer maxNumberOfRecords;
    	
    /** 
    * @description A single argument constructor
    * @param objectNames - Set of object names whose records needs to be deleted
    * Valid options are Account and Opporunity
    */
    public CDdDeleteSSMOTestRecordsSchd(Set<String> objectNames, Date startDate, Date endDate, Integer maxNumberOfRecords) {
        this.objectNames = objectNames;
        this.startDate = startDate;
        this.endDate = endDate;
        this.maxNumberOfRecords = maxNumberOfRecords;
    }
    
    /** 
    * @description Execute method for the schedulable class
    * DeleteSSMO Test record batch is queued for Account
    */
    public void execute(SchedulableContext sc){
        CDdDeleteSSMOTestRecordsBatch deleteRecords = new CDdDeleteSSMOTestRecordsBatch(objectNames, startDate, endDate, maxNumberOfRecords); 
        database.executebatch(deleteRecords);
    }
}