@isTest
private class CDdACConnectTaskCreationTest {
    public class MockHttpResponseGenerator implements HttpCalloutMock{      
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(204);
            return res;         
        }
    }  
    @isTest static void invokeLambda() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<String> input = new List<String>();
        input.add('key=value');
        CDdACConnectTaskCreation.CDdACConnectTaskCreation(input);
    }
    
    @isTest static void getProfileName() {
        Test.startTest();
        String profileName=CDdACConnectTaskCreation.getProfileName();
        Test.stopTest();
        System.assertEquals(true, profileName!=null, 'Method should return the logged in user profile');
    }
}