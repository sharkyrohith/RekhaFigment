@isTest
private class CDdMxDocumentsControllerTest {
    @isTest static void masterdataMethod() {
        
        Mx_Business_Verification_Status_Reason__c statusReason = new Mx_Business_Verification_Status_Reason__c();
        statusReason.Status__c = 'Denied';
        statusReason.Status_Reason__c = 'Denied1';
        insert statusReason;
        
        Mx_Document_Type__c docType = new Mx_Document_Type__c();
        docType.Country__c = 'US';
        docType.Document_Type__c = 'Passport';
        insert docType;
        
        Mx_Onboarding__c onBaording = new Mx_Onboarding__c();
        onBaording.StoreId__c = '98765';
        onBaording.Business_Verification_Status__c = '';
        onBaording.Business_Verification_Status_Reason__c = '';
        insert onBaording;
        
        List<Account> accs = TDdAccountFactory.createAccounts('StoreFrontCaseParentAcc0', 1, 'Marketplace');
        accs[0].Restaurant_Id__c = '98765';
        accs[0].BillingCountryCode = 'US';
        insert accs[0];
        
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Marketplace Onboarding');
        caseList[0].AccountId = accs[0].Id;
        insert caseList;
        
        CDdMxDocumentService.checkMxDocumentContentFolder(CDdMxDocumentService.getMxDocumentLibrary());
        
        Test.startTest();
            CDdMxDocumentsController.MasterDataWrapper returnData = CDdMxDocumentsController.getMasterData(caseList[0].Id);
            CDdMxDocumentsController.uploadCV('base64', 'filename','98765', 'Passport', 
                                                'Test Notes', 'Pending Review', 'Test File');
            CDdMxDocumentsController.DataWrapper returnFiles = CDdMxDocumentsController.getData(caseList[0].Id);
        Test.stopTest();
        
        system.assert(returnData != null);
        system.assert(returnFiles != null);
        system.assert(returnFiles.lstContentVersion.size() == 1);
    }
}