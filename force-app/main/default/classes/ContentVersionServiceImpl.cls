public inherited sharing class ContentVersionServiceImpl implements IContentVersionService{
    public void createCSVContentFileSalesforce(String fileName, String blobVal) {
        try {
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S'; //denotes it resides on Salesforce
            cv.Title = fileName + '.csv'; //title of the file
            cv.PathOnClient = fileName; // full path within Salesforce this can just be the name of file to be in the library
            cv.VersionData = Blob.valueOf(blobVal); //file data
            uow.registerNew(cv);
            uow.commitWork();
        } catch(DMLException ex) {
            throw new DeveloperException(ex.getMessage());
        }
    }

    public class DeveloperException extends Exception {}
}