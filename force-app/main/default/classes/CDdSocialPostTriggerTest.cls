/**
 *
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Test class for CDdSocialPostTriggerHandler migration from VSocial post and Caviar org
 */
@isTest
public class CDdSocialPostTriggerTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;

    static Map<String, Object> sampleSocialData;

    static Social.InboundSocialPostHandlerImpl handler;

    static {
        handler = new Social.InboundSocialPostHandlerImpl();
        sampleSocialData = getSampleSocialData('1');
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    }

   /**
    * @description Prepare and return the test running user
    */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
   /**
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            CDdContactTriggerHelper.insertCampaign();
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = getTestRunUser().Id);
            validation.Bypass_Opportunity_Validations__c = true;  validation.Bypass_Case_Validations__c = true;
            insert validation;
            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;
            TDdCaseFactory.getSupportFeatureFlag(true);
        }
    }

    @isTest
    static void verifyTwitterCampaign() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vTwitter_Campaign;
            mapping.Queue_API_Name__c = System.label.vTwitter_Campaign;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.Provider = 'Twitter';
            post.PostTags = 'Twitter Campaign';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();

            Case createdCase = [SELECT Id, Status, OwnerId, Initial_Queue_Name__c, Initial_Queue__c FROM Case];
            Group queue = [select Id, Name, DeveloperName from Group where DeveloperName =: System.label.vTwitter_Campaign];

            System.assertEquals(queue.Id, createdCase.OwnerId, 'Unexpected owner.');
            System.assertEquals(queue.Id, createdCase.Initial_Queue__c, 'Unexpected initial queue.');
            System.assertEquals(queue.Name, createdCase.Initial_Queue_Name__c, 'Unexpected initial queue name.');
        }
    }

    @isTest
    static void testTwitterPost() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vTwitter_Post;
            mapping.Queue_API_Name__c = System.label.vTwitter_Post;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.MessageType = 'Post';
            post.Provider = 'Twitter';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();
        }
    }

    @isTest
    static void testTwitterDM() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vTwitter_DM;
            mapping.Queue_API_Name__c = System.label.vTwitter_DM;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.MessageType = 'Direct';
            post.Provider = 'Twitter';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();
        }
    }

    @isTest
    static void testFacebookPost() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vFacebook_Post;
            mapping.Queue_API_Name__c = System.label.vFacebook_Post;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.MessageType = 'Post';
            post.Provider = 'Facebook';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();
        }
    }

    @isTest
    static void testFacebookMessage() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vFacebook_Message;
            mapping.Queue_API_Name__c = System.label.vFacebook_Message;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.MessageType = 'Private';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();
        }
    }

    @isTest
    static void testInstagramPost() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vInstagram_Post;
            mapping.Queue_API_Name__c = System.label.vInstagram_Post;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.Provider = 'Instagram';
            post.MessageType = 'Post';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();
        }
    }

    @isTest
    static void verifyNewRecordCreation(){
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vTwitter_Post;
            mapping.Queue_API_Name__c = System.label.vTwitter_Post;

            vSocial_Post_Queue_Mapping__c mapping2 = new vSocial_Post_Queue_Mapping__c();
            mapping2.name = System.label.vTwitter_DM;
            mapping2.Queue_API_Name__c = System.label.vTwitter_DM;

            insert new List<vSocial_Post_Queue_Mapping__c>{mapping,mapping2};

            SocialPost post = getSocialPost(sampleSocialData);

            SocialPersona persona = getSocialPersona(sampleSocialData);
            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();
            SocialPost createdPost = [SELECT Id, PersonaId, ParentId, WhoId FROM SocialPost];
            SocialPersona createdPersona = [SELECT Id, ParentId FROM SocialPersona];
            Contact createdContact = [SELECT Id FROM Contact];
            Case createdCase = [SELECT Id, ContactId FROM Case];

            Case caseTemp = new Case(Status='Open',Origin='Twitter',Customer_Type__c='Dasher');
            insert caseTemp;

            SocialPost postTweetSecond = getSocialPost(getSampleSocialData('2'));
            postTweetSecond.parentId=caseTemp.Id;
            insert postTweetSecond;

            Case caseDM = new Case(Status='Open',Origin='Twitter',Customer_Type__c='Dasher');
            insert caseDM;

            SocialPost postTweetDirect = getSocialPost(getSampleSocialData('3'));
            postTweetDirect.parentId=caseDM.Id;
            postTweetDirect.MessageType = 'Direct';
            insert postTweetDirect;

            System.assertEquals(createdPost.PersonaId, createdPersona.Id, 'Post is not linked to the Persona.');
            System.assertEquals(createdPost.WhoId, createdPersona.ParentId, 'Post is not linked to the Contact');
            System.assertEquals(createdPost.ParentId, createdCase.Id, 'Post is not linked to the Case.');
            System.assertEquals(createdCase.ContactId, createdContact.Id, 'Contact is not linked to the Case.');
        }
    }

    @isTest
    static void validateCaseUpdates() {
        System.runAs(getTestRunUser()){
            SocialPost post = getSocialPost(sampleSocialData);
            post.TopicProfileName = '@CaviarSupport';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();

            SocialPost createdPost = [SELECT Id, PersonaId, ParentId, WhoId FROM SocialPost];
            SocialPersona createdPersona = [SELECT Id, ParentId FROM SocialPersona];
            Case createdCase = [SELECT Id, OwnerId, Origin, ContactId, RecordTypeId, Type, Priority, Subject FROM Case];

            Id ownerId = [select Id from Group where DeveloperName = 'Caviar_Social_Support' and Type = 'Queue'].Id;
            Id caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Caviar_Support').getRecordTypeId();

            System.assertEquals(createdPost.PersonaId, createdPersona.Id, 'Post is not linked to the Persona');
            System.assertEquals(createdPost.WhoId, createdPersona.ParentId, 'Post is not linked to the Contact');
            System.assertEquals(createdPost.ParentId, createdCase.Id, 'Post is not linked to the Case');
            System.assertEquals(ownerId, createdCase.OwnerId, 'Incorrect OwnerId');
            System.assertEquals('Twitter', createdCase.Origin, 'Incorrect Origin');
            System.assertEquals(caseRecordType, createdCase.RecordTypeId, 'Incorrect RecordTypeId');
            System.assertEquals('Caviar Social', createdCase.Type, 'Incorrect Type');
        }
    }

    @isTest
    static void validateCaseUpdates2() {
        System.runAs(getTestRunUser()){
            SocialPost post = getSocialPost(sampleSocialData);
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();

            SocialPost createdPost = [SELECT Id, PersonaId, ParentId, WhoId FROM SocialPost];
            SocialPersona createdPersona = [SELECT Id, ParentId FROM SocialPersona];
            Case createdCase = [SELECT Id, OwnerId, Origin, ContactId, RecordTypeId, Type, Priority, Subject FROM Case];

            Id ownerId = [select Id from Group where DeveloperName = 'Caviar_Social_Support' and Type = 'Queue'].Id;
            Id caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();

            System.assertEquals(createdPost.PersonaId, createdPersona.Id, 'Post is not linked to the Persona');
            System.assertEquals(createdPost.WhoId, createdPersona.ParentId, 'Post is not linked to the Contact');
            System.assertEquals(createdPost.ParentId, createdCase.Id, 'Post is not linked to the Case');
            System.assertEquals('Twitter', createdCase.Origin, 'Incorrect Origin');
            System.assertEquals(caseRecordType, createdCase.RecordTypeId, 'Incorrect RecordTypeId');
        }
    }

    @isTest
    static void updateSP() {
        System.runAs(getTestRunUser()){
            SocialPost post = getSocialPost(sampleSocialData);
            SocialPersona persona = getSocialPersona(sampleSocialData);

            handler.handleInboundSocialPost(post, persona, sampleSocialData);

            List<SocialPost> createdPost = [SELECT Id, PersonaId, ParentId, WhoId, TopicProfileName FROM SocialPost];

            CDdSocialPostTriggerHandler triggerHandler = new CDdSocialPostTriggerHandler();
            triggerHandler.beforeUpdate(createdPost, null);
            triggerHandler.afterUpdate(createdPost, null);
        }
    }

    /*
    *@author : Sanidhya Jain
	*description : This method is to test when Provider is Facebook & Message Type is Reply then case should be assigned to Facebook Queue
	*/
    @isTest
    static void testFacebookReply() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vFacebook_Post;
            mapping.Queue_API_Name__c = System.label.vFacebook_Post;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.MessageType = 'Reply';
            post.Provider = 'Facebook';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();

            Case createdCase = [SELECT Id, Status, OwnerId, Initial_Queue_Name__c, Initial_Queue__c FROM Case];
            Group queue = [SELECT  Id,  DeveloperName, Name FROM Group WHERE Id =: createdCase.OwnerId  AND Type='Queue'];

            System.assertEquals(System.label.vFacebook_Post, queue.DeveloperName, 'Queue name should be name');
        }
    }

    /*
    *@author : Sanidhya Jain
	*description : This method is to test when Provider is Instagram & Message Type is Reply then case should be assigned to Instagram Queue
	*/
    @isTest
    static void testInstagramReply() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vInstagram_Post;
            mapping.Queue_API_Name__c = System.label.vInstagram_Post;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.MessageType = 'Reply';
            post.Provider = 'Instagram';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();

            Case createdCase = [SELECT Id, Status, OwnerId, Initial_Queue_Name__c, Initial_Queue__c FROM Case];
            Group queue = [SELECT  Id,  DeveloperName, Name FROM Group WHERE Id =: createdCase.OwnerId  AND Type='Queue'];

            System.assertEquals(System.label.vInstagram_Post, queue.DeveloperName, 'Queue name should be name');
        }
    }

    /*
    *@author : Sanidhya Jain
	*description : This Method is to checkInboundCount on Social Post
	*/
    @isTest
    static void testupdateDMIndoundOnCase() {
        System.runAs(getTestRunUser()){
            vSocial_Post_Queue_Mapping__c mapping = new vSocial_Post_Queue_Mapping__c();
            mapping.name = System.label.vInstagram_Post;
            mapping.Queue_API_Name__c = System.label.vInstagram_Post;
            insert mapping;

            SocialPost post = getSocialPost(sampleSocialData);
            post.MessageType = 'Reply';
            post.Provider = 'Instagram';
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            Case createdCase = [SELECT Id, Status, OwnerId, Initial_Queue_Name__c, Initial_Queue__c FROM Case];
            List<SocialPost> spList = new List<SocialPost>([Select id,Name,isOutbound,PersonaId,ParentId From SocialPost Where ParentId =: createdCase.id ]);
            CDdSocialPostTriggerHelper.updateDMIndoundOnCase(spList);
            test.stopTest();

            Case createdCaset = [SELECT Id, Status,Last_Social_Inbound_Subject__c, OwnerId, Initial_Queue_Name__c, Initial_Queue__c FROM Case];

            System.assertEquals(spList[0].Name, createdCaset.Last_Social_Inbound_Subject__c, 'Case Subject should be same as Inbound Post');
        }
    }

    static SocialPost getSocialPost(Map<String, Object> socialData) {
        SocialPost post = new SocialPost();
        post.Name = String.valueOf(socialData.get('source'));
        post.Content = String.valueOf(socialData.get('content'));
        post.Posted = Date.valueOf(String.valueOf(socialData.get('postDate')));
        post.PostUrl = String.valueOf(socialData.get('postUrl'));
        post.PostTags = String.valueOf(socialData.get('postTags'));
        post.PostPriority = String.valueOf(socialData.get('postPriority'));
        post.Provider = String.valueOf(socialData.get('mediaProvider'));
        post.MessageType = String.valueOf(socialData.get('messageType'));
        post.ExternalPostId = String.valueOf(socialData.get('externalPostId'));
        post.R6PostId = String.valueOf(socialData.get('r6PostId'));
        post.TopicProfileName = '@doordash_help';
        return post;
    }

    static SocialPersona getSocialPersona(Map<String, Object> socialData){
        SocialPersona persona = new SocialPersona();
        persona.Name = String.valueOf(socialData.get('author'));
        persona.RealName = String.valueOf(socialData.get('realName'));
        persona.Provider = String.valueOf(socialData.get('mediaProvider'));
        persona.MediaProvider = String.valueOf(socialData.get('mediaProvider'));
        persona.ExternalId = String.valueOf(socialData.get('externalUserId'));
        return persona;
    }

    static Map<String, Object> getSampleSocialData(String suffix) {
        Map<String, Object> socialData = new Map<String, Object>();
        socialData.put('r6PostId', 'R6PostId' + suffix);
        socialData.put('r6SourceId', 'R6SourceId' + suffix);
        socialData.put('postTags', 'M Team, Twitter Influencer, Random Tag');
        socialData.put('postPriority', 'High Priority');
        socialData.put('externalPostId', 'ExternalPostId' + suffix);
        socialData.put('content', 'Content' + suffix);
        socialData.put('postDate', '2015-01-12T12:12:12Z');
        socialData.put('mediaType', 'Twitter');
        socialData.put('author', 'Author');
        socialData.put('skipCreateCase', false);
        socialData.put('mediaProvider', 'TWITTER');
        socialData.put('externalUserId', 'ExternalUserId');
        socialData.put('postUrl', 'PostUrl' + suffix);
        socialData.put('messageType', 'Tweet');
        socialData.put('source', 'Source' + suffix);
        socialData.put('replyToExternalPostId', null);
        socialData.put('realName', 'Real Name');
        return socialData;
    }

    static Map<String, Object> getDirectTweetData(String suffix) {
        Map<String, Object> socialData = new Map<String, Object>();
        socialData.put('r6PostId', 'R6PostId' + suffix);
        socialData.put('r6SourceId', 'R6SourceId' + suffix);
        socialData.put('postTags', null);
        socialData.put('externalPostId', 'ExternalPostId' + suffix);
        socialData.put('content', 'Content' + suffix);
        socialData.put('postDate', '2015-01-12T12:12:12Z');
        socialData.put('mediaType', 'Twitter');
        socialData.put('author', 'Author');
        socialData.put('skipCreateCase', false);
        socialData.put('mediaProvider', 'TWITTER');
        socialData.put('externalUserId', 'ExternalUserId');
        socialData.put('postUrl', 'PostUrl' + suffix);
        socialData.put('messageType', 'Direct');
        socialData.put('source', 'Source' + suffix);
        socialData.put('replyToExternalPostId', null);
        socialData.put('realName', 'Real Name');
        return socialData;
    }

}