/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/20/2019
*
* @group SObject Field Copy
*
* @description This object utilizes the input custom metadata CDdSObjectFieldCopyObj and is responsible to 
*	Retrieve the source records using dyamic SOQL query
*	Retrieve the target records using dynamic SOQL query
*	Copy the source fields from the source records over to the target fields on the target records
*
**************************************************************************************************************************************/
public class CDdSObjectFieldCopyProcessor {
    /**
     * @description An instance of SObject Field Copy object that represents the configuration as found within custom metadata
     **/						
    @AuraEnabled	
    public CDdSObjectFieldCopyObj fieldCopyObj {get; set;}
    /**
     * @description A Collection of source records with the key 
     *	as the value found in the 'sourceRecordKeyField' of the source record
     **/						
    @AuraEnabled	
    public Map<String, sObject> sourceRecords {get; set;}
    /**
     * @description A Collection of target records 
     **/						
    @AuraEnabled	
    public List<sObject> targetRecords {get; set;}
    /**
     * @description A static constants value for record type 'ALL' as configured in the custom metadata
     **/						
    private static final String RECORD_TYPE_ALL = 'ALL';

    private static Set<String> FIELD_TYPES_STRING = new Set<String>{Schema.DisplayType.String.name()
                                                            , Schema.DisplayType.ID.name()
                                                            , Schema.DisplayType.Picklist.name()
                                                            , Schema.DisplayType.Reference.name()
                                                            , Schema.DisplayType.Email.name()};
    private static Set<String> FIELD_TYPES_NUMBER = new Set<String>{Schema.DisplayType.Double.name()
                                                            , Schema.DisplayType.Integer.name()
                                                            , Schema.DisplayType.Long.name()
                                                            , Schema.DisplayType.Currency.name()
                                                            , Schema.DisplayType.Percent.name()};
    private static Set<String> FIELD_TYPES_BOOLEAN = new Set<String>{Schema.DisplayType.boolean.name()};  
    /**
     * @description default constructor
     * @param obj an instance of SObject Field Copy object
     * @param sourceRecordIds the input collection of source record identifiers
     **/			
    public CDdSObjectFieldCopyProcessor(CDdSObjectFieldCopyObj obj, Set<Id> sourceRecordIds) {
        this(obj, sourceRecordIds, null);
    }
    /**
     * @description default constructor
     * @param obj an instance of SObject Field Copy object
     * @param sourceRecordIds the input collection of source record identifiers
     * @param targetRecordIds the input collection of target record identifiers	
     **/			
    public CDdSObjectFieldCopyProcessor(CDdSObjectFieldCopyObj obj, Set<Id> sourceRecordIds, Set<Id> targetRecordIds) {
        this.fieldCopyObj = obj;
        setSourceRecords(sourceRecordIds);
        setTargetRecords(targetRecordIds);
    }	
    /**
     * @description Set the source records
     *	Prepare dynamic SOQL query where
     *		sourceSObjectType is the object to query on
     *		Fields to retrieve are 
     *			- the sourceRecordKeyField 
     *			- and the source fields which are the keys found in the Collection sourceTargetfieldMapping
     *	Execute the query and populate the Collection Map sourceRecords with
     *		- the value from 'sourceRecordKeyField' as the key
     *		- and sourceRecord as the queried sObject record
     * @param sourceRecordIds the input collection of source record identifiers
     **/		
    private void setSourceRecords(Set<Id> sourceRecordIds){
        Set<String> sourceFields = new Set<String>();
        sourceFields.add('Id');
        sourceFields.add(this.fieldCopyObj.sourceRecordKeyField);
        sourceFields.addAll(this.fieldCopyObj.sourceTargetfieldMapping.keySet());
        this.sourceRecords = new Map<String, sObject>();
        Set<String> recordTypeDeveloperNames = this.fieldCopyObj.sourceRecordTypeDeveloperNames;
        String query = 'SELECT '
                        + String.join(new List<String>(sourceFields), ',')
                        + (this.fieldCopyObj.sourceRecordTypeDeveloperNames.contains(RECORD_TYPE_ALL)
                            ? ''
                            : ', ' + 'RecordTypeId' + ', ' + 'RecordType.DeveloperName'     
                            )
                        + ' FROM ' + this.fieldCopyObj.sourceSObjectType
                        + ' WHERE ' +  this.fieldCopyObj.sourceRecordKeyField + ' IN ' + ':' + 'sourceRecordIds'
                        + (this.fieldCopyObj.sourceRecordTypeDeveloperNames.contains(RECORD_TYPE_ALL)
                            ? ''
                            : ' AND ' + 'RecordType.DeveloperName' + ' IN ' + ':' + 'recordTypeDeveloperNames'
                            );
        for (sObject sObj : Database.query(query)){
            this.sourceRecords.put((String)sObj.get(this.fieldCopyObj.sourceRecordKeyField), sObj);
        }
    }
    /**
     * @description Set the target records
     *	Prepare dynamic SOQL query where
     *		targetSObjectType is the object to query on
     *		Fields to retrieve are 
     *			- the targetRecordKeyField 
     *			- and the target fields which are the values found in the Collection sourceTargetfieldMapping
     *	Execute the query and process the result of targetRecords
     *		For each target record
     *			- extract the corresponding sourceRecord (using the value in targetRecordKeyField)
     *			- compare the target record on the values of 'target fields' for changes against 
     *				corresponding field values found in the sourceRecord
     *			- if any value is found to be different on the target record, then 
     *				i. replace the value with the corresponding field value from the sourceRecord
     *				ii. add the record to the 'targetRecords' Collection
     * @param targetRecordIds the input collection of traget record identifiers		
     **/		
    private void setTargetRecords(Set<Id> targetRecordIds){
        Set<String> targetFieldsToQuery = new Set<String>();
        targetFieldsToQuery.add('Id');
        targetFieldsToQuery.add(this.fieldCopyObj.targetRecordKeyField);
        for (List<SObject_Copy_Field_Mapping__mdt> copyFieldMappings : this.fieldCopyObj.sourceTargetfieldMapping.values()){
            for (SObject_Copy_Field_Mapping__mdt copyFieldMapping : copyFieldMappings){
                targetFieldsToQuery.add(copyFieldMapping.Target_API_Field__c);
            }
        }
        this.targetRecords = new List<sObject>();
        Set<String> sourceRecordKeys = this.sourceRecords.keySet();
        Set<String> recordTypeDeveloperNames = this.fieldCopyObj.targetRecordTypeDeveloperNames;

        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(
                                                         new String[]{this.fieldCopyObj.sourceSObjectType
                                                                         ,this.fieldCopyObj.targetSObjectType});
        Map<String, Schema.SObjectField> sourceFieldMap = descResult[0].fields.getMap();
        Map<String, Schema.SObjectField> targetFieldMap = descResult[1].fields.getMap();

        String query = 'SELECT '
                        + String.join(new List<String>(targetFieldsToQuery), ',')
                        + (this.fieldCopyObj.targetRecordTypeDeveloperNames.contains(RECORD_TYPE_ALL)
                            ? ''
                            : ', ' + 'RecordTypeId' + ', ' + 'RecordType.DeveloperName'		
                            )						
                        + ' FROM ' + this.fieldCopyObj.targetSObjectType
                        + ' WHERE ' +  this.fieldCopyObj.targetRecordKeyField + ' IN ' + ':' + 'sourceRecordKeys'
                        + (	(targetRecordIds!=null && !targetRecordIds.isEmpty())
                            ? ' AND ' + 'Id' + ' IN '  + ':' + 'targetRecordIds'
                            : ''
                            )
                        + (this.fieldCopyObj.targetRecordTypeDeveloperNames.contains(RECORD_TYPE_ALL)
                            ? ''
                            : ' AND ' + 'RecordType.DeveloperName' + ' IN ' + ':' + 'recordTypeDeveloperNames'
                            );
        for (sObject targetObj : Database.query(query)){
            sObject sourceObj = this.sourceRecords.get((String)targetObj.get(this.fieldCopyObj.targetRecordKeyField));
            Boolean copyField = false;
            for (String sourceField : this.fieldCopyObj.sourceFields){
                for (SObject_Copy_Field_Mapping__mdt copyFieldMapping : this.fieldCopyObj.sourceTargetfieldMapping.get(sourceField)){
                    String targetField = copyFieldMapping.Target_API_Field__c; 
                    if (copyField(sourceObj, targetObj
                                            , sourceField, targetField
                                            , sourceFieldMap,  targetFieldMap
                                            , copyFieldMapping)){
                        copyField = true;
                    }					
                }
            }
            if (copyField){
                this.targetRecords.add(targetObj);
            }
        }
    }
    /**
     * @description Copy field from source record to target record only if the value is different between the two records
     **/	
    private Boolean copyField(SObject sourceObj, SObject targetObj
                            , String sourceField, String targetField
                            , Map<String, Schema.SObjectField> sourceFieldMap
                            , Map<String, Schema.SObjectField> targetFieldMap
                            , SObject_Copy_Field_Mapping__mdt copyFieldMapping){
        Schema.DescribeFieldResult sourceSObjectFieldResult = sourceFieldMap.get(sourceField).getDescribe();
        Schema.DescribeFieldResult targetSObjectFieldResult = targetFieldMap.get(targetField).getDescribe();

        if (!RECORD_TYPE_ALL.equals(copyFieldMapping.Source_Record_Type_Developer_Name__c)
            &&
                (
                    String.isBlank((Id)sourceObj.get('RecordTypeId'))
                    ||
                    (!copyFieldMapping.Source_Record_Type_Developer_Name__c
                        .equals(String.valueOf(sourceObj.getSObject('RecordType').get('DeveloperName')))
                    )
                )
            ) {
            return false;
        }

        if (!RECORD_TYPE_ALL.equals(copyFieldMapping.Target_Record_Type_Developer_Name__c)
            &&
                (
                    String.isBlank((Id)targetObj.get('RecordTypeId'))
                    ||
                    (!copyFieldMapping.Target_Record_Type_Developer_Name__c
                        .equals(String.valueOf(targetObj.getSObject('RecordType').get('DeveloperName')))
                    )
                )
            ) {
            return false;
        }		 

        Boolean copyOnlyIfTargetIsBlank = copyFieldMapping.Copy_Only_If_Target_Is_Blank__c;
        if (FIELD_TYPES_STRING.contains(sourceSObjectFieldResult.getType().name())
            && FIELD_TYPES_STRING.contains(targetSObjectFieldResult.getType().name())){
            String sourceFieldValue = (String)sourceObj.get(sourceField);
            String targetFieldValue = (String)targetObj.get(targetField);
            if (String.isNotBlank(sourceFieldValue)
                    &&
                    (String.isBlank(targetFieldValue) || (!copyOnlyIfTargetIsBlank && !sourceFieldValue.equals(targetFieldValue)))
                ){
                targetObj.put(targetField, sourceFieldValue);
                return true;
            }
        }
        if (FIELD_TYPES_NUMBER.contains(sourceSObjectFieldResult.getType().name())
            && FIELD_TYPES_NUMBER.contains(targetSObjectFieldResult.getType().name())){
            Decimal sourceFieldValue = (Decimal)sourceObj.get(sourceField);
            Decimal targetFieldValue = (Decimal)targetObj.get(targetField);
            if (sourceFieldValue != null
                    &&
                    (targetFieldValue == null || (!copyOnlyIfTargetIsBlank && (sourceFieldValue != targetFieldValue)))
                ){
                targetObj.put(targetField, sourceFieldValue);
                return true;
            }
        }
        if (FIELD_TYPES_BOOLEAN.contains(sourceSObjectFieldResult.getType().name())
        && FIELD_TYPES_BOOLEAN.contains(targetSObjectFieldResult.getType().name())){
            Boolean sourceFieldValue = (Boolean)sourceObj.get(sourceField);
            Boolean targetFieldValue = (Boolean)targetObj.get(targetField);
            if (sourceFieldValue != null &&
                (targetFieldValue == null || 
                (!copyOnlyIfTargetIsBlank && (sourceFieldValue != targetFieldValue))))
               {
                   targetObj.put(targetField, sourceFieldValue);
                   return true;
               }
        }		
        return false;
    }	
}