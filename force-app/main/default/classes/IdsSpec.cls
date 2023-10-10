/**
 * Created by scott on 9/3/22.
 */

@IsTest(IsParallel=true)
private class IdsSpec {
    @IsTest
    static void testWhenCallingNewInstanceWithListOfIdsThenItShouldReturnsAnIdsCollection() {
        // Arrange
        List<Id> lstIds = new List<Id>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Ids collection = Ids.newInstance( lstIds );
        // Assert
        System.assertEquals( 3, collection.getObjects().size() );
        System.assertEquals( lstIds, (List<Id>) collection.getObjects() );
    }

    @IsTest
    static void testWhenCallingNewInstanceWithSetOfIdsThenItShouldReturnAnIdsCollection() {
        // Arrange
        Set<Id> setIds = new Set<Id>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Ids collection = Ids.newInstance( setIds );
        // Assert
        System.assertEquals( 3, collection.getObjects().size() );
        System.assertEquals( setIds, new Set<Id>( (List<Id>) collection.getObjects() ) );
    }

    @IsTest
    static void testWhenCallingGetIdListThenItShouldReturnListOfIdsInTheCollection() {
        // Arrange
        List<Id> lstIds = new List<Id>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Ids collection = Ids.newInstance( lstIds );
        // Assert
        System.assertEquals( lstIds, collection.getList() );
    }

    @IsTest
    static void testWhenCallingGetIdSetThenItShouldReturnSetOfIdsInTheCollection() {
        // Arrange
        Set<Id> setIds = new Set<Id>{
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class ),
            Fake.generateId( Account.class )
        };
        // Act
        Ids collection = Ids.newInstance( setIds );
        // Assert
        System.assertEquals( setIds, collection.getSet() );
    }
}