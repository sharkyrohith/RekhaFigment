/**
* @author: Ed
* @date: 2019-03-25
* @description Service class for callouts to /v2/deliveries/check_addresses
*/
public class CDdCoverageCheckSvc {
    public static HttpCalloutMock mock = null;
    static final String calloutErrorMsg = 'Something went wrong! Please contact your administrator. ';
    private static final String INVALID_ADDRESS_ERROR_MSG = 'Please enter a valid address. Street and Postal Code are required fields';

    public static Boolean checkAcctCoverage(Account acct) {
        List<String> errorMessages = new List<String>();
        acct = [SELECT Id, BillingAddress
                FROM Account
                WHERE Id = :acct.Id];
        CDdRestJSONObj.coverageCheckResponse body;
        String requestURL = createCoverageRequestURL(acct.BillingAddress );
        try {
            if (acct.BillingAddress==null || String.isBlank(acct.BillingAddress.getStreet()) || String.isBlank(acct.BillingAddress.getPostalCode())) {
                throw new CDdCoverageCheckSvcValidationException(INVALID_ADDRESS_ERROR_MSG);
            }

            body = checkCoverage(acct.BillingAddress);

            if (body == null || body.valid == null) {
                throwCalloutException();
            } else if (body.valid) {
                acct.In_Coverage__c = 'Yes';
            } else {
                acct.In_Coverage__c = 'No';
            }
            
            if (body.starting_point != null){
            	acct.Starting_Point_ID__c = Integer.valueOf(body.starting_point);
            }
            
            if (body.starting_point_name != null){
            	acct.Starting_Point__c = body.starting_point_name;
            }
            
            Database.SaveResult sResults = Database.update(acct, false);

            errorMessages = CDdErrorUtilities.processSaveResults(new List<Database.SaveResult> { sResults });

        } catch (CDdCoverageCheckSvcValidationException e) {
            //acct.addError(e.getMessage());
            acct.addError(e.getMessage() + '<br/>Request= '+ requestURL + '<br/>Response= '+JSON.serialize(body) );
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createHTTPApexLogs(requestURL, JSON.serialize(body),acct.id, errorMessages, 
                                                 'CDdCoverageCheckSvc', 'checkAcctCoverage', LoggingLevel.ERROR);
            return false;
        } catch (Exception e) {
            String resError = '';
            if(body!=null)
                resError = body.errors != null && body.errors.pickup_address != null && body.errors.pickup_address.size() > 0 ? body.errors.pickup_address[0] : body.pickup_address ;
            
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
                CDdRestJSONObj.coverageCheckResponse body = checkCoverage(acc.BillingAddress);

                if (body == null) {
                    throwCalloutException();
                } else if (body.valid) {
                    acc.In_Coverage__c = 'Yes';
                } else {
                    acc.In_Coverage__c = 'No';
                }
                if (body.starting_point != null){
                    acc.Starting_Point_ID__c = Integer.valueOf(body.starting_point);
                }
                
                if (body.starting_point_name != null){
                    acc.Starting_Point__c = body.starting_point_name;
                }
                updateAccts.add(acc);
            } catch (Exception e) {
                System.debug('Error [' + acc.Id + ']: ' + e);
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
        String requestURL = createCoverageRequestURL(lead.Address);
        CDdRestJSONObj.coverageCheckResponse body;
        try {
            if (lead.Address==null || String.isBlank(lead.Address.getStreet()) || String.isBlank(lead.Address.getPostalCode())) {
                throw new CDdCoverageCheckSvcValidationException(INVALID_ADDRESS_ERROR_MSG);
            }

            body = checkCoverage(lead.Address);
            
            if (body == null || body.valid == null) {
                throwCalloutException();
            } else if (body.valid) {
                lead.In_Coverage__c = 'Yes';
            } else {
                lead.In_Coverage__c = 'No';
            }
            
            if (body.starting_point != null){
            	lead.Starting_Point_ID__c = Integer.valueOf(body.starting_point);
            }
            
            if (body.starting_point_name != null){
            	lead.Starting_Point__c = body.starting_point_name;
            }
            
            Database.SaveResult sResults = Database.update(lead, false);
            errorMessages = CDdErrorUtilities.processSaveResults(new List<Database.SaveResult> { sResults });
            //return true;
        } catch (CDdCoverageCheckSvcValidationException e) {
            lead.addError(calloutErrorMsg + e +'<br/>Request= '+ requestURL + '<br/>Response= '+JSON.serialize(body) );
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createHTTPApexLogs(requestURL, JSON.serialize(body),lead.id, errorMessages, 
                                                 'CDdCoverageCheckSvc', 'checkLeadCoverage', LoggingLevel.ERROR);
            return false;            
        } catch (Exception e) {
            String resError = '';
            if(body!=null)
                 resError = body.errors != null && body.errors.pickup_address != null && body.errors.pickup_address.size() > 0 ? body.errors.pickup_address[0] : body.pickup_address ;
            
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
        List<Lead> updateLeads = new List<Lead>();
        List<Lead> leads =    [SELECT Id, Address
                               FROM Lead
                               WHERE Id in :leadIds
                               AND Street != null
                               AND PostalCode != null];

        for (Lead ld : leads) {
            try {
                CDdRestJSONObj.coverageCheckResponse body = checkCoverage(ld.Address);
                
                System.debug('body:' + body);

                if (body == null) {
                    throwCalloutException();
                } else if (body.valid) {
                    ld.In_Coverage__c = 'Yes';
                } else {
                    ld.In_Coverage__c = 'No';
                }
                
                if (body.starting_point != null){
                    ld.Starting_Point_ID__c = Integer.valueOf(body.starting_point);
                }
                
                if (body.starting_point_name != null){
                    ld.Starting_Point__c = body.starting_point_name;
                }
                updateLeads.add(ld);
            } catch (Exception e) {
                System.debug('Error [' + ld.Id + ']: ' + e);
            }
        }

        Database.update(updateLeads, false);
    }

    private static CDdRestJSONObj.coverageCheckResponse checkCoverage(Address addr) {
        if (addr == null) return null;
        
        CDdRESTConnectorSvc restSvc = new CDdRESTConnectorSvc();
        CDdRestJSONObj.RestAPIResponse res = restSvc.getDoorstep('/v2/deliveries/check_addresses', '/?pickup_address=' + getEncodedAddressString(addr), false);
        System.debug('res.Body:' + res.body);
        return (CDdRestJSONObj.coverageCheckResponse) JSON.deserialize(res.body, CDdRestJSONObj.coverageCheckResponse.class);
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
        // addressString += ((String.isNotBlank(addressString) ? ' ' : '') + (String.isNotBlank(addr.PostalCode) ? 
        //                                                                         addr.PostalCode.SubString(0,5) : ''));        
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
        vCS__c apiSettings = vCS__c.getInstance();	
        String endpointPrefix = apiSettings.UseDSJSandbox__c ? apiSettings.DoorstepSandboxEndpointPrefix__c : apiSettings.DoorstepEndpointPrefix__c;	
        endpointPrefix += '/v2/deliveries/check_addresses'+'/?pickup_address=' + getEncodedAddressString(addr);	
        return endpointPrefix;	
    }
}