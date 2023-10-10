/*
*@Description: Utility Test class to mock callout
@Author : Veera Maddukuri
@Date : 2021-11
*/
@isTest
public with sharing class CDdMockHttpResponse implements HttpCalloutMock{
    private String body;
    private Integer statusCode;
    
    public CDdMockHttpResponse(String body){
        this.body = body;
        this.statusCode = 200;
    }

    public CDdMockHttpResponse(String body,Integer statusCode){
        this.body = body;
        this.statusCode = statusCode;
    }
    
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.statusCode);
        return res;
    }     
}