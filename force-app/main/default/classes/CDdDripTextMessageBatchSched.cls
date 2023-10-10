/************************************************************************************************************************************
* @author Tia Xuan (Perficient, Inc.)
* @date 06/2019
*
*
* @description Drip Text messages scheduler
* 
**************************************************************************************************************************************/

public class CDdDripTextMessageBatchSched implements Schedulable {
	
    /** 
    * @description Execute method for the schedulable class
    */	
    public void execute(SchedulableContext sc) {
    	 database.executebatch(new CDdDripTextMessageBatch(), 50);      
    }
    
}