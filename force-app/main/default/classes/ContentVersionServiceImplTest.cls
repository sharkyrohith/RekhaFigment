/**
 * @author Nayana Kapse
 * @date Dec 2022
 * @description Test class for ContentVersionServiceImpl
 */
@isTest
public class ContentVersionServiceImplTest {
    @isTest
    static void testCreateCSVContentFileSalesforce(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(
            fflib_SObjectUnitOfWork.class
        );
        String csvBackup = 'Id,MacroId,Target,Value'+'\n';
        String fileName = 'Test file';
        IContentVersionService serviceMock = (IContentVersionService) mocks.mock(IContentVersionService.class);
        Application.UNITOFWORK.setMock(uowMock);
        Application.SERVICE.setMock(IContentVersionService.class, serviceMock);
        try{
            ContentVersionService.createCSVContentFileSalesforce(fileName,csvBackup);
        }catch(Exception e){
            System.assert(false, 'it should not come here');
        }
    }
}