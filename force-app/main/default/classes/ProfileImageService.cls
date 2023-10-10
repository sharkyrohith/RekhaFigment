/**
 * @author Mahesh Chouhan
 * @Date Nove 2022
 * @description Service class for uploading profile image
 */

public inherited sharing class ProfileImageService {

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
    public static String setProfileImageForUser(String base64Content, String fileName, String userId) {
        return service().setProfileImageForUser(base64Content, fileName, userId);
    }

    private static IProfileImageService service() {
        return (IProfileImageService) Application.Service.newInstance(IProfileImageService.class);
    }
}