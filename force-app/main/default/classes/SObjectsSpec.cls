/**
 * Created by scott on 9/3/22.
 */

@IsTest( IsParallel=true )
private class SObjectsSpec {
    @IsTest
    static void testWhenCallingSizeThenItShouldReturnTheNumberOfRecordsInTheDomainCollection() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        Integer expectedSize = records.getRecords().size();
        Integer actualSize = records.size();
        // Assert
        System.assertEquals( expectedSize, actualSize,
            'Expected ' + expectedSize + ' records.  Received: ' + actualSize + ' Records: ' + records );
    }

    @IsTest
    static void testWhenCallingSizeOnEmptyDomainClassThenItShouldReturnZero() {
        // Arrange
        SuperHeroes records = getEmptySuperHeroesDomain();
        // Act
        Integer actualSize = records.size();
        // Assert
        System.assertEquals( 0, actualSize,
            'Expected 0 records.  Received: ' + actualSize + ' Records: ' + records );
    }

    @IsTest
    static void testWhenCallingGetStringFieldValuesThenItShouldReturnAListOfStringValuesFromTheGivenField() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        String[] expectedAssistants = new String[]{
            'Alexa', 'Google Voice', 'Siri', '  '
        };
        // Act
        String[] actualAssistants = records.getStringField( Contact.AssistantName );
        // Assert
        System.assertEquals( expectedAssistants.size(), actualAssistants.size(),
            'Expected ' + expectedAssistants + ' but received ' + actualAssistants );
        for( String assistant : expectedAssistants ) {
            System.assert( actualAssistants.contains( assistant ),
                'Expected results to include: ' + assistant + '.  Received: ' + actualAssistants );
        }
    }

    @IsTest
    static void testWhenCallingGetIdFieldValuesThenItShouldReturnASetOfIdValuesFromTheGivenIdField() {
        // Arrange
        Id accountId1 = Fake.generateId( Account.class );
        Id accountId2 = Fake.generateId( Account.class );
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AccountId, accountId1 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AccountId, accountId2 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .toSObject()
            }
        );
        // Act
        Set<Id> results = domain.getIdField( Contact.AccountId );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assertEquals( new Set<Id>{ accountId1, accountId2 }, results );
    }

    @IsTest
    static void testWhenCallingGetIdFieldValuesThenItShouldReturnASetOfIdValuesFromTheGivenStringField() {
        // Arrange
        Id accountId1 = Fake.generateId( Account.class );
        Id accountId2 = Fake.generateId( Account.class );
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, accountId1 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, accountId2 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .toSObject()
            }
        );
        // Act
        Set<Id> results = domain.getIdField( Contact.AssistantName );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assertEquals( new Set<Id>{ accountId1, accountId2 }, results );
    }

    @IsTest
    static void testWhenCallingGetIdFieldValuesOnIncompatibleFieldThenItShouldThrowSystemTypeException() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.Birthdate, Date.today() )
                    .toSObject()
            }
        );
        // Act
        try {
            domain.getIdField( Contact.Birthdate );
            System.assert( false, 'Expected a System.TypeException to be thrown but did not catch one.' );
        } catch( System.TypeException e ) {
            System.assert( e.getMessage().containsIgnoreCase( 'invalid id' ),
                'Expected an invalid id error message. Received: ' + e.getMessage() );
        } catch( Exception e ) {
            System.assert( false,
                'Expected a System.TypeException to be thrown but received: ' + e.getTypeName() + '. ErrorMessage: ' + e.getMessage() );
        }
    }

    @IsTest
    static void testWhenCallingGetDateFieldValuesThenItShouldReturnAListOfDateValuesFromTheGivenField() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.Birthdate, Date.today() )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField( Contact.Birthdate, Date.today().addDays( 1 ) )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .toSObject()
            }
        );
        // Act
        List<Date> results = domain.getDateField( Contact.Birthdate );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assert( results.contains( Date.today() ) );
        System.assert( results.contains( Date.today().addDays( 1 ) ) );
    }

    @IsTest
    static void testWhenCallingGetDateFieldValuesOnIncompatibleValueThenItShouldThrowSystemTypeException() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, Fake.generateId( Account.class ) )
                    .toSObject()
            }
        );
        // Act
        try {
            domain.getDateField( Contact.AssistantName );
            System.assert( false, 'Expected a System.TypeException to be thrown but did not catch one.' );
        } catch( System.TypeException e ) {
            System.assert( e.getMessage().containsIgnoreCase( 'invalid date' ),
                'Expected an invalid date error message. Received: ' + e.getMessage() );
        } catch( Exception e ) {
            System.assert( false,
                'Expected a System.TypeException to be thrown but received: ' + e.getTypeName() + '. ErrorMessage: ' + e.getMessage() );
        }
    }

    @IsTest
    static void testWhenCallingGetDatetimeFieldValuesThenItShouldReturnAListOfDatetimeValuesFromTheGivenField() {
        // Arrange
        Datetime today = Datetime.now();
        Datetime yesterday = Datetime.now().addDays( -1 );

        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.LastModifiedDate, today )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField( Contact.LastModifiedDate, yesterday )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .toSObject()
            }
        );
        // Act
        List<Datetime> results = domain.getDatetimeField( Contact.LastModifiedDate );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assert( results.contains( today ) );
        System.assert( results.contains( yesterday ) );
    }

    @IsTest
    static void testWhenCallingGetDatetimeFieldValuesOnIncompatibleValueThenItShouldThrowSystemTypeException() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, Fake.generateId( Account.class ) )
                    .toSObject()
            }
        );
        // Act
        try {
            domain.getDatetimeField( Contact.AssistantName );
            System.assert( false, 'Expected a System.TypeException to be thrown but did not catch one.' );
        } catch( System.TypeException e ) {
            System.assert( e.getMessage().containsIgnoreCase( 'invalid date/time' ),
                'Expected an invalid date/time error message. Received: ' + e.getMessage() );
        } catch( Exception e ) {
            System.assert( false,
                'Expected a System.TypeException to be thrown but received: ' + e.getTypeName() + '. ErrorMessage: ' + e.getMessage() );
        }
    }

    @IsTest
    static void testWhenCallingGetDecimalFieldValuesThenItShouldReturnAListOfDecimalValuesFromTheGivenField() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.MailingLatitude, 1.23 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField( Contact.MailingLatitude, 9.87 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .toSObject()
            }
        );
        // Act
        List<Decimal> results = domain.getDecimalField( Contact.MailingLatitude );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assert( results.contains( (Decimal) 1.23 ) );
        System.assert( results.contains( (Decimal) 9.87 ) );
    }

    @IsTest
    static void testWhenCallingGetDecimalFieldValuesOnIncompatibleValueThenItShouldThrowSystemTypeException() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, Fake.generateId( Account.class ) )
                    .toSObject()
            }
        );
        // Act
        try {
            domain.getDecimalField( Contact.AssistantName );
            System.assert( false, 'Expected a System.TypeException to be thrown but did not catch one.' );
        } catch( System.TypeException e ) {
            System.assert( e.getMessage().containsIgnoreCase( 'invalid conversion' ),
                'Expected an invalid conversion error message. Received: ' + e.getMessage() );
        } catch( Exception e ) {
            System.assert( false,
                'Expected a System.TypeException to be thrown but received: ' + e.getTypeName() + '. ErrorMessage: ' + e.getMessage() );
        }
    }

    @IsTest
    static void testWhenCallingGetDoubleFieldValuesThenItShouldReturnAListOfDoubleValuesFromTheGivenField() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.MailingLatitude, 1.23 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField( Contact.MailingLatitude, 9.87 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .toSObject()
            }
        );
        // Act
        List<Double> results = domain.getDoubleField( Contact.MailingLatitude );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assert( results.contains( (Double) 1.23 ), 'Results do not contain the expected value. Received: ' + results );
        System.assert( results.contains( (Double) 9.87 ), 'Results do not contain the expected value. Received: ' + results );
    }

    @IsTest
    static void testWhenCallingGetDoubleFieldValuesOnIncompatibleValueThenItShouldThrowSystemTypeException() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, Fake.generateId( Account.class ) )
                    .toSObject()
            }
        );
        // Act
        try {
            domain.getDoubleField( Contact.AssistantName );
            System.assert( false, 'Expected a System.TypeException to be thrown but did not catch one.' );
        } catch( System.TypeException e ) {
            System.assert( e.getMessage().containsIgnoreCase( 'invalid conversion' ),
                'Expected an invalid conversion error message. Received: ' + e.getMessage() );
        } catch( Exception e ) {
            System.assert( false,
                'Expected a System.TypeException to be thrown but received: ' + e.getTypeName() + '. ErrorMessage: ' + e.getMessage() );
        }
    }

    @IsTest
    static void testWhenCallingGetIntegerFieldValuesThenItShouldReturnAListOfIntegerValuesFromTheGivenField() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.MailingLatitude, 1.23 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField( Contact.MailingLatitude, 9.87 )
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .toSObject()
            }
        );
        // Act
        List<Integer> results = domain.getIntegerField( Contact.MailingLatitude );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assert( results.contains( (Integer) 1 ), 'Results do not contain the expected value. Received: ' + results );
        System.assert( results.contains( (Integer) 9 ), 'Results do not contain the expected value. Received: ' + results );
    }

    @IsTest
    static void testWhenCallingGetIntegerFieldValuesOnIncompatibleValueThenItShouldThrowSystemTypeException() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, Fake.generateId( Account.class ) )
                    .toSObject()
            }
        );
        // Act
        try {
            domain.getIntegerField( Contact.AssistantName );
            System.assert( false, 'Expected a System.TypeException to be thrown but did not catch one.' );
        } catch( System.TypeException e ) {
            System.assert( e.getMessage().containsIgnoreCase( 'invalid integer' ),
                'Expected an invalid integer error message. Received: ' + e.getMessage() );
        } catch( Exception e ) {
            System.assert( false,
                'Expected a System.TypeException to be thrown but received: ' + e.getTypeName() + '. ErrorMessage: ' + e.getMessage() );
        }
    }


    @IsTest
    static void testWhenCallingGetLongFieldValuesThenItShouldReturnAListOfLongValuesFromTheGivenField() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Account[]{
                (Account) new Fake( Account.class )
                    .setField( Account.NumberOfEmployees, 100 )
                    .toSObject(),
                (Account) new Fake( Account.class )
                    .setField( Account.NumberOfEmployees, 15000 )
                    .toSObject(),
                (Account) new Fake( Account.class )
                    .toSObject()
            }, Account.SObjectType
        );
        // Act
        List<Long> results = domain.getLongField( Account.NumberOfEmployees );
        // Assert
        System.assertEquals( 2, results.size() );
        System.assert( results.contains( (Long) 100 ), 'Results do not contain the expected value. Received: ' + results );
        System.assert( results.contains( (Long) 15000 ), 'Results do not contain the expected value. Received: ' + results );
    }

    @IsTest
    static void testWhenCallingGetLongFieldValuesOnIncompatibleValueThenItShouldThrowSystemTypeException() {
        // Arrange
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField( Contact.AssistantName, Fake.generateId( Account.class ) )
                    .toSObject()
            }
        );
        // Act
        try {
            domain.getLongField( Contact.AssistantName );
            System.assert( false, 'Expected a System.TypeException to be thrown but did not catch one.' );
        } catch( System.TypeException e ) {
            System.assert( e.getMessage().containsIgnoreCase( 'invalid conversion' ),
                'Expected an invalid long error message. Received: ' + e.getMessage() );
        } catch( Exception e ) {
            System.assert( false,
                'Expected a System.TypeException to be thrown but received: ' + e.getTypeName() + '. ErrorMessage: ' + e.getMessage() );
        }
    }


    @IsTest
    static void testWhenCallingGetSObjectsByIdFieldThenItShouldReturnAMapOfRecordsGroupedByTheGivenField() {
        // Arrange
        Id contactId1 = Fake.generateId(Contact.class);
        Id contactId2 = Fake.generateId(Contact.class);
        Id contactId3 = Fake.generateId(Contact.class);
        SuperHeroes domain = new SuperHeroes(
            new Contact[]{
                (Contact) new Fake( Contact.class )
                    .setField(Contact.Id, contactId1)
                    .setField(Contact.LastName, 'Superman')
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField(Contact.Id, contactId2)
                    .setField(Contact.LastName, 'Wonder Woman')
                    .toSObject(),
                (Contact) new Fake( Contact.class )
                    .setField(Contact.Id, contactId3)
                    .setField(Contact.LastName, 'Batman')
                    .toSObject()
            }
        );
        // Act
        Map<Id, SObject> mapRecordsById = domain.getByIdField( Contact.Id );
        // Assert
        System.assertEquals('Superman', mapRecordsById.get(contactId1).get('LastName') );
        System.assertEquals('Wonder Woman', mapRecordsById.get(contactId2).get('LastName') );
        System.assertEquals('Batman', mapRecordsById.get(contactId3).get('LastName') );
    }



    @IsTest
    static void testWhenCallingGetRecordsWithAnyNullFieldValuesWithMultipleFieldsThenItShouldReturnListOfRecordsHavingANullValueInAnyOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAnyNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 3, filteredRecords.getRecords().size(),
            'Expected 3 results. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert(
                record.get( 'LastName' ) == null || record.get( 'FirstName' ) == null,
                'Expected FirstName or LastName to be null.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingGetRecordsWithAnyNullFieldValuesWithASingleFieldThenItShouldReturnListOfRecordsHavingANullValueInAnyOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAnyNull( new Set<SObjectField>{ Contact.FirstName } );
        // Assert
        System.assertEquals( 3, filteredRecords.getRecords().size(),
            'Expected 3 results. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert( record.get( 'FirstName' ) == null,
                'Expected FirstName to be null.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingGetRecordsWithAnyNullFieldValuesOnEmptyDomainThenItShouldReturnAnEmptyDomain() {
        // Arrange
        SuperHeroes records = getEmptySuperHeroesDomain();
        // Act
        SuperHeroes filteredRecords =
            records.whereAnyNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 0, filteredRecords.getRecords().size(),
            'Expected 0 results. Received: ' + filteredRecords.getRecords() );
    }

    @IsTest
    static void testWhenCallingGetRecordsWithAllNullFieldValuesWithMultipleFieldsThenItShouldReturnListOfRecordsHavingANullValueInAllOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAllNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 1, filteredRecords.getRecords().size(),
            'Expected 1 result. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert(
                record.get( 'LastName' ) == null && record.get( 'FirstName' ) == null,
                'Expected FirstName and LastName to be null.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingGetRecordsWithAllNullFieldValuesWithASingleFieldThenItShouldReturnListOfRecordsHavingANullValueInAllOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAllNull( new Set<SObjectField>{ Contact.FirstName } );
        // Assert
        System.assertEquals( 3, filteredRecords.getRecords().size(),
            'Expected 3 results. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert(
                record.get( 'FirstName' ) == null,
                'Expected FirstName to be null.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingGetRecordsWithAllNullFieldValuesOnEmptyDomainThenItShouldReturnAnEmptyDomain() {
        // Arrange
        SuperHeroes records = getEmptySuperHeroesDomain();
        // Act
        SuperHeroes filteredRecords =
            records.whereAllNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 0, filteredRecords.getRecords().size(),
            'Expected 0 results. Received: ' + filteredRecords.getRecords() );
    }

    @IsTest
    static void testWhenCallingRecordsWithAllNotNullFieldValuesWithMultipleFieldsThenItShouldReturnListofRecordsNotHavingANullValueInAllOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAllNotNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 3, filteredRecords.getRecords().size(),
            'Expected 3 results. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert(
                record.get( 'LastName' ) != null && record.get( 'FirstName' ) != null,
                'Expected FirstName and LastName to both have values.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingRecordsWithAllNotNullFieldValuesWithSingleFieldThenItShouldReturnListofRecordsNotHavingANullValueInAllOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAllNotNull( new Set<SObjectField>{ Contact.FirstName } );
        // Assert
        System.assertEquals( 3, filteredRecords.getRecords().size(),
            'Expected 3 results. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert( record.get( 'FirstName' ) != null,
                'Expected FirstName to have values.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingGetRecordsWithAllNotNullFieldValuesOnEmptyDomainThenItShouldReturnAnEmptyDomain() {
        // Arrange
        SuperHeroes records = getEmptySuperHeroesDomain();
        // Act
        SuperHeroes filteredRecords =
            records.whereAllNotNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 0, filteredRecords.getRecords().size(),
            'Expected 0 results. Received: ' + filteredRecords.getRecords() );
    }

    @IsTest
    static void testWhenCallingRecordsWithAnyNotNullFieldValuesWithMultipleFieldsThenItShouldReturnListofRecordsNotHavingANullValueInAnyOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAnyNotNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 5, filteredRecords.getRecords().size(),
            'Expected 5 results. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert(
                record.get( 'LastName' ) != null || record.get( 'FirstName' ) != null,
                'Expected FirstName or LastName to have a value.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingRecordsWithAnyNotNullFieldValuesWithASingleFieldsThenItShouldReturnListofRecordsNotHavingANullValueInAnyOfTheGivenFields() {
        // Arrange
        SuperHeroes records = getSuperHeroes();
        // Act
        SuperHeroes filteredRecords =
            records.whereAnyNotNull( new Set<SObjectField>{ Contact.FirstName } );
        // Assert
        System.assertEquals( 3, filteredRecords.getRecords().size(),
            'Expected 3 results. Received: ' + filteredRecords.getRecords() );
        for( SObject record : filteredRecords.getRecords() ) {
            System.assert( record.get( 'FirstName' ) != null,
                'Expected FirstName to have a value.  Received: ' + record );
        }
    }

    @IsTest
    static void testWhenCallingGetRecordsWithAnyNotNullFieldValuesOnEmptyDomainThenItShouldReturnAnEmptyDomain() {
        // Arrange
        SuperHeroes records = getEmptySuperHeroesDomain();
        // Act
        SuperHeroes filteredRecords =
            records.whereAnyNotNull( new Set<SObjectField>{ Contact.LastName, Contact.FirstName } );
        // Assert
        System.assertEquals( 0, filteredRecords.getRecords().size(),
            'Expected 0 results. Received: ' + filteredRecords.getRecords() );
    }


    private static SuperHeroes getSuperHeroes() {
        Id accountId1 = Fake.generateId( Account.class );
        Id accountId2 = Fake.generateId( Account.class );
        return new SuperHeroes(
            new SObject[]{
                new Fake( Contact.class )
                    .setField( Contact.LastName, 'Smith' )
                    .setField( Contact.FirstName, 'Smith' )
                    .setField( Contact.AssistantName, 'Alexa' )
                    .setField( Contact.Birthdate, Date.today() )
                    .setField( Contact.AccountId, accountId1 )
                    .toSObject(),
                new Fake( Contact.class )
                    .setField( Contact.LastName, 'Smith' )
                    .setField( Contact.AssistantName, 'Google Voice' )
                    .setField( Contact.Birthdate, Date.today() )
                    .setField( Contact.AccountId, accountId2 )
                    .toSObject(),
                new Fake( Contact.class )
                    .setField( Contact.LastName, 'Smith' )
                    .setField( Contact.FirstName, '   ' )
                    .setField( Contact.AssistantName, 'Siri' )
                    .setField( Contact.Birthdate, Date.today() )
                    .setField( Contact.AccountId, accountId1 )
                    .toSObject(),
                new Fake( Contact.class )
                    .setField( Contact.LastName, 'Smith' )
                    .setField( Contact.FirstName, '' )
                    .setField( Contact.AssistantName, '  ' )
                    .setField( Contact.Birthdate, Date.today() )
                    .setField( Contact.AccountId, accountId2 )
                    .toSObject(),
                new Fake( Contact.class )
                    .setField( Contact.LastName, '' )
                    .toSObject(),
                new Fake( Contact.class ).toSObject()
            }
        );
    }

    private static SuperHeroes getEmptySuperHeroesDomain() {
        return new SuperHeroes( new Contact[]{} );
    }


    private class SuperHeroes extends SObjects {
        public SuperHeroes( List<SObject> records ) {
            super( records, Contact.SObjectType );
        }

        public SuperHeroes( List<SObject> records, SObjectType sObjectType) {
            super(records, sObjectType);
        }

        public SuperHeroes whereAnyNull( Set<Schema.SObjectField> fields ) {
            return new SuperHeroes(
                getRecordsWithAnyNullFieldValues( fields )
            );
        }

        public SuperHeroes whereAllNull( Set<Schema.SObjectField> fields ) {
            return new SuperHeroes(
                getRecordsWithAllNullFieldValues( fields )
            );
        }

        public SuperHeroes whereAnyNotNull( Set<Schema.SObjectField> fields ) {
            return new SuperHeroes(
                getRecordsWithAnyNotNullFieldValues( fields )
            );
        }

        public SuperHeroes whereAllNotNull( Set<Schema.SObjectField> fields ) {
            return new SuperHeroes(
                getRecordsWithAllNotNullFieldValues( fields )
            );
        }

        public String[] getStringField( SObjectField field ) {
            return getStringFieldValues( field );
        }

        public Set<Id> getIdField( SObjectField field ) {
            return getIdFieldValues( field );
        }

        public Date[] getDateField( SObjectField field ) {
            return getDateFieldValues( field );
        }

        public Datetime[] getDatetimeField( SObjectField field ) {
            return getDatetimeFieldValues( field );
        }

        public Decimal[] getDecimalField( SObjectField field ) {
            return getDecimalFieldValues( field );
        }

        public Double[] getDoubleField( SObjectField field ) {
            return getDoubleFieldValues( field );
        }

        public Integer[] getIntegerField( SObjectField field ) {
            return getIntegerFieldValues( field );
        }

        public Long[] getLongField( SObjectField field ) {
            return getLongFieldValues( field );
        }

        public Map<Id, SObject> getByIdField( SObjectField field ) {
            return getSObjectsByIdField( field );
        }
    }
}