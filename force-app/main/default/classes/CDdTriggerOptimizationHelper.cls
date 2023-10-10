/**
 * @description       : BZAP-15408 - Case Trigger Optimization -
 *
 *              This class allows for:
 *              1. Data structure to do single DML for each object from the case trigger...
 *                 The Data structure stores the data of opportunity/account etc which need to be updated across various case trigger methods and does the DML at the end of after insert/after update
 * @author            : Jose Vega
 * @last modified on  : 06-30-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdTriggerOptimizationHelper {

     /********************** DML OPTIMIZATION **********************
     * This framework stores all the updates to related entities like opportunities and account in memory and does one final DML in after insert/after update
     */

    // Static map<SobjectName,map<id,Sobject to update>> which will allow for single DMLs instead of each method doing its own dml on related entities
    private static Map<String,Map<Id,Sobject>> sObjectToUpdateMap = new Map<String,Map<Id,Sobject>>();
    /**
     * @description Sets the update needed in the sObjectToUpdateMap Map
     * @param   String sObjectName - Object Name to update
     *          Id objId - Record Id to Update
     *          String fieldName - Field API Name to set
     *          Object fieldVal - value to set on the field.
     * @return  None
     *
     * @example CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Opportunity',opp.Id,'Trial_Adjusted_Date__c', c.Trial_Adjustment_Date__c);
     */
    public static void setSobjectToUpdate(String sObjectName,Id objId,String fieldName,Object fieldVal) {
        if (String.isBlank(sObjectName) || objId == null) {
            return;
        }
        if (!sObjectToUpdateMap.containsKey(sObjectName)) {
            sObjectToUpdateMap.put(sObjectName,new Map<Id,SObject>());
        }
        Map<Id,Sobject> sObjectMap = sObjectToUpdateMap.get(sObjectName);
        if (!sObjectMap.containsKey(objId)) {
            Sobject obj = objId.getSobjectType().newSobject(objId);
            sObjectMap.put(objId,obj);
        }
        sObjectMap.get(objId).put(fieldName,fieldVal);
    }
    /**
     * @description Sets the update needed in the sObjectToUpdateMap Map - use if you have multiple fields to update
     * @param   String sObjectName - Object Name to update
     *          Id objId - Record Id to Update
     *          Map<String,Object> fieldValues - Map<Field API Name,Value>
     * @return  None
     *
     * @example Map<String,Object> fieldVal = new Map<String,Object>{
                    'BypassValidationForProcessBuilder__c' => true,
                    'OwnerId' => c.Post_Sale_Owner__c
                };
                CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Account',c.AccountId,fieldVal);
     */
    public static void setSobjectToUpdate(String sObjectName,Id objId,Map<String,Object> fieldValues) {
        if (String.isBlank(sObjectName) || objId == null) {
            return;
        }
        if (!sObjectToUpdateMap.containsKey(sObjectName)) {
            sObjectToUpdateMap.put(sObjectName,new Map<Id,SObject>());
        }
        Map<Id,Sobject> sObjectMap = sObjectToUpdateMap.get(sObjectName);
        if (!sObjectMap.containsKey(objId)) {
            Sobject obj = objId.getSobjectType().newSobject(objId);
            sObjectMap.put(objId,obj);
        }
        Sobject obj = sObjectMap.get(objId);
        for (String fieldName : fieldValues.keySet()) {
            obj.put(fieldName,fieldValues.get(fieldName));
        }
    }

    /*****************************************************************************************************************************/
    /********** Use this only if you can wait till the end of the transaction (after insert/after update) to do the DML **********/
    /*        If you need the id from the inserted record immediately after insert, do not use this optimization technique       */
    /*****************************************************************************************************************************/
    // Static map<SobjectName,List<Sobject to insert>> which will allow for single DMLs instead of each method doing its own dml on related entities
    private static Map<String,List<Sobject>> sObjectToInsertMap = new Map<String,List<Sobject>>();
    /**
     * @description Sets the list needed in the sObjectToInsertMap Map
     * @param   String sObjectName - Object Name to update
     *          List<SObject> - Sobjects to Insert
     * @return  None
     *
     */
    public static void setSObjectToInsert(String sObjectName,List<SObject> sObjectList) {
        if (String.isBlank(sObjectName) || sObjectList.isEmpty()) {
            return;
        }
        if (!sObjectToInsertMap.containsKey(sObjectName)) {
            sObjectToInsertMap.put(sObjectName,new List<SObject>());
        }
        sObjectToInsertMap.get(sObjectName).addAll(sObjectList);
    }

    /**
     * @description Execute the Insert and Update DMLs at the end of the transaction.
     * @param   None
     * @return  None
     **/
    public static void executeSObjectDML() {
        if (sObjectToInsertMap.isEmpty() && sObjectToUpdateMap.isEmpty()) {
            return;
        }
        Savepoint sp = Database.setSavepoint();
        try {
            if (!sObjectToInsertMap.isEmpty()) {
                Set<String> objectNames = sObjectToInsertMap.keySet().clone();
                // Dont worry about DML in a for loop, code is collecting insert requests from the trigger and executing it here
                // instead of multiple DML calls within the trigger itself to the same object.
                // Overall number of DML Calls will be <= traditional trigger coding where dml happens within the trigger methods.
                for (String objectName : objectNames) {
                    List<SObject> toInsert = sObjectToInsertMap.get(objectName);
                    sObjectToInsertMap.remove(objectName);
                    if (toInsert != null && !toInsert.isEmpty()) {
                        insert toInsert;
                    }
                }
            }
            if (!sObjectToUpdateMap.isEmpty()) {
                Set<String> objectNames = sObjectToUpdateMap.keySet().clone();
                // Dont worry about DML in a for loop, code is collecting update requests from the trigger and executing it here
                // instead of multiple DML calls within the trigger itself to the same object
                // Overall number of DML Calls will be <= traditional trigger coding where dml happens within the trigger methods.
                for (String objectName : objectNames) {
                    Map<Id,Sobject> toUpdate = sObjectToUpdateMap.get(objectName);
                    sObjectToUpdateMap.remove(objectName);
                    if (toUpdate != null && !toUpdate.isEmpty()) {
                        update toUpdate.values();
                    }
                }
            }
        } catch(Exception e) {
            Database.rollback( sp );
            throw e;
        }
    }
}