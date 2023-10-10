/**
 * @author Jeremy S. Johnson
 * @date November 2020
 *
 * @description BZAP-6164: Project Fuse: Onboarding Consolidation
 *
 * Implements an SObject-agnostic (mostly) Milestone__c child object for managing and measuring progress
 * toward completion of a parent object's goal.
 *
 * Originally implemented for Case, this class will create Milestone__c child records based on a
 * configurable template. As milestones are updated, operational metrics are collected and parent
 * Status and Stage are maintained until completion of all milestones.
 */
public virtual class CDdMilestone {
    private Boolean ranOnceInitialStage = false;
    private Boolean ranOncePopulateKPIs = false;
    private Boolean ranOnceUpdateParent = false;
    protected Boolean ranOnceSubclass = false;
    private Boolean ranOnceValidateAdPromo = false;
    private Boolean ranOnceCompleteAdPromo = false;
    public static Boolean allowCaseStatusUpdateInRescue = false;

    public static CDdSchemaUtils.MileStoneRT milestoneRT = new CDdSchemaUtils.MileStoneRT();

    // template maps keyed by parent object RecordTypeId
    protected final Map<Id, List<Milestone_Template__c>> defaultTemplates = new Map<Id, List<Milestone_Template__c>>();
    protected final Map<Id, List<Milestone_Template__c>> conditionalTemplates = new Map<Id, List<Milestone_Template__c>>();
    private final Long millisPerDay = 86400000;

    // Milestone Statuses
    private final String Not_Started = 'Not Started';
    @TestVisible
    private final String In_Progress = 'In Progress';
    private final String Ready_for_QA = 'Ready for QA';
    private final String QA_Complete = 'QA Complete';
    private final String Escalated = 'Escalated';
    private final String Blocked = 'Blocked';
    private final String InRescue = 'In Rescue';
    private final String Review_And_Triage = 'Review & Triage';
    @TestVisible
    private final String Complete = 'Complete';
    private final String Photo_Linking = 'Photo Linking';//BASD-41146 - For Setup Milestone

    // Parent Statuses
    private final String Dead = 'Dead';
    private final String Open = 'Open';
    private final String Reopened = 'Reopened';

    //RecordType
    public static final Id CASE_MARKETPLACE_ONBOARDING_RT = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Case', 'Marketplace_Onboarding');
    public static final Id CASE_POS_INTEGRATIONS_RT = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Case', 'POS_Integrations');
    public static final Id ACCOUNT_GRAND_PARENT_RT = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Account', 'Grandparent_Account');
    private static final Id MILESTONE_GRAND_PORTAL_ACCESS = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Milestone__c', 'Grant_Portal_Access');
    private static final List<String> MILESTONE_TYPES_NZ = new List<String>{
        'Review & Triage',
        'Setup Store',
        'Setup Business'
    };
    private static final List<String> MILESTONE_TYPES_POS_PROVIDERS = new List<String>{
        'Review & Triage',
        'Setup Store',
        'Setup Business',
        'Grant Portal Access'
    };

    //POS Bulk Activation
    public static final Id CASE_POS_INTEGRATION_RT = CDdRecordTypeCase.posIntegrations();
    public static final String CASE_ORIGIN_BULK_TOOL_AUTOMATION = 'Bulk Tool Automation';
    public static final String CASE_ORIGIN_SSIO = 'Px Initiated POS Integration [SSIO]';
    public static final String MULESOFT_INTEGRATION_USER  = 'Mulesoft Integration User';
    public static final String CASE_STAGE_UNDER_REVIEW = 'Under Review';
    @TestVisible
    private static final List<String> POS_BULK_MILESTONE_TYPES_CLOSED = new List<String>{
        'Complete pre-work',
        'Configure POS'
    };

    public static final String QUEUE_HIBERNATED_POS_PROVIDERS = 'Hibernated POS Providers';
    public static final String QUEUE_SUSPENDED_POS_PROVIDERS = 'Suspended POS Providers';

    //Milestone Type
    private final String Setup_Menu = 'Setup Menu';//BASD-41146 - For Setup Milestone

    public class Context {
        public Map<Id, List<Milestone__c>> milestoneMap { get; set; }
        public Map<Id, List<Milestone__c>> openRequiredMap = new Map<Id, List<Milestone__c>>();
        public Map<Id, List<SObject>> candidateMap = new Map<Id, List<SObject>>();
        public Map<Id, Milestone__c> newMap { get; set; }
        public Map<Id, Milestone__c> oldMap { get; set; }
        public Map<Id, SObject> parentMap { get; set; }
        public Set<Id> parentIdFilter { get; set; }
        public Set<Id> parentIds { get; set; }
    }

    /**
     * Interface implemented by subclasses to allow CDdMilestone to call into the subclass for SObject-specific operations.
     */
    public interface MilestoneInterface {
        void updateParentStageAndStatus(Context ctx);
    }

    /**
     * BZAP-9259: Automate Case Stage Movement
     *
     * @param newMap Map containing new values
     * @param oldMap Map containing old values
     */
    public void setInitialStage(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        if (ranOnceInitialStage) {
            return;
        } else {
            ranOnceInitialStage = true;
        }

        Map<Id, SObject> filteredMap = filterParentsForInitialStage(newMap, oldMap);
        Map<Id, List<Milestone__c>> milestoneMap = CDdMilestoneSelector.milestonesForInitialStageByParentId(filteredMap.keySet());

        for (Id parentId : milestoneMap.keySet()) {
            for (Milestone__c milestone : milestoneMap.get(parentId)) {
                if (milestone.Completed_by_Stage__c != null && milestone.Stage_Completed_Sort_Order__c == 1) {
                    newMap.get(parentId).put('Stage__c', milestone.Completed_by_Stage__c);

                } else if (milestone.Reviewed_by_Stage__c != null && milestone.Stage_Reviewed_Sort_Order__c == 1) {
                    newMap.get(parentId).put('Stage__c', milestone.Reviewed_by_Stage__c);
                }
            }
        }
    }

    /**
     * BZAP-9259: Filter parents to update
     *
     * @param newMap Map containing new values
     * @param oldMap Map containing old values
     * @return filtered parents
    */
    @TestVisible
    private Map<Id, SObject> filterParentsForInitialStage(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        Map<Id, SObject> filteredMap = new Map<Id, SObject>();
        for (SObject newObj : newMap.values()) {
            SObject oldObj = oldMap.get((Id) newObj.get('Id'));
            String ownerIdNew = (String) newObj.get('OwnerId');
            String ownerIdOld = (String) oldObj.get('OwnerId');
            String recordTypeId = (String) newObj.get('RecordTypeId');
            String stage = (String) newObj.get('Stage__c');
            String sobjType = CDdSchemaUtils.getSObjectTypeNameFromRecordId((Id) newObj.get('Id'));

            Boolean isRightOwner = ownerIdNew != null && ownerIdOld != null && ownerIdNew.startsWith('005') && ownerIdOld.startsWith('00G');
            Boolean isRightRecordType = CDdMilestoneSelector.settingsRecordTypeIds(sobjType).contains(recordTypeId);
            Boolean isRightStage = stage == Not_Started;

            if (isRightOwner && isRightRecordType && isRightStage) {
                filteredMap.put((Id) newObj.get('Id'), newObj);
            }
        }
        return filteredMap;
    }

    /**
     * BZAP-9184: Populate milestone KPIs
     *
     * Update KPIs on milestones when conditions are met
     *
     * @param newMap The new milestones to evaluate
     * @param oldMap The old milestones to evaluate
     * BASD-41146: Populate Last Photo Linking Timestamp
    */
    public void populateKPIs(Map<Id, Milestone__c> newMap, Map<Id, Milestone__c> oldMap) {

        if (ranOncePopulateKPIs) {
            return;
        } else {
            ranOncePopulateKPIs = true;
        }

        DateTime now = System.now();
        Id userId = UserInfo.getUserId();

        for (Milestone__c m : newMap.values()) {
            Id id = m.Id;
            Id ownerId = m.OwnerId;
            String statusNew = m.Status__c;
            String statusOld = oldMap.get(id).Status__c;
            Boolean isOwnerChange = ownerId == oldMap.get(id).OwnerId ? false : true;
            Boolean isStatusChanged = statusNew != statusOld;
            Boolean isUserOwner = userId == ownerId ? true : false;


            if (isStatusChanged && statusNew != Not_Started && m.Start_Date_Time__c == null) {
                m.Start_Date_Time__c = now;
                m.Initial_Owner__c = userId;
            }

            if (isStatusChanged && statusNew == Complete && m.Completed_Date_Time__c == null) {
                m.Completed_Date_Time__c = now;
            }

            if (statusNew != Not_Started && !isUserOwner && !isOwnerChange) {
                m.OwnerId = userId;
            }

            if (isStatusChanged && statusNew == Ready_for_QA && m.Initial_Preparation_Date_Time__c == null) {
                m.Initial_Preparation_Date_Time__c = now;
                m.Prepared_By__c = userId;
            }

            if (isStatusChanged && (statusNew == QA_Complete || (statusOld == Ready_for_QA && (statusNew == Escalated || statusNew == Complete)))) {
                m.Last_QA_Date_Time__c = now;
                m.Last_QAed_By__c = userId;
            }

            if (statusNew == Blocked && isStatusChanged) {
                m.Last_Blocked_Date_Time__c = now;
                m.Historical_Delay_Reasons__c = collectStatusReasons(m.Status_Reason__c, m.Historical_Delay_Reasons__c);
            }

            if (isStatusChanged && statusOld == Blocked && statusNew != Blocked && statusNew != null) {
                Long lastBlocked = m.Last_Blocked_Date_Time__c == null ? 0 : m.Last_Blocked_Date_Time__c.getTime();
                Long timeSpent = m.Time_Spent_in_Blocked_Days__c == null ? 0 : (Long) (m.Time_Spent_in_Blocked_Days__c * millisPerDay);
                Long diff = now.getTime() - lastBlocked + timeSpent;
                m.Time_Spent_in_Blocked_Days__c = (Decimal.valueOf(diff))/millisPerDay;
                m.Status_Reason_Details__c = '';
            }

            if (statusNew == Escalated && isStatusChanged) {
                m.Last_Escalation_Date_Time__c = now;
            }

            //BASD-41146 Populate Last Photo Linking Date time when QA is completed
            //Along with status being changed from Photo Linking of Type Setup Menu
            if(isStatusChanged && statusOld == Photo_Linking && m.Last_QA_Date_Time__c != null && m.Milestone_Type__c == Setup_Menu){
                m.Last_Photo_Linking_Date_Time__c = now;
            }
        }
    }

    /**
     * BZAP-9259: Automate Stage Movement
     * BZAP-9268: Automate Status and Status Reason
     * BZAP-9351: Update Activation Start //TODO: This should be handled by CDdCaseMilestone
     *
     * Updates parent Stage, Status, Status Reason, and Historical Status Reasons.
     *
     * A Context object collects relevant milestones and milestone parents for use by helper methods, which have the
     * side effect of updating parent objects as appropriate.
     *
     * Helper methods are responsible for using ctx.parentIdFilter as appropriate for their use case.
     *
     * @param  newMap The new milestones to evaluate
     * @param  oldMap The old milestones to evaluate
     */
    public void updateParentStageAndStatus(Map<Id, Milestone__c> newMap, Map<Id, Milestone__c> oldMap) {

        if (ranOnceUpdateParent) {
            return;
        } else {
            ranOnceUpdateParent = true;
        }

        Context ctx = new Context();
        ctx.newMap = newMap;
        ctx.oldMap = oldMap;
        ctx.parentIds = getParentIds(newMap.values(), 'ParentId__c');
        ctx.milestoneMap = CDdMilestoneSelector.milestoneMapByParentId(ctx.parentIds);
        ctx.parentMap = CDdMilestoneSelector.parentMap(ctx.parentIds);

        updateParentStatus(ctx);
        updateParentStage(ctx);
        updateParentOwnerByMileStoneType(ctx);
        performSObjectSpecificUpdates(ctx);
        updateParentOwnerByCompletedMileStoneType(ctx);

        update ctx.parentMap.values(); // FIXME: remove parents that haven't been updated
    }

    /**
     * BZAP-9351: Perform SObject-specific updates on milestone update
     *
     * @param ctx The context object
     */
    public void performSObjectSpecificUpdates(Context ctx) {
        if (ctx.parentMap.values()[0].Id != null) { // FIXME: assumes 1 SObject type per transaction
            String sobjectType = CDdSchemaUtils.getSObjectTypeNameFromRecordId(ctx.parentMap.values()[0].Id);
            String className = 'CDd' + sobjectType + 'Milestone';
            Type t = Type.forName(className);
            MilestoneInterface m = (MilestoneInterface) t.newInstance();
            m.updateParentStageAndStatus(ctx);
        }
    }

    /**
     * BZAP-9268: Update Case Status and Status Reason
     *
     * Given a set of milestones that have been updated, determine which have had a status change.
     * Pass these down the call stack to have statuses applied.
     *
     * @param ctx The Milestone Context object
    */
    private void updateParentStatus(Context ctx) {
        Map<Id, Milestone__c> filteredMap = new Map<Id, Milestone__c>();
        for (Milestone__c m : ctx.newMap.values()) {
            if (ctx.oldMap == null || m.Status__c != ctx.oldMap.get(m.Id).Status__c) {
                filteredMap.put(m.Id, m);
            }
        }

        ctx.parentIdFilter = getParentIds(filteredMap.values(), 'ParentId__c');

        updateParentStatusFiltered(ctx);
    }

    /**
     * BZAP-9268: Update Case Status and Status Reason
     *
     * For each parent, evaluate each milestone for all possible statuses. This may produce conflicting status updates,
     * so store matches in a candidate map, which holds a list of all candidate updates for each parent.
     * Note: these must be **clones** of the original SObject so as not to overwrite conflicting values.
     *
     * Finally, referee between conflicting candidates by applying criteria in a defined order.
     *
     * @param ctx The Milestone Context object
    */
    @TestVisible
    private void updateParentStatusFiltered(Context ctx) {
        Map<Id, SObject> refereedMap = new Map<Id, SObject>();

        // For each parent, evaluate all milestones for all potential status changes and add them to candidateMap
        for (Id parentId : ctx.parentIdFilter) {
            SObject sobj = ctx.parentMap.get(parentId);
            ctx.candidateMap.put(parentId, new List<SObject>());

            // This method has the side-effect of adding sobjs to the candidateMap if they meet the criteria
            initializeCandidates(ctx, sobj);
        }

        // Referee between potentially conflicting milestones and add the winner to refereedMap
        for (Id parentId : ctx.candidateMap.keySet()) {

            // Map candidates by Status
            Map<String, SObject> candidatesByStatusMap = new Map<String, SObject>();
            for (SObject sobj : ctx.candidateMap.get(parentId)) {
                candidatesByStatusMap.put((String) sobj.get('Status'), sobj);
            }

            // Apply criteria in defined order
            if (candidatesByStatusMap.containsKey(Dead)) {
                SObject parent = candidatesByStatusMap.get(Dead);
                refereedMap.put(parentId, parent);
            } else if (candidatesByStatusMap.containsKey(Blocked)) {
                SObject parent = candidatesByStatusMap.get(Blocked);
                refereedMap.put(parentId, parent);
            } else if (candidatesByStatusMap.containsKey(Escalated)) {
                SObject parent = candidatesByStatusMap.get(Escalated);
                refereedMap.put(parentId, parent);
            } else if (candidatesByStatusMap.containsKey(InRescue)) {
                SObject parent = candidatesByStatusMap.get(InRescue);
                refereedMap.put(parentId, parent);
            } else if (candidatesByStatusMap.containsKey(Open)) {
                SObject parent = candidatesByStatusMap.get(Open);
                refereedMap.put(parentId, parent);
            } else if (candidatesByStatusMap.containsKey(Reopened)) {
                SObject parent = candidatesByStatusMap.get(Reopened);
                refereedMap.put(parentId, parent);
            } else if (candidatesByStatusMap.containsKey(In_Progress)) {
                SObject parent = candidatesByStatusMap.get(In_Progress);
                refereedMap.put(parentId, parent);
            }
        }

        for (SObject obj : refereedMap.values()) {
            ctx.parentMap.put((Id) obj.get('Id'), obj);
        }
    }

    @TestVisible void initializeCandidates(Context ctx, SObject sobj) {
        Boolean isDead = false;
        Boolean isBlocked = false;
        Boolean isEscalated = false;
        Boolean isOpen = false;
        Boolean isReopened = false;
        Boolean isInProgress = false;
        Boolean isInRescue = false;

        Id parentId = (Id) sobj.get('Id');
        Id parentRecordTypeId = (Id) sobj.get('RecordTypeId');
        List<String> openReopenedFilter = new List<String> { Dead, Blocked, Escalated, Complete };
        List<String> statusReasons = new List<String>();
        List<String> historicalReasons = new List<String>();
        String statusReasonsDetailsStr = '';
        String parentStatus = (String) sobj.get('Status');
        String parentStage = (String) sobj.get('Stage__c');

        String sobjType = CDdSchemaUtils.getSObjectTypeNameFromRecordId((Id) sobj.get('Id'));
        List<String> eligibleStatusForRollup = CDdMilestoneSelector.settingsStatusRollup(sobjType);

        for (Milestone__c m : ctx.milestoneMap.get((Id) sobj.get('Id'))) {
            if (m.Status_Reason__c != null)                 { statusReasons.add(m.Status_Reason__c); }
            if (m.Historical_Delay_Reasons__c != null)      { historicalReasons.add(m.Historical_Delay_Reasons__c); }

            if ((m.Status__c == Dead && m.Completed_by_Stage__c != null) || (m.Milestone_Type__c == Review_And_Triage && m.Status__c == InRescue && parentRecordTypeId == CASE_MARKETPLACE_ONBOARDING_RT)) {
                isDead = true;
            } else if ((m.Status__c == Blocked && m.Completed_by_Stage__c != null && (m.Reviewed_by_Stage__c == null || m.Completed_by_Stage__c == parentStage)) || (m.Status__c == InRescue && Label.In_Rescue_Milestone_Types.contains(m.Milestone_Type__c) && parentRecordTypeId == CASE_MARKETPLACE_ONBOARDING_RT)) {
                isBlocked = true;
            } else if(m.Status__c == InRescue && parentRecordTypeId == CASE_POS_INTEGRATIONS_RT){
                isInRescue = true;
            } else if (m.Status__c == Escalated) {
                isEscalated = true;
            } else if (parentStatus != 'Reopened' && parentStatus != 'Open' && parentStatus != 'In Progress' && parentStatus != 'In Rescue' && !openReopenedFilter.contains(m.Status__c)) {
                if (parentStatus == Blocked) {
                    isReopened = true;
                } else if (parentStatus == Escalated) {
                    isInProgress = true;
                }
            } else if (parentStatus == 'Reopened' && !openReopenedFilter.contains((m.Status__c))) {
                isReopened = true;
            } else if (m.Status__c == In_Progress  || m.Status__c == Complete) {
                isInProgress = true;
            }
            if (eligibleStatusForRollup.contains(m.Status__c)) {
                statusReasonsDetailsStr += m.Milestone_Type__c + ' - ' + m.Status_Reason__c + ' - ' + m.Status_Reason_Details__c + '\n';
            }
        }

        String statusReasonsStr = collectStatusReasons(statusReasons, new List<String>());
        String historicalReasonsStr = collectStatusReasons(statusReasons, historicalReasons);

        ctx.candidateMap.put(parentId, new List<SObject>());
        if (isDead) {
            ctx.candidateMap.get(parentId).add(setParentStatus(sobj.clone(true), Dead, statusReasonsStr, historicalReasonsStr, statusReasonsDetailsStr));
        }
        if (isBlocked) {
            ctx.candidateMap.get(parentId).add(setParentStatus(sobj.clone(true), Blocked, statusReasonsStr, historicalReasonsStr, statusReasonsDetailsStr));
        }
        if (isEscalated) {
            ctx.candidateMap.get(parentId).add(setParentStatus(sobj.clone(true), Escalated, statusReasonsStr, null, statusReasonsDetailsStr));
        }
        if (isReopened) {
            ctx.candidateMap.get(parentId).add(setParentStatus(sobj.clone(true), Reopened, statusReasonsStr, null, statusReasonsDetailsStr));
        }
        if (isOpen) {
            ctx.candidateMap.get(parentId).add(setParentStatus(sobj.clone(true), Open, statusReasonsStr, null, statusReasonsDetailsStr));
        }
        if(isInProgress){
            ctx.candidateMap.get(parentId).add(setParentStatus(sobj.clone(true), In_Progress, statusReasonsStr, null, statusReasonsDetailsStr));
        }
        if(isInRescue){
            ctx.candidateMap.get(parentId).add(setParentStatus(sobj.clone(true), InRescue, statusReasonsStr, historicalReasonsStr, statusReasonsDetailsStr));
            allowCaseStatusUpdateInRescue = true;
        }
    }

    private SObject setParentStatus(SObject sobj, String status, String statusReasons, String historicalReasons, String statusReasonDetails) {
        SObject sobjClone = sobj.clone(true);
        sobjClone.put('Status', status);
        if (status == 'Reopened') {
            sobjClone.put('Status_Reason__c', null);
        } else {
            sobjClone.put('Status_Reason__c', statusReasons);
        }
        if (historicalReasons != null) {
            sobjClone.put('Historical_Delay_Reasons__c', historicalReasons);
        }
        if (statusReasonDetails != null) {
            sobjClone.put('Status_Reason_Details__c', statusReasonDetails);
        }
        return sobjClone;
    }

    /**
     * BZAP-9268: Update Parent Status and Status Reason
     *
     * @param statusReasons A semi-colon separated string of current status reason
     * @param historicalReasons A semi-colon separated string of historical status reason
     * @return A semi-colon separated string of combined status reasons
     */
    private String collectStatusReasons(String statusReasons, String historicalReasons) {
        List<String> statusReasonsList = new List<String>();
        List<String> historicalReasonsList = new List<String>();

        if (statusReasons != null) {
            statusReasonsList.addAll(statusReasons.split(';'));
        }
        if (historicalReasons != null) {
            historicalReasonsList.addAll(historicalReasons.split(';'));
        }
        return collectStatusReasons(statusReasonsList, historicalReasonsList);
    }

    /**
     * BZAP-9268: Update Parent Status and Status Reason
     *
     * @param statusReasons A list of current status reason
     * @param historicalReasons A list of historical status reason
     * @return A semi-colon separated string of combined status reasons
     */
    private String collectStatusReasons(List<String> statusReasons, List<String> historicalReasons) {
        Set<String> reasonSet = new Set<String>();
        for (String reasons : statusReasons) {
            reasonSet.addAll(reasons.split(';'));
        }
        for (String reasons : historicalReasons) {
            reasonSet.addAll(reasons.split(';'));
        }
        if (reasonSet.size() > 0) {
            List<String> reasons = new List<String>();
            reasons.addAll(reasonSet);
            return String.join(reasons, ';');
        } else {
            return null;
        }
    }

    /**
     * BZAP-9259: Evaluate whether parent stage should change based on updates to its milestones.
     *
     * @param  ctx The CDdMilestone.Context object
     */
    private void updateParentStage(Context ctx) {
        ctx.parentIdFilter = new Set<Id>();

        for (Milestone__c m : ctx.newMap.values()) {
            if (ctx.oldMap == null || isStageUpdateable(m, ctx.oldMap.get(m.Id))) { // 2.1
                ctx.parentIdFilter.add(m.ParentId__c);
            }
        }
        updateParentStageFiltered(ctx);
    }

    /**
     * BZAP-9259: Evaluate whether parent stage should change based on updates to its milestones.
     *
     * @param  ctx The CDdMilestone.Context object
     */
    @TestVisible
    private void updateParentStageFiltered(Context ctx) {
        for (Id parentId : ctx.parentIdFilter) {
            List<Milestone__c> milestones = ctx.milestoneMap.get(parentId);
            SObject parentObj = ctx.parentMap.get(parentId);

            if (isClosable(ctx, parentObj)) { // 2.2.a, 2.2.b) Close case
                parentObj.put('Stage__c', 'Onboarding Complete');
                parentObj.put('Status', 'Closed'); // FIXME: Other SObject types may not have a standard Status field; may need a field mapper
                parentObj.put('Status_Reason__c', null);

            } else if (!isStageComplete(ctx, parentId)) { // 2.2.c.i
                // 2.2.c.ii: Stop, do nothing

            } else { // 2.2.c.iii
                List<CompleteByWrapper> completedByMilestones = new List<CompleteByWrapper>();
                List<ReviewByWrapper> reviewedByMilestones = new List<ReviewByWrapper>();

                for (Milestone__c m : milestones) {
                    if (isStageEligibleCompleted(m) && m.Completed_by_Stage__c != null)  {
                        completedByMilestones.add(new CompleteByWrapper(m));
                    }
                    if (isStageEligibleReviewed(m) && m.Reviewed_by_Stage__c != null && m.Status__c != Blocked) {
                        reviewedByMilestones.add(new ReviewByWrapper(m));
                    }
                }

                completedByMilestones.sort();
                reviewedByMilestones.sort();

                String stage;
                if (completedByMilestones.size() > 0 && reviewedByMilestones.size() > 0) {
                    CompleteByWrapper cbm = completedByMilestones[0];
                    ReviewByWrapper rbm = reviewedByMilestones[0];
                    stage = (Decimal) cbm.obj.get('Stage_Completed_Sort_Order__c') < (Decimal) rbm.obj.get('Stage_Reviewed_Sort_Order__c') ?
                            (String) cbm.obj.get('Completed_by_Stage__c') :
                            (String) rbm.obj.get('Reviewed_by_Stage__c');
                } else if (completedByMilestones.size() > 0) {
                    CompleteByWrapper cbm = completedByMilestones[0];
                    stage = (String) cbm.obj.get('Completed_by_Stage__c');
                } else if (reviewedByMilestones.size() > 0) {
                    ReviewByWrapper rbm = reviewedByMilestones[0];
                    stage = (String) rbm.obj.get('Reviewed_by_Stage__c');
                } else {
                    stage = 'Onboarding Complete';
                }



                parentObj.put('Stage__c', stage);
                if (stage == 'Onboarding Complete') {
                    parentObj.put('Status', 'Closed');
                    parentObj.put('Status_Reason__c', null);
                }
            }
        }
    }

    /**
     * BZAP-9259: 2.2.c.i) Are all milestones reviewed or completed?
     *
     * @param ctx
     * @param parentId
     *
     * @return
     */
    private Boolean isStageComplete(Context ctx, Id parentId) {
        Boolean isStageComplete = true;

        for (Milestone__c m : ctx.openRequiredMap.get(parentId)) {
            String parentStage = (String) ctx.parentMap.get(parentId).get('Stage__c');
            Milestone__c mToEvaluate = ctx.newMap.keySet().contains(m.Id) ? ctx.newMap.get(m.Id) : m;

            Boolean isOpen = mToEvaluate.Status__c != Complete && mToEvaluate.Status__c != Dead;
            Boolean isCompleteBy = mToEvaluate.Completed_by_Stage__c != null && mToEvaluate.Completed_by_Stage__c == parentStage;
            Boolean isReviewBy = mToEvaluate.Reviewed_by_Stage__c != null && mToEvaluate.Reviewed_by_Stage__c == parentStage && mToEvaluate.Status__c != Blocked;

            if (isOpen && (isCompleteBy || isReviewBy)) {
                isStageComplete = false;
            }

        }
        return isStageComplete;
    }

    private Boolean isStageEligibleCompleted(Milestone__c m) {
        Boolean isStageEligible = (m.Status__c != Complete && m.Status__c != Dead && m.Completed_by_Stage__c != null);
        return isStageEligible;
    }

    private Boolean isStageEligibleReviewed(Milestone__c m) {
        Boolean isStageEligible = (m.Status__c != Complete && m.Status__c != Dead && m.Reviewed_by_Stage__c != null);
        return isStageEligible;
    }

    /**
     * BZAP-9259: 2.1) Milestone "complete" criteria
     *
     * @param newMilestone The milestone to evaluate
     * @param oldMilestone Old values to compare against
     * @return Whether the milestone is "complete"
     */
    @TestVisible
    private Boolean isStageUpdateable(Milestone__c newMilestone, Milestone__c oldMilestone) {
        Boolean isStageUpdateable = newMilestone.Status__c != oldMilestone.Status__c && new List<String> { Complete, Blocked, Dead }.contains(newMilestone.Status__c);
        return isStageUpdateable;
    }

    /**
     * BZAP-9259: 2.2.a) Stage "complete" criteria
     *
     * @param ctx The Context object
     * @param parentObj The parent to evaluate
     * @return Whether the milestone is "complete"
     */
    @TestVisible
    private Boolean isClosable(Context ctx, SObject parentObj) {
        Boolean isClosable = true;
        for (Milestone__c m : ctx.milestoneMap.get((Id) parentObj.get('Id'))) {
            Milestone__c mToEvaluate = ctx.newMap.keySet().contains(m.ParentId__c) ? ctx.newMap.get(m.Id) : m; // Use new values when available
            Boolean isComplete = mToEvaluate.Status__c != Complete && mToEvaluate.Status__c != Dead;
            Boolean isCompletedBy = mToEvaluate.Completed_by_Stage__c != null;
            Boolean isReviewedBy = mToEvaluate.Reviewed_by_Stage__c != null;

            ctx.openRequiredMap.put(m.ParentId__c, new List<Milestone__c>());
            if (isComplete && (isCompletedBy || isReviewedBy)) { // 2.2.a.i, 2.2.a.ii
                isClosable = false;
            } else {
                if (ctx.openRequiredMap.containsKey(m.ParentId__c)) {
                    ctx.openRequiredMap.get(m.ParentId__c).add(m);
                }
            }
        }
        return isClosable;
    }

    /**
     * @param template The template for the new milestone
     * @param parentField The milestone field which holds the parent reference
     * @param parentId The parent of the milestone
     *
     * @return An initialized Milestone__c
     */
    @TestVisible
    protected Milestone__c initializeMilestone(Milestone_Template__c template, String parentField, Id parentId) {
        Milestone__c milestone = new Milestone__c();
        milestone.Completed_by_Stage__c = template.Completed_by_Stage__c;
        milestone.Milestone_Template__c = template.Id;
        milestone.Milestone_Type__c = template.Milestone_Type__c;
        milestone.Name = template.Milestone_Type__c;
        milestone.OwnerId = template.Default_Owner_on_Creation_18__c;
        milestone.RecordTypeId = template.Milestone_Record_Type_ID_18__c;
        milestone.Reviewed_by_Stage__c = template.Reviewed_by_Stage__c;
        milestone.Sort_Order__c = template.Default_Sort_Order__c;
        milestone.Stage_Completed_Sort_Order__c = template.Stage_Completed_Sort_Order__c;
        milestone.Stage_Reviewed_Sort_Order__c  = template.Stage_Reviewed_Sort_Order__c;
        milestone.Status__c = template.Default_Milestone_Status_on_Creation__c;
        milestone.put(parentField, parentId);
        return milestone;
    }

    /**
     * @param sobjs The SObjects from which to get parent Ids
     * @param parentIdField The field API name for the parent Id field
     *
     * @return A set of parent Ids
     */
    private Set<Id> getParentIds(List<SObject> sobjs, String parentIdField) {
        Set<Id> ids = new Set<Id>();
        for (SObject sobj :sobjs) {
            if(sobj.get(parentIdField) != null) {
                ids.add((Id) sobj.get(parentIdField));
            }
        }
        return ids;
    }

    /**
     * Wrapper for sorting a list of milestones by Stage_Completed_Sort_Order__c
     */
    private class CompleteByWrapper implements Comparable {
        public SObject obj;
        public CompleteByWrapper(SObject obj) { this.obj = obj; }
        public Integer compareTo(Object compareTo) {
            CompleteByWrapper compareToObject = (CompleteByWrapper) compareTo;
            if ((Decimal) obj.get('Stage_Completed_Sort_Order__c') < (Decimal) compareToObject.obj.get('Stage_Completed_Sort_Order__c')) {
                return -1;
            }
            else {
                return 1;
            }
        }
    }

    /**
     * Wrapper for sorting a list of milestones by Stage_Reviewed_Sort_Order__c
     */
    private class ReviewByWrapper implements Comparable {
        public SObject obj;
        public ReviewByWrapper(SObject obj) { this.obj = obj; }
        public Integer compareTo(Object compareTo) {
            ReviewByWrapper compareToObject = (ReviewByWrapper) compareTo;
            if ((Decimal) obj.get('Stage_Reviewed_Sort_Order__c') < (Decimal) compareToObject.obj.get('Stage_Reviewed_Sort_Order__c')) {
                return -1;
            }
            else {
                return 1;
            }
        }
    }

    /**
     * BZAP-13115: Update Case Owner By MileStones
     * Given a set of milestones are completed for NZ Onboarding Marketplace case, We have to update the Case Owner.
     * @param ctx The Milestone Context object
    */
    @TestVisible
    private void updateParentOwnerByMileStoneType(Context ctx) {
        Map<Id, Milestone__c> filteredMap = new Map<Id, Milestone__c>();
        for (Milestone__c m : ctx.newMap.values()) {
            if ((ctx.oldMap == null ||
                m.Status__c != ctx.oldMap.get(m.Id).Status__c) &&
                m.Status__c == Complete &&
                String.isNotBlank(m.Milestone_Type__c) &&
                MILESTONE_TYPES_NZ.contains(m.Milestone_Type__c)) {
                filteredMap.put(m.Id, m);
            }
        }

        if(!Test.isRunningTest()){
            ctx.parentIdFilter = getParentIds(filteredMap.values(), 'ParentId__c');
        }
        if(ctx.parentIdFilter!= null && !ctx.parentIdFilter.isEmpty()){
            updateCaseOwner(ctx);
        }

    }

    private void updateCaseOwner(Context ctx){
        for (Id parentId : ctx.parentIdFilter) {
            if(parentId.getsobjecttype() != Case.SObjectType){
                continue;
            }

            Boolean isGrandPortalMLComplete = false;
            Case caseRec = (Case)ctx.parentMap.get(parentId);

            //checking Grand parent(Parent?.Parent?.RecordTypeId) record only as Parent and Grand Parent won't have Onboarding case
            if((caseRec.RecordTypeId == CASE_MARKETPLACE_ONBOARDING_RT &&
                caseRec.Account.Parent?.Parent?.RecordTypeId == ACCOUNT_GRAND_PARENT_RT &&
                //BASD-31125 Check if MO case status is not closed and Country is US/CAN/AUS/NZ
               	caseRec.Status != 'Closed' && caseRec.Segment__c != null &&
               	(CDdI18nUtility.isCountryNewZealand(caseRec.Account.BillingCountryCode) ||
                (CDdI18nUtility.isCountryEligibleForCaseOwnerChange(caseRec.Account.BillingCountryCode) && caseRec.Segment__c != 'Enterprise'))) ||
                Test.isRunningTest()){
                    Integer noOfMileStones = 0;
                    for (Milestone__c milestone : ctx.milestoneMap.get(parentId)) {
                        if (String.isNotBlank(milestone.Milestone_Type__c) &&
                            MILESTONE_TYPES_NZ.contains(milestone.Milestone_Type__c) &&
                            milestone.Status__c == Complete) {
                                noOfMileStones++;
                        }
                        if(milestone.RecordTypeId == MILESTONE_GRAND_PORTAL_ACCESS && milestone.Status__c == Complete){
                            isGrandPortalMLComplete = True;
                        }
                    }
                    if (noOfMileStones >= MILESTONE_TYPES_NZ.size() && !isGrandPortalMLComplete) {
                        SObject parentObj = ctx.parentMap.get(parentId);
                        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'QUEUE' AND DeveloperName= 'Onboarding_Business_Group_Creation'];
                        if(!queues.isEmpty()){
                            parentObj.put('OwnerId', queues[0].Id);
                        }
                    }
            }
        }
    }

     /**
     * BZAP-15016: Update Milestones status to 'Complete' listed in POS_BULK_MILESTONE_TYPES_CLOSED
     * This will be executed when Case is created by Mulesoft Integration User as part of POS Bulk Activation.
     *
     * @param newMileStoneList New Milestones list from the trigger before insert
    */
    public void updateMilestoneStatuses(List<Milestone__c> newMileStoneList) {
        Set<Id> caseIds = getParentIds(newMileStoneList, 'Case__c');
        Map<Id,SObject> caseMap = CDdMilestoneSelector.parentMap(caseIds);

        for(Milestone__c milstone : newMileStoneList){
            if(milstone.ParentId__c != null && caseMap.containsKey(milstone.ParentId__c)){
                Case parentCase = (Case)caseMap.get(milstone.ParentId__c);
                if( parentCase.RecordTypeId == CASE_POS_INTEGRATION_RT &&
                    parentCase.Stage__c == CASE_STAGE_UNDER_REVIEW  &&
                    (parentCase.Origin == CASE_ORIGIN_BULK_TOOL_AUTOMATION || parentCase.Origin == CASE_ORIGIN_SSIO) &&
                    POS_BULK_MILESTONE_TYPES_CLOSED.contains(milstone.Milestone_Type__c) &&
                    parentCase.CreatedBy.Name == MULESOFT_INTEGRATION_USER){
                        milstone.Status__c = Complete;
                        if(CDdUtilities.idIsUser(parentCase.ownerId)){
                            milstone.ownerId = parentCase.ownerId;
                        }else {
                            milstone.ownerId = parentCase.CreatedById;
                        }
                }
            }
        }
    }

    /**
     * BZAP-16106: Validation to check when the Ads and promo can be worked up on
     *
     * @param newMap Map containing new values
     * @param oldMap Map containing old values
    */
    public void validateAdPromo(Map<Id, Milestone__c> newMap, Map<Id, Milestone__c> oldMap){
        if(ranOnceValidateAdPromo){
            return;
        }else{
            ranOnceValidateAdPromo = true;
        }
        Map<Id, Milestone__c> parentIdWithStoreActivationMilestonMap = new Map<Id,Milestone__c>();
        Map<Id, Milestone__c> parentIdWithActivationChecklistMilestonMap = new Map<Id,Milestone__c>();
        Set<Id> parentIds = new Set<Id>();
        Set<String> recTypeIds = new Set<String>{milestoneRT.activateStoreId(), milestoneRT.activationsChecklistId()};
        for(Milestone__c adProMilestone : newMap.values()){
            if(adProMilestone.Status__c != oldMap.get(adProMilestone.Id).Status__c &&
                adProMilestone.recordTypeId == milestoneRT.adsPromosId()){
                parentIds.add(adProMilestone.ParentId__c);
            }
        }
        if(parentIds.size()>0){
            for(Milestone__c milestone : [Select Id, Status__c, ParentId__c, recordTypeId
                                                from Milestone__c
                                                WHERE ParentId__c IN:parentIds and recordTypeId IN:recTypeIds]){
                if(milestone.recordTypeId == milestoneRT.activateStoreId()){
                    parentIdWithStoreActivationMilestonMap.put(milestone.ParentId__c, milestone);
                }
                if(milestone.recordTypeId == milestoneRT.activationsChecklistId()){
                    parentIdWithActivationChecklistMilestonMap.put(milestone.ParentId__c, milestone);
                }
            }
        }

        for(Milestone__c adProMilestone : newMap.values()){
            if(parentIdWithStoreActivationMilestonMap.containsKey(adProMilestone.ParentId__c)){
                if(parentIdWithStoreActivationMilestonMap.get(adProMilestone.ParentId__c).Status__c != Complete){
                    adProMilestone.addError(CDdMxSxConstants.MILESTONE_AD_PROMS_VALIDATION_MESSAGE);
                }
            }else if(parentIdWithActivationChecklistMilestonMap.containsKey(adProMilestone.ParentId__c)){
                if(parentIdWithActivationChecklistMilestonMap.get(adProMilestone.ParentId__c).Status__c != Complete){
                    adProMilestone.addError(CDdMxSxConstants.MILESTONE_AD_PROMS_VALIDATION_MESSAGE);
                }
            }
        }
    }

    /**
     * BZAP-16107: Case ownership change for Ads and Promo Milestone
     *
     * @param newMap Map containing new values
     * @param oldMap Map containing old values
    */
    public void completeMilestoneWithAdPromo(Map<Id, Milestone__c> newMap, Map<Id, Milestone__c> oldMap){
        if(ranOnceCompleteAdPromo){
            return;
        }else{
            ranOnceCompleteAdPromo = true;
        }
        Map<Id, Milestone__c> parentIdWithStoreActivationMilestonMap = new Map<Id,Milestone__c>();
        Map<Id, Milestone__c> parentIdWithActivationChecklistMilestonMap = new Map<Id,Milestone__c>();
        Map<Id, Milestone__c> parentIdWithAdPromoMilestonMap = new Map<Id,Milestone__c>();
        Set<Id> parentIds = new Set<Id>();
        Set<String> recTypeIds = new Set<String>{milestoneRT.activateStoreId(), milestoneRT.activationsChecklistId()};
        Set<String> recTypeIdsWithAdProms = new Set<String>{milestoneRT.activateStoreId(), milestoneRT.activationsChecklistId(), milestoneRT.adsPromosId()};
        Map<Id,Case> parentCaseMap = new Map<Id,Case>();
        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'QUEUE' AND DeveloperName= 'Onboarding_Ads_Promos'];
        for(Milestone__c completedMilestone : newMap.values()){
            if(recTypeIds.contains(completedMilestone.recordTypeId) && completedMilestone.Status__c != oldMap.get(completedMilestone.Id).Status__c &&
                completedMilestone.Status__c == Complete){
                parentIds.add(completedMilestone.ParentId__c);
            }
        }
        if(parentIds.size()>0){
            for(Milestone__c milestone : [Select Id, Status__c, ParentId__c, recordTypeId
                                                from Milestone__c
                                                WHERE ParentId__c IN:parentIds and recordTypeId IN:recTypeIdsWithAdProms]){
                if(milestone.recordTypeId == milestoneRT.activateStoreId()){
                    parentIdWithStoreActivationMilestonMap.put(milestone.ParentId__c, milestone);
                }
                if(milestone.recordTypeId == milestoneRT.activationsChecklistId()){
                    parentIdWithActivationChecklistMilestonMap.put(milestone.ParentId__c, milestone);
                }
                if(milestone.recordTypeId == milestoneRT.adsPromosId()){
                    parentIdWithAdPromoMilestonMap.put(milestone.ParentId__c, milestone);
                }
            }
        }

        for(Milestone__c WithAdProMilestone : newMap.values()){
            if (parentCaseMap.containsKey(WithAdProMilestone.ParentId__c)) {
                continue;
            }
            if(WithAdProMilestone.recordTypeId==milestoneRT.activateStoreId() &&
                WithAdProMilestone.Status__c ==Complete &&
                parentIdWithAdPromoMilestonMap.containsKey(WithAdProMilestone.ParentId__c)){
                    Case cx = new Case();
                    cx.Id = WithAdProMilestone.ParentId__c;
                    cx.OwnerId = queues[0].Id;
                    //BASD-52032 Onboarding - Ads & Promos automation updates
                    cx.Onboarding_Ads_and_Promo_Status__c = CDdMxSxConstants.ADS_AND_PROMO_STATUS_INCOMPLETE;
                    parentCaseMap.put(cx.Id,cx);
            }else if(parentIdWithActivationChecklistMilestonMap.containsKey(WithAdProMilestone.ParentId__c) &&
                WithAdProMilestone.Status__c ==Complete &&
                !parentIdWithStoreActivationMilestonMap.containsKey(WithAdProMilestone.ParentId__c) &&
                parentIdWithAdPromoMilestonMap.containsKey(WithAdProMilestone.ParentId__c)){
                    Case cx = new Case();
                    cx.Id = WithAdProMilestone.ParentId__c;
                    cx.OwnerId = queues[0].Id;
                    cx.Onboarding_Ads_and_Promo_Status__c = CDdMxSxConstants.ADS_AND_PROMO_STATUS_INCOMPLETE;
                    parentCaseMap.put(cx.Id,cx);
            }
        }
        if(!parentCaseMap.isEmpty()){
            update parentCaseMap.values();
        }
    }

       /**
     * @author      Swedhaa Sri M
     * @date        Nov 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-39912
     * @description set case owner based on Hibernated and Suspended POS Values
     */
    @TestVisible
    private void updateParentOwnerByCompletedMileStoneType(Context ctx) {
        Map<Id, Milestone__c> filteredMap = new Map<Id, Milestone__c>();
        List<String> queueNames = new List<String> {QUEUE_HIBERNATED_POS_PROVIDERS, QUEUE_SUSPENDED_POS_PROVIDERS};

        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);
        Id marketplaceOnboardingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Marketplace_Onboarding');
        Id hibernatedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_HIBERNATED_POS_PROVIDERS);
        Id suspendedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_SUSPENDED_POS_PROVIDERS);

        String HIBERNATED_POS_PROVIDER_VALUES = CDdNameValuePairHelper.getLongTextValue('Hibernated_POS_Providers');
        String SUSPENDED_POS_PROVIDER_VALUES = CDdNameValuePairHelper.getLongTextValue('Suspended_POS_Providers');
        String ONBOARDING_POS_QUEUES = CDdNameValuePairHelper.getTextValue('Onboarding_POS_Queue_Ids');

        for (Milestone__c m : ctx.newMap.values()) {
            if (ctx.oldMap == null || m.Status__c != ctx.oldMap.get(m.Id).Status__c) {
                filteredMap.put(m.Id, m);
            }
        }

        if(!Test.isRunningTest()){
            ctx.parentIdFilter = getParentIds(filteredMap.values(), 'ParentId__c');
        }

        for (Id parentId : ctx.parentIdFilter) {
            if(parentId.getsobjecttype() != Case.SObjectType ){
                continue;
            }

            Integer noOfMileStones = 0;
            Case caseRec = (Case)ctx.parentMap.get(parentId);

            if(caseRec.POS_Integration_Type__c != null && caseRec.OwnerId != null && caseRec.OwnerId != hibernatedPOSProvidersQueueId && caseRec.OwnerId != suspendedPOSProvidersQueueId && caseRec.Status != 'Closed' && caseRec.RecordTypeId == marketplaceOnboardingRTId){
                for (Milestone__c milestone : ctx.milestoneMap.get(parentId)) {
                    if (String.isNotBlank(milestone.Milestone_Type__c) &&
                        MILESTONE_TYPES_POS_PROVIDERS.contains(milestone.Milestone_Type__c) &&
                        milestone.Status__c == Complete) {
                            noOfMileStones++;
                        }
                }

                if(noOfMileStones >= 4 && ONBOARDING_POS_QUEUES.contains(caseRec.OwnerId)){
                    SObject parentObj = ctx.parentMap.get(parentId);

                    if(HIBERNATED_POS_PROVIDER_VALUES.contains(caseRec.POS_Integration_Type__c)){
                        parentObj.put('OwnerId', hibernatedPOSProvidersQueueId);
                    } else if(SUSPENDED_POS_PROVIDER_VALUES.contains(caseRec.POS_Integration_Type__c)) {
                        parentObj.put('OwnerId', suspendedPOSProvidersQueueId);
                    }
                }
            }
        }
    }
}