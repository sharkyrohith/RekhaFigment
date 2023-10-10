/********************************************************************************************************************
* @author Ebenezer
* @date 11/23/2021
*
* @group Merchant Services
*
* @description Should be used for mocking http requests for test class execution
* 
**************************************************************************************************************************************/
@isTest
global class CDdMxSxHttpMockGenerator  implements HttpCalloutMock {
    /**
     * @description Overriding this method from HttpcalloutMock, checks the endpoint/method and responds as the service needs
     * @param HTTPRequest req
     * @return OHTTPResponse response
     */
    global HTTPResponse respond(HTTPRequest req) {
            HTTPResponse response = new HTTPResponse();
            //Mock other Endpoints here
            if(req.getEndpoint().containsIgnoreCase('segment') && req.getMethod() == 'POST'){
                response.setHeader('Content-Type', 'application/json');
                response.setStatusCode(200);
                response.setBody('{"success": true}');
            }

            return response;
    }
}