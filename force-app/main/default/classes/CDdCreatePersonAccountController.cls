/**
 * 
 * @author: Tia Xuan
 * @date: 2020-07
 * @description BZAPSUP-24 --- CSAT Responses Not Syncing with Salesforce
 *              Controller to create a person account and search existing person account 
 *              with email and phone for US
 * 
 */
public class CDdCreatePersonAccountController {

    @AuraEnabled
    public static string createPersonAccount(String caseId){
        Id personAccountRTId  = CDdSchemaUtils.ACCOUNT_RT.PersonAccountId();
        List<Case> caseList = [ select  Id,
                                        SuppliedEmail,
                                        SuppliedPhone,
                                        Full_Name__c,
                                        AccountId
                                from Case
                                where Id =: caseId];
        if (caseList.size() > 0){
            Case c = caseList[0];

            if (c.AccountId != null){
                throw new AuraHandledException('An account already exist for this case');
            }

            List<String> possiblePhoneNumbers = new List<String>();
            if (String.isNotBlank(c.SuppliedPhone)){
                String formattedPhoneNum = CDdStringUtil.formatPhoneNum(c.SuppliedPhone);
                if (!String.isBlank(formattedPhoneNum) && !String.isBlank(c.SuppliedPhone)) {
                    possiblePhoneNumbers.addAll(CDdStringUtil.getListOfPotentialPhoneNums(formattedPhoneNum));
                }
            } 

            String caseEmail = c.SuppliedEmail;

            if (String.isNotBlank(c.SuppliedPhone) || String.isNotBlank(c.SuppliedEmail)){
                String accQry = 'select Id ';
                accQry += '     from Account ';
                accQry += '     where  ( ';
                if (possiblePhoneNumbers.size() > 0){
                    accQry += '     Phone =: possiblePhoneNumbers ';
                }

                if (possiblePhoneNumbers.size() > 0 && String.isNotBlank(c.SuppliedEmail)){
                    accQry += '     or ';
                }

                
                if (String.isNotBlank(c.SuppliedEmail)){
                    accQry += '     PersonEmail =: caseEmail ';
                }

                accQry += ' ) ';
                accQry += ' and RecordTypeId =: personAccountRTId ';
                accQry += ' limit 10 ';

                List<Account> possibleAccts = Database.query(accQry);
                if (possibleAccts.size() > 0){
                    throw new AuraHandledException('There is already an account with the same email or phone');
                }
            }

            String firstName = '';
            String lastName = '';
            if (String.isNotBlank(c.Full_Name__c)){
                List<String> nameParts = c.Full_Name__c.split(' ');
                if (nameParts.size() >= 2){
                    firstName = nameParts[0];
                    for (Integer i=1; i< nameParts.size(); i++){
                        lastName += ' ' + nameParts[i];
                    }
                } else if (nameParts.size() == 1){
                    lastName = nameParts[0];
                } else {
                    lastName = '[Unknown]';
                }
            } 
            
            Account acc = new Account();
            acc.RecordTypeId = personAccountRTId;
            acc.PersonEmail = c.SuppliedEmail;
            acc.Phone = c.SuppliedPhone;
            acc.FirstName = firstName;
            acc.LastName = lastName;
            acc.PersonMailingCountry = 'United States';
            insert acc;

            Account currentAcct = [select Id, PersonContactId from Account where Id=: acc.Id];
            c.AccountId = currentAcct.Id;
            c.ContactId = currentAcct.PersonContactId;
            update c;
            return acc.Id;
        }

        return null;
    }
}