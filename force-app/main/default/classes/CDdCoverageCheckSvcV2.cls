/**
* @author: Venkat D
* @date: 2022-03-31
* @description Service class for callouts to /mapping/api/v1/address/coverage
*/
public class CDdCoverageCheckSvcV2 {
    static final String calloutErrorMsg = 'Something went wrong! Please contact your administrator. ';
    private static final String INVALID_ADDRESS_ERROR_MSG = 'Please enter a valid address. Street and Postal Code are required fields';
    private static List<NamedCredential> ncList = new List<NamedCredential>();
    public static Group Omniqueue;
    static {
        ncList =  [SELECT DeveloperName,Endpoint FROM NamedCredential WHERE DeveloperName = 'CoverageCheck_API_V2'];
        Omniqueue = [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name =:Label.Lead_Unassigned_Queue];
    }
    public static Boolean checkAcctCoverage(Account acct) {
        List<String> errorMessages = new List<String>();
        acct = [SELECT Id, BillingAddress FROM Account WHERE Id = :acct.Id];
        CDdRestJSONObj.CoverageCheckResponseV2 body;
        String requestURL = '';
        try {
            if (acct.BillingAddress==null || String.isBlank(acct.BillingAddress.getStreet()) || String.isBlank(acct.BillingAddress.getPostalCode())) {
                throw new CDdCoverageCheckSvcValidationException(INVALID_ADDRESS_ERROR_MSG);
            }

            requestURL = createCoverageRequestURL(acct.BillingAddress );
            body = checkCoverage(acct.BillingAddress);
            setCoverageStartingPointValues(acct,body);
            Database.SaveResult sResults = Database.update(acct, false);

            errorMessages = CDdErrorUtilities.processSaveResults(new List<Database.SaveResult> { sResults });

        } catch (CDdCoverageCheckSvcValidationException e) {
            acct.addError(e.getMessage() + '<br/>Request= '+ requestURL + '<br/>Response= '+JSON.serialize(body) );
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createHTTPApexLogs(requestURL, JSON.serialize(body),acct.id, errorMessages,
                                                 'CDdCoverageCheckSvc', 'checkAcctCoverage', LoggingLevel.ERROR);
            return false;
        } catch (Exception e) {
            String resError = 'No Coverage';
            acct.addError(calloutErrorMsg +'<br/>Request= '+ requestURL + '<br/>Response= '+JSON.serialize(body) );
            CDdErrorUtilities.createHTTPApexLogs(requestURL,JSON.serialize(body),acct.id, new List<String>{resError},
                                                 'CDdCoverageCheckSvc', 'checkAcctCoverage', LoggingLevel.ERROR);
            return false;
        }

        if (!errorMessages.isEmpty()) {
            CDdErrorUtilities.createHTTPApexLogs( requestURL, JSON.serialize(body),acct.id, errorMessages,
                                                 'CDdCoverageCheckSvc', 'checkAcctCoverage', LoggingLevel.ERROR);
        }

        return true;
    }

    public static void checkAcctCoverage(List<Id> accountIds) {
        List<String> errorMessages = new List<String>();
        List<Account> updateAccts = new List<Account>();

        List<Account> accounts =    [SELECT Id, BillingAddress
                                     FROM Account
                                     WHERE Id in :accountIds
                                     AND BillingStreet != null
                                     AND BillingPostalCode != null];

        for (Account acc : accounts) {
            try {
                CDdRestJSONObj.CoverageCheckResponseV2 body = checkCoverage(acc.BillingAddress);
                setCoverageStartingPointValues(acc,body);
                updateAccts.add(acc);
            } catch (Exception e) {
                errorMessages.add(e.getMessage());
            }
        }

        List<Database.SaveResult> sResults = Database.update(updateAccts, false);

        errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);

        if (!errorMessages.isEmpty()) {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdCoverageCheckSvc',
                        'checkAcctCoverage',LoggingLevel.ERROR);
        }
    }

    public static Boolean checkLeadCoverage(Lead lead) {
        List<String> errorMessages = new List<String>();
        lead = [SELECT Id, Address
                FROM Lead
                WHERE Id = :lead.Id];
        String requestURL = '';
        CDdRestJSONObj.CoverageCheckResponseV2 body;
        try {
            if (lead.Address==null || String.isBlank(lead.Address.getStreet()) || String.isBlank(lead.Address.getPostalCode())) {
                throw new CDdCoverageCheckSvcValidationException(INVALID_ADDRESS_ERROR_MSG);
            }

            requestURL = createCoverageRequestURL(lead.Address);

            body = checkCoverage(lead.Address);
            setCoverageStartingPointValues(lead,body);
            Database.SaveResult sResults = Database.update(lead, false);
            errorMessages = CDdErrorUtilities.processSaveResults(new List<Database.SaveResult> { sResults });
        } catch (CDdCoverageCheckSvcValidationException e) {
            lead.addError(e.getMessage() +'<br/>Request= '+ requestURL + '<br/>Response= '+JSON.serialize(body) );
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createHTTPApexLogs(requestURL, JSON.serialize(body),lead.id, errorMessages,
                                                 'CDdCoverageCheckSvc', 'checkLeadCoverage', LoggingLevel.ERROR);
            return false;
        } catch (Exception e) {
            String resError = 'No Coverage';
            lead.addError(calloutErrorMsg +'<br/>Request= '+ requestURL + '<br/>Response= '+JSON.serialize(body) );
            CDdErrorUtilities.createHTTPApexLogs(requestURL, JSON.serialize(body),lead.id, new List<String>{resError},
                                                 'CDdCoverageCheckSvc', 'checkLeadCoverage', LoggingLevel.ERROR);
            return false;
        }
        if (!errorMessages.isEmpty()) {
            CDdErrorUtilities.createHTTPApexLogs( requestURL, JSON.serialize(body), lead.id, errorMessages,
                                                 'CDdCoverageCheckSvc', 'checkAcctCoverage', LoggingLevel.ERROR);
        }

        return true;
    }

    public static void checkLeadCoverage(List<Id> leadIds) {
        checkLeadCoverage(leadIds, false);
    }

    //BASD-16422 - Call from weekly scheduler to check lead coverage
    public static List<Id> checkLeadCoverage(List<Id> leadIds, Boolean callFromSched) {
        List<Lead> updateLeads = new List<Lead>();
        Boolean isEmailLeads = False;
        List<Id> emailLeads = new List<Id>();
        List<String> errorMessages = new List<String>();
        List<Lead> leads =    [SELECT Id, Address, Status, OwnerId
                               FROM Lead
                               WHERE Id in :leadIds
                               AND Street != null
                               AND PostalCode != null];

        for (Lead ld : leads) {
            try {
                CDdRestJSONObj.CoverageCheckResponseV2 body = checkCoverage(ld.Address);
                isEmailLeads = setCoverageStartingPointValues(ld,body,callFromSched);

                if(isEmailLeads){
                    emailLeads.add(ld.id);
                }

                updateLeads.add(ld);
            } catch (Exception e) {
                errorMessages.add(e.getMessage());
            }
        }

        Database.update(updateLeads, false);

        if (!errorMessages.isEmpty()) {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdCoverageCheckSvc',
                        'checkLeadCoverage',LoggingLevel.ERROR);
        }

        return emailLeads;
    }

    private static void setCoverageStartingPointValues(sObject obj, CDdRestJSONObj.CoverageCheckResponseV2 body){
        setCoverageStartingPointValues(obj,body,False);
    }

    private static Boolean setCoverageStartingPointValues(sObject obj, CDdRestJSONObj.CoverageCheckResponseV2 body, Boolean callFromSched) {
        Boolean isEmailLeads = False;

        if (body == null) {
            throwCalloutException();
        }

        if (body.starting_point != null && body.starting_point.active == true) {
            obj.put('In_Coverage__c','Yes');

            //BASD-16422 - Check leads via weekly scheduler, if in coverage - update fields or send email to owner
            if(obj.getSObjectType().getDescribe().getName() == 'Lead' && callFromSched){
                Boolean isOwnerQueue = String.valueOf(obj.get('OwnerId')).startsWith('00G');

                if(isOwnerQueue && obj.get('Status') == 'Untouched'){
                    obj.put('OwnerId',Omniqueue.Id);
                } else if(isOwnerQueue && obj.get('Status') != 'Untouched'){
                    obj.put('Status','Untouched');
                    obj.put('OwnerId',Omniqueue.Id);
                }else if(!isOwnerQueue){
                    isEmailLeads = True;
                }
            }
        } else {
            obj.put('In_Coverage__c','No');
        }

        if (body.starting_point != null && body.starting_point.id != null){
            obj.put('Starting_Point_ID__c',Integer.valueOf(body.starting_point.id));
        }

        if (body.starting_point != null && body.starting_point.name != null){
            obj.put('Starting_Point__c',body.starting_point.name);
        }

        return isEmailLeads;
    }

    /**
    * @description BZAP-13644 - Coverage Check V2 - New Endpoint changes
    *
    */
    private static CDdRestJSONObj.CoverageCheckResponseV2 checkCoverage(Address addr) {
        if (addr == null) {
            return null;
        }


        CDdRestJSONObj.RestAPIResponse res = new CDdRestJSONObj.RestAPIResponse();
        HttpRequest req = new HttpRequest();
        try {

            req.setMethod('GET');
            req.setEndpoint('callout:CoverageCheck_API_V2'+ '?pickup_address=' + getEncodedAddressString(addr));
            req.setTimeout(20000);

            Http h = new Http();
            HttpResponse resp =  h.send(req);
            res.body = resp.getBody();
            res.statusCode = resp.getStatusCode();
            res.status = resp.getStatus();

        } catch (Exception ex) {
            throw ex;
        }

        CDdRestJSONObj.CoverageCheckResponseV2 covCheckResponse = null;
        if(res.statusCode == 404){
            covCheckResponse = new CDdRestJSONObj.CoverageCheckResponseV2();
            covCheckResponse.status = res.status;
            covCheckResponse.statusCode = res.statusCode;
        }else{
            covCheckResponse = (CDdRestJSONObj.CoverageCheckResponseV2) JSON.deserialize(res.body, CDdRestJSONObj.CoverageCheckResponseV2.class);
        }

        return covCheckResponse;
    }

    private static void throwCalloutException() {
        CalloutException e = new CalloutException();
        e.setMessage('Response body does not exist');
        throw e;
    }
    /**
    * @description BZAP-3955 - Improve Coverage Check
    * Check for empty (or null) values in the Address attributes. Do not include the empty (or null) values in the address string
    */
    private static String getEncodedAddressString(Address addr){
        String addressString = String.isNotBlank(addr.Street) ? addr.Street : '';
        addressString += ((String.isNotBlank(addressString) ? ' ' : '') + (String.isNotBlank(addr.City) ? addr.City : ''));
        addressString += ((String.isNotBlank(addressString) ? ' ' : '') + (String.isNotBlank(addr.StateCode) ? addr.StateCode : ''));
        if(String.isNotBlank(addr.PostalCode)) {
            if(String.isNotBlank(addr.CountryCode)) {
                addressString += ' ';
            }
            if (addr.CountryCode == 'US' && addr.PostalCode.Length() > 5) {
                addressString += addr.PostalCode.SubString(0,5);
            } else {
                addressString += addr.PostalCode;
            }
        }
        addressString += ((String.isNotBlank(addressString) ? ' ' : '') + (String.isNotBlank(addr.CountryCode) ? addr.CountryCode : ''));
        return EncodingUtil.urlEncode(addressString, 'UTF-8');
    }
   /**
    * @description Custom validation exception
    **/
    public class CDdCoverageCheckSvcValidationException extends Exception {}

    /**
    * @description Generate the HTTP Request
    **/
    private static string createCoverageRequestURL( Address addr){
        String endpointPrefix  = '';
        if(ncList != null && !ncList.isEmpty()){
            endpointPrefix = ncList[0].endpoint;
        }

        endpointPrefix = endpointPrefix +'?pickup_address=' + getEncodedAddressString(addr);
        return endpointPrefix;
    }
}