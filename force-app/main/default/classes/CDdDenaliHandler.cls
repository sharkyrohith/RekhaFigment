/**
 * 
 * @author: Tia Xuan
 * @date: 2019-09
 * @description Handles all Denali Cherwell interactions
 * 
 */
public with sharing class CDdDenaliHandler {

    public class DenaliException extends Exception {}

    /*  
    * get the label of the setting label based on sandbox or prod 
    */
    public static Organization org = [select IsSandbox from Organization where Id =:UserInfo.getOrganizationId()];
    public static String settingLabel = org.IsSandbox ? 'UAT' : 'Prod';

    /**
    * @description setting for Denali
    */
    public static Denali_Setting__mdt setting = [select DoorDash_Record_ID__c,
                                                        URL__c,
                                                        Client_ID__c,
                                                        Username__c,
                                                        Password__c,
                                                        Location_Object_ID__c,
                                                        Location_Template__c,
                                                        Customer_Contact_Object_ID__c,
                                                        Customer_Contact_Template__c,
                                                        Incident_Object_ID__c,
                                                        Incident_Template__c,
                                                        Incident_Specifics_Relationship_ID__c,
                                                        Incident_Specifics_Template__c,
                                                        Specifics_Deployment_Object_ID__c,
                                                        Specifics_Exchange_Object_ID__c,
                                                        GetBusinessObjectFields_URL__c,
                                                        GetBusinessObjectId_URL__c,
                                                        GetBusinessObjectTemplate_URL__c,
                                                        GetBusinessRelatedObject_URL__c,
                                                        SaveBusinessObject_URL__c,
                                                        SaveRelatedBusinessObject_URL__c,
                                                        SearchBusinessObject_URL__c
                                                from Denali_Setting__mdt
                                                where MasterLabel =: settingLabel];

    /**
    * @description field mapping for location (Account)
    */        
    public static Map<String, String> LocationFieldMapping = new Map<String, String>{
            'Address1' => 'Return_Shipping_Address_Street__c',
            'Address2' => 'Return_Shipping_Address_Suite_Apt_etc__c',
            'City' => 'Return_Shipping_Address_City__c',
            'Country' => 'Shipping_Address_Country__c',
            'Company' => 'String.DoorDash',
            'LocationName' => 'Account.Name',
            'PhoneNumber' => 'Account.Phone',
            'PrimaryContact' => 'Return_Label_Shipping_Contact_Name__c',
            'RegionName' => 'Account.Region_RealZips__c',
            'State' => 'Return_Shipping_Address_State__c',
            'Zip' => 'Return_Shipping_Address_Zip__c',
            'ExternalSystemID' => 'AccountId',
            'LocationNumber' => 'Account.Restaurant_ID__c',
            'Submarket' => 'Account.RealZip_Submarket__c',
            'SubmarketID' => 'Account.RealZip_Submarket_ID__c',
            'National Store Number' => 'National_Store_Number__c',
            'RecId' => 'Account.Denali_Record_ID__c'
    };
    
    /**
    * @description field mapping for customer contact (Contact)
    */  
    public static Map<String, String> CustomerContactFieldMapping = new Map<String, String>{
            'CompanyRecID' => 'String.' + setting.DoorDash_Record_ID__c,
            'CompanyName' => 'String.DoorDash',
            'FullName' => 'Contact.FullName__c',
            'ExternalSystemID' => 'ContactId',
            'Email' => 'Contact.Email',
            'Phone' => 'Contact.Phone',
            'RecID' => 'Contact.Denali_Record_ID__c',
            'Status' => 'String.Active'};

    /**
    * @description field mapping for incident (Case)
    */  
    public static Map<String, String> IncidentFieldMapping = new Map<String, String>{
            'Status' => 'String.New',
            'Source' => 'String.API',
            'CompanyRecID' => 'String.' + setting.DoorDash_Record_ID__c,
            'RequestorID' => 'Contact.Denali_Record_ID__c',
            'RequestedForID' => 'Contact.Denali_Record_ID__c',
            'Service' => 'String.Depot Services',
            /*'Category' => 'Denali_Category__c',*/
            'Subcategory' => 'Denali_Subcategory__c',
            'ExternalSystemPriority' => 'Account_Deck_Rank__c',
            'OwnedByTeam' => 'String.PLA-Lifecycle Services',
            'CustomerReferenceID' => 'CaseNumber',
            'ShortDescription' => 'String.DoorDash Request',
            'Description' => 'String.DoorDash Request',
            'ExternalSystemID' => 'Id',
            'ConfigItemDisplayName' => 'Denali_ConfigItemDisplayName__c',
            'RecId' => 'Denali_Record_ID__c',
            'ExternalSystemRegion' => 'Region_RealZips__c',
            'ExternalSystemUsername' => 'Tablet_Username2__c',
            'ExternalSystemPassword' => 'Tablet_Password2__c',
            'ExternalSystemOpportunityName' => 'Opportunity_Name_New__c',
            'ExternalMerchantSuppliedID' => 'Merchant_Supplied_ID__c',
            'ExternalSystemLanguage' => 'Language__c' };

    /**
    * @description field mapping for specifics (Case)
    */  
    public static Map<String, String> SpecificsFieldMapping = new Map<String, String>{
            'LocationID' => 'Account.Denali_Record_ID__c',
            'ShipToDestination' => 'String.Location Address',
            'ShipToAttentionTo' => 'Contact.Name',
            'ShipToCarrirer' => 'String.Fedex',
            'ExternalSystemShippingService' => 'Shipping_Type__c',
            'ExternalSystemKit' => 'Request_Type__c',
            'LargeMarket' => 'Include_Large_Marketing_Kit__c',
            'SmallMarket' => 'Include_Marketing_Kit__c',
            'ConfigurationType' => 'Account.BillingCountryCode',
            'APIReady'=>'String.true',
            'RecId' => 'Denali_Specifics_Record_ID__c'};

    /**
    * @description get access token from Cherwell
    */  
    public static String getAccessToken(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String url =  setting.URL__c + '/token?';
        url += 'auth_mode=internal';

        String body = 'grant_type=password';
        body += '&client_id=' + setting.Client_ID__c;
        body += '&username=' + setting.Username__c;
        body += '&password=' + setting.Password__c; 

        request.setEndpoint(url);
        request.setHeader('content-type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept','application/json');
        request.setMethod('POST');
        request.setBody(body);
        request.setTimeout(60000);

        try{
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return (String) resMap.get('access_token');
            } else {
                throw new DenaliException('Cannot get access token'); 
            }  
        } catch(CalloutException e) {
            if (e.getMessage() == 'Read timed out'){
                return getAccessToken();
            }
        }

        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            Map<String, Object> resMap =   (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return (String) resMap.get('access_token');
        } else {
            throw new DenaliException('Cannot get access token'); 
        }  
    }

    /**
    * @description get Cherwell business object Id by object name
    */ 
    public static String getBusinessObjectId(String objName, String token){

        if (token == null){
            token = CDdDenaliHandler.getAccessToken();
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String url =  setting.URL__c + setting.GetBusinessObjectId_URL__c + objName;
        
        request.setEndpoint(url);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Bearer ' + token);
        request.setMethod('GET');

        HttpResponse response = http.send(request);
        String busObjId = '';

        if (response.getStatusCode() == 200) {
            List<CDdDenaliObjects.BusinessObject> resList =   (List<CDdDenaliObjects.BusinessObject>) JSON.deserialize(response.getBody(), List<CDdDenaliObjects.BusinessObject>.class);
            if (resList.size() > 0){
                return resList[0].busObId; 
            } 
        } 

        return null;     
    }

    /**
    * @description get Cherwell business object fields from business object ID
    */ 
    public static CDdDenaliObjects.BusinessObject getBusinessObjectFields(String busObjId, String token){

        if (token == null){
            token = CDdDenaliHandler.getAccessToken();
        }

        Http http = new Http(); 
        HttpRequest request = new HttpRequest();
        String url =  setting.URL__c + setting.GetBusinessObjectFields_URL__c + busObjId;
        url += '?includerelationships=true';

        request.setEndpoint(url);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Bearer ' + token);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            CDdDenaliObjects.BusinessObject resList =   (CDdDenaliObjects.BusinessObject) JSON.deserialize(response.getBody(), CDdDenaliObjects.BusinessObject.class);
            return resList; 
        } 
        return null;
    }

    /**
    * @description get Cherwell business object templates from business object ID
    */ 
    public static CDdDenaliObjects.BusinessObjectTemplate getBusinessObjectTemplate(String busObjId, List<String> fields, String token){

        if (token == null){
            token = CDdDenaliHandler.getAccessToken();
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String url =  setting.URL__c + setting.GetBusinessObjectTemplate_URL__c;

        request.setEndpoint(url);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Bearer ' + token);
        request.setMethod('POST');

        CDdDenaliObjects.BusinessObjectTemplateRequest body =  new CDdDenaliObjects.BusinessObjectTemplateRequest();
        body.busObId = busObjId;
        if (fields != null){
            body.fieldNames = fields; 
        } else {
            body.includeAll = true;
            body.includeRequired = true;
        }

        request.setBody(JSON.serialize(body));

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
           return (CDdDenaliObjects.BusinessObjectTemplate) JSON.deserialize(response.getBody(), CDdDenaliObjects.BusinessObjectTemplate.class);
        }

        return null;
    }

    /**
    * @description get Cherwell business object by search text
    */ 
    public static List<String> searchBusinessObject(String searchText, String busObjId, String token){

        if (token == null){
            token = CDdDenaliHandler.getAccessToken();
        }

        Http http = new Http();

        HttpRequest request = new HttpRequest();
        String url =  setting.URL__c + setting.SearchBusinessObject_URL__c;

        request.setEndpoint(url);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Bearer ' + token);
        request.setMethod('POST');

        CDdDenaliObjects.BusinessObjectSearch search = new CDdDenaliObjects.BusinessObjectSearch();
        search.searchText = searchText;
        search.busObIds = new List<String>{busObjId};

        request.setBody(JSON.serialize(search)); 

        HttpResponse response = http.send(request); 
        List<String> result = new List<String>();
        if (response.getStatusCode() == 200) {
            CDdDenaliObjects.BusinessObjectSearchResult res = (CDdDenaliObjects.BusinessObjectSearchResult) JSON.deserialize(response.getBody(), CDdDenaliObjects.BusinessObjectSearchResult.class);
            if (!res.hasError){
                for (CDdDenaliObjects.BusinessObjectSearchResultGroup g : res.groups){
                    if (!g.hasError){
                        for (CDdDenaliObjects.BusinessObjectSearchResultGroupListItem srl : g.simpleResultsListItems){
                            if (srl.busObId == busObjId){
                                result.add(srl.busObRecId);
                            }
                        }
                    }
                }
            }
        } 
        return result;
    }

    /**
    * @description save Cherwell business object
    */ 
    public static CDdDenaliObjects.BusinessObjectSaveResult saveBusinessObject(Object template, String token, Boolean isRelated){

        if (token == null){
            token = CDdDenaliHandler.getAccessToken();
        }

        Http http = new Http();

        HttpRequest request = new HttpRequest();
        String url =  setting.URL__c + setting.SaveBusinessObject_URL__c;
        if (isRelated){
            url =  setting.URL__c + setting.SaveRelatedBusinessObject_URL__c;
        }
        system.debug('CDdDenaliHandler.saveBusinessObject - request endpoint: --> '+ url);
        system.debug('CDdDenaliHandler.saveBusinessObject - template: --> ');
        system.debug(template);
        system.debug('CDdDenaliHandler.saveBusinessObject - serialized template/request body: -->');
        system.debug(template);
        request.setEndpoint(url);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Bearer ' + token);
        request.setMethod('POST');

        request.setBody(JSON.serialize(template)); 

        HttpResponse response = http.send(request); 
        system.debug('CDdDenaliHandler.saveBusinessObject - response: --> ');
        system.debug(response);
        CDdDenaliObjects.BusinessObjectSaveResult res = (CDdDenaliObjects.BusinessObjectSaveResult) JSON.deserialize(response.getBody(), CDdDenaliObjects.BusinessObjectSaveResult.class); 
        system.debug('CDdDenaliHandler.saveBusinessObject - response.body: --> ');
        system.debug(response.getBody());
        system.debug('CDdDenaliHandler.saveBusinessObject - CDdDenaliObjects.BusinessObjectSaveResult: --> ');
        system.debug(res);
        if (res.hasError == null){
            throw new DenaliException(response.getBody()); 
        } else if (res.hasError){
            throw new DenaliException(res.errorMessage); 
        } else {
            return res;
        } 
    }

    /**
    * @description save Cherwell business object relationship object
    */ 
    public static CDdDenaliObjects.BusinessObjectRelationshipResult getBusinessRelatedObject(String busObjId, String busRecId, String relationshipId, String token){

        if (token == null){
            token = CDdDenaliHandler.getAccessToken();
        }

        Http http = new Http(); 
        HttpRequest request = new HttpRequest();
        String partialURL = String.format(setting.GetBusinessRelatedObject_URL__c, new List<String>{busObjId, busRecId, relationshipId});
        String url =  setting.URL__c + partialURL;

        request.setEndpoint(url);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Bearer ' + token);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        CDdDenaliObjects.BusinessObjectRelationshipResult resList = (CDdDenaliObjects.BusinessObjectRelationshipResult) JSON.deserialize(response.getBody(), CDdDenaliObjects.BusinessObjectRelationshipResult.class);CDdDenaliObjects.BusinessObjectSaveResult res =  (CDdDenaliObjects.BusinessObjectSaveResult) JSON.deserialize(response.getBody(), CDdDenaliObjects.BusinessObjectSaveResult.class);
         if (res.hasError == null){
            throw new DenaliException(response.getBody()); 
        } else if (resList.hasError){
            throw new DenaliException(resList.errorMessage); 
        } else {
            return resList;
        }
    }

    /**
    * @description save Case to Cherwell, used in batch
    */ 
    public static void saveCasesToDenali(List<Id> casesId){
        if (!CDdExperimentSvc.getFeatureFlag('Send_To_Denali__c')) return;

        List<SObject> results = new List<SObject>();
        for (Id caseId : casesId){
            List<SObject> res = saveCaseToDenali(caseId, false);
            if (res.size() > 0){
                results.addAll(res);
            }
        }
        
        if (results.size() > 0){
            update results;
        }
    }

    /**
    * @description save Case to Cherwell individual case, in VF and called by trigger
    */ 
    public static List<SObject> saveCaseToDenali(Id currentCaseId, Boolean saveObjects){
        if (!CDdExperimentSvc.getFeatureFlag('Send_To_Denali__c')) return null;

        // object that will be updated after the web service calls
        List<SObject> objToUpdate = new List<SObject>();
        
        // query for the fields in the mapping
        Case currentCase = queryCase(currentCaseId);

        try {
            // get the access token from Cherwell
            String token = getAccessToken();

            // fill the location object for creation or update in Cherwell
            CDdDenaliObjects.BusinessObjectTemplate tempLocation =  
                (CDdDenaliObjects.BusinessObjectTemplate) JSON.deserialize(setting.Location_Template__c,
                                    CDdDenaliObjects.BusinessObjectTemplate.class);
            if (String.isNotBlank(currentCase.Account.Denali_Record_ID__c)){
                tempLocation.busObRecId = currentCase.Account.Denali_Record_ID__c;
            }
            tempLocation.fields = fillTemplate(tempLocation.fields, LocationFieldMapping, currentCase);
            // save the location to Cherwell
            CDdDenaliObjects.BusinessObjectSaveResult saveLocationRes = saveBusinessObject(tempLocation, token, false);
            // fill the Account Denali Record ID with the Cherwell record ID
            if (String.isBlank(currentCase.Account.Denali_Record_ID__c)){
                Account acc = new Account(Id=currentCase.AccountId, Denali_Record_ID__c= saveLocationRes.busObRecId);
                objToUpdate.add(acc);
                currentCase.Account.Denali_Record_ID__c = saveLocationRes.busObRecId;
            }

            // fill the customer contact object for creation or update in Cherwell
            CDdDenaliObjects.BusinessObjectTemplate tempCustomerContact =  
                (CDdDenaliObjects.BusinessObjectTemplate) JSON.deserialize(setting.Customer_Contact_Template__c,
                                    CDdDenaliObjects.BusinessObjectTemplate.class);
            if (String.isNotBlank(currentCase.Contact.Denali_Record_ID__c)){
                tempCustomerContact.busObRecId = currentCase.Contact.Denali_Record_ID__c;
            }
            tempCustomerContact.fields = fillTemplate(tempCustomerContact.fields, CustomerContactFieldMapping, currentCase);
            // save the customer contact to Cherwell
            CDdDenaliObjects.BusinessObjectSaveResult saveCustomerContactRes = saveBusinessObject(tempCustomerContact, token, false);
            // fill the Contact Denali Record ID with the Cherwell record ID
            if (String.isBlank(currentCase.Contact.Denali_Record_ID__c)){
                Contact ctc = new Contact(Id=currentCase.ContactId, Denali_Record_ID__c=saveCustomerContactRes.busObRecId);
                objToUpdate.add(ctc);
                currentCase.Contact.Denali_Record_ID__c = saveCustomerContactRes.busObRecId;
            }

            // fill the incident object for creation or update in Cherwell
            CDdDenaliObjects.BusinessObjectTemplate tempIncident =   
                (CDdDenaliObjects.BusinessObjectTemplate) JSON.deserialize(setting.Incident_Template__c,
                                    CDdDenaliObjects.BusinessObjectTemplate.class);
            if (String.isNotBlank(currentCase.Denali_Record_ID__c)){
                tempIncident.busObRecId = currentCase.Denali_Record_ID__c;
            }
            tempIncident.fields = fillTemplate(tempIncident.fields, IncidentFieldMapping, currentCase);
            // save the incident to Cherwell
            CDdDenaliObjects.BusinessObjectSaveResult saveIncidentRes = saveBusinessObject(tempIncident, token, false);
            // fill the Case Denali Record ID with Denali Record ID withe C
            if (String.isBlank(currentCase.Denali_Record_ID__c)){
                currentCase.Denali_Record_ID__c = saveIncidentRes.busObRecId;
            }

            // search for the specific record id
            if (String.isBlank(currentCase.Denali_Specifics_Record_ID__c)){
                CDdDenaliObjects.BusinessObjectRelationshipResult resSpecifics = 
                    CDdDenaliHandler.getBusinessRelatedObject(
                        CDdDenaliHandler.setting.Incident_Object_ID__c,
                        saveIncidentRes.busObRecId,
                        CDdDenaliHandler.setting.Incident_Specifics_Relationship_ID__c,
                        token
                    );
                // fill the Case Specifics Denali Record ID with Denali Record ID
                currentCase.Denali_Specifics_Record_ID__c = resSpecifics.relatedBusinessObjects[0].busObRecId;
            }

            // fill the incident specific object for creation or update in Cherwell
            CDdDenaliObjects.BusinessObjectRelationshipTemplate tempSpecifics =  (CDdDenaliObjects.BusinessObjectRelationshipTemplate) JSON.deserialize(setting.Incident_Specifics_Template__c,
                                    CDdDenaliObjects.BusinessObjectRelationshipTemplate.class);
            if (currentCase.Denali_Subcategory__c == 'Standard Deployment'){
                tempSpecifics.busObId = setting.Specifics_Deployment_Object_ID__c;
            } else {
                tempSpecifics.busObId = setting.Specifics_Exchange_Object_ID__c;
            }
            tempSpecifics.relationshipId = setting.Incident_Specifics_Relationship_ID__c;
            tempSpecifics.parentBusObId = setting.Incident_Object_ID__c;
            tempSpecifics.parentBusObRecId = saveIncidentRes.busObRecId;
            tempSpecifics.busObRecId = currentCase.Denali_Specifics_Record_ID__c;
            tempSpecifics.fields = fillTemplate(tempSpecifics.fields, SpecificsFieldMapping, currentCase);
            // save the incident specifics to Cherwell
            CDdDenaliObjects.BusinessObjectSaveResult saveSpecificsRes = saveBusinessObject(tempSpecifics, token, true);
            
            // clear the denali apex logs
            currentCase.Denali_Apex_Log__c = null;
            currentCase.Send_To_Denali__c = false;
            objToUpdate.add(currentCase);

        } catch (Exception e) {
            // log the error in the error log and reference it to the Case.
            List<Apex_Log__c> logs = CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()}, 'CDdDenaliHandler');
            currentCase.Denali_Apex_Log__c = logs[0].Id;
            objToUpdate.add(currentCase);

            // if it is a trigger than return the object with the record id and update them.
            // otherwise throw the exception so it can be logged on to the VF page
            if (System.isBatch()){
                return objToUpdate;
            } else {
                throw e;
            }
        } finally {   
            // update the object if saveObjects flag is passed in
            if (objToUpdate.size() > 0 && saveObjects){
                update objToUpdate;
            } 
        }

        return objToUpdate;    
    }

    /**
    * @description Query the case object with object mappings
    */ 
    private static Case queryCase(String caseId){                                                           
        
        Set<String> flds = null;
        flds = getFieldsFromMap(LocationFieldMapping, flds);
        flds = getFieldsFromMap(CustomerContactFieldMapping, flds);
        flds = getFieldsFromMap(IncidentFieldMapping, flds);
        flds = getFieldsFromMap(SpecificsFieldMapping, flds);

        String qry = 'Select ';
        qry += String.join(new List<String>(flds), ',');
        qry += ' from Case';
        qry += ' where Id =: caseId';

        System.debug ('qry:' + qry);

        return Database.query(qry);
    }

    /**
    * @description extract fields of case from mapping
    */ 
    private static Set<String> getFieldsFromMap(Map<String, String> fieldMap, Set<String> flds){

        if (flds == null){
            flds = new Set<String>();
            flds.add('Id');
        }

        for (String fld : fieldMap.values()){
            if (!flds.contains(fld) && !fld.contains('String.')){
                    flds.add(fld);
            }
        }
        return flds;
    }

    /**
    * @description fill in the template with case fields
    */ 
    private static List<CDdDenaliObjects.BusinessObjectField> fillTemplate( List<CDdDenaliObjects.BusinessObjectField> fields,
                                        Map<String, String> fldMap,
                                        Case currentCase){                                                           
        for (CDdDenaliObjects.BusinessObjectField fld : fields){
            if (fldMap.containsKey(fld.name)){ 
                String fieldVal = fldMap.get(fld.name);
                fld.dirty = true;
                // if the field mapping isn't a relationship then get the field
                if (!fieldVal.contains('.')){
                    fld.value = String.valueOf(currentCase.get(fieldVal));
                } else {
                    // if it is a relationship then get the relationship 
                    // or put the hardcoded value if it starts with 'String'
                    List<String> relFieldVal = fieldVal.split('\\.');
                    if (relFieldVal[0] == 'String'){
                        fld.value = String.valueOf(relFieldVal[1]);
                    } else {
                        fld.value = String.valueOf(currentCase.getSObject(relFieldVal[0]).get(relFieldVal[1]));
                    }
                }
            }
        }
        return fields;
    }


    

}