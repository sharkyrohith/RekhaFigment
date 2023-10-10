/**
 * @author: Mahesh Chouhan
 * @date : Aug 2023
 * @description: Factory to create Claim
 */

public class CDdClaimFactory {

    public static final String CLAIM_TYPE_AUTO = 'Auto';

    /**
     * @description Create Auto Claims for Case
     */
    public static List<Claim__c> createAutoClaims(Integer numberOfClaims, Id caseId, Id reportingPartingAccountId, boolean doInsert){
        return createClaims(numberOfClaims, caseId, reportingPartingAccountId, CLAIM_TYPE_AUTO, doInsert);
    }

    /**
     * @description Create Claims for Case
     */
    public static List<Claim__c> createClaims(Integer numberOfClaims, Id caseId, Id reportingPartingAccountId, String claimType, boolean doInsert){
        List<Claim__c> claimsToBeInsert = new List<Claim__c>();
        for (Integer count = 0 ; count < numberOfClaims; count++){
            Claim__c claimRecord = new Claim__c();
            claimRecord.Facts_of_Loss__c = 'Test Facts of Loss';
            claimRecord.Case__c = caseId;
            claimRecord.Claim_Type__c = 'Auto';
            claimRecord.Reporting_Party_Name__c = reportingPartingAccountId;
            claimRecord.Date_of_Loss__c = DateTime.now();
            claimRecord.Loss_Location_Street__c = '116 New Montgomery St,';
            claimRecord.Loss_Location_City__c = 'San Francisco ';
            claimRecord.Loss_Location_State_Province__c = 'US-CA';
            claimRecord.Loss_Location_Country__c = 'USA';
            claimRecord.Loss_Location_Zip_Postal_Code__c = '94107';
            claimRecord.Dasher_FirstName__c = 'Test';
            claimRecord.Dasher_LastName__c = 'Dasher';
            claimRecord.Dasher_Email__c = 'test.dasher@test.com';
            claimRecord.Dasher_City__c = 'San Francisco';
            claimRecord.Dasher_State_Province__c = 'US-CA';
            claimRecord.Dasher_Country__c = 'USA';
            claimRecord.Delivery_UUID__c = 'testDeliveryUuid';
            claimRecord.Drive_Partner__c = 'Test Dasher';
            claimRecord.Dasher_ID__c = 1234567;

            claimsToBeInsert.add(claimRecord);
        }

        if(doInsert) {
            insert claimsToBeInsert;
        }
        return claimsToBeInsert;
    }
}