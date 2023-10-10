/**
 * @author Jeremy S. Johnson
 * @date November 2020
 *
 * @description BZAP-9178
 */

@IsTest
public with sharing class CDdMilestoneTest {
    public static final Id caseRecordTypeId = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
    public static final Id casePosIntegrationsRT = CDdSchemaUtils.CASE_RT.posIntegrationsId();
    public static final Id milestoneOwnerId = [select Id from Group where DeveloperName = 'Onboarding_Not_Started'].Id;
    public static final Long millisPerDay = 86400000;
    public static final String caseId = '50000000000000000'; //call nextId() before using
    public static final String milestoneId = Schema.SObjectType.Milestone__c.getKeyPrefix() + '00000000000000'; //call incrementId() before using
    public static final String ownerIdGrp = '00G000000000000000';
    public static final String ownerIdUsr = '005000000000000000';
    public static final User user = [select Id from User where Profile.Name = 'System Administrator' limit 1];
    public static Integer currentId = 0;
    public static List<Milestone__c> milestones;
    public static Map<Id, Milestone_Template__c> templateMap;
    public static Opportunity opp;
    public static Map<String, Account> accountMap;
    public static final Id GRANDPARENT_ACCOUNT_RECORD_TYPE_ID;
    public static final Id PARENT_ACCOUNT_RECORD_TYPE_ID;
    public static final Id MARKETPLACE_RECORD_TYPE_ID;
    static {
        GRANDPARENT_ACCOUNT_RECORD_TYPE_ID = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Account', 'Grandparent_Account');
        PARENT_ACCOUNT_RECORD_TYPE_ID = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Account', 'Parent_Account');
        MARKETPLACE_RECORD_TYPE_ID = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Account', 'Prospect');
    }

    /**
     * Inserting a Marketplace Onboarding Opportunity should generate a Marketplace Onboarding Case
     * with Corresponding Milestone__c records, based on the templates.
     */
    public static void setupData() {
        insert VTestUtil.createVeltigSettings();

        CDdMilestoneTemplate.insertMilestoneTemplates();
        templateMap = CDdMilestoneSelector.templatesByParentTypeMap('Case');

        opp = CDdOpportunityCaseHelperTest.setupEnterpriseMarketplaceOnboardingOpp(user, false);
        insert opp;
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Milestone_Validations__c  = true;
        insert validation;

        accountMap = new Map<String, Account>{
            'Grand Parent' => TDdAccountFactory.createAccount(GRANDPARENT_ACCOUNT_RECORD_TYPE_ID),
            'Parent' => TDdAccountFactory.createAccount(PARENT_ACCOUNT_RECORD_TYPE_ID),
            'Child' => TDdAccountFactory.createAccount(MARKETPLACE_RECORD_TYPE_ID)
        };
        insert accountMap.values();

        accountMap.get('Parent').ParentId = accountMap.get('Grand Parent').Id;
        accountMap.get('Child').ParentId = accountMap.get('Parent').Id;
        update accountMap.values();
    }

    /**
     * BZAP-9178: Test generate Case Milestones
     */
    @IsTest
    public static void testInsertMilestones() {
        Test.startTest(); // force Case creation to run synchronously
        setupData();
        Test.stopTest();

        Case c = [select Id from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];

        List<Milestone__c> milestones = CDdMilestoneSelector.milestonesByParentId(new Set<Id> { c.Id });
        System.assertNotEquals(0, milestones.size());
        for (Milestone__c milestone : milestones) {
            Milestone_Template__c template = templateMap.get(milestone.Milestone_Template__c);
            System.assertEquals(template.Completed_by_Stage__c, milestone.Completed_by_Stage__c);
            System.assertEquals(template.Default_Milestone_Status_on_Creation__c, milestone.Status__c);
            System.assertEquals(template.Default_Owner_on_Creation_18__c, String.valueOf(milestone.OwnerId));
            System.assertEquals(template.Default_Sort_Order__c, milestone.Sort_Order__c);
            System.assertEquals(template.Id, milestone.Milestone_Template__c);
            System.assertEquals(template.Milestone_Type__c, milestone.Milestone_Type__c);
            System.assertEquals(template.Milestone_Record_Type_ID_18__c, String.valueOf(milestone.RecordTypeId));
            System.assertEquals(template.Reviewed_by_Stage__c, milestone.Reviewed_by_Stage__c);
        }
    }

    /**
     * BZAP-9178: Test conditional milestone logic
     */
    @IsTest
    public static void testCaseMilestone() {
        CDdCaseMilestone caseMilestone = new CDdCaseMilestone();

        Test.startTest();
        setupData();

        opp.Activate_Centrally_2__c = 'Yes';
        //opp.Menu_to_be_completed_by__c = 'Merchant';
        opp.Mx_Requested_Custom_Radius_Demand_Gen__c = 'Yes';
        opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
        opp.PDOA_Delay_Reason__c = 'Tablet Delay';
        opp.Tablet_Delivery_Method__c = 'Drop-Ship';
        update opp;

        Test.stopTest();

        Case c = [
                select
                        Activate_Centrally2__c,
                        Id,
                        Opportunity_Name__r.Activate_Centrally_2__c,
                        Opportunity_Name__r.Menu_to_be_completed_by__c,
                        Opportunity_Name__r.Mx_Requested_Custom_Radius_Demand_Gen__c,
                        Opportunity_Name__r.Order_Protocol__c,
                        Opportunity_Name__r.POS_Integration_Type__c,
                        Opportunity_Name__r.Tablet_Delivery_Method__c,
                        Segment__c
                from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];
        c.Segment__c = 'Local';
        update c;

        opp.Activate_Centrally_2__c = 'No';
        opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        opp.Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
        opp.Order_Protocol__c = 'POS';
        opp.Tablet_Delivery_Method__c = null;
        update opp;

        c.Segment__c = '';
        update c;

        c = [
                select
                        Activate_Centrally2__c,
                        Id,
                        Opportunity_Name__r.Activate_Centrally_2__c,
                        Opportunity_Name__r.Menu_to_be_completed_by__c,
                        Opportunity_Name__r.Mx_Requested_Custom_Radius_Demand_Gen__c,
                        Opportunity_Name__r.Order_Protocol__c,
                        Opportunity_Name__r.POS_Integration_Type__c,
                        Opportunity_Name__r.Tablet_Delivery_Method__c,
                        Segment__c
                from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];
        c.Segment__c = 'Local';
        update c;

    }

    /**
     * BZAP-9259: Automate stage Movement
     */
    @IsTest
    static void testFilterParents() {
        CDdMilestone milestone = new CDdMilestone();
        Id recordTypeId = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
        String currentRecordId;

        Map<Id, SObject> newMap = new Map<Id, SObject>();
        Map<Id, SObject> oldMap = new Map<Id, SObject>();

        // pass
        currentRecordId = incrementId(caseId);
        oldMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdGrp, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));
        newMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdUsr, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));

        // ownerId didn't change
        currentRecordId = incrementId(caseId);
        oldMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdGrp, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));
        newMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdGrp, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));

        // old ownerId wrong type
        currentRecordId = incrementId(caseId);
        oldMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdUsr, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));
        newMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdUsr, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));

        // new ownerId wrong type
        currentRecordId = incrementId(caseId);
        oldMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdGrp, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));
        newMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdGrp, RecordTypeId = recordTypeId, Stage__c = 'Not Started'));

        // wrong stage
        currentRecordId = incrementId(caseId);
        oldMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdGrp, RecordTypeId = recordTypeId, Stage__c = 'Under Review'));
        newMap.put(currentRecordId, new Case(Id = currentRecordId, OwnerId = ownerIdUsr, RecordTypeId = recordTypeId, Stage__c = 'Under Review'));

        Map<Id, SObject> filteredMap = milestone.filterParentsForInitialStage(newMap, oldMap);
        System.assertEquals(1, filteredMap.keySet().size());
    }

    /**
     * BZAP-9259: Automate Stage Movement: Initial and Maintain
     */
    @IsTest
    public static void testSetInitialStageAndMaintainStage() {
        Test.startTest();
        setupData();
        Test.stopTest();

        Case c = [select Id, OwnerId from Case where RecordTypeId = :caseRecordTypeId];
        c.OwnerId = user.Id;
        update c;

        c = [select Stage__c from Case where Id = :c.Id];
        System.assertEquals('Under Review', c.Stage__c);

        Milestone__c milestone = [select Id, Status__c from Milestone__c where ParentId__c = :c.Id and Completed_by_Stage__c = 'Under Review'];
        milestone.Status__c = 'Complete';
        update milestone;

        c = [select Stage__c from Case where Id = :c.Id];
        System.assertEquals('Store Configuration', c.Stage__c);

        c = [select Stage__c from Case where Id = :c.Id];
        c.Stage__c = 'Ready for Activation';
        update c;

        List<Milestone__c> milestones = CDdMilestoneSelector.milestonesByParentId(new Set<Id> { c.Id });
        for (Milestone__c m : milestones) {
            m.Status__c = 'Complete';
            if (m.Milestone_Type__c == 'Activate Store') {
                m.Type__c = 'Rep Activation';
            }
        }
        update milestones;

        c = [select Stage__c, Status, Status_Reason__c from Case where Id = :c.Id];
        System.assertEquals('Onboarding Complete', c.Stage__c);
        System.assertEquals('Closed', c.Status);
        System.assertEquals(null, c.Status_Reason__c);
    }

    /**
     * BZAP-9184: Test Populate KPIs
     */
    @IsTest
    public static void testPopulateKPIs() {
        CDdMilestone milestone = new CDdMilestone();
        String currentId;
        Datetime now = Datetime.now();

        Map<Id, Milestone__c> oldMap = new Map<Id, Milestone__c>();
        Map<Id, Milestone__c> newMap = new Map<Id, Milestone__c>();

        currentId = incrementId(milestoneId); //0
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Not Started'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'In Progress'));

        currentId = incrementId(milestoneId); //1
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Not Started'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Complete'));

        currentId = incrementId(milestoneId); //2
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Complete', OwnerId = ownerIdGrp));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Complete', OwnerId = ownerIdGrp));

        currentId = incrementId(milestoneId); //3
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Not Started'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'QA Complete'));

        currentId = incrementId(milestoneId); //4
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Ready for QA'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'QA Complete'));

        currentId = incrementId(milestoneId); //5
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Ready for QA'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Escalated', Status_Reason__c = 'Fraud'));

        currentId = incrementId(milestoneId); //6
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Blocked'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Complete', Last_Blocked_Date_Time__c = now.addDays(-1), Time_Spent_in_Blocked_Days__c = 1.75));

        currentId = incrementId(milestoneId); //7
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Blocked'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Escalated'));

        currentId = incrementId(milestoneId); // 8) Last_Blocked_Date_Time__c
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'In Progress'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Blocked', Status_Reason__c = 'Status Reason', Historical_Delay_Reasons__c = 'Historical Delay Reason'));

        currentId = incrementId(milestoneId); // 9) Initial_Preparation_Date_Time__c
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'In Progress'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Ready for QA'));

        currentId = incrementId(milestoneId); // 10) Last_Photo_Linking_Date_Time__c
        oldMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'Photo Linking', Last_QA_Date_Time__c = now, Milestone_Type__c = 'Setup Menu'));
        newMap.put(currentId, new Milestone__c(Id = currentId, Status__c = 'In Progress',Last_QA_Date_Time__c = now, Milestone_Type__c = 'Setup Menu'));

        milestone.populateKPIs(newMap, oldMap);

        Milestone__c m = newMap.values()[0];
        System.assert(Math.abs(now.getTime() - m.Start_Date_Time__c.getTime()) < 10000);
        System.assertEquals(UserInfo.getUserId(), m.Initial_Owner__c);

        m = newMap.values()[1];
        System.assert(Math.abs(now.getTime() - m.Completed_Date_Time__c.getTime()) < 10000);

        m = newMap.values()[2];
        System.assertEquals(UserInfo.getUserId(), m.OwnerId);

        m = newMap.values()[3];
        System.assert(Math.abs(now.getTime() - m.Last_QA_Date_Time__c.getTime()) < 10000);
        System.assertEquals(UserInfo.getUserId(), m.Last_QAed_By__c);

        m = newMap.values()[4];
        System.assert(Math.abs(now.getTime() - m.Last_QA_Date_Time__c.getTime()) < 10000);
        System.assertEquals(UserInfo.getUserId(), m.Last_QAed_By__c);
        //TODO: test variants

        m = newMap.values()[5];
        System.assert(Math.abs(now.getTime() - m.Last_QA_Date_Time__c.getTime()) < 10000);
        System.assertEquals(UserInfo.getUserId(), m.Last_QAed_By__c);

        m = newMap.values()[6];
        Long lastBlocked = now.addDays(-1).getTime();
        Long timeSpent = (Long) (1.75 * millisPerDay);
        Long diff = now.getTime() - lastBlocked + timeSpent;
        Long actual = (Long) (m.Time_Spent_in_Blocked_Days__c * millisPerDay);
        System.assert(Math.abs(diff - actual) < 10000);

        m = newMap.values()[7];
        System.assert(Math.abs(now.getTime() - m.Last_Escalation_Date_Time__c.getTime()) < 10000);

        m = newMap.values()[8];
        System.assert(Math.abs(now.getTime() - m.Last_Blocked_Date_Time__c.getTime()) < 10000);
        System.assertEquals('Status Reason;Historical Delay Reason', m.Historical_Delay_Reasons__c);

        m = newMap.values()[9];
        System.assert(Math.abs(now.getTime() - m.Initial_Preparation_Date_Time__c.getTime()) < 10000);
        System.assertEquals(UserInfo.getUserId(), m.Prepared_By__c);

        m = newMap.values()[10];
        System.assert(m.Last_Photo_Linking_Date_Time__c != null);
    }

    public static String incrementId(String id) {
        if(currentId >= 10){
            id = id.substring(0, id.length()-1);
        }
        return id + String.valueOf(currentId++);
    }

    /**
     * BZAP-9268: Update Parent Status and Status Reason
     */
    @IsTest
    public static void testUpdateParentStatusFiltered() {
        CDdMilestone milestone = new CDdMilestone();
        CDdMilestone.Context ctx = new CDdMilestone.Context();
        ctx.milestoneMap = new Map<Id, List<Milestone__c>>();
        ctx.parentMap = new Map<Id, Case>();
        ctx.parentIdFilter = new Set<Id>();

        CDdMilestoneTemplate.insertMilestoneTemplates();
        templateMap = CDdMilestoneSelector.templatesByParentTypeMap('Case');

        // 0) 2.a: Dead
        Id currentId = incrementId(caseId);
        ctx.parentIdFilter.add(currentId);
        ctx.parentMap.put(currentId, new Case(Id = currentId, Status = 'New'));
        ctx.milestoneMap.put(currentId, new List<Milestone__c>());
        for (Milestone_Template__c template : templateMap.values()) {
            Milestone__c m = milestone.initializeMilestone(template, 'Case__c', currentId);
            m.Status__c = 'Dead';
            m.Status_Reason__c = 'Fraud';
            ctx.milestoneMap.get(currentId).add(m);
        }

        // 1) 2.b: Blocked
        currentId = incrementId(caseId);
        ctx.parentIdFilter.add(currentId);
        ctx.parentMap.put(currentId, new Case(Id = currentId, Status = 'New'));
        ctx.milestoneMap.put(currentId, new List<Milestone__c>());
        for (Milestone_Template__c template : templateMap.values()) {
            Milestone__c m = milestone.initializeMilestone(template, 'Case__c', currentId);
            m.Status__c = 'Blocked';
            m.Status_Reason__c = 'Fraud';
            m.Status_Reason_Details__c = 'Fraudulent details.';
            ctx.milestoneMap.get(currentId).add(m);
        }

        // 2) 2.c: Escalated
        currentId = incrementId(caseId);
        ctx.parentIdFilter.add(currentId);
        ctx.parentMap.put(currentId, new Case(Id = currentId, Status = 'New'));
        ctx.milestoneMap.put(currentId, new List<Milestone__c>());
        for (Milestone_Template__c template : templateMap.values()) {
            Milestone__c m = milestone.initializeMilestone(template, 'Case__c', currentId);
            m.Status__c = 'Escalated';
            m.Status_Reason__c = 'Fraud';
            ctx.milestoneMap.get(currentId).add(m);
        }

        // 3) 2.d: Reopen
        currentId = incrementId(caseId);
        ctx.parentIdFilter.add(currentId);
        ctx.parentMap.put(currentId, new Case(Id = currentId, Status = 'Blocked'));
        ctx.milestoneMap.put(currentId, new List<Milestone__c>());
        for (Milestone_Template__c template : templateMap.values()) {
            Milestone__c m = milestone.initializeMilestone(template, 'Case__c', currentId);
            m.Status__c = 'In Progress';
            ctx.milestoneMap.get(currentId).add(m);
        }

        // 4) 2.d: Open
        currentId = incrementId(caseId);
        ctx.parentIdFilter.add(currentId);
        ctx.parentMap.put(currentId, new Case(Id = currentId, Status = 'Escalated'));
        ctx.milestoneMap.put(currentId, new List<Milestone__c>());
        for (Milestone_Template__c template : templateMap.values()) {
            Milestone__c m = milestone.initializeMilestone(template, 'Case__c', currentId);
            m.Status__c = 'In Progress';
            ctx.milestoneMap.get(currentId).add(m);
        }

        milestone.updateParentStatusFiltered(ctx);

        List<Case> parents = new List<Case>();
        for (SObject c : ctx.parentMap.values()) {
            parents.add((Case) c);
        }

        // 0) 2.a: Dead
        System.assertEquals('Dead', parents[0].Status);
        System.assertNotEquals(null, parents[0].Status_Reason__c);
        System.assertNotEquals(null, parents[0].Historical_Delay_Reasons__c);

        // 1) 2.b: Blocked
        System.assertEquals('Blocked', parents[1].Status);
        System.assertNotEquals(null, parents[1].Status_Reason__c);
        System.assertNotEquals(null, parents[1].Historical_Delay_Reasons__c);
        System.assertNotEquals(null, parents[1].Status_Reason_Details__c);

        // 2) 2.c: Escalated
        System.assertEquals('Escalated', parents[2].Status);
        System.assertNotEquals(null, parents[2].Status_Reason__c);
        System.assertEquals(null, parents[2].Historical_Delay_Reasons__c);

        // 3) 2.d.ii.2: Reopened/Blocked
        System.assertEquals('Reopened', parents[3].Status);
        System.assertEquals(null, parents[3].Status_Reason__c);
        System.assertEquals(null, parents[3].Historical_Delay_Reasons__c);

        // 4) 2.d.ii.3: Open/Escalated
        System.assertEquals('In Progress', parents[4].Status);
        System.assertEquals(null, parents[4].Status_Reason__c);
        System.assertEquals(null, parents[4].Historical_Delay_Reasons__c);
    }

    @IsTest
    public static void testInitializeCandidates() {
        CDdMilestoneTemplate.insertMilestoneTemplates();
        CDdMilestone milestone = new CDdMilestone();
        CDdMilestone.Context ctx = new CDdMilestone.Context();
        Id parentId = incrementId(caseId);
        Case c = new Case(Id = parentId, Status = 'Escalated', RecordTypeId = caseRecordTypeId);
        Map<Id, List<Milestone__c>> milestoneMap = new Map<Id, List<Milestone__c>>();
        Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');

        milestoneMap.put(parentId, new List<Milestone__c>());

        Milestone__c dead = milestone.initializeMilestone(templateByNameMap.get('Review & Triage'), 'Case__c', parentId);
        dead.Status__c = 'Dead';
        dead.Status_Reason__c = 'Fraud;SSMO Franchise';
        milestoneMap.get(parentId).add(dead);

        Milestone__c blocked = milestone.initializeMilestone(templateByNameMap.get('Setup Store'), 'Case__c', parentId);
        blocked.Status__c = 'Blocked';
        blocked.Status_Reason__c = 'Invalid Address';
        blocked.Historical_Delay_Reasons__c = 'Invalid Store Phone';
        milestoneMap.get(parentId).add(blocked);

        Milestone__c escalated = milestone.initializeMilestone(templateByNameMap.get(CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_INTEGRATION), 'Case__c', parentId);
        escalated.Status__c = 'Escalated';
        escalated.Status_Reason__c = 'POS Testing Error';
        escalated.Historical_Delay_Reasons__c = 'POS Ingestion Failure';
        milestoneMap.get(parentId).add(escalated);

        Milestone__c open = milestone.initializeMilestone(templateByNameMap.get(CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_INTEGRATION), 'Case__c', parentId);
        open.Status__c = 'In Progress';
        milestoneMap.get(parentId).add(open);

        ctx.milestoneMap = milestoneMap;
        milestone.initializeCandidates(ctx, c);

        System.assertEquals(4, ctx.candidateMap.get(parentId).size());

        List<String> expectedReasons = new List<String> { 'Fraud', 'SSMO Franchise', 'Invalid Address', 'POS Testing Error' };
        List<String> expectedHistorical = new List<String> { 'Fraud', 'SSMO Franchise', 'Invalid Address', 'POS Testing Error', 'Invalid Store Phone', 'POS Ingestion Failure' };

        Case candidateDead = (Case) ctx.candidateMap.get(parentId)[0];
        System.assertEquals('Dead', candidateDead.Status);
        System.assertEquals(expectedReasons, ((String) candidateDead.get('Status_Reason__c')).split(';'));
        System.assertEquals(expectedHistorical, ((String) candidateDead.get('Historical_Delay_Reasons__c')).split(';'));

        Case candidateBlocked = (Case) ctx.candidateMap.get(parentId)[1];
        System.assertEquals('Blocked', candidateBlocked.Status);
        System.assertEquals(expectedReasons, ((String) candidateBlocked.get('Status_Reason__c')).split(';'));
        System.assertEquals(expectedHistorical, ((String) candidateBlocked.get('Historical_Delay_Reasons__c')).split(';'));

        Case candidateEscalated = (Case) ctx.candidateMap.get(parentId)[2];
        System.assertEquals('Escalated', candidateEscalated.Status);
        System.assertEquals(expectedReasons, ((String) candidateEscalated.get('Status_Reason__c')).split(';'));
        System.assertEquals(null, candidateEscalated.get('Historical_Delay_Reasons__c'));

        Case candidateOpen = (Case) ctx.candidateMap.get(parentId)[3];
        System.assertEquals('In Progress', candidateOpen.Status);
        System.assertEquals(expectedReasons, ((String) candidateOpen.get('Status_Reason__c')).split(';'));
        System.assertEquals(null, candidateOpen.get('Historical_Delay_Reasons__c'));

        milestoneMap = new Map<Id, List<Milestone__c>>();
        milestoneMap.put(parentId, new List<Milestone__c>());

        Milestone__c reopened = milestone.initializeMilestone(templateByNameMap.get(CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_INTEGRATION), 'Case__c', parentId);
        reopened.Status__c = 'Escalated';
        reopened.Status_Reason__c = 'POS Testing Error';
        reopened.Historical_Delay_Reasons__c = 'POS Ingestion Failure';
        milestoneMap.get(parentId).add(open);
        ctx.milestoneMap = milestoneMap;

        c.Status = 'Blocked';
        milestone.initializeCandidates(ctx, c);

        System.assertEquals(1, ctx.candidateMap.get(parentId).size());
        System.assertEquals('Reopened', (String) ctx.candidateMap.get(parentId)[0].get('Status'));

        Milestone__c inrescue = milestone.initializeMilestone(templateByNameMap.get('Review & Triage'), 'Case__c', parentId);
        inrescue.Status__c = 'In Rescue';
        inrescue.Status_Reason__c = '1st Attempt';
        inrescue.Historical_Delay_Reasons__c = '1st Attempt';
        milestoneMap.get(parentId).add(inrescue);
        ctx.milestoneMap = milestoneMap;

        milestone.initializeCandidates(ctx, c);

        System.assertEquals(2, ctx.candidateMap.get(parentId).size());
        System.assertEquals('Dead', (String) ctx.candidateMap.get(parentId)[0].get('Status'));

        //Test for POS Integrations Record type
        Id posCaseId = incrementId(caseId);
        Case posCase = new Case(Id = posCaseId, Status = 'Escalated', RecordTypeId = casePosIntegrationsRT);
        milestoneMap.put(posCaseId, new List<Milestone__c>());

        Milestone__c inRescuePOS = milestone.initializeMilestone(templateByNameMap.get('Review & Triage'), 'Case__c', posCaseId);
        inRescuePOS.Status__c = 'In Rescue';
        inRescuePOS.Status_Reason__c = '1st Attempt';
        inRescuePOS.Historical_Delay_Reasons__c = '1st Attempt';
        milestoneMap.get(posCaseId).add(inRescuePOS);

        ctx.milestoneMap = milestoneMap;
        milestone.initializeCandidates(ctx, posCase);
        Case candidateRescue = (Case) ctx.candidateMap.get(posCaseId)[0];
        System.assertEquals('In Rescue', candidateRescue.Status);
    }

    private static Map<String, Milestone_Template__c> listToMap(List<Milestone_Template__c> sobjects, String keyField) {
        Map<String, Milestone_Template__c> sobjectMap = new Map<String, Milestone_Template__c>();
        for (Milestone_Template__c sobj : sobjects) {
            String key = (String) sobj.get(keyField);
            sobjectMap.put(key, sobj);
        }
        return sobjectMap;
    }

     /**
     * BZAP-13115: Test updateParentOwnerByMileStoneType
     */
    @IsTest
    public static void testUpdateParentOwnerByMileStoneType() {
        Test.startTest();
        setupData();
        CDdMilestoneTemplate.insertMilestoneTemplates();
        CDdMilestone milestone = new CDdMilestone();
        CDdMilestone.Context ctx = new CDdMilestone.Context();
        ctx.parentMap = new Map<Id, SObject>();
        ctx.parentIdFilter = new Set<Id>();
        Id parentId = incrementId(caseId);
        Id currentId = incrementId(milestoneId);

        List<Account> childAccounts = [Select Id from Account where RecordTypeId = :MARKETPLACE_RECORD_TYPE_ID];
        Case c = new Case(Id = parentId, Status = 'Escalated', AccountId = childAccounts[0].Id, RecordTypeId=CDdMilestone.CASE_MARKETPLACE_ONBOARDING_RT);
        ctx.parentMap.put(parentId, c);
        ctx.parentIdFilter.add(parentId);

        Map<Id, List<Milestone__c>> milestoneMap = new Map<Id, List<Milestone__c>>();
        Map<Id, Milestone__c> newMap = new Map<Id, Milestone__c>();
        Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');

        milestoneMap.put(parentId, new List<Milestone__c>());

        Milestone__c RTMileStone = milestone.initializeMilestone(templateByNameMap.get('Review & Triage'), 'Case__c', parentId);
        RTMileStone.Status__c = milestone.Complete;
        newMap.put(currentId,RTMileStone);
        milestoneMap.get(parentId).add(RTMileStone);

        Milestone__c SStoreMileStone = milestone.initializeMilestone(templateByNameMap.get('Setup Store'), 'Case__c', parentId);
        SStoreMileStone.Status__c = milestone.Complete;
        currentId = incrementId(milestoneId);
        newMap.put(currentId,SStoreMileStone);
        milestoneMap.get(parentId).add(SStoreMileStone);

        Milestone__c SBUMileStone = milestone.initializeMilestone(templateByNameMap.get('Setup Business'), 'Case__c', parentId);
        SBUMileStone.Status__c = milestone.Complete;
        currentId = incrementId(milestoneId);
        newMap.put(currentId,SBUMileStone);
        milestoneMap.get(parentId).add(SBUMileStone);

        ctx.milestoneMap = milestoneMap;
        ctx.newMap = newMap;

        Test.stopTest();
        milestone.updateParentOwnerByMileStoneType(ctx);

        Case caseRec = (Case) ctx.parentMap.get(parentId);
        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'QUEUE' AND DeveloperName= 'Onboarding_Business_Group_Creation'];
        System.assertNotEquals(null, caseRec);
        System.assertEquals(queues[0].Id, caseRec.OwnerId);
    }

    /**
     *  BZAP-15016: Test UpdateMilestoneStatuses for BAT Case Origin
     */
    @IsTest
    public static void testUpdateMilestoneStatusesFromBAT() {
        User testRunUser = makeMulesoftUser();
        Case testCase = getMulesoftInsertedCase(CDdMilestone.CASE_ORIGIN_BULK_TOOL_AUTOMATION);

        createMilestones(testRunUser, testCase);
        List<Milestone__c> milestoneListUpdated = [SELECT Id, Milestone_Type__c, Status__c, OwnerId, Case__r.Status FROM Milestone__c WHERE Case__c = :testCase.Id];

        System.assert(!milestoneListUpdated.isEmpty());
        verifyMilestoneStatusesAreUpdated(milestoneListUpdated, testCase);
    }

    // BZAP-19827 - POS Integration Milestone Updates from BAT for SSIO Case Origin
    @IsTest
    public static void testUpdateMilestoneStatusesFromSSIO() {
        User testRunUser = makeMulesoftUser();
        Case testCase = getMulesoftInsertedCase(CDdMilestone.CASE_ORIGIN_SSIO);

        createMilestones(testRunUser, testCase);
        List<Milestone__c> milestoneListUpdated = [SELECT Id, Milestone_Type__c, Status__c, OwnerId, Case__r.Status FROM Milestone__c WHERE Case__c = :testCase.Id];

        System.assert(!milestoneListUpdated.isEmpty());
        verifyMilestoneStatusesAreUpdated(milestoneListUpdated, testCase);
    }

     /**
     *  BZAP-16107 : Test ValidateAdsPromosMilestone
     */
    @isTest
    static void testValidateAdsPromosMilestone() {
        Test.startTest();
        setupData();
        Test.stopTest();
        Case testCase = [select Id from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];



        Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');

        List<Milestone__c> milestoneList = new List<Milestone__c>();

        Milestone__c adsPromos = new CDdMilestone().initializeMilestone(templateByNameMap.get('Ads & Promos'), 'Case__c', testCase.Id);
        milestoneList.add(adsPromos);

        insert milestoneList;
        milestoneList[0].Status__c = CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS;
        try {
            update milestoneList;
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(CDdMxSxConstants.MILESTONE_AD_PROMS_VALIDATION_MESSAGE));
        }
    }

    /**
     *  BZAP-16107 : Test completeMilestoneWithAdPromo
    */
    @isTest
    static void testcompleteMilestoneWithAdPromoe() {
        Test.startTest();
        setupData();
        Test.stopTest();
        Case testCase = [select Id from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];

        Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');

        List<Milestone__c> milestoneList = new List<Milestone__c>();

        Milestone__c adsPromos = new CDdMilestone().initializeMilestone(templateByNameMap.get('Ads & Promos'), 'Case__c', testCase.Id);
        milestoneList.add(adsPromos);

        insert milestoneList;
        milestoneList[0].Status__c = CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS;
        List<Milestone__c> milestones = CDdMilestoneSelector.milestonesByParentId(new Set<Id> { testCase.Id });
        System.assertNotEquals(0, milestones.size());

        testCase.OwnerId = UserInfo.getUserId();
        testCase.Stage__c = 'Ready for Activation';
        update testCase;

        for (Milestone__c milestone : milestones) {
            if(milestone.Milestone_Type__c == 'Activate Store'){
                milestone.Type__c = 'Self-Activation';
                milestone.Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE;
            }
        }
        update milestones;
        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'QUEUE' AND DeveloperName= 'Onboarding_Ads_Promos'];
        testCase = [select Id,OwnerId,Onboarding_Ads_and_Promo_Status__c from Case where RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];
        System.assertEquals(queues[0].Id, testCase.OwnerId);
        System.assertEquals(CDdMxSxConstants.ADS_AND_PROMO_STATUS_INCOMPLETE, testCase.Onboarding_Ads_and_Promo_Status__c);
    }

    /**
     * BASD-39912: Test updateParentOwnerByCompletedMileStoneType
     */
    @IsTest
    public static void testUpdateParentOwnerByCompletedMileStoneType() {
        CDdMilestoneTemplate.insertMilestoneTemplates();
        CDdMilestone milestone = new CDdMilestone();
        List<String> queueNames = new List<String> {'Hibernated POS Providers','Suspended POS Providers'};
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);
        Id hibernatedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Hibernated POS Providers');
        Id suspendedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Suspended POS Providers');

        CDdMilestone.Context ctx = new CDdMilestone.Context();
        ctx.parentMap = new Map<Id, SObject>();
        ctx.parentIdFilter = new Set<Id>();
        Id parentId = incrementId(caseId);
        Id currentId = incrementId(milestoneId);
        String Onboarding_POS_Queue_Ids = CDdNameValuePairHelper.getTextValue('Onboarding_POS_Queue_Ids');
        List<String> queues = Onboarding_POS_Queue_Ids.split(',');


        Group testGroup1 = new Group(Name='Onboarding - POS', Type='Queue');
        insert testGroup1;
        Group testGroup2 = new Group(Name='Onboarding - POS Integrations', Type='Queue');
        insert testGroup2;
        Group testGroup3 = new Group(Name='ENT Onboarding - Under Review', Type='Queue');
        insert testGroup3;
        Group testGroup4 = new Group(Name='Suspended POS Providers', Type='Queue');
        insert testGroup4;
        Group testGroup5 = new Group(Name='Hibernated POS Providers', Type='Queue');
        insert testGroup5;

        Case c = new Case(Id = parentId, Status = 'In Progress', OwnerId = queues[0], RecordTypeId=CDdMilestone.CASE_MARKETPLACE_ONBOARDING_RT,POS_Integration_Type__c = 'aldelo');

        ctx.parentMap.put(parentId, c);
        ctx.parentIdFilter.add(parentId);

        Map<Id, List<Milestone__c>> milestoneMap = new Map<Id, List<Milestone__c>>();
        Map<Id, Milestone__c> newMap = new Map<Id, Milestone__c>();
        Map<Id, Milestone__c> oldMap = new Map<Id, Milestone__c>();
        Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');

        milestoneMap.put(parentId, new List<Milestone__c>());

        Milestone__c RTMileStone = milestone.initializeMilestone(templateByNameMap.get('Review & Triage'), 'Case__c', parentId);
        RTMileStone.Status__c = milestone.In_Progress;
        RTMileStone.Id = currentId;
        oldMap.put(currentId,RTMileStone);
        Milestone__c RTMileStone1 = milestone.initializeMilestone(templateByNameMap.get('Review & Triage'), 'Case__c', parentId);
        RTMileStone1.Status__c = milestone.Complete;
        RTMileStone1.Id = currentId;
        newMap.put(currentId,RTMileStone1);
        milestoneMap.get(parentId).add(RTMileStone);
        milestoneMap.get(parentId).add(RTMileStone1);

        Milestone__c SStoreMileStone = milestone.initializeMilestone(templateByNameMap.get('Setup Store'), 'Case__c', parentId);
        SStoreMileStone.Status__c = milestone.In_Progress;
        currentId = incrementId(milestoneId);
        SStoreMileStone.Id = currentId;
        oldMap.put(currentId,SStoreMileStone);
        Milestone__c SStoreMileStone1 = milestone.initializeMilestone(templateByNameMap.get('Setup Store'), 'Case__c', parentId);
        SStoreMileStone1.Status__c = milestone.Complete;
        SStoreMileStone1.Id = currentId;
        newMap.put(currentId,SStoreMileStone1);
        milestoneMap.get(parentId).add(SStoreMileStone);
        milestoneMap.get(parentId).add(SStoreMileStone1);

        Milestone__c SBUMileStone = milestone.initializeMilestone(templateByNameMap.get('Setup Business'), 'Case__c', parentId);
        SBUMileStone.Status__c = milestone.In_Progress;
        currentId = incrementId(milestoneId);
        SBUMileStone.Id = currentId;
        oldMap.put(currentId,SBUMileStone);
        Milestone__c SBUMileStone1 = milestone.initializeMilestone(templateByNameMap.get('Setup Business'), 'Case__c', parentId);
        SBUMileStone1.Status__c = milestone.Complete;
        SBUMileStone1.Id = currentId;
        newMap.put(currentId,SBUMileStone1);
        milestoneMap.get(parentId).add(SBUMileStone);
        milestoneMap.get(parentId).add(SBUMileStone1);

        Milestone__c GPAMileStone = milestone.initializeMilestone(templateByNameMap.get('Grant Portal Access'), 'Case__c', parentId);
        GPAMileStone.Status__c = milestone.In_Progress;
        currentId = incrementId(milestoneId);
        GPAMileStone.Id = currentId;
        oldMap.put(currentId,GPAMileStone);
        Milestone__c GPAMileStone1 = milestone.initializeMilestone(templateByNameMap.get('Grant Portal Access'), 'Case__c', parentId);
        GPAMileStone1.Status__c = milestone.Complete;
        GPAMileStone1.Id = currentId;
        newMap.put(currentId,GPAMileStone1);
        milestoneMap.get(parentId).add(GPAMileStone);
        milestoneMap.get(parentId).add(GPAMileStone1);

        Milestone__c SBMileStone = milestone.initializeMilestone(templateByNameMap.get('Setup Banking'), 'Case__c', parentId);
        SBMileStone.Status__c = milestone.In_Progress;
        currentId = incrementId(milestoneId);
        SBMileStone.Id = currentId;
        oldMap.put(currentId,SBMileStone);
        Milestone__c SBMileStone1 = milestone.initializeMilestone(templateByNameMap.get('Setup Banking'), 'Case__c', parentId);
        SBMileStone1.Status__c = milestone.Complete;
        SBMileStone1.Id = currentId;
        newMap.put(currentId,SBMileStone1);
        milestoneMap.get(parentId).add(SBMileStone);
        milestoneMap.get(parentId).add(SBMileStone1);



        ctx.milestoneMap = milestoneMap;
        ctx.newMap = newMap;
        ctx.oldMap = oldMap;


        Test.startTest();
        milestone.updateParentOwnerByCompletedMileStoneType(ctx);
        Test.stopTest();

        Case caseRec = (Case) ctx.parentMap.get(parentId);

        System.assertNotEquals(null, caseRec);
        System.assertEquals(suspendedPOSProvidersQueueId, caseRec.OwnerId);
    }

    // Initializes a Case of a specified Origin - helper method for Milestone automation from Mulesoft
    private static Case getMulesoftInsertedCase(String origin) {
        Case testCase = TDdCaseFactory.createSolveableSupportCase(1,CDdRecordTypeCase.posIntegrations())[0];
        testCase.Status = 'Open';
        testCase.Stage__c = 'Under Review';
        testCase.Origin = origin;
        testCase.Issue__c = '';

        return testCase;
    }

    // Initializes User with Mulesoft Name
    private static User makeMulesoftUser() {
        Id TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        User testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
        testRunUser.FirstName = 'Mulesoft';
        testRunUser.LastName = 'Integration User';

        return testRunUser;
    }

    // Helper method for Milestone automation from Mulesoft
    // For a specified User and specified POS Integrations Case, create set of Milestones.
    private static void createMilestones(User testRunUser, Case testCase) {
        System.runAs(testRunUser){
            setupData();
            Test.startTest();
            insert testCase ;

            Map<String, Milestone_Template__c> templateByNameMap = new Map<String, Milestone_Template__c>();
            List<Milestone_Template__c> milestoneTemplates = CDdMilestoneSelector.templatesByParentTypeMap('Case').values();
            for(Milestone_Template__c template : milestoneTemplates){
                if(template.Parent_Object_Record_Type_ID_18__c == CDdRecordTypeCase.posIntegrations()){
                    templateByNameMap.put(template.Milestone_Type__c, template);
                }
            }

            List<Milestone__c> milestoneList = new List<Milestone__c>();
            Milestone__c asMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Complete pre-work'), 'Case__c', testCase.Id);
            Milestone__c smMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Configure POS'), 'Case__c', testCase.Id);
            Milestone__c posMenuPreviewLinkSent = new CDdMilestone().initializeMilestone(templateByNameMap.get('QA Menu'), 'Case__c', testCase.Id);
            milestoneList.add(asMileStone);
            milestoneList.add(smMileStone);
            milestoneList.add(posMenuPreviewLinkSent);

            insert milestoneList;
            Test.stopTest();
        }
    }

    // Helper method for Milestone Status automation scenarios
    private static void verifyMilestoneStatusesAreUpdated(List<Milestone__c> milestoneListUpdated, Case testCase) {
        for(Milestone__c thisMilestone : milestoneListUpdated) {
            if(CDdMilestone.POS_BULK_MILESTONE_TYPES_CLOSED.contains(thisMilestone.Milestone_Type__c)){
                System.assertEquals(CDdMxSxConstants.MILESTONE_STATUS_COMPLETE, thisMilestone.Status__c);
                System.assertEquals(CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS, thisMilestone.Case__r.Status);
                if(CDdUtilities.idIsUser(testCase.OwnerId)) {
                    System.assertEquals(testCase.OwnerId, thisMilestone.OwnerId);
                }
            }
        }
    }
}