@istest
global without sharing class NSAccountCreationResponseGenerator {
  global class MockSuccess implements HttpCalloutMock{
    global HttpResponse respond(HttpRequest req){
      System.assertEquals(true, req.getEndpoint().startsWith('https://3938860-sb1.restlets.api.netsuite.com'));
      System.assertEquals('POST', req.getMethod());
      
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"id":"5678656"}');
      res.setStatusCode(200);
      return res;
    }
  }
  global class MockFailure implements HttpCalloutMock{
    global HttpResponse respond(HttpRequest req){
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('Bad Request');
      res.setStatusCode(400);
      return res;
    }
  }
}