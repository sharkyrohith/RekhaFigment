/**
 * CDdBulkCaseProcessor
 *
 * @author     Sahil (sahil.chaudhry@doordash.com)
 * @date       2022-05-17
 * @decription controller for the client to process incoming CSV and upload data to staging object
 */
public with sharing class CDdBulkCaseProcessor {
    /*****************************************************************************************************************************
    *
    * Constants
    *
    *****************************************************************************************************************************/
    public static Support_Settings__c SUPPORT_SETTINGS = Support_Settings__c.getInstance() == null ? 
                                                                new Support_Settings__c() : Support_Settings__c.getInstance();
    public static Integer LRI_BATCH_SIZE = Integer.valueOf(SUPPORT_SETTINGS.Load_Req_Item_Batch_Size__c != null ? 
                                                                SUPPORT_SETTINGS.Load_Req_Item_Batch_Size__c : 200);
    public static Integer CSV_COL_SIZE = Integer.valueOf(SUPPORT_SETTINGS.Valid_CSV_Columns__c != null ? 
                                                                SUPPORT_SETTINGS.Valid_CSV_Columns__c : 5);
   /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        2022-05-17
     * @decription  method called by client component to pass context about the file uploaded
     * @param       contentDocId, checkbox to send email, case close reason
     * @return      response from salesforce
    */
    @AuraEnabled(cacheable=true)
    public static String processCases(Id contentDocId, Boolean sendEmail, String emailBody, String caseStatus) 
    {
        List<Load_Request_Item__c> lriToInsertAddAll = new List<Load_Request_Item__c>(); 

        try  
        {
            // Step 1: Query CSV file to process
            List<ContentVersion> csvFile = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId =: contentDocId];
            if (csvFile.isEmpty()) {
                throw new CDdBulkCaseProcessorException('No Document to Process');
            } 

            // Step 2: Split the CSV File
            List<String> lstCSVLines = parseAndSplitFile(csvFile[0]);
            if (lstCSVLines.size() < 2) {
                throw new CDdBulkCaseProcessorException('No data to process in the CSV');
            }
            
            // Step 3: Validate each row for blanks. otherwise do not process entire CSV
            List<String> csvRowData = new List<String>();
            for (Integer i = 1; i < lstCSVLines.size(); i++) {
                csvRowData = CDdCsvReader.parseCSVRow(lstCSVLines[i]);
                if (csvRowData.isEmpty()) {
                    throw new CDdBulkCaseProcessorException('Cannot split CSV row');
                }
                //get 1st row size
                Integer validRowSize = lstCSVLines[0].split(CDdCoreConstants.DELIMITER_COMMA).size();
                validateRow(csvRowData,validRowSize); // will throw exception if any value is blank
            }

            // Step 4: CSV is valid. Now start processing it. Covert CSV Rows to sObject records
            lriToInsertAddAll = insertCsvData(lstCSVLines, sendEmail, emailBody, caseStatus);
            if (lriToInsertAddAll.isEmpty()) {
                throw new CDdBulkCaseProcessorException('No records inserted to staging table');
            }

            // Step 5: Upsert staging records using queueable
            Schema.SObjectField uuidField = Load_Request_Item__c.Fields.UUID__c;
            system.debug(lriToInsertAddAll.size());
            CDdUtilities.sobjectDMLQueueable dmlQueueInstance = new CDdUtilities.sobjectDMLQueueable('CDdBulkCaseProcessor', lriToInsertAddAll, uuidField,
                                                                    CDdUtilities.DML_UPSERT,LRI_BATCH_SIZE,CDdUtilities.START_INDEX_0);
            Id JobId = System.enqueueJob(dmlQueueInstance);
            return 'Records submitted for processing';
        } 
        catch (Exception e) {
            throw new CDdBulkCaseProcessorException(e.getMessage());
        } 
        finally {
            // Step 6: delete the uploaded document async
            deleteContentDoc(contentDocId);
        }
    }

    /**
     * @author      Sid Agarwal
     * @date        2022-06-28
     * @decription  Split CSV file by new lines
     * @param       CSV File
     * @return      CSV rows as Strings
    */
    private static List<String> parseAndSplitFile(ContentVersion csvFile)
    {
        List<String> allRows = new List<String>();
        utilityRowIterator rowIterator = new utilityRowIterator(csvFile.VersionData.toString(), '\n');
        while (rowIterator.hasNext()) 
        {
            String currentRow = rowIterator.next();
            allRows.add(currentRow);
        }
        return allRows;
    }

     /**
     * @author      Sid Agarwal
     * @date        2022-06-28
     * @decription  COnvert CSV Rows to Iterator
     * @param       CSV Rows
     * @return      CSV rows iterator
    */
    private with sharing class utilityRowIterator implements Iterator<String>, Iterable<String>
    {
        private String m_Data;
        private Integer m_index = 0;
        private String m_rowDelimiter = '\n';
            
        public utilityRowIterator(String fileData)
        {
            m_Data = fileData; 
        }
        public utilityRowIterator(String fileData, String rowDelimiter)
        {
            m_Data = fileData; 
            m_rowDelimiter = rowDelimiter;
        }
        public Boolean hasNext()
        {
            return m_index < m_Data.length() ? true : false;
        }
        public String next()
        {     
            Integer key = m_Data.indexOf(m_rowDelimiter, m_index);
            
            if (key == -1){
                key = m_Data.length();
            }
                    
            String row = m_Data.subString(m_index, key);
            m_index = key + 1;
            return row;
        }
        public Iterator<String> Iterator()
        {
            return this;   
        }
    }

     /**
     * @author      Sahil Chaudhry
     * @date        2022-05-17
     * @decription  build data from csv rows to upsert
     * @param       row data, content doc id, send email?, email body
     * @return      list of staging object records
    */
    private static List<Load_Request_Item__c> insertCsvData(List<String> lstCSVLines, Boolean sendEmail,
                                                             String emailBody, String caseStatus) {
        List<Load_Request_Item__c> lriToInsert = new List<Load_Request_Item__c>();
        Set<String> uUIds = new Set<String>();
        Set<String> erroruUIds = new Set<String>();
        try 
        {
            for(String row : lstCSVLines) {
                List<String> csvRowData = row.split(',');
                if(!csvRowData.isEmpty() && csvRowData[0] instanceof Id)
                {
                    uUIds.add(csvRowData[0]);
                }
            }

            List<Load_Request_Item__c> errorLRI = [SELECT UUID__c
                                                   FROM Load_Request_Item__c
                                                   WHERE UUID__c IN :uUIds AND Status__c = :CDdSupportConstants.ERROR_LABEL];
            for(Load_Request_Item__c lRI : errorLRI) {
                erroruUIds.add(lRI.UUID__c);
            }

            for(String row : lstCSVLines)
            {
                list<String> csvRowData = CDdCsvReader.parseCSVRow(row);

                Load_Request_Item__c lriObj = new Load_Request_Item__c();
                if(!csvRowData.isEmpty() && csvRowData[0] instanceof Id)
                {
                    lriObj.Operation__c = CDdSupportConstants.OPERATION_CASE_UPDATES;
                    lriObj.UUID__c = csvRowData[0]; //case Id is the first column as per the format
                    lriObj.Issue_Type__c = csvRowData[1];
                    lriObj.Issue__c = csvRowData[2];
                    lriObj.Resolution_Category__c = csvRowData[3];
                    lriObj.Resolution__c = csvRowData[4];
                    lriObj.Payload__c = row;
                    lriObj.Email_Body__c = emailBody;
                    lriObj.Send_Email__c = sendEmail;
                    lriObj.Case_Status__c = caseStatus;
                    if(erroruUIds.contains(csvRowData[0])){
                        lriObj.Status__c = CDdSupportConstants.NEW_STATUS;
                        lriObj.Error__c = false;
                        lriObj.Exception_Details__c = CDdCoreConstants.BLANK_STRING;
                    }
                    lriToInsert.add(lriObj);
                }
            }
            return lriToInsert;
        } 
        catch (Exception e) {
            throw new CDdBulkCaseProcessorException(e.getMessage());
        }
    }

    /**
     * @author      Sahil Chaudhry
     * @date        2022-05-17
     * @decription  validate csv row
     * @param       contentDocId
     * @return      N/A
    */
    private static void validateRow(List<String> csvRowData,Integer validRowSize) {
        if (csvRowData.size() != validRowSize || csvRowData.size() != CSV_COL_SIZE) {
            throw new CDdBulkCaseProcessorException('Row with Id '+csvRowData[0]+' is Invalid');
        }
    }

    /**
     * @author      Sahil Chaudhry
     * @date        2022-05-17
     * @decription  delete the uploaded CSV as it's already been parsed
     * @param       contentDocId
     * @return      N/A
    */
    @future
    private static void deleteContentDoc(Id contentDocId) {
        try {
            if (contentDocId != null) {
                delete [SELECT Id FROM ContentDocument WHERE Id =: contentDocId];
            }
        } catch (Exception e) {
            throw new CDdBulkCaseProcessorException(e.getMessage());
        }
    }

    public class CDdBulkCaseProcessorException extends Exception{}
}