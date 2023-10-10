/**
 * @description Domain implementation for primitive String values
 * @author Scott McClung
 * @date 2022/08/31
 */
public inherited sharing class Strings extends Objects {
    /**
     * @description Convenience factory method to resolve an instance of the domain class
     * @param values List of Strings to be injected into the domain class
     * @return An instance of Strings
     */
    public static Strings newInstance( List<String> values ) {
        return new Strings( values );
    }

    /**
     * @description Convenience factory method to resolve an instance of the domain class
     * @param values Set of Strings to be injected into the domain class
     * @return An instance of Strings
     */
    public static Strings newInstance( Set<String> values ) {
        return new Strings( values );
    }

    /**
     * @description Class constructor
     * @param values List of Strings
     */
    private Strings( List<String> values ) {
        super( values );
    }

    /**
     * @description Class constructor
     * @param values Set of Strings
     */
    private Strings( Set<String> values ) {
        this( new List<String>( values ) );
    }

    /**
     * @description Convenience method that returns the domain collection as a List<T>
     * @return List of Strings
     */
    public List<String> getList() {
        return (List<String>) getObjects();
    }

    /**
     * @description Convenience method that returns the domain collection as a Set<T>
     * @return Set of Strings
     */
    public Set<String> getSet() {
        return new Set<String>( getList() );
    }
}