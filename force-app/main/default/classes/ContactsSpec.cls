/**
 * Created by scott on 9/3/22.
 */

@IsTest(IsParallel=true)
private class ContactsSpec {
    @IsTest
    static void testWhenCallingRecordTypesThenItShouldReturnAnInstanceOfRecordTypeInfosDomainClass() {
        RecordTypeInfo info = Contacts.RecordTypes.getByName( 'Master' );
        System.assert( info != null );
        System.assertEquals( 'Master', info.getName() );
    }

    @IsTest
    static void testWhenCallingNewInstanceThenItShouldResolveAnInstanceOfIContactsInterfaceFromApplicationFactory() {
        // Arrange
        Contact[] testRecords = new Contact[]{
            (Contact) new Fake( Contact.class ).toSObject(),
            (Contact) new Fake( Contact.class ).toSObject()
        };
        // Act
        Object domain = Contacts.newInstance( testRecords );
        // Assert
        System.assert( domain instanceof IContacts );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfContactRecordsThenItShouldReturnSObjectDomainInstanceWithContactSObjectType() {
        // Arrange
        Contact[] testRecords = new Contact[]{
            (Contact) new Fake( Contact.class ).toSObject(),
            (Contact) new Fake( Contact.class ).toSObject()
        };
        // Act
        IContacts domain = Contacts.newInstance( testRecords );
        // Assert
        System.assertEquals( Contact.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyCollectionOfSObjectRecordsThenItShouldReturnSObjectDomainInstanceWithContactSObjectType() {
        // Arrange
        SObject[] testRecords = new SObject[]{}; // Sometimes the record collection argument received by newInstance() does not have type of List<Contact>
        // Act
        IContacts domain = Contacts.newInstance( testRecords );
        // Assert
        System.assertEquals( Contact.SObjectType, domain.getSObjectType() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithCollectionOfContactRecordsThenItShouldReturnSObjectDomainInstanceWithGivenContacts() {
        // Arrange
        Contact[] testRecords = new Contact[]{
            (Contact) new Fake( Contact.class ).toSObject(),
            (Contact) new Fake( Contact.class ).toSObject()
        };
        // Act
        IContacts domain = Contacts.newInstance( testRecords );
        // Assert
        System.assertEquals( 2, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithEmptyListOfContactsThenItShouldResolveReturnSObjectDomainInstanceWithEmptyCollectionOfContacts() {
        // Arrange
        Contact[] testRecords = new Contact[]{};
        // Act
        IContacts domain = Contacts.newInstance( testRecords );
        // Assert
        System.assertEquals( 0, domain.getRecords().size() );
        System.assertEquals( testRecords, domain.getRecords() );
    }
}