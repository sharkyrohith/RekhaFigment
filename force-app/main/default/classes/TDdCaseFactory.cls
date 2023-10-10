public class TDdCaseFactory {

    public TDdCaseFactory(){
    }

    /**
* @author Saniya Belim
* @date 2018-11
*
* @description Create standard Case Record
* Parameters: numberOfCaseRecords - Number of Case records to be created
* recordType: Case Record Type
* default record type: Support
*/
    public static List<Case> createCaseRecords(integer numberOfCaseRecords, string recordType){
        List<Case> caseRecordsToBeInserted = new List<Case>();
        Id RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        caseRecordsToBeInserted = createCases(numberOfCaseRecords, RecTypeId);
        return caseRecordsToBeInserted;
    }

    public static List<Case> createCases(Integer numberOfCases, Id accountId, Id oppId, Id recordTypeId) {
        List<Case> cases = createCases(numberOfCases, recordTypeId);
        for (Case cas : cases) {
            cas.AccountId = accountId;
            cas.Opportunity_Name__c = oppId;
        }

        return cases;
    }

    public static List<Case> createCases(Integer numberOfCases, Id recordTypeId){
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < numberOfCases; i++) {
            Case cas = new Case(
                    RecordTypeId = recordTypeId,
                    Subject='Test Case',
                    Status='New',
                    Origin='Web',
                    Customer_Type__c='Consumer',
                    SuppliedEmail=i+'test@fakemail.com',
                    SuppliedName='Testy McTesterson '+i);
            cases.add(cas);
        }
        return cases;
    }

    public static List<LiveChatTranscript> createTranscripts(Integer numberOfTranscripts){
        List<LiveChatTranscript> transList = new List<LiveChatTranscript>();
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        for (Integer i = 0; i < numberOfTranscripts; i++) {
            LiveChatTranscript tx = new LiveChatTranscript(
                chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
                StartTime= datetime.newInstance(2017, 9, 15, 12, 31, 0), EndTime=datetime.newInstance(2017, 9, 15, 12, 32, 0),
                RequestTime=datetime.newInstance(2017, 9, 15, 12, 30, 0));
            transList.add(tx);
        }
        return transList;
    }


    public static List<Case> createSolveableSupportCase(Integer numberOfCases, Id recordtypeId) {
        return createSolveableSupportCase(numberOfCases, recordTypeId, null, null);
    }

    public static List<Case> createSolveableSupportCase(Integer numberOfCases, String recordType) {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        return createSolveableSupportCase(numberOfCases, recordTypeId, null, null);
    }

    public static List<Case> createSolveableSupportCase(Integer numberOfCases, String recordType, Id accountId, Id contactId) {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        return createSolveableSupportCase(numberOfCases, recordTypeId, accountId, contactId);
    }

    public static List<Case> createSolveableSupportCase(Integer numberOfCases, Id RecordtypeId, Id accountId, Id contactId) {
        List<Case> solveableCases = createCases(numberOfCases, recordTypeId);
        for(Case currCase : solveableCases) {
            currCase.AccountId = accountId;
            currCase.contactId = contactId;
            currCase.Customer_Type__c = 'Consumer';
            currCase.Resolution__c = 'Account Not ATO';
            currCase.Resolution_Type__c = 'Account Management - CX';
            currCase.Issue_Type__c = 'Account Management - CX';
            currCase.Issue__c = 'Suspicious Account Activity';
        }
        return solveableCases;
    }

    public static List<Case> createSendbirdCase(Integer numberofCases, Id accountId, Id contactId) {
        System.debug('Creating cases');
        Id recordtypeId = CDdSchemaUtils.getRecordTypeIdByDeveloperName(CDdSupportConstants.CASE_OBJECT_LABEL,
                            CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        List<Case> sendbirdCases = createSolveableSupportCase(numberOfCases, recordTypeId, accountid, contactId);
        for(Case currCase : sendbirdCases) {
            currCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
            currCase.Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
            currCase.chatKey__c = getRandomNumber();
            currCase.Issue__c = 'Update Account Information';
        }
        return sendbirdCases;

    }


    public static String getRandomNumber(){
        Integer len = 10;
        final String chars = '0123456789';
        String randStr = '';

        While (randStr.length() < len){
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

    public static StaticResourceCalloutMock getSendbirdMockResponse() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_Empty');//empty response
        mock.setStatusCode(200);//success
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        return mock;
    }

    public static Support_Feature_Flag__c getSupportFeatureFlag(Boolean doUpsert) {
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Sendbird_Use_Future_Method__c = false;
        featureFlag.Disable_THQ_Callouts__c = true;
        if(doUpsert) {
            upsert featureFlag;
        }
        return featureFlag;

    }
}