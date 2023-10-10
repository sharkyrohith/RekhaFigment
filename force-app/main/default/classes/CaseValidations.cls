/**
 * @description CaseValidations abstract domain Class for Case SObject.
 * Provides a location for domain validation methods on hero objects that would
 * otherwise end up with a bloated domain class.  Cases domain class inherits
 * behavior from this class.
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class CaseValidations
    extends CaseFilters
    implements ICaseValidations {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public CaseValidations( List<Case> records ) {
        super( records );
    }
}