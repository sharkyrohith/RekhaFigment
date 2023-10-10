/**
 * @author Mahesh Chouhan
 * @date Nov 2022
 * @description Test class for ProfileImageServiceImpl
 */

@isTest
public class ProfileImageServiceImplTest {

    /**
     * @description Test method for setProfileImageForUser method
     */
    @isTest
    static void testSetProfileImageForUserPositive(){
        Id userId = Fake.generateId(User.SObjectType);
        Id folderId = Fake.generateId(Folder.SObjectType);

        Folder imageFolder = (Folder) new Fake(Folder.class)
            .setField(Folder.Id, folderId)
            .setField(Folder.Name, 'Images')
            .setField(Folder.NamespacePrefix, null)
            .toSObject();
        
        User userRecord = (User) new Fake(User.class)
            .setField(User.Id, userId)
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .toSObject();
        
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IFoldersSelector foldersSelectorMock = (IFoldersSelector) mocks.mock(
            IFoldersSelector.class
        );
        IUsersSelector usersSelectorMock = (IUsersSelector) mocks.mock(
            IUsersSelector.class
        );
        fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(
            fflib_SObjectUnitOfWork.class
        );

        mocks.startStubbing();
        mocks.when(foldersSelectorMock.sObjectType()).thenReturn(Folder.SObjectType);
        mocks.when(foldersSelectorMock.selectImageFolder()).thenReturn(new List<Folder>{imageFolder});
        mocks.when(usersSelectorMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(usersSelectorMock.selectById(new Set<Id>{userId})).thenReturn(new List<User>{userRecord});
        mocks.stopStubbing();

        Application.Selector.setMock(foldersSelectorMock);
        Application.Selector.setMock(usersSelectorMock);
        Application.UnitOfWork.setMock(uowMock);

        ProfileImageService.setProfileImageForUser('Base64String1', 'firstprofilepicture', userId);
        String imageURL = ProfileImageService.setProfileImageForUser('Base64String2', 'secondprofilepicture', userId);

        ((fflib_SObjectUnitOfWork) mocks.verify(uowMock, mocks.times(1)))
            .registerUpsert(
                fflib_Match.sObjectWith(
                    new Map<SObjectField, Object>{
                        Document.Body => EncodingUtil.base64Decode('Base64String1'),
                        Document.Name => 'firstprofilepicture',
                        Document.folderid => folderId,
                        Document.IsPublic => true
                    }
                )
            );
        
        ((fflib_SObjectUnitOfWork) mocks.verify(uowMock, mocks.times(1)))
            .registerUpsert(
                fflib_Match.sObjectWith(
                    new Map<SObjectField, Object>{
                        Document.Body => EncodingUtil.base64Decode('Base64String2'),
                        Document.Name => 'secondprofilepicture',
                        Document.folderid => folderId,
                        Document.IsPublic => true
                    }
                )
            );
        
        ((fflib_SObjectUnitOfWork) mocks.verify(uowMock, mocks.times(2)))
            .registerDirty(
                fflib_Match.sObjectWith(
                    new Map<SObjectField, Object>{
                        User.Id => userId
                        //User.Photo_Document_URL__c => 'firstprofilepicture'
                    }
                )
            );
        
        ((fflib_SObjectUnitOfWork) mocks.verify(uowMock, mocks.times(4))).commitWork();
        //Document Id is null since actual DML is not performed
        String expectedImageURL = URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=null&oid=' + UserInfo.getOrganizationId();
        System.assertEquals(expectedImageURL, imageURL, 'Image URL is not same as expected.');
    }
    
    /**
     * @description Test method for setProfileImageForUser method if Image Folder does not exists
     */
    @isTest
    static void testSetProfileImageForUserNoImageFolderException(){
        Id userId = Fake.generateId(User.SObjectType);
        
        User userRecord = (User) new Fake(User.class)
            .setField(User.Id, userId)
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .toSObject();
        
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IFoldersSelector foldersSelectorMock = (IFoldersSelector) mocks.mock(
            IFoldersSelector.class
        );
        IUsersSelector usersSelectorMock = (IUsersSelector) mocks.mock(
            IUsersSelector.class
        );
        fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(
            fflib_SObjectUnitOfWork.class
        );

        mocks.startStubbing();
        mocks.when(foldersSelectorMock.sObjectType()).thenReturn(Folder.SObjectType);
        mocks.when(foldersSelectorMock.selectImageFolder()).thenReturn(new List<Folder>());
        mocks.when(usersSelectorMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(usersSelectorMock.selectById(new Set<Id>{userId})).thenReturn(new List<User>{userRecord});
        mocks.stopStubbing();

        Application.Selector.setMock(foldersSelectorMock);
        Application.Selector.setMock(usersSelectorMock);
        Application.UnitOfWork.setMock(uowMock);

        Boolean exceptionOccured = false;
        String exceptionMessage;
        try{
            ProfileImageService.setProfileImageForUser('Base64String1', 'firstprofilepicture', userId);   
        }
        catch(Exception ex){
            exceptionOccured = true;
            exceptionMessage = ex.getMessage(); 
        }
        
        System.assert(exceptionOccured, 'Exception must be fired.');
        System.assertEquals('List index out of bounds: 0', exceptionMessage, 'Exception Message is not same as expected.');
    }
    
    /**
     * @description Test method for setProfileImageForUser method if User does not exists
     */
    @isTest
    static void testSetProfileImageForUser(){
        Id userId = Fake.generateId(User.SObjectType);
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector usersSelectorMock = (IUsersSelector) mocks.mock(
            IUsersSelector.class
        );

        mocks.startStubbing();
        mocks.when(usersSelectorMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(usersSelectorMock.selectById(new Set<Id>{userId})).thenReturn(new List<User>());
        mocks.stopStubbing();

        Application.Selector.setMock(usersSelectorMock);

        Boolean exceptionOccured = false;
        String exceptionMessage;
        try{
            ProfileImageService.setProfileImageForUser('Base64String1', 'firstprofilepicture', userId);   
        }
        catch(Exception ex){
            exceptionOccured = true;
            exceptionMessage = ex.getMessage(); 
        }
        
        System.assert(exceptionOccured, 'Exception must be fired.');
        System.assertEquals('List index out of bounds: 0', exceptionMessage, 'Exception Message is not same as expected.');
    }
}