@isTest
global class TDdCoverageCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // vCS__c testSettings = VTestUtil.createVeltigSettings();
        // testSettings.APICalloutToKodakit__c = true;

        // insert testSettings;


        // System.assertEquals(testSettings.DoorstepEndpointPrefix__c, req.getEndpoint());
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"starting_point":453,"valid":true,"submarket_is_active":true}');
        res.setStatusCode(200);
        return res;
    }
}