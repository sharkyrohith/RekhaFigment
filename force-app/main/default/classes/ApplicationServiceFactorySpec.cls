/**
 * Created by scott on 9/9/22.
 */

@IsTest( IsParallel=true )
private class ApplicationServiceFactorySpec {

    @IsTest
    private static void testWhenCallingServiceFactoryThenReturnRegisteredImplementationsAndMocks() {
        // Standard behaviour
        System.assert( Service.newInstance( IAccountService.class ) instanceof AccountsServiceImpl, 'Expected a registered implementation of AccountServiceImpl' );

        // Mocking behaviour
        Service.setMock( IAccountService.class, new AccountsServiceMock() );
        System.assert( Service.newInstance( IAccountService.class ) instanceof AccountsServiceMock, 'Expected a registered mock implementation of AccountServiceImpl' );
    }

    // Configure and create the ServiceFactory for this Application
    public static final fflib_Application.ServiceFactory Service =
        new ApplicationServiceFactory(
            new Map<Type, Type>{
                IAccountService.class => AccountsServiceImpl.class
            }
        );

    /**
     * @description Test implementation of service interface for Account
     */
    public interface IAccountService {}

    /**
     * @description Test implementation of service implementation class for Account
     */
    public class AccountsServiceImpl implements IAccountService {}

    /**
     * @description Stubbed service implementation class for Account
     */
    public class AccountsServiceMock implements IAccountService {}
}