/**
 * @description LeadGetters abstract domain Class for Lead SObject.
 * Provides a location for domain getter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Leads domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class LeadGetters
    extends SObjects
    implements ILeadGetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public LeadGetters( List<Lead> records ) {
        super( records, Lead.SObjectType );
    }

    /**
     * @description Extracts a properly typed list records from the domain collection
     * @return List of all records
     */
    public virtual List<Lead> getLeads() {
        return (List<Lead>) getRecords();
    }
}