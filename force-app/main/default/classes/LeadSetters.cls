/**
 * @description LeadSetters abstract domain Class for Lead SObject.
 * Provides a location for domain setter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Leads domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class LeadSetters
    extends LeadGetters
    implements ILeadSetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public LeadSetters( List<Lead> records ) {
        super( records );
    }
}