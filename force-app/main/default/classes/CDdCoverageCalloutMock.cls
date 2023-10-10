/**
* @author Tia Xuan	
* @date 2019-04
*
* @description Used for CDdCoverageCheckTest test class call out
*/
@isTest
global class CDdCoverageCalloutMock implements HttpCalloutMock {
    /**
	* @description default response for coverage
	*/
    global HTTPResponse respond(HTTPRequest req) {
        
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"starting_point":453,"starting_point_name":"test","valid":true,"submarket_is_active":true}');
        res.setStatusCode(200);
        return res;
    }
    
    /**
	* @description non valid response for coverage
	*/
    global class CDdCoverageCalloutNonValidMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            
            System.assertEquals('GET', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"starting_point":453,"starting_point_name":"test","valid":false,"submarket_is_active":true}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    /**
	* @description null response for coverage
	*/
    global class CDdCoverageCalloutNullMock implements HttpCalloutMock {
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