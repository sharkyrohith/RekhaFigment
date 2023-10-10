/********************************************************************************************************************
* @author Veera
* @date 04/28/2022
*
* @group Merchant Services
*
* @description Helper test class fro CDdMxSupportEventBatchTest to implement CDdMxSupportEventInterface
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSupportEventInterfaceTest implements CDdMxSupportEventInterface{
    public  Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator('Select Id,AccountId from Case LIMIT 1');
    }

    public void publishEvents(String sObjectType, Set<Id> sObjectIds){
       
    }
    
    public void handleEvents(String sObjectType, Set<Id> sObjectIds){
        String querywithIdsFilter = String.format(getDbQueryFilteredBySObjectIds(), new List<String>{'sObjectIds'});
        Set<Id> parentAccountIds = new Set<Id>();
        List<Case> caseList = Database.query(querywithIdsFilter);
    }

    private String getDbQueryFilteredBySObjectIds(){
        return 'Select Id,AccountId from Case WHERE Id IN :{0}';
    }
}