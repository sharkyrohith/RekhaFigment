/**
 * @description Custom implementation of the Service Factory.
 * Override factory methods here for any custom behavior
 */
public inherited sharing class ApplicationServiceFactory extends fflib_Application.ServiceFactory {
    /**
     * @description Constructs a simple Service Factory using a map of interfaces
     * to classes implementing the interface
     * @param serviceImplTypesByServiceInterfaceType - Map of service classes by the interface they implement
     */
    public ApplicationServiceFactory( Map<Type, Type> serviceImplTypesByServiceInterfaceType ) {
        super( serviceImplTypesByServiceInterfaceType );
    }
}