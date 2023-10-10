/*******************************************************************************************
 * @Name         VCaseFeedItemNewExtension
 * @Author       Sahil
 * @Date         2021-03-02
 * @Group        Bizapps Support
 * @Description  Controller for Case Feed item VF page
 *******************************************************************************************/
/* MODIFICATION LOG
 * Version          Developer          Date               Description
 *-------------------------------------------------------------------------------------------
 *  1.0.1              Sahil              2021-03-02         Adding escalation queues
 *******************************************************************************************/
public without sharing class VCaseFeedItemNewExtension
{
    private List<SelectOption> templateSelectOptions;
    public Case caseRec {get;set;}
    public FeedItem fi {get;set;}
    public String selectedTemplateId {get;set;}
    public String errorMessage {get;set;}
    public Boolean hasError {get;set;}
    public Map<Id, String> idToTemplateNameMap {get; set;}
    public List<SelectOption> escQueueOptions {get; set;} //Escalation changes  Raj 2/20/21
    public String selectedEscQueueId {get; set;} //Escalation changes  Raj 2/20/21
    public List<SelectOption> transferQueueOptions {get; set;}
    public String selectedTransferQueueId {get; set;} //Escalation changes  Raj 2/20/21
    public Boolean hasEscQueues {get; set;}
    private static List<Site_Escalation_Config__c> cachedSiteEscConfigs;
    public Boolean isTransferSelected {get; set;}
    public Boolean isEscalateSelected {get; set;}
    public String selectedAction {get; set;}
    @TestVisible private static final String SITE_CONFIGS = 'local.DoorDash.siteEscConfigs';
    public Map<string,String> cacheKeySetMap = new Map<string,String>();
    // to get the current case status from db
    private static string case_status_db;
    // to check the Live Order MX
    public static final String ISSUE_CAT_LIVEORDER_MX = 'Live Order - MX';
    public static final String ISSUE_CAT_DRIVEORDER_MX = 'DoorDash Drive - MX';
    // Issue category requiring UUID
    //public static final String ISSUE_CAT_REQUIRE_UUID = 'CASE_ISSUE_CAT_REQUIRE_UUID';
    // Issue type requiring UUID
    public static final String ISSUE_TYPE_REQUIRE_UUID = 'CASE_ISSUE_TYPE_REQUIRE_UUID';
    //public static set<String> issueCATSet = getIssuesRequiringUUID('CAT');
    public static set<String> issueTYPESet = getIssuesRequiringUUID();
    public static final set<String> SET_CLOSED_CASE_STATUS = new set<String>{CDdSupportConstants.SOLVED_STATUS,CDdSupportConstants.CLOSED_STATUS};


    public VCaseFeedItemNewExtension(ApexPages.StandardController controller)
    {
        List<String> fields = new List<String> { 'Case_Notes_Initial_Count__c', 'Case_Notes_Count__c', 'CaseNotesCommentCount__c','TotalCommentCount__c'};
        isTransferSelected = true;
        isEscalateSelected = false;
        hasEscQueues = false;
        // Needed, as test class does not allow addFields
        if (!Test.isRunningTest()) {
            controller.addFields(fields);
        }
        caseRec = (Case)controller.getRecord();
        idToTemplateNameMap = new Map<Id, String>();
        getTemplateOptions();

        escQueueOptions = getEscQueueOptions();
        transferQueueOptions = getTransferQueueOptions();

        if (escQueueOptions.size() > 1 || transferQueueOptions.size() > 1) {
            hasEscQueues = true;
        } else {
            hasEscQueues = false;
        }
        reset();
    }

    /**************************************************************************************
    * @Description  get site escalation queues
    * @Param
    * @Return    List of escalation queues as select options
    * @Example
    **************************************************************************************/
    public List<SelectOption> getEscQueueOptions() {
        if (escQueueOptions == null) {
            escQueueOptions = new List<SelectOption>();
            escQueueOptions.add(new SelectOption('', '--None--'));
            if((UserInfo.getUserRoleId()) != null) {
                cacheKeySetMap.put(SITE_CONFIGS +String.valueOf(UserInfo.getUserRoleId()),String.valueof(UserInfo.getUserRoleId()));
                cachedSiteEscConfigs = CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(
                    UserInfo.getUserRoleId(), cacheKeySetMap
                );
            }
            if (cachedSiteEscConfigs != null) {
                for (Site_Escalation_Config__c se : cachedSiteEscConfigs) {
                    if (se.IsEscalation__c == true) {
                        escQueueOptions.add(
                        new SelectOption(se.Queue_ID__c, se.Queue_Label__c)
                        );
                    }
                }
            }
        }
        return escQueueOptions;
    }

    /**************************************************************************************
    * @Description  get site escalation queues
    * @Param
    * @Return    List of transfer queues as select options
    * @Example
    **************************************************************************************/
    public List<SelectOption> getTransferQueueOptions() {
        if (transferQueueOptions == null) {
            transferQueueOptions = new List<SelectOption>();
            transferQueueOptions.add(new SelectOption('', '--None--'));

            if((UserInfo.getUserRoleId()) != null) {
            cacheKeySetMap.put(SITE_CONFIGS +String.valueOf(UserInfo.getUserRoleId()),String.valueof(UserInfo.getUserRoleId()));
            cachedSiteEscConfigs = CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(
                UserInfo.getUserRoleId(), cacheKeySetMap
            );
            }

            if (cachedSiteEscConfigs != null) {
                for (Site_Escalation_Config__c se : cachedSiteEscConfigs) {
                    if (se.IsTransfer__c == true) {
                        transferQueueOptions.add(
                        new SelectOption(se.Queue_ID__c, se.Queue_Label__c)
                        );
                    }
                }
            }
        }
        return transferQueueOptions;
    }

    /**************************************************************************************
    * @Description  get default panel for escalate or transfer options
    * @Param
    * @Return    List of default escalate transfer options
    * @Example
    **************************************************************************************/
    public List<SelectOption> getEscOrTransfer() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Transfer', 'Transfer'));
        options.add(new SelectOption('Escalate', 'Escalate'));
        return options;
    }


    public List<SelectOption> getTemplateOptions() {
        if(templateSelectOptions == null) {
            // System.debug('#### templateSelectOptions: '+templateSelectOptions);

            templateSelectOptions = new List<SelectOption>();
            templateSelectOptions.add(new SelectOption('', '-- Select a template --'));

            List<Chatter_Post_Notes_Template__c> cpnt = getChatterPostNotesTemplateForSelect();

            for(Chatter_Post_Notes_Template__c t : cpnt) {
                templateSelectOptions.add(new SelectOption(t.Id, t.Name));
                idToTemplateNameMap.put(t.Id, t.Name);
            }
        }

        return templateSelectOptions;
    }

    private List<Chatter_Post_Notes_Template__c> getChatterPostNotesTemplateForSelect() {
        List<Chatter_Post_Notes_Template__c> cpnt = ChatterPostNotesTemplateCache.loadCPNT();
        return cpnt;
    }

    public PageReference postFeed()
    {
        // BASD-30265 and BASD-24895 Start
        // Require UUID for LiveOrders
        // Check Case status so that Tx will not change Solved cases to open
        // set the error false
        hasError = false;
        // get current status from db - temp code- need a way to cache this and avoid SOQL
            if(String.isBlank(case_status_db) && caseRec.Id!=null){
                case_status_db = [Select id,status from Case where Id = : caseRec.Id].Status;
            }

        // only for merchant we need to get the status of the case from Db to verify -BASD-24895
        //if((String.isnotBlank(caseRec.Customer_type__c) && caseRec.Customer_type__c.equalsIgnorecase(CDdSupportConstants.CUSTOMER_TYPE_MERCHANT))){
            // if Case old status is either Solved or Closed and if new status is New or Open then error
            if (    (String.isNotBlank(case_status_db)
                        && (case_status_db.equalsIgnoreCase(CDdSupportConstants.SOLVED_STATUS) || case_status_db.equalsIgnoreCase(CDdSupportConstants.CLOSED_STATUS)))
                        && (String.isNotBlank(caserec.Status)
                            && (caseRec.Status==CDdSupportConstants.OPEN_STATUS||caseRec.status==CDdSupportConstants.NEW_STATUS)
                            )
                ){
                    // read from label
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.Case_Notes_Updates_MX_Solved ));
                    hasError=true;
                    return null;
            }
        //}
        String issueVal = getLowercaseNoSpaceString(caseRec.issue__c);
        // if Issue type is Live Order-MX and Case status is Solved or Closed, ensure UUID is filled -BASD-30265
        // if the issue type is Drive-MX, should be part of list of values in the set
        // lower case value
        String issueType = caseRec.Issue_Type__c;
        if((ISSUE_CAT_LIVEORDER_MX.equalsIgnoreCase(issueType) ||
            (ISSUE_CAT_DRIVEORDER_MX.equalsIgnoreCase(issueType) && issueTYPESet.contains(issueVal)))
            && (SET_CLOSED_CASE_STATUS.contains(caseRec.Status))
            && String.isBlank(caseRec.DeliveryUUID__c)
            ){
                //String errMsg = String.format('For Issue Category/Issue :<b> {0} / {1} </b>- Delivery UUID is required', new List<Object> { caseRec.Issue_Type__c,caseRec.Issue__c });
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errMsg));
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.Case_Notes_Require_Delv_for_LiveOrder));
                hasError=true;
                return null;
        }
        // BASD-30265 and BASD-24895 End
        //Savepoint sp = Database.setSavepoint();
        try {
            // Though the <br> tag isn’t supported, you can use <p>&nbsp;</p> to create lines.
            // https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_feeditem.htm
            fi.Body = fi.Body.Replace('<br>', '<p>&nbsp;</p>');
            fi.Body = fi.Body.Replace('<br/>', '<p>&nbsp;</p>');
            fi.Body = fi.Body.Replace('<br />', '<p>&nbsp;</p>');
            fi.Body = fi.Body.Replace('<strong>', '<b>');
            fi.Body = fi.Body.Replace('</strong>', '</b>');
            fi.Body = fi.Body.Replace('<em>', '<i>');
            fi.Body = fi.Body.Replace('</em>', '</i>');

            String bodyWithoutSpaces = fi.Body.replaceAll('\\s+',CDdCoreConstants.BLANK_STRING) // Remove spaces
                .replaceAll('<[/a-zAZ0-9]*>',CDdCoreConstants.BLANK_STRING) // Remove html tags
                .replaceAll('&nbsp;',CDdCoreConstants.BLANK_STRING); // Remove &nbsp;

            if(caseRec.Case_Notes_Initial_Count__c ==null){
                caseRec.Case_Notes_Initial_Count__c = bodyWithoutSpaces.length();
                caseRec.Case_Notes_Count__c = 1;
                caseRec.CaseNotesCommentCount__c = bodyWithoutSpaces.length();
            }else{
                caseRec.Case_Notes_Count__c =  (caseRec.Case_Notes_Count__c + 1);
                caseRec.CaseNotesCommentCount__c = (caseRec.CaseNotesCommentCount__c + bodyWithoutSpaces.length());
            }

            caseRec.CaseNoteTemplate__c = idToTemplateNameMap.get(selectedTemplateId);
            if (caseRec.TotalCommentCount__c == null || caseRec.TotalCommentCount__c == 0) {
                caseRec.TotalCommentCount__c = 1;
            } else {
                caseRec.TotalCommentCount__c ++;
            }
            caseRec.Last_Internal_Comment__c = DateTime.now();
            VFeedItemTriggerHandler.doNotUpdateCases = true;
            insert fi;

            if (String.isNotBlank(selectedEscQueueId) && selectedAction == 'Escalate') {
                caseRec.IsEscalated = true;
                caseRec.OwnerId = selectedEscQueueId;
              } else if (String.isNotBlank(selectedTransferQueueId) && selectedAction == 'Transfer') {
                caseRec.OwnerId = selectedTransferQueueId;
              }
            update caseRec;
            //show message on the page
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Case Updated Successfully'));
            //refresh page after updating the case
            PageReference tempPage = ApexPages.currentPage();
            tempPage.setRedirect(true);
            this.reset();
            return tempPage;
        } catch(DmlException de) {
            hasError = true;
            errorMessage = de.getMessage();
        }

        return null;
    }

    public PageReference loadTemplate()
    {
        loadTemplateBody();
        return null;
    }

    private void reset()
    {
        hasError = false;
        errorMessage = '';
        selectedTemplateId = '';

        fi = new FeedItem();
        fi.ParentId = caseRec.id;
        fi.IsRichText = true;
    }

    private void loadTemplateBody() {
        String feedBody = getFeedBody(selectedTemplateId);
        if (!String.isBlank(feedBody)) {
            fi.Body = feedBody;
        }
    }

    /**
    * @description Handles retrieve of Chatter Post Notes Template from either
    * cache or db.
    * @author Jose Vega | 05-03-2022
    * @param Id selectedChatterPostNotesTemplate
    * @return String
    **/
    private String getFeedBody(Id selectedChatterPostNotesTemplateId) {
        String feedBody;
        feedBody = ChatterPostNotesTemplateCache.getChatterPostNotesTemplateBody(String.valueOf(selectedChatterPostNotesTemplateId));
        if (String.isBlank(feedBody)) {
            List<Chatter_Post_Notes_Template__c> templateList = [
                SELECT Id, Body__c
                FROM Chatter_Post_Notes_Template__c
                WHERE Id = :selectedChatterPostNotesTemplateId LIMIT 1
            ];

            if (!templateList.isEmpty()) {
                feedBody = templateList[0].Body__c;
                ChatterPostNotesTemplateCache.setChatterPostNotesTemplateBody(templateList[0].Id, feedBody);
            }
        }
        return feedBody;
    }

    /**************************************************************************************
    * @Description  render escalate or transfer panel
    * @Param
    * @Return
    * @Example
    **************************************************************************************/
    public PageReference renderEscOrTfrPanel() {
        if (selectedAction == 'Transfer') {
            isTransferSelected = true;
            isEscalateSelected = false;
        } else if (selectedAction == 'Escalate') {
            isEscalateSelected = true;
            isTransferSelected = false;
        }
        return null;
    }

    /**************************************************************************************
    * @Description - Get the Issues requiring UUID
    * @Param - Return set
    * @Return
    * @Example
    **************************************************************************************/
    public static Set<String> getIssuesRequiringUUID(){
        Set<String> rtnSet = new Set<String>();
        String cacheKey = SITE_CONFIGS+'UUID';
        try {
            // get from Cache rather than service class - performance
            // have to get from service class as this value can be more than 255 chars
            // getinstance only returns 255 chars
            rtnSet = (Set<String>)CDdCacheService.getFromOrgCache(cacheKey);
            if(rtnSet==null || rtnSet.isEmpty()){
                rtnSet=new set<String>();
                String configVal = CDdNameValuePairHelper.getLongTextValue(ISSUE_TYPE_REQUIRE_UUID);
                // split and form a set
                if(String.isNotBlank(configVal)){
                    // split the string into a set
                    rtnSet.addAll(getLowercaseNoSpaceString(configVal).split(CDdCoreConstants.DELIMITER_COMMA));
                }
                // put in Cache- valid for next 6 hours?
                CDdCacheService.putInOrgCache(cacheKey, rtnSet,21600);
            }
        } catch (Exception ex) {
            // do nothing...?
        }
        // default return
        return rtnSet;
    }
    // given a string retunr lowercase and remove white space
    // needed to compare in set
    public static String getLowercaseNoSpaceString(String inStr){
        if(String.isnotBlank(inStr)){
            inStr = inStr.tolowerCase().replaceAll('(\\s+)', '');
            return inStr;
        }else{
            return '';
        }
    }
}