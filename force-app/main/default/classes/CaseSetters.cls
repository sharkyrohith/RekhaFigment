/**
 * @description CaseSetters abstract domain Class for Case SObject.
 * Provides a location for domain setter methods on hero objects that would
 * otherwise end up with a bloated domain class.  Cases domain class inherits
 * behavior from this class.
 *
 * @author Scott McClung
 * @date 2022/09/03
 */
public abstract inherited sharing class CaseSetters
    extends CaseGetters
    implements ICaseSetters {

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public CaseSetters( List<Case> records ) {
        super( records );
    }
}