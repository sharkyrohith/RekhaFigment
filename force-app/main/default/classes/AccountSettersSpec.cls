/**
 * Created by scott on 8/16/22.
 */

@IsTest( IsParallel=true )
private class AccountSettersSpec {
    @IsTest
    static void testWhenCallingSetNamesThenItShouldSetNameValueOnAllRecordsInDomainCollectionToGivenValue() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.Name, 'Name 1' ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.Name, 'Name 2' ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Act
        List<Account> testAccounts = accounts.setNames( 'New Name' ).getAccounts();
        // Assert
        System.assertEquals( 'New Name', testAccounts[0].Name );
        System.assertEquals( 'New Name', testAccounts[1].Name );
        System.assertEquals( 'New Name', testAccounts[2].Name );
    }

    @IsTest
    static void testWhenCallingSetNamesWithNullValueThenItShouldSetNameValueOnAllRecordsInDomainCollectionToNull() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.Name, 'Name 1' ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.Name, 'Name 2' ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Act
        String nullValue;
        List<Account> testAccounts = accounts.setNames( nullValue ).getAccounts();
        // Assert
        System.assert( String.isBlank( testAccounts[0].Name ) );
        System.assert( String.isBlank( testAccounts[1].Name ) );
        System.assert( String.isBlank( testAccounts[2].Name ) );
    }

    @IsTest
    static void testWhenCallingSetOwnerIdsThenItShouldSetOwnerIdValueOnAllRecordsInDomainCollectionToGivenValue() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.OwnerId, Fake.generateId( User.class ) ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.OwnerId, Fake.generateId( User.class ) ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        // Act
        Id newOwnerId = Fake.generateId( User.class );
        IAccounts accounts = Accounts.newInstance( testRecords ).setOwnerIds( newOwnerId );
        Account[] testAccounts = accounts.getAccounts();
        // Assert
        System.assertEquals( newOwnerId, testAccounts[0].OwnerId );
        System.assertEquals( newOwnerId, testAccounts[1].OwnerId );
        System.assertEquals( newOwnerId, testAccounts[2].OwnerId );
    }

    @IsTest
    static void testWhenCallingSetOwnerIdsWithNullValueThenItShouldSetOwnerIdValueOnAllRecordsInDomainCollectionToNull() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.OwnerId, Fake.generateId( User.class ) ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.OwnerId, Fake.generateId( User.class ) ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Act
        Id nullValue;
        List<Account> testAccounts = accounts.setOwnerIds( nullValue ).getAccounts();
        // Assert
        System.assert( String.isBlank( testAccounts[0].OwnerId ) );
        System.assert( String.isBlank( testAccounts[1].OwnerId ) );
        System.assert( String.isBlank( testAccounts[2].OwnerId ) );
    }

    @IsTest
    static void testWhenCallingSetParentIdsThenItShouldSetParentIdValueOnAllRecordsInDomainCollectionToGivenValue() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.ParentId, Fake.generateId( Account.class ) ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, Fake.generateId( Account.class ) ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        // Act
        Id newParentId = Fake.generateId( Account.class );
        IAccounts accounts = Accounts.newInstance( testRecords ).setParentIds( newParentId );
        Account[] testAccounts = accounts.getAccounts();
        // Assert
        System.assertEquals( newParentId, testAccounts[0].ParentId );
        System.assertEquals( newParentId, testAccounts[1].ParentId );
        System.assertEquals( newParentId, testAccounts[2].ParentId );
    }

    @IsTest
    static void testWhenCallingSetParentIdsWithNullValueThenItShouldSetParentIdValueOnAllRecordsInDomainCollectionToNull() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.ParentId, Fake.generateId( Account.class ) ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, Fake.generateId( Account.class ) ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Act
        Id nullValue;
        List<Account> testAccounts = accounts.setParentIds( nullValue ).getAccounts();
        // Assert
        System.assert( String.isBlank( testAccounts[0].ParentId ) );
        System.assert( String.isBlank( testAccounts[1].ParentId ) );
        System.assert( String.isBlank( testAccounts[2].ParentId ) );
    }
}