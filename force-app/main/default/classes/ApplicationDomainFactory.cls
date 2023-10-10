/**
 * @description Custom implementation of the Domain Factory.
 * Override factory methods here for any custom behavior
 */
public inherited sharing class ApplicationDomainFactory extends fflib_Application.DomainFactory {
    /**
     * @description Constructs a Domain factory, using an instance of the Selector Factory
     *   and a map of objects by object type
     * @param selectorFactory - e.g. Application.Selector
     * @param constructorTypeByObject - Map of Domain classes by Object type
     */
    public ApplicationDomainFactory( fflib_Application.SelectorFactory selectorFactory,
        Map<Object, Type> constructorTypeByObject ) {
        super( selectorFactory, constructorTypeByObject );
    }

    /**
     * @description Constructs a Domain factory, using an instance of the Selector Factory
     *   and a map of classes implementing fflib_ISObjectDomain by SObjectType
     * @param selectorFactory - e.g. Application.Selector
     * @param sObjectByDomainConstructorType - Map of Domain classes by SObjectType
     */
    public ApplicationDomainFactory( fflib_Application.SelectorFactory selectorFactory,
        Map<SObjectType, Type> sObjectByDomainConstructorType ) {
        super( selectorFactory, sObjectByDomainConstructorType );
    }
}