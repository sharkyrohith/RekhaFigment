/**
 * Created by scott on 9/3/22.
 */

@IsTest( IsParallel=true )
private class ContactGettersSpec {
    @IsTest
    static void testWhenCallingGetContactsThenItShouldReturnAListOfAllContactRecords() {
        // Arrange
        Contact[] testRecords = new Contact[]{
            (Contact) new Fake( Contact.class ).toSObject(),
            (Contact) new Fake( Contact.class ).toSObject(),
            (Contact) new Fake( Contact.class ).toSObject()
        };
        IContacts domain = Contacts.newInstance( testRecords );
        // Act
        Contact[] results = domain.getContacts();
        // Assert
        System.assert( domain.getContacts() instanceof List<Contact> );
        System.assertEquals( testRecords, results );
    }
}