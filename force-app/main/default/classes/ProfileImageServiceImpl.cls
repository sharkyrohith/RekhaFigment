/**
 * @author Mahesh Chouhan
 * @Date Nove 2022
 * @description Service class for uploading profile image
 */

public inherited sharing class ProfileImageServiceImpl implements IProfileImageService {

    /**
     * @author Mahesh Chouhan
     * @date  Nov 2022
     * @decription Creates a document for MXP Profile Picture and update
     *             document URL on MXP User record
     * @params String base64Content - Base64 representation of uploaded image
     * @params String filename - Name of uploaded image with extension
     * @params String userId - Id of the user for which picture needs to be updated
     * @return String Profile picture URL
    */
    public String setProfileImageForUser(String base64Content, String fileName, String userId) {
        User objUser;
        try {
            objUser = UsersSelector.newInstance().selectById(new Set<Id>{userId})[0];
        } catch(Exception ex) {
            throw new DeveloperException(ex.getMessage());
        }
        return setProfileImageForUser(base64Content, fileName, objUser);
    }

    /**
     * @author Mahesh Chouhan
     * @date  Nov 2022
     * @decription Creates a document for MXP Profile Picture and update
     *             document URL on MXP User record
     * @params String base64Content - Base64 representation of uploaded image
     * @params String filename - Name of uploaded image with extension
     * @params User objUser - User for which picture needs to be updated
     * @return String Profile picture URL
    */
    private String setProfileImageForUser(String base64Content, String fileName, User objUser) {
        Document profilePicture = createImageDocument(fileName, base64Content, extractPhotoIdFromUrl(objUser.Photo_Document_URL__c));
        String pictureUrl = generateImageDocumentUrl(profilePicture.Id);
        setUserProfileImageUrl(objUser.Id, pictureURL);
        return pictureUrl;
    }
   
    /**
     * @author Mahesh Chouhan
     * @date  Nov 2022
     * @decription Creates a document for MXP Profile Picture and update
     *             document URL on MXP User record
     * @params String fileName - Name of uploaded image with extension
     * @params String base64Content - Base64 representation of uploaded image
     * @params String currentImageDocumentId - Id of current Image Document
     * @return Document document record with image
    */
    private Document createImageDocument(String fileName, String base64Content, String currentImageDocumentId) {
        try {
            String imageFolderId = getImageFolderId();
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            Document image = new Document(
                Id = currentImageDocumentId,
                Body = EncodingUtil.base64Decode(base64Content),
                Name = fileName,
                FolderId = imageFolderId,
                IsPublic = true
            );
            uow.registerUpsert(image);
            uow.commitWork();
            return image;
        } catch(DMLException ex) {
            throw new DeveloperException(ex.getMessage());
        }
    }

    /**
     * @author Mahesh Chouhan
     * @date  Nov 2022
     * @decription Get Id of Image Folder
     * @return String Id of Image Folder
    */
    private String getImageFolderId() {
        try {
            List<Folder> imageFolder = FoldersSelector.newInstance().selectImageFolder();
            return imageFolder[0].Id;
        } catch(Exception ex) {
            throw new DeveloperException(ex.getMessage());
        }
    }

    /**
     * @author Mahesh Chouhan
     * @date  Nov 2022
     * @decription Update Photo_Document_URL__c with Image Document URL
     * @params String imageDocumentUrl - URL to access Image document
     * @return none
    */
    private void setUserProfileImageUrl(Id userId, String imageDocumentUrl) {
        try {
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            uow.registerDirty(
                new User(
                    Id = userId, 
                    Photo_Document_URL__c = imageDocumentUrl
                    )
                );
            uow.commitWork();
        } catch(DMLException ex) {
            throw new DeveloperException(ex.getMessage());
        }
    }

    /**
     * @author Mahesh Chouhan
     * @date  Nov 2022
     * @decription Generate Image Document URL from document Id
     * @params String documentId - Id of the document record
     * @return String URL to access Image document
    */
    private String generateImageDocumentUrl(String documentId) {
        return URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=' + documentId + '&oid=' + UserInfo.getOrganizationId();
    }

    /**
     * @author Mahesh Chouhan
     * @date  Nov 2022
     * @decription Extract Document Id from Image URL
     * @params String url - URL to access Image document
     * @return String Id of the Image Document record
    */
    private String extractPhotoIdFromUrl(String url) {
        if(String.isBlank(url)) {
            return null;
        }
        return url.substring(url.indexOf('?id=') + 4, url.indexOf('&oid'));
    }

    public class DeveloperException extends Exception {}
}