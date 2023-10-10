/**
 * 
 * @author: Tia Xuan
 * @date: 2020-05
 * @description test class for CDdRecaptchaContactSupportController
 * 
 */
@isTest
public class CDdRecaptchaContactSupportTest {

    public class MockHttpResponseGenerator implements HttpCalloutMock{
        
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(200);
            return res;         
        }
    }  

    public static testMethod void verifyCaptchaTest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());     
        
        Test.startTest();
        Boolean res = CDdRecaptchaContactSupportController.verifyRecaptcha('test','Default');
        System.assertEquals(true, res);
        Test.stopTest();
    }


}