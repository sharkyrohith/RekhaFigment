/**
 * Created by scott on 9/6/22.
 */

@IsTest
private class AccountHelperMethodsSpec {
    @IsTest
    static void testWhenCallingUpdateADRAndTheOwnerOfAnAccountChangesThenItShouldSetTheOwnersAccountDevelopmentRepOnTheAccountRecord() {
        // Arrange
        User[] users = generateUsersWithAccountDevelopmentReps();
        User user1 = users[0];
        User user2 = users[1];
        User user3 = users[2];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[0].Id )
                .setField( Account.OwnerId, user2.Id )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[1].Id )
                .setField( Account.OwnerId, user2.Id )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[2].Id )
                .setField( Account.OwnerId, user3.Id )
                .toSObject()
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector usersSelector = (IUsersSelector) mocks.mock( IUsersSelector.class );
        mocks.startStubbing();
        mocks.when( usersSelector.sObjectType() ).thenReturn( Schema.User.SObjectType );
        mocks.when( usersSelector.selectById( new Set<Id>{ user2.Id, user3.Id } ) ).thenReturn( new List<User>{ user2, user3 } );
        mocks.stopStubbing();
        Application.Selector.setMock( usersSelector );

        // Act
        CDdAccountHelperMethods.updateADR( newAccounts, oldAccounts );

        // Assert
        System.assertEquals( user2.ADR__c, newAccounts[0].ADR_Owner_Actual__c );
        System.assertEquals( user2.ADR__c, newAccounts[1].ADR_Owner_Actual__c );
        System.assertEquals( user3.ADR__c, newAccounts[2].ADR_Owner_Actual__c );
    }

    @IsTest
    static void testWhenCallingUpdateADRAndTheOwnerOfAnAccountDoesNotChangeThenItShouldDoNotChangeTheAccountDevelopmentRepValueOnTheAccountRecord() {
        // Arrange
        User[] users = generateUsersWithAccountDevelopmentReps();
        User user1 = users[0];
        User user3 = users[2];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[0].Id )
                .setField( Account.OwnerId, user3.Id )
                .setField( Account.ADR_Owner_Actual__c, user1.ADR__c )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[1].Id )
                .setField( Account.OwnerId, user1.Id )
                .setField( Account.ADR_Owner_Actual__c, user1.ADR__c )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[2].Id )
                .setField( Account.ADR_Owner_Actual__c, user1.ADR__c )
                .toSObject()
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector usersSelector = (IUsersSelector) mocks.mock( IUsersSelector.class );
        mocks.startStubbing();
        mocks.when( usersSelector.sObjectType() ).thenReturn( Schema.User.SObjectType );
        mocks.when( usersSelector.selectById( new Set<Id>{ user3.Id } ) ).thenReturn( new List<User>{ user3 } );
        mocks.stopStubbing();
        Application.Selector.setMock( usersSelector );

        // Act
        CDdAccountHelperMethods.updateADR( newAccounts, oldAccounts );

        // Assert
        System.assertEquals( user3.ADR__c, newAccounts[0].ADR_Owner_Actual__c );
        System.assertEquals( user1.ADR__c, newAccounts[1].ADR_Owner_Actual__c );
        System.assertEquals( user1.ADR__c, newAccounts[2].ADR_Owner_Actual__c );
    }

    @IsTest
    static void testWhenCallingUpdateADRAndNoneOfTheAccountsHaveHadAnOwnerChangeThenItShouldDoNotExecuteAUserQuery() {
        // Arrange
        User[] users = generateUsersWithAccountDevelopmentReps();
        User user1 = users[0];
        User user2 = users[1];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[0].Id )
                .setField( Account.OwnerId, user1.Id )
                .setField( Account.ADR_Owner_Actual__c, user2.ADR__c )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[1].Id )
                .setField( Account.OwnerId, user1.Id )
                .setField( Account.ADR_Owner_Actual__c, user2.ADR__c )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[2].Id )
                .setField( Account.ADR_Owner_Actual__c, user2.ADR__c )
                .toSObject()
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector usersSelector = (IUsersSelector) mocks.mock( IUsersSelector.class );
        Application.Selector.setMock( usersSelector );

        // Act
        CDdAccountHelperMethods.updateADR( newAccounts, oldAccounts );

        // Assert
        System.assertEquals( user2.ADR__c, newAccounts[0].ADR_Owner_Actual__c );
        System.assertEquals( user2.ADR__c, newAccounts[1].ADR_Owner_Actual__c );
        System.assertEquals( user2.ADR__c, newAccounts[2].ADR_Owner_Actual__c );

        // assert that we don't call the usersselector
        ( (IUsersSelector) mocks.verify( usersSelector, mocks.never() ) )
            .selectById( (Set<Id>) fflib_Match.anyObject() );
    }

    @IsTest
    static void testWhenCallingUpdateADRAndAccountOwnerHasChangedAndAccountDeveloperRepIdFromUserRecordIsNotAValidIdThenItShouldSetValueOnAccountToNull() {
        // Arrange
        User[] users = generateUsersWithAccountDevelopmentReps();
        User user1 = users[0];
        User user2 = users[1];
        User user3 = users[2];

        user2.ADR__c = '1234SomeRandomText';
        user3.ADR__c = '1234SomeRandomText';

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[0].Id )
                .setField( Account.OwnerId, user2.Id )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[1].Id )
                .setField( Account.OwnerId, user3.Id )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setField( Account.Id, oldAccounts.values()[2].Id )
                .setField( Account.OwnerId, user1.Id )
                .toSObject()
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector usersSelector = (IUsersSelector) mocks.mock( IUsersSelector.class );
        mocks.startStubbing();
        mocks.when( usersSelector.sObjectType() ).thenReturn( Schema.User.SObjectType );
        mocks.when( usersSelector.selectById( new Set<Id>{ user2.Id, user3.Id, user1.Id } ) ).thenReturn( new List<User>{ user2, user3, user1 } );
        mocks.stopStubbing();
        Application.Selector.setMock( usersSelector );

        // Act
        CDdAccountHelperMethods.updateADR( newAccounts, oldAccounts );

        // Assert
        System.assertEquals( null, newAccounts[0].ADR_Owner_Actual__c );
        System.assertEquals( null, newAccounts[1].ADR_Owner_Actual__c );
        System.assertEquals( user1.ADR__c, newAccounts[2].ADR_Owner_Actual__c );
    }

    @isTest
    static void testWhenAccountIsNewThenCleanEncryptedFields() {
        //Arrange
        //Creating In-memory data

        List<Account> accountList = generateAccounts();

        //ACT
        CDdAccountHelperMethods.cleanEncryptedFields(accountList,null);

        //ASSERT
        System.assert(!accountList[0].EIN_Encrypted__c.contains(' '));
        System.assert(!accountList[0].EIN_Encrypted__c.contains('-'));
        System.assert(!accountList[0].Bank_Account_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[0].Bank_Account_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[0].Bank_Institution_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[0].Bank_Institution_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[0].Bank_Routing_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[0].Bank_Routing_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[1].EIN_Encrypted__c.contains(' '));
        System.assert(!accountList[1].EIN_Encrypted__c.contains('-'));
        System.assert(!accountList[1].Bank_Account_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[1].Bank_Account_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[1].Bank_Institution_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[1].Bank_Institution_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[1].Bank_Routing_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[1].Bank_Routing_Number_Encrypted__c.contains('-'));


    }

    @isTest
    static void testWhenEinEncryptedIsUpdatedThenCleanEncryptedFields() {
        //Arrange
        //Creating In-memory data

        List<Account> accountList = generateAccounts();


        Map<id,Account>oldMap= new Map<id,Account>(
            new Account[]{
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[0].ID)
                    .setField(Account.Bank_Account_Number_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'123-451 ')
                    .toSObject(),
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[1].ID)
                    .setField(Account.Bank_Account_Number_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'567-451 ')
                    .toSObject()
                    }
        );

        //ACT
        CDdAccountHelperMethods.cleanEncryptedFields(accountList,oldMap);

        //ASSERT
        System.assert(!accountList[0].EIN_Encrypted__c.contains(' '));
        System.assert(!accountList[0].EIN_Encrypted__c.contains('-'));
        System.assert(!accountList[1].EIN_Encrypted__c.contains(' '));
        System.assert(!accountList[1].EIN_Encrypted__c.contains('-'));

    }

    @isTest
    static void testWhenBankAccountNumberEncryptedIsUpdatedThenCleanEncryptedFields() {
        //Arrange
        //Creating In-memory data

        List<Account> accountList = generateAccounts();

        Map<id,Account>oldMap= new Map<id,Account>(
            new Account[]{
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[0].ID)
                    .setField(Account.EIN_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'123-451 ')
                    .toSObject(),
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[1].ID)
                    .setField(Account.EIN_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'567-451 ')
                    .toSObject()
                    }
        );

        //ACT
        CDdAccountHelperMethods.cleanEncryptedFields(accountList,oldMap);

        //ASSERT
        System.assert(!accountList[0].Bank_Account_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[0].Bank_Account_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[1].Bank_Account_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[1].Bank_Account_Number_Encrypted__c.contains('-'));
    }

    @isTest
    static void testWhenBankInstitutionNumberEncryptedIsUpdatedThenCleanEncryptedFields() {
        //Arrange
        //Creating In-memory data

        List<Account> accountList = generateAccounts();

        Map<id,Account>oldMap= new Map<id,Account>(
            new Account[]{
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[0].ID)
                    .setField(Account.EIN_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Account_Number_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'123-451 ')
                    .toSObject(),
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[1].ID)
                    .setField(Account.EIN_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Account_Number_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'567-451 ')
                    .toSObject()
                    }
        );

        //ACT
        CDdAccountHelperMethods.cleanEncryptedFields(accountList,oldMap);

        //ASSERT
        System.assert(!accountList[0].Bank_Institution_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[0].Bank_Institution_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[1].Bank_Institution_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[1].Bank_Institution_Number_Encrypted__c.contains('-'));
    }



    @isTest
    static void testWhenBankRoutingNumberEncryptedIsUpdatedThenCleanEncryptedFields() {
        //Arrange
        //Creating In-memory data

        List<Account> accountList = generateAccounts();

        Map<id,Account>oldMap= new Map<id,Account>(
            new Account[]{
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[0].ID)
                    .setField(Account.EIN_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Account_Number_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'123-451 ')
                    .toSObject(),
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[1].ID)
                    .setField(Account.EIN_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Account_Number_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'567-451 ')
                    .toSObject()
                    }
        );

        //ACT
        CDdAccountHelperMethods.cleanEncryptedFields(accountList,oldMap);

        //ASSERT
        System.assert(!accountList[0].Bank_Routing_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[0].Bank_Routing_Number_Encrypted__c.contains('-'));
        System.assert(!accountList[1].Bank_Routing_Number_Encrypted__c.contains(' '));
        System.assert(!accountList[1].Bank_Routing_Number_Encrypted__c.contains('-'));

    }


    @isTest
    static void testWhenNoneOfTheEncryptedFieldsAreChangedOnAccountUpdateThenItShouldNotChangeAnyEncryptedFieldValues() {
        //Arrange
        //Creating In-memory data

        List<Account> accountList = generateAccounts();

        Map<id,Account>oldMap= new Map<id,Account>(
            new Account[]{
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[0].ID)
                    .setField(Account.EIN_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Account_Number_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'123-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'123-451 ')
                    .toSObject(),
                (Account) new Fake( Account.class )
                    .setField(Account.id,accountList[1].ID)
                    .setField(Account.EIN_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Account_Number_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Institution_Number_Encrypted__c,'567-451 ')
                    .setField(Account.Bank_Routing_Number_Encrypted__c,'567-451 ')
                    .toSObject()

                    }
        );

        //ACT
        CDdAccountHelperMethods.cleanEncryptedFields(accountList,oldMap);

        //ASSERT
        System.assert(accountList[0].EIN_Encrypted__c.contains(' '));
        System.assert(accountList[0].EIN_Encrypted__c.contains('-'));
        System.assert(accountList[0].Bank_Account_Number_Encrypted__c.contains(' '));
        System.assert(accountList[0].Bank_Account_Number_Encrypted__c.contains('-'));
        System.assert(accountList[0].Bank_Institution_Number_Encrypted__c.contains(' '));
        System.assert(accountList[0].Bank_Institution_Number_Encrypted__c.contains('-'));
        System.assert(accountList[0].Bank_Routing_Number_Encrypted__c.contains(' '));
        System.assert(accountList[0].Bank_Routing_Number_Encrypted__c.contains('-'));
        System.assert(accountList[1].EIN_Encrypted__c.contains(' '));
        System.assert(accountList[1].EIN_Encrypted__c.contains('-'));
        System.assert(accountList[1].Bank_Account_Number_Encrypted__c.contains(' '));
        System.assert(accountList[1].Bank_Account_Number_Encrypted__c.contains('-'));
        System.assert(accountList[1].Bank_Institution_Number_Encrypted__c.contains(' '));
        System.assert(accountList[1].Bank_Institution_Number_Encrypted__c.contains('-'));
        System.assert(accountList[1].Bank_Routing_Number_Encrypted__c.contains(' '));
        System.assert(accountList[1].Bank_Routing_Number_Encrypted__c.contains('-'));

    }

    // BASD-37666 Start : Unit Test Methods for handlePostSaleAccountOwnershipRejected method
    @isTest
    static void testWhenTheAccountOwnershipRejectedIsTrueAndRequestAccountOwnerIsNotNullThenItShouldSetOwnerIdToRequestAccountOwnerId(){
        //Arrange
        User[] users = generateUsers();
        User user1 = users[0];
        User user2 = users[1];
        User user3 = users[2];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake(Account.class)
                .setFakeId()
                .setField(Account.Requested_Account_Owner__c, user2.Id)
                .setField(Account.Account_Ownership_Rejected__c, true)
                .toSObject(),
                (Account) new Fake(Account.class)
                .setFakeId()
                .setField(Account.Account_Ownership_Rejected__c, true)
                .setField(Account.Requested_Account_Owner__c, user3.Id)
                .toSObject()
                };

        //Act
        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newAccounts, oldAccounts);

        //Assert
        System.assertEquals(newAccounts[0].OwnerId, user2.Id);
        System.assertEquals(newAccounts[1].OwnerId, user3.Id);
    }

    @isTest
    static void testWhenTheAccountOwnershipRejectedIsFalseAndRequestAccountOwnerIsNotNullThenItShouldNotSetOwnerIdToRequestAccountOwnerId(){
        //Arrange
        User[] users = generateUsers();
        User user1 = users[0];
        User user2 = users[1];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake(Account.class)
                .setFakeId()
                .setField(Account.Requested_Account_Owner__c, user2.Id)
                .setField(Account.Account_Ownership_Rejected__c, false)
                .toSObject()
                };

        //Act
        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newAccounts, oldAccounts);

        //Assert
        System.assertEquals(newAccounts[0].OwnerId, null);
    }

    @isTest
    static void testWhenTheAccountOwnershipRejectedIsTrueAndRequestAccountOwnerIsNullThenItShouldNotOverrideOwnerIdToRequestAccountOwnerId(){
        //Arrange
        User[] users = generateUsers();
        User user1 = users[0];
        User user2 = users[1];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake(Account.class)
                .setFakeId()
                .setField(Account.Requested_Account_Owner__c, null)
                .setField(Account.Account_Ownership_Rejected__c, true)
                .toSObject(),
                (Account) new Fake(Account.class)
                .setFakeId()
                .setField(Account.Account_Ownership_Rejected__c, true)
                .setField(Account.Requested_Account_Owner__c, null)
                .setField(Account.OwnerId, user2.Id)
                .toSObject()
                };

        //Act
        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newAccounts, oldAccounts);

        //Assert
        System.assertEquals(newAccounts[0].OwnerId, null);
        System.assertEquals(newAccounts[1].OwnerId, user2.Id);
    }

    @isTest
    static void testWhenTheAccountOwnershipRejectedIsTrueThenItShouldSetWhyShouldAccountOwnershipBeChangedToNull(){
        //Arrange
        User[] users = generateUsers();
        User user1 = users[0];
        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake(Account.class)
                .setFakeId()
                .setField(Account.Account_Ownership_Rejected__c, true)
                .setField(Account.Why_should_account_ownership_be_changed__c, 'Testing')
                .toSObject()
        };
        //Act
        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newAccounts, oldAccounts);

        //Assert
        System.assertEquals(newAccounts[0].Why_should_account_ownership_be_changed__c, null);
    }

    @isTest
    static void testWhenTheAccountOwnershipRejectedIsTrueAndRequestAccountOwnerIsNotNullThenItShouldSetOwnerIdToRequestAccountOwnerIdOnUpdate(){
        //Arrange
        User[] users = generateUsers();
        User user1 = users[0];
        User user2 = users[1];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{};
            for(Id accountId : oldAccounts.keySet()){
                newAccounts.add(
                    (Account) new Fake(Account.class)
                    .setField(Account.Id, accountId)
                    .setField(Account.Account_Ownership_Rejected__c, true)
                    .setField(Account.Requested_Account_Owner__c, user2.Id)
                    .toSObject()
                );
            }

        //Act
        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newAccounts, oldAccounts);

        //Assert
        System.assertEquals(newAccounts[0].OwnerId, user2.Id);
    }

    @isTest
    static void testWhenranPostSaleAccountOwnershipRejectedFlagIsTrueThenMethodShouldNotDoAnyProsessingOnAccountRecord(){
        //Arrange
        User[] users = generateUsers();
        User user1 = users[0];

        Map<Id, Account> oldAccounts = new Map<Id, Account>(generateOldAccounts(user1));

        Account[] newAccounts = new Account[]{
            (Account) new Fake(Account.class)
                .setFakeId()
                .setField(Account.Requested_Account_Owner__c, user1.Id)
                .setField(Account.Account_Ownership_Rejected__c, true)
                .toSObject()
        };
        //Act
        CDdAccountHelperMethods.ranPostSaleAccountOwnershipRejected = True;
        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newAccounts, oldAccounts);

        //Assert
        System.assertEquals(newAccounts[0].OwnerId, null);
    }
    // BASD-37666 End

    @isTest
  static void testWhenIsHierarchyAccountIsCalledWithGrandparentAccountRecordTypeThenReturnTrue(){
    Id recordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_GRANDPARENT_ACCOUNT).getRecordTypeId();

    System.assertEquals(true, CDdAccountHelperMethods.isHierarchyAccount(recordtypeId), 'The GrandParent account recordtype ' + recordtypeId + 'should return true');
  }

  @isTest
  static void testWhenIsHierarchyAccountIsCalledWithParentAccountRecordTypeThenReturnTrue(){
    Id recordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId();

    System.assertEquals(true, CDdAccountHelperMethods.isHierarchyAccount(recordtypeId), 'The Parent account recordtype ' + recordtypeId + 'should return true');
  }

  @isTest
  static void testWhenIsHierarchyAccountIsCalledWithMarketplaceAccountRecordTypeThenReturnTrue(){
    Id recordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_MARKETPLACE).getRecordTypeId();
    System.assertEquals(true, CDdAccountHelperMethods.isHierarchyAccount(recordtypeId), 'The Marketplace account recordtype ' + recordtypeId + 'should return true');
  }

  @isTest
  static void testWhenIsHierarchyAccountIsCalledWithEnterpriseMarketplaceAccountRecordTypeThenReturnTrue(){
    Id recordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_ENTERPRISE_MARKETPLACE).getRecordTypeId();

    System.assertEquals(true, CDdAccountHelperMethods.isHierarchyAccount(recordtypeId), 'The Enterprise Marketplace account recordtype ' + recordtypeId + 'should return true');
  }

  @isTest
  static void testWhenIsHierarchyAccountIsCalledWithNonHierarchyAccountRecordTypeThenReturnFalse(){
    Id recordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_ENTERPRISE_DRIVE).getRecordTypeId();

    System.assertEquals(false, CDdAccountHelperMethods.isHierarchyAccount(recordtypeId), 'The Enterprise Drive account recordtype ' + recordtypeId + 'should return false');
  }

  @isTest
  static void testWhenIsHierarchyAccountIsCalledWithNullRecordTypeThenReturnFalse(){
    Id recordtypeId;

    System.assertEquals(false, CDdAccountHelperMethods.isHierarchyAccount(recordtypeId), 'A null account recordtype should return false');
  }

  @isTest
    static void testWhenAccountsDeckRankIsBlankThenDefaultDeckRankToSameValueAsLaunchDeckRank() {

        //Arrange
        //Creating In-memory data
        List<Account> accountData = generateAccounts();

        //act
        CDdAccountHelperMethods.populateDeckRankIfBlank(accountData);

        //assert
        System.assertEquals(accountData[0].Deck_Rank__c, accountData[0].Launch_Deck_Rank__c);
        System.assertEquals(accountData[1].Deck_Rank__c, accountData[1].Launch_Deck_Rank__c);


    }

    @isTest
    static void testWhenAccountsBillingCountryCodeIsNotNZThenDoNotDefaultDeckRankToSameValueAsLaunchDeckRank() {
        //Arrange
        //Creating In-memory data
        List<Account> accountData = generateAccounts();

        accountData[0].BillingCountry = 'United State';
        accountData[0].BillingCountryCode = 'US';
        accountData[0].Launch_Deck_Rank__c = 'Ace';
        accountData[1].BillingCountry = 'Australia';
        accountData[1].BillingCountryCode = 'AU';
        accountData[1].Launch_Deck_Rank__c = 'King';

        //Act
        CDdAccountHelperMethods.populateDeckRankIfBlank(accountData);

        //Assert
        System.assertNotEquals(accountData[0].Deck_Rank__c, accountData[0].Launch_Deck_Rank__c);
        System.assertNotEquals(accountData[1].Deck_Rank__c, accountData[1].Launch_Deck_Rank__c);

    }

    @isTest
    static void testWhenAccountsRecordTypeIsNotMarketplaceThenDoNotDefaultDeckRankToSameValueAsLaunchDeckRank() {
        //Arrange
        //Creating In-memory data
        Id grandParentRecordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_GRANDPARENT_ACCOUNT).getRecordTypeId();
        Id enterpriseDriveRecordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_ENTERPRISE_DRIVE).getRecordTypeId();

        List<Account> accountData = generateAccounts();
        accountData[0].RecordTypeId = grandParentRecordtypeId;
        accountData[1].RecordTypeId = enterpriseDriveRecordtypeId;

        //Act
        CDdAccountHelperMethods.populateDeckRankIfBlank(accountData);

        //Assert
        System.assertNotEquals(accountData[0].Deck_Rank__c, accountData[0].Launch_Deck_Rank__c);
        System.assertNotEquals(accountData[1].Deck_Rank__c, accountData[1].Launch_Deck_Rank__c);

    }

    @isTest
    static void testWhenLunchDeckRankIsNotValidThenDoNotDefaultDeckRankToSameValueAsLaunchDeckRank() {
        //Arrange
        //Creating In-memory data
        List<Account> accountData = generateAccounts();
        accountData[0].Launch_Deck_Rank__c = 'Ace of Spades';
        accountData[1].Launch_Deck_Rank__c = 'King of Spades';

        //Act
        CDdAccountHelperMethods.populateDeckRankIfBlank(accountData);

        //Assert
        System.assertNotEquals(accountData[0].Deck_Rank__c, accountData[0].Launch_Deck_Rank__c);
        System.assertNotEquals(accountData[1].Deck_Rank__c, accountData[1].Launch_Deck_Rank__c);

    }

    @isTest
    static void testWhenAccountsDeckRankIsNotBlankThenDoNotDefaultDeckRankToSameValueAsLaunchDeckRank() {
        //Arrange
        //Creating In-memory data
        List<Account> accountData = generateAccounts();
        accountData[0].Deck_Rank__c = 'King';
        accountData[1].Deck_Rank__c = 'Ace';

        //Act
        CDdAccountHelperMethods.populateDeckRankIfBlank(accountData);

        //Assert
        System.assertNotEquals(accountData[0].Deck_Rank__c, accountData[0].Launch_Deck_Rank__c);
        System.assertNotEquals(accountData[1].Deck_Rank__c, accountData[1].Launch_Deck_Rank__c);

    }

    private static User[] generateUsersWithAccountDevelopmentReps() {
        return new User[]{
            (User) new Fake( User.class )
                .setFakeId()
                .setField( User.ADR__c, Fake.generateId( User.class ) )
                .toSObject(),
            (User) new Fake( User.class )
                .setFakeId()
                .setField( User.ADR__c, Fake.generateId( User.class ) )
                .toSObject(),
            (User) new Fake( User.class )
                .setFakeId()
                .setField( User.ADR__c, Fake.generateId( User.class ) )
                .toSObject()
        };
    }

    private static Account[] generateOldAccounts(User objUser) {
        return new Account[]{
            (Account) new Fake( Account.class )
                .setFakeId()
                .setField( Account.OwnerId, objUser.Id )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setFakeId()
                .setField( Account.OwnerId, objUser.Id )
                .toSObject(),
            (Account) new Fake( Account.class )
                .setFakeId()
                .toSObject()
        };
    }

    private static List<Account> generateAccounts() {

        Id marketplaceRecordtypeId = CDdAccountHelperMethods.RECORD_TYPE_INFO_BY_DEV_NAME.get(CDdAccountHelperMethods.RECORD_TYPE_DEV_NAME_MARKETPLACE).getRecordTypeId();

        return new List<Account>{
            (Account) new Fake( Account.class )
                .setFakeId()
                .setField(Account.BillingCountry,'New Zealand')
                .setField(Account.BillingCountryCode,'NZ')
                .setField(Account.BillingState,'')
                .setField(Account.Launch_Deck_Rank__c,'Ace')
                .setField(Account.Deck_Rank__c,null)
                .setField(Account.RecordTypeId,marketplaceRecordtypeId)
                .setField(Account.EIN_Encrypted__c,'123-451 ')
                .setField(Account.Bank_Account_Number_Encrypted__c,'123-451 ')
                .setField(Account.Bank_Institution_Number_Encrypted__c,'123-451 ')
                .setField(Account.Bank_Routing_Number_Encrypted__c,'123-451 ')
                .toSObject(),
            (Account) new Fake( Account.class )
                .setFakeId()
                .setField(Account.BillingCountry,'New Zealand')
                .setField(Account.BillingCountryCode,'NZ')
                .setField(Account.BillingState,'')
                .setField(Account.Launch_Deck_Rank__c,'King')
                .setField(Account.Deck_Rank__c,null)
                .setField(Account.RecordTypeId,marketplaceRecordtypeId)
                .setField(Account.Bank_Account_Number_Encrypted__c,'567-451 ')
                .setField(Account.EIN_Encrypted__c,'567-451 ')
                .setField(Account.Bank_Routing_Number_Encrypted__c,'567-451 ')
                .setField(Account.Bank_Institution_Number_Encrypted__c,'567-451 ')
                .toSObject()
        };
    }

    private static User[] generateUsers() {
        return new User[]{
            (User) new Fake( User.class )
                .setFakeId()
                .toSObject(),
            (User) new Fake( User.class )
                .setFakeId()
                .toSObject(),
            (User) new Fake( User.class )
                .setFakeId()
                .toSObject()
        };
    }




}