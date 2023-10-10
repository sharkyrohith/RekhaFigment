/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/20/2019
*
* @group SObject Field Copy
*
* @description This is the SObject Field Copy Object to hold the information populated from the following Custom Metadata objects
* - SObject Copy Record Type
* - SObject Copy Field Mapping
* 
**************************************************************************************************************************************/
public class CDdSObjectFieldCopyObj {
    /**
    * @description Source sObject type of the record to copy from
    **/						
    @AuraEnabled
    public String sourceSObjectType {get; set;}
    /**
    * @description Source sObject key (example: Id field) of the record to copy from
    **/						
    @AuraEnabled
    public String sourceRecordKeyField {get; set;}
    /**
    * @description Eligible Source sObject record type(s) of the records to copy from
    **/						
    @AuraEnabled
    public Set<String> sourceRecordTypeDeveloperNames {get; set;}
    /**
    * @description Target sObject type of the record to copy to	
    **/						
    @AuraEnabled
    public String targetSObjectType {get; set;}
    /**
    * @description Target sObject key (example: reference key AccountId field on the Contact) of the record to copy to
    **/						
    @AuraEnabled
    public String targetRecordKeyField {get; set;}
    /**
    * @description Eligible Target sObject record type(s) of the records to copy to. 
    * If 'ALL', there is no restriction on the target records for field copy. This Collection is expected to be empty for 'ALL' option
    **/						
    @AuraEnabled
    public Set<String> targetRecordTypeDeveloperNames {get; set;}
    /**
    * @description Source to Target field mapping. The field names in the mapping represent the API name in the object definition
    *   Note:   There will likely be more than one target field mapping for a source field, 
    *           based on how the copy is handled for individual record types
    **/						
    @AuraEnabled
    public Map<String, List<SObject_Copy_Field_Mapping__mdt>> sourceTargetfieldMapping {get; set;}
    /**
    * @description An ordered collection of source fields 
    **/           
    @AuraEnabled
    public List<String> sourceFields {get; set;}
}