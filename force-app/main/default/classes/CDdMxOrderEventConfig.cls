/********************************************************************************************************************
* @author Sriram
* @date 03/09/2022
*
* @group Merchant Services
*
* @description This class will read the configured data as found in Merchant Order Event Configuration (custom metadata - Mx_Order_Event_Config__mdt) 
*               and provide the corresponding configuration setup values to the caller of this class
*
*               In order to optimize serving the configuration information to the caller, a one-time read is performed on the
*               custom metadata - Mx_Order_Event_Config__mdt record, and the values are populated to static variables in this helper class.
*               Note: These values expect to go unchanged within the caller's execution/transaction, once read from this helper class
* 
**************************************************************************************************************************************/
public class CDdMxOrderEventConfig {

    public static Map<CDdMxOrderEventEnum, Mx_Order_Event_Config__mdt> MX_ORDER_EVENT_CONFIG;
    public static Map<String, Map<String, CDdMxOrderEventEnum>> MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE;
    public static Map<CDdMxOrderEventEnum, Set<Id>> SOURCE_SOBJECT_RECORD_TYPE_IDS_FOR_MX_ORDER_EVENT;
    public static Map<String, String> STATUS_API_FIELD_FOR_SOBJECT_TYPE;
    public static Map<CDdMxOrderEventEnum, CDdMxOrderMappingHandlerInterface> MX_ORDER_EVENT_APEX_MAPPING_HANDLER;
    public static Map<String, Set<CDdMxOrderEventEnum>> MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE;
    public static Map<Id, Mx_Order_Request__c> MX_ORDER_REQUEST_MAP;

    static {
        MX_ORDER_EVENT_CONFIG = new Map<CDdMxOrderEventEnum, Mx_Order_Event_Config__mdt>();
        MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE = new Map<String, Map<String, CDdMxOrderEventEnum>>();
        SOURCE_SOBJECT_RECORD_TYPE_IDS_FOR_MX_ORDER_EVENT = new Map<CDdMxOrderEventEnum, Set<Id>>();
        STATUS_API_FIELD_FOR_SOBJECT_TYPE = new Map<String, String>();
        MX_ORDER_EVENT_APEX_MAPPING_HANDLER = new Map<CDdMxOrderEventEnum, CDdMxOrderMappingHandlerInterface>();
        MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE = new Map<String, Set<CDdMxOrderEventEnum>>();
        for (Mx_Order_Event_Config__mdt config : [  SELECT Id, Event_Name__c, 
                                                    Source_SObject_Fields_Changed__c, Source_SObject_Record_Types__c, 
                                                    Source_SObject_Type__c, Source_SObject_Key_API_Field__c,
                                                    Target_SObject_Type__c, Target_SObject_Key_API_Field__c,
                                                    Target_SObject_DML_Operation__c, Apex_Mapping_Handler__c,
                                                    (SELECT Id, Field_Type__c,
                                                    Source_SObject_API_Field__c, Target_SObject_API_Field__c, 
                                                    Target_Default_Value__c,  Target_SObject_API_Field_Length__c
                                                    FROM Mx_Order_Event_Config_Copy_Field__r
                                                    WHERE Is_Active__c = TRUE),
                                                    (SELECT Id, Source_SObject_Status_API_Field__c, Source_SObject_Status_Value__c
                                                    FROM Mx_Order_Event_Source_Obj_Status__r
                                                    WHERE Is_Active__c = TRUE)
                                                    FROM Mx_Order_Event_Config__mdt
                                                    WHERE Is_Active__c = TRUE
                                                ]){
            CDdMxOrderEventEnum event = CDdMxOrderEventEnumHelper.toEnum(config.Event_Name__c);
            if (event!=null){
                MX_ORDER_EVENT_CONFIG.put(event, config);
                // Handle Source sObject Record Types Configuration
                setSourceSObjectRecordTypeIdsForMxOrderEvent(event, config);
                // Handle Source sObject Status Configuration
                setMxOrderEventForStatusBySourceSObjectType(event, config);
                // Set the Apex Mapping Handler
                setApexMappingHandler(event, config);
                // Set the Mx Order Events for Source SObject Type
                setMxOrderEventsForSourceSObjectType(event, config); 
            }                                       
        }
        MX_ORDER_REQUEST_MAP = new Map<Id, Mx_Order_Request__c>([SELECT Id, Request_Type__c, Country_Code__c, Is_Routing_Enabled__c
                                                                FROM Mx_Order_Request__c
                                                                WHERE Is_Active__c = TRUE
                                                                ]);
    }
    private static void setSourceSObjectRecordTypeIdsForMxOrderEvent(CDdMxOrderEventEnum event, Mx_Order_Event_Config__mdt config){
        String sObjectType = config.Source_SObject_Type__c;
        Set<Id> recordTypeIds = new Set<Id>();                
        if (String.isNotBlank(config.Source_SObject_Record_Types__c)){
            List<String> recordTypeDeveloperNames = config.Source_SObject_Record_Types__c.replaceAll('(\r\n|\r|\n)','').split(',');
            for (String recordTypeDeveloperName : recordTypeDeveloperNames){
                recordTypeIds.add(CDdSchemaUtils.getRecordTypeIdByDeveloperName(sObjectType, recordTypeDeveloperName));
            }
        }
        SOURCE_SOBJECT_RECORD_TYPE_IDS_FOR_MX_ORDER_EVENT.put(event, recordTypeIds);        
    }
    private static void setMxOrderEventForStatusBySourceSObjectType(CDdMxOrderEventEnum event, Mx_Order_Event_Config__mdt config){
        for (Mx_Order_Event_Source_Obj_Status__mdt sourceObjStatus : config.Mx_Order_Event_Source_Obj_Status__r){
            STATUS_API_FIELD_FOR_SOBJECT_TYPE.put(config.Source_SObject_Type__c, sourceObjStatus.Source_SObject_Status_API_Field__c);
            if (MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE.containsKey(config.Source_SObject_Type__c)){
                MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE
                        .get(config.Source_SObject_Type__c)
                        .put(sourceObjStatus.Source_SObject_Status_Value__c, event);
            } else {
                MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE.put(
                                        config.Source_SObject_Type__c,
                                        new Map<String, CDdMxOrderEventEnum>{sourceObjStatus.Source_SObject_Status_Value__c => event}
                                    );
            }
        }        
    }
    private static void setApexMappingHandler(CDdMxOrderEventEnum event, Mx_Order_Event_Config__mdt config){
        if (String.isNotBlank(config.Apex_Mapping_Handler__c)){
            MX_ORDER_EVENT_APEX_MAPPING_HANDLER.put(event, (CDdMxOrderMappingHandlerInterface)Type.forName(config.Apex_Mapping_Handler__c).newInstance());
        }
    }
    private static void setMxOrderEventsForSourceSObjectType(CDdMxOrderEventEnum event, Mx_Order_Event_Config__mdt config){
        if (String.isNotBlank(config.Source_SObject_Type__c)){
            if (MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE.containsKey(config.Source_SObject_Type__c)){
                MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE.get(config.Source_SObject_Type__c).add(event);
            } else {
                MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE.put(config.Source_SObject_Type__c, new Set<CDdMxOrderEventEnum>{ event });
            }
        }
    }
    public static Set<Id> getSourceSObjectRecordTypeIds(String sourceSObjectType){
        Set<Id> sourceSObjectRecordTypeIds = new Set<Id>();
        if (String.isNotBlank(sourceSObjectType) && MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE.containsKey(sourceSObjectType)){
            for (CDdMxOrderEventEnum event : MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE.get(sourceSObjectType)){
                sourceSObjectRecordTypeIds.addAll(SOURCE_SOBJECT_RECORD_TYPE_IDS_FOR_MX_ORDER_EVENT.get(event));
            }
        }
        return sourceSObjectRecordTypeIds;
    }
    public static String getSObjectType(CDdMxOrderEventEnum event, String sourceOrTarget){
        if (!MX_ORDER_EVENT_CONFIG.containsKey(event) || String.isBlank(sourceOrTarget)) { return null; }
        String sObjectType = null;
        switch on sourceOrTarget {
            when 'source' {
                sObjectType = MX_ORDER_EVENT_CONFIG.get(event).Source_SObject_Type__c;
            }
            when 'target' {
                sObjectType = MX_ORDER_EVENT_CONFIG.get(event).Target_SObject_Type__c;
            }
        }        
        return sObjectType;
    }
    public static String getSObjectKeyApiField(CDdMxOrderEventEnum event, String sourceOrTarget){
        if (!MX_ORDER_EVENT_CONFIG.containsKey(event) || String.isBlank(sourceOrTarget)) { return null; }
        String sObjectKeyApiField = null;
        switch on sourceOrTarget {
            when 'source' {
                sObjectKeyApiField = MX_ORDER_EVENT_CONFIG.get(event).Source_SObject_Key_API_Field__c;
            }
            when 'target' {
                sObjectKeyApiField = MX_ORDER_EVENT_CONFIG.get(event).Target_SObject_Key_API_Field__c;
            }
        }        
        return sObjectKeyApiField;
    }
    public static String getTargetSObjectDmlOperation(CDdMxOrderEventEnum event){
        if (!MX_ORDER_EVENT_CONFIG.containsKey(event)) { return null; }        
        return MX_ORDER_EVENT_CONFIG.get(event).Target_SObject_DML_Operation__c;
    }         
    public static List<SObject> querySObjects(String sObjectType, String sourceOrTarget, String fieldApiKey, Set<Id> sObjectIds){
        List<String> sObjectApiFields = CDdMxOrderEventConfig.getAllApiFields(sObjectType, sourceOrTarget);
        String sObjectQuery = 'SELECT ' +  String.join(sObjectApiFields, ',') + ' FROM ' + sObjectType + ' WHERE ' + fieldApiKey + ' IN ' + ' :sObjectIds ';
        List<SObject> sObjs = new List<SObject>();
        for (SObject sObj : Database.query(sObjectQuery)){
            sObjs.add(sObj);
        }
        return sObjs;
    }     
    public static List<String> getAllApiFields(String sObjectType, String sourceOrTarget){
        Set<String> apiFields = new Set<String>();
        for (CDdMxOrderEventEnum event : MX_ORDER_EVENT_CONFIG.keySet()){
            Mx_Order_Event_Config__mdt config = MX_ORDER_EVENT_CONFIG.get(event);
            switch on sourceOrTarget {
                when 'source' {
                    if (config.Source_SObject_Type__c.equals(sObjectType)){
                        apiFields.add(config.Source_SObject_Key_API_Field__c);
                        apiFields.addAll(new Set<String>(getSourceChangedFields(event)));
                        for (Mx_Order_Event_Config_Copy_Field__mdt copyFieldConfig : config.Mx_Order_Event_Config_Copy_Field__r){
                            if (String.isNotBlank(copyFieldConfig.Source_SObject_API_Field__c)){
                                apiFields.add(copyFieldConfig.Source_SObject_API_Field__c);
                            }
                        }
                        for (Mx_Order_Event_Source_Obj_Status__mdt sourceObjectStatus : config.Mx_Order_Event_Source_Obj_Status__r){
                            if (String.isNotBlank(sourceObjectStatus.Source_SObject_Status_API_Field__c)){
                                apiFields.add(sourceObjectStatus.Source_SObject_Status_API_Field__c);
                            }
                        }                        
                        if (hasApexMappingHandler(event)){
                            apiFields.addAll(MX_ORDER_EVENT_APEX_MAPPING_HANDLER.get(event).getSourceSObjectApiFields());
                        }
                    }
                }
                when 'target' {
                    if (config.Target_SObject_Type__c.equals(sObjectType)){
                        apiFields.add(config.Target_SObject_Key_API_Field__c);
                        for (Mx_Order_Event_Config_Copy_Field__mdt copyFieldConfig : config.Mx_Order_Event_Config_Copy_Field__r){
                            if (String.isNotBlank(copyFieldConfig.Target_SObject_API_Field__c)){
                                apiFields.add(copyFieldConfig.Target_SObject_API_Field__c);
                            }
                        }
                        if (hasApexMappingHandler(event)){
                            apiFields.addAll(MX_ORDER_EVENT_APEX_MAPPING_HANDLER.get(event).getTargetSObjectApiFields());
                        }                        
                    }
                }
            }
        }
        return new List<String>(apiFields);
    }
    /**
     * @description Check for validity of Mx Order Event 
     * 1. Mx Order Event should not be null
     * 2. Is the Mx Order Event valid for input Source sObject Type?
     * 3. If the Source sObject is partitioned based on Record Type, then
     *      - Record Type of the Source SObject should be specified in the Mx Order Event Custom Metadata configuration
     */
    public static Boolean isValidMxOrderEvent(CDdMxOrderEventEnum event, String sourceSObjectType, SObject sourceSObject){
        return (event != null
                && MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE.containsKey(sourceSObjectType)
                && MX_ORDER_EVENTS_FOR_SOURCE_SOBJECT_TYPE.get(sourceSObjectType).contains(event)
                && CDdMxOrderEventConfig.isEventEligibleForRecordType(event, sourceSObject));
    }     
    /**
     * @description Copy field values from Source sObject to Target sObject
     * @param CDdMxOrderEventEnum event
     * @param SObject sourceSObj
     * @param SObject targetSObj
     * @return Boolean - True if the target sObject record is updated
     */
    public static Boolean copyFields(CDdMxOrderEventEnum event, SObject sourceSObj, SObject targetSObj){
        Boolean isUpdated = false; 
        if (!MX_ORDER_EVENT_CONFIG.containsKey(event)) { return isUpdated; }
        Mx_Order_Event_Config__mdt config = MX_ORDER_EVENT_CONFIG.get(event);
        // Is the copy to target sObject for dml operation INSERT or UPDATE?
        String targetSObjectDmlOperation = config.Target_SObject_DML_Operation__c;
        for (Mx_Order_Event_Config_Copy_Field__mdt copyFieldConfig : config.Mx_Order_Event_Config_Copy_Field__r){
            String fieldType = copyFieldConfig.Field_Type__c;
            String sourceSObjectApiField = copyFieldConfig.Source_SObject_API_Field__c;
            String targetSObjectApiField = copyFieldConfig.Target_SObject_API_Field__c;
            String targetDefaultValue = copyFieldConfig.Target_Default_Value__c;
            Integer targetFieldLength = copyFieldConfig.Target_SObject_API_Field_Length__c != null ? Integer.valueOf(copyFieldConfig.Target_SObject_API_Field_Length__c) : null;
            // Check if target sobject api field exists, to copy the source value to
            if (String.isNotBlank(targetSObjectApiField)){
                // Get the value of the sobject api field from the target sobject (Note : will be considered null for 'INSERT' dml operation on targetsObject)
                // It will used to compare with value found in the corresponding field on the source sobject
                Object targetFieldValue = (('INSERT'.equals(targetSObjectDmlOperation)) ? null : (targetSObj.isSet(targetSObjectApiField) ? targetSObj.get(targetSObjectApiField) : null));
                // Check if source sobject api field exists, to copy the source value from
                if (String.isNotBlank(sourceSObjectApiField)){
                    if (sourceSObj.isSet(sourceSObjectApiField)){
                        Object sourceFieldValue = sourceSObj.get(sourceSObjectApiField);
                        if (    (sourceFieldValue == null && targetFieldValue != null)
                                ||
                                (sourceFieldValue != null && targetFieldValue == null) 
                                || 
                                (sourceFieldValue != null && targetFieldValue != null && sourceFieldValue != targetFieldValue) 
                            ){
                            if (sourceFieldValue != null && targetFieldLength != null){
                                String sourceFieldValueStr = String.valueOf(sourceFieldValue);
                                targetSObj.put(targetSObjectApiField, (sourceFieldValueStr.length() > targetFieldLength ? sourceFieldValueStr.substring(0, targetFieldLength) : sourceFieldValueStr));
                            } else {
                                targetSObj.put(targetSObjectApiField, sourceFieldValue);
                            }
                            isUpdated = true;
                        }
                    }
                } else if (String.isNotBlank(targetDefaultValue)) { // Else use the default target value
                    if (targetFieldValue == null ||  (targetFieldValue != null && targetFieldValue != targetDefaultValue)){
                        targetSObj.put(targetSObjectApiField, targetDefaultValue);
                        isUpdated = true;
                    }
                }
            }
        }
        if (hasApexMappingHandler(event)){
            isUpdated = MX_ORDER_EVENT_APEX_MAPPING_HANDLER.get(event).copyFields(event, sourceSObj, targetSObj, targetSObjectDmlOperation) || isUpdated;
        } 
        return isUpdated;
    }     
    /**
     * @description Does the Merchant Order Event Enum have a corresponding config?
     * @param CDdMxOrderEventEnum mxOrderEventEnum
     * @return Boolean
     */
    public static Boolean hasConfig(CDdMxOrderEventEnum mxOrderEventEnum){
        return (mxOrderEventEnum!=null && MX_ORDER_EVENT_CONFIG.containsKey(mxOrderEventEnum));
    }
    /**
     * @description Return the event configuration for Merchant Order Event Enum 
     * @param CDdMxOrderEventEnum mxOrderEventEnum
     * @return Mx_Order_Event_Config__mdt
     */
    public static Mx_Order_Event_Config__mdt getConfig(CDdMxOrderEventEnum mxOrderEventEnum){
        return (hasConfig(mxOrderEventEnum) ? MX_ORDER_EVENT_CONFIG.get(mxOrderEventEnum) : null);
    }
    /**
     * @description Return a Collection of Changed Fields on the Source SObject associated with the Merchant Order Event Enum 
     * @param CDdMxOrderEventEnum mxOrderEventEnum
     * @return List<String>
     */
    public static List<String> getSourceChangedFields(CDdMxOrderEventEnum mxOrderEventEnum){
        return (    hasConfig(mxOrderEventEnum) 
                    && String.isNotBlank(getConfig(mxOrderEventEnum).Source_SObject_Fields_Changed__c)
                )
                ? getConfig(mxOrderEventEnum).Source_SObject_Fields_Changed__c.replaceAll('(\r\n|\r|\n)','').split(',')
                : new List<String>();
    }
    /**
     * @description Is the MX Order Event eligible for record type?
     * Note: If no record type is configured for the event, then this method will return TRUE
     * @param CDdMxOrderEventEnum event
     * @param SObject sObj
     * @return Boolean
     */
    public static Boolean isEventEligibleForRecordType(CDdMxOrderEventEnum event, SObject sObj){
        return (!isEventFilteredForSObjectRecordTypes(event) || (sObj.isSet('RecordTypeId') && isEventAllowedForSObjectRecordType(event, (Id)sObj.get('RecordTypeId')) ));        
    }
    /**
     * @description Is the Mx Order Event configured for certain record types of the SObject record?
     */
    public static Boolean isEventFilteredForSObjectRecordTypes(CDdMxOrderEventEnum mxOrderEventEnum){
        return !SOURCE_SOBJECT_RECORD_TYPE_IDS_FOR_MX_ORDER_EVENT.get(mxOrderEventEnum).isEmpty();
    }
    /**
     * @description Is the Mx Order Event allowed for input Record Type Id of the SObject record?
     */
    public static Boolean isEventAllowedForSObjectRecordType(CDdMxOrderEventEnum mxOrderEventEnum, Id recordTypeId){
        if (isEventFilteredForSObjectRecordTypes(mxOrderEventEnum)){
            return SOURCE_SOBJECT_RECORD_TYPE_IDS_FOR_MX_ORDER_EVENT.get(mxOrderEventEnum).contains(recordTypeId);
        }
        return true;
    }
    /**
     * @description Does the Mx Order Event have an Apex Mapping Handler?
     * @param CDdMxOrderEventEnum event
     * @return Boolean
     */
    public static Boolean hasApexMappingHandler(CDdMxOrderEventEnum event){
        return MX_ORDER_EVENT_APEX_MAPPING_HANDLER.containsKey(event);       
    }    
    /**
     * @description Return the appropriate Mx Order Event for the input sObject 
     * Criteria that drive what the appropriate Mx Order Event could be
     * - RecordTypeId the sObject record belongs to (provided the event is filtered by record type)
     * - Status value on the sObject record
     * @param String sourceSObjectType
     * @param sObject sourceSObject
     * @return CDdMxOrderEventEnum - return the Mx Order Event
     */
    public static CDdMxOrderEventEnum getMxOrderEvent(String sourceSObjectType, SObject sourceSObject){
        CDdMxOrderEventEnum event = null;
        if (MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE.containsKey(sourceSObjectType) && STATUS_API_FIELD_FOR_SOBJECT_TYPE.containsKey(sourceSObjectType)){
            Map<String, CDdMxOrderEventEnum> mxOrderEventForStatus = MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE.get(sourceSObjectType);
            String statusApiFieldName = STATUS_API_FIELD_FOR_SOBJECT_TYPE.get(sourceSObjectType);
            if (sourceSObject.isSet(statusApiFieldName)){
                String statusValue = (String)sourceSObject.get(statusApiFieldName);
                if (String.isNotBlank(statusValue) && mxOrderEventForStatus.containsKey(statusValue)){
                    event = mxOrderEventForStatus.get(statusValue);
                }
            } 
        }
        return isValidMxOrderEvent(event, sourceSObjectType, sourceSObject) ? event : null;
    }
    /**
     * @description Return the applicable status values for an SObject Type pertaining to a Mx Order Event
     * @param String sourceSObjectType
     * @param CDdMxOrderEventEnum event
     * @return Set<String> Collection of status values
     */
    public static Set<String> getSourceSObjectStatusValues(String sourceSObjectType, CDdMxOrderEventEnum event){
        Set<String> sourceSObjectStatusValues = new Set<String>();
        if (MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE.containsKey(sourceSObjectType) && STATUS_API_FIELD_FOR_SOBJECT_TYPE.containsKey(sourceSObjectType)){
            Map<String, CDdMxOrderEventEnum> mxOrderEventForStatus = MX_ORDER_EVENT_FOR_STATUS_BY_SOURCE_SOBJECT_TYPE.get(sourceSObjectType);
            for (String statusValue : mxOrderEventForStatus.keySet()){
                if (mxOrderEventForStatus.get(statusValue).equals(event)){
                    sourceSObjectStatusValues.add(statusValue);
                }
            }
        }
        return sourceSObjectStatusValues;
    }
}