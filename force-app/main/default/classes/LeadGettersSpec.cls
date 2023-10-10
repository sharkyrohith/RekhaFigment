/**
 * Created by scott on 9/3/22.
 */

@IsTest( IsParallel=true )
private class LeadGettersSpec {
    @IsTest
    static void testWhenCallingGetLeadsThenItShouldReturnAListOfAllLeadRecords() {
        // Arrange
        Lead[] testRecords = new Lead[]{
            (Lead) new Fake( Lead.class ).toSObject(),
            (Lead) new Fake( Lead.class ).toSObject(),
            (Lead) new Fake( Lead.class ).toSObject()
        };
        ILeads domain = Leads.newInstance( testRecords );
        // Act
        Lead[] results = domain.getLeads();
        // Assert
        System.assert( domain.getLeads() instanceof List<Lead> );
        System.assertEquals( testRecords, results );
    }
}