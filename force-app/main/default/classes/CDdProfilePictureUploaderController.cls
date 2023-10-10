/**
 * CDdProfilePictureUploaderController
 * @ticket https://doordash.atlassian.net/browse/BASD-15507
 * @author Mahesh Chouhan
 * @date  20 Dec 2021
 * @decription Controller for lwcDdProfilePictureUploader lwc component
 */
public without sharing class CDdProfilePictureUploaderController {

  /**
   * @author Mahesh Chouhan
   * @date  20 Dec 2021
   * @decription Creates a document for MXP Profile Picture and update
   *             document URL on MXP User record
   * @params String base64 - Base64 representation of uploaded image
   * @params String filename - Name of uploaded image with extension
   * @params String userId - Id of the user for which picture needs to be updated
   * @return String Profile picture URL
   */
  @AuraEnabled
  public static String uploadProfilePicture(String base64, String filename, String userId){
    return ProfileImageService.setProfileImageForUser(base64, filename, userId);
  }

  /** 
   * @author     Mahesh Chouhan
   * @date  11 may 2022
   * @decription: returns the list of users based on search terms 
   * @param   string of search terms
   * @return  List of users
   */
  @AuraEnabled(cacheable=true)
  public static List<User> getUsers(String nameSerchVal, String emailSearchVal, String profileSearchVal, String roleSeachVal){
    List<User> userListToReturn = new List<User>();

    if(String.isBlank(nameSerchVal) && String.isBlank(emailSearchVal) && String.isBlank(profileSearchVal) && String.isBlank(roleSeachVal)){
      return userListToReturn;
    }

    try{
        userListToReturn = UsersSelector.newInstance().selectByNameEmailProfileRole(nameSerchVal, emailSearchVal, profileSearchVal,
            roleSeachVal, Integer.valueOf(System.Label.User_Nesting_Manual_Limit));
    
      }catch(Exception ex){
        CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, 'CDdProfilePictureUploaderController', 'getUsers', LoggingLevel.ERROR);
        throw new AuraHandledException(ex.getMessage());
      }
    return userListToReturn;
  }

  /**
   * @author Mahesh Chouhan
   * @date  24 May 2022
   * @decription Deletes MXP Email Picture of specified User
   * @params String userId - Id of the user for which picture needs to be deleted
   * @params String documentId - Id of the picture that needs to be deleted
   * @return String specify if operation was successful 
   */
  @AuraEnabled
  public static String deleteProfilePicture(String userId, String documentId){
    String result = 'success';
    try {
      fflib_ISObjectUnitOfWork unitOfWorkInstance = Application.UnitOfWork.newInstance();
      if(String.isNotBlank(documentId)) {
        unitOfWorkInstance.registerDeleted(new Document(Id=documentId));
      }
  
      if(String.isNotBlank(userId)) {
        unitOfWorkInstance.registerDirty(new User(Id=userId, Photo_Document_URL__c = CDdCoreConstants.BLANK_STRING));
      }
      unitOfWorkInstance.commitWork();
    } catch (Exception ex) {
      CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, 'CDdProfilePictureUploaderController', 'deleteProfilePicture', LoggingLevel.ERROR);
      throw new AuraHandledException(ex.getMessage());
    }
    return result;
  }
}