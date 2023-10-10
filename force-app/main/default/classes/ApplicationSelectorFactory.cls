/**
 * @description Custom implementation of the Selector Factory.
 * Override factory methods here for any custom behavior
 */
public inherited sharing class ApplicationSelectorFactory extends fflib_Application.SelectorFactory {

    /**
     * @description Constructs a Selector Factory linking SObjectType's with classes
     * implementing the fflib_ISObjectSelector interface
     * @param selectorTypesBySObjectType - Map of Selector classes by SObjectType
     */
    public ApplicationSelectorFactory( Map<SObjectType, Type> selectorTypesBySObjectType ) {
        super( selectorTypesBySObjectType );
    }
}