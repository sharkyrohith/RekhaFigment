/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 03/08/2021
*
* @group Apex Test
*
* @description Test class for Merchant Document trigger handler and helper 
**************************************************************************************************************************************/
@isTest
public class CDdMerchantDocumentTriggerHandlerTest {
    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{       
        CDdMerchantDocumentTriggerHandler.class,
        CDdMerchantDocumentHelper.class,
        CDdOpportunityTriggerHandler.class,
        CDdOpportunityTriggerHelper.class
    };
    /**
     * End - Test class to execute if one of these classes is updated
     */        
    public static Integer TEST_RECORD_SIZE = 1;
    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
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
            testRunUser.UserPermissionsSFContentUser = true;
        }
        return testRunUser;
    }
    @testSetup
    static void testSetup() {
        
        System.runAs(getTestRunUser()){
            Test.startTest();
            CDdContactTriggerHelper.insertCampaign();    
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;

            List<Account> accs = TDdAccountFactory.createAccounts('testAcct', TEST_RECORD_SIZE, 'Marketplace');
            Integer x = 0;
            for (Account a : accs){
                a.iPad_Username__c = 'test.' + a.Name + '@doordash.com';
                a.iPad_Password__c  = 'xyz';
                a.Restaurant_ID__c  = '1230000' + x++;
                a.Entity_Type__c = 'Corporation';
            }
            insert accs;

            Contact contact = new Contact(FirstName='Test', LastName='Merchant', Email='test@doordash.com', Birthdate = Date.newInstance(1991, 9, 29));
            insert contact;

            List<Opportunity> opps = new List<Opportunity>();
            Integer y = 0;
            for (Account a : accs) {
                Opportunity o = TDdOpportunityFactory.createOpportunity(
                        'Test Opportunity ' + y++,
                        a.Id,
                        contact.Id,
                        'Closed Won',
                        'Omitted',
                        UserInfo.getUserId()
                );
                o.Stripe_Account_Owner__r = contact;
                opps.add(o);
            }
            insert opps; 
            
            List<Merchant_Document__c> merchantDocuments = new List<Merchant_Document__c>();
            for (Account a : accs) {
                Merchant_Document__c merchantDocument = new Merchant_Document__c();
                merchantDocument.Merchant__c = a.id;
                merchantDocument.Type__c = 'Business Verification';
                merchantDocument.Sub_Type__c = 'Passport';
                merchantDocuments.add(merchantDocument);
            }
            insert merchantDocuments;
            
            // Insert a document 
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            for (Integer i=0; i < TEST_RECORD_SIZE; i++){
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Test';
                contentVersion.PathOnClient = 'test.png';
                contentVersion.versiondata = blob.valueof('test content' + i);
                contentVersion.IsMajorVersion = true;
                contentVersions.add(contentVersion);
            }
            insert contentVersions;
            contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersions];
            
            List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
            for (Integer j=0; j < TEST_RECORD_SIZE; j++){
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.LinkedEntityId = merchantDocuments[j].Id;
                contentDocumentLink.ContentDocumentId = contentVersions[j].ContentDocumentId;
                contentDocumentLink.ShareType = 'V';
                contentDocumentLinks.add(contentDocumentLink);
            }
            insert contentDocumentLinks;          
            
            Test.stopTest();
        }
    }
    @isTest
    static void testMerchantDocumentDelete() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Opportunity> opportunities = [ SELECT Id, Business_Verification_Document_Attached__c 
                                                FROM Opportunity
                                                WHERE Business_Verification_Document_Attached__c = true];
            System.assertEquals(TEST_RECORD_SIZE, opportunities.size());
            List<Merchant_Document__c> merchantDocuments = [SELECT Id FROM Merchant_Document__c];
            System.assertEquals(TEST_RECORD_SIZE, merchantDocuments.size());
            delete merchantDocuments;
            Test.stopTest();
            List<Opportunity> opportunitiesFromDB = [   SELECT Id, Business_Verification_Document_Attached__c 
                                                        FROM Opportunity
                                                        WHERE Business_Verification_Document_Attached__c = false];
            System.assertEquals(TEST_RECORD_SIZE, opportunitiesFromDB.size());            
        }
    }
    @isTest
    static void testMerchantDocumentFileURL() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Merchant_Document__c> merchantDocuments = [SELECT Id, Content_Version_Id__c, File_URL__c FROM Merchant_Document__c];
            System.assertEquals(TEST_RECORD_SIZE, merchantDocuments.size());
            List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion];
            System.assertEquals(TEST_RECORD_SIZE, contentVersions.size());
            // Verify merchant document file URL
            String merchantDocumentFileURL = merchantDocuments[0].File_URL__c;
            String contentDocumentURL = '';
            for (ContentVersion cv : contentVersions){
                if (cv.Id.equals(merchantDocuments[0].Content_Version_Id__c)){
                    contentDocumentURL = CDdContentDocumentLinkHelper.getContentDocumentURL(cv.contentDocumentId);
                }
            }
            System.assertEquals(merchantDocumentFileURL, contentDocumentURL);
            Test.stopTest();
        }
    }    
    @isTest
    static void testMerchantDocumentUpdate() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Opportunity> opportunities = [ SELECT Id, Business_Verification_Document_Attached__c 
                                                FROM Opportunity
                                                WHERE Business_Verification_Document_Attached__c = true];
            System.assertEquals(TEST_RECORD_SIZE, opportunities.size());
            List<Merchant_Document__c> merchantDocuments = [SELECT Id, File_URL__c FROM Merchant_Document__c];
            System.assertEquals(TEST_RECORD_SIZE, merchantDocuments.size());
            List<Merchant_Document__c> merchantDocumentsToUpdate = new List<Merchant_Document__c>();
            for (Merchant_Document__c md : merchantDocuments){
                merchantDocumentsToUpdate.add(new Merchant_Document__c(
                    Id = md.Id,
                    File_URL__c = null
                ));
            }
            update merchantDocumentsToUpdate;
            Test.stopTest();
            List<Opportunity> opportunitiesFromDB = [   SELECT Id, Business_Verification_Document_Attached__c 
                                                        FROM Opportunity
                                                        WHERE Business_Verification_Document_Attached__c = false];
            System.assertEquals(TEST_RECORD_SIZE, opportunitiesFromDB.size());            
        }
    }    
    @isTest
    static void testContentDocumentLinkDelete() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Opportunity> opportunities = [ SELECT Id, Business_Verification_Document_Attached__c 
                                                FROM Opportunity
                                                WHERE Business_Verification_Document_Attached__c = true];
            System.assertEquals(TEST_RECORD_SIZE, opportunities.size());
            List<Merchant_Document__c> merchantDocuments = [SELECT Id FROM Merchant_Document__c];
            System.assertEquals(TEST_RECORD_SIZE, merchantDocuments.size());
            Set<Id> merchantDocumentIds = new Set<Id>();
            for (Merchant_Document__c merchantDocument : merchantDocuments){
                merchantDocumentIds.add(merchantDocument.Id);
            }
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :merchantDocumentIds];
            System.assertEquals(TEST_RECORD_SIZE, contentDocumentLinks.size());
            delete contentDocumentLinks;
            Test.stopTest();
            List<Opportunity> opportunitiesFromDB = [   SELECT Id, Business_Verification_Document_Attached__c 
                                                        FROM Opportunity
                                                        WHERE Business_Verification_Document_Attached__c = false];
            System.assertEquals(TEST_RECORD_SIZE, opportunitiesFromDB.size());            
        }
    }
    @isTest
    static void testCreateOpportunityWithBizDocumentAttachedFlagSet() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Opportunity> opportunities = [ SELECT Id, AccountId, Business_Verification_Document_Attached__c 
                                                FROM Opportunity
                                                WHERE Business_Verification_Document_Attached__c = true];
            System.assertEquals(TEST_RECORD_SIZE, opportunities.size());

            Contact contact = new Contact(FirstName='Test1', LastName='MerchantNewOpp', Email='test.newOpp@doordash.com', Birthdate = Date.newInstance(1991, 9, 29));
            insert contact;

            List<Opportunity> newOpps = new List<Opportunity>();
            Opportunity newOpp = TDdOpportunityFactory.createOpportunity(
                    'Test New Opportunity ',
                    opportunities[0].AccountId,
                    contact.Id,
                    'Closed Won',
                    'Omitted',
                    UserInfo.getUserId()
            );
            newOpp.Stripe_Account_Owner__r = contact;
            newOpps.add(newOpp);
            insert newOpps;

            Test.stopTest();
            List<Opportunity> opportunitiesFromDB = [   SELECT Id, Business_Verification_Document_Attached__c 
                                                        FROM Opportunity
                                                        WHERE Id IN :newOpps
                                                        AND Business_Verification_Document_Attached__c = true];
            System.assertEquals(1, opportunitiesFromDB.size());            
        }
    }
    @isTest
    static void testValidateContentDocumentExists() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Opportunity> opportunities = [ SELECT Id, Business_Verification_Document_Attached__c 
                                                FROM Opportunity
                                                WHERE Business_Verification_Document_Attached__c = true];
            System.assertEquals(TEST_RECORD_SIZE, opportunities.size());
            List<Merchant_Document__c> merchantDocuments = [SELECT Id FROM Merchant_Document__c];
            System.assertEquals(TEST_RECORD_SIZE, merchantDocuments.size());
            List<Id> merchantDocumentIds = new List<Id>();
            for (Merchant_Document__c merchantDocument : merchantDocuments){
                merchantDocumentIds.add(merchantDocument.Id);
            }

            // Insert a document 
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'Test Another One';
            contentVersion.PathOnClient = 'test_another_one.png';
            contentVersion.versiondata = blob.valueof('test content xyz');
            contentVersion.IsMajorVersion = true;
            contentVersions.add(contentVersion);
            insert contentVersions;
            contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersions];
            System.assertEquals(1, contentVersions.size());
            
            Boolean hasError = false;
            String errorMessage = '';
            try {
                List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.LinkedEntityId = merchantDocumentIds[0];
                contentDocumentLink.ContentDocumentId = contentVersions[0].ContentDocumentId;
                contentDocumentLink.ShareType = 'V';
                contentDocumentLinks.add(contentDocumentLink);
                insert contentDocumentLinks;
            } catch(Exception e){
                hasError = true;
                errorMessage = e.getMessage();
            } 
            Test.stopTest();
            System.assertEquals(true, hasError);
            System.assertEquals(true, String.isNotBlank(errorMessage));
            System.assertEquals(true, errorMessage.indexOf(CDdContentDocumentLinkHelper.ERROR_MESSAGE_CONTENT_DOCUMENT_EXISTS)>-1);                    
        }
    }                                
}