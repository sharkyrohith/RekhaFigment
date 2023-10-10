/**
 * @author   Raju Lakshman
 * @date  Sept 2021
 * @decription Data provider for the 'MXP User Report' in the Grid Report Framework
 *             This class implements the CDdGridReportInterface to provide the data back the UI
 */
public without sharing class CDdMxpUserReportHelper implements CDdGridReportInterface {

    // Used for sorting, when UI sends the field in the Sort Wrapper, we need the actual field API name to sort by.
    private static final Map<String,String> sortFieldMap = new Map<String,String> {
        'Id' => 'Id',
        'CaseNumber' => 'CaseNumber',
        'CaseURL' => 'CaseNumber',
        'AccountName' => 'Account.Name',
        'AccountURL' => 'Account.Name',
        'AccountBusinessId' => 'Account.Business_ID__c',
        'AccountStoreId' => 'Account.Restaurant_ID__c',
        'AccountOwner' => 'Account.Owner.Name',
        'CreatedDate' => 'CreatedDate',
        'LastModifiedDate' => 'LastModifiedDate',
        'Status' => 'Status',
        'Subject' => 'Subject',
        'Owner' => 'Owner.Name',
        'RecordType' => 'RecordType.Name'
    };

    private static String MXP_DELIMITER = CDdCoreConstants.DELIMITER_COMMA + CDdCoreConstants.DELIMITER_SPACE;

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription  Gets upto 50K case records which match the query
     * @param   String filterConfig - JSON of filters
     * @param   CDdGridReportSortWrapper sortConfig - Sort Field and Sort Direction
     * @return  List<Id> Wrapper of list of Ids the UI can store and use lazy loading to render
     */
    public CDdGridReportHelper.CDdGridReportRecordIdWrapper getRecordIds(List<CDdGridReportFilterWrapper> filterList, CDdGridReportSortWrapper sortConfig) {

        String query = CDdCoreConstants.BLANK_STRING;

        Set<String> mxpTeamMemberIds = new Set<String>();
        Boolean viewMyCases = false;
        Boolean viewMyAccounts = false;
        Boolean viewMxpTeamAccounts = false;
        String caseStatusQuery = CDdCoreConstants.BLANK_STRING;
        Boolean viewAllCaseStatuses = false;
        Boolean viewAllMxpQueueCases = false;
        String commonDateRangeQuery;
        Id mxpQueueId = CDdAccountTeamMemberUtilities.getMxpQueueId();

        // Go thru the filters to form the query where clause.
        for (CDdGridReportFilterWrapper filter : filterList) {
            String queryComponent = CDdCoreConstants.BLANK_STRING;
            String fieldApiNames = filter.definition.Query_Field_API_Names__c;
            switch on filter.definition.Type__c  {
                when 'MultiSelect Picklist'{
                    List<Object> values = (List<Object>)filter.value;
                    switch on filter.Name {
                        when 'MXP_User_Report_Team_Member' {
                            // This does not have a direct field in Case object to query. We will collect the ids in a set to add the query later
                            String ownerIdClause = CDdGridReportHelper.getMultiSelectPicklistQuery(fieldApiNames,values,filter.definition.MultiSelect_Query_Operator__c);
                            if (String.isNotBlank(ownerIdClause)) {
                                ownerIdClause = ownerIdClause.subStringAfterLast('(').subStringBefore(')').replaceAll('\'','');
                                mxpTeamMemberIds.addAll(ownerIdClause.split('\\,'));
                            }
                        } when 'MXP_User_Report_LastModifiedDatePcklst' {
                            // The formation of the query for this param is custom, the value on the wrapper will have the last modified date dynamic query (LAST_N_DAYS, etc)
                            if (values != null && !values.isEmpty()) {
                                List<CDdMultiSelectPicklistWrapper> wL = (List<CDdMultiSelectPicklistWrapper>)JSON.deserialize(
                                    JSON.serialize(values), List<CDdMultiSelectPicklistWrapper>.class);
                                commonDateRangeQuery = wL[0].value;
                            }
                        } when else {
                            // Get the query component
                            queryComponent = CDdGridReportHelper.getMultiSelectPicklistQuery(fieldApiNames,values,filter.definition.MultiSelect_Query_Operator__c);
                            // Later on, if user has not provided case statuses, we will add a Status != Closed filter
                            if (filter.Name == 'MXP_User_Report_Case_Status' && String.isNotBlank(queryComponent)) {
                                caseStatusQuery = queryComponent;
                                queryComponent = null;
                            }
                        }
                    }
                }
                when 'Number','Percent' {
                    List<Object> values = (List<Object>)filter.value;
                    queryComponent = CDdGridReportHelper.getNumberFilterQuery(fieldApiNames,values);
                }
                when 'Date' {
                    List<Object> values = (List<Object>)filter.value;
                    queryComponent = CDdGridReportHelper.getDateFilterQuery('Date',fieldApiNames,values);
                }
                when 'DateTime' {
                    List<Object> values = (List<Object>)filter.value;
                    queryComponent = CDdGridReportHelper.getDateFilterQuery('DateTime',fieldApiNames,values);
                }
                when 'Toggle' {
                    Object value = (Object)filter.value;
                    switch on filter.Name {
                        when 'MXP_User_Report_Show_Queue' {
                            // Get the MXP Queue Id to add in ownerId query if toggle selected in UI
                            if (value != null && (Boolean)value) {
                                viewAllMxpQueueCases = true;
                            }
                        }
                        when 'MXP_User_Report_My_View' {
                            if (value != null && (Boolean)value) {
                                viewMyCases = true;
                            }
                        }
                        when 'MXP_User_Report_My_Acccount' {
                            if (value != null && (Boolean)value) {
                                viewMyAccounts = true;
                            }
                        }
                        when 'MXP_User_Report_MXP_Team_Member_Account' {
                            if (value != null && (Boolean)value) {
                                viewMxpTeamAccounts = true;
                            }
                        }
                        when 'MXP_User_Report_Case_Status_Common' {
                            if (value != null && (Boolean)value) {
                                viewAllCaseStatuses = true;
                            }
                        }
                        when else {
                            queryComponent = CDdGridReportHelper.getToggleQuery(filter.definition.Query_Field_API_Names__c,value);
                        }
                    }
                }
            }
            if (String.isNotBlank(queryComponent))
                query += queryComponent;
        }

        String closedStatus = CDdSupportConstants.CLOSED_STATUS;
        Set<string> defaultStatuses = CDdSupportConstants.MXP_CASE_REPORT_DEFAULT_CASE_STATUS;

        if (String.isBlank(caseStatusQuery)) {
            caseStatusQuery = viewAllCaseStatuses ?
                ' Status != :closedStatus ' + CDdGridReportHelper.QUERY_AND :
                ' Status IN :defaultStatuses ' + CDdGridReportHelper.QUERY_AND;
        }

        commonDateRangeQuery = String.isBlank(commonDateRangeQuery) ?
            CDdCoreConstants.BLANK_STRING :
            CDdGridReportHelper.OPEN_PARENTHESIS + commonDateRangeQuery + CDdGridReportHelper.CLOSE_PARENTHESIS + CDdGridReportHelper.QUERY_AND;

        Set<Id> mxpQueueCaseIds = new Set<Id>();
        if (viewMyAccounts || (!mxpTeamMemberIds.isEmpty() && viewMxpTeamAccounts)) {
            if (mxpQueueId != null) {
                List<Case> mxpQueueCases = Database.query(
                    'SELECT Id,AccountId FROM Case ' +
                    ' WHERE ' + caseStatusQuery + commonDateRangeQuery + ' AccountId != null AND OwnerId = :mxpQueueId'
                );
                if (!mxpQueueCases.isEmpty()) {
                    Map<Id,List<Id>> accountToCaseMap = new Map<Id,List<Id>>();
                    for (Case cse : mxpQueueCases) {
                        if (!accountToCaseMap.containsKey(cse.AccountId)) {
                            accountToCaseMap.put(cse.AccountId,new List<Id>());
                        }
                        accountToCaseMap.get(cse.AccountId).add(cse.Id);
                    }
                    if (!accountToCaseMap.isEmpty()) {
                        for (AccountTeamMember atm :
                            [SELECT Id,UserId,AccountId
                               FROM AccountTeamMember
                              WHERE TeamMemberRole = :CDdSupportConstants.MXP_ROLE_NAME
                                AND User.Isactive = true
                                AND AccountId IN :accountToCaseMap.keySet()]) {
                            if ((viewMyAccounts && atm.UserId == UserInfo.getUserId()) || mxpTeamMemberIds.contains(atm.UserId)) {
                                mxpQueueCaseIds.addAll(accountToCaseMap.get(atm.AccountId));
                            }
                        }
                    }
                }
            }
        }

        Set<String> ownerIds = new Set<String>();
        if (viewMyCases) {
            ownerIds.add(UserInfo.getUserId());
        }
        if (!mxpTeamMemberIds.isEmpty()) {
            ownerIds.addAll(mxpTeamMemberIds);
        }
        if (viewAllMxpQueueCases && mxpQueueId != null) {
            ownerIds.add(mxpQueueId);
        }

        String ownerDefaultQuery = ' OwnerId = \'' + UserInfo.getUserId() + '\'';
        String ownerQuery =
            (!ownerIds.isEmpty() ? ' ( OwnerId IN :ownerIds ) ' + CDdGridReportHelper.QUERY_OR  : CDdCoreConstants.BLANK_STRING ) +
            (!mxpQueueCaseIds.isEmpty() ? ' (Id IN :mxpQueueCaseIds) ' + CDdGridReportHelper.QUERY_OR : CDdCoreConstants.BLANK_STRING);

        ownerQuery = CDdGridReportHelper.OPEN_PARENTHESIS +
            (String.isNotBlank(ownerQuery) ? ownerQuery.removeEnd(CDdGridReportHelper.QUERY_OR) : ownerDefaultQuery) +
            CDdGridReportHelper.CLOSE_PARENTHESIS + CDdGridReportHelper.QUERY_AND;

        query = (ownerQuery + caseStatusQuery + commonDateRangeQuery + query).removeEnd(CDdGridReportHelper.QUERY_AND);

        String orderBy = CDdCoreConstants.BLANK_STRING;
        if (sortConfig != null && String.isNotBlank(sortConfig.sortedBy) && sortFieldMap.containsKey(sortConfig.sortedBy)) {
            orderBy = CDdGridReportHelper.QUERY_ORDER_BY + sortFieldMap.get(sortConfig.sortedBy) + CDdCoreConstants.DELIMITER_SPACE +
                (String.isNotBlank(sortConfig.sortDirection) ? sortConfig.sortDirection : CDdGridReportHelper.ORDER_ASCENDING) +
                CDdCoreConstants.DELIMITER_SPACE;
        }
        Integer recordCount = Database.countQuery('SELECT count() FROM Case WHERE ' + query);

        Integer totalQueryLimit = Limits.getLimitQueryRows();
        Integer currentQueryLimit = Limits.getQueryRows();
        Integer queryLimit = totalQueryLimit - currentQueryLimit;

        // Forming final query
        query = 'SELECT Id FROM Case WHERE ' + query + orderBy + CDdGridReportHelper.QUERY_LIMIT + queryLimit;

        // Just send the Ids back to the UI
        List<Id> caseIds = new List<Id>();
        for (Case cse : Database.query(query)) {
            caseIds.add(cse.Id);
        }

        CDdGridReportHelper.CDdGridReportRecordIdWrapper wrapper = new CDdGridReportHelper.CDdGridReportRecordIdWrapper();
        wrapper.recordIds = caseIds;
        wrapper.count = recordCount;
        return wrapper;
    }


    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription  Gets the data for the record Ids
     * @param  List<Id> recordIds - List of ids for which data needs to be retrieved
     * @return String data - JSON form of the data to be returned
     */
    public String getData(List<Id> recordIds) {
        // Query and put in a map. REMEMBER - The data needs to be returned in the same order as the param recordIds.
        Map<Id,Case> caseMap = new Map<Id,Case>(
            [SELECT Id,
                    CaseNumber,
                    OwnerId,
                    Owner.Name,
                    AccountId,
                    Account.Name,
                    Account.Business_ID__c,
                    Account.Restaurant_ID__c,
                    Account.Owner.Name,
                    CreatedDate,
                    LastModifiedDate,
                    Status,
                    Subject,
                    RecordType.Name
                FROM Case
                WHERE Id IN :recordIds]);

        // Get Account MXP
        Map<Id,List<String>> accountIdToMxpUserMap = new Map<Id,List<String>>();
        for (Case cse : caseMap.values()) {
            if (cse.AccountId != null)
                accountIdToMxpUserMap.put(cse.AccountId,new List<String>());
        }
        if (!accountIdToMxpUserMap.isEmpty()) {
            for (AccountTeamMember atm :
                    [SELECT Id,User.Name,AccountId
                    FROM AccountTeamMember
                    WHERE TeamMemberRole = :CDdSupportConstants.MXP_ROLE_NAME
                        AND User.Isactive = true
                        AND AccountId IN :accountIdToMxpUserMap.keySet()]) {
                accountIdToMxpUserMap.get(atm.AccountId).add(atm.User.Name);
            }
        }

        // Using Map<String,Object> instead of an unnecessary wrapper.
        List<Map<String,Object>> caseData = new List<Map<String,Object>>();
        for (Id recordId : recordIds) { // Doing this will ensure sort order
            if (!caseMap.containsKey(recordId))
                continue;
            Case cse = caseMap.get(recordId);
            Map<String,Object> data = new Map<String,Object>{
                'Id' => cse.Id,
                'CaseNumber' => cse.CaseNumber,
                'CaseURL' => '/' + cse.Id,
                'AccountId' => cse.AccountId,
                'AccountName' => cse.Account.Name,
                'AccountURL' => '/' + cse.AccountId,
                'AccountBusinessId' => cse.Account.Business_ID__c,
                'AccountStoreId' => cse.Account.Restaurant_ID__c,
                'AccountOwner' => cse.Account.Owner.Name,
                'CreatedDate' => cse.CreatedDate,
                'LastModifiedDate' => cse.LastModifiedDate,
                'Status' => cse.Status,
                'Subject' => cse.Subject,
                'Owner' => cse.Owner.Name,
                'RecordType' => cse.RecordType.Name,
                'AccountMxp' => (cse.AccountId != null ? String.join(accountIdToMxpUserMap.get(cse.AccountId),MXP_DELIMITER) : CDdCoreConstants.DELIMITER_HYPHEN)
            };
            caseData.add(data);
        }

        return JSON.serialize(caseData);
    }
}