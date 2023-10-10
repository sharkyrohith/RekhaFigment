/**
* @author Tia Xuan	
* @date 2019-04
*
* @description Used for CDdLocalPromoTest test class call out
*/
global class CDdLocalPromoCalloutMock { //implements HttpCalloutMock {
   	/**
	* @description default callout result
	*/
    // global HTTPResponse respond(HTTPRequest req) {
        
    //     System.assertEquals('POST', req.getMethod());
        
    //     // Create a fake response
    //     HttpResponse res = new HttpResponse();
    //     res.setHeader('Content-Type', 'application/json');
    //     res.setBody('[{"id":"1", "type":"weblink", "consumer promotion": {"id":"1", "code":"test", "submarkets":[{"id":1}]}}]');
    //     res.setStatusCode(200);
    //     return res;
    // }
    
    // /**
	// * @description consumer callout result
	// */
    // global class CDdLocalPromoCalloutConsumerMock implements HttpCalloutMock {
    //     global HTTPResponse respond(HTTPRequest req) {
            
    //         System.assertEquals('POST', req.getMethod());
            
    //         // Create a fake response
    //         HttpResponse res = new HttpResponse();
    //         res.setHeader('Content-Type', 'application/json');
    //         res.setBody('[{"id":"1", "type":"consumer_promotion", "consumer promotion": {"id":"1", "code":"test", "submarkets":[{"id":1}]}}]');
    //     	res.setStatusCode(200);
    //         return res;
    //     }
    // }
    
    // /**
	// * @description non valid callout result
	// */
    // global class CDdLocalPromoCalloutNonValidMock implements HttpCalloutMock {
    //     global HTTPResponse respond(HTTPRequest req) {
            
    //         System.assertEquals('POST', req.getMethod());
            
    //         // Create a fake response
    //         HttpResponse res = new HttpResponse();
    //         res.setHeader('Content-Type', 'application/json');
	// 		res.setStatusCode(400);
    //         return res;
    //     }
    // }
}