/**
 * Created by scott on 9/9/22.
 */

@IsTest( IsParallel=true )
private class ApplicationUnitOfWorkFactorySpec {

    @IsTest
    private static void testWhenCallingUnitOfWorkFactoryThenReturnRegisteredImplementationsAndMocks() {
        // Standard behaviour
        System.assert( UnitOfWork.newInstance() instanceof fflib_SObjectUnitOfWork, 'Expected a registered implementation of fflib_SObjectUnitOfWork' );

        // Mocking behaviour
        UnitOfWork.setMock( new fflib_SObjectMocks.SObjectUnitOfWork( new fflib_ApexMocks() ) );
        System.assert( UnitOfWork.newInstance() instanceof fflib_SObjectMocks.SObjectUnitOfWork, 'Expected a registered mock implementation of fflib_SObjectUnitOfWork' );
    }

    // Configure and create the UnitOfWorkFactory for this Application
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
        new ApplicationUnitOfWorkFactory(
            new List<SObjectType>{
                Account.SObjectType
            }
        );
}