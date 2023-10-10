public with sharing class CDdACConnectTaskCreation {
    @InvocableMethod
    public static void CDdACConnectTaskCreation(List<String> info){
      HttpRequest req = new HttpRequest();
      req.setEndpoint('https://rx5wjnrkog.execute-api.us-west-2.amazonaws.com/task/create');
      req.setMethod('POST');
      req.setBody(string.join(info, ','));
 
      HTTPResponse response = new Http().send(req);
      return;
    }
    
    public static string getProfileName() {
        return [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
    }
 }