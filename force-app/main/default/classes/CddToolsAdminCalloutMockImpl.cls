/**
 * Author       : Sugan
 * Date         : Feb 13th 2023
 * Description  : All mock responses related to the different implementations of the Tools AdminCallout
 */
@isTest
public class CddToolsAdminCalloutMockImpl implements HttpCalloutMock
{
    public string actionName;
    public string testresponsKey;
    public string responseBody;
    public Integer responseStatusCode;
    /* we can use this map to configure response body
    based on the response key sent in the constructor */
    public Map<String,String> testResponseMessageMap = new Map<String,String>{
        'SUCCESS_RESPONSE' => '{ "deliveryUuidShort": "17970df2-2fca-4920-8fda-12b1e9a3f3d1", "storeRefund": 573, "dispatchErrorId": 587685242}',
        'NO_ERROR_CHARGE_RESPONSE' => '{"message": "9 FAILED_PRECONDITION: Error = FAILED_PRECONDITION: The Mx error charge refund was denied because there are no error charges (with valid store charge) on this order."}'
    };
    public CddToolsAdminCalloutMockImpl(String actionNameVal, String responseKeyVal){
        this.actionName = actionNameVal;
        this.testresponsKey = responseKeyVal;
        if(actionName == 'chargebacksubmission'){
            this.responseBody =  testResponseMessageMap.containsKey(testresponsKey) ? testResponseMessageMap.get(testresponsKey) : '';
            this.responseStatusCode = (testresponsKey == 'SUCCESS_RESPONSE') ? 200 : 500;
        }
    }
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.responseBody);
        res.setStatusCode(this.responseStatusCode);
        return res;
    }
}