/**
 * Created by scott on 9/4/22.
 */

@IsTest( IsParallel=true )
private class OpportunityGettersSpec {
    @IsTest
    static void testWhenCallingGetOpportunitiesThenItShouldReturnAListOfAllCaseRecords() {
        // Arrange
        Opportunity[] testRecords = new Opportunity[]{
            (Opportunity) new Fake( Opportunity.class ).toSObject(),
            (Opportunity) new Fake( Opportunity.class ).toSObject(),
            (Opportunity) new Fake( Opportunity.class ).toSObject()
        };
        IOpportunities domain = Opportunities.newInstance( testRecords );
        // Act
        Opportunity[] results = domain.getOpportunities();
        // Assert
        System.assert( domain.getOpportunities() instanceof List<Opportunity> );
        System.assertEquals( testRecords, results );
    }
}