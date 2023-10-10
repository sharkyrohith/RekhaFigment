/**
 * CDdSendCassieAPIHandler
 *
 * @author     Raja
 * @date  2021-11-16
 * @decription  This class is the handler for Cassie API Callouts
 */
public with sharing class CDdGDPRCassieAPI{

    /*** constants ***/
    public static final String CLASS_INFO = 'CDdGDPRCassieAPI';
    public static final String MAKE_CASSE_REQUEST= 'makeCassieRequest';
    
    /**
    * @author     Dinesh Annapareddy
    * @date  11-09-2021
    */
    public static string getCassieAuthToken() {
        CDdRESTConnectorSvc var = new CDdRESTConnectorSvc();
        String token;
        DateTime timeStamp;
        
        if(CDdCacheService.getFromOrgCache(CDdGDPRConstants.PLATFORM_CACHE_TIMESTAMP) != null)
            timeStamp= (DateTime) Cache.Org.get(CDdGDPRConstants.PLATFORM_CACHE_TIMESTAMP);
        
        if(CDdCacheService.getFromOrgCache(CDdGDPRConstants.PLATFORM_CACHE_TOKEN) != null)
            token= (String) Cache.Org.get(CDdGDPRConstants.PLATFORM_CACHE_TOKEN);
        
        if(timeStamp ==null || timeStamp <= datetime.now() || token == null ){
            Map<string,string> body = new Map<string,string>();
            body.put('apiKey',  CDdGDPREmailHelper.SETTING.Cassie_API_Key__c != null 
                                    ? CDdGDPREmailHelper.SETTING.Cassie_API_Key__c
                                        : '');
            body.put('Username','{!$Credential.UserName}');
            body.put('Password','{!$Credential.Password}');

            String namedCreds = CDdGDPREmailHelper.SETTING.Cassie_Named_Credential__c != null 
                                ? CDdGDPREmailHelper.SETTING.Cassie_Named_Credential__c
                                    : '';

            String authURL = CDdGDPREmailHelper.SETTING.Cassie_Authorization_URL__c != null 
                                ? CDdGDPREmailHelper.SETTING.Cassie_Authorization_URL__c
                                    : '';


            CDdRestJSONObj.RestAPIResponse response= var.invokeRESTAPI('POST',JSON.serialize(body),NULL,NULL,authURL,'application/json',NULL, NULL, namedCreds);                
            
            if(response != null){
                if(response.statusCode == 200){
                    if(response.body != null){
                        Map<String, Object> mapOfJson = (Map<String, Object>) JSON.deserializeUntyped(response.body);
                        token = (String)mapOfJson.get('token');
                        timeStamp=DateTime.ValueofGmt(((String)mapOfJson.get('tokenExpiry')).replace('T', ' '));
                    }
                }

                CDdCacheService.putInOrgCache(CDdGDPRConstants.PLATFORM_CACHE_TIMESTAMP,timeStamp,CDdGDPRConstants.PLATFORM_CACHE_TTL);
                CDdCacheService.putInOrgCache(CDdGDPRConstants.PLATFORM_CACHE_TOKEN,token,CDdGDPRConstants.PLATFORM_CACHE_TTL);
            }
            
        }
        return token;
    }
    /**
    * @author     Raja
    * @date  2021-11-16
    * @decription This method makes an API call to Cassie  endpoint
    * @param   http method type,endpoint,request body
    * @return  response from API
    */
    public static List<CDdGDPREmailObj.CDdGDPRCreateContactObject> sendContactCreation(String reqbody) {
        List<CDdGDPREmailObj.CDdGDPRCreateContactObject> wrpList = (List<CDdGDPREmailObj.CDdGDPRCreateContactObject>) 
                                                                        JSON.deserialize(reqbody, 
                                                                            List<CDdGDPREmailObj.CDdGDPRCreateContactObject>.class);

        string cassieQueryEndPoint = CDdGDPREmailHelper.SETTING.Cassie_Query_Endpoint__c != null 
                                        ? CDdGDPREmailHelper.SETTING.Cassie_Query_Endpoint__c
                                            : '';
        cassieQueryEndPoint +=  CDdGDPREmailHelper.SETTING.Cassie_Query_Params__c != null 
                                    ? CDdGDPREmailHelper.SETTING.Cassie_Query_Params__c
                                    : '';
        
        string cassieUpdateEndPoint = CDdGDPREmailHelper.SETTING.Cassie_Update_Endpoint__c != null 
                                        ? CDdGDPREmailHelper.SETTING.Cassie_Update_Endpoint__c 
                                            : '';
        
        string cassieToken = getCassieAuthToken();
              
        if(cassieToken != NULL){
            for(CDdGDPREmailObj.CDdGDPRCreateContactObject wrp: wrpList){
                for(String reqKey : wrp.reqList.keySet()){
                    CDdGDPREmailObj.CassieRequest req = wrp.reqList.get(reqKey);
                    CDdRESTConnectorSvc var = new CDdRESTConnectorSvc();
                    try{
                        //make a call to cassie to get Preferences
                        CDdRestJSONObj.RestAPIResponse response=var.invokeRESTAPI(
                                                                    CDdSupportConstants.POST_METHOD,
                                                                    JSON.serialize(req),null,
                                                                    cassieQueryEndPoint,null,
                                                                    CDdSupportConstants.CONTENT_TYPE_JSON,
                                                                    'Authorization','Bearer ' + cassieToken, 
                                                                    null);
               
                        if (response.statusCode == 200) {
                            Type resultType = Type.forName('CDdGDPREmailObj.cassieCurrentPreferencesResponse');
                            CDdGDPREmailObj.cassieCurrentPreferencesResponse deserializeResponse = (CDdGDPREmailObj.cassieCurrentPreferencesResponse)JSON.deserialize(response.body, resultType);
                            
                            //add responseplayload to process
                            wrp.respList.put(reqKey, deserializeResponse);
                        } else if(response.statusCode == 204){
                            //prepare a requst for creating the request in CASSIE.                       
                            CDdGDPREmailObj.CassieRequestNewContact createRequest = CreateUpdateRequest(req.Identifiers[1].Value,req.Identifiers[0].Value);
                            //make a call to insert the contact in cassie 
                            CDdRestJSONObj.RestAPIResponse res=var.invokeRESTAPI(
                                                                    CDdSupportConstants.POST_METHOD,
                                                                    JSON.serialize(createRequest),null,
                                                                    cassieUpdateEndPoint,null,
                                                                    CDdSupportConstants.CONTENT_TYPE_JSON,
                                                                    'Authorization','Bearer ' + cassieToken, 
                                                                    null);                                                 
                        }
                    }
                    catch(Exception ex){  
                        CDdErrorUtilities.publishException('CDdGDPRCassieAPI','sendContactCreation',ex);
                    }
                }
            }
        }
        return wrpList;
    }

    public static CDdGDPREmailObj.CassieRequest createCassieLookupRequest(String email,String persona) {
        
        CDdGDPREmailObj.CassieRequest request = new CDdGDPREmailObj.CassieRequest(); 
        list<CDdGDPREmailObj.cassieIdentifiers> reqIdentifiers= new list<CDdGDPREmailObj.cassieIdentifiers> ();
        
        if(email != null && persona != null){
        
            if(persona != null){
            
                CDdGDPREmailObj.cassieIdentifiers Identifier1=new CDdGDPREmailObj.cassieIdentifiers();
                Identifier1.IdentifierID='2';
                Identifier1.Value=Persona;
                reqIdentifiers.add(Identifier1);
            }
            if(email!= NULL){
            
                CDdGDPREmailObj.cassieIdentifiers Identifier2=new CDdGDPREmailObj.cassieIdentifiers();
                Identifier2.IdentifierID='3';
                Identifier2.Value=email;
                reqIdentifiers.add(Identifier2);
            }
            
            request.Identifiers=reqIdentifiers;
        }
        return request;
    }
    
    private static CDdGDPREmailObj.CassieRequestNewContact CreateUpdateRequest(String email,String persona) {
        CDdGDPREmailObj.CassieRequestNewContact req= new CDdGDPREmailObj.CassieRequestNewContact(); 
        CDdGDPREmailObj.CassieRequestLookupProperties reqProperties=new CDdGDPREmailObj.CassieRequestLookupProperties();
        reqProperties.URN1 = persona;
        reqProperties.Email1 = email;
        
        req.MethodType = CDdGDPRConstants.CASSIE_UPDATE_METHOD_TYPE;
        req.LookupParameters = reqProperties;
        
        return req;
    }
}