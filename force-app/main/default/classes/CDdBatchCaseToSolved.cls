/**
 * @description       :
 * @author            : Jose Vega
 * @group             :
 * @last modified on  : 01-12-2023
 * @last modified by  : Jose Vega
**/
public class CDdBatchCaseToSolved implements Database.Batchable<sObject> {
    public Boolean forceErrorForTestClass = false;
    public CDdBatchCaseToSolved() {}
    public CDdBatchCaseToSolved(Boolean forceErrorForTestClass) {
        this.forceErrorForTestClass = forceErrorForTestClass;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        final Integer DAYS_TO_WAIT = 3;

        List<Agent_Setting__c> agentSettings = [SELECT Id, Is_Agent__c, Name, Profile_Name__c, SetupOwnerId, SetupOwner.Name
                                                    FROM Agent_Setting__c
                                                    WHERE Is_Agent__c = TRUE];

        Set<String> agentProfileNames = new Set<String>();
        for(Agent_Setting__c agentSetting : agentSettings) {
            if(!String.isblank(agentSetting.Profile_Name__c)) {
                agentProfileNames.add(agentsetting.Profile_Name__c);
            }
        }

        Set<String> profilesToCheck = new Set<String>();
        profilesToCheck.add('Agent');
        profilesToCheck.add('System Administrator');
        profilesToCheck.add('BizApps Team');
        profilesToCheck.add('Vendor Team');
        profilesToCheck.addAll(agentProfileNames);

        Set<String> recordTypesToCheck = new Set<String>();
        recordTypesToCheck.add(CDdSupportConstants.RECORDTYPE_NAME_API);
        recordTypesToCheck.add(CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        recordTypesToCheck.add(CDdSupportConstants.RECORDTYPE_NAME_PROACTIVE_OUTREACH);
        String query =  'SELECT ' +
                        'Id, Status, Subject, Customer_Type__c, Issue__c, ' +
                        'Issue_Type__c, Pending_At__c, Resolution__c, Resolution_Type__c, ' +
                        'Upsert_Error__c, LastModifiedDate, Error_Exception__c ' +
                        'FROM Case ' +
                        'WHERE ((Pending_At__c < LAST_N_DAYS:' + DAYS_TO_WAIT + ' ' +
                        'OR (Pending_At__c = NULL AND LastModifiedDate < LAST_N_DAYS:' + DAYS_TO_WAIT + ')) ' +
                        'AND Case_Detail__c = NULL ' +
                        'AND Status = \'Pending\') ' +
                        'AND Case_Owner_Profile__c IN: profilesToCheck ' +
                        'AND RecordType.Name IN :recordTypesToCheck ' +
                        'AND Priority <> \'Urgent\'';
        System.debug('Query = ' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> casesToUpsert = new List<Case>();
        for (Case c : scope) {
            if (c.Subject != null && c.Customer_Type__c != null && c.Issue__c != null && c.Issue_Type__c != null && c.Resolution__c != null && c.Resolution_Type__c != null) {
                c.Status = 'Solved';
                if (c.Pending_At__c == null) {
                    c.Pending_At__c = c.LastModifiedDate;
                }
                if (c.Upsert_Error__c) {
                    c.Upsert_Error__c = false;
                    c.Error_Exception__c = '';
                }
                casesToUpsert.add(c);
            } else if (c.Upsert_Error__c) {
                continue;
            } else {
                c.Error_Exception__c = 'You don\'t meet the requirement to move to solved!\nMake sure you provide the following: Subject, Customer Type, Issue, Issue Type, Resolution, Resolution Type';
                c.Upsert_Error__c = true;
                c.Validation_Bypass__c = true;
                casesToUpsert.add(c);
            }
        }

        Database.SaveResult[] lsr = Database.update(casesToUpsert,false);
        if (Test.isRunningTest() && this.forceErrorForTestClass){
            Database.SaveResult sr = (Database.SaveResult)
                JSON.deserialize('{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
            lsr = new Database.SaveResult[]{sr};
        }
        List<Case> casesWithExceptions = new List<Case>();
        for (Integer i = 0; i < lsr.size(); i++) {
            if (!lsr[i].isSuccess()) {
                //System.debug(LoggingLevel.ERROR, 'lsr[' + i + '] that failed = ' + lsr[i]);
                Case tempCase = new Case(Id=scope.get(i).Id);
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

    public void finish(Database.BatchableContext BC) {
        //[JN-NOTE] We don't need this for now
    }
}