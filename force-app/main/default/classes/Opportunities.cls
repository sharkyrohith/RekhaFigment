/**
 * @description Domain implementation for Opportunity records
 * @author Scott McClung
 * @date 2022/09/04
 */
public virtual inherited sharing class Opportunities extends OpportunityValidations implements IOpportunities {

    public static IRecordTypeInfos RecordTypes {
        get {
            if(RecordTypes == null) {
                RecordTypes = RecordTypeInfos.newInstance(Opportunity.SObjectType);
            }
            return RecordTypes;
        }
        private set;
    }

    /**
     * @description Convenience factory method to resolve an instance of the domain class from the
     * Application factory
     * @param records List of SObjects to be injected into the domain class
     * @return A concrete or mock implementation of IOpportunities
     */
    public static IOpportunities newInstance( List<Opportunity> records ) {
        return (IOpportunities) Application.Domain.newInstance( records, Opportunity.SObjectType );
    }

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public Opportunities( List<Opportunity> records ) {
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
            return new Opportunities( (List<SObject>) objectList );
        }
    }
}