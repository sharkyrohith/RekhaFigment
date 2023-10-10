/**
 * @author Raju Lakshman
 * @date October 2020
 * @description Test class for the MXP Supervisor report within the Grid Report Framework.
 */

@isTest
public class CDdMxpSupervisorReportHelperTest {
    /*****************************************************************************************************************************
    *
    * Public/Global Variables
    *
    *****************************************************************************************************************************/
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
    static {
        TEST_ROLE_ID = TDdUserFactory.getUserRole('COO');
    }

    /**
     * @description Prepare test data
     */
    @testSetup
    static void testSetup(){
        List<User> users = TDdUserFactory.createUsers(3);
        users[1].ManagerId = getTestRunUser().Id;
        insert users;
        users[0].ManagerId = users[2].Id;
        update users;
        System.runAs(getTestRunUser()) {

            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;

            List<Account> accounts = TDdAccountFactory.createAccounts('AccountName', 4);
            insert accounts;

            List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
            for (Account acc : accounts) {
                accTeamMembers.add(new AccountTeamMember(UserId = users[0].Id, AccountId = acc.Id, TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME));
                accTeamMembers.add(new AccountTeamMember(UserId = users[1].Id, AccountId = acc.Id, TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME));
            }
            insert accTeamMembers;

            List<Case> casesToInsert = new List<Case>();
            List<Case> cases1 = TDdCaseFactory.createCases(3, accounts[0].Id, null, recTypeId);
            for (Case cs : cases1) {
                cs.OwnerId = users[0].Id;
            }
            casesToInsert.addAll(cases1);
            List<Case> cases2 = TDdCaseFactory.createCases(3, accounts[1].Id, null, recTypeId);
            for (Case cs : cases2) {
                cs.OwnerId = users[1].Id;
                cs.New_Queue_Change__c = System.now();
            }
            casesToInsert.addAll(cases2);
            insert casesToInsert;
        }
    }

    /**
     * @description Prepare and return the test running user
     */
    private static User testRunUser = null;
    private static User getTestRunUser() {
        if (testRunUser == null) {
            for (User u : [SELECT Id, Name FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
                testRunUser = u;
            }
            if (testRunUser == null) {
                testRunUser = TDdUserFactory.createUsers(1, null, TEST_ROLE_ID, false)[0];
                testRunUser.Username = TEST_DD_RUN_USERNAME;
                insert testRunUser;
            }
        }
        return testRunUser;
    }

    @isTest
    public static void mxpSupervisorReportTest_1() {
        System.runAs(getTestRunUser()) {
            DD_Grid_Report_Master__mdt master = CDdGridReportCtrl.getReportDefinition('MXP_Supervisor_Report');
            system.assert(master != null,'MXP_Supervisor_Report Grid Report Master mdt not found');
            system.assert(master.DD_Grid_Report_Filters__r != null && !master.DD_Grid_Report_Filters__r.isEmpty(),'MXP_Supervisor_Report Grid Report Filters mdt not found');
            system.assert(master.DD_Grid_Report_Fields__r != null && !master.DD_Grid_Report_Fields__r.isEmpty(),'MXP_Supervisor_Report Grid Report Fields mdt not found');

            Map<String,CDdGridReportFilterWrapper> filterDefinitionMap = getDefaultFilterDefinition(master.DD_Grid_Report_Filters__r);

            CDdGridReportFilterWrapper myReportsFilter = filterDefinitionMap.get('MXP_Sup_Report_My_Reports_Cases');
            myReportsFilter.value = false;
            CDdGridReportFilterWrapper myReportsAccountFilter = filterDefinitionMap.get('MXP_Sup_Report_My_Reports_Accounts');
            myReportsAccountFilter.value = false;
            CDdGridReportFilterWrapper myReportsMXPSupervisorCasesFilter = filterDefinitionMap.get('MXP_Sup_Report_MXP_Supervisor_Reports');
            myReportsMXPSupervisorCasesFilter.value = true;

            CDdMultiSelectPicklistCtrl.InitWrapper supervisors = CDdMultiSelectPicklistCtrl.getSearchInfo('MXP_Sup_Report_Account_Team_Supervisor');
            system.assert(supervisors != null,'MXP Supervisors do not exist');
            system.assert(supervisors.lookupResults != null && !supervisors.lookupResults.isEmpty(),'MXP Supervisors do not exist');
            CDdGridReportFilterWrapper mxpSupervisorFilterValueFilter = filterDefinitionMap.get('MXP_Sup_Report_Supervisor_List');
            List<CDdMultiSelectPicklistWrapper> mxpSupervisorFilterValue = (List<CDdMultiSelectPicklistWrapper>)mxpSupervisorFilterValueFilter.value;
            for (CDdMultiSelectPicklistWrapper wrapper : supervisors.lookupResults) {
                if (wrapper.value != getTestRunUser().Id) {
                    mxpSupervisorFilterValue.add(wrapper);
                    break;
                }
            }

            CDdGridReportFilterWrapper mxpTeamAccountFilter = filterDefinitionMap.get('MXP_Sup_Report_Sups_Reports_Accounts');
            mxpTeamAccountFilter.value = false;

            CDdGridReportSortWrapper sortWrapper = new CDdGridReportSortWrapper();
            sortWrapper.sortedBy = 'CaseNumber';
            sortWrapper.sortDirection = 'asc';

            CDdGridReportHelper.CDdGridReportRecordIdWrapper result =
                CDdGridReportCtrl.getRecordIds(master.Apex_Class__c, JSON.serialize(filterDefinitionMap.values()), JSON.serialize(sortWrapper));
            system.assertEquals(3,result.recordIds.size(),'Case count mismatch');

            String records = CDdGridReportCtrl.getData(master.Apex_Class__c, result.recordIds);
        }
    }

    @isTest
    public static void mxpSupervisorReportTest_2() {
        System.runAs(getTestRunUser()) {
            DD_Grid_Report_Master__mdt master = CDdGridReportCtrl.getReportDefinition('MXP_Supervisor_Report');
            system.assert(master != null,'MXP_Supervisor_Report Grid Report Master mdt not found');
            system.assert(master.DD_Grid_Report_Filters__r != null && !master.DD_Grid_Report_Filters__r.isEmpty(),'MXP_Supervisor_Report Grid Report Filters mdt not found');
            system.assert(master.DD_Grid_Report_Fields__r != null && !master.DD_Grid_Report_Fields__r.isEmpty(),'MXP_Supervisor_Report Grid Report Fields mdt not found');

            Map<String,CDdGridReportFilterWrapper> filterDefinitionMap = getDefaultFilterDefinition(master.DD_Grid_Report_Filters__r);

            CDdGridReportFilterWrapper myReportsFilter = filterDefinitionMap.get('MXP_Sup_Report_My_Reports_Cases');
            myReportsFilter.value = true;
            CDdGridReportFilterWrapper myReportsAccountFilter = filterDefinitionMap.get('MXP_Sup_Report_My_Reports_Accounts');
            myReportsAccountFilter.value = false;
            CDdMultiSelectPicklistCtrl.InitWrapper commonDates = CDdMultiSelectPicklistCtrl.getSearchInfo('MXP_User_Report_Last_Modified_Picklist');
            system.assert(commonDates != null, 'Case Last Modified Date Common Dates Picklist not found');
            system.assert(commonDates.lookupResults != null && !commonDates.lookupResults.isEmpty(), 'Case Last Modified Date Common Dates Picklist not found');
            CDdGridReportFilterWrapper commonDatesFilter = filterDefinitionMap.get('MXP_Sup_Report_NewQueueChangePklst');
            List<CDdMultiSelectPicklistWrapper> commonDatesFilterValue = (List<CDdMultiSelectPicklistWrapper>)commonDatesFilter.value;
            commonDatesFilterValue.add(commonDates.lookupResults[0]);

            CDdGridReportSortWrapper sortWrapper = new CDdGridReportSortWrapper();
            sortWrapper.sortedBy = 'LastModifiedDate';
            sortWrapper.sortDirection = 'desc';

            CDdGridReportHelper.CDdGridReportRecordIdWrapper result =
                CDdGridReportCtrl.getRecordIds(master.Apex_Class__c, JSON.serialize(filterDefinitionMap.values()), JSON.serialize(sortWrapper));
            system.assertEquals(3,result.recordIds.size(),'Case count mismatch');

            String records = CDdGridReportCtrl.getData(master.Apex_Class__c, result.recordIds);
        }
    }

    @isTest
    public static void mxpSupervisorReportTest_3() {
        System.runAs(getTestRunUser()) {
            DD_Grid_Report_Master__mdt master = CDdGridReportCtrl.getReportDefinition('MXP_Supervisor_Report');
            system.assert(master != null,'MXP_Supervisor_Report Grid Report Master mdt not found');
            system.assert(master.DD_Grid_Report_Filters__r != null && !master.DD_Grid_Report_Filters__r.isEmpty(),'MXP_Supervisor_Report Grid Report Filters mdt not found');
            system.assert(master.DD_Grid_Report_Fields__r != null && !master.DD_Grid_Report_Fields__r.isEmpty(),'MXP_Supervisor_Report Grid Report Fields mdt not found');

            Map<String,CDdGridReportFilterWrapper> filterDefinitionMap = getDefaultFilterDefinition(master.DD_Grid_Report_Filters__r);

            CDdGridReportFilterWrapper customDatesFilter = filterDefinitionMap.get('MXP_Sup_Report_New_Queue_Change');
            List<CDdDateFilterWrapper> customDatesFilterValue = (List<CDdDateFilterWrapper>)customDatesFilter.value;
            CDdDateFilterWrapper dateWrapper = new CDdDateFilterWrapper();
            dateWrapper.value = System.now().addDays(-3);
            dateWrapper.operator = '<=';

            CDdDateFilterWrapper dateWrapper2 = new CDdDateFilterWrapper();
            dateWrapper2.value = System.now();
            dateWrapper2.operator = '=';

            customDatesFilterValue.add(dateWrapper2);

            CDdGridReportFilterWrapper caseStatusFilter = filterDefinitionMap.get('MXP_Sup_Report_Case_Status');
            List<CDdMultiSelectPicklistWrapper> caseStatusFilterValue = (List<CDdMultiSelectPicklistWrapper>)caseStatusFilter.value;
            CDdMultiSelectPicklistWrapper statusWrapper = new CDdMultiSelectPicklistWrapper();
            statusWrapper.value = 'Closed';
            statusWrapper.operator = 'Does Not Equal';
            caseStatusFilterValue.add(statusWrapper);

            CDdGridReportSortWrapper sortWrapper = new CDdGridReportSortWrapper();

            CDdGridReportHelper.CDdGridReportRecordIdWrapper result =
                CDdGridReportCtrl.getRecordIds(master.Apex_Class__c, JSON.serialize(filterDefinitionMap.values()), JSON.serialize(sortWrapper));

            system.assertEquals(3, result.recordIds.size(), 'Case count mismatch');

            String records = CDdGridReportCtrl.getData(master.Apex_Class__c, result.recordIds);
        }
    }

    private static Map<String,CDdGridReportFilterWrapper> getDefaultFilterDefinition(List<DD_Grid_Report_Filter__mdt> filters) {
        Map<String,CDdGridReportFilterWrapper> filterDefinitionMap = new Map<String,CDdGridReportFilterWrapper>();
        for (DD_Grid_Report_Filter__mdt filter : filters) {
            CDdGridReportFilterWrapper filterDefinition = new CDdGridReportFilterWrapper();
            filterDefinition.name = filter.DeveloperName;
            filterDefinition.definition = filter;
            switch on filterDefinition.definition.Type__c {
                when  'MultiSelect Picklist' {
                    filterDefinition.value = new List<CDdMultiSelectPicklistWrapper>();
                }
                when 'Date','DateTime' {
                    filterDefinition.value = new List<CDdDateFilterWrapper>();
                }
                when 'Number','Percent' {
                    filterDefinition.value = new List<CDdNumberFilterWrapper>();
                }
                when 'Toggle' {
                    filterDefinition.value = filter.Toggle_Default__c;
                }
            }
            filterDefinitionMap.put(filter.DeveloperName,filterDefinition);
        }
        return filterDefinitionMap;
    }
}