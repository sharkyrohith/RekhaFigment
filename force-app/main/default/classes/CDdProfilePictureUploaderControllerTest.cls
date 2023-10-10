/**
 * @author Mahesh Chouhan
 * @date Jan 2022
 * @description Test class for controller of lwcDdProfilePictureUploader LWC Component
 */

@isTest
private class CDdProfilePictureUploaderControllerTest {
    private static final String MOCK_EXCEPTION_MESSAGE = 'Exception occurred while performing DML operation';
    private static final String MOCK_EXCEPTION_MESSAGE_2 = 'Records not found';

    /**
     * @description Test method for uploadProfilePicture method
     */
    @isTest
    static void testUploadProfilePicture(){
        Id userId = Fake.generateId(User.SObjectType);

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IProfileImageService profileImageService = (IProfileImageService) mocks.mock(
            IProfileImageService.class
        );

        String expectedImageURL = 'https://www.testimageurl.com';
        mocks.startStubbing();
        mocks.when(profileImageService.setProfileImageForUser('Base64String1', 'firstprofilepicture', userId)).thenReturn(expectedImageURL);
        mocks.stopStubbing();

        Application.Service.setMock(IProfileImageService.class, profileImageService);

        String actaulImageURL = CDdProfilePictureUploaderController.uploadProfilePicture('Base64String1', 'firstprofilepicture', userId);
        System.assertEquals(expectedImageURL, actaulImageURL, 'Photo Image URL is not same as expected.');
    }

    /**
     * @description Test method for getUsers method
     */
    @isTest
    public static void testGetUsers(){
        Id user1Id = Fake.generateId(User.SObjectType);
        Id user2Id = Fake.generateId(User.SObjectType);

        User user1 = (User) new Fake(User.class)
            .setField(User.Id, user1Id)
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .toSObject();
        User user2 = (User) new Fake(User.class)
            .setField(User.Id, user1Id)
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .toSObject();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector userSelectorMock = (IUsersSelector) mocks.mock(
            IUsersSelector.class
        );

        mocks.startStubbing();
        mocks.when(userSelectorMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(userSelectorMock.selectByNameEmailProfileRole('TestUser', '', 'HQ', 'COO', Integer.valueOf(System.Label.User_Nesting_Manual_Limit)))
            .thenReturn(new List<User>{user1});
        mocks.stopStubbing();

        Application.Selector.setMock(userSelectorMock);

        List<User> hQUsers = CDdProfilePictureUploaderController.getUsers('TestUser', '', 'HQ', 'COO');

        ((IUsersSelector) mocks.verify(userSelectorMock, 1))
            .selectByNameEmailProfileRole('TestUser', '', 'HQ', 'COO', Integer.valueOf(System.Label.User_Nesting_Manual_Limit));
        
        System.assertEquals(1, hQUsers.size(),'Only One user has the HQ Team profile, then return list count is one.');
    }

    /**
     * @description Test method for getUsers method with Exception
     */
    @isTest
    public static void testGetUsersWithException(){
        Id user1Id = Fake.generateId(User.SObjectType);
        Id user2Id = Fake.generateId(User.SObjectType);

        User user1 = (User) new Fake(User.class)
            .setField(User.Id, user1Id)
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .toSObject();
        User user2 = (User) new Fake(User.class)
            .setField(User.Id, user1Id)
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .toSObject();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector userSelectorMock = (IUsersSelector) mocks.mock(
            IUsersSelector.class
        );

        mocks.startStubbing();
        mocks.when(userSelectorMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(userSelectorMock.selectByNameEmailProfileRole('TestUser', '', 'HQ', 'COO', Integer.valueOf(System.Label.User_Nesting_Manual_Limit)))
            .thenThrow(new TestException(MOCK_EXCEPTION_MESSAGE_2));
        mocks.stopStubbing();

        Application.Selector.setMock(userSelectorMock);

        Boolean exceptionOccured = false;
        String exceptionMessage;
        try{
            CDdProfilePictureUploaderController.getUsers('TestUser', '', 'HQ', 'COO'); 
        }
        catch(AuraHandledException ex){
            exceptionOccured = true;
        }
        
        System.assert(exceptionOccured, 'Exception must be fired.');
    }
    
    /**
     * @description Test method for deleteProfilePicture method
     */
    @isTest
    public static void testDeleteProfilePicture(){
        Id documentId = Fake.generateId(Document.SObjectType);
        Id userId = Fake.generateId(User.SObjectType);
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(
            fflib_SObjectUnitOfWork.class
        );

        Application.UnitOfWork.setMock(uowMock);

        String result = CDdProfilePictureUploaderController.deleteProfilePicture(userId, documentId);

        ((fflib_SObjectUnitOfWork) mocks.verify(uowMock, mocks.times(1)))
            .registerDeleted(
                fflib_Match.sObjectWith(
                    new Map<SObjectField, Object>{
                        Document.Id => documentId
                    }
                )
            );
        
        ((fflib_SObjectUnitOfWork) mocks.verify(uowMock, mocks.times(1)))
            .registerDirty(
                fflib_Match.sObjectWith(
                    new Map<SObjectField, Object>{
                        User.Id => userId,
                        User.Photo_Document_URL__c => CDdCoreConstants.BLANK_STRING
                    }
                )
            );
        
        ((fflib_SObjectUnitOfWork) mocks.verify(uowMock, mocks.times(1))).commitWork();
        System.assertEquals('success', result, 'Result should be success.');
    }
    
    /**
     * @description Test method for deleteProfilePicture method with Exception
     */
    @isTest
    public static void testDeleteProfilePictureWithException(){
        Id documentId = Fake.generateId(Document.SObjectType);
        Id userId = Fake.generateId(User.SObjectType);
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(
            fflib_SObjectUnitOfWork.class
        );

        mocks.startStubbing();
        ((fflib_ISObjectUnitOfWork) mocks.doThrowWhen(
            new TestException(MOCK_EXCEPTION_MESSAGE),
            uowMock
        	))
        	.commitWork();
        mocks.stopStubbing();
        
        Application.UnitOfWork.setMock(uowMock);
        
        Boolean exceptionOccured = false;
        String exceptionMessage;
        try{
            CDdProfilePictureUploaderController.deleteProfilePicture(userId, documentId); 
        }
        catch(AuraHandledException ex){
            exceptionOccured = true;
        }
        
        System.assert(exceptionOccured, 'Exception must be fired.');
    }
    
    /**
     * @author Mahesh Chouhan
     * @date Nov 2022
     * @description Exception class for customizing exception for Tests.
     */
    class TestException extends Exception {
    }
}