/**
 * @description Abstract class to add common object domain functionality without needing to
 * make changes to the fflib packages.  All object domain classes should inherite from
 * Objects rather than fflib_Objects.
 * This base class is inherited by non-sobject domain classes.  It is not inherited by
 * SObjects base class.
 * @author Scott McClung
 * @date 2022/08/31
 */
public abstract inherited sharing class Objects extends fflib_Objects implements IObjects {
    /**
     * @description Class constructor
     * @param objects Collection of objects
     */
    public Objects( List<Object> objects ) {
        super( objects );
    }

    /**
     * @description Class constructor
     * @param objects Collection of objects
     */
    public Objects( Set<Object> objects ) {
        this( new List<Object>( objects ) );
    }

    /**
     * @description Convenience method to return the number of objects in the domain collection
     * @return Count of objects
     */
    public Integer size() {
        return getObjects().size();
    }

    /**
     * @description Provides the domain collection as a set of objects
     * This is useful when needing to pass a collection of high level objects as
     * an argument to a method that accepts a set of generic objects.
     * @return Set of objects
     */
    public Set<Object> getObjectSet() {
        return new Set<Object>( objects );
    }
}