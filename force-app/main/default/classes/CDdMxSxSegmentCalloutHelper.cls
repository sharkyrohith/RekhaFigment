/********************************************************************************************************************
* @author Ebenezer
* @date 12/05/2021
*
* @group Merchant Services
*
* @description Will make Http API callout to Segment based on the Named Credentials
* 
**************************************************************************************************************************************/
public class CDdMxSxSegmentCalloutHelper {
    /**
     * @description Calls the Segment http API, yo post the event triggered
     * @param CDdMxSxSegmentHelper helper
     * @return  
    */ 
    public static HttpResponse callSegmentAPI(String body, 
                                              String urlPath,String method){
        HttpRequest req = new HttpRequest();
        String namedCredientialName = CDdMxSxSegmentConstants.NAMED_CREDENTIAL_NAME ; 
        String authHeaderKey = CDdMxSxSegmentConstants.AUTHORIZATION_HEADER_KEY ;
        req.setEndpoint('callout:' + namedCredientialName + urlPath);
        req.setMethod(method);
        req.setBody(body);
        String apiToken = 'Basic ' + '{!$Credential.Password}';
        req.setHeader(authHeaderKey, apiToken);
        Http http = new Http();
        return http.send(req) ;
    }
}