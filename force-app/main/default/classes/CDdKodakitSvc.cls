public class CDdKodakitSvc {
    public static final vCS__c SETTINGS = vCS__c.getInstance();
    
    @future(callout=true)
    public static void createPhotoshoot(List<Id> caseIdList) {
        CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
        List<Case> casesToUpdate = new List<Case>();
        String kodakitAPIToken;
        
        List<Case> caseList =   [SELECT 
                                    Id, Subject, Account.Name, Account.BillingStreet, Account.BillingCity, 
                                    Account.BillingState, Account.BillingPostalCode, Account.BillingCountryCode, 
                                    Address_Latitude__c, Address_Longitude__c, Address_UTC_Offset__c, Photo_Provider__c,
                                    Photoshoot_Date__c, Photoshoot_Time__c, Contact.Name, ContactPhone, ContactEmail
                                FROM Case
                                WHERE Id in :caseIdList
                                AND Photo_Provider__c = 'Kodakit'];
        
        for (Case c : caseList) {    
            try {
                CDdRestJSONObj.KodakitRequest request = new CDdRestJSONObj.KodakitRequest();
                request.businessName = c.Account.Name;
                request.lat = String.valueOf(c.Address_Latitude__c);
                request.lng = String.valueOf(c.Address_Longitude__c);
                request.address = c.Account.BillingStreet + ', ' +  c.Account.BillingCity + ', ' + c.Account.BillingState + ' ' + c.Account.BillingPostalCode;
                request.country = c.Account.BillingCountryCode;

                if (request.country == 'US') {
                    request.bookingTemplate = SETTINGS.KodakitAPIBookingTemplateUS__c;
                    kodakitAPIToken = SETTINGS.KodakitAPITokenUS__c;
                } else if (request.country == 'CA') {
                    request.bookingTemplate = SETTINGS.KodakitAPIBookingTemplateCA__c;
                    kodakitAPIToken = SETTINGS.KodakitAPITokenCA__c;
                }

                Date photoDate = c.Photoshoot_Date__c;
                boolean isAM = c.Photoshoot_Time__c.split(' ')[1] == 'AM';
                // Time is string like '5:00 PM'. Parse then apply offset
                List<String> hourMinute = c.Photoshoot_Time__c.split(' ')[0].split(':');
                DateTime photoDateTime = DateTime.newInstance(photoDate.year(), photoDate.month(), photoDate.day(), 
                                                            Integer.valueOf(hourMinute[0]) + (isAM ? 0 : 12), Integer.valueOf(hourMinute[1]), 0);
                Integer hourOffset = Integer.valueOf(c.Address_UTC_Offset__c);
                String offset = (hourOffset < 0 ? '-' : '+') + (hourOffset >= 10 || hourOffset <= 10 ? '0' : '') + String.valueOf(Math.abs(hourOffset)) + ':00';
                // formatGMT doesn't work because the Kodakit API doesn't accept it. Offset with Z or +-00:00 won't work
                request.bookingDateTime	= photoDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'' + offset + '\'');
                request.contactName = c.Contact.Name;
                request.contactNumber = c.ContactPhone.replaceAll('\\D','');
                request.contactEmail = c.ContactEmail;
                request.listingId = c.Id;

                CDdRestJSONObj.RestAPIResponse kodakitRes = connector.postRESTAPI(JSON.serialize(request, true).replace('\"lng\"', '\"long\"'), 
                                                                    'Bearer ' + kodakitAPIToken ,SETTINGS.KodakitAPIEndpointURL__c + '/photoshoots');
                                                                    
                CDdRestJSONObj.KodakitResponse kodakit = (CDdRestJSONObj.KodakitResponse) JSON.deserialize(kodakitRes.body, CDdRestJSONObj.KodakitResponse.class);
                if (kodakit.status.equals('ok')) {
                    c.Kodakit_Job_ID__c = String.valueOf(kodakit.jobId);
                    c.Kodakit_URL__c = 'https://www.kodakit.com/orders/details/' + c.Kodakit_Job_ID__c;
                    c.Kodakit_Event__c = 'OK';
                    c.Kodakit_Error__c = '';
                } else {
                    c.Kodakit_Error__c = 'ERROR';               
                    c.Kodakit_Event__c = kodakit.status;
                }
            } catch (Exception e) {
                c.Kodakit_Event__c = 'ERROR';
                c.Kodakit_Error__c = 'ERROR (Contact Admin): ' + e.getMessage();
            }
            casesToUpdate.add(c);
        }
        try {
            List<Database.SaveResult> results = Database.update(casesToUpdate);
        } catch (Exception e){
            System.Debug(e.getMessage());
        } 	
    }
}