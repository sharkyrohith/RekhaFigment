/**
 * @description       :
 * @author            : Ebenezer Suppogu
 * @group             :
 * @last modified on  : 12-07-2022
**/
public with sharing class CDdTriggerConstantsUtil {
    public static Set<String> skipTriggerExecutionSet = new Set<String>();//Should be used to Skip Trigger Execution for a transaction
    public static String skipCaseTrigger = 'caseTrigger';
    public static Boolean skipCaseTriggerExecution = false;
}