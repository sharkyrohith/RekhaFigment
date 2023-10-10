/**
 * @author Sanidhya Jain
 * @date 2023-08
 *
 * @description Class : BIZS-3185 used to get Fields of the Record on basis object and field set name
*/
public with sharing class CDdShowLightningRecordForm {

    /**
     * @description  get field set name with help of record id & fieldset Name
     * @param   recordId : {String}
     * @param   fSet : {String}
     * @return  FieldObjWrapper
     */
    @AuraEnabled
    public static FieldObjWrapper getFields(String recordId,String fSet){
        List<String> fields = new List<String>();
        if (String.isBlank(recordId) || (fSet == null || String.isBlank(fSet))) {
            return null;
        }
        Id idRecord = CDdUtilities.returnValidId(recordId);
        if (idRecord == null) {
            return null;
        }

        Schema.DescribeSObjectResult describeSObjectResultObj = idRecord.getSObjectType().getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fSet);
        String objectApiName = describeSObjectResultObj.getName();

        if (fieldSetObj == null || fieldSetObj.getFields().isEmpty()){
            return null;
        }

        for(Schema.FieldSetMember objField : fieldSetObj.getFields()){
            fields.add(objField.getFieldPath());
        }
        if(!fields.isEmpty() && fields != null){
            FieldObjWrapper objwrap = new FieldObjWrapper();
            objwrap.strObject = objectApiName;
            objwrap.lstFields = fields;
            return objWrap;
        }
        return null;
    }

    public class FieldObjWrapper{
        @AuraEnabled
        public String strObject;
        @AuraEnabled
        public List<String>lstFields;
   }

}