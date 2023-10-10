/**
 * @description Domain implementation for primitive Id values
 * @author Scott McClung
 * @date 2022/08/31
 */
public virtual inherited sharing class Ids extends Objects {
    /**
     * @description Convenience factory method to resolve an instance of the domain class
     * @param values List of Ids to be injected into the domain class
     * @return An instance of Ids
     */
    public static Ids newInstance( List<Id> values ) {
        return new Ids( values );
    }

    /**
     * @description Convenience factory method to resolve an instance of the domain class
     * @param values Set of Ids to be injected into the domain class
     * @return An instance of Ids
     */
    public static Ids newInstance( Set<Id> values ) {
        return new Ids( values );
    }

    /**
     * @description Class constructor
     * @param values List of Ids
     */
    private Ids( List<Id> values ) {
        super( values );
    }

    /**
     * @description Class constructor
     * @param values Set of Ids
     */
    private Ids( Set<Id> values ) {
        this( new List<Id>( values ) );
    }

    /**
     * @description Convenience method that returns the domain collection as a Set<T>
     * @return Set of Ids
     */
    public Set<Id> getSet() {
        return new Set<Id>( getList() );
    }

    /**
     * @description Convenience method that returns the domain collection as a List<T>
     * @return List of Ids
     */
    public List<Id> getList() {
        return (List<Id>) getObjects();
    }
}