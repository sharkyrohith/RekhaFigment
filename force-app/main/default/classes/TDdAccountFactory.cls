/**
 * @author: AAmrute
 * @date: 11-29-2018
 * @description This Class contains Account related data factory methods
 */
@isTest
public class TDdAccountFactory {
  /**
   * @description create an Account record for test purposes, defaulting the record type to 'Marketplace'.
   *
   * @return (Account)
   */
  public static Account createAccount() {
    return createAccount('Marketplace');
  }

  /**
   * @description create an Account record for test purposes.
   *
   * @param recordTypeName (String)
   * @return (Account)
   */
  public static Account createAccount(String recordTypeName) {
    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get(recordTypeName)
      .getRecordTypeId();
    return createAccount(recordTypeId);
  }

  /**
   * @description create an Account record for test purposes.
   *
   * @param recordTypeId (Id)
   * @return (Account)
   */
  public static Account createAccount(Id recordTypeId) {
    Account account = new Account(
      BillingStreet = getRandom() + ' Mulberry Ln',
      BillingCity = 'South San Francisco',
      BillingState = 'CA',
      BillingCountryCode = 'US',
      BillingCountry = 'United States',
      Phone = getRandom(),
      BillingPostalCode = '95689',
      Bank_Account_Number_Encrypted__c = '123456789',
      Bank_Routing_Number_Encrypted__c = '123456789',
      EIN_Encrypted__c = '123456789',
      Legal_Business_Name__c = 'TestAccount',
      RecordTypeId = recordTypeId
    );

    if (CDdSchemaUtils.ACCOUNT_RT.personAccountId().equals(recordTypeId)) {
      account.LastName = 'Test Account';
    } else {
      account.Name = 'Test Account';
    }

    return account;
  }

  public static List<Account> createAccounts(
    String testAccountName,
    Integer numberOfAccounts
  ) {
    return createAccounts(testAccountName, numberOfAccounts, 'Marketplace');
  }

  public static List<Account> createAccountsWithJapanAddress(
    String testAccountName,
    Integer numberOfAccounts
  ) {
    return createAccounts(testAccountName, numberOfAccounts, 'Marketplace');
  }
  /**
   * @description Function to create multiple Accounts as per requirement for a particular record type
   */
  public static List<Account> createAccounts(
    String testAccountName,
    Integer numberOfAccounts,
    String recordType
  ) {
    List<Account> accountsToBeCreated = new List<Account>();
    Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get(recordType)
      .getRecordTypeId();

    for (Integer i = 0; i < numberOfAccounts; i++) {
      Account acct = new Account(
        BillingStreet = i + ' Mulberry Ln',
        BillingCity = 'South San Francisco',
        BillingState = 'CA',
        BillingCountryCode = 'US',
        BillingCountry = 'United States',
        Phone = getRandom(),
        BillingPostalCode = '95689',
        Bank_Account_Number_Encrypted__c = '123456789',
        Bank_Routing_Number_Encrypted__c = '123456789',
        EIN_Encrypted__c = '123456789',
        Legal_Business_Name__c = 'TestAccount',
        RecordTypeId = accRecordTypeId
      );
      if (recordType.equals('Consumer or Dasher')) {
        acct.LastName = testAccountName + ' ' + i;
      } else {
        acct.Name = testAccountName + ' ' + i;
      }
      accountsToBeCreated.add(acct);
    }
    return accountsToBeCreated;
  }

  /*
* @author Mani.
@description Function to create multiple Accounts with Japan Addresses as per requirement for a particular record type
* */

  public static List<Account> createAccountsWithJapanAddress(
    String testAccountName,
    Integer numberOfAccounts,
    String recordType
  ) {
    List<Account> accountsToBeCreated = new List<Account>();
    Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get(recordType)
      .getRecordTypeId();

    for (Integer i = 0; i < numberOfAccounts; i++) {
      Account acct = new Account(
        BillingStreet = '1225' + i + 'Hirai Honode-Machi',
        BillingCity = 'Nishitama-gun',
        BillingState = 'Tokyo',
        BillingCountryCode = 'JP',
        BillingCountry = 'Japan',
        // Phone = getRandom(),
        phone = '+81 9-9999-9999',
        BillingPostalCode = '190-018',
        Bank_Account_Number_Encrypted__c = '123456789',
        Bank_Routing_Number_Encrypted__c = '123456789',
        EIN_Encrypted__c = '123456789',
        Legal_Business_Name__c = 'TestAccount',
        RecordTypeId = accRecordTypeId
      );
      if (recordType.equals('Consumer or Dasher')) {
        acct.LastName = testAccountName + ' ' + i;
      } else {
        acct.Name = testAccountName + ' ' + i;
      }
      accountsToBeCreated.add(acct);
    }
    return accountsToBeCreated;
  }

  /*
* @author ATG:Saketha
@description Function to create multiple Accounts with different Addresses for user group
* */

  public static List<Account> createAccountsWithDynamicAddress(
    String testAccountName,
    Integer numberOfAccounts,
    String recordType,
    String billingCountry,
    String billingCountryCode,
    String state,
    String phone,
    String billingPostalCode
  ) {
    List<Account> accountsToBeCreated = new List<Account>();
    Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get(recordType)
      .getRecordTypeId();

    for (Integer i = 0; i < numberOfAccounts; i++) {
      Account acct = new Account(
        BillingStreet = i + ' Mulberry Ln',
        BillingCity = 'South San Francisco',
        BillingState = state,
        BillingCountryCode = billingCountryCode,
        BillingCountry = billingCountry,
        Phone = phone,
        BillingPostalCode = billingPostalCode,
        Bank_Account_Number_Encrypted__c = '123456789',
        Bank_Routing_Number_Encrypted__c = '123456789',
        EIN_Encrypted__c = '123456789',
        Legal_Business_Name__c = 'TestAccount',
        RecordTypeId = accRecordTypeId
      );
      if (recordType.equals('Consumer or Dasher')) {
        acct.LastName = testAccountName + ' ' + i;
      } else {
        acct.Name = testAccountName + ' ' + i;
      }
      accountsToBeCreated.add(acct);
    }
    return accountsToBeCreated;
  }

  /**
   * @description Function to create multiple Contacts as per requirement for a particular Account
   */
  public static List<Contact> createContacts(
    Integer numberOfContacts,
    Id accountId
  ) {
    CDdContactTriggerHelper.insertCampaign();
    List<Contact> contactsToBeCreated = new List<Contact>();

    for (integer i = 0; i < numberOfContacts; i++) {
      Contact ct = new Contact(
        firstName = 'TestFn' + i,
        LastName = 'TestLn' + i,
        AccountId = accountId,
        Email = 'testfnln' + i + '@test.com',
        Birthdate = Date.newInstance(1991, 9, 29)
      );
      contactsToBeCreated.add(ct);
    }
    return contactsToBeCreated;
  }

  /**
   * @description Function to create multiple Opportunities as per requirement for a particular Account
   */
  public static List<Opportunity> createOpportunities(
    Integer numberOfOpportunities,
    Id accountId
  ) {
    List<Opportunity> opportunitiesToBeCreated = new List<Opportunity>();

    for (integer i = 0; i < numberOfOpportunities; i++) {
      Opportunity opp = new Opportunity(
        Name = 'TestOpportunity' + i,
        AccountId = accountId
      );
      opportunitiesToBeCreated.add(opp);
    }

    return opportunitiesToBeCreated;
  }

  /**
   * @description Function to create multiple Users as per requirement
   */
  public static List<User> createUsers(Integer numberOfUsers) {
    List<User> usersToBeCreated = createUsers(numberOfUsers, null, null);
    return usersToBeCreated;
  }

  /*
    * @description Function to create multiple users with a given profile ID and a role Id
    If the userProfileId is null, it will use Sys Admin profile.
    If the RoleId is Null, it will create a test role.
    */
  public static List<User> createUsers(
    Integer numberOfUsers,
    Id userProfileId,
    Id roleId
  ) {
    return TDdUserFactory.createUsers(
      numberOfUsers,
      userProfileId,
      roleId,
      false
    );
  }

  // create users without a role to avoid mixed DML issues in tests
  public static List<User> createUsersWithOutRole(Integer numberOfUsers) {
    List<User> usersToBeCreated = createUsersWithOutRole(numberOfUsers, null);
    return usersToBeCreated;
  }

  public static List<User> createUsersWithOutRole(
    Integer numberOfUsers,
    Id userProfileId
  ) {
    return TDdUserFactory.createUsersWithoutRole(
      numberOfUsers,
      userProfileId,
      false
    );
  }

  /**
   * @description Function to generate a random 10 digit number
   */
  public static String getRandom() {
    Integer len = 10;
    final String chars = '0123456789';
    String randStr = '';

    while (randStr.length() < len) {
      Integer idx = Math.mod(
        Math.abs(Crypto.getRandomInteger()),
        chars.length()
      );
      randStr += chars.substring(idx, idx + 1);
    }
    return randStr;
  }

  /**
   * @description Setup Submarket, realzip,
   */
  public static Id setupRealZIPData() {
    Submarket__c submarket = new Submarket__c();
    submarket.Name = 'NY - Rochester';
    submarket.Region__c = 'NEW YORK';
    submarket.Photoshoot_Vendor__c = 'OCUS';
    insert submarket;

    RealZip__RealZips__c realZip = new RealZip__RealZips__c();
    realzip.Submarket_lookup__c = submarket.id;
    insert realzip;
    return realzip.id;
  }
  /**
   * @description BZAP-11406 - setUp Business Verticals
   */
  public static List<Business_Vertical__c> setUpBusinessVerticals() {
    Id categoryRecordTypeId = Schema.SObjectType.Vertical_Category__c.getRecordTypeInfosByDeveloperName()
      .get('Category')
      .getRecordTypeId();
    Id subCategoryRecordTypeId = Schema.SObjectType.Vertical_Category__c.getRecordTypeInfosByDeveloperName()
      .get('Sub_Category')
      .getRecordTypeId();
    List<Vertical_Category__c> parentCategoryList = new List<Vertical_Category__c>();
    //insert parent categories
    Vertical_Category__c parentCategory1 = new Vertical_Category__c(
      Name = 'Alcohol',
      RecordTypeId = categoryRecordTypeId
    );
    Vertical_Category__c parentCategory2 = new Vertical_Category__c(
      Name = 'Grocery',
      RecordTypeId = categoryRecordTypeId
    );
    parentCategoryList.add(parentCategory1);
    parentCategoryList.add(parentCategory2);
    insert parentCategoryList;
    //insert sub categories
    List<Vertical_Category__c> subCategoryList = new List<Vertical_Category__c>();
    Vertical_Category__c subCategory1 = new Vertical_Category__c(
      Name = 'Alcohol-Lite',
      Parent_Category__c = parentCategory1.Id,
      RecordTypeId = subCategoryRecordTypeId
    );
    subCategoryList.add(subCategory1);
    insert subCategoryList;
    // insert vertical categories
    List<Business_Vertical__c> bvList = new List<Business_Vertical__c>();
    Business_Vertical__c businessVericalRetail = new Business_Vertical__c(
      Name = 'Test Retail',
      Menu_UI_Type__c = 'Retail',
      Primary_Category__c = 'Grocery',
      Business_Vertical_Id__c = 1
    );
    Business_Vertical__c businessVericalRestaurant = new Business_Vertical__c(
      Name = 'Test Restaurant',
      Menu_UI_Type__c = 'Restaurant',
      Primary_Category__c = 'Alcohol',
      Business_Vertical_Id__c = 2
    );
    bvList.add(businessVericalRetail);
    bvList.add(businessVericalRestaurant);
    insert bvList;
    return bvList;
  }
}