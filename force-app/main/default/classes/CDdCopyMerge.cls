/**************************************************************************************************************
 @ Purpose      : To copy data from duplicate record (source) to survivor (targeted record) 
 @ Created Date : 7 july 2021
 @ Author       : lalit
 **************************************************************************************************************/
public class CDdCopyMerge {

    /** 
     * @ purpose : Copy data from source object record to survivor object record  
     * @ params  : 1) survivorObjList (record to copy the data) 2) sobjectApiName
     * @ return  : -
     */
    public static void copySourceDataToSurvivor (List<SObject> survivorObjList, String copyInfoField, 
                                                 String fieldSetField, String sourceField) {

        Map<String, List<String>> fieldSetToFieldNamesMap;
        Map<Id, Sobject> sourceDataMap;
        string sobjectApiName;

        //input parameter validation
        if((survivorObjList == null || survivorObjList.isEmpty()) && String.isBlank(sobjectApiName)){
            return;
        }

        sobjectApiName = survivorObjList[0].Id.getSObjectType().getDescribe().getName();
        
        fieldSetToFieldNamesMap = getMergeSettingMap(sobjectApiName);
        sourceDataMap = getSourceDataMap(survivorObjList, sobjectApiName, fieldSetToFieldNamesMap, fieldSetField, sourceField);
        copyData(survivorObjList, sourceDataMap, fieldSetToFieldNamesMap, copyInfoField, fieldSetField, sourceField);

    }

    /** 
     * @ purpose : To create Map of field set name and list of field Name from merge setting custom metadata. 
     * @ params  : 1) sobjectApiName (string)
     * @ return  : fieldSetToFieldNamesMap (Map<String, List<String>>)
     */
    private static Map<String, List<String>> getMergeSettingMap (string sobjectApiName){

        Map<String, List<String>> fieldSetToFieldNamesMap = new Map<String, List<String>>();

        for(Sobject_Merge_Settings__mdt sobjMergeSettingRec :[SELECT Field_Name__c, Fieldset_Name__c
                                                              FROM Sobject_Merge_Settings__mdt
                                                              WHERE Is_Active__c = true AND 
                                                                    Sobject_Name__c =: sobjectApiName]){

            if(fieldSetToFieldNamesMap.containsKey(sobjMergeSettingRec.Fieldset_Name__c)){

                fieldSetToFieldNamesMap.get(sobjMergeSettingRec.Fieldset_Name__c).add(sobjMergeSettingRec.Field_Name__c);
                continue;

            }

            fieldSetToFieldNamesMap.put(sobjMergeSettingRec.Fieldset_Name__c, new List<String>{sobjMergeSettingRec.Field_Name__c});

        }

        return fieldSetToFieldNamesMap;

    }

    /** 
     * @ purpose : get source object data to copy   
     * @ params  : 1) survivorObjList (sobject target list) 2) sobjectName
     *             3)fieldSetToFieldNamesMap (Map<String, List<String>>)    
     * @ return  : SourceDataMap (map of source record Id to source record)
     */
    private static Map<Id, SObject> getSourceDataMap (List<SObject> survivorObjList, string sobjectApiName, 
                                                      Map<String, List<String>> fieldSetToFieldNamesMap, 
                                                      String fieldSetField, String sourceField) {

        Map<Id, Sobject> sourceRecordMap;
        Set<Id> sourceIdSet = new Set<Id>();
        Set<String> fieldNameSet = new Set<String>();

        for(SObject sobjectRec : survivorObjList){

            sourceIdSet.add((Id)sobjectRec.get(sourceField));

            String fieldSetName = String.valueOf(sobjectRec.get(fieldSetField));

            if(fieldSetToFieldNamesMap.containsKey(fieldSetName)){
                //create set of field name to create dynamic query string
                fieldNameSet.addAll(fieldSetToFieldNamesMap.get(fieldSetName));
            }
        }
        // create query string dynamically to fetch the source (sobject) data 
        string queryString = 'SELECT Id, ' + String.join(new List<String>(fieldNameSet), ',') + 
                             ' FROM ' + sobjectApiName + ' WHERE Id IN : sourceIdSet';

        sourceRecordMap = new Map<Id, SObject>(Database.query(queryString));

        return sourceRecordMap;
    }

    /** 
     * @ purpose : To copy the data from source to surviour using fieldset name 
     * @ params  : 1) survivorObjList (sobject target list) 2) SourceDataMap (map of source sobject records)
     *             3) fieldSetToFieldNamesMap (Map<String, List<String>>)  
     * @ return  : -
     */
    private static void copyData (List<SObject> survivorObjList, Map<Id, Sobject> sourceDataMap, 
                                  Map<String, List<String>> fieldSetToFieldNamesMap, String copyInfoField, 
                                  String fieldSetField, String sourceField) {

        Set<String> copyFieldNameSet = new Set<String>();

        for(SObject survivorRec :survivorObjList){

            //extract fieldset Name and source Id from sobject record
            String fieldSetName = (String)survivorRec.get(fieldSetField);
            String sourceId = (String)survivorRec.get(sourceField);

            if(sourceDataMap.containsKey(sourceId) && fieldSetToFieldNamesMap.containsKey(fieldSetName)){

                SObject sourceRecord = sourceDataMap.get(sourceId);

                for(String fieldName : fieldSetToFieldNamesMap.get(fieldSetName)){
                    survivorRec.put(fieldName, sourceRecord.get(fieldName));
                }

                //Reset all the value after data is copied to survivor
                survivorRec.put(copyInfoField, false);
                survivorRec.put(fieldSetField, null);
                survivorRec.put(sourceField, null);
 
            }
        }
    }
    
}