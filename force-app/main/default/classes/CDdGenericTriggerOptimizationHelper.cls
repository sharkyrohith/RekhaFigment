/**
 * @author      Raju Lakshman
 * @date        Nov 2021
 * @decription  BIZS-666 - Trigger Optimization logic
 *
 *              This class has generic trigger optimization code like
 *              - Saving queues queried in a static context to allow for trigger transactions to cache queue query results
 *              - Saving non-mutating/mostly reference objects like BusinessHours in a cache
 *              - Saving record type maps in memory for fast access within a transaction (CDdSchemaUtils is not optimized for performance, so plz dont use that)
 *
 *
 *              In the future, if you have any generic, i.e. non mutating reference data which needs to be accessed in multiple trigger context of multiple objects
 *              (Example: Live Chat Transcipt queries queues and then does a case update DML -- so queue cache is common to both trigger context) or
 *              is needed in both the before/after trigger context of the same object - you can add it here!
 */

public with sharing class CDdGenericTriggerOptimizationHelper {
    private static List<String> queueMappingFields = null;
    public static List<String> getQueueMappingFields() {
        if (queueMappingFields != null) {
           return queueMappingFields;
        }
        Set<String> qmFields = new Set<String> {
            'id',
            'queue_developer_name__c',
            'queue_id__c',
            'queue_name__c',
            'customer_type__c',
            'queue_type__c',
            'queue_usage__c',
            'status__c',
            'language__c',
            'is_support_queue__c',
            'is_vip__c',
            'is_vendor_split__c'
        };
        List<String> qmFieldsFromShield = CDdCaseTransferValidationHelper.getRelatedObjectFieldsMap().get('Queue_Mapping__c');
        if (qmFieldsFromShield != null) {
            qmFields.addAll(qmFieldsFromShield);
        }
        queueMappingFields = new List<String>(qmFields);
        return queueMappingFields;
    }

    private static Map<String,String> fieldsCache = new Map<String,String>();
    public static String getFields(String objectName) {
        if (fieldsCache.containsKey(objectName)) {
            return fieldsCache.get(objectName);
        }
        List<String> fieldNames;
        switch on objectName {
            when 'Queue_Mapping__c' {
                fieldNames = getQueueMappingFields();
            }
        }
        if (fieldNames == null) {
            return CDdCoreConstants.BLANK_STRING;
        }
        String retVal = String.join(fieldNames,',');
        fieldsCache.put(objectName,retVal);
        return retVal;
    }

    /********************** QUEUE QUERY OPTIMIZATION **********************/
    // Static map which will allow any method in the case trigger get a queue Id by Name
    private static Map<String,Id> queueNameToIdMap = new Map<String,Id>();
    // Static map which will allow any method in the case trigger get a queue Id by DeveloperName
    private static Map<String,Id> queueDevNameToIdMap = new Map<String,Id>();
    // Static map which will allow any method in the case trigger get a queue information by Id
    private static Map<Id,Group> queueMap = new Map<Id,Group>();
    /**
     * @description  Setter for the Queue maps (both Name and DevName + id map) in memory
     * @param   List<String> queueNames - this list can have both developer names and names together
     * @param   Set<Id> ids - this set contains ids to query
     * @return  None
     */
    public static void setQueueMap(List<String> queueNames,Set<Id> ids) {
        List<String> queueNamesToQuery = new List<String>();
        for (String queueName : queueNames) {
            if (!queueNameToIdMap.containsKey(queueName) && !queueDevNameToIdMap.containsKey(queueName)) {
                queueNamesToQuery.add(queueName);
            }
        }

        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(queueMap.keySet());
        if (queueNamesToQuery.isEmpty() && idsToQuery.isEmpty()) {
            return;
        }
        for (Group q: [SELECT Id, DeveloperName, Name FROM Group WHERE Type = 'QUEUE' AND (DeveloperName IN :queueNamesToQuery OR Name IN :queueNamesToQuery OR Id IN :idsToQuery)]){
            queueNameToIdMap.put(q.Name, q.Id);
            queueDevNameToIdMap.put(q.DeveloperName, q.Id);
            queueMap.put(q.Id,q);
        }
    }
    /**
     * @description  Setter for the Queue maps (both Name and DevName + id map) in memory
     * @param   List<String> queueNames - this list can have both developer names and names together
     * @return  None
     */
    public static void setQueueMap(List<String> queueNames) {
        List<String> queueNamesToQuery = new List<String>();
        for (String queueName : queueNames) {
            if (!queueNameToIdMap.containsKey(queueName) && !queueDevNameToIdMap.containsKey(queueName)) {
                queueNamesToQuery.add(queueName);
            }
        }
        if (queueNamesToQuery.isEmpty()) {
            return;
        }
        for (Group q: [SELECT Id, DeveloperName, Name FROM Group WHERE Type = 'QUEUE' AND (DeveloperName IN :queueNamesToQuery OR Name IN :queueNamesToQuery)]){
            queueNameToIdMap.put(q.Name, q.Id);
            queueDevNameToIdMap.put(q.DeveloperName, q.Id);
            queueMap.put(q.Id,q);
        }
    }
    /**
     * @description  Setter for the Queue maps (both Name and DevName + id map) in memory
     * @param   Set<Id> queueNames - this list can have both developer names and names together
     * @return  None
     */
    public static void setQueueMap(Set<Id> ids) {
        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(queueMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }
        for (Group q: [SELECT Id, DeveloperName, Name FROM Group WHERE Id IN :idsToQuery]){
            queueNameToIdMap.put(q.Name, q.Id);
            queueDevNameToIdMap.put(q.DeveloperName, q.Id);
            queueMap.put(q.Id,q);
        }
    }
    /**
     * @description  Getter for the Queue Map by Name
     * @param   None
     * @return  Map<String,Id>
     */
    public static Map<String,Id> getQueueNameToIdMap() {
        return queueNameToIdMap;
    }
    /**
     * @description Gets Queue Id by Name
     * @param   String name - Queue Name <Not Developer Name>
     * @return  Id
     */
    public static Id getQueueIdByName(String name) {
        return queueNameToIdMap.get(name);
    }
    /**
     * @description  Getter for the Queue Map by Developer Name
     * @param   None
     * @return  Map<String,Id>
     */
    public static Map<String,Id> getQueueDevNameToIdMap() {
        return queueDevNameToIdMap;
    }
    /**
     * @description Gets Queue Id by Dev Name
     * @param   String name - Queue Dev Name <Not Name / Label>
     * @return  Id
     */
    public static Id getQueueIdByDevName(String name) {
        return queueDevNameToIdMap.get(name);
    }
    /**
     * @description  Getter for the Queue Map
     * @param   None
     * @return  Map<Id,Group>
     */
    public static Map<Id,Group> getQueueMap() {
        return queueMap;
    }
    /**
     * @description Gets Queue by Id
     * @param   Id qId - Id of queue
     * @return  Group
     */
    public static Group getQueue(Id qId) {
        return queueMap.get(qId);
    }

    /********************** QUEUE MAPPING OPTIMIZATION **********************/
    // Static map which will allow any method in the trigger get a Queue Mapping by Name
    private static Map<String,Queue_Mapping__c> queueNameToQueueMappingMap = new Map<String,Queue_Mapping__c>();
    // Static map which will allow any method in the trigger get a Queue Mapping by DeveloperName
    private static Map<String,Queue_Mapping__c> queueDevNameToQueueMappingMap = new Map<String,Queue_Mapping__c>();
    // Static map which will allow any method in the trigger get a Queue Mapping by Id
    private static Map<Id,Queue_Mapping__c> queueMapppingMap = new Map<Id,Queue_Mapping__c>();

    /**
     * @description  Get the base query of all the fields needed from an Queue Mapping; if using outside the this class, use in conjuction with addToOpportunityMap
     * @param   None
     * @return  String
     */
    private static String queueMappingBaseQuery = null;
    public static String getQueueMappingBaseQuery() {
        if (queueMappingBaseQuery == null) {
            queueMappingBaseQuery = 'SELECT ' + getFields('Queue_Mapping__c') + ' FROM Queue_Mapping__c ';
        }
        return queueMappingBaseQuery;
    }

    /**
     * @description  Setter for the Queue Mapping maps (both Name and DevName + id map) in memory
     * @param   List<String> queueNames - this list can have both developer names and names together
     * @param   Set<Id> ids - this set contains ids to query
     * @return  None
     */
    public static void setQueueMappingMap(List<String> queueNames,Set<Id> ids) {
        List<String> queueNamesToQuery = new List<String>();
        for (String queueName : queueNames) {
            if (!queueNameToQueueMappingMap.containsKey(queueName) && !queueDevNameToQueueMappingMap.containsKey(queueName)) {
                queueNamesToQuery.add(queueName);
            }
        }

        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(queueMapppingMap.keySet());
        if (queueNamesToQuery.isEmpty() && idsToQuery.isEmpty()) {
            return;
        }

        for (Queue_Mapping__c qm : Database.query(getQueueMappingBaseQuery() +
                ' WHERE Queue_Developer_Name__c IN :queueNamesToQuery OR Queue_Name__c IN :queueNamesToQuery OR Queue_Id__c IN :idsToQuery')) {
            queueNameToQueueMappingMap.put(qm.Queue_Name__c, qm);
            queueDevNameToQueueMappingMap.put(qm.Queue_Developer_Name__c, qm);
            queueMapppingMap.put(qm.Queue_Id__c,qm);
        }
    }
    /**
     * @description  Setter for the Queue Mapping maps (both Name and DevName + id map) in memory
     * @param   List<String> queueNames - this list can have both developer names and names together
     * @return  None
     */
    public static void setQueueMappingMap(List<String> queueNames) {
        List<String> queueNamesToQuery = new List<String>();
        for (String queueName : queueNames) {
            if (!queueNameToQueueMappingMap.containsKey(queueName) && !queueDevNameToQueueMappingMap.containsKey(queueName)) {
                queueNamesToQuery.add(queueName);
            }
        }
        if (queueNamesToQuery.isEmpty()) {
            return;
        }

        for (Queue_Mapping__c qm : Database.query(getQueueMappingBaseQuery() +
                ' WHERE Queue_Developer_Name__c IN :queueNamesToQuery OR Queue_Name__c IN :queueNamesToQuery')) {
            queueNameToQueueMappingMap.put(qm.Queue_Name__c, qm);
            queueDevNameToQueueMappingMap.put(qm.Queue_Developer_Name__c, qm);
            queueMapppingMap.put(qm.Queue_Id__c,qm);
        }
    }
    /**
     * @description  Setter for the Queue Mapping maps (both Name and DevName + id map) in memory
     * @param   Set<Id> queueNames - this list can have both developer names and names together
     * @return  None
     */
    public static void setQueueMappingMap(Set<Id> ids) {
        Set<Id> idsToQuery = ids.clone();
        idsToQuery.removeAll(queueMapppingMap.keySet());
        if (idsToQuery.isEmpty()) {
            return;
        }

        for (Queue_Mapping__c qm : Database.query(getQueueMappingBaseQuery() +  ' WHERE Queue_Id__c IN :idsToQuery')) {
            queueNameToQueueMappingMap.put(qm.Queue_Name__c, qm);
            queueDevNameToQueueMappingMap.put(qm.Queue_Developer_Name__c, qm);
            queueMapppingMap.put(qm.Queue_Id__c,qm);
        }
    }

    /**
     * @description  Setter for the Queue Mapping maps (both Name and DevName + id map) in memory
     * @param   List<Group> queues - Queues to get queue mapping for
     * @return  None
     */
    public static void setQueueMappingMap(List<Group> queues) {
        Set<Id> idsToQuery = new Set<Id>();
        for (Group q : queues) {
            if (!queueMapppingMap.containsKey(q.Id)) {
                idsToQuery.add(q.Id);
            }
        }
        if (idsToQuery.isEmpty()) {
            return;
        }

        for (Queue_Mapping__c qm : Database.query(getQueueMappingBaseQuery() +  ' WHERE Queue_Id__c IN :idsToQuery')) {
            queueNameToQueueMappingMap.put(qm.Queue_Name__c, qm);
            queueDevNameToQueueMappingMap.put(qm.Queue_Developer_Name__c, qm);
            queueMapppingMap.put(qm.Queue_Id__c,qm);
        }
    }

    /**
     * @description  Getter for the Queue Map by Name
     * @param   None
     * @return  Map<String,Queue_Mapping__c>
     */
    public static Map<String,Queue_Mapping__c> getQueueNameToQueueMappingMap() {
        return queueNameToQueueMappingMap;
    }
    /**
     * @description Gets Queue Mapping by Name
     * @param   String name - Queue Name <Not Developer Name>
     * @return  Queue_Mapping__c
     */
    public static Queue_Mapping__c getQueueMappingByName(String name) {
        return queueNameToQueueMappingMap.get(name);
    }
    /**
     * @description  Getter for the Queue Map by Developer Name
     * @param   None
     * @return  Map<String,Queue_Mapping__c>
     */
    public static Map<String,Queue_Mapping__c> getQueueDevNameToQueueMappingMap() {
        return queueDevNameToQueueMappingMap;
    }
    /**
     * @description Gets Queue Map by Dev Name
     * @param   String name - Queue Dev Name <Not Name / Label>
     * @return  Queue_Mapping__c
     */
    public static Queue_Mapping__c getQueueMappingByDevName(String name) {
        return queueDevNameToQueueMappingMap.get(name);
    }
    /**
     * @description  Getter for the Queue Map
     * @param   None
     * @return  Map<Id,Queue_Mapping__c>
     */
    public static Map<Id,Queue_Mapping__c> getQueueMappingMap() {
        return queueMapppingMap;
    }
    /**
     * @description Gets Queue by Id
     * @param   Id qId - Id of queue
     * @return  Queue_Mapping__c
     */
    public static Queue_Mapping__c getQueueMapping(Id qId) {
        return queueMapppingMap.get(qId);
    }

    /********************** Business Hours **********************/
    private static List<BusinessHours> businessHours = null;
    private static BusinessHours defaultBusinessHour = null;
    public static List<BusinessHours> getBusinessHours() {
        if (businessHours == null) {
            businessHours = [SELECT Id, Name, IsDefault from BusinessHours WHERE IsDefault = true];
            defaultBusinessHour = businessHours.isEmpty() ? null : businessHours[0];
        }
        return businessHours;
    }
    public static BusinessHours getDefaultBusinessHour() {
        if (defaultBusinessHour == null) {
            if (businessHours == null) {
                getBusinessHours();
            } else {
                defaultBusinessHour = businessHours.isEmpty() ? null : businessHours[0];
            }
        }
        return defaultBusinessHour;
    }

    /********************** RECORD TYPE OPTIMIZATION **********************
     * Note that CDdSchemaUtils is not performance optimized.
     * Having Schema.SObjectType.<Object>.getRecordTypeInfosByName() and Schema.SObjectType.<Object>.getRecordTypeInfosByDeveloperName()
     * in memory as static variables dramatically improves performance.
     *
     * CDdSupportConstants have some public static final strings for the record type labels/api names. Please use them as much as possible/add to them if they dont exist.
     */
    public static final Map<String, RecordTypeInfo> CASE_RT_INFO = Schema.SObjectType.Case.getRecordTypeInfosByName();
    public static Id getCaseRecordTypeId(String name) {
        return CASE_RT_INFO.get(name).getRecordTypeId();
    }
    public static final Map<Id, RecordTypeInfo> CASE_RTID_INFO = Schema.SObjectType.Case.getRecordTypeInfosById();
    public static String getCaseRecordTypeDevNameById(Id recId) {
        return CASE_RTID_INFO.get(recId).getDeveloperName();
    }
    public static final Map<String, RecordTypeInfo> OPPORTUNITY_RT_INFO = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    public static Id getOpportunityRecordTypeId(String name) {
        return OPPORTUNITY_RT_INFO.get(name).getRecordTypeId();
    }
    public static final Map<String, RecordTypeInfo> ACCOUNT_RT_INFO = Schema.SObjectType.Account.getRecordTypeInfosByName();
    public static Id getAccountRecordTypeId(String name) {
        return ACCOUNT_RT_INFO.get(name).getRecordTypeId();
    }
    public static final Map<String, RecordTypeInfo> MILESTONES_RT_INFO = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName();
    public static Id getMilestoneRecordTypeId(String name) {
        return MILESTONES_RT_INFO.get(name).getRecordTypeId();
    }

    public static final Map<String, RecordTypeInfo> CASE_DEVNAME_RT_INFO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
    public static Id getCaseRecordTypeIdByDevName(String name) {
        return CASE_DEVNAME_RT_INFO.get(name).getRecordTypeId();
    }
    public static final Map<String, RecordTypeInfo> OPPORTUNITY_DEVNAME_RT_INFO = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
    public static Id getOpportunityRecordTypeIdByDevName(String name) {
        return OPPORTUNITY_DEVNAME_RT_INFO.get(name).getRecordTypeId();
    }
    public static final Map<String, RecordTypeInfo> ACCOUNT_DEVNAME_RT_INFO = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    public static Id getAccountRecordTypeIdByDevName(String name) {
        return ACCOUNT_DEVNAME_RT_INFO.get(name).getRecordTypeId();
    }
    public static final Map<String, RecordTypeInfo> MILESTONES_DEVNAME_RT_INFO = Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName();
    public static Id getMilestoneRecordTypeIdByDevName(String name) {
        return MILESTONES_DEVNAME_RT_INFO.get(name).getRecordTypeId();
    }

    public static Id supportRecordTypeId = getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
    public static Id caviarSupportRecordTypeId = getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIRA_SUPPORT);
    public static Id caviarOnboardingRecordTypeId = getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING);
    public static Id tabletRequestRecordTypeId = getCaseRecordTypeId('Tablet Requests');
}