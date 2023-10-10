/**
 * @author Mahesh Chouhan
 * @date   Oct 2021
 * @decription Controller for lwcDdGridReportQuickViewPanel to display record data
 */
public without sharing class CDdGridReportQuickViewPanelCtrl {

    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
     *****************************************************************************************************************************/
    private static final String STANDARD_ICON_NAME = 'standard:{0}';
    private static final String CUSTOM_ICON_NAME = 'custom:{0}';
    private static final String IMAGE_CONTENT_TYPE_SVG = 'image/svg+xml';
    private static final String CUSTOM_STRING_LITERAL = 'custom';
    private static final String SVG_STRING_LITERAL = 'svg';
    public static final String INVALID_FIELD_SET_NAME_ERROR = 'The fieldset name specified in quickViewFieldSetName key in Type Attributes JSON field in DD Grid Report Field does not exist';

    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author Mahesh Chouhan
     * @date   Oct 2021
     * @decription  Gets SObject Name, Label, Icon and Field Data
     * @param  Id recordId - Id of the record to display in Quick View Panel
     * @param  String fieldSetName - to get field names to display in Quick View Panel
     * @return  CDdGridReportQuickViewWrapper containing objectLabel, objectName and fields
     */
    @AuraEnabled(cacheable=true)
    public static CDdGridReportQuickViewWrapper getSObjectDetails(Id recordId, String fieldSetName) {
        String objectLabel;
        String objectName;
        List<String> fields;
        try {
            Schema.SObjectType objectType = recordId.getsobjecttype();
            objectLabel = objectType.getDescribe().getName();
            objectName = String.valueOf(objectType);
            fields = new List<String>();

            if(objectType.getDescribe().fieldSets.getMap().containsKey(fieldSetName)) {
                for(Schema.FieldSetMember field :objectType.getDescribe().fieldSets.getMap().get(fieldSetName).getFields()) {
                    fields.add(field.getFieldPath());
                }
            }
            else {
                throw new CDdGridReportQuickViewPanelCtrlException(INVALID_FIELD_SET_NAME_ERROR);
            }
        }
        catch(Exception ex){
            throw new AuraException(ex.getMessage());
        }
        return new CDdGridReportQuickViewWrapper(objectName, objectLabel, fields);
    }

    /**
     * CDdGridReportQuickViewWrapper 
     *
     * @author  Mahesh Chouhan
     * @date  15 July 2021
     * @decription Wrapper class containing objectLabel, objectName and fields
     * 
     */
    public class CDdGridReportQuickViewWrapper {
        @AuraEnabled
        public String objectName { get; set; }
        @AuraEnabled
        public String objectLabel { get; set; }
        @AuraEnabled
        public List<String> fields { get; set; }

        public CDdGridReportQuickViewWrapper(String objectName, String objectLabel, List<String> fields) {
            this.objectName = objectName;
            this.objectLabel = objectLabel;
            this.fields = fields;
        }
    }

    /**
     * @description A custom exception is thrown in the event something goes wrong
     */ 
    public class CDdGridReportQuickViewPanelCtrlException extends Exception { }
}