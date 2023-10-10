/**
 * @author  Sanidhya Jain L
 * @date    January 2023
 * @description This is the interface class for CloseOpenCasesRequestService.
 */
public interface ICloseOpenCasesRequestService{

    List<String> updateOpenCasestoClose(List<Case> caseList);
    List<String> handleCasesWithInactiveOwner(List<Case> caseList);
}