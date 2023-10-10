/**
 * @description Unit Tests for ContactTriggerHandler
 *
 * @author Ed Kim
 * @date 10/26/2022
 */
@IsTest
public with sharing class ContactTriggerHandlerSpec {
    @IsTest
    static void testWhenCallingUpdateLeadCreatedfromContactAndStateChangesThenItShouldSetTheStateOnTheContactRecord() {
        // Arrange
        User hubspotUser = generateHubspotUser();

        Contact[] oldContacts = generateOldContacts();

        Contact[] newContacts = new Contact[]{
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[0].Id)
                                    .setField(Contact.MailingState, 'CO')
                                    .toSObject(),
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[1].Id)
                                    .setField(Contact.MailingState, 'CO')
                                    .toSObject(),
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[2].Id)
                                    .setField(Contact.MailingState, 'CO')
                                    .toSObject()
                                };

        Lead[] testLeads = new Lead[]{
                            (Lead) new Fake(Lead.class)
                                .setFakeId()
                                .setField(Lead.Created_from_Contact__c, oldContacts[0].Id)
                                .toSObject(),
                            (Lead) new Fake(Lead.class)
                                .setFakeId()
                                .setField(Lead.Created_from_Contact__c, oldContacts[1].Id)
                                .toSObject(),
                            (Lead) new Fake(Lead.class)
                                .setFakeId()
                                .setField(Lead.Created_from_Contact__c, oldContacts[2].Id)
                                .toSObject()
                            };


        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        ILeadsSelector leadsSelector = (ILeadsSelector) mocks.mock(ILeadsSelector.class);

        mocks.startStubbing();
        mocks.when(leadsSelector.sObjectType()).thenReturn(Schema.Lead.SObjectType);
        mocks.when(leadsSelector.selectLeadsByCreatedFromContact(new Set<Id>{ newContacts[0].Id, newContacts[1].Id, newContacts[2].Id }))
             .thenReturn( new List<Lead>{ testLeads[0], testLeads[1] } );
        mocks.stopStubbing();
        Application.UnitofWork.setMock(mockUOW);
        Application.Selector.setMock(leadsSelector);

        // Act
        System.runAs(hubspotUser) {
            CDdContactTriggerHandler.updateLeadCreatedFromContact(new Map<Id,Contact>(newContacts), new Map<Id,Contact>(oldContacts));
        }

        // Assert
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).commitWork();
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 2)).registerDirty(fflib_Match.anySObject());
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Lead.Id => testLeads[0].Id,
            Lead.State => newContacts[0].MailingState
        }));
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Lead.Id => testLeads[1].Id,
            Lead.State => newContacts[1].MailingState
        }));

        System.assertNotEquals(newContacts[2].MailingState, testLeads[2].State);


        }

    @IsTest
    static void testWhenCallingUpdateLeadCreatedfromContactAndPrimaryMerchantCategoryChangesThenItShouldSetThePMCOnTheContactRecord() {
        User hubspotUser = generateHubspotUser();

        Contact[] oldContacts = generateOldContacts();

        Contact[] newContacts = new Contact[]{
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[0].Id)
                                    .setField(Contact.Primary_Merchant_Category__c, 'Grocery')
                                    .toSObject(),
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[1].Id)
                                    .setField(Contact.Primary_Merchant_Category__c, 'Grocery')
                                    .toSObject(),
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[2].Id)
                                    .setField(Contact.Primary_Merchant_Category__c, 'Grocery')
                                    .toSObject()
                                };

        Lead[] testLeads = new Lead[]{
                            (Lead) new Fake(Lead.class)
                                .setFakeId()
                                .setField(Lead.Created_from_Contact__c, oldContacts[0].Id)
                                .toSObject(),
                            (Lead) new Fake(Lead.class)
                                .setFakeId()
                                .setField(Lead.Created_from_Contact__c, oldContacts[1].Id)
                                .toSObject(),
                            (Lead) new Fake(Lead.class)
                                .setFakeId()
                                .setField(Lead.Created_from_Contact__c, oldContacts[2].Id)
                                .toSObject()
                            };


        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        ILeadsSelector leadsSelector = (ILeadsSelector) mocks.mock(ILeadsSelector.class);

        mocks.startStubbing();
        mocks.when(leadsSelector.sObjectType()).thenReturn(Schema.Lead.SObjectType);
        mocks.when(leadsSelector.selectLeadsByCreatedFromContact(new Set<Id>{ newContacts[0].Id, newContacts[1].Id, newContacts[2].Id }))
                .thenReturn( new List<Lead>{ testLeads[0], testLeads[1] } );
        mocks.stopStubbing();
        Application.Unitofwork.setMock(mockUOW);
        Application.Selector.setMock(leadsSelector);

        // Act
        System.runAs (hubspotUser) {
            CDdContactTriggerHandler.updateLeadCreatedFromContact(new Map<Id,Contact>(newContacts), new Map<Id,Contact>(oldContacts));
        }

        // Assert
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).commitWork();
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 2)).registerDirty(fflib_Match.anySObject());
            ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Lead.Id => testLeads[0].Id,
            Lead.Primary_Merchant_Category__c => newContacts[0].Primary_Merchant_Category__c
        }));
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Lead.Id => testLeads[1].Id,
            Lead.Primary_Merchant_Category__c => newContacts[1].Primary_Merchant_Category__c
        }));

        System.assertNotEquals(newContacts[2].Primary_Merchant_Category__c, testLeads[2].Primary_Merchant_Category__c);
    }

    @IsTest
    static void testWhenCallingUpdateContactOwnerfromContactThenItShouldSetTheOwnerOnTheContactRecordToAccountOwner() {
        User[] users = generateUsers();
        Contact[] oldContacts = generateOldContacts();
        Account[] accounts = new Account[] {
                                (Account) new Fake(Account.class)
                                    .setFakeId()
                                    .setField(Account.Name, 'Test Account')
                                    .setField(Account.OwnerId, users[0].Id)
                                    .toSObject()
        };

        Contact[] newContacts = new Contact[]{
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[0].Id)
                                    .setField(Contact.FirstName, 'Contact Owner should change')
                                    .setField(Contact.LastName, 'To Test User 0')
                                    .setField(Contact.OwnerId, users[1].Id)
                                    .setField(Contact.AccountId, accounts[0].Id)
                                    .toSObject()
                                };
        fflib_ApexMocks mocks =  new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAccountsSelector accountsSelector = (IAccountsSelector) mocks.mock(IAccountsSelector.class);

        mocks.startStubbing();
        mocks.when(accountsSelector.sObjectType()).thenReturn(Schema.Account.SObjectType);
        mocks.when(accountsSelector.selectById(new Set<Id>{accounts[0].Id})).thenReturn(new List<Account>{accounts[0]});
        mocks.stopStubbing();

        Application.UnitofWork.setMock(mockUOW);
        Application.Selector.setMock(accountsSelector);

        CDdContactTriggerHandler.updateContactOwner(newContacts, new Map<Id,Contact>(oldContacts));

        System.assertEquals(newContacts[0].OwnerId, users[0].Id);
    }

    @IsTest
    static void testWhenCallingUpdateContactOwnerfromContactThenItShouldSetTheOwnerOnTheContactRecordToAccountADROwner() {
        User[] users = generateUsers();
        Contact[] oldContacts = generateOldContacts();
        Account[] accounts = new Account[] {
                                (Account) new Fake(Account.class)
                                    .setFakeId()
                                    .setField(Account.Name, 'Test Account with ADR_Owner_Actual__c')
                                    .setField(Account.OwnerId, users[1].Id)
                                    .setField(Account.ADR_Owner_Actual__c, users[0].Id)
                                    .toSObject()
        };

        Contact[] newContacts = new Contact[]{
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[1].Id)
                                    .setField(Contact.FirstName, 'Contact Owner should change')
                                    .setField(Contact.LastName, 'To Test User 0')
                                    .setField(Contact.OwnerId, users[1].Id)
                                    .setField(Contact.AccountId, accounts[0].Id)
                                    .toSObject()
        };

        fflib_ApexMocks mocks =  new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAccountsSelector accountsSelector = (IAccountsSelector) mocks.mock(IAccountsSelector.class);

        mocks.startStubbing();
        mocks.when(accountsSelector.sObjectType()).thenReturn(Schema.Account.SObjectType);
        mocks.when(accountsSelector.selectById(new Set<Id>{accounts[0].Id})).thenReturn(new List<Account>{accounts[0]});
        mocks.stopStubbing();

        Application.UnitofWork.setMock(mockUOW);
        Application.Selector.setMock(accountsSelector);

        CDdContactTriggerHandler.updateContactOwner(newContacts, new Map<Id,Contact>(oldContacts));

        System.assertEquals(newContacts[0].OwnerId, users[0].Id);
    }

    @IsTest
    static void testWhenCallingUpdateContactOwnerfromContactThenItShouldKeepTheOwnerOnTheContactRecordAsIs() {
        User[] users = generateUsers();
        Contact[] oldContacts = generateOldContacts();
        Account[] accounts = new Account[] {
                                (Account) new Fake(Account.class)
                                    .setFakeId()
                                    .setField(Account.Name, 'Test Account with ADR_Owner_Actual__c')
                                    .setField(Account.OwnerId, users[0].Id)
                                    .setField(Account.ADR_Owner_Actual__c, users[1].Id)
                                    .toSObject()
        };

        Contact[] newContacts = new Contact[]{
                                (Contact) new Fake(Contact.class)
                                    .setField(Contact.Id, oldContacts[2].Id)
                                    .setField(Contact.FirstName, 'Contact Owner should remain')
                                    .setField(Contact.LastName, 'As Test User 1')
                                    .setField(Contact.OwnerId, users[1].Id)
                                    .setField(Contact.AccountId, accounts[0].Id)
                                    .toSObject()
        };

        fflib_ApexMocks mocks =  new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAccountsSelector accountsSelector = (IAccountsSelector) mocks.mock(IAccountsSelector.class);

        mocks.startStubbing();
        mocks.when(accountsSelector.sObjectType()).thenReturn(Schema.Account.SObjectType);
        mocks.when(accountsSelector.selectById(new Set<Id>{accounts[0].Id})).thenReturn(new List<Account>{accounts[0]});
        mocks.stopStubbing();

        Application.UnitofWork.setMock(mockUOW);
        Application.Selector.setMock(accountsSelector);

        CDdContactTriggerHandler.updateContactOwner(newContacts, new Map<Id,Contact>(oldContacts));

        System.assertEquals(newContacts[0].OwnerId, users[1].Id);
    }

    private static Contact[] generateOldContacts() {
        return new Contact[]{
            (Contact) new Fake(Contact.class)
                .setFakeId()
                .setField(Contact.MailingState, 'CA')
                .toSObject(),
            (Contact) new Fake(Contact.class)
                .setFakeId()
                .setField(Contact.MailingState, 'NY')
                .setField(Contact.Primary_Merchant_Category__c, 'Flowers')
                .toSObject(),
            (Contact) new Fake(Contact.class)
                .setFakeId()
                .setField(Contact.MailingState, 'CO')
                .setField(Contact.Primary_Merchant_Category__c, 'Grocery')
                .toSObject()
        };
    }

    private static User generateHubspotUser() {
        User hubspotUser = TDdAccountFactory.createUsers(1)[0];
        hubspotUser.FirstName = 'Hubspot';
        hubspotUser.LastName = 'Integration User';
        hubspotUser.email = 'hubspot@doordash.com.testemail';
        insert hubspotUser;

        return hubspotUser;
    }

    private static User[] generateUsers() {
        return new User[] {
            (User) new Fake(User.class)
                .setFakeId()
                .setField(User.FirstName, 'Test User 0')
                .setField(User.LastName, 'For Account')
                .toSObject(),
            (User) new Fake(User.class)
                .setFakeId()
                .setField(User.FirstName, 'Test User 1')
                .setField(User.LastName, 'For Account')
                .toSObject()
        };
    }
}