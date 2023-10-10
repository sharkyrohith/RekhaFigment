/**
 * @description Unit tests for UsersSelector class
 * @author Scott McClung
 * @date 2022/09/13
 */
@IsTest
private class UsersSelectorSpec {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheUserSObject() {
        SObjectType actualType = new UsersSelector().getSObjectType();
        System.assertEquals(
            User.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting User.SObjectType and received: ' + actualType );
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            User.Id,
            User.Name,
            User.ADR__c,
            User.Email,
            User.UserProfile__c,
            User.UserRole__c,
            User.Photo_Document_URL__c
        };

        SObjectField[] actualTokens = new UsersSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenCallingNewInstanceThenItShouldReturnSelectorForUsersObject() {
        SObjectType actualType = UsersSelector.newInstance().sObjectType();
        System.assertEquals(
            User.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting User.SObjectType and received: ' + actualType );
    }

    @IsTest
    static void testWhenCallingSelectByIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        User[] records = TDdUserFactory.createUsers( 3 );
        insert records;

        // Act
        Map<Id, User> testRecords = new Map<Id, User>(
            new UsersSelector().selectById( new Set<Id>{
                records[0].Id,
                records[1].Id
            } ) );

        // Assert
        System.assert( testRecords.keySet().contains( records[0].Id ) );
        System.assert( testRecords.keySet().contains( records[1].Id ) );
        System.assertEquals( 2, testRecords.size() );
    }

    @IsTest
    static void testWhenCallingSelectByIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        // Arrange
        User[] records = TDdUserFactory.createUsers( 3 );
        insert records;

        // Act
        User[] testRecords = new UsersSelector().selectById( new Set<Id>{
            Fake.generateId( User.class ),
            Fake.generateId( User.class )
        } );

        // Assert
        System.assert( testRecords.isEmpty() );
    }
}