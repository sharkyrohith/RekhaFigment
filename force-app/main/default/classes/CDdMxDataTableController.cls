/********************************************************************************************************************
* @author Praveen
* @date 29/06/2022
*
* @group Merchant Services
*
* @description Dynamic table controller for Equipment request component. 
* 
**************************************************************************************************************************************/



public with sharing class CDdMxDataTableController {
    /**
* @Descriptoin Methods takes table name from parent equipment request component and returns the table columns from metadata and data from query.
* @param string tableName
* @return DataTableResponse
*/
    @AuraEnabled(cacheable=true)
    public static DataTableResponse GetTableColumnData(String tableName, String customFilterField, String customFilterValue)
    {
        try{
            List<DataTableColumns> lstDataColumns            = new List<DataTableColumns>();
            List<SObject> lstDataTableData                   = new List<SObject>();
            List<string> columnList                          = new List<string>();
            List<string> fieldAPINameList                    = new List<string>();
            
            DynamicDataTable__mdt TableComponentMetadata = [SELECT Id, DeveloperName, Field_Name__c, Header_Name__c, Query__c,Filter__c, Table_Title__c FROM DynamicDataTable__mdt WHERE DeveloperName =: TableName];
            
            if(TableComponentMetadata.Header_Name__c != null)
            {
                columnList = TableComponentMetadata.Header_Name__c.split(',');
            }
            
            if(TableComponentMetadata.Field_Name__c != null)
            {
                fieldAPINameList = TableComponentMetadata.Field_Name__c.split(',');
            }
            
            for(integer i = 0; i < columnList.size(); i++)
            {
                
                DataTableColumns datacolumns = new DataTableColumns( columnList[i].trim() , 
                                                                    fieldAPINameList[i].substringBefore(':').trim(), 
                                                                    fieldAPINameList[i].substringAfter(':').trim());
                
                lstDataColumns.add(datacolumns);
            }           
            string q= TableComponentMetadata.Query__c+' '+customFilterField+' = \'' +customFilterValue+ '\' and '+ TableComponentMetadata.Filter__c;
            for(SObject SObjectItem : Database.query(q))
            {
                lstDataTableData.add(SObjectItem);
            }
            
            DataTableResponse finalWrapper   = new DataTableResponse();
            finalWrapper.TableTitle          = TableComponentMetadata.Table_Title__c;
            finalWrapper.lstDataTableColumns = lstDataColumns;
            finalWrapper.lstDataTableData    = lstDataTableData;
            return finalWrapper;
        }catch(exception e){     
            throw new AuraHandledException('Error Occured while fetching data Message: '+e.getmessage() +'line: '+e.getLineNumber());
        }
    }
    
    public class DataTableColumns {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        
        public DataTableColumns(String label, String fieldName, String type)
        {
            this.label     = label;
            this.fieldName = fieldName;
            this.type      = type;          
        }
    }    
    public class DataTableResponse {
        @AuraEnabled
        public List<DataTableColumns> lstDataTableColumns {get;set;}
        @AuraEnabled
        public List<sObject> lstDataTableData {get;set;}
        @AuraEnabled
        public String TableTitle {get;set;}       
    }
    
    
}