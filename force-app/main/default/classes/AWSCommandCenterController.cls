/**
 * @description       : Controller for Command Center
 * @author            : Jose Vega
 * @last modified on  : 08-02-2023
 * @last modified by  : Jose Vega
**/
public with sharing class AWSCommandCenterController {

    /**
     * @description hasAccess checks if the username exists in the custom metadata object
     * @return   return description
     */
    @AuraEnabled (cacheable=true)
    public static Boolean hasAccess() {
        Command_Center_Access__c accessRecord = Command_Center_Access__c.getInstance(UserInfo.getUserId());
        return accessRecord != null && accessRecord.Active__c;
    }

    /**
     * @description getUserVertical checks which vertical user belongs to filter out which queue to show.
     * @return   return description
     */
    @AuraEnabled (cacheable=true)
    public static String getUserVertical() {
        Command_Center_Access__c accessRecord = Command_Center_Access__c.getInstance(UserInfo.getUserId());
        return accessRecord.Vertical__c;
    }

    @AuraEnabled (cacheable=true)
    public static String getQueues() {
        String endpoint = awsGetResourceEndpoint('queues');
        HttpResponse res = awsMakeCallout('GET', null, 'AWS_Command_Center', endpoint, new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});

        String responseBody = res.getBody();

        // check callout response status
        if(res.getStatusCode() != 200) {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        // return datatable
        List<queuesResponse> response = (List<queuesResponse>) JSON.deserialize(responseBody, List<queuesResponse>.class);
        String vertialToMatch = getUserVertical();
        List<queuesResponse> queuesToReturn = new List<queuesResponse>();
        for(queuesResponse queueEntry : response) {
            if (queueEntry.tags == vertialToMatch || vertialToMatch == 'ALL' && !String.isBlank(queueEntry.name)) {
                queuesToReturn.add(queueEntry);
            }
        }

        return JSON.serializePretty(queuesToReturn);
    }

    @AuraEnabled (cacheable=true)
    public static String saveQueue(String payload) {
        queueRequest request = (queueRequest) JSON.deserialize(payload, queueRequest.class);

        // Dynamically set the Vertical of the Queue and User who created it
        if(String.isBlank(request.vertical)) {
            request.tags = getUserVertical();
        } else {
            request.tags = request.vertical;
        }

        request.user = UserInfo.getUserName();

        String endpoint = awsGetResourceEndpoint('queues');

        HttpResponse res = awsMakeCallout('POST', JSON.serializePretty(request), 'AWS_Command_Center', endpoint, new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});
        String responseBody = res.getBody();

        // check callout response status
        if(res.getStatusCode() != 200) {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        return JSON.serializePretty(responseBody);
    }

    @AuraEnabled (cacheable=true)
    public static String getBlockedNumbers() {
        String endpoint = awsGetResourceEndpoint('blocked-numbers');
        HttpResponse res = awsMakeCallout('GET', null, 'AWS_Command_Center', endpoint, new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});

        String responseBody = res.getBody();

        // check callout response status
        if(res.getStatusCode() != 200) {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        return responseBody;
    }

    @AuraEnabled (cacheable=true)
    public static String getPrompts() {
        String endpoint = awsGetResourceEndpoint('prompts');
        HttpResponse res = awsMakeCallout('GET', null, 'AWS_Command_Center', endpoint, new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});
        String responseBody = res.getBody();

        // check callout response status
        if(res.getStatusCode() != 200) {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        return responseBody;
    }

    @AuraEnabled (cacheable=true)
    public static String deleteBlockedNumber(string payload) {
        String endpoint = awsGetResourceEndpoint('blocked-numbers');
        HttpResponse res = awsMakeCallout('DELETE', payload, 'AWS_Command_Center', endpoint, new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});
        String responseBody = res.getBody();
        // system.debug(responseBody);

        // check callout response status
        if(res.getStatusCode() != 200) {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        // return datatable
        return responseBody;
    }

    @AuraEnabled (cacheable=true)
    public static String addBlockedNumber(string payload) {
        String endpoint = awsGetResourceEndpoint('blocked-numbers');
        HttpResponse res = awsMakeCallout('POST', payload, 'AWS_Command_Center', endpoint, new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});

        String responseBody = res.getBody();

        // check callout response status
        if(res.getStatusCode() != 200) {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        // return datatable
        return responseBody;
    }

    @AuraEnabled (cacheable=true)
    public static String getHoursOfOperations() {
        String endpoint = awsGetResourceEndpoint('hours');
        HttpResponse res = awsMakeCallout('GET', null, 'AWS_Command_Center', endpoint, new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});

        String responseBody = res.getBody();

        // check callout response status
        if(res.getStatusCode() != 200) {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        return responseBody;
    }

    @AuraEnabled
    public static customResponse awsUpdateRecord(String payload) {
        customResponse result = new customResponse();

        // make callout
        HttpResponse res = awsMakeCallout('POST', payload, 'AWS_Command_Center', 'prompts', new Map<String, String>{'x-api-key' => '{!$Credential.Password}'});
        String responseBody = res.getBody();

        // check callout response status
        if(res.getStatusCode() == 200) {
            result.isSuccess = true;
            result.message = 'Record has been updated successfully!';
        } else {
            throw new AWSCommandCenterException('Exception: ' + res.getStatusCode() + ': ' + responseBody);
        }

        return result;
    }

    // -- AWS Methods -- //

    // to do : URL encoding (space etc)
    private static HttpResponse awsMakeCallout(String method, String payload, String namedCredential, String endpointSuffix, Map<String, String> additionalHeaders) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + namedCredential + '/' + endpointSuffix);
        req.setMethod(method);
        if(String.isNotBlank(payload)){
            req.setBody(payload);
        }
        for(String headerName : additionalHeaders.keyset()) {
            req.setHeader(headerName, additionalHeaders.get(headerName));
        }

        Http h = new Http();
        return h.send(req);
    }

    private static String awsGetResourceEndpoint(String resource) {
        return resource;
    }

    // -- Wrappers -- //

    public class customResponse {
        @AuraEnabled public boolean isSuccess   {public get; public set;}
        @AuraEnabled public string message      {public get; public set;}
    }

    public class queuesTagResponse {
        @AuraEnabled public string type         {public get; public set;}
    }

    public class queuesResponse {
        @AuraEnabled public string name             {public get; public set;}
        @AuraEnabled public string description      {public get; public set;}
        @AuraEnabled public string status           {public get; public set;}
        @AuraEnabled public string hoursOfOperation {public get; public set;}
        @AuraEnabled public string tags             {public get; public set;}
        @AuraEnabled public string arn              {public get; public set;}
    }

    public class queueRequest {
        public string name              {public get; public set;}
        public string description       {public get; public set;}
        public string vertical          {public get; public set;}
        public string businessHours     {public get; public set;}
        public string businessHoursName {public get; public set;}
        public string tags              {public get; public set;}
        public string user              {public get; public set;}
    }

    // -- Custom Exception -- //

    public class AWSCommandCenterException extends Exception {}
}