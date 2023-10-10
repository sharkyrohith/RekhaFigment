/**
 * @author  Mahesh Chouhan
 * @date    June 2023
 * @description Service class for Claim Integration
 */

public with sharing class CDdClaimsCalloutController {

    public static final String INTERNATIONAL_PHONE_FORMAT = '+1-{0}-{1}';
    public static Claim_Integration_Setting__mdt claimIntegrationSettings = Claim_Integration_Setting__mdt.getInstance('DEFAULT');
    public static final String AUTHORIZAION_BODY = 'grant_type=client_credentials&client_id={!$Credential.Username}&client_secret={!$Credential.Password}';
    public static final String POLICY_DATE = '-09-01';
    public static final String LINE_OF_BUSINESS_AUTOB = 'AUTOB';
    public static final String ORG_NAME_LINE = 'organizationNameLine1';
    public static final String ORG_NAME_DOORDASH = 'DOORDASH, INC.';
    public static final String CLAIM_ALREADY_SUBMITTED_MESG = 'Claim Submission already processed for current Claim';
    public static final String CLAIM_NOT_SUBMITTED_MESG = 'Claim is not submitted for this Claim. Click Claim Callout button for Claim Submission.';
    public static final String DOC_WITH_SAME_NAME = 'Multiple Documents with same name exists on Claim. Please rename duplicate documents.';
    public static final String CLAIM_ALREADY_SUBMITTED_CASE_MESG = 'Claim has already been submitted for the Case through ';
    public static final String CLAIM_SUBTYPE_BODILY_INJURED = 'Bodily Injury';
    public static final String CLAIM_SUBTYPE_PROPERTY_DAMAGE = 'Property Damage';
    public static final String CHECK_RESPONSE_PAYLOAD_MESG = '{0}. Check Response Payload for more info.';
    public static final String NO_DOCUMENT_FOUND_MESG = 'No Document found for submission.';
    public static final String NO_NEW_DOCUMENT_FOUND_MESG = 'No New Documents found for Sync.';
    public static final String API_CLAIM_SUBMISSION = 'Claim Submission';
    public static final String API_DOCUMENT_SUBMISSION = 'Document Submission';
    public static final String API_S3_FILE_UPDATION = 'S3 File Updation';
    public static final String API_TYPE_CUSTOMER = 'Customer';

    //Key is JSON key name and Value is default value to be used
    public static Map<String, String> defaultValues = new Map<String, String> {
        'insuredOrPrincipal.lineOfBusinessCode' => 'AUTOB',
        'insuredOrPrincipal.primaryAddress.city' => 'San Francisco',
        'insuredOrPrincipal.primaryAddress.stateProvinceCode' => 'US-CA',
        'insuredOrPrincipal.primaryAddress.countryCode' => 'USA',
        'insuredOrPrincipal.primaryAddress.addressLine1' => '303 2nd Street',
        'insuredOrPrincipal.primaryAddress.postalCode' => '941031729',
        'insuredOrPrincipal.businessPhone.phoneNumber' => '+9-999-9999999',
        'autoEventDetails.claimReportedByRelationshipToInsuredCode' => 'EmployeeOrInternalAgent',
        'vehicleDetails.typeOfVehicle' => 'PassengerAutomobile',
        'vehicleDetails.vehicleOwnershipTypeCode' => 'NonOwnedBelongsToAnEmployee',
        'insuredVehicle.driverCustodian.wasDriverOrCustodianPresent' => 'Yes',
        'insuredVehicle.driverCustodian.relationshipToVehicleOwner' => 'Self',
        'vehicleDetails.year' => '1925',
        'vehicleDetails.model' => 'Unknown',
        'vehicleDetails.make' => 'Unknown',
        'claimReportedBy.personName.firstName' => 'DoorDash',
        'claimReportedBy.personName.lastName' => 'Claims',
        'claimReportedBy.email.emailAddress' => 'autoclaims@doordash.com',
        'claimReportedBy.businessPhone.phoneNumber' => '+9-999-9999999',
        'insuredVehicle.driverCustodian.businessPhone.phoneNumber' => '+9-999-9999999',
        'thirdPartyVehicle.driverCustodian.businessPhone.phoneNumber' => '+9-999-9999999',
        'thirdPartyVehicle.driverCustodian.wasDriverOrCustodianPresent' => 'Yes',
        'thirdPartyVehicle.driverCustodian.relationshipToVehicleOwner' => 'Self',
        'bicyclistsOrPedestrian.businessPhone.phoneNumber' => '+9-999-9999999',
        'insuredVehicle.driverCustodian.demographics.genderCode' => 'Male',
        'customDataFields.claimSpecificCode10.label' => 'Special Customer Type',
        'customDataFields.claimSpecificCode10.description' => 'DDash',
        'customDataFields.claimSpecificCode10.value' => 'DDash',
        'customDataFields.claimSpecific120Character01.label' => 'Delivery UUID?',
        'customDataFields.claimSpecific80Character01.label' => 'Dasher ID?',
        'customDataFields.claimSpecific80Character02.label' => 'Drive Partner',
        'autoEventDetails.eventDescriptionCode' => '18',
        'vehicleDamages.wasVehicleStopped' => 'Unknown',
        'vehicleDamages.pointOfImpactCode' => 'PointOfImpactUnknown',
        'vehicleDamages.estimatedDamageSeverityCode' => 'Unknown'
    };


    /**
     * @author  Mahesh Chouhan
     * @date    June 2023
     * @description method to make Claim Submission callout
     * @param claimId Claim Record Id
     * @return ClaimResponse instance storing api response
    */
    @AuraEnabled
    public static CDdClaimInformation.ClaimResponse makeClaimAPICallout(String claimId){
        CDdClaimInformation.ClaimResponse claimResponse = new CDdClaimInformation.ClaimResponse();
        CDdClaimInformation.ClaimsRequest request = new CDdClaimInformation.ClaimsRequest();
        String accessToken;
        try {
            Claim__c claimRecord = [SELECT Id, Date_of_Loss__c, Incident_Involves_Bodily_Injury__c, Large_Loss_Notice__c, Facts_of_Loss__c, Review_Only__c,
                                    Drive_Partner__c, Case__c, Case__r.CaseNumber, Claim_Number__c, Dasher_FirstName__c, Dasher_LastName__c,
                                    Dasher_Email__c, Dasher_Phone__c, Dasher_City__c, Dasher_Country__c, Dasher_State_Province__c, Delivery_UUID__c,
                                    Reporting_Party_Name__r.FirstName, Reporting_Party_Name__r.LastName, Reporting_Party_Phone__c, Dasher_ID__c,
                                    Loss_Location_Street__c, Loss_Location_City__c, Loss_Location_State_Province__c, Loss_Location_Country__c,
                                    Vehicle_Make__c, Vehicle_Model__c, Vehicle_Year__c, API_Type__c, Request_Payload__c, Response_Payload__c,
                                    Dasher_Address_Line_1__c, Dasher_Address_Line_2__c, Dasher_Address_Zip__c, Loss_Location_Zip_Postal_Code__c,
                                    Third_Party_FirstName__c, Third_Party_LastName__c, Third_Party_Email__c, Third_Party_Phone__c, Third_Party_Property_Damage__c,
                                    Third_Party_Bodily_Injury__c, Bicyclists_Or_Pedestrians_FirstName__c, Bicyclists_Or_Pedestrians_LastName__c,
                                    Bicyclists_Or_Pedestrians_Email__c, Bicyclists_Or_Pedestrians_Phone__c, Bicyclists_Or_Pedestrians_Role__c,
                                    Bicyclists_Or_Pedestrians_Bodily_Injury__c, Bicyclists_Or_Pedestrian_Property_Damage__c
                                    FROM Claim__c WHERE Id = :claimId];

            String validateClaimResponse = validateClaim(claimRecord);
            if(String.isNotBlank(validateClaimResponse)){
                claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
                claimResponse.message = validateClaimResponse;
                return claimResponse;
            }


            CDdRestJSONObj.RestAPIResponse authResponse = getAccessToken();
            Map<String, Object> authResponseMap = (Map<String, Object>) JSON.deserializeUntyped(authResponse.body);

            if(authResponse.statusCode == 200) {
                accessToken =  String.valueOf(authResponseMap.get('access_token'));
            }
            else {
                claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
                claimResponse.message = String.valueOf(authResponseMap.get('Error'));
                return claimResponse;
            }

            //InsuredOrPrincipal
            CDdClaimInformation.InsuredOrPrincipal insuredOrPrincipal = new CDdClaimInformation.InsuredOrPrincipal();
            insuredOrPrincipal.accountStakeholderID = Integer.valueOf(claimIntegrationSettings.Account_Stack_Holder_ID__c);
            insuredOrPrincipal.lineOfBusinessCode = LINE_OF_BUSINESS_AUTOB;

            switch on insuredOrPrincipal.lineOfBusinessCode {
                when 'AUTOB' {
                    insuredOrPrincipal.policyNumber = claimIntegrationSettings.AUTOB_Policy_Number__c;
                }
                when 'CGL' {
                    insuredOrPrincipal.policyNumber = claimIntegrationSettings.CGL_Policy_Number__c;
                }
            }

            if(claimRecord.Date_of_Loss__c != null){
                Integer year = claimRecord.Date_of_Loss__c.month() >= 9 && claimRecord.Date_of_Loss__c.month() <= 12 ?
                    claimRecord.Date_of_Loss__c.year() : (claimRecord.Date_of_Loss__c.year() - 1);
                insuredOrPrincipal.policyEffectiveDate = year + POLICY_DATE;
                insuredOrPrincipal.policyExpirationDate = (year + 1) + POLICY_DATE;
            }

            Map<String, String> organizationName = new Map<String, String>();
            organizationName.put(ORG_NAME_LINE, ORG_NAME_DOORDASH);
            insuredOrPrincipal.organizationName = organizationName;

            insuredOrPrincipal.primaryAddress = new CDdClaimInformation.PrimaryAddress();
            insuredOrPrincipal.primaryAddress.city = defaultValues.get('insuredOrPrincipal.primaryAddress.city');
            insuredOrPrincipal.primaryAddress.stateProvinceCode = defaultValues.get('insuredOrPrincipal.primaryAddress.stateProvinceCode');
            insuredOrPrincipal.primaryAddress.countryCode = defaultValues.get('insuredOrPrincipal.primaryAddress.countryCode');
            insuredOrPrincipal.primaryAddress.addressLine1 = defaultValues.get('insuredOrPrincipal.primaryAddress.addressLine1');
            insuredOrPrincipal.primaryAddress.postalCode = defaultValues.get('insuredOrPrincipal.primaryAddress.postalCode');

            insuredOrPrincipal.businessPhone = new CDdClaimInformation.BusinessPhone();
            insuredOrPrincipal.businessPhone.phoneNumber = defaultValues.get('insuredOrPrincipal.businessPhone.phoneNumber');
            request.insuredOrPrincipal = insuredOrPrincipal;

            //ClaimsOccurrence
            CDdClaimInformation.ClaimsOccurrence claimsOccurrence = new CDdClaimInformation.ClaimsOccurrence();
            claimsOccurrence.insuredReportNumber = claimRecord.Case__r.CaseNumber;
            String lossDateTime = claimRecord.Date_of_Loss__c.format(CDdCoreConstants.TIMEFORMAT);
            claimsOccurrence.lossDate = lossDateTime.split(CDdCoreConstants.DELIMITER_SPACE)[0];
            claimsOccurrence.lossTime = lossDateTime.split(CDdCoreConstants.DELIMITER_SPACE)[1];
            claimsOccurrence.reportedToInsuredDateTime = DateTime.now().format(CDdCoreConstants.TIMEFORMAT_UTC);
            request.claimsOccurrence = claimsOccurrence;

            //AutoEventDetails
            CDdClaimInformation.AutoEventDetails autoEventDetails = new CDdClaimInformation.AutoEventDetails();
            autoEventDetails.eventDescriptionCode = defaultValues.get('autoEventDetails.eventDescriptionCode');
            autoEventDetails.eventDescriptionText = claimRecord.Facts_of_Loss__c;
            autoEventDetails.eventStreetLine1 = claimRecord.Loss_Location_Street__c;
            autoEventDetails.eventCity = claimRecord.Loss_Location_City__c;
            autoEventDetails.eventStateProvinceCode = claimRecord.Loss_Location_State_Province__c;
            autoEventDetails.eventCountryCode = claimRecord.Loss_Location_Country__c;
            autoEventDetails.seekingInsuredVehicleCoverageIndicator = claimRecord.Review_Only__c;
            autoEventDetails.claimReportedByRelationshipToInsuredCode = defaultValues.get('autoEventDetails.claimReportedByRelationshipToInsuredCode');
            if(String.isNotBlank(claimRecord.Loss_Location_Zip_Postal_Code__c)){
                autoEventDetails.eventPostalCode = claimRecord.Loss_Location_Zip_Postal_Code__c;
            }
            request.autoEventDetails = autoEventDetails;

            //ClaimReportedBy
            CDdClaimInformation.ClaimReportedBy claimReportedBy = new CDdClaimInformation.ClaimReportedBy();
            claimReportedBy.personName = new CDdClaimInformation.PersonName();
            claimReportedBy.personName.firstName = defaultValues.get('claimReportedBy.personName.firstName');
            claimReportedBy.personName.lastName = defaultValues.get('claimReportedBy.personName.lastName');
            claimReportedBy.businessPhone = new CDdClaimInformation.BusinessPhone();
            claimReportedBy.businessPhone.phoneNumber = String.isBlank(claimRecord.Reporting_Party_Phone__c) ?
                defaultValues.get('claimReportedBy.businessPhone.phoneNumber') : getInternalPhoneFormat(claimRecord.Reporting_Party_Phone__c);
            claimReportedBy.email = new CDdClaimInformation.Email();
            claimReportedBy.email.emailAddress = defaultValues.get('claimReportedBy.email.emailAddress');
            request.claimReportedBy = claimReportedBy;

            //VehicleDetails
            CDdClaimInformation.VehicleDetails vehicleDetails = new CDdClaimInformation.VehicleDetails();
            vehicleDetails.typeOfVehicle = defaultValues.get('vehicleDetails.typeOfVehicle');
            vehicleDetails.vehicleOwnershipTypeCode = defaultValues.get('vehicleDetails.vehicleOwnershipTypeCode');

            vehicleDetails.make = defaultValues.get('vehicleDetails.make');
            vehicleDetails.model = defaultValues.get('vehicleDetails.model');
            vehicleDetails.year = defaultValues.get('vehicleDetails.year');

            claimRecord.Vehicle_Make__c = vehicleDetails.make;
            claimRecord.Vehicle_Model__c = vehicleDetails.model;
            claimRecord.Vehicle_Year__c = vehicleDetails.year;

            //VehicleDamages
            CDdClaimInformation.VehicleDamages vehicleDamages = new CDdClaimInformation.VehicleDamages();
            vehicleDamages.wasVehicleStopped = defaultValues.get('vehicleDamages.wasVehicleStopped');
            vehicleDamages.pointOfImpactCode = defaultValues.get('vehicleDamages.pointOfImpactCode');
            vehicleDamages.estimatedDamageSeverityCode = defaultValues.get('vehicleDamages.estimatedDamageSeverityCode');

            claimRecord.Was_Vehicle_Stopped__c = vehicleDamages.wasVehicleStopped;
            claimRecord.Point_Of_Impact__c = vehicleDamages.pointOfImpactCode;
            claimRecord.Vehicle_Damage_Severity__c = vehicleDamages.estimatedDamageSeverityCode;

            //InsuredVehicle
            CDdClaimInformation.InsuredVehicle insuredVehicle = new CDdClaimInformation.InsuredVehicle();
            insuredVehicle.driverCustodian = new CDdClaimInformation.DriverCustodian();

            insuredVehicle.driverCustodian.personName = new CDdClaimInformation.PersonName();
            insuredVehicle.driverCustodian.personName.firstName = claimRecord.Dasher_FirstName__c;
            insuredVehicle.driverCustodian.personName.lastName = claimRecord.Dasher_LastName__c;

            insuredVehicle.driverCustodian.businessPhone = new CDdClaimInformation.BusinessPhone();
            insuredVehicle.driverCustodian.businessPhone.phoneNumber = String.isBlank(claimRecord.Dasher_Phone__c) ?
                defaultValues.get('insuredVehicle.driverCustodian.businessPhone.phoneNumber') : getInternalPhoneFormat(claimRecord.Dasher_Phone__c);

            insuredVehicle.driverCustodian.email = new CDdClaimInformation.Email();
            insuredVehicle.driverCustodian.email.emailAddress = claimRecord.Dasher_Email__c;

            if(String.isNotBlank(claimRecord.Dasher_City__c) && String.isNotBlank(claimRecord.Dasher_Country__c)
                && String.isNotBlank(claimRecord.Dasher_State_Province__c)){
                    insuredVehicle.driverCustodian.primaryAddress = new CDdClaimInformation.PrimaryAddress();
                    insuredVehicle.driverCustodian.primaryAddress.city = claimRecord.Dasher_City__c;
                    insuredVehicle.driverCustodian.primaryAddress.countryCode = claimRecord.Dasher_Country__c;
                    insuredVehicle.driverCustodian.primaryAddress.stateProvinceCode = claimRecord.Dasher_State_Province__c;
                    if(String.isNotBlank(claimRecord.Dasher_Address_Line_1__c)){
                        insuredVehicle.driverCustodian.primaryAddress.addressLine1 = claimRecord.Dasher_Address_Line_1__c;
                    }
                    if(String.isNotBlank(claimRecord.Dasher_Address_Line_2__c)){
                        insuredVehicle.driverCustodian.primaryAddress.addressLine2 = claimRecord.Dasher_Address_Line_2__c;
                    }
                    if(String.isNotBlank(claimRecord.Dasher_Address_Zip__c)){
                        insuredVehicle.driverCustodian.primaryAddress.postalCode = claimRecord.Dasher_Address_Zip__c;
                    }
            }

            insuredVehicle.driverCustodian.demographics = new CDdClaimInformation.Demographics();
            insuredVehicle.driverCustodian.demographics.genderCode = defaultValues.get('insuredVehicle.driverCustodian.demographics.genderCode');

            insuredVehicle.driverCustodian.injury = new CDdClaimInformation.Injury();
            insuredVehicle.driverCustodian.injury.sufferedBodilyInjuryIndicator = claimRecord.Incident_Involves_Bodily_Injury__c;

            insuredVehicle.driverCustodian.personalPropertyDamage = new CDdClaimInformation.PersonalPropertyDamage();
            insuredVehicle.driverCustodian.personalPropertyDamage.personalPropertyDamagedIndicator = claimRecord.Large_Loss_Notice__c;
            insuredVehicle.driverCustodian.wasDriverOrCustodianPresent = defaultValues.get('insuredVehicle.driverCustodian.wasDriverOrCustodianPresent');
            insuredVehicle.driverCustodian.relationshipToVehicleOwner = defaultValues.get('insuredVehicle.driverCustodian.relationshipToVehicleOwner');
            insuredVehicle.vehicleDetails = vehicleDetails;
            insuredVehicle.vehicleDamages = vehicleDamages;
            request.insuredVehicle = insuredVehicle;

            //ThirdPartyVehicles
            List<CDdClaimInformation.InsuredVehicle> thirdPartyVehicles = new List<CDdClaimInformation.InsuredVehicle>();
            CDdClaimInformation.InsuredVehicle thirdPartyVehicle = new CDdClaimInformation.InsuredVehicle();
            thirdPartyVehicle.driverCustodian = new CDdClaimInformation.DriverCustodian();

            thirdPartyVehicle.driverCustodian.personName = new CDdClaimInformation.PersonName();
            thirdPartyVehicle.driverCustodian.personName.firstName = claimRecord.Third_Party_FirstName__c;
            thirdPartyVehicle.driverCustodian.personName.lastName = claimRecord.Third_Party_LastName__c;

            thirdPartyVehicle.driverCustodian.businessPhone = new CDdClaimInformation.BusinessPhone();
            thirdPartyVehicle.driverCustodian.businessPhone.phoneNumber = String.isBlank(claimRecord.Third_Party_Phone__c) ?
                defaultValues.get('thirdPartyVehicle.driverCustodian.businessPhone.phoneNumber') : getInternalPhoneFormat(claimRecord.Third_Party_Phone__c);

            thirdPartyVehicle.driverCustodian.email = new CDdClaimInformation.Email();
            thirdPartyVehicle.driverCustodian.email.emailAddress = claimRecord.Third_Party_Email__c;

            if(String.isNotBlank(claimRecord.Third_Party_FirstName__c) && String.isNotBlank(claimRecord.Third_Party_LastName__c)){
                thirdPartyVehicle.driverCustodian.injury = new CDdClaimInformation.Injury();
                thirdPartyVehicle.driverCustodian.injury.sufferedBodilyInjuryIndicator = claimRecord.Third_Party_Bodily_Injury__c;

                thirdPartyVehicle.driverCustodian.personalPropertyDamage = new CDdClaimInformation.PersonalPropertyDamage();
                thirdPartyVehicle.driverCustodian.personalPropertyDamage.personalPropertyDamagedIndicator = claimRecord.Third_Party_Property_Damage__c;
                thirdPartyVehicle.driverCustodian.wasDriverOrCustodianPresent = defaultValues.get('thirdPartyVehicle.driverCustodian.wasDriverOrCustodianPresent');
                thirdPartyVehicle.driverCustodian.relationshipToVehicleOwner = defaultValues.get('thirdPartyVehicle.driverCustodian.relationshipToVehicleOwner');
                thirdPartyVehicles.add(thirdPartyVehicle);
                request.thirdPartyVehicles = thirdPartyVehicles;
            }

            //BicyclistOrPedestrian
            List<CDdClaimInformation.BicyclistOrPedestrian> bicyclistsOrPedestrians = new List<CDdClaimInformation.BicyclistOrPedestrian>();
            CDdClaimInformation.BicyclistOrPedestrian bicyclistsOrPedestrian = new CDdClaimInformation.BicyclistOrPedestrian();
            bicyclistsOrPedestrian.bicyclistOrPedestrianRoleCode = claimRecord.Bicyclists_Or_Pedestrians_Role__c;
            bicyclistsOrPedestrian.personName = new CDdClaimInformation.PersonName();
            bicyclistsOrPedestrian.personName.firstName = claimRecord.Bicyclists_Or_Pedestrians_FirstName__c;
            bicyclistsOrPedestrian.personName.lastName = claimRecord.Bicyclists_Or_Pedestrians_LastName__c;

            bicyclistsOrPedestrian.businessPhone = new CDdClaimInformation.BusinessPhone();
            bicyclistsOrPedestrian.businessPhone.phoneNumber = String.isBlank(claimRecord.Bicyclists_Or_Pedestrians_Phone__c) ?
                defaultValues.get('bicyclistsOrPedestrian.businessPhone.phoneNumber') : getInternalPhoneFormat(claimRecord.Bicyclists_Or_Pedestrians_Phone__c);

            bicyclistsOrPedestrian.email = new CDdClaimInformation.Email();
            bicyclistsOrPedestrian.email.emailAddress = claimRecord.Bicyclists_Or_Pedestrians_Email__c;

            if(String.isNotBlank(claimRecord.Bicyclists_Or_Pedestrians_FirstName__c) && String.isNotBlank(claimRecord.Bicyclists_Or_Pedestrians_LastName__c)){
                bicyclistsOrPedestrian.injury = new CDdClaimInformation.Injury();
                bicyclistsOrPedestrian.injury.sufferedBodilyInjuryIndicator = claimRecord.Bicyclists_Or_Pedestrians_Bodily_Injury__c;

                bicyclistsOrPedestrian.personalPropertyDamage = new CDdClaimInformation.PersonalPropertyDamage();
                bicyclistsOrPedestrian.personalPropertyDamage.personalPropertyDamagedIndicator = claimRecord.Bicyclists_Or_Pedestrian_Property_Damage__c;
                bicyclistsOrPedestrians.add(bicyclistsOrPedestrian);
                request.bicyclistsOrPedestrians = bicyclistsOrPedestrians;
            }

            //Custom Fields
            CDdClaimInformation.CustomDataFields customDataFields = new CDdClaimInformation.CustomDataFields();
            customDataFields.claimSpecificCode10 = new CDdClaimInformation.ClaimSpecificCode();
            customDataFields.claimSpecificCode10.label = defaultValues.get('customDataFields.claimSpecificCode10.label');
            customDataFields.claimSpecificCode10.description = defaultValues.get('customDataFields.claimSpecificCode10.description');
            customDataFields.claimSpecificCode10.value = defaultValues.get('customDataFields.claimSpecificCode10.value');

            if(claimRecord.Dasher_ID__c != null){
                customDataFields.claimSpecific80Character01 = new CDdClaimInformation.ClaimSpecificCode();
                customDataFields.claimSpecific80Character01.label = defaultValues.get('customDataFields.claimSpecific80Character01.label');
                customDataFields.claimSpecific80Character01.value = String.valueOf(claimRecord.Dasher_ID__c);
            }

            if(String.isNotBlank(claimRecord.Drive_Partner__c)){
                customDataFields.claimSpecific80Character02 = new CDdClaimInformation.ClaimSpecificCode();
                customDataFields.claimSpecific80Character02.label = defaultValues.get('customDataFields.claimSpecific80Character02.label');
                customDataFields.claimSpecific80Character02.value = String.valueOf(claimRecord.Drive_Partner__c);
            }

            if(String.isNotBlank(claimRecord.Delivery_UUID__c)){
                customDataFields.claimSpecific120Character01 = new CDdClaimInformation.ClaimSpecificCode();
                customDataFields.claimSpecific120Character01.label = defaultValues.get('customDataFields.claimSpecific120Character01.label');
                customDataFields.claimSpecific120Character01.value = claimRecord.Delivery_UUID__c;
            }

            request.customDataFields = customDataFields;

            CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
            String endpoint = CDdUtilities.getIsSandbox() ? claimIntegrationSettings.Sandbox_AUTOB_Claim_Submission_API__c
                : claimIntegrationSettings.AUTOB_Claim_Submission_API__c;
            CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI(CDdSupportConstants.POST_METHOD, JSON.serialize(request, true),
                                                                              CDdSupportConstants.AUTHORIZATION_BEARER + accessToken,
                                                                              endpoint,
                                                                              null);
            Map<String, Object> responseMap =  (Map<String, Object>) JSON.deserializeUntyped(response.body);
            claimRecord.Claim_Number__c = String.valueOf(responseMap.get('claimNumber'));
            claimResponse = updateClaim(API_CLAIM_SUBMISSION, request, response, claimRecord);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return claimResponse;
    }

    /**
     * @author  Mahesh Chouhan
     * @date    June 2023
     * @description method to make Claim Document Submission callout
     * @param claimId Claim Record Id
     * @return ClaimResponse instance storing api response
    */
    @AuraEnabled
    public static CDdClaimInformation.ClaimResponse makeClaimDocumentAPICallout(String claimId){
        CDdClaimInformation.ClaimResponse claimResponse = new CDdClaimInformation.ClaimResponse();
        CDdClaimInformation.ClaimDocumentRequest request = new CDdClaimInformation.ClaimDocumentRequest();
        String accessToken;
        try {
            Claim__c claimRecord = [SELECT Id, Claim_Number__c, API_Type__c, Request_Payload__c, Response_Payload__c
                                    FROM Claim__c WHERE Id = :claimId];

            if(String.isBlank(claimRecord.Claim_Number__c)){
                claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
                claimResponse.message = CLAIM_NOT_SUBMITTED_MESG;
                return claimResponse;
            }

            CDdRestJSONObj.RestAPIResponse authResponse = getAccessToken();
            Map<String, Object> authResponseMap = (Map<String, Object>) JSON.deserializeUntyped(authResponse.body);

            if(authResponse.statusCode == 200) {
                accessToken =  String.valueOf(authResponseMap.get('access_token'));
            }
            else {
                claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
                claimResponse.message = String.valueOf(authResponseMap.get('Error'));
                return claimResponse;
            }

            List<Attachment> docs = [SELECT Id, Body, Name
                                     FROM Attachment
                                     WHERE ParentId =: claimId];

            List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, ContentDocument.LatestPublishedVersion.VersionData,
                                                              ContentDocument.FileExtension, ContentDocument.Title
                                                              FROM ContentDocumentLink
                                                              WHERE LinkedEntityId = :claimId];

            if(docs.isEmpty() && contentDocumentLinks.isEmpty()){
                claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
                claimResponse.message = NO_DOCUMENT_FOUND_MESG;
                return claimResponse;
            }

            request.claimNumber = claimRecord.Claim_Number__c;
            List<CDdClaimInformation.ClaimDocument> documents = new List<CDdClaimInformation.ClaimDocument>();
            //Key is File Name and Value is Attachment
            Map<String, Attachment> attachmentMap = new Map<String, Attachment>();
            Map<String, ContentDocumentLink> fileMap = new Map<String, ContentDocumentLink>();
            for(Attachment doc : docs){
                Integer index = doc.Name.lastIndexOf(CDdCoreConstants.DELIMITER_DOT);
                String fileName = doc.Name.substring(0, index);
                String fileExt = doc.Name.substring(index + 1);
                if(attachmentMap.containsKey(fileName)){
                    claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
                    claimResponse.message = DOC_WITH_SAME_NAME;
                    return claimResponse;
                }
                attachmentMap.put(fileName, doc);
                CDdClaimInformation.ClaimDocument document = new CDdClaimInformation.ClaimDocument();
                document.name = fileName;
                document.type = API_TYPE_CUSTOMER;
                document.extension = fileExt;
                documents.add(document);
            }

            for(ContentDocumentLink contentDocumentLink : contentDocumentLinks){
                if(attachmentMap.containsKey(contentDocumentLink.ContentDocument.Title) || fileMap.containsKey(contentDocumentLink.ContentDocument.Title)){
                    claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
                    claimResponse.message = DOC_WITH_SAME_NAME;
                    return claimResponse;
                }
                fileMap.put(contentDocumentLink.ContentDocument.Title, contentDocumentLink);
                CDdClaimInformation.ClaimDocument document = new CDdClaimInformation.ClaimDocument();
                document.name = contentDocumentLink.ContentDocument.Title;
                document.type = API_TYPE_CUSTOMER;
                document.extension = contentDocumentLink.ContentDocument.FileExtension;
                documents.add(document);
            }
            request.documents = documents;

            CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
            String endpoint = CDdUtilities.getIsSandbox() ? claimIntegrationSettings.Sandbox_Document_Submission_API__c
                : claimIntegrationSettings.Document_Submission_API__c;
            CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI(CDdSupportConstants.POST_METHOD, JSON.serialize(request),
                                                                              CDdSupportConstants.AUTHORIZATION_BEARER + accessToken,
                                                                              endpoint,
                                                                              null);
            String apiType = API_DOCUMENT_SUBMISSION;
            if(response.statusCode == 201){
                claimRecord = populateAPIFields(apiType, request, response, claimRecord);
                CDdClaimInformation.ClaimDocumentResponse claimDocResponse = (CDdClaimInformation.ClaimDocumentResponse) JSON.deserialize(response.body, CDdClaimInformation.ClaimDocumentResponse.class);
                for(CDdClaimInformation.ClaimDocURL docURL : claimDocResponse.documentURLs){
                    if(attachmentMap.containsKey(docURL.name) || fileMap.containsKey(docURL.name)){
                        HttpRequest putRequest = new HttpRequest();
                        Blob body = attachmentMap.containsKey(docURL.name) ? attachmentMap.get(docURL.name).Body
                            : fileMap.get(docURL.name).ContentDocument.LatestPublishedVersion.VersionData;
                        putRequest.setBodyAsBlob(body);
                        putRequest.setEndpoint(docURL.url);
                        putRequest.setMethod(CDdSupportConstants.PUT_METHOD);
                        HttpResponse resp = new Http().send(putRequest);
                        response = new CDdRestJSONObj.RestAPIResponse();
                        response.body = resp.getBody();
                        response.statusCode = resp.getStatusCode();
                        response.status = resp.getStatus();
                        apiType = API_S3_FILE_UPDATION;
                        request = null;
                    }
                }
            }
            claimResponse = updateClaim(apiType, request, response, claimRecord);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return claimResponse;
    }

    /**
     * @author  Mahesh Chouhan
     * @date    June 2023
     * @description method to get access token for Claims Callout
     * @return Access token
    */
    public static CDdRestJSONObj.RestAPIResponse getAccessToken() {
        String namedCredentail = CDdUtilities.getIsSandbox() ? claimIntegrationSettings.Sandbox_Named_Credentail__c
            : claimIntegrationSettings.Named_Credentail__c;

        CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
        CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI(CDdSupportConstants.POST_METHOD,AUTHORIZAION_BODY, CDdCoreConstants.BLANK_STRING,
                                                                          CDdCoreConstants.BLANK_STRING, CDdCoreConstants.BLANK_STRING,
                                                                          CDdSupportConstants.CONTENT_TYPE_URL_ENCODED,
                                                                          namedCredentail);
        return response;
    }

    /**
     * @author  Mahesh Chouhan
     * @date    June 2023
     * @description get phone number in +9-999-9999999 format
     * @param String phone number
     * @return String phone number in +9-999-9999999 format
    */
    private static String getInternalPhoneFormat(String phone) {
        String trimmedPhone = phone.deleteWhitespace()
                                   .replaceAll('\\+1', CDdCoreConstants.BLANK_STRING)
                                   .replaceAll(CDdCoreConstants.DELIMITER_HYPHEN, CDdCoreConstants.BLANK_STRING)
                                   .replace(CDdCoreConstants.PARENTHESES_LEFT, CDdCoreConstants.BLANK_STRING)
                                   .replace(CDdCoreConstants.PARENTHESES_RIGHT, CDdCoreConstants.BLANK_STRING);

        return String.format(INTERNATIONAL_PHONE_FORMAT, new List<String>{trimmedPhone.mid(0,3), trimmedPhone.mid(3,7)});
    }

    /**
     * @author  Mahesh Chouhan
     * @date    June 2023
     * @description Check if Claim is already submitted for current Claim or Parent Case
     * @param claimRecord Current claim record
     * @return String contains error message
    */
    private static String validateClaim(Claim__c claimRecord){
        String returnValue = '';
        if(String.isNotBlank(claimRecord.Claim_Number__c)) {
            return CLAIM_ALREADY_SUBMITTED_MESG;
        }

        List<Claim__c> caseClaims = [SELECT Id, Name FROM Claim__c WHERE Case__c = :claimRecord.Case__c AND Claim_Number__c != null];

        if(caseClaims.size() > 0){
            returnValue = CLAIM_ALREADY_SUBMITTED_CASE_MESG + caseClaims[0].Name;
        }
        return returnValue;
    }

    /**
     * @author  Mahesh Chouhan
     * @date    June 2023
     * @description Check if Claim is already submitted for current Claim or Parent Case
     * @param String apiType
     * @param Object request
     * @param CDdRestJSONObj.RestAPIResponse httpResponse
     * @param Claim__c claimRecord
     * @return Claim__c claimRecord
    */
    public static Claim__c populateAPIFields(String apiType, Object request, CDdRestJSONObj.RestAPIResponse httpResponse, Claim__c claimRecord){
        if(apiType == API_CLAIM_SUBMISSION){
            claimRecord.API_Type__c = apiType;
            claimRecord.Request_Payload__c = request != null ? JSON.serialize(request, true) : CDdCoreConstants.BLANK_STRING;
            claimRecord.Response_Payload__c = httpResponse.body;
        }
        else {
            claimRecord.API_Type__c = claimRecord.API_Type__c + ';' + apiType;
            claimRecord.Request_Payload__c = request != null ? claimRecord.Request_Payload__c + ';' + JSON.serialize(request, true) : claimRecord.Request_Payload__c + ';' + CDdCoreConstants.BLANK_STRING;
            claimRecord.Response_Payload__c = claimRecord.Response_Payload__c + ';' + httpResponse.body;
        }

        return claimRecord;
    }

    /**
     * @author  Mahesh Chouhan
     * @date    June 2023
     * @description Update API Request and Response on Claim object
     * @param String apiType
     * @param Object request
     * @param CDdRestJSONObj.RestAPIResponse httpResponse
     * @param Claim__c claimToUpdate
     * @return ClaimResponse containing ClaimNumber or Errors
    */
    public static CDdClaimInformation.ClaimResponse updateClaim(String apiType, Object request, CDdRestJSONObj.RestAPIResponse httpResponse, Claim__c claimToUpdate){
        CDdClaimInformation.ClaimResponse claimResponse = new CDdClaimInformation.ClaimResponse();

        claimToUpdate = populateAPIFields(apiType, request, httpResponse, claimToUpdate);

        claimToUpdate.API_Status_Code__c = String.valueOf(httpResponse.statusCode);
        claimToUpdate.API_Status__c = httpResponse.status;

        if(httpResponse.statusCode == 201 || httpResponse.statusCode == 200){
            claimResponse.status = CDdSupportConstants.SUCCESS_LABEL;
            if(apiType == API_CLAIM_SUBMISSION) {
                claimToUpdate.First_Notice_of_Loss_Date__c = Date.today();
            }
        }
        else {
            CDdClaimInformation.ClaimErrorResponse errorResponse = (CDdClaimInformation.ClaimErrorResponse) JSON.deserialize(httpResponse.body, CDdClaimInformation.ClaimErrorResponse.class);
            claimResponse.status = CDdSupportConstants.FAILURE_LABEL;
            claimResponse.message = String.format(CHECK_RESPONSE_PAYLOAD_MESG, new List<String>{errorResponse.message});
            claimResponse.errors = errorResponse.errors;
        }
        update claimToUpdate;
        return claimResponse;
    }

    /**
     * @author  Mahesh Chouhan
     * @date    July 2023
     * @description Copy documents from Case and Email related to Case to Claim
     * @param claimId Claim Record Id
    */
    @AuraEnabled
    public static String syncDocuments(String claimId){
        String result = '';
        try {
            List<Attachment> claimAttachments = new List<Attachment>();
            Set<String> existingDocNames = new Set<String>();
            Set<Id> contentDocumentIds = new Set<Id>();

            Claim__c claimRecord = [SELECT Id, Case__c, (SELECT Id, Name FROM Attachments),
                                    (SELECT ContentDocument.Title FROM ContentDocumentLinks)
                                    FROM Claim__c WHERE Id = :claimId];

            for(Attachment doc : claimRecord.Attachments){
                existingDocNames.add(doc.Name);
            }

            for(ContentDocumentLink docLink : claimRecord.ContentDocumentLinks){
                existingDocNames.add(docLink.ContentDocument.Title);
            }

            Set<Id> parentIds = new Set<Id>{claimRecord.Case__c};
            List<EmailMessage> emailMessages = [SELECT ID FROM EmailMessage WHERE ParentId = :claimRecord.Case__c];

            for(EmailMessage email : emailMessages){
                parentIds.add(email.Id);
            }

            List<Attachment> docs = [SELECT Id, Body, Name
                                     FROM Attachment
                                     WHERE ParentId IN :parentIds AND Name NOT IN :existingDocNames];

            List<ContentVersion> claimFiles = new List<ContentVersion>();
            for(ContentDocumentLink contentDocumentLink : [SELECT ContentDocumentId, ContentDocument.LatestPublishedVersion.VersionData,
                                                           ContentDocument.FileExtension, ContentDocument.Title, ContentDocument.LatestPublishedVersion.PathOnClient
                                                           FROM ContentDocumentLink
                                                           WHERE LinkedEntityId = :parentIds AND ContentDocument.Title NOT IN :existingDocNames]){
                ContentVersion claimFile = new ContentVersion();
                claimFile.Title = contentDocumentLink.ContentDocument.Title;
                claimFile.PathOnClient = contentDocumentLink.ContentDocument.LatestPublishedVersion.PathOnClient;
                claimFile.VersionData = contentDocumentLink.ContentDocument.LatestPublishedVersion.VersionData;
                claimFile.IsMajorVersion = true;
                claimFiles.add(claimFile);
            }

            if(docs.isEmpty() && claimFiles.isEmpty()){
                throw new CDdClaimsCalloutControllerException(NO_NEW_DOCUMENT_FOUND_MESG);
            }

            insert claimFiles;

            Set<Id> insertedClaimFileIds = new Set<Id>();

            for(ContentVersion claimFile : claimFiles){
                insertedClaimFileIds.add(claimFile.Id);
            }

            claimFiles = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ID IN :insertedClaimFileIds];

            List<ContentDocumentLink> insertContentDocumentLinks = new List<ContentDocumentLink>();
            for(ContentVersion claimFile : claimFiles){
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = claimRecord.Id;
                cdl.ContentDocumentId = claimFile.ContentDocumentId;
                cdl.shareType = 'V';
                insertContentDocumentLinks.add(cdl);
            }

            for(Attachment doc : docs){
                if(!existingDocNames.contains(doc.Name)){
                    Attachment claimDoc = doc.clone();
                    claimDoc.ParentId = claimId;
                    claimAttachments.add(claimDoc);
                }
            }

            if(!claimAttachments.isEmpty()){
                insert claimAttachments;
            }

            if(!insertContentDocumentLinks.isEmpty()){
                insert insertContentDocumentLinks;
            }

            result = CDdSupportConstants.SUCCESS_LABEL;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return result;
    }

    /**
     * @description Custom Exception
     **/
    public class CDdClaimsCalloutControllerException extends Exception {}
}