/********************************************************************************************************************
* @author Praveen
* @date 07/20/2022
*
* @group Merchant Services
*
* @description Call is for providing contact field set values to the equipment request screen.
* 
**************************************************************************************************************************************/



public with sharing class CDdMxFieldSetController {
    public static DescribeSObjectResult sObjectResult;
    public class MetadataResponse {

        @AuraEnabled
        public String recordTypeId;

        @AuraEnabled
        public String fieldSetLabel;

        @AuraEnabled
        public String sObjectName;
        @AuraEnabled
        public List<String> fieldsMetadata;

        //@AuraEnabled
       // public List<field> fieldsMetadata;

    }
    public class field {
        @AuraEnabled
        public string fieldname;
        @AuraEnabled
        public string fieldApiName;
        @AuraEnabled
        public Boolean Required;
    }

     /**
     * @Descriptoin Methods takes the field setName and object Name as parameter and return the fields as metadata.
     * @param string fieldSetName
     * @param string objectName
     * @return MetadataResponse
     */
    @AuraEnabled(Cacheable=true)
    public static MetadataResponse getFields(String fieldSetName, String objectName) {
        Schema.SObjectType objectType = null;
        //objectName = 'contact';
         if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName);
        }       
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Schema.FieldSet fieldSetObj = objectDescribe.FieldSets.getMap().get(fieldSetName);
       // String objectApiName = describeSObjectResultObj.getName();
        if (fieldSetObj == null || fieldSetObj.getFields().isEmpty()){
            return null;
        }
        List<string> fieldss = new List<string>();
        for(Schema.FieldSetMember objField : fieldSetObj.getFields()){
           // field fie = new field();
            //fie.fieldname = objField.getFieldPath();
           // fie.Required =objField.getRequired();
           fieldss.add(objField.getFieldPath());
        }
        //system.debug(' fields '+fields);
        MetadataResponse response = new MetadataResponse();
        response.fieldsMetadata = fieldss;
        response.sObjectName =objectName ;
    return response;
    }
     /**
     * @Descriptoin Methods to validate contact owner. If the contact adr owner is not active assign the parent owner or account owner as contact owner.
     * @param string accountId
     * @param string contactId
     * @return ContactOwnerValidationResultModel
     */
    @AuraEnabled(Cacheable=true)
    public static ContactOwnerValidationResultModel validateContactOwner(String accountId,String contactId){
        if(String.isNotBlank(contactId)){
            accountId = [select AccountId from contact where Id = :contactId].AccountId;
        }
        ContactOwnerValidationResultModel contactValidation = new ContactOwnerValidationResultModel();
        contactValidation.accountId = accountId;
        contactValidation.noActiveOwnerFound =false;
        Account act = [select Id, ADR_Owner_Actual__c, owner.isactive, ADR_Owner_Actual__r.isactive, parentId, parent.owner.isactive from account where Id = :accountId];
        contactValidation = validateContactOwnerFromAccount(act,contactValidation);
        return contactValidation;
    }
      /**
     * @Descriptoin Methods to validate contact owner. If the contact adr owner is not active assign the parent owner or account owner as contact owner.
     * @param string accountId
     * @param ContactOwnerValidationResultModel ContactOwnerValidationResultModel
     * @return ContactOwnerValidationResultModel
     */
    public static ContactOwnerValidationResultModel validateContactOwnerFromAccount(Account act, ContactOwnerValidationResultModel contactValidation){
        if(String.isNotBlank(act.ADR_Owner_Actual__c) && act.ADR_Owner_Actual__r.isactive){
            contactValidation.accountId = act.Id;
        } else if(String.isBlank(act.ADR_Owner_Actual__c) && act.owner.isactive){
            contactValidation.accountId = act.Id;
        } else if(String.isNotBlank(act.ADR_Owner_Actual__c) && !act.ADR_Owner_Actual__r.isactive && String.isNotBlank(act.parentId) && act.parent.owner.isactive){
            contactValidation.accountId = act.parentId;
        } else {
            contactValidation.noActiveOwnerFound =true;
        } 
        return contactValidation;
    }
    public class ContactOwnerValidationResultModel{
        @AuraEnabled
        public string accountId;
        @AuraEnabled
        public Boolean noActiveOwnerFound;
    }
  
}