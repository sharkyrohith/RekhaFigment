/**
* @author Veera Maddukuri
* @date 2021-11
* @description : To handle requests from Case trigger and webhook class to update Case
*/
public with sharing class CDdOCUSAPIHandler {

    public static Boolean isExecuted = false;
    public static Integer maxRetryCount = 3;
    public static Map<String,CDdAPICredentialData.CredentialWrapper> credentialData = CDdAPICredentialData.getCredentialWrapper(CDdAPICredentialData.OCUS_CATEGORY);
    public static final Id OPPORTUNITY_MARKETPLACE_RT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ML_Inside_Sales').getRecordTypeId();
    public static final String OCUSInvalidDataErrorMessage  = CDdNameValuePairHelper.getTextValue('OCUSInvalidDataError');
    public static final String OCUSPhotoshootDateErrorMessage  = CDdNameValuePairHelper.getTextValue('OCUSPhotoshootDateError');
    /*
    *Description: Called from trigger to create or Update OCUS Milestone/Assignment
    * @param   caseIdSet           Set<Id>
    * @param   isCreatePhotoshoot  Boolean
    */
    public static void handleOCUSPhotoshoot(Set<Id> caseIdSet,Boolean isCreatePhotoshoot) {
        if(isExecuted){
            return;
        }
        isExecuted = true;
        if (System.isFuture() || System.isQueueable()) {
            if(isCreatePhotoshoot){
                createOCUSPhotoshoot(new List<Id>(caseIdSet));
            }else{
                updateSalesNotesOnOCUS(caseIdSet);
            }
        } else {
            if(isCreatePhotoshoot){
                createPhotoshootAsync(caseIdSet);
            }else{
                updatePhotoshootAsync(caseIdSet);
            }
        }
    }

    @future(callout=true)
    public static void createPhotoshootAsync(Set<id> caseIdSet) {
        createOCUSPhotoshoot(new List<Id>(caseIdSet));
    }

    @future(callout=true)
    public static void updatePhotoshootAsync(Set<id> caseIdSet) {
        updateSalesNotesOnOCUS(caseIdSet);
    }

    @AuraEnabled
    public static void createOCUSPhotoshoot(List<Id> caseIdSet){
        List<Case> caseList = getCases(new Set<Id>(caseIdSet));
        for(Case caseRec : caseList){
            try {
                //BASD-42481 -Opportunity, Menu Preview Links on Case are required to make callout to OCUS.
                //Either both Photoshoot Date & Time on Case should be filled or shall be left blank to make callout to OCUS.
                if(caseRec.Opportunity_Name__c != null && caseRec.Menu_Preview_Links__c != null
                   &&((caseRec.Photoshoot_Date__c == null && caseRec.Photoshoot_Time__c == null)
                   ||(caseRec.Photoshoot_Date__c != null && caseRec.Photoshoot_Time__c != null))){
                    CDdRestJSONObj.OCUSAPIRequest bookingRequest = CDdOCUSAPIServiceHelper.prepareOCUSMilestoneRequest(caseRec);
                    createOCUSMilestoneAPI(bookingRequest,caseRec);
                }
             }catch(Exception ex){
                System.debug(ex.getMessage());
            }
        }
    }

    /*
    *Description: Create new OCUS Milestone
    * @param   bookingRequest   CDdRestJSONObj.OCUSAPIRequest
    * @param   caseRec          Case
    */
    public static void createOCUSMilestoneAPI(CDdRestJSONObj.OCUSAPIRequest bookingRequest,Case caseRec){
        List<String> errorList = new List<String>();
        String missionId;
        try{
            //getting Authorization details from custom metadata based on Country code
            CDdAPICredentialData.CredentialWrapper cred = getCredentialWrapper(caseRec);

            if(cred != null){
                //OCUS API request for POST/Create Milestone call
                CDdRestJSONObj.OCUSMissionResponse missionResponse = CDdOCUSAPIService.postOCUSMilestoneAPI(bookingRequest,cred.namedCredential, cred.postSuffix);
                if(missionResponse.isSuccess){
                    if(missionResponse?.data?.id != null)
                        missionId = missionResponse.data.id;
                    else
                        errorList.add('No Mission Id returned');
                }else{
                    if(maxRetryCount>0 && CDdOCUSAPIConstants.STATUS_CODES_SERVER_ERROR.contains(missionResponse.statusCode)){
                        maxRetryCount--;
                        createOCUSMilestoneAPI(bookingRequest,caseRec);
                        return;
                    }
                    errorList.add(missionResponse.message);
                    for(List<String> errors : missionResponse.errors.values()){
                        errorList.addAll(errors);
                    }
                }
            }else{
                errorList.add('NP API Credentials');
            }
        }catch(Exception ex){
            errorList.add(ex.getMessage());
        }finally{
            updateCaseWithMissionData(missionId,caseRec,errorList,true);
        }
    }

    /*
    *Description: Case will be updated with MileStone Id or errors during OCUS Assignment creation or updatation
    * @param   missionId            String
    * @param   caseRec              Case
    * @param   errorList            List<String>
    * @param   isAssignmentCreation boolean        Variable to check if it's OCUS assigment creation
    */
    public static void updateCaseWithMissionData(String missionId,Case caseRec,List<String> errorList, boolean isAssignmentCreation){
        Map<String,Id> queueNameVsIdMap = getQueuesByDeveloperName(CDdOCUSAPIConstants.queueDeveloperNames);
        try{
            if(String.isNotBlank(missionId)){
                caseRec.Kodakit_Job_Id__c = missionId;
                caseRec.Status = 'Open';
                caseRec.Kodakit_Event__c = 'ORDERED';
                caseRec.Error_Exception__c = '';
                caseRec.Kodakit_Error__c = '';
                if(isAssignmentCreation){
                    switch on caseRec.Account.BillingCountryCode {
                        when 'JP' {
                            caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_Japan_OCUS');
                        }
                        when 'DE' {
                            caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_Germany_OCUS');
                        }
                        when 'CA' {
                            caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_Canada_OCUS');
                        }
                        when 'US' {
                            if(caseRec.Account.BillingStateCode == 'PR'){
                                caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_PR_OCUS');
                            } else if((caseRec.Opportunity_Name__r.Platform__c == 'Caviar' || caseRec.Opportunity_Name__r.Platform__c == 'Caviar and DoorDash') &&
                              (caseRec.Opportunity_Name__r.DRN__c == 'Ace' || caseRec.Opportunity_Name__r.DRN__c == 'King' || caseRec.Opportunity_Name__r.DRN__c == 'Ace of Spades' || caseRec.Opportunity_Name__r.DRN__c == 'King of Spades')){
                                caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_caviar_US_OCUS');
                            } else {
                                caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_US_OCUS');
                            }
                        }
                    }
                }
            }
            if(errorList != null && errorList.size() > 0){
                caseRec.Error_Exception__c = System.now()+' \n'+string.join(errorList,'\n');
                caseRec.Kodakit_Error__c = string.join(errorList,'\n');
                if(isAssignmentCreation){
                    switch on caseRec.Account.BillingCountryCode {
                        when 'JP' {
                            caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_Japan');
                        }
                        when 'DE' {
                            caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_Germany');
                        }
                        when 'CA' {
                            caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_Canada');
                        }
                        when 'US' {
                            if(caseRec.Account.BillingStateCode == 'PR'){
                                caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_PR');
                            } else if((caseRec.Opportunity_Name__r.Platform__c == 'Caviar' || caseRec.Opportunity_Name__r.Platform__c == 'Caviar and DoorDash') &&
                              (caseRec.Opportunity_Name__r.DRN__c == 'Ace' || caseRec.Opportunity_Name__r.DRN__c == 'King' || caseRec.Opportunity_Name__r.DRN__c == 'Ace of Spades' || caseRec.Opportunity_Name__r.DRN__c == 'King of Spades')){
                                caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_caviar_OCUS_errors_US');
                            } else{
                                caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_US');
                            }
                        }
                    }
                }
            }
            update caseRec;
        }catch(Exception ex){
            CDdErrorUtilities.publishException('Case', 'updateCaseWithMissionData', ex);
        }
    }

    /*
    *Description: CDdOCUSWebhookHandler will trigger this method if Appointment Date is updated on OCUS
    * @param   WebhookResponse   CDdRestJSONObj.OCUSWebhookResponse
    */
    public static void updateCaseAppointmentDateFromOCUS(CDdRestJSONObj.OCUSWebhookResponse WebhookResponse){
        CDdOCUSAPIHandlerWOS woshandler = new CDdOCUSAPIHandlerWOS();
        try{
            if(WebhookResponse?.attributes?.mission_reference_id != null){
                Case caseRec = woshandler.getCasesWOS(WebhookResponse.attributes.mission_reference_id)[0];
                CDdAPICredentialData.CredentialWrapper cred = getCredentialWrapper(caseRec);
                CDdRestJSONObj.OCUSMissionResponse response = CDdOCUSAPIService.getOCUSMilestoneAPI(cred.namedCredential, cred.getSuffix+'/'+WebhookResponse.attributes.mission_reference_id+'?include='+CDdOCUSAPIConstants.OCUS_ADDRESS_QUERY);
                if(response.isSuccess && response?.data?.attributes?.approved_appointment != null){
                    String countryCode = response.data.relationships.address.attributes.country_code;
                    String timeZone;
                    if(CDdOCUSAPIConstants.COUNTRYCODE_TIME_ZONE.containsKey(countryCode)){
                        timeZone = CDdOCUSAPIConstants.COUNTRYCODE_TIME_ZONE.get(countryCode);
                    }

                    List<String> dateTimeList = CDdOCUSAPIServiceHelper.getDateTimeFromISOFormat(response.data.attributes.approved_appointment, timeZone);
                    String public_status = WebhookResponse.attributes.public_status;
                    if(String.isNotBlank(CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status))){
                        CaseRec.Status = CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status);
                    }
                    CaseRec.Kodakit_Event__c = public_status;
                    caseRec.Error_Exception__c = '';
                    caseRec.Kodakit_Error__c = '';
                    if(dateTimeList.size() > 1){
                        CaseRec.Photoshoot_Date__c = Date.valueOf(dateTimeList[0]);
                        CaseRec.Photoshoot_Time__c =  dateTimeList[1];
                    }
                    new CDdOCUSAPIHandlerWOS().updateRecordsWOS(new List<SObject>{caseRec});
                }else{
                    CDdErrorUtilities.publishException('Case', 'updateCaseAppointmentDateFromOCUS', '', response.message);
                }
            }
        }catch(Exception ex){
            CDdErrorUtilities.publishException('Case', 'updateCaseAppointmentDateFromOCUS', ex);
        }
    }

    /*
    *Description: CDdOCUSWebhookHandler will trigger this if Media is uploaded on OCUS Assignment
    * @param   WebhookResponse   CDdRestJSONObj.OCUSWebhookResponse
    */
    public static void updateCaseMediaURLFromOCUS(CDdRestJSONObj.OCUSWebhookResponse WebhookResponse){
        CDdOCUSAPIHandlerWOS woshandler = new CDdOCUSAPIHandlerWOS();
        try{
            if(WebhookResponse?.attributes?.mission_reference_id != null){
                Case caseRec = woshandler.getCasesWOS(WebhookResponse.attributes.mission_reference_id)[0];
                CDdAPICredentialData.CredentialWrapper cred = getCredentialWrapper(caseRec);
                CDdRestJSONObj.OCUSMissionResponse response = CDdOCUSAPIService.getOCUSMilestoneAPI(cred.namedCredential, cred.getSuffix+'/'+WebhookResponse.attributes.mission_reference_id+'?include='+CDdOCUSAPIConstants.OCUS_ARCHIVE_MEDIAFILES_QUERY);
                String fileUrls = '';
                if(response.isSuccess && response?.data?.relationships?.archives.data.size() > 0){
                    List<CDdRestJSONObj.OCUSFileData> filesData = response.data.relationships.archives.data;
                    for(CDdRestJSONObj.OCUSFileData file : filesData){
                        if(file.type.equalsIgnoreCase('mission_media_file_archives') && file.attributes.type.equalsIgnoreCase('customer_delivery')){
                            fileUrls += file.attributes.url+'\n';
                            break;
                        }
                    }
                    String public_status = WebhookResponse.attributes.public_status;
                    caseRec.Error_Exception__c = '';
                    caseRec.Kodakit_Error__c = '';
                    if(String.isNotBlank(fileUrls)){
                        if(fileUrls.length() < 256){
                            caseRec.Kodakit_Pictures_URL__c = fileUrls;
                        }else{
                            caseRec.Kodakit_Pictures_URL__c = 'Media URL length exceeded 255 characters. Please check Photoshoot Message field for Meida Link.';
                            caseRec.Kodakit_Message__c = fileUrls;
                        }
                    }
                    if(String.isNotBlank(CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status))){
                        CaseRec.Status = CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status);
                    }
                    CaseRec.Kodakit_Event__c = public_status;
                    new CDdOCUSAPIHandlerWOS().updateRecordsWOS(new List<SObject>{caseRec});
                }else {
                    CDdErrorUtilities.publishException('Case', 'updateCaseMediaURLFromOCUS', '', response.message);
                }
            }
        }catch(Exception ex){
            System.debug(ex.getMessage());
            CDdErrorUtilities.publishException('Case', 'updateCaseMediaURLFromOCUS', ex);
        }
    }

     /*
    *Description: CDdOCUSWebhookHandler will trigger this method if Status is Blocked
    * @param   WebhookResponse   CDdRestJSONObj.OCUSWebhookResponse
    * TODO[Veera] : can merge with above methods updateCaseMediaURLFromOCUS, updateCaseAppointmentDateFromOCUS
    */
    public static void updateCaseBlockedStatusFromOCUS(CDdRestJSONObj.OCUSWebhookResponse WebhookResponse){
        CDdOCUSAPIHandlerWOS woshandler = new CDdOCUSAPIHandlerWOS();
        try{
            if(WebhookResponse?.attributes?.mission_reference_id != null){
                Case caseRec = woshandler.getCasesWOS(WebhookResponse.attributes.mission_reference_id)[0];
                CDdAPICredentialData.CredentialWrapper cred = getCredentialWrapper(caseRec);
                CDdRestJSONObj.OCUSMissionResponse response = CDdOCUSAPIService.getOCUSMilestoneAPI(cred.namedCredential, cred.getSuffix+'/'+WebhookResponse.attributes.mission_reference_id+'?include='+CDdOCUSAPIConstants.OCUS_BLOCKER_QUERY);
                String blockerComment = '';
                String public_status = WebhookResponse.attributes?.public_status;
                if(String.isNotBlank(CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status))){
                    CaseRec.Status = CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status);
                }
                CaseRec.Kodakit_Event__c = public_status;

                if(response.isSuccess && response?.data?.relationships?.events?.data != null){
                    for(CDdRestJSONObj.OCUSEventData eventData : response?.data?.relationships?.events.data){
                        if(eventData.type == 'mission_event' && eventData.attributes.code?.contains('SP:')){
                            blockerComment += eventData.attributes.code +' - '+eventData.attributes.payload+'\n';
                        }
                    }

                    if(String.isNotBlank(blockerComment)){
                        CaseRec.Kodakit_Message__c = blockerComment;
                    }
                    new CDdOCUSAPIHandlerWOS().updateRecordsWOS(new List<SObject>{caseRec});
                }else{
                    new CDdOCUSAPIHandlerWOS().updateRecordsWOS(new List<SObject>{caseRec});
                    CDdErrorUtilities.publishException('Case', 'updateCaseAppointmentDateFromOCUS', '', response.message);
                }
            }
        }catch(Exception ex){
            CDdErrorUtilities.publishException('Case', 'updateCaseAppointmentDateFromOCUS', ex);
        }
    }

    /*
    *Description: CDdOCUSWebhookHandler will trigger this if Status on OCUS Assignment is updated
    * @param   WebhookResponse   CDdRestJSONObj.OCUSWebhookResponse
    */
    public static void updateCaseStatusFromOCUS(CDdRestJSONObj.OCUSWebhookResponse WebhookResponse){
        CDdOCUSAPIHandlerWOS woshandler = new CDdOCUSAPIHandlerWOS();
        try{
            if(WebhookResponse?.attributes?.public_status != null){
                List<Case> caseList = woshandler.getCasesWOS(WebhookResponse.attributes.mission_reference_id);
                Case CaseRec = caseList[0];
                String public_status = WebhookResponse.attributes.public_status;
                caseRec.Error_Exception__c = '';
                caseRec.Kodakit_Error__c = '';
                if(String.isNotBlank(CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status))){
                    CaseRec.Status = CDdOCUSAPIConstants.OCUS_CASE_STATUS_MAPPING.get(public_status);
                }
                CaseRec.Kodakit_Event__c = public_status;
                new CDdOCUSAPIHandlerWOS().updateRecordsWOS(new List<SObject>{caseRec});
            }
        }catch(Exception ex){
            CDdErrorUtilities.publishException('Case', 'updateCaseStatusFromOCUS', ex);
        }
    }

     /*
    *Description: CaseTrigger will call this if Sales Notes is updated on the Case
    * @param   WebhookResponse   CDdRestJSONObj.OCUSWebhookResponse
    */
    public static void updateSalesNotesOnOCUS(Set<Id> caseIdSet){
        List<Case> caseList = getCases(caseIdSet);
        for(Case caseRec : caseList){
            try {
                CDdAPICredentialData.CredentialWrapper cred = getCredentialWrapper(caseRec);
                CDdRestJSONObj.OCUSAPIRequest bookingRequest = CDdOCUSAPIServiceHelper.prepareOCUSMilestoneRequestForUpdate(caseRec);
                CDdRestJSONObj.OCUSMissionResponse missionResponse = CDdOCUSAPIService.updateOCUSMilestoneAPI(bookingRequest,cred.namedCredential, cred.postSuffix, caseRec.Kodakit_Job_Id__c);
                if(!missionResponse.isSuccess){
                    List<String> errorList = new List<String>{missionResponse.message};
                        for(List<String> errors : missionResponse?.errors.values()){
                            errorList.addAll(errors);
                        }
                    updateCaseWithMissionData(null,caseRec,errorList,false);
                }
            }catch(Exception ex){
                CDdErrorUtilities.publishException('Case', 'updateSalesNotesOnOCUS', ex);
            }
        }
    }

    /**
     * @author      Swedhaa Sri M
     * @date        Feb 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-42481
     * @description CaseTrigger will call this to validate OCUS Photoshoot Data
     */
    public static void validateOCUSData(List<Case> casesToCheck, Boolean isInsert){
        Map<String,Id> queueNameVsIdMap = getQueuesByDeveloperName(CDdOCUSAPIConstants.queueDeveloperNames);
        for(Case caseRec : casesToCheck){

            if(caseRec.Opportunity_Name__c == null || caseRec.Menu_Preview_Links__c == null){
                caseRec.Kodakit_Error__c = OCUSInvalidDataErrorMessage;
            }
            else if((caseRec.Photoshoot_Date__c == null && caseRec.Photoshoot_Time__c != null) || (caseRec.Photoshoot_Date__c != null && caseRec.Photoshoot_Time__c == null)){
                caseRec.Kodakit_Error__c = OCUSPhotoshootDateErrorMessage;
            }

            switch on caseRec.Shipping_Address_Country__c {
                when 'Japan' {
                    caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_Japan');
                }
                when 'Germany' {
                    caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_Germany');
                }
                when 'Canada' {
                    caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_Canada');
                }
                when 'United States' {
                    if(caseRec.Return_Shipping_Address_State__c == 'Puerto Rico'){
                        caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_PR');
                    } else if((caseRec.Opportunity_Name__r.Platform__c == 'Caviar' || caseRec.Opportunity_Name__r.Platform__c == 'Caviar and DoorDash') &&
                              (caseRec.Opportunity_Name__r.DRN__c == 'Ace' || caseRec.Opportunity_Name__r.DRN__c == 'King' || caseRec.Opportunity_Name__r.DRN__c == 'Ace of Spades' || caseRec.Opportunity_Name__r.DRN__c == 'King of Spades')){
                        caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_caviar_OCUS_errors_US');
                    } else{
                        caseRec.OwnerId = queueNameVsIdMap.get('Photoshoot_cases_OCUS_errors_US');
                    }
                }
            }
        }

        if(!isInsert && !casesToCheck.isEmpty()){
            Update casesToCheck;
        }
    }

    public static List<Case> getCases(Set<Id> caseIdSet) {
        List<Case> caseList = [SELECT Id, Subject, CaseNumber, Photo_Provider__c, Photoshoot_Date__c, Photoshoot_Time__c, Kodakit_Job_Id__c, Photo_Review_Notes__c,Language__c, ContactPhone,
                                ContactEmail , Contact.Name,  Contact.Firstname, Contact.LastName, Menu_Preview_Links__c,Return_Shipping_Address_Street__c,Return_Shipping_Address_City__c,
                                Return_Shipping_Address_State__c, Shipping_Address_Country__c, Return_Shipping_Address_Zip__c, Return_Shipping_Address_Suite_Apt_etc__c, Business_ID_Acc__c,
                                //Account Fields
                                AccountId, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountryCode, Account.BillingCountry,
                                Account_Address__c, Account.BillingStateCode, Account.Legal_Business_Name__c, Account.Address2__c, Account.Kanji_Street__c, Account.Kanji_City__c, Account.Kanji_State__c,
                                Account.Kanji_Country__c, Account.Kanji_Zip__c, Account.Kanji_Address2__c, Account.Restaurant_ID__c, Account.PhotoshootCaseCreated__c,
                                Account.RealZip__RealZip__r.Submarket_lookup__r.Photoshoot_Vendor__c,Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c,
                                //Opportunity fields
                                Opportunity_Name__r.Name, Opportunity_Name__r.Notes_for_Menu_Team__c, Opportunity_Name__r.Photoshoot_Date__c, Opportunity_Name__r.Photoshoot_Time__c,
                                Opportunity_Name__r.Decision_Maker__c, Opportunity_Name__r.Preferred_Language__c, Opportunity_Name__r.Mx_Requesting_Photoshoot__c,Opportunity_Name__r.Platform__c,Opportunity_Name__r.DRN__c
                                FROM Case
                                WHERE Id in :caseIdSet AND Opportunity_Name__r.RecordtypeId = :OPPORTUNITY_MARKETPLACE_RT AND Account.RecordTypeId = :CDdRecordTypeAccount.prospect()
                                FOR UPDATE];
        return caseList;
    }

    public static Map<String,Id> getQueuesByDeveloperName(Set<String> developerNames) {
        Map<String,Id> queueNameVsIdMap = new Map<String,Id>();
        List<Group> queueList = [SELECT Id, Type, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN : developerNames];
        for(Group queue : queueList){
            queueNameVsIdMap.put(queue.DeveloperName, queue.Id);
        }
        return queueNameVsIdMap;
    }

    //getting Authorization details from custom metadata based on Country code
    public static CDdAPICredentialData.CredentialWrapper getCredentialWrapper(Case caseRec) {
        CDdAPICredentialData.CredentialWrapper cred;

        if(caseRec.Account.BillingCountryCode == 'US' && caseRec.Account.BillingStateCode == 'PR'){
            cred = credentialData.get('OCUS_PR');
        }else if((caseRec.Opportunity_Name__r.Platform__c == 'Caviar' || caseRec.Opportunity_Name__r.Platform__c == 'Caviar and DoorDash') &&
         (caseRec.Opportunity_Name__r.DRN__c == 'Ace' || caseRec.Opportunity_Name__r.DRN__c == 'King' || caseRec.Opportunity_Name__r.DRN__c == 'Ace of Spades' || caseRec.Opportunity_Name__r.DRN__c == 'King of Spades')){
            cred = CDdAPICredentialData.getCredentialWrapper(CDdAPICredentialData.OCUS_CATEGORY).get('OCUS_'+ caseRec.Account.BillingCountryCode + '_Caviar' );
        } else{
            cred = credentialData.get('OCUS_'+caseRec.Account.BillingCountryCode);
        }
        return cred;
    }

    //Without sharing class to bypass sharing rules for OCUS Webhook User(Public site User).
    public without sharing class CDdOCUSAPIHandlerWOS {

        public void updateRecordsWOS(List<Sobject> recordList){
            Database.SaveResult[] srList = Database.update(recordList, false);
            CDdErrorUtilities.publishException('Case', 'updateRecordsWOS', srList);
        }

        public List<Case> getCasesWOS(String missionId) {
            List<Case> caseList = [SELECT Id,Kodakit_Event__c, Status, Account.BillingCountryCode, Account.BillingStateCode,Opportunity_Name__r.Platform__c ,Opportunity_Name__r.DRN__c FROM Case WHERE RecordtypeId = :CDdRecordTypeCase.photoshootProcessing() AND Kodakit_Job_Id__c = :missionId LIMIT 1];
            return caseList;
        }
    }
}