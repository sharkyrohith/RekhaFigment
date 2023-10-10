/**
 * @author  Mahesh Chouhan
 * @date    June 2023
 * @description Wrapper for Claim Integration
 */

public with sharing class CDdClaimInformation {

    public class ClaimsRequest {
        public InsuredOrPrincipal insuredOrPrincipal { get; set; }
        public ClaimsOccurrence claimsOccurrence { get; set; }
        public InsuredVehicle insuredVehicle { get; set; }
        public List<InsuredVehicle> thirdPartyVehicles { get; set; }
        public List<BicyclistOrPedestrian> bicyclistsOrPedestrians { get; set; }
        public AutoEventDetails autoEventDetails { get; set; }
        public ClaimReportedBy claimReportedBy { get; set; }
        public CustomDataFields customDataFields { get; set; }
    }

    public class InsuredOrPrincipal {
        public Integer accountStakeholderID { get; set; }
        public String lineOfBusinessCode { get; set; }
        public String policyNumber { get; set; }
        public String policyEffectiveDate { get; set; }
        public String policyExpirationDate { get; set; }
        public Map<String, String> organizationName { get; set; }
        public PrimaryAddress primaryAddress { get; set; }
        public BusinessPhone businessPhone { get; set; }
    }

    public class PrimaryAddress {
        public String city { get; set; }
        public String stateProvinceCode { get; set; }
        public String countryCode { get; set; }
        public String addressLine1 { get; set; }
        public String addressLine2 { get; set; }
        public String postalCode { get; set; }
    }

    public class BusinessPhone {
        public String phoneNumber { get; set; }
    }

    public class ClaimsOccurrence {
        public String lossDate { get; set; }
        public String lossTime { get; set; }
        public String reportedToInsuredDateTime { get; set; }
        public String insuredReportNumber { get; set; }
    }

    public class AutoEventDetails {
        public String eventDescriptionCode { get; set; }
        public String eventDescriptionText { get; set; }
        public String eventStreetLine1 { get; set; }
        public String eventCity { get; set; }
        public String eventStateProvinceCode { get; set; }
        public String eventCountryCode { get; set; }
        public String eventPostalCode { get; set; }
        public Boolean seekingInsuredVehicleCoverageIndicator { get; set; }
        public String claimReportedByRelationshipToInsuredCode { get; set; }
    }

    public class ClaimReportedBy {
        public PersonName personName { get; set; }
        public BusinessPhone businessPhone { get; set; }
        public Email email { get; set; }
    }

    public class PersonName {
        public String firstName { get; set; }
        public String lastName { get; set; }
    }

    public class InsuredVehicle {
        public VehicleDetails vehicleDetails { get; set; }
        public VehicleDamages vehicleDamages { get; set; }
        public DriverCustodian driverCustodian { get; set; }
    }

    public class VehicleDetails {
        public String vehicleOwnershipTypeCode { get; set; }
        public String typeOfVehicle { get; set; }
        public String year { get; set; }
        public String make { get; set; }
        public String model { get; set; }
    }

    public class VehicleDamages {
        public String wasVehicleStopped { get; set; }
        public String pointOfImpactCode { get; set; }
        public String estimatedDamageSeverityCode { get; set; }
    }

    public class DriverCustodian {
        public PersonName personName { get; set; }
        public BusinessPhone businessPhone { get; set; }
        public Demographics demographics { get; set; }
        public Injury injury { get; set; }
        public PersonalPropertyDamage personalPropertyDamage { get; set; }
        public String wasDriverOrCustodianPresent { get; set; }
        public String relationshipToVehicleOwner { get; set; }
        public Email email { get; set; }
        public PrimaryAddress primaryAddress { get; set; }
    }

    public class BicyclistOrPedestrian {
        public String bicyclistOrPedestrianRoleCode { get; set; }
        public PersonName personName { get; set; }
        public BusinessPhone businessPhone { get; set; }
        public Injury injury { get; set; }
        public PersonalPropertyDamage personalPropertyDamage { get; set; }
        public Email email { get; set; }
    }

    public class Email {
        public String emailAddress {get; set;}
    }
    public class Demographics {
        public String genderCode { get; set; }
    }

    public class Injury {
        public Boolean sufferedBodilyInjuryIndicator { get; set; }
    }

    public class PersonalPropertyDamage {
        public Boolean personalPropertyDamagedIndicator { get; set; }
    }

    public class ClaimResponse {
        @AuraEnabled
        public String status {get; set; }
        @AuraEnabled
        public String message {get; set; }
        @AuraEnabled
        public List<ClaimError> errors {get; set;}
    }

    public class ClaimError {
        @AuraEnabled
        public String field {get; set; }
        @AuraEnabled
        public String message {get; set; }
    }

    public class ClaimErrorResponse {
        public String code {get; set; }
        public String message {get; set; }
        public List<ClaimError> errors {get; set;}
    }

    public class ClaimDocumentRequest {
        public String claimNumber {get; set; }
        public List<ClaimDocument> documents {get; set; }
    }

    public class ClaimDocument {
        public String name {get; set; }
        public String extension {get; set; }
        public String type {get; set; }
    }

    public class ClaimDocumentResponse {
        @AuraEnabled
        public List<ClaimDocURL> documentURLs {get; set; }
        @AuraEnabled
        public String error {get; set; }
    }

    public class ClaimDocURL {
        @AuraEnabled
        public String name {get; set; }
        @AuraEnabled
        public String url {get; set; }
    }

    public class CustomDataFields {
        public ClaimSpecificCode claimSpecificCode10 {get; set; }
        public ClaimSpecificCode claimSpecific80Character01 {get; set; }
        public ClaimSpecificCode claimSpecific80Character02 {get; set; }
        public ClaimSpecificCode claimSpecific120Character01 {get; set; }
    }

    public class ClaimSpecificCode {
        public String label {get; set; }
        public String description {get; set; }
        public String value {get; set; }
    }
}