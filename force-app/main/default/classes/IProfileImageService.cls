public interface IProfileImageService {

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
    String setProfileImageForUser(String base64Content, String fileName, String userId);
}