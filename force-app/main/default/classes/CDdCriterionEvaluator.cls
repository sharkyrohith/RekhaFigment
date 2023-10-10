/**
 * CDdCriterionEvaluator
 *
 * @author      Sahil
 * @date        2021-05-05
 * @decription  interface to evaluate criteria of an incoming record
 *              BIZS-1076 - Raju L - Changed from Interface to virtual class so that the child classes can reuse some methods defined here.
 *              BIZS-1595 - Raju L - Added Project Shield CMT
 */
public virtual class CDdCriterionEvaluator {
    private static String CASE_KEY_PREFIX = 'Case-';

    @TestVisible
    protected Set<String> BOOLEAN_FIELD_VALUE_OPTIONS = new Set<String>{'true','false'};

    public virtual Boolean evaluateCriterion(String fieldName, String fieldValue, SObject record) {
        return false;
    }

    public virtual Boolean evaluateCriterion(String fieldName, String fieldValue, SObject record, Boolean caseSensitive) {
        return false;
    }

    public virtual Boolean evaluateCriterion(String fieldName, SObject record) {
        return false;
    }

    public virtual Boolean evaluateCriterion() {
        return false;
    }

    public virtual Boolean evaluateCriterion(Routing_Criterion__mdt routingCriterion, SObject record) {
        return false;
    }

    public virtual Boolean evaluateCriterion(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        return false;
    }

    public virtual Boolean evaluateCriterion(Proactive_Case_Creation_Criterion__mdt criterion, Case record) {
        return false;
    }

    public virtual Boolean evaluateCriterion(Workflow_Criterion__mdt workflowCriterion, SObject record) {
        return false;
    }

    @TestVisible
    protected String getRelatedObjectFieldValue(SObject record,String recordFieldApiName,Map<Id,SObject> relatedObjectMap,String relatedObjectFieldApiName) {
        if (record == null || recordFieldApiName == null || relatedObjectMap == null || relatedObjectMap.isEmpty() || !relatedObjectMap.containsKey((Id)record.get(recordFieldApiName))) {
            return CDdCoreConstants.BLANK_STRING;
        }
        SObject relatedObject = relatedObjectMap.get((Id)record.get(recordFieldApiName));
        return relatedObject != null ? CDdUtilities.getFieldValAsString(relatedObject,relatedObjectFieldApiName) : null;
    }

    @TestVisible
    protected String getRelatedObjectFieldValue(Id recId,Map<Id,SObject> relatedObjectMap,String relatedObjectFieldApiName) {
        if (recId == null || relatedObjectMap == null || relatedObjectMap.isEmpty() || !relatedObjectMap.containsKey(recId)) {
            return CDdCoreConstants.BLANK_STRING;
        }
        SObject relatedObject = relatedObjectMap.get(recId);
        return relatedObject != null ? CDdUtilities.getFieldValAsString(relatedObject,relatedObjectFieldApiName) : null;
    }

    @TestVisible
    protected String getRelatedObjectFieldValue(SObject relatedObject,String relatedObjectFieldApiName) {
        if (relatedObject == null) {
            return CDdCoreConstants.BLANK_STRING;
        }
        return relatedObject != null ? CDdUtilities.getFieldValAsString(relatedObject,relatedObjectFieldApiName) : null;
    }

    protected Map<String,String> lookupFieldMap = new Map<String,String> {
        'Case-Account' => 'AccountId',
        'Case-Opportunity' => 'Opportunity_Name__c',
        'Case-Contact' => 'ContactId',
        'Case-Current Owner (User)' => 'OwnerId',
        'Case-Target Queue' => 'OwnerId',
        'Case-Previous Queue' => 'Previous_Queue_ID__c',
        'Case-Target Queue Mapping' => 'OwnerId',
        'Case-Previous Queue Mapping' => 'Previous_Queue_ID__c',
        'LiveChatTranscript-Case' => 'CaseId'
    };

    @TestVisible
    protected Map<Id,SObject> getRelatedObjectMap(String key) {
        switch on key {
            when 'Case-Account' {
                return CDdCaseTriggerOptimizationHelper.getAccountMap();
            }
            when 'Case-Opportunity' {
                return CDdCaseTriggerOptimizationHelper.getOpportunityMap();
            }
            when 'Case-Contact' {
                return CDdCaseTriggerOptimizationHelper.getContactByIdMap();
            }
            when 'Case-Target Queue','Case-Previous Queue' {
                return CDdGenericTriggerOptimizationHelper.getQueueMap();
            }
            when 'Case-Target Queue Mapping','Case-Previous Queue Mapping' {
                return CDdGenericTriggerOptimizationHelper.getQueueMappingMap();
            }
            when 'Case-Current Owner (User)','Current User' {
                return CDdCaseTriggerOptimizationHelper.getUserMap();
            }
            when 'LiveChatTranscript-Case' {
                return CDdLiveChatTransOptimizationHelper.getCaseMap();
            }
        }
        return null;
    }

    @TestVisible
    protected String getRelatedObjectFieldValue(Case_Transfer_Validation_Criterion__mdt criterion, Case record) {
        Case oldRecord = (trigger.isUpdate) ? (Case)trigger.oldMap.get(record.Id) : null;
        String key = null;
        Id relatedRecordId = null;
        Sobject relatedRecord = null;

        switch on criterion.Related_Object__c {
            when 'Account','Opportunity','Contact','Target Queue','Target Queue Mapping','Previous Queue','Previous Queue Mapping' {
                key = CASE_KEY_PREFIX + criterion.Related_Object__c;
            }
            when 'Current Owner (User)' {
                String ownerId = oldRecord.OwnerId;
                if (String.isNotBlank(ownerId) && CDdUtilities.idIsUser(ownerId)) {
                    key = CASE_KEY_PREFIX + criterion.Related_Object__c;
                    relatedRecordId = ownerId;
                }
            }
            when 'Current User' {
                key = criterion.Related_Object__c;
                relatedRecordId = UserInfo.getUserId();
            }
            when 'Latest Case Note' {
                List<CaseFeed> caseFeeds = CDdCaseTriggerOptimizationHelper.getCaseFeeds(record.Id);
                if (caseFeeds == null || caseFeeds.isEmpty()) {
                    return null;
                }
                relatedRecord = caseFeeds[0];
            }
            when 'DispatchCallout' {
                String actualFieldValue = String.isNotBlank(String.valueOf(record.get('DispatchRQResponse__c'))) ?
                                getDispatchAttribute(String.valueOf(record.get('DispatchRQResponse__c')),criterion.Related_Object_Field_API_Name__c): '';

                return actualFieldValue;
            }
            when else {
                return null;
            }
        }

        if (relatedRecord != null) {
            return getRelatedObjectFieldValue(relatedRecord,criterion.Related_Object_Field_API_Name__c);
        }

        if (String.isBlank(key)) {
            return null;
        }

        Map<Id,SObject> relatedObjectMap = getRelatedObjectMap(key);
        if (relatedRecordId != null) {
            return getRelatedObjectFieldValue(relatedRecordId,relatedObjectMap,criterion.Related_Object_Field_API_Name__c);
        }

        String lookupField = lookupFieldMap.get(key);
        return getRelatedObjectFieldValue(record,lookupField,relatedObjectMap,criterion.Related_Object_Field_API_Name__c);
    }

    protected String getRelatedObjectFieldValue(Proactive_Case_Creation_Criterion__mdt criterion, Case record) {
        Case oldRecord = (trigger.isUpdate) ? (Case)trigger.oldMap.get(record.Id) : null;
        String key = null;
        Id relatedRecordId = null;
        Sobject relatedRecord = null;

        switch on criterion.Related_Object__c {
            when 'Account','Opportunity','Contact'{
                key = CASE_KEY_PREFIX + criterion.Related_Object__c;
            }
            when 'Current Owner (User)' {
                String ownerId = oldRecord.OwnerId;
                if (String.isNotBlank(ownerId) && CDdUtilities.idIsUser(ownerId)) {
                    key = CASE_KEY_PREFIX + criterion.Related_Object__c;
                    relatedRecordId = ownerId;
                }
            }
            when 'Current User' {
                key = criterion.Related_Object__c;
                relatedRecordId = UserInfo.getUserId();
            }
            when else {
                return null;
            }
        }

        if (relatedRecord != null) {
            return getRelatedObjectFieldValue(relatedRecord,criterion.Related_Object_Field_API_Name__c);
        }

        if (String.isBlank(key)) {
            return null;
        }

        Map<Id,SObject> relatedObjectMap = getRelatedObjectMap(key);
        if (relatedRecordId != null) {
            return getRelatedObjectFieldValue(relatedRecordId,relatedObjectMap,criterion.Related_Object_Field_API_Name__c);
        }

        String lookupField = lookupFieldMap.get(key);
        return getRelatedObjectFieldValue(record,lookupField,relatedObjectMap,criterion.Related_Object_Field_API_Name__c);
    }

    @TestVisible
    protected Boolean validateCaseNotes(Id caseId,String operation,String fieldApiName,String fieldValue,Boolean compareCaseSensitive) {
        List<CaseFeed> caseFeeds = CDdCaseTriggerOptimizationHelper.getCaseFeeds(caseId);
        if (caseFeeds == null) {
            caseFeeds = new List<CaseFeed>();
        }
        Boolean retVal = false;
        switch on operation {
            when 'Case Notes exist' {
                fieldValue = String.isNotBlank(fieldValue) && BOOLEAN_FIELD_VALUE_OPTIONS.contains(fieldValue.toLowerCase()) ? fieldValue.toLowerCase() : 'true';
                retVal = fieldValue == 'true' ? !caseFeeds.isEmpty() : caseFeeds.isEmpty();
            }
            when 'Actual value contains string (Like)' {
                for (CaseFeed cf : caseFeeds) {
                    String actualValue = CDdUtilities.getFieldValAsString(cf,fieldApiName);
                    if (String.isNotBlank(actualValue) && (compareCaseSensitive ? actualValue.contains(fieldValue) : actualValue.containsIgnoreCase(fieldValue))) {
                        retVal = true;
                        break;
                    }
                }
            }
            when 'Actual value does not contain string (Not Like)' {
                retVal = !validateCaseNotes(caseId,'Actual value contains string (Like)',fieldApiName,fieldValue,compareCaseSensitive);
            }
            when 'Equals' {
                for (CaseFeed cf : caseFeeds) {
                    String actualValue = CDdUtilities.getFieldValAsString(cf,fieldApiName);
                    if (String.isNotBlank(actualValue) && (compareCaseSensitive ? actualValue.equals(fieldValue) : actualValue.equalsIgnoreCase(fieldValue))) {
                        retVal = true;
                        break;
                    }
                }
            }
            when 'Not Equals' {
                retVal = !validateCaseNotes(caseId,'Equals',fieldApiName,fieldValue,compareCaseSensitive);
            }
        }
        return retVal;
    }

     /**
     * @author      Nayana
     * @date        August 2022
     * @decription  Finds the dispatch attribute value and returns
     * @param   dispatchResponse JSON string for Dispatch Callout.
     * @param   attributeName String separated by (.) to find the value. eg. to get
     *                        tenure string value will be audience.store.tenure
     * @return  String value of specified attribute
     */
    @TestVisible
    protected String getDispatchAttribute(String dispatchResponse,String attributeName) {
        String retVal = '';
        try{
            if(String.isNotBlank(dispatchResponse) && dispatchResponse.contains('salesforceAudienceInfoBulkResponse')){
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(dispatchResponse);
                List<Object> lst_salesforceAudienceInfoBulkResponse = (List<Object>) m.get('salesforceAudienceInfoBulkResponse');
                if(!lst_salesforceAudienceInfoBulkResponse.isEmpty()){
                    Map<String,Object> mapAudienctInfo = (Map<String, Object>)lst_salesforceAudienceInfoBulkResponse[0];
                    do{
                        String strFirst = attributeName.SubStringBefore('.');
                        attributeName = attributeName.SubStringAfter('.');
                        if(mapAudienctInfo.containsKey(strFirst)){
                            mapAudienctInfo = (Map<String,Object>)mapAudienctInfo.get(strFirst);
                        }else{
                            break;
                        }
                    } while(attributeName.contains('.'));
                    if(mapAudienctInfo.containsKey(attributeName)){
                        retVal = String.valueOf(mapAudienctInfo.get(attributeName));
                    }
                }
            }
        }catch(Exception e){
            CDdErrorUtilities.publishException('DispatchResponse','CDdCriterionEvaluator.getDispatchAttribute','',dispatchResponse);
        }
        return retVal;
    }

    @TestVisible
    protected String getActualFieldValue(String fieldName, SObject record) {
        if (String.isBlank(fieldName) || record == null) {
            return CDdCoreConstants.BLANK_STRING;
        }
        return record.get(fieldName) != null ? String.valueOf(record.get(fieldName)) : CDdCoreConstants.BLANK_STRING;
    }


     /**
     * @author      Nayana
     * @date        August 2022
     * @decription  Finds the dispatch attribute value and returns
     * @param   routingCriterion {Routing_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  String value of specified attribute
     */
    @TestVisible
    protected String getActualFieldValue(Routing_Criterion__mdt routingCriterion, SObject record) {
        String actualFieldValue ='';
        if (routingCriterion.Related_Object__c == 'DispatchCallout') {
            actualFieldValue = String.isNotBlank(String.valueOf(record.get('DispatchRQResponse__c'))) ?
                                getDispatchAttribute(String.valueOf(record.get('DispatchRQResponse__c')),routingCriterion.Related_Object_Field_API_Name__c):'';
        }else if(routingCriterion.Related_Object__c == 'Current User'){
            String relatedRecordId = UserInfo.getUserId();
            Map<Id,SObject> relatedObjectMap = getRelatedObjectMap('Current User');
            actualFieldValue = getRelatedObjectFieldValue(relatedRecordId,relatedObjectMap,routingCriterion.Related_Object_Field_API_Name__c);
        } else{
            String key = routingCriterion.Object_API_Name__c + CDdCoreConstants.DELIMITER_HYPHEN + routingCriterion.Related_Object__c;
            String lookupField = lookupFieldMap.get(key);
            Map<Id,SObject> relatedObjectMap = getRelatedObjectMap(key);
            actualFieldValue = getRelatedObjectFieldValue(record,lookupField,relatedObjectMap,routingCriterion.Related_Object_Field_API_Name__c);
        }
        return actualFieldValue;
    }


     /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  Finds the dispatch attribute value and returns
     * @param   routingCriterion {Routing_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  String value of specified attribute
     */
    @TestVisible
    protected String getActualFieldValue(Proactive_Case_Creation_Criterion__mdt routingCriterion, SObject record) {
        String key = routingCriterion.Object_API_Name__c + CDdCoreConstants.DELIMITER_HYPHEN + routingCriterion.Related_Object__c;
        String lookupField = lookupFieldMap.get(key);
        Map<Id,SObject> relatedObjectMap = getRelatedObjectMap(key);
        String actualFieldValue = getRelatedObjectFieldValue(record,lookupField,relatedObjectMap,routingCriterion.Related_Object_Field_API_Name__c);
        return actualFieldValue;
    }


    /**
     * @author      Sid A
     * @date        Sept 2022
     * @decription  Finds the "Compare To" value
     * @param   criterion {Case_Transfer_Validation_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  String value of specified attribute
     */
    @TestVisible
    protected String getCompareToValue(Case_Transfer_Validation_Criterion__mdt criterion, SObject record) {
        return String.isNotBlank(criterion.Field_Value__c) && criterion.Field_Value__c.startsWith('{') ?
                    CDdUtilities.replaceMergeFieldsExtension(record, criterion.Field_Value__c) :
                    criterion.Field_Value__c;
    }

    /**
     * @author      Nayana
     * @date        Sept 2022
     * @decription  Finds the "Compare To" value
     * @param   FieldValue
     * @param   record {SObject} - Parent record being evaluated
     * @return  String value of specified attribute*/
    @TestVisible
    protected String getCompareToValue(String fieldValue, SObject record) {
        return String.isNotBlank(fieldValue) && fieldValue.startsWith('{') ?
                    CDdUtilities.replaceMergeFieldsExtension(record, fieldValue) :
                    fieldValue;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Jan 2023
     * @decription  Finds the dispatch attribute value and returns
     * @param   workflowCriterion {Workflow_Criterion__mdt} - metadata which info to evaluate against.
     * @param   record {SObject} - Parent record being evaluated
     * @return  String value of specified attribute
     */
    @TestVisible
    protected String getActualFieldValue(Workflow_Criterion__mdt workflowCriterion, SObject record) {
        String actualFieldValue ='';
        if (workflowCriterion.Related_Object__c == 'DispatchCallout') {
            actualFieldValue = String.isNotBlank(String.valueOf(record.get('DispatchRQResponse__c'))) ?
                                getDispatchAttribute(String.valueOf(record.get('DispatchRQResponse__c')),workflowCriterion.Related_Object_Field_API_Name__c):'';
        }else if(workflowCriterion.Related_Object__c == 'Current User'){
            String relatedRecordId = UserInfo.getUserId();
            Map<Id,SObject> relatedObjectMap = getRelatedObjectMap('Current User');
            actualFieldValue = getRelatedObjectFieldValue(relatedRecordId,relatedObjectMap,workflowCriterion.Related_Object_Field_API_Name__c);
        } else{
            String key = workflowCriterion.Object_API_Name__c + CDdCoreConstants.DELIMITER_HYPHEN + workflowCriterion.Related_Object__c;
            String lookupField = lookupFieldMap.get(key);
            Map<Id,SObject> relatedObjectMap = getRelatedObjectMap(key);
            actualFieldValue = getRelatedObjectFieldValue(record,lookupField,relatedObjectMap,workflowCriterion.Related_Object_Field_API_Name__c);
        }
        return actualFieldValue;
    }
}