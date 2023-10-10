/* 
 * @author: Tia Xuan
 * @date : 2020-08
 * @description: BZAPSUP-756 --- Bypass flag for Case Trigger to bypass execution for long running batches
 *               Helper method to read the Trigger Bypass Settings custom setting, can be used by other objects
 */
public with sharing class CDdTriggerBypassSettings {
    public static Set<String> getExecutedMethods(String objName){
        Set<String> retVal = new Set<String>();
        Trigger_Bypass_Settings__c tbs = Trigger_Bypass_Settings__c.getInstance(UserInfo.getUserId());
        String runMethods = (String) tbs.get(objName + '_Run_Methods__c');
        if (String.isNotBlank(runMethods)){
            retVal = new Set<String>(runMethods.split(';'));
        }
        return retVal;
    }

}