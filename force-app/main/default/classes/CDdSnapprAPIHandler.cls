/**
 * @author Jeegar Brahmakshatriya
 * @date 2020-02
 * 
 * @description BZAP-5898 This class does an API callout to Snappr to create a photoshoot booking for Snappr Photoshoot Porvider = 'Snappr'
 * 
 * To trigger the errors :
    Be in sandbox mode. ( https://sandbox.snappr.co api domain and use the sandbox_key)
    Send all parameters required to create a booking. ( POST /booking with a valid payload)
    Send latitude = 42.42 and longitude = -42.42  (This is the middle of the Atlantic ocean :sweat_smile:)
    And set duration according to the error they want to trigger
    Duration: 60 -> Error: NotAvailable
    Duration: 120 -> Error: NoCoverage
    Duration: 180 -> Error: InsufficientCredits
    Duration: 240 -> Error: RateLimit

 */

 


public with sharing class CDdSnapprAPIHandler {
    @testVisible private static Snappr_API_Setting__mdt regionalSetting; 
   @testVisible public static Map<String,Snappr_API_Setting__mdt> regionKeyMap {
        get{
            if(regionKeyMap == null){
                regionKeyMap = new Map<String,Snappr_API_Setting__mdt>();
                List<Snappr_API_Setting__mdt> snapprApiSetiingsLst = Snappr_API_Setting__mdt.getAll().values();
                   for(Snappr_API_Setting__mdt setting : snapprApiSetiingsLst){
                        regionKeyMap.put(setting.Region__c, setting);
                        } 
                }
            return regionKeyMap;
         }
        set;
    }
        
   
    /* 
     * Returns a list of cases
     * @param caseIdSet     Set of Case Ids. Ensuer that the caseIdSet does not have any other type of cases, it should ONLY contain
     *                      Photoshoot Cases that have Photo_Provider__c = 'Snappr'
     */
    private static List<Case> getCases(Set<Id> caseIdSet) {
        List<Case> caseList = [SELECT Id, Subject, Account.Name, Account.BillingStreet, Account.BillingCity, 
                                    Account.BillingState, Account.BillingPostalCode, Account.BillingCountryCode, Account_Address__c, 
                                    Address_Latitude__c, Address_Longitude__c, Address_UTC_Offset__c, Photo_Provider__c,
                                    Photoshoot_Date__c, Photoshoot_Time__c, Contact.Name, ContactPhone, ContactEmail, Contact.Firstname, 
                                    Contact.LastName, AccountId, Account.BillingStateCode
                                FROM Case
                                WHERE Id in :caseIdSet
                                FOR UPDATE];
        return caseList; 
    }


    @future(callout=true)
    public static void createPhotoshootAsync(Set<id> caseIdSet) {
        List<Case> caseList = getCases(caseIdSet);
        createPhotoshootOnSnappr(caseList);
    }

    /* 
     * Check if this is running in an async context or not. If it is async context, do not call future. 
     * If it is async, call future method. 
     * NOTE: Triggers fired in a batch context are not considered async so do batch and scheduled context are not added here. 
     * @param caseIdSet     Set of Case Ids. Ensuer that the caseIdSet does not have any other type of cases, it should ONLY contain
     *                      Photoshoot Cases that have Photo_Provider__c = 'Snappr'
     */
    public static void createPhotoshoot(Set<Id> caseIdSet) {
        if (System.isFuture() || System.isQueueable()) {
            createPhotoshootOnSnappr(getCases(caseIdSet));
        } else {
            createPhotoshootAsync(caseIdSet);
        }
    }

    /*
     * Creates a photoshoot booking on Snappr portal. 
     * Uses different portal endpoints for different regions. The Mapping is stored in Custom Metadata Snappr_API_Setting__mdt
     * Authentication is stored in Named Credentials. Password in the named credential should be 'Bearer <APIToken>'. 
     * If the photoshoot case has a Photoshoot Date Time populated, this method tries to create a booking with the provided date time, 
     *      If the provided photoshoot date time is not availabe, create a booking without photoshoot date time. Snappr will coordinate
     *      with the merchant to schedule a booking. 
     * If Snappr does not provide coverage for the merchant's region, Do NOT create a booking on Snappr, instad send an email to merchant
     *      and Snappr using template stating the Merchant is out of coverage area, and Snappr will schedule the photoshoot within 2 weeks. 
     * Update the case with Success, failure. 
     * 
     * @params caseList list of Photoshoot Cases where Photo_Provider__c = 'Snappr'
     * 
     */
    public static void createPhotoshootOnSnappr(List<Case> caseList) {
        CDdRestJSONObj.SnapprErrorResponse errorResponse;

        List<Case> casesToUpdate = new List<Case>(); 
        CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
        DateTime photoshootDateTime; 
        String photoShootDateTimeStr; 
        CDdRestJSONObj.SnapprBookingResponse bookingResponse; 
        CDdRestJSONObj.RestAPIResponse response;
       
        for(Case currCase : caseList){
            try{
                if(String.isBlank(currCase.Account.BillingCountryCode)) {
                    
                    // Do not create a Photoshoot Booking for case that does not have a valid address. 
                    currCase.Kodakit_Error__c = 'Invalid Address';
                    casesToUpdate.add(currCase);
                    
                } else if(regionKeyMap.containsKey(currCase.Account.BillingCountryCode)) {
                    
                    // Puerto Rico is a special case, it has its own snappr portal like Canada or Australia.
                        if(currCase.Account.BillingCountryCode == 'US' && currCase.Account.BillingStateCode == 'PR') {
                           regionalSetting= regionKeyMap.get('PR');
                        } else {
                          regionalSetting= regionKeyMap.get(currCase.Account.BillingCountryCode);
                                
                        }
                  

                    // check if Photoshoot_Date__c and Photoshoot_Time__c are populated if yes, calculate datetime, else null; 

                    if(currCase.Photoshoot_Date__c == null || currCase.Photoshoot_Time__c == null) {
                        photoshootDateTime = null; 
                        photoshootDateTimeStr = null; 
                    } else {
                        try {
                            photoshootDateTime = DateTime.newInstance(currCase.Photoshoot_Date__c, 
                                CDdUtilities.stringAMPMToTime(currCase.Photoshoot_Time__c));
                                photoShootDateTimeStr = JSON.serialize(photoshootDateTime);
                                photoShootDateTimeStr = photoShootDateTimeStr.replace('"','');
                        } catch (CDdUtilities.StringAMPMToTimeException ex) {
                            // if there is an exception while converting String to Time, create a photoshoot without date time so that 
                            // merchant can pick the date time that is most conveneient to them. 

                            photoshootDateTime = null;
                            photoshootDateTimeStr = null; 
                        }
                    }
                    
                    response = bookPhotoshoot(currCase, photoshootDateTimeStr, connector);
                    System.debug('Photoshoot Response Body = ' + response.body); 
                    System.debug('Photoshoot Status Code = ' + response.statusCode); 
                    // IF successful update the case
                    if(response.statusCode == 201) {
                        currCase = processSuccessfulResponse(response, currCase);

                    } else {
                        // check the error code. If it is notAvailable, create new booking wihtout date time so that merchant can pick 
                        // the next available date time on the Snappr portal. Snappr will send an email to Merchant to select a date time. 
                        errorResponse = (CDdRestJSONObj.SnapprErrorResponse) JSON.deserialize(
                            response.body, CDdRestJSONObj.SnapprErrorResponse.class);
                        if(errorResponse.code == 'NotAvailable') {
                            response = bookPhotoshoot(currCase, null, connector);
                            if(response.statusCode == 201) {
                                currCase = processSuccessfulResponse(response, currCase);
                            } else {
                                errorResponse = (CDdRestJSONObj.SnapprErrorResponse) JSON.deserialize(
                                    response.body, CDdRestJSONObj.SnapprErrorResponse.class);
                                currCase = processUncessfulResponse(errorResponse, currCase);
                            }
                        } else {
                            errorResponse = (CDdRestJSONObj.SnapprErrorResponse) JSON.deserialize(
                                response.body, CDdRestJSONObj.SnapprErrorResponse.class);
                            currCase = processUncessfulResponse(errorResponse, currCase);
                        }
                    }
                    casesToUpdate.add(currCase);
                }

                
                // set the regional setting to Null so that if a new country is onboarded but the corresponding named credential for new   
                // snappr portal is not updated, it should not create an booking on the last regional setting. 

                regionalSetting = null; 
            } catch (Exception e){
                throw e; 
            }
        }

        List<Database.SaveResult> results = Database.update(casesToUpdate, false);
        for (Database.SaveResult result : results) {
          if (!result.isSuccess()){
            for (Database.Error err : result.getErrors()){
              System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
            }
          }
        }
    //log error details
    CDdErrorUtilities.publishException('Case', 'PhotoshootCaseSnapperAPICallOut', results);
}

    /*
     * Process successful case. 
     * Update the case fields and populate BookingResponse Unique ID on hte Kodakit_Job_Id__c field. 
     */
    public static Case processSuccessfulResponse(CDdRestJSONObj.RestAPIResponse response, Case photoshootCase) { 

        CDdRestJSONObj.SnapprBookingResponse bookingResponse;
        bookingResponse = (CDdRestJSONObj.SnapprBookingResponse) JSON.deserialize(response.body, 
                            CDdRestJSONObj.SnapprBookingResponse.class);
        photoshootCase.Kodakit_Job_Id__c = bookingResponse.uid;
        photoshootCase.Kodakit_Event__c = 'Booking Created';
        photoshootCase.Kodakit_URL__c = regionalSetting.Bookings_URL_Prefix__c + bookingResponse.uid;
        photoshootCase.Kodakit_Pictures_URL__c = regionalSetting.Bookings_URL_Prefix__c + bookingResponse.uid 
                + regionalSetting.Gallery_URL_PostFix__c;
        photoshootCase.Kodakit_Error__c = null;
        
        return photoshootCase;
    }

    /*
     * Process Unsuccessful Response. 
     * Update Case with the error message and if the Error message was No Coverage, send an email to Merchant and Snappr. 
     */
    public static Case processUncessfulResponse(CDdRestJSONObj.SnapprErrorResponse errorResponse, Case photoshootCase) {
        List<Messaging.SingleEmailMessage> emailMessages; 
        photoshootCase.Kodakit_Error__c = 'Error Code = ' +  errorResponse.Code;
        if(errorResponse.errors != null && errorResponse.errors.size() > 0) {
            photoshootCase.Kodakit_Error__c += '. Error Message =  ' + errorResponse.errors[0]; 
        }
        photoshootCase.Kodakit_Event__c = errorResponse.Code; 
        if(errorResponse.code == 'NoCoverage') {
            emailMessages = createEmailMessages(photoshootCase);
            if(emailMessages != null && emailMessages.size() > 0 ) {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailMessages); 
                for(Messaging.SendEmailResult result : results) {
                    if(!result.isSuccess()) {
                        photoshootCase.Kodakit_Error__c += '. Error Sending Email ';
                        for(Messaging.sendEmailError error : result.getErrors()) {
                            photoshootCase.Kodakit_Error__c += '. Fields: ' + error.getFields() + ', Message: ' + error.getMessage(); 
                        }
                    }
                }
            }
        }
        return photoshootCase;
    }

    /*
     * Create a booking request and make a callout to snappr. 
     */

    public static CDdRestJSONObj.RestAPIResponse bookPhotoshoot(Case photoshootCase, String photoShootDateTime, 
            CDdRESTConnectorSvc connector) {
        CDdRestJSONObj.SnapprBookingRequest bookingRequest = new CDdRestJSONObj.SnapprBookingRequest(); 
        bookingRequest.title = photoshootCase.Account.Name + ' - ' + photoshootCase.Account.BillingCity; 
        bookingRequest.latitude = photoshootCase.Address_Latitude__c;
        bookingRequest.longitude = photoshootCase.Address_Longitude__c;
        bookingRequest.duration = Integer.valueOf(regionalSetting.Duration__c); 
        bookingRequest.shoottype = regionalSetting.Shoot_Type__c;
        bookingRequest.start_at = photoshootDateTime; 
        bookingRequest.location_notes = photoshootCase.Account_Address__c;
        bookingRequest.address = photoshootCase.Account_Address__c;
        bookingRequest.customer_company = photoshootCase.Account.Name;
        bookingRequest.internal_id = photoshootCase.Id;
        bookingRequest.customer_firstname = photoshootCase.Contact.Firstname; 
        bookingRequest.customer_surname = photoshootCase.Contact.LastName; 
        bookingRequest.customer_email = photoshootCase.ContactEmail; 
        bookingRequest.customer_mobilephone = photoshootCase.ContactPhone; 
        System.debug('><><> ' + JSON.serialize(bookingRequest,false)); 
        
        CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI('POST', JSON.serialize(bookingRequest,false), 
            null, null, regionalSetting.Bookings_EndPoint__c, null , regionalSetting.Named_Credential__c); 
        return response; 
    }

    /*
     * Create an email message when Snappr does not cover the merchant's region. 
     * 
     */
    public static List<Messaging.SingleEmailMessage> createEmailMessages(Case photoshootCase) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage(); 
       
        //Send email to Merchant that snappr does not cover this region. 
        emailMessage.setTargetObjectId(photoshootCase.ContactId);
        emailMessage.setTemplateId(regionalSetting.Merchant_Email_Template_Id__c); 
        emailMessage.setWhatId(photoshootCase.Id); 
        emailMessage.setOrgWideEmailAddressId(Id.valueOf(regionalSetting.Org_Wide_Email_Address_Id__c));
        emailMessages.add(emailMessage);
        
        // Send email to Snappr that they do not cover this region. 
        // Need to associate this email message with the Contact and Account so that template can populate the fields 
        // from contact and Account. 
        emailMessage = new Messaging.SingleEmailMessage(); 
        system.debug('........'+regionalSetting.Snappr_Support_Contact_Id__c);
        emailMessage.setTargetObjectId(Id.valueOf(regionalSetting.Snappr_Support_Contact_Id__c));
        // emailMessage.setToAddresses(snapprSupportEmailList);
        emailMessage.setTemplateId(regionalSetting.Snappr_Email_Template_Id__c); 
        emailMessage.setOrgWideEmailAddressId(Id.valueOf(regionalSetting.Org_Wide_Email_Address_Id__c));
        emailMessage.setWhatId(photoshootCase.AccountId); 
        emailMessages.add(emailMessage);

        return emailMessages;
    }
    
}