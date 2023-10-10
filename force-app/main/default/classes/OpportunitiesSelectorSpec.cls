/**
 * @description Unit Tests for the OpportunitiesSelector
 * @author Scott McClung
 * @date 2022/08/16
 */
@IsTest
private class OpportunitiesSelectorSpec {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheOpportunitySObject() {
        SObjectType actualType = new OpportunitiesSelector().getSObjectType();
        System.assertEquals(
            Opportunity.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Opportunity.SObjectType and received: ' + actualType );
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Opportunity.AccountId,
            Opportunity.CloseDate,
            Opportunity.Id,
            Opportunity.Name,
            Opportunity.OwnerId,
            Opportunity.RecordTypeId,
            Opportunity.StageName,
            Opportunity.Type,
            Opportunity.SBQQ__PrimaryQuote__c,
            Opportunity.Prebot_Link__c,
            Opportunity.Prebot_Error__c,
            Opportunity.Proposed_Date_of_Activation__c
        };

        SObjectField[] actualTokens = new OpportunitiesSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        Account objAccount = TDdAccountFactory.createAccount();
        insert objAccount;
        Opportunity[] records = new Opportunity[]{
            VTestUtil.createOpportunity( 'Test Opp 1', objAccount ),
            VTestUtil.createOpportunity( 'Test Opp 2', objAccount ),
            VTestUtil.createOpportunity( 'Test Opp 3', objAccount )
        };
        insert records;

        // Act
        Map<Id, Opportunity> testRecords = new Map<Id, Opportunity>( new OpportunitiesSelector().selectById( new Set<Id>{
            records[0].Id,
            records[1].Id
        } ) );

        // Assert
        System.assert( testRecords.keySet().contains( records[0].Id ) );
        System.assert( testRecords.keySet().contains( records[1].Id ) );
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        // Arrange
        Account objAccount = TDdAccountFactory.createAccount();
        insert objAccount;
        VTestUtil.createOpportunity( 'Test Opp 1', objAccount );

        // Act
        Map<Id, Opportunity> testRecords = new Map<Id, Opportunity>( new OpportunitiesSelector().selectById( new Set<Id>{
            Fake.generateId( Opportunity.class ),
            Fake.generateId( Opportunity.class )
        } ) );

        // Assert
        System.assert( testRecords.isEmpty() );
    }
}