/**
* @author Venkat D	
* @date 2022-04
*
* @description Used for CDdCoverageCheckV2Test test class call out
*/
@isTest
global class CDdCoverageCheckV2CalloutMock implements HttpCalloutMock {
    /**
	* @description default response for coverage
	*/
    global HTTPResponse respond(HTTPRequest req) {
        
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"starting_point":{"id":"453","name":"test","active":true},"submarket":{"id":"5650","name":"test","active":true}}');
        res.setStatusCode(200);
        return res;
    }
    
    /**
	* @description non valid response for coverage
	*/
    global class CDdCoverageCheckV2CalloutNonValidMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            
            System.assertEquals('GET', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{}');
            res.setStatusCode(404);
            return res;
        }
    }
    
    /**
	* @description null response for coverage
	*/
    global class CDdCoverageCheckV2CalloutNullMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            
            System.assertEquals('GET', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('');
            res.setStatusCode(500);
            return res;
        }
    }
}