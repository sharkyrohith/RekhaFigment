/**
 * Created by scott on 9/3/22.
 */

@IsTest( IsParallel=true )
private class CasesSpec {

    @IsTest
    static void testWhenCallingRecordTypesThenItShouldReturnAnInstanceOfRecordTypeInfosDomainClass() {
        RecordTypeInfo info = Cases.RecordTypes.getByName( 'Master' );
        System.assert( info != null );
        System.assertEquals( 'Master', info.getName() );
    }

    @IsTest
    static void testWhenCallingNewInstanceThenItShouldResolveAnInstanceOfICasesInterfaceFromApplicationFactory() {
        // Arrange
        Case[] testRecords = new Case[]{
            (Case) new Fake( Case.class ).toSObject(),
            (Case) new Fake( Case.class ).toSObject()
        };
        // Act
        Object domain = Cases.newInstance( testRecords );
        // Assert
        System.assert( domain instanceof ICases );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfCaseRecordsThenItShouldReturnSObjectDomainInstanceWithCaseSObjectType() {
        // Arrange
        Case[] testRecords = new Case[]{
            (Case) new Fake( Case.class ).toSObject(),
            (Case) new Fake( Case.class ).toSObject()
        };
        // Act
        ICases domain = Cases.newInstance( testRecords );
        // Assert
        System.assertEquals( Case.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyCollectionOfSObjectRecordsThenItShouldReturnSObjectDomainInstanceWithCaseSObjectType() {
        // Arrange
        SObject[] testRecords = new SObject[]{}; // Sometimes the record collection argument received by newInstance() does not have type of List<Case>
        // Act
        ICases domain = Cases.newInstance( testRecords );
        // Assert
        System.assertEquals( Case.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfCaseRecordsThenItShouldReturnSObjectDomainInstanceWithGivenCases() {
        // Arrange
        Case[] testRecords = new Case[]{
            (Case) new Fake( Case.class ).toSObject(),
            (Case) new Fake( Case.class ).toSObject()
        };
        // Act
        ICases domain = Cases.newInstance( testRecords );
        // Assert
        System.assertEquals( 2, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyListOfCasesThenItShouldResolveReturnSObjectDomainInstanceWithEmptyCollectionOfCases() {
        // Arrange
        Case[] testRecords = new Case[]{};
        // Act
        ICases domain = Cases.newInstance( testRecords );
        // Assert
        System.assertEquals( 0, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }
}