/**
 * Created by scott on 9/3/22.
 */

@IsTest( IsParallel=true )
private class ObjectsSpec {
    @IsTest
    static void testWhenCallingSizeThenItShouldReturnTheCountOfObjectsInTheCollection() {
        // Arrange
        List<String> values = new List<String>{
            'Value 1',
            'Value 2',
            'Value 3'
        };
        Collection collection = new Collection( values );
        Integer expectedSize = values.size();
        // Act
        Integer actualSize = collection.size();
        // Assert
        System.assertEquals( expectedSize, actualSize );
    }

    @IsTest
    static void testWhenCallingGetObjectSetThenItShouldReturnASetContainingTheObjectsInTheCollection() {
        // Arrange
        Set<Object> values = new Set<Object>{
            'Value 1',
            'Value 2',
            'Value 3'
        };
        Collection collection = new Collection( values );
        Integer expectedSize = values.size();
        // Act
        Integer actualSize = collection.getObjectSet().size();
        // Assert
        System.assertEquals( expectedSize, actualSize );
        System.assertEquals( values, collection.getObjectSet() );
    }


    public class Collection extends Objects {
        public Collection( List<Object> objects ) {
            super( objects );
        }

        public Collection( Set<Object> objects ) {
            this( new List<Object>( objects ) );
        }
    }
}