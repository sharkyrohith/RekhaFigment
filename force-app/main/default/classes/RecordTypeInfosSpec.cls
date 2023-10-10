/**
 * @description Unit tests for RecordTypeInfos class
 * RecordTypeInfos objects cannot be constructed so creating test records in memory isn't
 * possible.  We're stuck writing a unit test that calls the system for actual record types.
 * This isn't too bad performance wise given that we aren't inserting data that has resulting
 * functionality executing.
 * It is important that the tests pass correctly in ANY environment.  They cannot have knowledge
 * of the actual record types configured in the system.
 */
@IsTest( IsParallel=true )
private class RecordTypeInfosSpec {

    private final static String INVALID_ID_ERROR = 'Getting record types by id requires at least one valid id.  Received null.';
    private final static String INVALID_NAME_ERROR = 'Getting record types by name requires at least one valid name.  Received null.';
    private final static String INVALID_RECORDTYPEINFOS_ERROR = 'RecordTypeInfos requires a valid list of RecordTypeInfo objects.  Received null.';
    private final static String INVALID_SOBJECTTYPES_ERROR = 'RecordTypeInfos requires a valid SObjectType.  Received null.';


    @IsTest
    static void testWhenCallingTheNewInstanceFactoryWithListObjectsThenItShouldReturnObjectEncapsulatingTheData() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        // Act
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Assert
        System.assert( collection.isNotEmpty() );
        System.assertEquals( infos.size(), collection.getAll().size() );
        System.assertEquals( getRecordTypeIds( infos ), getRecordTypeIds( collection ) );
    }

    @IsTest
    static void testWhenCallingTheNewInstanceFactoryWithANullCollectionThenItShouldThrowADeveloperException() {
        // Arrange
        List<RecordTypeInfo> infos;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( infos );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_RECORDTYPEINFOS_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingTheNewInstanceFactoryWithAnSObjectTypeThenItShouldReturnObjectEncapsulatingTheRecordTypeDataForThatSObject() {
        // Arrange
        SObjectType testType = Account.SObjectType;
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        // Act
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( testType );
        // Assert
        System.assert( collection.isNotEmpty() );
        System.assertEquals( infos.size(), collection.getAll().size() );
        System.assertEquals( getRecordTypeIds( infos ), getRecordTypeIds( collection ) );
    }

    @IsTest
    static void testWhenCallingTheNewInstanceFactoryWithANullSObjectTypeThenItShouldThrowADeveloperException() {
        // Arrange
        SObjectType testType;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( testType );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_SOBJECTTYPES_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingGetAllThenItShouldReturnAllRecordTypeObjectEncapsulatedByTheObject() {
        // Arrange
        SObjectType testType = Account.SObjectType;
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( testType );
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        // Act
        List<RecordTypeInfo> testInfos = collection.getAll();
        // Assert
        System.assert( !testInfos.isEmpty() );
        System.assertEquals( infos.size(), testInfos.size() );
        System.assertEquals( getRecordTypeIds( infos ), getRecordTypeIds( testInfos ) );
    }

    @IsTest
    static void testWhenCallingGetIdsThenItShouldReturnTheCollectionOfRecordTypeIds() {
        // Arrange
        Map<Id, RecordTypeInfo> mapRecordTypeInfosById = Account.SObjectType.getDescribe().getRecordTypeInfosById();
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( mapRecordTypeInfosById.values() );
        // Act
        Set<Id> results = collection.getIds();
        // Assert
        System.assertEquals( mapRecordTypeInfosById.keySet().size(), results.size() );
        System.assertEquals( mapRecordTypeInfosById.keySet(), results );
    }

    @IsTest
    static void testWhenCallingGetNamesThenItShouldReturnTheCollectionOfRecordTypeNames() {
        // Arrange
        Map<String, RecordTypeInfo> mapRecordTypeInfosByName = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( mapRecordTypeInfosByName.values() );
        // Act
        Set<String> results = collection.getNames();
        // Assert
        System.assertEquals( mapRecordTypeInfosByName.keySet().size(), results.size() );
        System.assertEquals( mapRecordTypeInfosByName.keySet(), results );
    }

    @IsTest
    static void testWhenCallingGetDeveloperNamesThenItShouldReturnTheCollectionOfRecordTypeDeveloperNames() {
        // Arrange
        Map<String, RecordTypeInfo> mapRecordTypeInfosByDeveloperName = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( mapRecordTypeInfosByDeveloperName.values() );
        // Act
        Set<String> results = collection.getDeveloperNames();
        // Assert
        System.assertEquals( mapRecordTypeInfosByDeveloperName.keySet().size(), results.size() );
        System.assertEquals( mapRecordTypeInfosByDeveloperName.keySet(), results );
    }

    @IsTest
    static void testWhenCallingGetByIdThenItShouldReturnTheRecordtypeInfoMatchingTheGivenId() {
        // Arrange
        Map<String, RecordTypeInfo> mapRecordTypeInfosByDeveloperName = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        Id masterRecordTypeId = mapRecordTypeInfosByDeveloperName.get( 'Master' ).getRecordTypeId();
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( Account.SObjectType );
        // Act
        RecordTypeInfo result = collection.getById( masterRecordTypeId );
        RecordTypeInfo emptyResult = collection.getById( '012000000000001AAA' );
        // Assert
        System.assertEquals( 'Master', result.getName() );
        System.assertEquals( null, emptyResult );
    }

    @IsTest
    static void testWhenCallingGetByNameThenItShouldReturnTheRecordtypeInfoMatchingTheGivenName() {
        // Arrange
        Map<String, RecordTypeInfo> mapRecordTypeInfosByDeveloperName = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        Id masterRecordTypeId = mapRecordTypeInfosByDeveloperName.get( 'Master' ).getRecordTypeId();
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( Account.SObjectType );
        // Act
        RecordTypeInfo result = collection.getByName( 'Master' );
        RecordTypeInfo emptyResult = collection.getByName( 'SomeOtherUnexpectedRecordTypeName1234' );
        // Assert
        System.assertEquals( 'Master', result.getName() );
        System.assertEquals( masterRecordTypeId, result.getRecordTypeId() );
        System.assertEquals( null, emptyResult );
    }

    @IsTest
    static void testWhenCallingGetByDeveloperNameThenItShouldReturnTheRecordtypeInfoMatchingTheGivenDeveloperName() {
        // Arrange
        Map<String, RecordTypeInfo> mapRecordTypeInfosByDeveloperName = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        Id masterRecordTypeId = mapRecordTypeInfosByDeveloperName.get( 'Master' ).getRecordTypeId();
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( Account.SObjectType );
        // Act
        RecordTypeInfo result = collection.getByDeveloperName( 'Master' );
        RecordTypeInfo emptyResult = collection.getByDeveloperName( 'SomeOtherUnexpectedRecordTypeName1234' );
        // Assert
        System.assertEquals( 'Master', result.getDeveloperName() );
        System.assertEquals( masterRecordTypeId, result.getRecordTypeId() );
        System.assertEquals( null, emptyResult );
    }

    @IsTest
    static void testWhenCallingFilterByIdThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenId() {
        // Arrange
        Map<String, RecordTypeInfo> mapRecordTypeInfosByDeveloperName = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        Id masterRecordTypeId = mapRecordTypeInfosByDeveloperName.get( 'Master' ).getRecordTypeId();
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterById( masterRecordTypeId );
        IRecordTypeInfos emptyResults = collection.filterById( '012000000000001AAA' );
        // Assert
        System.assertEquals( 1, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByIdWithNullStringThenItShouldThrowADeveloperException() {
        // Arrange
        Id nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterById( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_ID_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByIdsWithListOfIdsThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenIds() {
        // Arrange
        List<Id> masterIds = new List<Id>();
        masterIds.add( Account.SObjectType.getDescribe().getRecordTypeInfosByName().get( 'Master' ).getRecordTypeId() );
        masterIds.add( Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get( 'Master' ).getRecordTypeId() );

        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterByIds( masterIds );
        IRecordTypeInfos emptyResults = collection.filterByIds( new Set<Id>{ '012000000000001AAA' } );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 'Master', results.getAll()[1].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByIdsWithSetOfIdsThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenIds() {
        // Arrange
        Set<Id> masterIds = new Set<Id>();
        masterIds.add( Account.SObjectType.getDescribe().getRecordTypeInfosByName().get( 'Master' ).getRecordTypeId() );
        masterIds.add( Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get( 'Master' ).getRecordTypeId() );

        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterByIds( masterIds );
        IRecordTypeInfos emptyResults = collection.filterByIds( new Set<Id>{ '012000000000001AAA' } );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 'Master', results.getAll()[1].getName() );
        System.assertEquals( masterIds, results.getIds() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByIdsWithNullListOfValuesThenItShouldThrowADeveloperException() {
        // Arrange
        Id[] nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByIds( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_ID_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByIdsWithNullSetOfValuesThenItShouldThrowADeveloperException() {
        // Arrange
        Set<Id> nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByIds( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_ID_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByNameThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenName() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        // Act
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterByName( 'Master' );
        IRecordTypeInfos emptyResults = collection.filterByName( 'SomeOtherUnexpectedRecordTypeName1234' );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByNameWithNullStringThenItShouldThrowADeveloperException() {
        // Arrange
        String nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByName( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_NAME_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByNamesWithListOfNameThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenNames() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        // In an ideal world we would use more values to evaluate if the filterByNames method
        // worked correctly. Making a trade off here to ensure this test works correctly regardless
        // of how the org is configured. (e.g. empty scratch orgs only contain master record types)
        IRecordTypeInfos results = collection.filterByNames( new String[]{ 'Master' } );
        IRecordTypeInfos emptyResults = collection.filterByNames( new String[]{ 'SomeOtherUnexpectedRecordTypeName1234' } );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByNamesWithSetOfNameThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenNames() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterByNames( new Set<String>{ 'Master' } );
        IRecordTypeInfos emptyResults = collection.filterByNames( new Set<String>{ 'SomeOtherUnexpectedRecordTypeName1234' } );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByNamesWithNullListOfStringsThenItShouldThrowADeveloperException() {
        // Arrange
        String[] nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByNames( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_NAME_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByNamesWithNullSetOfStringsThenItShouldThrowADeveloperException() {
        // Arrange
        Set<String> nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByNames( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_NAME_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByDeveloperNameThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenDeveloperName() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterByDeveloperName( 'Master' );
        IRecordTypeInfos emptyResults = collection.filterByDeveloperName( 'SomeOtherUnexpectedRecordTypeName1234' );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByDeveloperNameWithNullStringThenItShouldThrowADeveloperException() {
        // Arrange
        String nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByDeveloperName( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_NAME_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByDeveloperNamesWithListOfDeveloperNameThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenDeveloperNames() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterByDeveloperNames( new String[]{ 'Master' } );
        IRecordTypeInfos emptyResults = collection.filterByDeveloperNames( new String[]{ 'SomeOtherUnexpectedRecordTypeName1234' } );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByDeveloperNamesWithSetOfDeveloperNameThenItShouldReturnANewObjectWithRecordTypeObjectsMatchingTheGivenDeveloperNames() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.filterByDeveloperNames( new Set<String>{ 'Master' } );
        IRecordTypeInfos emptyResults = collection.filterByDeveloperNames( new Set<String>{ 'SomeOtherUnexpectedRecordTypeName1234' } );
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
        System.assertEquals( 0, emptyResults.getAll().size() );
    }

    @IsTest
    static void testWhenCallingFilterByDeveloperNamesWithNullListOfStringsThenItShouldThrowADeveloperException() {
        // Arrange
        String[] nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByDeveloperNames( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_NAME_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingFilterByDeveloperNamesWithNullSetOfStringsThenItShouldThrowADeveloperException() {
        // Arrange
        Set<String> nullTestValue;
        // Act & Assert
        try {
            RecordTypeInfos.newInstance( Account.SObjectType )
                .filterByDeveloperNames( nullTestValue );
            System.assert( false, 'Expected an exception to be thrown.' );
        } catch( RecordTypeInfos.DeveloperException e ) {
            System.assertEquals( INVALID_NAME_ERROR, e.getMessage() );
        } catch( Exception e ) {
            System.assert( false, 'Unexpected exception caught. Expected an RecordTypeInfos.DeveloperException but received: ' + e.getTypeName() );
        }
    }

    @IsTest
    static void testWhenCallingWhereActiveThenItShouldReturnANewObjectWithRecordTypeObjectsHavingIsActiveEqualToTrue() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.whereActive();
        // Assert
        System.assertEquals( getActiveRecordTypes( infos ).size(), results.getAll().size() );
        System.assertEquals( getRecordTypeIds( getActiveRecordTypes( infos ) ), getRecordTypeIds( results.getAll() ) );
    }

    @IsTest
    static void testWhenCallingWhereNotActiveThenItShouldReturnANewObjectWithRecordTypeObjectsHavingIsActiveEqualToFalse() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.whereNotActive();
        // Assert
        System.assertEquals( getNotActiveRecordTypes( infos ).size(), results.getAll().size() );
        System.assertEquals( getRecordTypeIds( getNotActiveRecordTypes( infos ) ), getRecordTypeIds( results.getAll() ) );
    }

    @IsTest
    static void testWhenCallingWhereAvailableThenItShouldReturnANewObjectWithRecordTypeObjectsHavingIsAvailableEqualToTrue() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.whereAvailable();
        // Assert
        System.assertEquals( getAvailableRecordTypes( infos ).size(), results.getAll().size() );
        System.assertEquals( getRecordTypeIds( getAvailableRecordTypes( infos ) ), getRecordTypeIds( results.getAll() ) );
    }

    @IsTest
    static void testWhenCallingWhereNotAvailableThenItShouldReturnANewObjectWithRecordTypeObjectsHavingIsAvailableEqualToFalse() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.whereNotAvailable();
        // Assert
        System.assertEquals( getNotAvailableRecordTypes( infos ).size(), results.getAll().size() );
        System.assertEquals( getRecordTypeIds( getNotAvailableRecordTypes( infos ) ), getRecordTypeIds( results.getAll() ) );
    }

    @IsTest
    static void testWhenCallingWhereDefaultThenItShouldReturnANewObjectWithRecordTypeObjectsHavingIsDefaultEqualToTrue() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.whereDefault();
        // Assert
        System.assertEquals( getDefaultRecordTypes( infos ).size(), results.getAll().size() );
        System.assertEquals( getRecordTypeIds( getDefaultRecordTypes( infos ) ), getRecordTypeIds( results.getAll() ) );
    }

    @IsTest
    static void testWhenCallingWhereDefaultThenItShouldReturnANewObjectWithRecordTypeObjectsHavingIsMasterEqualToTrue() {
        // Arrange
        List<RecordTypeInfo> infos = Account.SObjectType.getDescribe().getRecordTypeInfos();
        infos.addAll( Contact.SObjectType.getDescribe().getRecordTypeInfos() );
        IRecordTypeInfos collection = RecordTypeInfos.newInstance( infos );
        // Act
        IRecordTypeInfos results = collection.whereMaster();
        // Assert
        System.assertEquals( 2, results.getAll().size() );
        System.assertEquals( 'Master', results.getAll()[0].getName() );
    }

    static Set<Id> getRecordTypeIds( IRecordTypeInfos infos ) {
        return getRecordTypeIds( infos.getAll() );
    }

    static Set<Id> getRecordTypeIds( List<RecordTypeInfo> infos ) {
        Set<Id> results = new Set<Id>();
        for( RecordTypeInfo info : infos ) {
            results.add( info.getRecordTypeId() );
        }
        return results;
    }

    static List<RecordTypeInfo> getActiveRecordTypes( List<RecordTypeInfo> infos ) {
        List<RecordTypeInfo> results = new List<RecordTypeInfo>();
        for( RecordTypeInfo info : infos ) {
            if( info.isActive() ) {
                results.add( info );
            }
        }
        return results;
    }

    static List<RecordTypeInfo> getNotActiveRecordTypes( List<RecordTypeInfo> infos ) {
        List<RecordTypeInfo> results = new List<RecordTypeInfo>();
        for( RecordTypeInfo info : infos ) {
            if( !info.isActive() ) {
                results.add( info );
            }
        }
        return results;
    }

    static List<RecordTypeInfo> getAvailableRecordTypes( List<RecordTypeInfo> infos ) {
        List<RecordTypeInfo> results = new List<RecordTypeInfo>();
        for( RecordTypeInfo info : infos ) {
            if( info.isAvailable() ) {
                results.add( info );
            }
        }
        return results;
    }

    static List<RecordTypeInfo> getNotAvailableRecordTypes( List<RecordTypeInfo> infos ) {
        List<RecordTypeInfo> results = new List<RecordTypeInfo>();
        for( RecordTypeInfo info : infos ) {
            if( !info.isAvailable() ) {
                results.add( info );
            }
        }
        return results;
    }

    static List<RecordTypeInfo> getDefaultRecordTypes( List<RecordTypeInfo> infos ) {
        List<RecordTypeInfo> results = new List<RecordTypeInfo>();
        for( RecordTypeInfo info : infos ) {
            if( info.isDefaultRecordTypeMapping() ) {
                results.add( info );
            }
        }
        return results;
    }
}