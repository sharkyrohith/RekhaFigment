/**
 * @description CaseGetters abstract domain Class for Case SObject.
 * Provides a location for domain getter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Cases domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class CaseGetters
    extends SObjects
    implements ICaseGetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public CaseGetters( List<Case> records ) {
        super( records, Case.SObjectType );
    }

    /**
     * @description Extracts a properly typed list records from the domain collection
     * @return List of all records
     */
    public virtual List<Case> getCases() {
        return (List<Case>) getRecords();
    }
}