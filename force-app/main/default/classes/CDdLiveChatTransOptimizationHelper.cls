/**
 * @author      Sahil Chaudhry
 * @date        Dec 2021
 * @decription  BIZS-814 - LiveChatTranscript Trigger Optimization - optimized by loading transaction data in memory
 *
 */
public without sharing class CDdLiveChatTransOptimizationHelper {
    /*****************************************************************************************************************************
    *
    * Constants & Private Variables
    *
    *****************************************************************************************************************************/
    private static Map<Id,Case> caseMap = new Map<Id,Case>();
    private static String caseBaseQuery = null;
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
    private static Map<String,List<String>> relatedObjectFieldsMap = null;
    public static Map<String,List<String>> getRelatedObjectFieldsMap() {
        if (relatedObjectFieldsMap != null) {
            return relatedObjectFieldsMap;
        }
        relatedObjectFieldsMap = CDdIssueBasedRoutingHelper.getRelatedObjectFieldsMap('LiveChatTranscript');
        return relatedObjectFieldsMap;
    }

    private static List<String> caseFields = null;
    public static List<String> getCaseFields() {
        if (caseFields != null) {
           return caseFields;
        }
        Set<String> fields = new Set<String> {
            'id',
            'chatwaittime__c',
            'chatduration__c',
            'chatkey__c',
            'chat_type__c',
            'initial_queue__c',
            'initial_queue_name__c',
            'suppliedname',
            'full_name__c'
        };
        List<String> caseFieldsFromMissionControl = getRelatedObjectFieldsMap().get('Case');
        if (caseFieldsFromMissionControl != null) {
            fields.addAll(caseFieldsFromMissionControl);
        }
        caseFields = new List<String>(fields);
        return caseFields;
    }

    private static Map<String,String> fieldsCache = new Map<String,String>();
    public static String getFields(String objectName, String prefix) {
        String cacheKey = objectName + (String.isBlank(prefix) ? CDdCoreConstants.BLANK_STRING : CDdCoreConstants.DELIMITER_HYPHEN + prefix);
        if (fieldsCache.containsKey(cacheKey)) {
            return fieldsCache.get(cacheKey);
        }
        List<String> fieldNames;
        switch on objectName {
            when 'Case' {
                fieldNames = getCaseFields();
            }
        }
        if (fieldNames == null) {
            return CDdCoreConstants.BLANK_STRING;
        }
        String retVal = CDdCoreConstants.BLANK_STRING;
        if (String.isBlank(prefix)) {
            prefix = CDdCoreConstants.BLANK_STRING;
        } else {
            prefix = prefix.endsWith(CDdCoreConstants.DELIMITER_DOT) ? prefix : prefix + CDdCoreConstants.DELIMITER_DOT;
        }
        for (String field : fieldNames) {
            retVal += prefix + field + CDdCoreConstants.DELIMITER_COMMA;
        }
        retVal = retVal.removeEnd(CDdCoreConstants.DELIMITER_COMMA);
        fieldsCache.put(cacheKey,retVal);
        return retVal;
    }

    /********************** CASE QUERY OPTIMIZATION **********************/
     /**
     * @description  Getter for the case map in memory
     * @param   None
     * @return  Map<Id, Case>
     */
    public static Map<Id, Case> getCaseMap() {
        return caseMap;
    }
    /**
     * @description  Get the case base query of all the fields needed from an Case; if using outside the this class, use in conjuction with addToCaseMap
     * @param   None
     * @return  String
     */

    public static String getCaseBaseQuery() {
        if (caseBaseQuery == null) {
            caseBaseQuery = 'SELECT ' + getFields('Case', null) +' FROM Case ';
        }
        return caseBaseQuery;
    }
    /**
     * @description  Setter for the opportunity map in memory
     * @param   Set<Id> ids - Id of case to query
     * @return  None
     */
    public static void setCaseMap(Set<Id> ids) {
        if (ids.isEmpty()) {
            return;
        }
        List<Case> cases = Database.query(getCaseBaseQuery() + ' WHERE Id IN :ids');
        caseMap.putAll(new Map<Id, Case>(cases));
    }
    /**
     * @description  Add Case queried outside this class (mostly within the trigger helper) to add to the static map for easy future access within the transaction
     *               Ensure you use the getCaseBaseQuery() to add the fields needed across the transaction
     * @param   List<Case> opptys - Case to add to the static map
     * @return  None
     */
    public static void addToCaseMap(List<Case> cases) {
        if (!cases.isEmpty()) {
            caseMap.putAll(new Map<Id, Case>(cases));
        }
    }
    /**
     * @description  Refreshes the static variable caseMap
     * @param   None
     * @return  None
     */
    public static void refreshCaseMap() {
        Set<Id> caseIds = caseMap.keySet();
        if (caseIds.isEmpty()) {
            return;
        }
        caseMap = new Map<Id, Case>((List<Case>)Database.query(getCaseBaseQuery() + ' WHERE Id IN :caseIds'));
    }

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
                    // Refreshing cache
                    switch on objectName {
                        when 'Case' {
                            refreshCaseMap();
                        }
                    }
                }
            }
        } catch(Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }
}