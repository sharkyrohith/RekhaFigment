/**
 * Created by scott on 9/3/22.
 */

@IsTest(IsParallel=true)
private class StringsSpec {
    @IsTest
    static void testWhenCallingNewInstanceWithListOfStringsThenItShouldReturnsAnStringsCollection() {
        // Arrange
        List<String> lstStrings = new List<String>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Strings collection = Strings.newInstance( lstStrings );
        // Assert
        System.assertEquals( 3, collection.getObjects().size() );
        System.assertEquals( lstStrings, (List<String>) collection.getObjects() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithSetOfStringsThenItShouldReturnAnStringsCollection() {
        // Arrange
        Set<String> setStrings = new Set<String>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Strings collection = Strings.newInstance( setStrings );
        // Assert
        System.assertEquals( 3, collection.getObjects().size() );
        System.assertEquals( setStrings, new Set<String>( (List<String>) collection.getObjects() ) );
    }

    @IsTest
    static void testWhenCallingGetStringListThenItShouldReturnListOfStringsInTheCollection() {
        // Arrange
        List<String> lstStrings = new List<String>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Strings collection = Strings.newInstance( lstStrings );
        // Assert
        System.assertEquals( lstStrings, collection.getList() );
    }

    @IsTest
    static void testWhenCallingGetSetThenItShouldReturnSetOfStringsInTheCollection() {
        // Arrange
        Set<String> setStrings = new Set<String>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Strings collection = Strings.newInstance( setStrings );
        // Assert
        System.assertEquals( setStrings, collection.getSet() );
    }
}