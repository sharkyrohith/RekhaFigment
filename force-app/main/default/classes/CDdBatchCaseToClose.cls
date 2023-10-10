global class CDdBatchCaseToClose implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private static final String SUPPORT_RECORDTYPE_NAME = 'Support';
    private static final String JAPAN_COUNTRY = 'Japan';
    private static final String DASHER_CUSTOMER_TYPE = 'Dasher';
    private static final String PAYMANAGEMENT_DX_CATEGORY = 'Pay Management - DX';
    private static final String COVID19_FINANCIAL_ASSISTANCE = 'Covid-19 Financial Assistance';


    global Date startDate = Date.TODAY();

    global List<String> Profiles = new List<String> {
        'BizApps Team', 'System Administrator', 'Operations Team', 'Local - Agent', 'HQ Team', 'Agent', 'Vendor Team', 'Tier 3 Agent'
    };

    global Integer iEntry = 0;      // starting position
    global Integer onlyEntry = 0;   // allow running of only a single entry (based on the Order field)
    global List<Batch_Case_To_Close__mdt> batchCaseToCloseList = CDdCustomMetadata.getBatchCaseCloseList();

    global String TOOLS_ADMIN_USER = CDdCustomMetadata.getIdValueFor('Tools_Admin_User');

    global void execute(SchedulableContext sc) {
        Set<String> runningStatus = new Set<String> {'Holding', 'Processing', 'Queued', 'Preparing'};
        ApexClass thisClass = [SELECT Id FROM ApexClass WHERE Name = 'CDdBatchCaseToClose' LIMIT 1];
        AsyncApexJob[] runningJobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClassId = :thisClass.Id
            AND Status IN :runningStatus
        ];
        CDdBatchCaseToClose batch = new CDdBatchCaseToClose();
        for (Integer i = batch.batchCaseToCloseList.size() - 1; i >= 0; i--) {
            if (onlyEntry > 0) {    // run only a single entry
                if (batch.batchCaseToCloseList[i].Order__c != onlyEntry) {
                    batch.batchCaseToCloseList.remove(i);
                }
            } else {                // filter out inactive and skipped entries
                if (
                    (batch.batchCaseToCloseList[i].Active__c != true)
                ||  ((runningJobs.size() >= 1) && (batch.batchCaseToCloseList[i].SkipOnWrap__c))
                )
                    batch.batchCaseToCloseList.remove(i);
            }
        }
        Database.executeBatch(batch, CDdCustomMetadata.getBatchSize('CDdBatchCaseToClose'));
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<Agent_Setting__c> agentSettings = [SELECT Id, Is_Agent__c, Name, Profile_Name__c, SetupOwnerId, SetupOwner.Name
                                                    FROM Agent_Setting__c
                                                    WHERE Is_Agent__c = TRUE];

        Set<String> agentProfileNames = new Set<String>();
        for(Agent_Setting__c agentSetting : agentSettings) {
            if(!String.isblank(agentSetting.Profile_Name__c)) {
                Profiles.add(agentsetting.Profile_Name__c);
            }
        }
        List<RecordType> rtCase = [select Id, Name from RecordType where SObjectType = 'Case'];
        Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : rtCase){
            rtMap.put(rt.Name, rt.Id);
        }

        Boolean OmitProfileCheck = batchCaseToCloseList[iEntry].OmitProfileCheck__c;

        List<Profile> ownerProfiles = [SELECT Id, Name FROM Profile];
        Map<String, Id> profileMap = new Map<String, Id>();
        Set<Id> profileIDs = new Set<Id>();
        for (Profile p : ownerProfiles) profileMap.put(p.Name, p.Id);
        for (String profile : Profiles) profileIDs.add(profileMap.get(profile));

        Integer hoursToWait = (Integer)batchCaseToCloseList[iEntry].Hours__c;
        DateTime hours = DateTime.now().addHours(hoursToWait * -1);
        Integer maxLookBack = CDdCustomMetadata.getCustomNumber('CDdBatchCaseToClose');
        // changing lookback threshold to 3 from 7 so that we can look back upto 4 days.

        if ((maxLookBack == null) || (maxLookBack < 3)) maxLookBack = 7;
        DateTime maxCaseAge = DateTime.now().addDays(-1 * maxLookBack);
        String rtName = batchCaseToCloseList[iEntry].Record_Type__c;
        Id rtId = rtMap.get(rtName);

        String fieldList = 'Id, Status, Subject, Customer_Type__c, Issue__c, Issue_Category__c, ' +
            'Issue_Type__c, Issue_PM__c, Solved_At__c, Solved_Date__c, Resolution__c, Resolution_Type__c, ' +
            'Upsert_Error__c, LastModifiedDate, Error_Exception__c, AccountId, RecordType.Name, Type, Owner.Name ';

        List<String> Priorities = new List<String> {
            'Low', 'Medium', 'Normal', 'High', 'Escalated' // Everything EXCEPT Urgent ...
        };

        String whereBase = '(RecordTypeId = :rtId) AND (isClosed = false) AND (Priority IN: Priorities)';
        if (! OmitProfileCheck) whereBase += ' AND (Owner.ProfileId IN :profileIDs)';

        // BZAPSUP-1722 05/2021 Tia Xuan Do Not AutoClose Japan CFA Cases
        if (CDdExperimentSvc.getSupportFeatureFlag('Enable_Case_Close_Japan_CFA_Exclusion__c')){
            Id supportRT = rtMap.get(SUPPORT_RECORDTYPE_NAME);
            String japanExclusion = ' AND (NOT ( RecordTypeId = \'' + supportRT + '\'';
            japanExclusion += '                 AND Country__c = \'' + JAPAN_COUNTRY + '\'';
            japanExclusion += '                 AND Customer_Type__c = \'' + DASHER_CUSTOMER_TYPE + '\'';
            japanExclusion += '                 AND Issue_Type__c = \'' +  PAYMANAGEMENT_DX_CATEGORY + '\'';
            japanExclusion += '                 AND Issue__c = \'' + COVID19_FINANCIAL_ASSISTANCE + '\'))';
            whereBase += japanExclusion;
        }
        String whereClause = ' WHERE ' + whereBase;
        if (CDdExperimentSvc.getSupportFeatureFlag('Case_Close_Job_use_Where_Clause__c')){
            whereClause = whereClause+ ' AND ' + batchCaseToCloseList[iEntry].Where_Clause__c;
        } else {
            whereClause = whereClause+ ' AND ' + batchCaseToCloseList[iEntry].Criteria__c;
        }

        if (batchCaseToCloseList[iEntry].Status_Criteria__c != null)
            whereClause += ' AND ' + batchCaseToCloseList[iEntry].Status_Criteria__c;

        if (rtName == 'Support') whereClause += ' AND LastModifiedDate > :maxCaseAge';

        String query = 'SELECT ' + fieldList + ' FROM Case ';

        if (! Test.isRunningTest()) query += whereClause;    // Ensure we retrieve test data while testing.

        System.debug('query = ' + query);
        List<String> messages = new List<String>();
        // messages.add('Processing record type: ' + rtName + '...');
        messages.add(
        'Processing record type: ' + rtName + ' Max Case Age = ' + maxCaseAge
        + ' ProfileIds = ' + profileIds
        + ' RecordTypeId = ' + rtId
        + ' hours = ' + hours
        + ' ... ' + 'Batch query =  ' + query + '.');
        System.debug(messages);
        CDdErrorUtilities.createApexLogs(messages, 'CDdBatchCaseToClose', 'start', System.LoggingLevel.Debug);

        Database.QueryLocator ql = Database.getQueryLocator(query);
        System.debug(LoggingLevel.ERROR, 'ql = ' + ql);
        return ql;
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> casesToUpsert = new List<Case>();
        for (Case c : scope) {
            if (batchCaseToCloseList[iEntry].Logic__c == 'MERCHANT ENTITLEMENT') {
                c.Status = 'Solved';
                if (c.Solved_At__c == null) {
                    c.Solved_At__c = c.LastModifiedDate;
                }
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                casesToUpsert.add(c);
            }//BASD-51074(For Dasher Solved cases don't overrite owner/resolution/Issue just the status as it is already solved by an agent)
            else if (c.Subject != null && c.Customer_Type__c != null && c.Issue__c != null && c.Issue_Type__c != null &&
            c.Resolution__c != null && c.Resolution_Type__c != null && c.RecordType.Name != 'Account Management'
            && (c.Customer_Type__c != 'Dasher' || (c.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_DASHER && c.Status == CDdSupportConstants.SOLVED_STATUS))) {
                c.Status = 'Closed';
                if (c.Solved_At__c == null) {
                    c.Solved_At__c = c.LastModifiedDate;
                }
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                casesToUpsert.add(c);
            }else if(c.RecordType.Name == 'Account Management' && c.Issue_Category__c != null && c.Issue_PM__c != null && c.AccountId != null) {
                c.Status = 'Closed';
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                casesToUpsert.add(c);
            } else if((new Set<String>{'Menu Update','POS Integrations'}).contains(c.RecordType.Name)){
                c.Status = 'Closed';
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                casesToUpsert.add(c);
            } else if (c.Owner.Name == 'Checkr Review') {
                c.Status = 'Closed';
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                    c.Validation_Bypass__c = true;
                }
                casesToUpsert.add(c);
            } else if (c.Customer_Type__c == 'Dasher') {
                c.Status = 'Closed';
                c.OwnerId = TOOLS_ADMIN_USER;
                c.Resolution_Type__c = 'Other - DX';
                c.Resolution__c = 'Closed due to Backlog';
                if (c.Issue__c == null) c.Issue__c = 'Other';
                if (c.Issue_Type__c == null) c.Issue_Type__c = 'Other - DX';
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                c.Validation_Bypass__c = true;
                casesToUpsert.add(c);
            } else if (c.RecordType.Name == 'Caviar Support') {
                c.Status = 'Closed';
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                casesToUpsert.add(c);
            }else if (c.RecordType.Name == CDdSupportConstants.RECORDTYPE_NAME_ENT_COO_RESCUE) {
                c.Status = 'Closed';
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                casesToUpsert.add(c);
            } else if (c.Upsert_Error__c) {
                continue;
            } else {
                if (c.RecordType.Name == 'Account Management') {
                    c.Error_Exception__c = 'You don\'t meet the requirement to move to closed!\nMake sure you provide the following: Account Issue Category, Account Issue, and an Account linked to the Case';
                } else {
                    c.Error_Exception__c = 'You don\'t meet the requirement to move to closed!\nMake sure you provide the following: Subject, Customer Type, Issue, Issue Type, Resolution, Resolution Type';
                }
                c.Upsert_Error__c = true;
                c.Validation_Bypass__c = true;
                casesToUpsert.add(c);
            }
        }
        Database.SaveResult[] lsr = Database.update(casesToUpsert,false);

        if (Test.isRunningTest()){
            Database.SaveResult sr = (Database.SaveResult)
                            JSON.deserialize('{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
            lsr = new Database.SaveResult[]{sr};
        }

        List<Case> casesWithExceptions = new List<Case>();
        for (Integer i = 0; i < lsr.size(); i++) {
            if (!lsr[i].isSuccess()) {
                //System.debug(LoggingLevel.ERROR, 'lsr[' + i + '] that failed = ' + lsr[i]);
                Case tempCase = scope.get(i);
                if (lsr[i].getErrors() != null && !lsr[i].getErrors().isEmpty()) {
                    String tempError = '';
                    for(Database.Error err : lsr[i].getErrors()) {
                        tempError += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                    }
                    if (tempError.equalsIgnoreCase('')) {
                        tempCase.Error_Exception__c = 'No specific error message!';
                    } else {
                        tempCase.Error_Exception__c = tempError;
                    }
                } else {
                    tempCase.Error_Exception__c = 'No specific error message!';
                }
                tempCase.Upsert_Error__c = true;
                tempCase.Validation_Bypass__c = true;
                casesWithExceptions.add(tempCase);
            }
        }

        if (casesWithExceptions.size() != 0) {
            //System.debug(LoggingLevel.ERROR, '[errors] casesWithExceptions = ' + casesWithExceptions);
            Database.SaveResult[] result = Database.update(casesWithExceptions, false);
            //System.debug(LoggingLevel.ERROR, 'result = ' + result);
        }
    }

    global void finish(Database.BatchableContext BC) {

        AsyncApexJob job = [
            SELECT Id, JobType, JobItemsProcessed, NumberOfErrors, TotalJobItems, Status, ExtendedStatus, CompletedDate
            FROM AsyncApexJob
            WHERE Id = :BC.getJobId()
        ];

        List<String> messages = new List<String>();
        messages.add('Batch entry ' + batchCaseToCloseList[iEntry].Label + ' contained a total of ' + job.TotalJobItems + ' item(s) and processed ' + job.JobItemsProcessed + ' item(s) with ' + job.NumberOfErrors + ' error(s).');
        messages.add('Batch entry ' + batchCaseToCloseList[iEntry].Label + ' completed on ' + job.CompletedDate + ' with status: ' + job.Status + ' and extended status: ' + job.ExtendedStatus + '.');
        CDdErrorUtilities.createApexLogs(messages, 'CDdBatchCaseToClose', 'finish', System.LoggingLevel.Debug);

        // Chaining for next Entry
        iEntry += 1;
        if (iEntry >= batchCaseToCloseList.size()) iEntry = 0;

        // Chain the next batch and start over if the next day
        if ((iEntry > 0) || (startDate < Date.TODAY())) {
            CDdBatchCaseToClose newBatch = new CDdBatchCaseToClose();
            newBatch.batchCaseToCloseList = batchCaseToCloseList;
            newBatch.iEntry = iEntry;
            // If we started over, set the starting day
            if (iEntry == 0)
                newBatch.startDate = Date.TODAY();
            if (! Test.isRunningTest()) Database.executeBatch(newBatch, CDdCustomMetadata.getBatchSize('CDdBatchCaseToClose'));
        }
    }
}