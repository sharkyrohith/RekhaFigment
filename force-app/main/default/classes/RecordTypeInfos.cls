/**
 * @description Domain Class for RecordTypeInfos Object
 * @author Scott McClung
 * @date 2022/08/17
 */
public virtual inherited sharing class RecordTypeInfos extends fflib_Objects implements IRecordTypeInfos {
    private final static String INVALID_ID_ERROR = 'Getting record types by id requires at least one valid id.  Received null.';
    private final static String INVALID_NAME_ERROR = 'Getting record types by name requires at least one valid name.  Received null.';
    private final static String INVALID_RECORDTYPEINFOS_ERROR = 'RecordTypeInfos requires a valid list of RecordTypeInfo objects.  Received null.';
    private final static String INVALID_SOBJECTTYPES_ERROR = 'RecordTypeInfos requires a valid SObjectType.  Received null.';

    /**
     * @description Cache of RecordTypeInfo objects grouped by SObjectType
     */
    private static Map<SObjectType, List<RecordTypeInfo>> infosBySObjectType = new Map<SObjectType, List<RecordTypeInfo>>();

    /**
     * @description Convenience factory method to resolve an instance of the domain class from the
     * Application factory
     * @param types List of SObjects to be injected into the domain class
     * @return A concrete or mock implementation of IRecordTypeInfos
     */
    public static IRecordTypeInfos newInstance( List<RecordTypeInfo> types ) {
        guard( types, INVALID_RECORDTYPEINFOS_ERROR );
        return (IRecordTypeInfos) Application.Domain.newInstance( types, IRecordTypeInfos.class );
    }

    /**
     * @description Convenience factory method to resolve an instance of the domain class from the
     * Application factory
     * @param sObjectType List of SObjects to be injected into the domain class
     * @return A concrete or mock implementation of IRecordTypeInfos
     */
    public static IRecordTypeInfos newInstance( SObjectType sObjectType ) {
        guard( sObjectType, INVALID_SOBJECTTYPES_ERROR );
        return (IRecordTypeInfos) RecordTypeInfos.newInstance( getInfosBySObjectType( sObjectType ) );
    }

    /**
     * @description Casted collection of the raw RecordTypeInfo objects in the domain class
     */
    protected List<RecordTypeInfo> types {
        get {
            return (List<RecordTypeInfo>) objects;
        }
    }

    /**
     * @description Class constructor
     * @param objects Collection of Objects
     */
    public RecordTypeInfos( List<RecordTypeInfo> objects ) {
        super( objects );
    }

    /**
     * @description Provides access to all of the raw RecordTypeInfo objects
     * encapsulated by the domain class
     * @return Collection of RecordTypeInfo objects
     */
    public List<RecordTypeInfo> getAll() {
        return (List<RecordTypeInfo>) objects;
    }

    /**
     * @description Provides a set of the record type ids encapsulated in the domain object
     * @return Set collection of the id values
     */
    public Set<Id> getIds() {
        Set<Id> results = new Set<Id>();
        for(RecordTypeInfo info : getAll()) {
            results.add(info.getRecordTypeId());
        }
        return results;
    }

    /**
     * @description Provides a set of the record type names encapsulated in the domain object
     * @return Set collection of the name values
     */
    public Set<String> getNames() {
        Set<String> results = new Set<String>();
        for(RecordTypeInfo info : getAll()) {
            results.add(info.getName());
        }
        return results;
    }

    /**
     * @description Provides a set of the record type developer names encapsulated in the domain object
     * @return Set collection of the developer name values
     */
    public Set<String> getDeveloperNames() {
        Set<String> results = new Set<String>();
        for(RecordTypeInfo info : getAll()) {
            results.add(info.getDeveloperName());
        }
        return results;
    }

    /**
     * @description Convenience method to return a single RecordTypeInfo object
     * matching the given id
     * @param id A single id value to filter the RecordTypes by
     * @return The matching RecordTypeInfo object. Returns null if no match is found.
     */
    public RecordTypeInfo getById( Id id ) {
        IRecordTypeInfos infos = filterById( id );
        if( infos.isEmpty() ) return null;
        return infos.getAll()[0];
    }

    /**
     * @description Convenience method to return a single RecordTypeInfo object
     * matching the given name
     * @param name A single name value to filter the RecordTypes by
     * @return The matching RecordTypeInfo object. Returns null if no match is found.
     */
    public RecordTypeInfo getByName( String name ) {
        IRecordTypeInfos infos = filterByName( name );
        if( infos.isEmpty() ) return null;
        return infos.getAll()[0];
    }

    /**
     * @description Convenience method to return a single RecordTypeInfo object
     * matching the given developer name
     * @param name A single name value to filter the RecordTypes by
     * @return The matching RecordTypeInfo object. Returns null if no match is found.
     */
    public RecordTypeInfo getByDeveloperName( String name ) {
        IRecordTypeInfos infos = filterByDeveloperName( name );
        if( infos.isEmpty() ) return null;
        return infos.getAll()[0];
    }

    /**
     * @description Method for filtering the RecordTypes by their id value
     * @param id A single id value to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterById( Id id ) {
        guard( id, INVALID_ID_ERROR );
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new ByIds(), new Id[]{ id } ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their id value
     * @param ids A collection of ids to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByIds( Set<Id> ids ) {
        guard( ids, INVALID_ID_ERROR );
        return filterByIds( new List<Id>( ids ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their id value
     * @param ids A collection of ids to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByIds( List<Id> ids ) {
        guard( ids, INVALID_ID_ERROR );
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new ByIds(), ids ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their Name value
     * @param name A single name value to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByName( String name ) {
        guard( name, INVALID_NAME_ERROR );
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new ByNames(), new String[]{ name } ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their Name value
     * @param names A collection of names to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByNames( Set<String> names ) {
        guard( names, INVALID_NAME_ERROR );
        return filterByNames( new List<String>( names ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their Name value
     * @param names A collection of names to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByNames( List<String> names ) {
        guard( names, INVALID_NAME_ERROR );
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new ByNames(), names ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their DeveloperName value
     * @param name A single name value to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByDeveloperName( String name ) {
        guard( name, INVALID_NAME_ERROR );
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new ByDeveloperNames(), new String[]{ name } ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their DeveloperName value
     * @param names A collection of names to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByDeveloperNames( Set<String> names ) {
        guard( names, INVALID_NAME_ERROR );
        return filterByDeveloperNames( new List<String>( names ) );
    }

    /**
     * @description Method for filtering the RecordTypes by their DeveloperName value
     * @param names A collection of names to filter the RecordTypes by
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos filterByDeveloperNames( List<String> names ) {
        guard( names, INVALID_NAME_ERROR );
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new ByDeveloperNames(), names ) );
    }

    /**
     * @description Method for filtering the RecordTypes to just those that are Active
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos whereActive() {
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new IsActive(), true ) );
    }

    /**
     * @description Method for filtering the RecordTypes to just those that are NOT Active
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos whereNotActive() {
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new IsActive(), false ) );
    }

    /**
     * @description Method for filtering the RecordTypes to just those that are Available
     * to the current user.
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos whereAvailable() {
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new IsAvailable(), true ) );
    }

    /**
     * @description Method for filtering the RecordTypes to just those that are NOT Available
     * to the current user.
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos whereNotAvailable() {
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new IsAvailable(), false ) );
    }

    /**
     * @description Method for filtering the RecordTypes to just the ones defined
     * as the default for the current user.
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos whereDefault() {
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new IsDefault(), true ) );
    }

    /**
     * @description Method for filtering the RecordTypes to just the ones defined
     * as Master.
     * @return A new instance of RecordTypeInfos encapsulating the results of the filter
     */
    public IRecordTypeInfos whereMaster() {
        return (IRecordTypeInfos) new RecordTypeInfos( filterBy( new IsMaster(), true ) );
    }

    /**
     * @description Lazy loaded cache of record type info objects
     * @param sObjectType The SObjectType to return record type information for
     * @return List of RecordTypeInfo objects for the given SObject
     */
    private static List<RecordTypeInfo> getInfosBySObjectType( SObjectType sObjectType ) {
        if( !infosBySObjectType.containsKey( sObjectType ) ) {
            infosBySObjectType.put( sObjectType, sObjectType.getDescribe().getRecordTypeInfos() );
        }
        return infosBySObjectType.get( sObjectType );
    }

    /**
     * @description Provides a null check for method parameters.  Throws a DeveloperException
     * if the parameter is null.
     * @param obj The object to be tested
     * @param errorMessage The error message to include in the thrown exception
     */
    private static void guard( Object obj, String errorMessage ) {
        if( obj == null ) throw new DeveloperException( errorMessage );
    }

    /**
     * @description Method for iterating over the objects contained in the domain class and
     * returning records that match the criteria in the IFilter callback
     * @param filter The filter callback to use when iterating over the records
     * @param value The comparator value
     * @return An instance of the RecordTypeInfos with the resulting dataset
     */
    private RecordTypeInfo[] filterBy( IFilter filter, Object value ) {
        List<RecordTypeInfo> results = new List<RecordTypeInfo>();
        for( Integer i = 0; i < types.size(); i++ ) {
            if( filter.compare( types[i], value ) ) {
                results.add( types[i] );
            }
        }
        return results;
    }

    /**
     * @description Interface for a filter class to be used as a callback
     * when iterating over the records
     */
    private interface IFilter {
        Boolean compare( RecordTypeInfo obj, Object value );
    }

    /**
     * @description Implementation of filter class to return RecordTypes that match the given set of Id values
     */
    private class ByIds implements IFilter {
        public Boolean compare( RecordTypeInfo obj, Object value ) {
            return ( (List<Id>) value ).contains( obj.getRecordTypeId() );
        }
    }

    /**
     * @description Implementation of filter class to return RecordTypes that match the given set of name values
     */
    private class ByNames implements IFilter {
        public Boolean compare( RecordTypeInfo obj, Object value ) {
            return ( (List<String>) value ).contains( obj.getName() );
        }
    }

    /**
     * @description Implementation of filter class to return RecordTypes that match the given set of developer name values
     */
    private class ByDeveloperNames implements IFilter {
        public Boolean compare( RecordTypeInfo obj, Object value ) {
            return ( (List<String>) value ).contains( obj.getDeveloperName() );
        }
    }

    /**
     * @description Implementation of filter class to return RecordTypes that match the given Active state
     */
    private class IsActive implements IFilter {
        public Boolean compare( RecordTypeInfo obj, Object value ) {
            return obj.isActive() == (Boolean) value;
        }
    }

    /**
     * @description Implementation of filter class to return RecordTypes that match the given Available state
     */
    private class IsAvailable implements IFilter {
        public Boolean compare( RecordTypeInfo obj, Object value ) {
            return obj.isAvailable() == (Boolean) value;
        }
    }

    /**
     * @description Implementation of filter class to return RecordTypes that match the given Default state
     */
    private class IsDefault implements IFilter {
        public Boolean compare( RecordTypeInfo obj, Object value ) {
            return obj.isDefaultRecordTypeMapping() == (Boolean) value;
        }
    }

    /**
     * @description Implementation of filter class to return RecordTypes that match the given Master recordtype state
     */
    private class IsMaster implements IFilter {
        public Boolean compare( RecordTypeInfo obj, Object value ) {
            return obj.isMaster() == (Boolean) value;
        }
    }

    /**
     * @description Domain factory class to support dependency injection
     */
    public class Constructor implements fflib_IDomainConstructor {
        /**
         * @description Factory method to provide the Application Factory an api
         * where it can resolve new instances of this domain class and inject the
         * objects.
         * @param objectList List of objects to be injected into the domain class
         * @return Instance of the domain class
         */
        public fflib_Objects construct( List<Object> objectList ) {
            return new RecordTypeInfos( (List<RecordTypeInfo>) objectList );
        }
    }

    public class DeveloperException extends Exception {}
}