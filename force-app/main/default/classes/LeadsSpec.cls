/**
 * Created by scott on 9/3/22.
 */

@IsTest( IsParallel=true )
private class LeadsSpec {

    @IsTest
    static void testWhenCallingRecordTypesThenItShouldReturnAnInstanceOfRecordTypeInfosDomainClass() {
        RecordTypeInfo info = Leads.RecordTypes.getByName( 'Master' );
        System.assert( info != null );
        System.assertEquals( 'Master', info.getName() );
    }

    @IsTest
    static void testWhenCallingNewInstanceThenItShouldResolveAnInstanceOfILeadsInterfaceFromApplicationFactory() {
        // Arrange
        Lead[] testRecords = new Lead[]{
            (Lead) new Fake( Lead.class ).toSObject(),
            (Lead) new Fake( Lead.class ).toSObject()
        };
        // Act
        Object domain = Leads.newInstance( testRecords );
        // Assert
        System.assert( domain instanceof ILeads );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfLeadRecordsThenItShouldReturnSObjectDomainInstanceWithLeadSObjectType() {
        // Arrange
        Lead[] testRecords = new Lead[]{
            (Lead) new Fake( Lead.class ).toSObject(),
            (Lead) new Fake( Lead.class ).toSObject()
        };
        // Act
        ILeads domain = Leads.newInstance( testRecords );
        // Assert
        System.assertEquals( Lead.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyCollectionOfSObjectRecordsThenItShouldReturnSObjectDomainInstanceWithLeadSObjectType() {
        // Arrange
        SObject[] testRecords = new SObject[]{}; // Sometimes the record collection argument received by newInstance() does not have type of List<Lead>
        // Act
        ILeads domain = Leads.newInstance( testRecords );
        // Assert
        System.assertEquals( Lead.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfLeadRecordsThenItShouldReturnSObjectDomainInstanceWithGivenLeads() {
        // Arrange
        Lead[] testRecords = new Lead[]{
            (Lead) new Fake( Lead.class ).toSObject(),
            (Lead) new Fake( Lead.class ).toSObject()
        };
        // Act
        ILeads domain = Leads.newInstance( testRecords );
        // Assert
        System.assertEquals( 2, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyListOfLeadsThenItShouldResolveReturnSObjectDomainInstanceWithEmptyCollectionOfLeads() {
        // Arrange
        Lead[] testRecords = new Lead[]{};
        // Act
        ILeads domain = Leads.newInstance( testRecords );
        // Assert
        System.assertEquals( 0, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }
}