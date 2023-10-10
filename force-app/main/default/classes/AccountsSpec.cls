/**
 * Created by scott on 8/16/22.
 */

@IsTest( IsParallel=true )
private class AccountsSpec {
    @IsTest
    static void testWhenCallingRecordTypesThenItShouldReturnAnInstanceOfRecordTypeInfosDomainClass() {
        RecordTypeInfo info = Accounts.RecordTypes.getByName( 'Master' );
        System.assert( info != null );
        System.assertEquals( 'Master', info.getName() );
    }

    @IsTest
    static void testWhenCallingNewInstanceThenItShouldResolveAnInstanceOfIAccountsInterfaceFromApplicationFactory() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        // Act
        Object accounts = Accounts.newInstance( testRecords );
        // Assert
        System.assert( accounts instanceof IAccounts );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfAccountRecordsThenItShouldReturnSObjectDomainInstanceWithAccountSObjectType() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Assert
        System.assertEquals( Account.SObjectType, accounts.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyCollectionOfSObjectRecordsThenItShouldReturnSObjectDomainInstanceWithAccountSObjectType() {
        // Arrange
        SObject[] testRecords = new SObject[]{}; // Sometimes the record collection argument received by newInstance() does not have type of List<Account>
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Assert
        System.assertEquals( Account.SObjectType, accounts.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfAccountRecordsThenItShouldReturnSObjectDomainInstanceWithGivenAccounts() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Assert
        System.assertEquals( 2, accounts.getRecords().size() );
        System.assertEquals( testRecords, accounts.getRecords() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyListOfAccountsThenItShouldResolveReturnSObjectDomainInstanceWithEmptyCollectionOfAccounts() {
        // Arrange
        Account[] testRecords = new Account[]{};
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Assert
        System.assertEquals( 0, accounts.getRecords().size() );
        System.assertEquals( testRecords, accounts.getRecords() );
    }
}