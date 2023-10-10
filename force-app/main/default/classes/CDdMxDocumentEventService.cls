/**
* @author: Critical River
* @date: 2023-05
* @description Service class for Mx_Document_Event__c object.
*/
public class CDdMxDocumentEventService {

    public static final String CASE_OBJECT = 'Case';
    public static final String CONTENT_VERSION_OBJECT = 'ContentVersion';
    public static final String ACCOUNT_OBJECT = 'Account';
    public static final String CASE_STATUS_CLOSED = 'Closed';
    public static final String CASE_STATUS_DEAD = 'Dead';
    public static final String CATEGORY = 'SSMO Fraud';
    public static final String EVENT_TYPE = 'DOCUMENT_UPLOADED';
    public static final String STATUS_FAILED = 'Failed';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_INVALID = 'Invalid';
    public static final String ERROR_MESSAGE = 'System Failure while sending document events - {0}';
    public static final String STORE_NOT_EXIST = 'Store doesn\'t exist with given Store Id.';
    public static final String CASE_NOT_EXIST = 'Marketplace Onboarding Case doesn\'t exist with given Store Id.';
    public static final Id mpRTId;
    public static final Map<String, String> HEADERS = new Map<String, String>();
    public static String URL_PREFIX;
    public static Boolean IS_SANDBOX;
    public Enum TYPE {Named_Credential, Header}

    static{
        mpRTId = Schema.SObjectType.Case.getRecordTypeInfosByName()
                               .get('Marketplace Onboarding').getRecordTypeId();
    }
    public static void getAPIURLHeaders(List<String> type){
        for (Organization o : [SELECT Id, IsSandbox FROM Organization WHERE Id = :UserInfo.getOrganizationId()]){
            IS_SANDBOX = o.IsSandbox;
        }
        for (SSMO_Mulesoft_API__mdt api : [SELECT Id, MasterLabel, DeveloperName, Is_Sandbox__c,
                                                Name__c, Type__c, Value__c, Active__c,Category__c
                                                FROM SSMO_Mulesoft_API__mdt
                                                Where Active__c = true
                                                AND Is_Sandbox__c = :IS_SANDBOX
                                                AND Category__c = :CATEGORY
                                                AND Type__c IN :type
                                                ORDER BY Type__c ASC]){
            switch on getType(api.Type__c) {
                when Named_Credential {
                    URL_PREFIX = 'callout:' + api.Value__c;
                }
                when Header {
                    HEADERS.put(api.Name__c, api.Value__c);
                }
            }
        }
    }

    /**
    * @description Return the Enum Type for the input type String value
    **/
    private static TYPE getType(String typeName){
        for (TYPE typeEnum : TYPE.values()){
            if (typeName.equals(typeEnum.name())){
                return typeEnum;
            }
        }
        return null;
    }
    /**
    * @description Set the HttpRequest headers
    **/
    private static void setRequestHeaders(HttpRequest req){
        for (String name : HEADERS.keySet()){
            req.setHeader(name, HEADERS.get(name));
        }
    }

    public static List<SSMO_Fraud_Field_Mapping__mdt> fetchSSMOFraudAPIFields(){
        List<SSMO_Fraud_Field_Mapping__mdt> ssmoFraudFields = [SELECT Id,MasterLabel,DeveloperName, Field_Name__c , Object_Name__c, Data_Type__c ,API_Property__c, JSON_Object__c,Add_to_Request__c
                                                                        FROM SSMO_Fraud_Field_Mapping__mdt ORDER BY Object_Name__c Limit 100];
        return ssmoFraudFields;
    }

    public static void sendMxDocumentEvents(Set<String> storeIdSet,List<Mx_Document_Event__c> mxDocumentList){
        List<String> contentVersionIdList = new List<String>();
        Map<String,Case> storeIdCaseMap = new Map<String,Case>();
        Map<String,Account> storeIdAccountMap = new Map<String,Account>();
        Map<String,List<ContentVersion>> storeIdContentVersionMap = new Map<String,List<ContentVersion>>();
        Map<Id,Id> conVerDocEventMap = new Map<Id,Id>();

        List<SSMO_Fraud_Field_Mapping__mdt> ssmoFraudFieldsMapping = fetchSSMOFraudAPIFields();
        getAPIURLHeaders(new List<String>{Type.Named_Credential.name(),Type.Header.name()});

        List<String> listOfIds  = new List<String>();
        String accountQuery = prepareQuery(listOfIds,ssmoFraudFieldsMapping,ACCOUNT_OBJECT,null);
        String caseQuery = prepareQuery(listOfIds,ssmoFraudFieldsMapping,CASE_OBJECT,mpRTId);
        String contentVersionQuery = prepareQuery(listOfIds,ssmoFraudFieldsMapping,CONTENT_VERSION_OBJECT,null);

        listOfIds.addAll(storeIdSet);
        List<Case> caseList = Database.query(caseQuery);
        List<Account> accountList = Database.query(accountQuery);

        listOfIds.clear();
        for(Mx_Document_Event__c mxDocEvent : mxDocumentList){
            contentVersionIdList.add(mxDocEvent.SObject_Id__c);
            conVerDocEventMap.put(mxDocEvent.SObject_Id__c,mxDocEvent.Id);
        }
        listOfIds.addAll(contentVersionIdList);
        List<ContentVersion> contentVersionList = Database.query(contentVersionQuery);

        for(Account account : accountList){
            storeIdAccountMap.put(account.Restaurant_ID__c,account);
        }

        for(Case storeCase : caseList){
            storeIdCaseMap.put(storeCase.Account.Restaurant_ID__c,storeCase);
        }

        for(ContentVersion mxContVersion : contentVersionList){
            if(!storeIdContentVersionMap.containsKey(mxContVersion.Mx_Store_Id__c)){
                storeIdContentVersionMap.put(mxContVersion.Mx_Store_Id__c,new List<ContentVersion>());
            }
            storeIdContentVersionMap.get(mxContVersion.Mx_Store_Id__c).add(mxContVersion);
        }

        List<Mx_Document_Event__c> mxDocumentsToBeUpdated = new List<Mx_Document_Event__c>();
        for(String storeId : storeIdSet){
            Map<String,String> resultMap = sendMxDocumentEvents(storeIdAccountMap.get(storeId),
                                                                storeIdCaseMap.get(storeId),
                                                                storeIdContentVersionMap.get(storeId),
                                                                ssmoFraudFieldsMapping);
            for(ContentVersion contVer:storeIdContentVersionMap.get(storeId)){
                Mx_Document_Event__c docEvent = new Mx_Document_Event__c(Id=conVerDocEventMap.get(contVer.Id));
                if(resultMap.containsKey(STATUS_INVALID)){
                    docEvent.Status__c  = STATUS_INVALID;
                    docEvent.Error_Message__c = String.format(ERROR_MESSAGE, new List<String>{resultMap.get(STATUS_INVALID)});

                }else if(resultMap.get('status') == 'success'){
                    docEvent.Status__c  = STATUS_COMPLETED;
                    docEvent.Error_Message__c = '';
                }else{
                    docEvent.Status__c  = STATUS_FAILED;
                    docEvent.Error_Message__c = String.format(ERROR_MESSAGE, new List<String>{resultMap.get('status')});
                }
                mxDocumentsToBeUpdated.add(docEvent);
            }
       }

       Database.SaveResult[] updateResults = Database.update(mxDocumentsToBeUpdated,false);
    }

    public static Map<String,String> sendMxDocumentEvents(Account accountRecord,
                                                          Case caseRecord,
                                                          List<ContentVersion> storeContentVersionList,
                                                          List<SSMO_Fraud_Field_Mapping__mdt> ssmoFraudFieldsMapping){
        Map<String, String> result = new Map<String, String>();
        CDdRestJSONObj.RestAPIResponse apiResponse = null;
        try{
            if(accountRecord == null){
                result.put(STATUS_INVALID,STORE_NOT_EXIST);
                return result;
            }
            if(caseRecord == null){
                result.put(STATUS_INVALID,CASE_NOT_EXIST);
                return result;
            }
            String requestBody = prepareRequestJSON(accountRecord,caseRecord,storeContentVersionList,ssmoFraudFieldsMapping);
            apiResponse = sendRequest(requestBody);
            if(apiResponse.statusCode == 200){
                result.put('status','success');
            }else{
                result.put('status',String.valueOf(apiResponse.statusCode));
            }
        }catch(Exception ex){
            String message = ex.getMessage() + ' '+ex.getLineNumber()+' '+ex.getCause();
            if(apiResponse != null){
                message = apiResponse.statusCode + ' '+apiResponse.status + ' '+ message;
            }
            result.put('status',message);
        }

        return result;
    }

    public static CDdRestJSONObj.RestAPIResponse sendRequest(String requestBody) {
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        req.setEndpoint(URL_PREFIX);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setTimeout(120000);
        req.setBody(requestBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        CDdRestJSONObj.RestAPIResponse restApiResponse = new CDdRestJSONObj.RestAPIResponse();
        restApiResponse.body = res.getBody();
        restApiResponse.statusCode = res.getStatusCode();
        restApiResponse.status = res.getStatus();
        return restApiResponse;
    }

    public static String prepareRequestJSON(Account accountRecord,
                                            Case caseRecord,
                                            List<ContentVersion> mxContentVersionList,
                                            List<SSMO_Fraud_Field_Mapping__mdt> ssmoFraudFieldsMapping){

        JSONGenerator reqGenerator = JSON.createGenerator(true);
        reqGenerator.writeStartObject();

        for(SSMO_Fraud_Field_Mapping__mdt fieldMapping : ssmoFraudFieldsMapping){
            if(fieldMapping.Object_Name__c == CASE_OBJECT && fieldMapping.Add_to_Request__c){
                Object fieldValue = caseRecord.get(fieldMapping.Field_Name__c);
                createJSONProperty(reqGenerator,fieldMapping,fieldValue);
            }else if(fieldMapping.Object_Name__c == ACCOUNT_OBJECT && fieldMapping.Add_to_Request__c){
                Object fieldValue = accountRecord.get(fieldMapping.Field_Name__c);
                createJSONProperty(reqGenerator,fieldMapping,fieldValue);
            }
        }

        reqGenerator.writeFieldName('Documents');
        reqGenerator.writeStartArray();
      for(ContentVersion  mxContentVersion : mxContentVersionList){
            reqGenerator.writeStartObject();
          for(SSMO_Fraud_Field_Mapping__mdt fieldMapping : ssmoFraudFieldsMapping){
                if(fieldMapping.Object_Name__c == CONTENT_VERSION_OBJECT && fieldMapping.Add_to_Request__c){
                    Object fieldValue = mxContentVersion.get(fieldMapping.Field_Name__c);
                    createJSONProperty(reqGenerator,fieldMapping,fieldValue);
                }
            }
            reqGenerator.writeEndObject();
        }
      reqGenerator.writeEndArray();

        reqGenerator.writeEndObject();
        String requestJSON = reqGenerator.getAsString();
        return requestJSON;
    }

    private static void createJSONProperty(JSONGenerator reqGenerator,SSMO_Fraud_Field_Mapping__mdt fieldMapping,Object fieldValue){
        if(fieldMapping.Data_Type__c == 'Text'){
            reqGenerator.writeStringField(fieldMapping.API_Property__c, fieldValue != null?String.valueOf(fieldValue):'');
        }else if(fieldMapping.Data_Type__c == 'Boolean'){
            reqGenerator.writeBooleanField(fieldMapping.API_Property__c, fieldValue != null?Boolean.valueOf(fieldValue):false);
        }if(fieldMapping.Data_Type__c == 'Date' || fieldMapping.Data_Type__c == 'DateTime'){
            if(fieldValue != null){
                DateTime dateField;
                if(fieldMapping.Data_Type__c == 'Date'){
                    Date dateVal = (Date) fieldValue;
                    dateField = DateTime.newInstance(dateVal.year(), dateVal.month(), dateVal.day());
                }else{
                    dateField = (DateTime) fieldValue;
                }
                reqGenerator.writeStringField(fieldMapping.API_Property__c, dateField.format('yyyy-MM-dd\'T\'hh:mm:ss\'.000z\''));
            }else{
                reqGenerator.writeStringField(fieldMapping.API_Property__c, '');
            }
        }
    }

    public static String prepareQuery(List<String> listOfIds,List<SSMO_Fraud_Field_Mapping__mdt> ssmoFraudAPIFields,String objectName,Id recordTYpeId){
        String queryString = 'SELECT {0} FROM {1} WHERE ID IN {2}';
        if(objectName == CASE_OBJECT){
            queryString = 'SELECT {0} FROM {1} WHERE  STATUS != :CASE_STATUS_CLOSED AND STATUS != :CASE_STATUS_DEAD AND RecordTypeId = {2} AND '+
                      ' AccountId IN (SELECT Id FROM Account WHERE Restaurant_ID__c IN {3})';
        }else if(objectName == ACCOUNT_OBJECT){
            queryString = 'SELECT {0} FROM {1} WHERE Restaurant_ID__c IN {2}';
        }
        String fields = 'Id';
        List<String> fieldAPINames = getFieldNames(objectName,ssmoFraudAPIFields);
        for(String field: fieldAPINames){
          if(field == 'Id'){
            continue;
          }

          fields += ', '+field;
        }

        if(objectName == CASE_OBJECT){
            queryString = String.format(queryString, new List<String>{fields, objectName, '\''+recordTYpeId+'\'',':listOfIds'});
        }else{
          queryString = String.format(queryString, new List<String>{fields, objectName, ':listOfIds'});
        }

        return queryString;
    }

    private static List<String> getFieldNames(String objectName,List<SSMO_Fraud_Field_Mapping__mdt> ssmoFraudAPIFields){
        List<String> fieldAPINames = new List<String>();
        for(SSMO_Fraud_Field_Mapping__mdt fieldMapping:ssmoFraudAPIFields){
            if(objectName == fieldMapping.Object_Name__c && !fieldAPINames.contains(fieldMapping.Field_Name__c)){
                fieldAPINames.add(fieldMapping.Field_Name__c);
            }
        }
        return fieldAPINames;
    }

    public static void insertMxDocumentUploadEvents(List<ContentVersion> mxContentVersionList){
        List<Mx_Document_Event__c> mxDocumentEventInsertList = new List<Mx_Document_Event__c>();
        for(ContentVersion newContentVersion : mxContentVersionList){
            Mx_Document_Event__c mxDocumentEvent = new Mx_Document_Event__c();
            mxDocumentEvent.Event_Type__c = EVENT_TYPE;
            mxDocumentEvent.SObject_Id__c = newContentVersion.Id;
            mxDocumentEvent.SObject_Type__c = CONTENT_VERSION_OBJECT;
            mxDocumentEvent.Status__c = 'New';
            mxDocumentEvent.Store_Id__c = newContentVersion.Mx_Store_Id__c;

            mxDocumentEventInsertList.add(mxDocumentEvent);
        }

        Database.SaveResult[] insertResults = Database.insert(mxDocumentEventInsertList,false);
    }

}