/**
 * Created by scott on 9/3/22.
 */

@IsTest( IsParallel=true )
private class CaseGettersSpec {
    @IsTest
    static void testWhenCallingGetCasesThenItShouldReturnAListOfAllCaseRecords() {
        // Arrange
        Case[] testRecords = new Case[]{
            (Case) new Fake( Case.class ).toSObject(),
            (Case) new Fake( Case.class ).toSObject(),
            (Case) new Fake( Case.class ).toSObject()
        };
        ICases domain = Cases.newInstance( testRecords );
        // Act
        Case[] results = domain.getCases();
        // Assert
        System.assert( domain.getCases() instanceof List<Case> );
        System.assertEquals( testRecords, results );
    }
}