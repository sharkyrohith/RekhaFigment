/*
*@Description: Class to prepare SSMO Quote API request and invoke the API
@Author : Venkat D
@Date : 2022-06
*/
public class CDdSSMOQuoteHelper {

    public static final String OPPORTUNITY_OBJECT = 'Opportunity';
    public static final String ACCOUNT_OBJECT = 'Account';
    public static final String CONTACT_OBJECT = 'Contact';
    public static final String USER_OBJECT = 'User';
    public static final String QUOTE_OBJECT = 'SBQQ__Quote__c';
    public static final String QUOTELINE_OBJECT = 'SBQQ__QuoteLine__c';
    public static final Map<String, String> HEADERS = new Map<String, String>();
    public static String URL_PREFIX;
    public static Boolean IS_SANDBOX;
    public static final String CATEGORY = 'SSMO Quote';
    public Enum TYPE {Named_Credential, Header,Named_Credential_Recall}
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
                when Named_Credential,Named_Credential_Recall {
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

    public static List<SSMO_Quote_Field_Mapping__mdt> fetchSSMOQuoteAPIFields(){
        List<SSMO_Quote_Field_Mapping__mdt> ssmoQuoteRequiredFields = [SELECT Id,MasterLabel,DeveloperName, Field_Name__c , Object_Name__c, Data_Type__c ,API_Property__c,Is_Required__c, JSON_Object__c,Add_to_Request__c  
                                                                       	FROM SSMO_Quote_Field_Mapping__mdt ORDER BY Object_Name__c Limit 100];
        return ssmoQuoteRequiredFields;
    }
    
    public static Map<String,Object> sendQuote(Id quoteId, Id opportunityId){
        Map<String, Object> result = new Map<String, Object>();
        CDdRestJSONObj.RestAPIResponse apiResponse = null;
        getAPIURLHeaders(new List<String>{Type.Named_Credential.name(),Type.Header.name()});
        try{
            String requestBody = prepareRequestJSON(quoteId,opportunityId);
            apiResponse = sendRequest(requestBody);
            if(apiResponse.statusCode == 200){
                result = (Map<String, Object>) JSON.deserializeUntyped(apiResponse.body);
                result.put('status','success');
            }else{
                result.put('status','failed');
                Map<String, Object> jsonResult = (Map<String, Object>)JSON.deserializeUntyped(apiResponse.body);
                if(jsonResult.get('error_message') != null){
                    result.put('message',(String) jsonResult.get('error_message'));
                }else{
                    result.put('message',apiResponse.statusCode + ' '+apiResponse.status);
                }    
                insert new Apex_Log__c(Class_Name__c = 'CDdSSMOQuoteHelper', Method_Name__c = 'sendQuote',Log__c = apiResponse.statusCode + apiResponse.status + requestBody, Log_Level__c = 'Error');
            }
        }catch(Exception ex){
            String message = ex.getMessage() + ' '+ex.getLineNumber()+' '+ex.getCause();
            if(apiResponse != null){
                message = apiResponse.statusCode + ' '+apiResponse.status + ' '+ message;
            }
            insert new Apex_Log__c(Class_Name__c = 'CDdSSMOQuoteHelper', Method_Name__c = 'sendQuote',Log__c = message, Log_Level__c = 'Error');
            result.put('status','failed');
            result.put('message',message);
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

    public static String prepareRequestJSON(Id quoteId, Id opportunityId){
        
        List<SSMO_Quote_Field_Mapping__mdt> ssmoQuoteAPIFields = fetchSSMOQuoteAPIFields();
        
        Account acctRecord = null;
        Contact decisionMakerRecord = null;
        User ownerRecord = null;

        String opptyQuery = prepareQuery(opportunityId,ssmoQuoteAPIFields,OPPORTUNITY_OBJECT);
        sObject[] sobjectList = Database.query(opptyQuery);
        Opportunity oppRecord = sobjectList.size() > 0 ? (Opportunity)sobjectList[0]:null;
        
        if(oppRecord != null){
            String accountQuery = prepareQuery(oppRecord.AccountId,ssmoQuoteAPIFields,ACCOUNT_OBJECT);
            sobjectList = Database.query(accountQuery);
            acctRecord = sobjectList.size() > 0 ? (Account)sobjectList[0]:null;
            
            String contactQuery = prepareQuery(oppRecord.Decision_Maker__c,ssmoQuoteAPIFields,CONTACT_OBJECT);
            sobjectList = Database.query(contactQuery);
            decisionMakerRecord = sobjectList.size() > 0 ? (Contact)sobjectList[0]:null;
            
            String userQuery = prepareQuery(oppRecord.OwnerId,ssmoQuoteAPIFields,USER_OBJECT);
            sobjectList = Database.query(userQuery);
            ownerRecord = sobjectList.size() > 0 ? (User)sobjectList[0]:null;
        }
        
        String quoteQuery = prepareQuery(quoteId,ssmoQuoteAPIFields,QUOTE_OBJECT);
        sobjectList = Database.query(quoteQuery);
        SBQQ__Quote__c quoteRecord = sobjectList.size() > 0 ? (SBQQ__Quote__c)sobjectList[0]:null;
        
        String quoteLineItemsQuery = prepareQuery(quoteId,ssmoQuoteAPIFields,QUOTELINE_OBJECT);
        sobjectList = Database.query(quoteLineItemsQuery);
        List<SBQQ__QuoteLine__c> quoteLineItems = new List<SBQQ__QuoteLine__c>();
        for(sObject qouteLineItem:sobjectList){
            quoteLineItems.add((SBQQ__QuoteLine__c)qouteLineItem);
        }
        
        JSONGenerator reqGenerator = JSON.createGenerator(true);
        reqGenerator.writeStartObject();
        
        reqGenerator.writeFieldName(OPPORTUNITY_OBJECT);
        reqGenerator.writeStartObject();
        for(SSMO_Quote_Field_Mapping__mdt fieldMapping : ssmoQuoteAPIFields){
        	if(fieldMapping.JSON_Object__c == OPPORTUNITY_OBJECT && fieldMapping.Add_to_Request__c){
                Object fieldValue = null;
                if(fieldMapping.Object_Name__c == OPPORTUNITY_OBJECT && oppRecord != null){
                    fieldValue = oppRecord.get(fieldMapping.Field_Name__c); 
                }else if(fieldMapping.Object_Name__c == ACCOUNT_OBJECT && acctRecord != null){
                    fieldValue = acctRecord.get(fieldMapping.Field_Name__c);
                }else if(fieldMapping.Object_Name__c == CONTACT_OBJECT && decisionMakerRecord != null){
                    fieldValue = decisionMakerRecord.get(fieldMapping.Field_Name__c);
                }else if(fieldMapping.Object_Name__c == USER_OBJECT && ownerRecord != null){
                    fieldValue = ownerRecord.get(fieldMapping.Field_Name__c);
                }
                createJSONProperty(reqGenerator,fieldMapping,fieldValue);
           	}
        }
        reqGenerator.writeEndObject();
        
        reqGenerator.writeFieldName(ACCOUNT_OBJECT);
        reqGenerator.writeStartObject();
        for(SSMO_Quote_Field_Mapping__mdt fieldMapping : ssmoQuoteAPIFields){
            if(fieldMapping.JSON_Object__c == ACCOUNT_OBJECT && fieldMapping.Add_to_Request__c){
                Object fieldValue = null;
                if(fieldMapping.Object_Name__c == ACCOUNT_OBJECT && acctRecord != null){
                    fieldValue = acctRecord.get(fieldMapping.Field_Name__c);
                }
                createJSONProperty(reqGenerator,fieldMapping,fieldValue);
            }
        }
        reqGenerator.writeEndObject();

        reqGenerator.writeFieldName(QUOTE_OBJECT);
        reqGenerator.writeStartObject();
        for(SSMO_Quote_Field_Mapping__mdt fieldMapping : ssmoQuoteAPIFields){
            if(fieldMapping.JSON_Object__c == QUOTE_OBJECT && fieldMapping.Add_to_Request__c){
                Object fieldValue = null;
                if(fieldMapping.Object_Name__c == QUOTE_OBJECT && quoteRecord != null){
                    fieldValue = quoteRecord.get(fieldMapping.Field_Name__c);
                }
                createJSONProperty(reqGenerator,fieldMapping,fieldValue);
            }
        }
        reqGenerator.writeEndObject();
        
        reqGenerator.writeFieldName(QUOTELINE_OBJECT);
        reqGenerator.writeStartArray(); 
        for(SBQQ__QuoteLine__c  quoteLineItem : quoteLineItems){
          	reqGenerator.writeStartObject();
        	for(SSMO_Quote_Field_Mapping__mdt fieldMapping : ssmoQuoteAPIFields){
                if(fieldMapping.JSON_Object__c == QUOTELINE_OBJECT && fieldMapping.Add_to_Request__c){
                    Object fieldValue = null;
                    if(fieldMapping.Object_Name__c == QUOTELINE_OBJECT){
                        fieldValue = quoteLineItem.get(fieldMapping.Field_Name__c);
                    }
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
    
    private static void createJSONProperty(JSONGenerator reqGenerator,SSMO_Quote_Field_Mapping__mdt fieldMapping,Object fieldValue){
        if(fieldMapping.Data_Type__c == 'Text'){
            reqGenerator.writeStringField(fieldMapping.API_Property__c, fieldValue != null?String.valueOf(fieldValue):'');
        }else if(fieldMapping.Data_Type__c == 'Boolean'){
            reqGenerator.writeBooleanField(fieldMapping.API_Property__c, fieldValue != null?Boolean.valueOf(fieldValue):false);
        }if(fieldMapping.Data_Type__c == 'Date'){
            if(fieldValue != null){
                Date dateVal = (Date) fieldValue;
                DateTime dateField = DateTime.newInstance(dateVal.year(), dateVal.month(), dateVal.day());
                reqGenerator.writeStringField(fieldMapping.API_Property__c, dateField.format('yyyy-MM-dd'));
            }else{
                reqGenerator.writeStringField(fieldMapping.API_Property__c, '');
            }
        }
    }
    
    public static String prepareQuery(Id recordId,List<SSMO_Quote_Field_Mapping__mdt> ssmoQuoteAPIFields,String objectName){
        String queryString = 'SELECT {0} FROM {1} WHERE ID = {2}';
        if(objectName == QUOTELINE_OBJECT){
            queryString = 'SELECT {0} FROM {1} WHERE SBQQ__Quote__c = {2}';
        }
        String fields = 'Id';
        List<String> fieldAPINames = getFieldNames(objectName,ssmoQuoteAPIFields);
        for(String field: fieldAPINames){
          if(field == 'Id'){ 
            continue;
          }
            
          fields += ', '+field;
        }
        queryString = String.format(queryString, new List<String>{fields, objectName, '\''+recordId+'\''});
        return queryString;
    }
    
    private static List<String> getFieldNames(String objectName,List<SSMO_Quote_Field_Mapping__mdt> ssmoQuoteAPIFields){
        List<String> fieldAPINames = new List<String>();
        for(SSMO_Quote_Field_Mapping__mdt fieldMapping:ssmoQuoteAPIFields){
            if(objectName == fieldMapping.Object_Name__c && !fieldAPINames.contains(fieldMapping.Field_Name__c)){
                fieldAPINames.add(fieldMapping.Field_Name__c);
            }
        }
        return fieldAPINames;
    }
    
    /**
     * BZAP-17203 - Recall Process Enhancements for Rep Enabled SSMO SALESFORCE.
     * This method is being called from LWC Component to recall a quote which was sent to SSMO and is currently in Out for Signature status.
     */
    public static Map<String,Object> recallQuote(Id quoteId, Id opportunityId,String uuid,Id decisionMakerId){
        Map<String, Object> result = new Map<String, Object>();
        CDdRestJSONObj.RestAPIResponse apiResponse = null;
        getAPIURLHeaders(new List<String>{Type.Named_Credential_Recall.name(),Type.Header.name()});
        try{
            String requestBody = prepareRecallRequestJSON(quoteId,opportunityId,uuid,decisionMakerId);
            apiResponse = sendRequest(requestBody);
            if(apiResponse.statusCode == 200){
                result = (Map<String, Object>) JSON.deserializeUntyped(apiResponse.body);
                result.put('status','success');
            }else{
                result.put('status','failed');
                Map<String, Object> jsonResult = (Map<String, Object>)JSON.deserializeUntyped(apiResponse.body);
                if(jsonResult.get('error_message') != null){
                    result.put('message',(String) jsonResult.get('error_message'));
                }else{
                    result.put('message',apiResponse.statusCode + ' '+apiResponse.status);
                }    
                insert new Apex_Log__c(Class_Name__c = 'CDdSSMOQuoteHelper', Method_Name__c = 'recallQuote',Log__c = String.format('API Response code = {0} and Status = {1}. Request Body = {2}',new List<String>{String.valueOf(apiResponse.statusCode),apiResponse.status,requestBody}), Log_Level__c = 'Error');
            }
        }catch(Exception ex){
            String message = String.format('Exception : {0} ',new List<String>{ex.getStackTraceString()});
            if(apiResponse != null){
                message = String.format('API Response code = {0} and Status = {1}. {2}',new List<String>{String.valueOf(apiResponse.statusCode),apiResponse.status,message});
            }
            insert new Apex_Log__c(Class_Name__c = 'CDdSSMOQuoteHelper', Method_Name__c = 'recallQuote',Log__c = message, Log_Level__c = 'Error');
            result.put('status','failed');
            result.put('message',message);
        }
        
        return result;
    }
    
    public static String prepareRecallRequestJSON(Id quoteId, Id opportunityId,String uuid,Id decisionMakerId){
        RecallRequestWrapper recallWrapper = new RecallRequestWrapper();
        
        recallWrapper.Uuid = uuid;
        recallWrapper.OpportunityId = opportunityId;
        recallWrapper.QuoteId = quoteId;
        recallWrapper.ContactId = decisionMakerId;
        
        
        String recallRequestJSON = JSON.serializePretty(recallWrapper);
        return recallRequestJSON;
    }

    public class RecallRequestWrapper{
        String Uuid;
        String OpportunityId;
        String QuoteId;
        String ContactId;
    }
}