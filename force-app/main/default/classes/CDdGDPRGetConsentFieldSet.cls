/**
 * @author Ravali Tummala
 * @date 2020-10
 *
 * @description Class : BIZS-377 used to mask the field values for Support agents
*/


public class CDdGDPRGetConsentFieldSet {

    private static final String MASK_VALUE = 'xxxxxx';
    private static final String EMAIL ='Email';
    private static final String PHONE ='Phone';
    private static final String REFERENCE ='Reference';

    private static final String NAME_REFERENCE_FIELD = 'Name';
    private static final String NAME_REFERENCE_FIELD_SOQL = '.Name';

    private static final Integer NUM_CHAR_TO_SHOW = 4;

    @AuraEnabled
    public static DataWrapper getData(String recordId,String fSet,String sectionName){
        if (String.isBlank(recordId) || (fSet == null || String.isBlank(fSet))) {
            return null;
        }
        Id idRecord = CDdUtilities.returnValidId(recordId);
        if (idRecord == null) {
            return null;
        }
        List<MaskDataWrapper> lstMaskData = new List<MaskDataWrapper>();

        Schema.DescribeSObjectResult describeSObjectResultObj = idRecord.getSObjectType().getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fSet);
        String objectApiName = describeSObjectResultObj.getName();

        List<String> lstFLD = new List<String>();
        if (fieldSetObj == null || fieldSetObj.getFields().isEmpty()){
            return null;
        }

        String strQuery = 'Select id';
        List<String> fields = new List<String>();
        for(Schema.FieldSetMember objField : fieldSetObj.getFields()){
            strQuery += ', ' + objField.getFieldPath();
            if (objField.type ==  Schema.DisplayType.REFERENCE){
                strQuery += ', ' + objField.getSObjectField().getDescribe().getReferenceTo()[0].getDescribe().getName() + NAME_REFERENCE_FIELD_SOQL;
            }
            fields.add(objField.getFieldPath());
        }
        strQuery += ' FROM ' + objectApiName +' Where Id = :recordId';
        Sobject objData = Database.query(strQuery);

        for(Schema.FieldSetMember objField : fieldSetObj.getFields()){
            MaskDataWrapper objMask = new MaskDataWrapper();
            String strType = String.valueOf(objField.getType());
            String strFieldName = objField.getFieldPath();
            String strFieldLabel = objField.getLabel();
            if (strType == REFERENCE){
                List<SObjectType> refObjs = objField.getSObjectField().getDescribe().getReferenceTo();
                if (!refObjs.isEmpty()){
                    String strObjName = refObjs[0].getDescribe().getName();
                    String strFldLabel = refObjs[0].getDescribe().getLabel() + ' ' +refObjs[0].getDescribe().fields.getMap().get(NAME_REFERENCE_FIELD).getDescribe().getLocalName();
                    strFieldName = refObjs[0].getDescribe().getName() + NAME_REFERENCE_FIELD_SOQL;
                    strFieldLabel = strFldLabel;
                }
            }
            String strFieldId = objField.getFieldPath();
            objMask.fieldType = strType;
            objMask.fieldLabel = strFieldLabel;
            objMask.actualValue = CDdUtilities.getFieldValAsString(objData,strFieldName,strType);
            objMask.referenceId =  CDdUtilities.getFieldValAsString(objData,strFieldId,strType);
            objMask.isHidden  = String.isNotBlank(objMask.actualValue);

            objMask.maskValue = CDdCoreConstants.BLANK_STRING;
            if (String.isNotBlank(objMask.actualValue)){
                if(strType == EMAIL || strType == REFERENCE){
                    objMask.maskValue = CDdUtilities.maskString(objMask.actualValue,NUM_CHAR_TO_SHOW,true);
                } else if (strType == PHONE){
                    objMask.maskValue = CDdUtilities.maskString(objMask.actualValue,NUM_CHAR_TO_SHOW,false);
                } else {
                    objMask.maskValue = MASK_VALUE;
                }
            }
            lstMaskData.add(objMask);
        }
        if(!fields.isEmpty() && fields != null){
            DataWrapper objwrap = new DataWrapper();
            objwrap.strObject = objectApiName;
            objwrap.lstFields = fields;
            objwrap.lstMaskData = lstMaskData;
            return objWrap;
        }
        return null;
    }

    public class DataWrapper{
        @AuraEnabled
        public String strObject;
        @AuraEnabled
        public List<String>lstFields;
        @AuraEnabled
        public List<MaskDataWrapper> lstMaskData;
   }

    public class MaskDataWrapper{
        @AuraEnabled
        public String fieldLabel;
        @AuraEnabled
        public String maskValue;
        @AuraEnabled
        public String actualValue;
        @AuraEnabled
        public String fieldType;
        @AuraEnabled
        public String referenceId;
        @AuraEnabled
        public Boolean isHidden;
    }
}