/**
 * @description OpportunityGetters abstract domain Class for Opportunity SObject.
 * Provides a location for domain getter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Opportunities domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class OpportunityGetters
    extends SObjects
    implements IOpportunityGetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public OpportunityGetters( List<Opportunity> records ) {
        super( records, Opportunity.SObjectType );
    }

    /**
     * @description Extracts a properly typed list records from the domain collection
     * @return List of all records
     */
    public virtual List<Opportunity> getOpportunities() {
        return (List<Opportunity>) getRecords();
    }
}