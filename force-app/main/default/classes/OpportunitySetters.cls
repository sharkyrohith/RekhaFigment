/**
 * @description OpportunitySetters abstract domain Class for Opportunity SObject.
 * Provides a location for domain setter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Opportunities domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class OpportunitySetters
    extends OpportunityGetters
    implements IOpportunitySetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public OpportunitySetters( List<Opportunity> records ) {
        super( records );
    }
}