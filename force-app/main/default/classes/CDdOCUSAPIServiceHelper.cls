/**
* @author Veera Maddukuri
* @date 2021-11
* @description OCUS Service class helper to prepare data for OCUS request and utility methods
* to process the data
*/

public with sharing class CDdOCUSAPIServiceHelper {

    /**
    * @author Veera Maddukuri
    * @date 2021-11
    * @description : Helper method to parse API response: RestAPIResponse -->  missionResponse
    */
    public static CDdRestJSONObj.OCUSMissionResponse handleMissionResponse(CDdRestJSONObj.RestAPIResponse response){
        CDdRestJSONObj.OCUSMissionResponse missionResponse = new CDdRestJSONObj.OCUSMissionResponse();
        try{
            if(response.status != 'No Content'){
                missionResponse = (CDdRestJSONObj.OCUSMissionResponse) JSON.deserialize(response.body, CDdRestJSONObj.OCUSMissionResponse.class);
            }
            if(CDdOCUSAPIConstants.STATUS_CODES_SUCCESS.contains(response.statusCode) || response?.status?.equalsIgnoreCase('OK')){
                missionResponse.isSuccess = true;
            }else{
                missionResponse.isSuccess = false;
            }
            missionResponse.statusCode = response.statusCode;
        }catch(Exception ex){
            missionResponse.isSuccess = false;
            missionResponse.message = ex.getMessage();
            System.debug('OCUS '+ex.getMessage());
        }
         return missionResponse;
    }

    /**
    * @author Veera Maddukuri
    * @date 2021-11
    * @description : Service request to create new Milestone/Assignment
    */
    public static CDdRestJSONObj.OCUSAPIRequest prepareOCUSMilestoneRequest(Case caseRec){
        CDdRestJSONObj.OCUSAPIRequest OCUSAPIRequest = new CDdRestJSONObj.OCUSAPIRequest();
        CDdRestJSONObj.OCUSData bookingRequest = new CDdRestJSONObj.OCUSData();

        //mission
        CDdRestJSONObj.Attributes missionAttri = new CDdRestJSONObj.Attributes();
        missionAttri.name = caseRec.Account.Name;
        missionAttri.internal_reference = caseRec.Account.Restaurant_ID__c;
        missionAttri.description = formatDescription(caseRec);
        missionAttri.approved_appointment = formatOCUSPhotoshootDate(caseRec);
        CDdAPICredentialData.CredentialWrapper cred;
        if(caseRec.Account.BillingCountryCode == 'US' && caseRec.Account.BillingStateCode == 'PR'){
            cred = CDdAPICredentialData.getCredentialWrapper(CDdAPICredentialData.OCUS_CATEGORY).get('OCUS_PR');
        } else if((caseRec.Opportunity_Name__r.Platform__c == 'Caviar' || caseRec.Opportunity_Name__r.Platform__c == 'Caviar and DoorDash') &&
                              (caseRec.Opportunity_Name__r.DRN__c == 'Ace' || caseRec.Opportunity_Name__r.DRN__c == 'King' || caseRec.Opportunity_Name__r.DRN__c == 'Ace of Spades' || caseRec.Opportunity_Name__r.DRN__c == 'King of Spades')){
            cred = CDdAPICredentialData.getCredentialWrapper(CDdAPICredentialData.OCUS_CATEGORY).get('OCUS_'+ caseRec.Account.BillingCountryCode + '_Caviar' );
        } else{
            cred = CDdAPICredentialData.getCredentialWrapper(CDdAPICredentialData.OCUS_CATEGORY).get('OCUS_'+caseRec.Account.BillingCountryCode);
        }

        if(CDdI18nUtility.isCountryCANADA(caseRec.Account.BillingCountryCode) || CDdI18nUtility.isCountryUSA(caseRec.Account.BillingCountryCode)) {
            missionAttri.organization_id = cred?.organization_id;
        }

        bookingRequest.type = 'mission';
        bookingRequest.attributes = missionAttri;

        //relationShips
        CDdRestJSONObj.Relationships relationship = new CDdRestJSONObj.Relationships();

        //Address
        CDdRestJSONObj.OCUSAddress addressMain = new CDdRestJSONObj.OCUSAddress();
        CDdRestJSONObj.AddressData addressData = new CDdRestJSONObj.AddressData();
        CDdRestJSONObj.AddressAttributes addressAttri = new CDdRestJSONObj.AddressAttributes();
        addressAttri.city = caseRec.Return_Shipping_Address_City__c;
        addressAttri.country_code = (caseRec.Account.BillingCountryCode == 'US' && caseRec.Account.BillingStateCode == 'PR') ? caseRec.Account.BillingStateCode : caseRec.Account.BillingCountryCode;
        addressAttri.street1 = caseRec.Return_Shipping_Address_Street__c;
        addressAttri.zip_code= caseRec.Return_Shipping_Address_Zip__c;
        addressAttri.street2 = caseRec.Return_Shipping_Address_Suite_Apt_etc__c;

        if(caseRec.Account.BillingState != null){
        addressAttri.state= caseRec.Account.BillingState;
        }
        if(caseRec.Account.Address2__c != null){
        addressAttri.street2= caseRec.Account.Address2__c;
        }

        addressData.type = 'address';
        addressData.attributes = addressAttri;

        addressMain.data = addressData;

        //Offers
        CDdRestJSONObj.Offers Offers = new CDdRestJSONObj.Offers();
        CDdRestJSONObj.OfferData offersData = new CDdRestJSONObj.OfferData();
        offersData.type = 'offer';
        offersData.id = cred?.offerId;

        Offers.data = new List<CDdRestJSONObj.OfferData>{offersData};

        //Contacts
        CDdRestJSONObj.Contacts contacts = new CDdRestJSONObj.Contacts();
        CDdRestJSONObj.ContactData contactData = new CDdRestJSONObj.ContactData();
        CDdRestJSONObj.ContactAttributes contactAttri = new CDdRestJSONObj.ContactAttributes();

        contactAttri.firstname = caseRec.Contact.Firstname;
        contactAttri.lastname = caseRec.Contact.Lastname;
        contactAttri.email = caseRec.ContactEmail;

        if(CDdI18nUtility.isCountryCANADA(caseRec.Account.BillingCountryCode)) {
            contactAttri.phone_1 = CDdI18nUtility.formatPhoneNumberCanadaForOCUS(caseRec);
        } else {
            contactAttri.phone_1 = caseRec.ContactPhone;
        }

        contactData.type = 'contact';
        contactData.attributes = contactAttri;

        contacts.data = new List<CDdRestJSONObj.ContactData>{contactData};

        relationship.address = addressMain;
        relationship.offers = Offers;
        relationship.contacts = contacts;
         bookingRequest.relationships = relationship;

        OCUSAPIRequest.data = bookingRequest;

        return OCUSAPIRequest;
    }

     /**
    * @author Veera Maddukuri
    * @date 2021-11
    * @description : Service request to update Milestone/Assignment
    */
    public static CDdRestJSONObj.OCUSAPIRequest prepareOCUSMilestoneRequestForUpdate(Case caseRec){
        CDdRestJSONObj.OCUSAPIRequest OCUSAPIRequest = new CDdRestJSONObj.OCUSAPIRequest();
        CDdRestJSONObj.OCUSData bookingRequest = new CDdRestJSONObj.OCUSData();

        //mission
        CDdRestJSONObj.Attributes missionAttri = new CDdRestJSONObj.Attributes();
        missionAttri.description = formatDescription(caseRec);
        bookingRequest.type = 'mission';
        bookingRequest.attributes = missionAttri;
        bookingRequest.id = caseRec.Kodakit_Job_Id__c;
        OCUSAPIRequest.data = bookingRequest;
        return OCUSAPIRequest;
    }

    //@Todo[Veera]: Keeping this methos as we have to include new field in the next release
    private static String formatDescription(Case caseRec){
        String decription = CDdCoreConstants.BLANK_STRING;
        if(String.isNotBlank(caseRec.Photo_Review_Notes__c)) {
            decription = decription + 'Photo Review Notes: '+caseRec.Photo_Review_Notes__c;
        }
        if(String.isNotBlank(caseRec.Menu_Preview_Links__c)) {
            decription = (String.isBlank(decription) ? CDdCoreConstants.BLANK_STRING : decription + ',\n') + 'Menu Link: ' + caseRec.Menu_Preview_Links__c;
        }
        return decription;
    }

    /**
     * @author      Swedhaa Sri M
     * @date        Feb 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-42481 , https://doordash.atlassian.net/browse/BASD-50050
     * @description Format Case's Photoshoot Date & Time to ISO 8601 format
     */
    public static String formatOCUSPhotoshootDate(Case caseRec){
        String photoshootDateTime = CDdCoreConstants.BLANK_STRING;
        String timeZoneIdentifier = caseRec.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c != null ? String.valueOf(caseRec.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c*0.1).substringBefore('.')
                                    + String.valueOf(caseRec.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c*0.1).substringAfter('.') + ':00' : CDdCoreConstants.BLANK_STRING ;
        if(caseRec.Photoshoot_Date__c != null && caseRec.Photoshoot_Time__c != null){
            String timeVal = String.valueOf(caseRec.Photoshoot_Time__c);
            Date photoDate = caseRec.Photoshoot_Date__c;
            String dateVal = photoDate.format();

            if(timeZoneIdentifier != ''){
                               photoshootDateTime = DateTime.parse(dateVal+' '+ timeVal).format('yyyy-MM-dd\'T\'HH:mm:ss') + timeZoneIdentifier;
            }
            else{

                photoshootDateTime = getISODateTimeFormat(dateVal, timeVal);
            }

        }
        return photoshootDateTime;
    }

    // @description : Get datetime in ISO 8601 format
    public static String getISODateTimeFormat(String dateVal, String timeVal){
        return DateTime.parse(dateVal+' '+ timeVal).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
    }

     // @description : parse ISO 8601 format into date and Time (AM or PM)
    public static List<String> getDateTimeFromISOFormat(String dateTimeInISO, String timezone){
        if(String.isBlank(timezone)){
            timeZone = 'America/Los_Angeles';
        }

        dateTimeInISO = '"' + dateTimeInISO + '"';
        Datetime dt = (DateTime)JSON.deserialize(dateTimeInISO,DateTime.class);
        String strTimeInAMorPM = dt.format('h:mm a',timezone);
        String dateVal = String.valueOf(dt.date());
        return new List<String>{dateVal,strTimeInAMorPM};
    }
}