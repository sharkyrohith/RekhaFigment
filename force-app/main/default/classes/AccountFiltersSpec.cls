/**
 * Created by scott on 8/16/22.
 */

@IsTest( IsParallel=true )
private class AccountFiltersSpec {
    @IsTest
    static void testWhenCallingFilteredByOwnerIdThenItShouldReturnDomainCollectionContainingRecordsMatchingGivenValue() {
        // Arrange
        Id ownerId1 = Fake.generateId( User.class );
        Id ownerId2 = Fake.generateId( User.class );
        Id ownerId3 = Fake.generateId( User.class );
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.OwnerId, ownerId1 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.OwnerId, ownerId2 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.OwnerId, ownerId3 ).toSObject()
        };
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords ).filterByOwnerId( new Set<Id>{ ownerId1, ownerId2 } );
        // Assert
        System.assertEquals( 2, accounts.size() );
        System.assertEquals( ownerId1, accounts.getAccounts()[0].OwnerId );
        System.assertEquals( ownerId2, accounts.getAccounts()[1].OwnerId );
    }

    @IsTest
    static void testWhenCallingFilteredByParentIdThenItShouldReturnDomainCollectionContainingRecordsMatchingGivenValue() {
        // Arrange
        Id parentId1 = Fake.generateId( User.class );
        Id parentId2 = Fake.generateId( User.class );
        Id parentId3 = Fake.generateId( User.class );
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.ParentId, parentId1 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, parentId2 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, parentId3 ).toSObject()
        };
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords ).filterByParentId( new Set<Id>{ parentId1, parentId2 } );
        // Assert
        System.assertEquals( 2, accounts.size() );
        System.assertEquals( parentId1, accounts.getAccounts()[0].ParentId );
        System.assertEquals( parentId2, accounts.getAccounts()[1].ParentId );
    }

    @IsTest
    static void testWhenCallingParentIdNotBlankThenItShouldReturnDomainCollectionContainingRecordsWithAValueInParentIdField() {
        // Arrange
        Id parentId1 = Fake.generateId( User.class );
        Id parentId2 = Fake.generateId( User.class );
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.ParentId, parentId1 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, parentId2 ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords ).whereParentIdNotBlank();
        // Assert
        System.assertEquals( 2, accounts.size() );
        System.assertEquals( parentId1, accounts.getAccounts()[0].ParentId );
        System.assertEquals( parentId2, accounts.getAccounts()[1].ParentId );
    }

    @IsTest
    static void testWhenCallingParentIdBlankThenItShouldReturnDomainCollectionContainingRecordsWithParentIdHavingWhiteSpaceEmptyOrNullValues() {
        // Arrange
        Id parentId1 = Fake.generateId( User.class );
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.ParentId, parentId1 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, '' ).toSObject(), // Empty
            (Account) new Fake( Account.class ).setField( Account.ParentId, ' ' ).toSObject(), // Whitespace
            (Account) new Fake( Account.class ).toSObject() // Null
        };
        // Act
        IAccounts accounts = Accounts.newInstance( testRecords ).whereParentIdBlank();
        // Assert
        System.assertEquals( 3, accounts.size() );
        System.assert( String.isBlank( accounts.getAccounts()[0].ParentId ) );
        System.assert( String.isBlank( accounts.getAccounts()[1].ParentId ) );
        System.assert( String.isBlank( accounts.getAccounts()[2].ParentId ) );
    }
}