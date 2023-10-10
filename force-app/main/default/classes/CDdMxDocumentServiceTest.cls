@isTest
private class CDdMxDocumentServiceTest {

    public static testMethod void testAddMxDocumentToLibrary(){
        Id oppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
        Id marketplaceOnboardingRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();

        // insert account
        Account testAcc = TDdAccountFactory.createAccounts('Default Values', 1, 'Marketplace')[0];
        testAcc.BillingCountryCode = 'US';
        testAcc.BillingCountry = 'United States';
        testAcc.BillingState = 'CA';
        testAcc.BillingPostalCode = '91367';
        testAcc.Phone = '120456789';
        testAcc.CurrencyISOCode = 'USD';
        testAcc.Restaurant_ID__c = '11111';
        insert testAcc;

        // Create Opportunity
        Opportunity recOpp = new Opportunity(AccountId = testAcc.Id,Name = 'Test Opportunity',CloseDate= System.Today(),RecordtypeId=oppRecTypeId,
                                          StageName='Prospecting',Pricebook2Id = Test.getStandardPricebookId());
        insert recOpp;


        Case recCase = new Case(AccountId = testAcc.Id, RecordTypeId = marketplaceOnboardingRecordTypeId, Type='My Type',
                                Origin='My Origin', Status='Open', Opportunity_Name__c = recOpp.Id);
        insert recCase;
                
        CDdMxDocumentService.checkMxDocumentContentFolder(CDdMxDocumentService.getMxDocumentLibrary());        
        
        Test.startTest();
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Content Version';
        contentVersion.PathOnClient = 'TestCOntentVersion.pdf';
        contentVersion.VersionData = Blob.valueOf('Test Data');
        contentVersion.Origin = 'C';
        contentVersion.Mx_Store_Id__c = '11111';
        contentVersion.Mx_Document_Type__c = 'Passport';
        contentVersion.Mx_Country__c = 'US';
        insert contentVersion;

        contentVersion = [Select Id,ContentDocumentId,Mx_Store_Id__c,Mx_Document_Type__c,Mx_Country__c,Mx_Document_Verification_Status__c FROM ContentVersion
                                            WHERE Id = :contentVersion.Id];
        System.assert(contentVersion != null);
        System.assert('Pending Review'.equals(contentVersion.Mx_Document_Verification_Status__c));
        List<ContentDocumentLink> contentDocumentLinks = [Select Id, LinkedEntityId from ContentDocumentLink
                                                          WHERE ContentDocumentId = :contentVersion.ContentDocumentId];
        System.assertEquals(3, contentDocumentLinks.size());
        
        ContentWorkspace contentLibrary = CDdMxDocumentService.getMxDocumentLibrary();
        for(ContentDocumentLink contentDocumentLink:contentDocumentLinks){
            System.assert((new set<Id>{testAcc.Id, recCase.Id, contentLibrary.Id}).contains(contentDocumentLink.LinkedEntityId));
        }

        ContentFolder rootFolder = CDdMxDocumentService.getMxDocumentContentFolder(contentLibrary);
        
        Set<String> countryDocumentTypeSet = new Set<String>();
        for(Mx_Document_Type__c documentType: [SELECT Id,Document_Type__c,Country__c FROM Mx_Document_Type__c
                                                WHERE Country__c = :contentVersion.Mx_Country__c AND
                                                Document_Type__c = :contentVersion.Mx_Document_Type__c]){
            countryDocumentTypeSet.add(documentType.Country__c+documentType.Document_Type__c);
        }

        System.assert(countryDocumentTypeSet.contains(contentVersion.Mx_Country__c+contentVersion.Mx_Document_Type__c));
        
        ContentVersion contentVersion1 = new ContentVersion();
        contentVersion1.Title = 'Test Content Version Latest';
        contentVersion1.PathOnClient = 'TestCOntentVersionUpdated.pdf';
        contentVersion1.VersionData = Blob.valueOf('Test Data Updated');
        contentVersion1.Origin = 'C';
        contentVersion1.Mx_Store_Id__c = '11111';
        contentVersion1.Mx_Document_Type__c = 'Passport';
        contentVersion1.Mx_Country__c = 'US';
        insert contentVersion1;
        
        contentVersion1 = [Select Id,ContentDocumentId,Mx_Store_Id__c,Mx_Document_Type__c,Mx_Country__c,Mx_Document_Verification_Status__c FROM ContentVersion
                                            WHERE Id = :contentVersion1.Id];
        
        System.assertEquals(contentVersion1.ContentDocumentId, contentVersion.ContentDocumentId);
        Test.stopTest();

    }
}