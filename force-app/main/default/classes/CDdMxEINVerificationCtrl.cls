public class CDdMxEINVerificationCtrl {

    private static final String ALOGORITHM_ENCRYPT_VALUE_RECORD_NAME = 'AES-256';
    @AuraEnabled
    public static Case displayAccountID(String caseId){
        Case objCase = [SELECT Id, AccountId, Account.Name, Account.EIN_Encrypted__c,Account.Encrypted_Tax_Id__c from Case where Id =: caseId];
        return objCase;
    }

    /**
     * description verify 4 digit EIN number with the Case Account EIN number
     * @JIRA# LEM-2144 - Added the logic to verify EIN number with the Case Account EIN number for Lemonade accounts
     */
    @AuraEnabled
    public static Boolean compareLast4EIN(String accountID, String last4EIN, String caseId){
        Account objAcc = [Select Id, Name, EIN_Encrypted__c,Encrypted_Tax_Id__c,Lemonade_Record_ID__c FROM Account where Id=: accountID];
        Encrypted_Value__c encryptedValueRec = [Select Id,Value__c,Name from Encrypted_Value__c where Name  =:ALOGORITHM_ENCRYPT_VALUE_RECORD_NAME];
        String substrEIN;
        if(objAcc.EIN_Encrypted__c !=null){
          substrEIN = string.valueOf(objAcc.EIN_Encrypted__c.right(4));
         }
        if(String.isNotBlank(objAcc.Encrypted_Tax_Id__c) && String.isNotBlank(objAcc.Lemonade_Record_ID__c)){
            Blob key = EncodingUtil.base64Decode(encryptedValueRec.Value__c);
            Blob decrypted = Crypto.decryptWithManagedIV('AES256', key,  EncodingUtil.base64Decode(objAcc.Encrypted_Tax_Id__c));
            substrEIN = decrypted.tostring();
        }

        if(substrEIN == last4EIN) {
            CDdMxEINVerificationCtrl.createApexLog('Successfully', caseId);
            return true;

        }
        else{
            CDdMxEINVerificationCtrl.createApexLog('UnSuccessfully', caseId);
            return false;
         }

    }

    //log the details in Apex Log object
    public static void createApexLog(String result, String caseID){
        Task newTask = new Task();
        newTask.Subject = 'Mx Verified '+ result;
        newTask.WhatId = caseID;
        newTask.ActivityDate = date.today();
        newTask.Status = 'Completed';
        newTask.OwnerId = userinfo.getuserid();
        insert newTask;
    }
}