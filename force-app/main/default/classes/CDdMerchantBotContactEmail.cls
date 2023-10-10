// ===========================================================================
// Component: CDdMerchantBotContactEmail
// Author: Nayana Kapse
// Purpose: Merchant Chat bot uses this class to pull email address
// ===========================================================================
public with sharing class CDdMerchantBotContactEmail {
    /**
    * @author  Nayana
    * @date    12/2021
    * @decription  Input from chat Bot
    * @param   merchantId : This is coming from Dispatch which is value on Account.StoreId
    */
    public class MerchantAccountIdInput {
        @InvocableVariable( required=true )
        public Double merchantId;
    }

    /**
    * @author  Nayana
    * @date    12/2021
    * @decription  Input from chat Bot
    * @param   lstEmailAddress : List of email addresses
    */
    public class MerchantContactEmailOutput {
        @InvocableVariable( required=true )
        public List<String> lstEmailAddress;
        @InvocableVariable
        public Integer lstEmailAddressCount;
    }

    /**
    * @author  Nayana
    * @date    12/2021
    * @decription  This method is called from Merchant Chat bot
    * @param   MerchantAccountIdInput : This is coming from Bot
    * @return MerchantContactEmailOutput
    */
    @InvocableMethod(label='Get Merchant Contacts')
    public static List < MerchantContactEmailOutput > fetchMerchantContacts( List < MerchantAccountIdInput > lstMerchantIds ) {
        List <MerchantContactEmailOutput> objOutputs = new List <MerchantContactEmailOutput>();
        Set <Double> setMerchantIds = new Set <Double>();
        MerchantContactEmailOutput objOutput = new MerchantContactEmailOutput();
        objOutput.lstEmailAddress = new List<String>();
        Set<String> emailSet = new Set<String>();
        List<Account> lstAccount = new List<Account>();
        Map<String,Integer> mapMostFrequentEmail = new Map<String,Integer>();
        Map<Integer,Set<String>> mapEmailoccuranceSet = new Map<Integer,Set<String>>();
        Integer emailOccurance = 0;
        String contactEmail = '';
        try{
            //Ideally we will get 1 store Id at a time as it is called from bot.
            for(MerchantAccountIdInput mId:lstMerchantIds){
                setMerchantIds.add(mId.merchantId);
            }
            //First Get Decision Maker's email from Account. Ideally query will return 1 account.
            lstAccount = [SELECT Id, Decision_Maker__r.Email FROM Account
                          WHERE MerchantNo__c  IN: setMerchantIds AND Decision_Maker__r.Email!=null];
            for(Account acc : lstAccount){
                emailSet.add(acc.Decision_Maker__r.Email.toLowerCase());
            }
            if(!lstAccount.isEmpty()){
                //Query on recent cases to get mostly used and recent contact info
                for(AggregateResult aResult: [SELECT count(Id) noEmailOccurance , contactEmail
                                              FROM Case WHERE AccountId IN: lstAccount
                                              AND ContactEmail!=NULL AND CreatedDate = LAST_90_DAYS GROUP BY ContactEmail]){
                    emailOccurance = (Integer) aResult.get('noEmailOccurance');
                    contactEmail = (String) aResult.get('contactEmail');
                    //This is to get most commonly used email.This map will have count Vs email used on cases.
                    if(!mapEmailoccuranceSet.containsKey(emailOccurance)){
                        mapEmailoccuranceSet.put(emailOccurance,new Set<String>());
                    }
                    mapEmailoccuranceSet.get(emailOccurance).add(contactEmail.toLowerCase());
                }
                //Find out 3 emails
                List<Integer> lstEmailOccurance = new List<Integer>();
                if(!mapEmailoccuranceSet.isEmpty()){
                    lstEmailOccurance.addAll(mapEmailoccuranceSet.keySet());
                    lstEmailOccurance.sort();
                    for(Integer i = lstEmailOccurance.size()-1; i>=0;i--)
                    {
                        emailOccurance = lstEmailOccurance.get(i);
                        emailSet.addAll(mapEmailoccuranceSet.get(emailOccurance));
                        if(emailSet.size()>=3){
                            break;
                        }
                    }
                }
            }
             //Make sure we are showing only 3 email addresses
            if(emailSet.size()>3){
                emailOccurance =0;
                for (String str : emailSet) {
                    objOutput.lstEmailAddress.add(str);
                    emailOccurance++;
                    if(emailOccurance==3){
                        break;
                    }
                }
            }else{
                objOutput.lstEmailAddress.addAll(emailSet);
                objOutput.lstEmailAddress.add('Enter Email Address');
                objOutput.lstEmailAddressCount = objOutput.lstEmailAddress.size();
            }

        }catch(Exception e){
            CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()+e.getLineNumber() +e.getStackTraceString()}, 'CDdMerchantBotContactEmail');
        }finally{
            objOutputs.add( objOutput );
        }
        return objOutputs;
    }

}