@isTest
private class CDdMxEINVerificationCtrlTest {


    public static testmethod void testverifyEIN(){
        //soql on recortype to get the Account and Case recordtype Id
        RecordType accRecType = [select Id,Name from RecordType where sObjectType='Account' and Name = 'Marketplace'];
        RecordType caseRecType = [select Id,Name from RecordType where sObjectType='Case' and Name = 'Support'];

        //insert account
        Account accObj = TDdAccountFactory.createAccount(accRecType.Id);
        insert accObj;

        //insert Case
        List<Case> caseObj = TDdCaseFactory.createCaseRecords(1,caseRecType.Name);
        caseObj[0].AccountId = accObj.id;
        caseObj[0].Customer_Type__c = 'Consumer';
        caseObj[0].Status = 'Open';
        insert caseObj;

        Blob key = Crypto.generateAesKey(256);
        String key2 = EncodingUtil.base64Encode(key);
        Encrypted_Value__c envalue = new Encrypted_Value__c ();
       envalue.Value__c = key2;
       envalue.Description__c = 'LEM-2144: This key is used for encrypting Tax Id using AES-256.';
       envalue.Name = 'AES-256';
        Insert envalue;


        CDdMxEINVerificationCtrl.displayAccountID(caseObj[0].id);

        Account accRec = [Select Id, EIN_Encrypted__c, Name from Account where Id=: accObj.Id];
        Case caseRec = [Select Id, Account.Name from Case where Id=: caseObj[0].Id];
        system.assertEquals(caseRec.Account.Name, 'Test Account');

        CDdMxEINVerificationCtrl.compareLast4EIN(accRec.Id, '2346', caseRec.id);

        Task taskObj = [Select Id, Subject, Status from Task where WhatId =: caseRec.id ];
        system.assertEquals(taskObj.Subject, 'Mx Verified UnSuccessfully');

        CDdMxEINVerificationCtrl.compareLast4EIN(accRec.Id, '6789', caseRec.id);

    }

    public static testmethod void testverifyEncryptedTaxId(){

        //soql on recortype to get the Account and Case recordtype Id
        RecordType accRecType = [select Id,Name from RecordType where sObjectType='Account' and Name = 'Marketplace'];
        RecordType caseRecType = [select Id,Name from RecordType where sObjectType='Case' and Name = 'Support'];

        //insert account
        Account accObj = TDdAccountFactory.createAccount(accRecType.Id);
        accObj.Encrypted_Tax_Id__c = 'K4zgdNnp3H0sYvcQienrK6Gc8AR6iRxuvOIoXiUr9hE=';
        accObj.Lemonade_Record_ID__c = '0018M00000G0LcKQAV';

        insert accObj;
        List<Case> caseObj = TDdCaseFactory.createCaseRecords(1,caseRecType.Name);
        caseObj[0].AccountId = accObj.id;
        caseObj[0].Customer_Type__c = 'Consumer';
        caseObj[0].Status = 'Open';
        insert caseObj;

        Encrypted_Value__c envalue = new Encrypted_Value__c ();
       envalue.Value__c = 'mqKfRqLRpDDzMXa0JGFPqyb4xZxY+lPAdhXOa8LaroQ=';
       envalue.Description__c = 'LEM-2144: This key is used for encrypting Tax Id using AES-256.';
       envalue.Name = 'AES-256';
        Insert envalue;


        CDdMxEINVerificationCtrl.displayAccountID(caseObj[0].id);

        Account accRec = [Select Id, EIN_Encrypted__c, Name from Account where Id=: accObj.Id];
        Case caseRec = [Select Id, Account.Name from Case where Id=: caseObj[0].Id];
        system.assertEquals(caseRec.Account.Name, 'Test Account');

        CDdMxEINVerificationCtrl.compareLast4EIN(accRec.Id, '9990', caseRec.id);

        Task taskObj = [Select Id, Subject, Status from Task where WhatId =: caseRec.id ];
        system.assertEquals(taskObj.Subject, 'Mx Verified Successfully');


    }
}