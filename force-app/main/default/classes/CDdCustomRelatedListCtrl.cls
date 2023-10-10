public with sharing class CDdCustomRelatedListCtrl {
    @AuraEnabled(cacheable=false)
    public static List<SObject> getAllRecords(Id recordId, String parentFieldName, String childObjectName, List<String> fields, String orderByField){
        //Get Custom Metadata with the object name and build query to get fields
        String query = 'SELECT Id, CurrencyIsoCode';
        //build dynamic inner query based on fields to display
        for(String field : fields){
            //Id already included in query
            if(field != 'Id' && field != 'CurrencyIsoCode'){
                query += ', ' + field;    
            }       
        }
        query += ' FROM ' + childObjectName + ' WHERE ' + parentFieldName + ' = \'' + recordId + '\'';
        if(!String.isBlank(orderByField)){
            query += ' ORDER BY ' + orderByField;
        }
        List<SObject> records = Database.query(query);
        return records;
	}

    @AuraEnabled
    public static List<Custom_Related_List_Fields__mdt> getFields(String childObject){
        List<Custom_Related_List_Fields__mdt> fieldsToDisplay = [
            SELECT MasterLabel, Display_Order__c, Field_Name__c, LWC_Data_Table_Type__c, URL_Display_Field__c, URL_Id__c, Decimal_Places__c, Show_Date_Time__c
            FROM Custom_Related_List_Fields__mdt 
            WHERE Object_Name__c =: childObject
            ORDER BY Display_Order__c ASC
        ];       
        if(!fieldsToDisplay.isEmpty()){
            SObjectType sObjType = ((SObject)Type.forName('Schema',childObject).newInstance()).getSObjectType();
            Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
            for(Custom_Related_List_Fields__mdt field : fieldsToDisplay){
                if(fieldMap.containsKey(field.Field_Name__c)){
                    field.MasterLabel = fieldMap.get(field.Field_Name__c).getDescribe().getLabel();
                }
            }
        } 
        return fieldsToDisplay;
    }

    @AuraEnabled(cacheable=false)
    public static String getPluralLabel(String childObjectName){
        String pluralLabel = '';
        
        //Get child object info based on the object name defined on the lightning record page
        SObjectType sObjType = ((SObject)Type.forName('Schema',childObjectName).newInstance()).getSObjectType();
        Schema.DescribeSObjectResult childObjType = sObjType.getDescribe();
        pluralLabel = childObjType.getLabelPlural();
        return pluralLabel;
    }
}