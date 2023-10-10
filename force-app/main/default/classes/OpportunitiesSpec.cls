/**
 * Created by scott on 9/4/22.
 */

@IsTest( IsParallel=true )
private class OpportunitiesSpec {

    @IsTest
    static void testWhenCallingRecordTypesThenItShouldReturnAnInstanceOfRecordTypeInfosDomainClass() {
        RecordTypeInfo info = Opportunities.RecordTypes.getByName( 'Master' );
        System.assert( info != null );
        System.assertEquals( 'Master', info.getName() );
    }

    @IsTest
    static void testWhenCallingNewInstanceThenItShouldResolveAnInstanceOfIOpportunitiesInterfaceFromApplicationFactory() {
        // Arrange
        Opportunity[] testRecords = new Opportunity[]{
            (Opportunity) new Fake( Opportunity.class ).toSObject(),
            (Opportunity) new Fake( Opportunity.class ).toSObject()
        };
        // Act
        Object domain = Opportunities.newInstance( testRecords );
        // Assert
        System.assert( domain instanceof IOpportunities );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfCaseRecordsThenItShouldReturnSObjectDomainInstanceWithCaseSObjectType() {
        // Arrange
        Opportunity[] testRecords = new Opportunity[]{
            (Opportunity) new Fake( Opportunity.class ).toSObject(),
            (Opportunity) new Fake( Opportunity.class ).toSObject()
        };
        // Act
        IOpportunities domain = Opportunities.newInstance( testRecords );
        // Assert
        System.assertEquals( Opportunity.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyCollectionOfSObjectRecordsThenItShouldReturnSObjectDomainInstanceWithCaseSObjectType() {
        // Arrange
        SObject[] testRecords = new SObject[]{}; // Sometimes the record collection argument received by newInstance() does not have type of List<Opportunity>
        // Act
        IOpportunities domain = Opportunities.newInstance( testRecords );
        // Assert
        System.assertEquals( Opportunity.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfCaseRecordsThenItShouldReturnSObjectDomainInstanceWithGivenOpportunities() {
        // Arrange
        Opportunity[] testRecords = new Opportunity[]{
            (Opportunity) new Fake( Opportunity.class ).toSObject(),
            (Opportunity) new Fake( Opportunity.class ).toSObject()
        };
        // Act
        IOpportunities domain = Opportunities.newInstance( testRecords );
        // Assert
        System.assertEquals( 2, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyListOfOpportunitiesThenItShouldResolveReturnSObjectDomainInstanceWithEmptyCollectionOfOpportunities() {
        // Arrange
        Opportunity[] testRecords = new Opportunity[]{};
        // Act
        IOpportunities domain = Opportunities.newInstance( testRecords );
        // Assert
        System.assertEquals( 0, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }
}