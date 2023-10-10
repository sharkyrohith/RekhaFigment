/**
 * @description Domain implementation for Case records
 * @author Scott McClung
 * @date 2022/09/03
 */
public virtual inherited sharing class Cases
    extends CaseValidations
    implements ICases {

    public static IRecordTypeInfos RecordTypes {
        get {
            if(RecordTypes == null) {
                RecordTypes = RecordTypeInfos.newInstance(Case.SObjectType);
            }
            return RecordTypes;
        }
        private set;
    }

    /**
     * @description Convenience factory method to resolve an instance of the domain class from the
     * Application factory
     * @param records List of SObjects to be injected into the domain class
     * @return A concrete or mock implementation of ICases
     */
    public static ICases newInstance( List<Case> records ) {
        return (ICases) Application.Domain.newInstance( records, Case.SObjectType );
    }

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public Cases( List<Case> records ) {
        super( records );
    }

    /**
     * @description Domain factory class to support dependency injection
     */
    public class Constructor implements fflib_IDomainConstructor {
        /**
         * @description Factory method to provide the Application Factory an api
         * where it can resolve new instances of this domain class and inject the
         * sobject records.
         * @param objectList List of records to be injected into the domain class
         * @return Instance of the domain class
         */
        public SObjects construct( List<Object> objectList ) {
            return new Cases( (List<SObject>) objectList );
        }
    }
}