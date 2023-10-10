/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 11/03/2020
*
* @group SObject Required Fields Service
*
* @description A Service class that 
*   Interrogates the SObject record for specific fields based on the input 'field set'
*   Determines if any of the specific fields on the SObject record are blank, empty or null
*   Writes the corresponding result as a Boolean on the member variable 'sObjectResult'
*       Boolean 'true' denotes all the required fields on the SObject record are filled/populated with a value
*       Boolean 'false' denotes at least one required field is blank, empty or null on the SObject record
*
**************************************************************************************************************************************/
public class CDdSObjectRequiredFieldsService {
    /**
     * @description Member variable sObjectResult is defined here
     * This variable uses a key/value pair to track if all the required fields are filled/populated or not
     * for a specific SObject record identified by a unqiue key that represents the record.
     * An example of a Key could possibly be a
     * a) A Record Id
     * b) Or a composite key such as concatenated string of
     *      Name and 'Look Up identifier' of a parent or associated/relational record 
     **/    
    private Map<String, Boolean> sObjectResult = new Map<String, Boolean>();
    private Map<String, Set<String>> sObjectRequiredFieldsPassed = new Map<String, Set<String>>();
    private Map<String, Set<String>> sObjectRequiredFieldsFailed = new Map<String, Set<String>>();
    /**
     * @description default constructor
     * @param sObjectType - a String value of the SObject Type. Example Account, Lead or Opportunity
     * @param fieldSetOfRequiredFieldsForSObject - a Map Collection where
     * Key is the Field Set Name
     * Value is a Collection of SObject records that will be interrogated for 
     *  'Required field' i.e filled (or populated) or not, 
     *      on specific fields that belong to the input Field Set (the key of the Collection fieldSetOfRequiredFieldsForSObject)
     * Note : The inner Collection of fieldSetOfRequiredFieldsForSObject is represented by a Key
     * Inner Collection Key (that represents the SObject record) could possibly be a
     * a) A Record Id
     * b) Or a composite key such as concatenated string of
     *      Name and 'Look Up identifier' of a parent or associated/relational record
     **/    
    public CDdSObjectRequiredFieldsService(String sObjectType, Map<String, Map<String, SObject>> fieldSetOfRequiredFieldsForSObject) {
        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new String[]{sObjectType});
        Map<String, Schema.SObjectField> sObjectFieldMap = descResult[0].fields.getMap();
        Map<String, Schema.FieldSet> fieldSetMap = descResult[0].fieldSets.getMap();
        for (String fieldSetName : fieldSetOfRequiredFieldsForSObject.keySet()){
            Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
            for (String sObjKey : fieldSetOfRequiredFieldsForSObject.get(fieldSetName).keySet()){
                SObject record = fieldSetOfRequiredFieldsForSObject.get(fieldSetName).get(sObjKey);
                Set<String> requiredFieldsPassed = new Set<String>();
                Set<String> requiredFieldsFailed = new Set<String>();
                for (Schema.FieldSetMember fieldSetMember : fieldSet.getFields()) {
                    String fieldApiName = fieldSetMember.getFieldPath();
                    Boolean isFieldPopulated = true;
                    Schema.DisplayType fieldDisplayType = fieldSetMember.getType();
                    switch on fieldDisplayType {
                        when String, ID, Picklist, Reference, Email, TextArea, EncryptedString {
                            isFieldPopulated = String.isNotBlank((String)record.get(fieldApiName));
                        }
                        when else {
                            isFieldPopulated = (record.get(fieldApiName)!=null);
                        }
                    }
                    if (isFieldPopulated){
                        requiredFieldsPassed.add(fieldApiName);
                    } else {
                        requiredFieldsFailed.add(fieldApiName);
                    }
                }
                this.sObjectResult.put(sObjKey, requiredFieldsFailed.isEmpty());
                this.sObjectRequiredFieldsPassed.put(sObjKey, requiredFieldsPassed);
                this.sObjectRequiredFieldsFailed.put(sObjKey, requiredFieldsFailed);
            }
        }       
    }
    public Map<String, Boolean> getSObjectResult(){
        return this.sObjectResult;
    }
    public Map<String, Set<String>> getSObjectRequiredFieldsPassed(){
        return this.sObjectRequiredFieldsPassed;
    }
    public Map<String, Set<String>> getSObjectRequiredFieldsFailed(){
        return this.sObjectRequiredFieldsFailed;
    }        
}