/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/20/2019
*
* @group SObject Field Copy
*
* @description This object may initialize one or more instances of 'CDdSObjectFieldCopyObj' depending on 
*	how many target sObject types the data needs to be copied to.
* For example: A Parent Account will require data to be copied over to the Child Account.
* 	as well as to the 'Contacts' of the Parent Account
*	A 'Marketplace' Account will only require data to be copied over to the associated 'Contact' records 
*
* Steps performed
*	Query the metadata records from 'SObject Copy Record Types' for the input 'Source SObject Type' 
*	and input 'Source Record Type Developer Name'
*	If atleast one record found,
*		Initialize the object CDdSObjectFieldCopyObj
*		Set the corresponding source and target fields on the object CDdSObjectFieldCopyObj
*		If more than one record found for the same targetSObjectType, add the additional target record type names 
*		to the Collection targetRecordTypeDeveloperName
*		Query the metadata 'SObject Copy Field Mapping' with input for sourceSObjectType and targetSObjectType
*			and populate the sourceTargetfieldMapping Map Collection on the object CDdSObjectFieldCopyObj.
*		Create a new object CDdSObjectFieldCopyObj for additional targetSObjectType(s) found for the input 'Source SObject Type'
*		Finally, set the Collection of CDdSObjectFieldCopyObj objects on the member variable fieldCopyObjs 
*
**************************************************************************************************************************************/
public class CDdSObjectFieldCopyInitializer {
  /**
    * @description A Collection of SObject Field Copy objects that represent the configuration as found within custom metadata
    * - SObject Copy Record Type
    * - SObject Copy Field Mapping
    **/						
    @AuraEnabled
    public List<CDdSObjectFieldCopyObj> fieldCopyObjs {get; set;}
    /**
     * @description default constructor
     * @param sourceSObjectType the input source object type
     **/			
    public CDdSObjectFieldCopyInitializer(String sourceSObjectType){
        setSObjectFieldCopyObj(sourceSObjectType);
    }
    /**
    * @description Return the field copy object for the input target object type
    * @param targetSObjectType the input target object type
    **/		
    public CDdSObjectFieldCopyObj getFieldCopyObj(String targetSObjectType){
        for (CDdSObjectFieldCopyObj fcObj : this.fieldCopyObjs){
            if (targetSObjectType.equals(fcObj.targetSObjectType)){
                return fcObj;
            }
        }
        return null;		
    }
    /**
    * @description Populate the member variable Collection fieldCopyObjs with the retrieved custom metadata information
    * @param sourceSObjectType the input source object type
    **/		
    private void setSObjectFieldCopyObj(String sourceSObjectType){
        Map<String, CDdSObjectFieldCopyObj> fieldCopyObjByTargetSObjectType  = new Map<String, CDdSObjectFieldCopyObj>();
        for (SObject_Copy_Record_Type__mdt copyRecordType 
                        : [SELECT Source_Record_Type_Developer_Name__c, Source_SObject_Key__c, Source_SObject_Type__c
                            , Target_Record_Type_Developer_Name__c, Target_SObject_Key__c, Target_SObject_Type__c
                            FROM SObject_Copy_Record_Type__mdt
                            WHERE Source_SObject_Type__c = :sourceSObjectType
                            ORDER BY Source_SObject_Type__c, Target_SObject_Type__c ASC  
                        ]){
            if (fieldCopyObjByTargetSObjectType.containsKey(copyRecordType.Target_SObject_Type__c)){
                fieldCopyObjByTargetSObjectType.get(copyRecordType.Target_SObject_Type__c)
                                .sourceRecordTypeDeveloperNames.add(copyRecordType.Source_Record_Type_Developer_Name__c);				
                fieldCopyObjByTargetSObjectType.get(copyRecordType.Target_SObject_Type__c)
                                .targetRecordTypeDeveloperNames.add(copyRecordType.Target_Record_Type_Developer_Name__c);
            } else {
                CDdSObjectFieldCopyObj fcObj = new CDdSObjectFieldCopyObj();
                fcObj.sourceSObjectType = copyRecordType.Source_SObject_Type__c;
                fcObj.sourceRecordKeyField = copyRecordType.Source_SObject_Key__c;
                fcObj.sourceRecordTypeDeveloperNames = new Set<String>{copyRecordType.Source_Record_Type_Developer_Name__c};
                fcObj.targetSObjectType = copyRecordType.Target_SObject_Type__c;
                fcObj.targetRecordKeyField = copyRecordType.Target_SObject_Key__c;
                fcObj.targetRecordTypeDeveloperNames = new Set<String>{copyRecordType.Target_Record_Type_Developer_Name__c};
                fcObj.sourceTargetfieldMapping = new Map<String, List<SObject_Copy_Field_Mapping__mdt>>();
                fcObj.sourceFields = new List<String>();
                fieldCopyObjByTargetSObjectType.put(fcObj.targetSObjectType, fcObj);				
            }
        }
        setFieldMapping(sourceSObjectType, fieldCopyObjByTargetSObjectType);
        this.fieldCopyObjs = new List<CDdSObjectFieldCopyObj>();
        this.fieldCopyObjs.addAll(fieldCopyObjByTargetSObjectType.values());
    }
    /**
     * @description Set the Collection of Source Target field mapping from the retrieved custom metadata information
     **/	
    private void setFieldMapping(String sourceSObjectType, Map<String, CDdSObjectFieldCopyObj> fieldCopyObjByTargetSObjectType){
        Boolean isAsynchronous = (System.isBatch() || System.isQueueable() || System.isScheduled());
        Map<String, Set<String>> sourceFieldsForTargetSObjectType = new Map<String, Set<String>>();
        for (SObject_Copy_Field_Mapping__mdt copyFieldMapping 
                        : [SELECT Asynchronous__c, Copy_Only_If_Target_Is_Blank__c, Realtime__c
                            , Source_SObject_Type__c, Source_Record_Type_Developer_Name__c, Source_API_Field__c
                            , Target_SObject_Type__c, Target_Record_Type_Developer_Name__c, Target_API_Field__c
                            , Sequence__c
                            FROM SObject_Copy_Field_Mapping__mdt
                            WHERE Source_SObject_Type__c = :sourceSObjectType
                            AND Target_SObject_Type__c IN :fieldCopyObjByTargetSObjectType.keySet()
                            ORDER BY Target_SObject_Type__c, Sequence__c ASC
                        ]){
            if ( (!isAsynchronous && copyFieldMapping.Realtime__c) || (isAsynchronous && copyFieldMapping.Asynchronous__c)){
                if (sourceFieldsForTargetSObjectType.containsKey(copyFieldMapping.Target_SObject_Type__c)){
                    Set<String> sourceFields = sourceFieldsForTargetSObjectType.get(copyFieldMapping.Target_SObject_Type__c);
                    if (!sourceFields.contains(copyFieldMapping.Source_API_Field__c)){
                        sourceFieldsForTargetSObjectType.get(copyFieldMapping.Target_SObject_Type__c).add(copyFieldMapping.Source_API_Field__c);
                        fieldCopyObjByTargetSObjectType.get(copyFieldMapping.Target_SObject_Type__c).sourceFields.add(copyFieldMapping.Source_API_Field__c);
                        fieldCopyObjByTargetSObjectType.get(copyFieldMapping.Target_SObject_Type__c)
                            .sourceTargetfieldMapping
                            .put(copyFieldMapping.Source_API_Field__c, new List<SObject_Copy_Field_Mapping__mdt>{copyFieldMapping});   					
                    } else {
                        fieldCopyObjByTargetSObjectType.get(copyFieldMapping.Target_SObject_Type__c)
                            .sourceTargetfieldMapping
                            .get(copyFieldMapping.Source_API_Field__c)
                            .add(copyFieldMapping); 	    				
                    }
                } else {
                    sourceFieldsForTargetSObjectType.put(copyFieldMapping.Target_SObject_Type__c, new Set<String>{copyFieldMapping.Source_API_Field__c});
                    fieldCopyObjByTargetSObjectType.get(copyFieldMapping.Target_SObject_Type__c).sourceFields.add(copyFieldMapping.Source_API_Field__c);
                    fieldCopyObjByTargetSObjectType.get(copyFieldMapping.Target_SObject_Type__c)
                        .sourceTargetfieldMapping
                        .put(copyFieldMapping.Source_API_Field__c, new List<SObject_Copy_Field_Mapping__mdt>{copyFieldMapping});
                }
            }
        }
    }	
}