/**
 * Created by scott on 8/16/22.
 */

@IsTest( IsParallel=true )
private class AccountGettersSpec {
    @IsTest
    static void testWhenCallingGetAccountsThenItShouldReturnAListOfAllAccountRecords() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).toSObject(),
            (Account) new Fake( Account.class ).toSObject(),
            (Account) new Fake( Account.class ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Act
        Account[] testAccounts = accounts.getAccounts();
        // Assert
        System.assert( accounts.getAccounts() instanceof List<Account> );
        System.assertEquals( testRecords, testAccounts );
    }

    @IsTest
    static void testWhenCallingGetAccountsByIdThenItShouldReturnAMapOfAllAccountsGroupedByAccountId() {
        // Arrange
        Id accountId1 = Fake.generateId( Account.class );
        Id accountId2 = Fake.generateId( Account.class );
        Id accountId3 = Fake.generateId( Account.class );
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.Id, accountId1 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.Id, accountId2 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.Id, accountId3 ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );
        // Act
        Map<Id, Account> mapAccountsById = accounts.getAccountsById();
        // Assert
        System.assert( mapAccountsById.keySet().contains( accountId1 ) );
        System.assert( mapAccountsById.keySet().contains( accountId2 ) );
        System.assert( mapAccountsById.keySet().contains( accountId3 ) );
        System.assertEquals( accountId1, mapAccountsById.get( accountId1 ).Id );
        System.assertEquals( accountId2, mapAccountsById.get( accountId2 ).Id );
        System.assertEquals( accountId3, mapAccountsById.get( accountId3 ).Id );
    }

    @IsTest
    static void testWhenCallingGetNamesThenItShouldReturnASetOfAllAccountNames() {
        // Arrange
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.Name, 'Name 1' ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.Name, 'Name 2' ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.Name, 'Name 3' ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );

        // Act
        List<String> names = accounts.getNames();

        // Assert
        System.assertEquals( new List<String>{ 'Name 1', 'Name 2', 'Name 3' }, names );
    }

    @IsTest
    static void testWhenCallingGetNamesOnEmptyDomainThenItShouldReturnAnEmptyListOfStrings() {
        // Arrange
        IAccounts accounts = Accounts.newInstance( new Account[]{} );

        // Act
        List<String> names = accounts.getNames();

        // Assert
        System.assertEquals( new List<String>(), names );
    }

    @IsTest
    static void testWhenCallingGetOwnerIdsThenItShouldReturnASetOfAllOwnerIds() {
        // Arrange
        Id userId1 = Fake.generateId( User.class );
        Id userId2 = Fake.generateId( User.class );
        Id userId3 = Fake.generateId( User.class );
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.OwnerId, userId1 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.OwnerId, userId2 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.OwnerId, userId3 ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );

        // Act
        Set<Id> ownerIds = accounts.getOwnerIds();

        // Assert
        System.assertEquals( new Set<Id>{ userId1, userId2, userId3 }, ownerIds );
    }

    @IsTest
    static void testWhenCallingGetOwnerIdsOnEmptyDomainThenItShouldReturnAnEmptySetOfIds() {
        // Arrange
        IAccounts accounts = Accounts.newInstance( new Account[]{} );

        // Act
        Set<Id> ownerIds = accounts.getOwnerIds();

        // Assert
        System.assertEquals( new Set<Id>(), ownerIds );
    }

    @IsTest
    static void testWhenCallingGetParentIdsThenItShouldReturnASetOfAllParentIds() {
        // Arrange
        Id accountId1 = Fake.generateId( Account.class );
        Id accountId2 = Fake.generateId( Account.class );
        Id accountId3 = Fake.generateId( Account.class );
        Account[] testRecords = new Account[]{
            (Account) new Fake( Account.class ).setField( Account.ParentId, accountId1 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, accountId2 ).toSObject(),
            (Account) new Fake( Account.class ).setField( Account.ParentId, accountId3 ).toSObject()
        };
        IAccounts accounts = Accounts.newInstance( testRecords );

        // Act
        Set<Id> parentIds = accounts.getParentIds();

        // Assert
        System.assertEquals( new Set<Id>{ accountId1, accountId2, accountId3 }, parentIds );
    }

    @IsTest
    static void testWhenCallingGetParentIdsOnEmptyDomainThenItShouldReturnAnEmptySetOfIds() {
        // Arrange
        IAccounts accounts = Accounts.newInstance( new Account[]{} );

        // Act
        Set<Id> parentIds = accounts.getParentIds();

        // Assert
        System.assertEquals( new Set<Id>(), parentIds );
    }
}