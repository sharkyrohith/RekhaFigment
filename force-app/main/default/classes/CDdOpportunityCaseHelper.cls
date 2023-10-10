/*
* @Author Jeegar
* @Date March 2020
* @description A helper class to create cases for Opportunities where cases need to be created
*
* Refactoring to do:
*   RecordTypeIds variables were created below to utiltize CDdGenericTriggerOptimizationHelper.cls
*     Action: initialize Case records using the new variables
*   Queue queries: variables were created for Queue DEV Names in old code
*     Action: Leverage CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(). Entries in Id_Metadata__mdt could be retired
*   defaultBusinessHoursId was created using CDdGenericTriggerOptimizationHelper.getDefaultBusinessHour()
*     Action: replace defaultBusinessHoursId with defaultBusinessHoursId in old code
*     Action: consider creating a checkbox and leveraging this Custom Settings for each feature method in this class
*   Leverage CDdSupportConstants for text constants in old code (Origin, Stage__c, country names,...)
*
* Improvements to be considered:
*   Avoiding calling the same matches() calls twice in createCases() by creating another structure to store the outcode of matches(), by opp
*/
public class CDdOpportunityCaseHelper {

    public class LogicException extends Exception {}

    // Deprecate these as part of Class refactoring

    public static final Id tabletRequestCaseRTId = CDdSchemaUtils.CASE_RT.tabletRequestsId();
    public static final Id omHandoffCaseRTId = CDdSchemaUtils.CASE_RT.onboardingManagerHandoffId();

    public static final Id mxMarketingRequestRTID = CDdSchemaUtils.CASE_RT.mxMarketingRequestsId();

    public static final Id driveActivationCaseRTId = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Case','Drive_Activation_Case');

    public static final Id oppMarketPlaceRTId = CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId();
    public static final Id oppDoorDashDriveRTId = CDdSchemaUtils.OPPORTUNITY_RT.doorDashDriveId();
    public static final Id oppEnterpriseDriveRTId = CDdSchemaUtils.OPPORTUNITY_RT.enterpriseDriveId();
    public static final Id oppEnterpriseMarketplaceRTId = CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId();
    public static final Id oppCorporateRTId = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Opportunity','Corporate');

    // Please use the below way to retrieve RT Ids going forward
    public static final Id caseTabletRequestRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Tablet_Requests');
    public static final Id caseOmHandoffRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Onboarding_Manager_Handoff');
    public static final Id caseMxMarketingRequestRTID = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Mx_Marketing_Requests');
    public static final Id caseCaviarOnboardingRTID = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Caviar_Onboarding');
    public static final Id caseDriveActivationRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Drive_Activation_Case');
    public static final Id casePosIntegrationsRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('POS_Integrations');
    public static final Id casePhotoshootProcessingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Photoshoot_Processing');
    public static final Id opptyCorporateRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Corporate');
    public static final Id opptyDoorDashDriveRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('DoorDash_Drive');
    public static final Id opptyEnterpriseDriveRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Enterprise_Drive');
    public static final Id opptyPostSaleRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Post_Sale');
    public static final Id opptyMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('ML_Inside_Sales');
    public static final Id opptyEnterpriseMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Enterprise_Marketplace');
    public static final Id opptyCorporateApprovedRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Corporate_Approved');

    // Queue Dev Names
    public static final String QUEUE_CAVIAR_ONBOARDING_TEAM = 'Caviar_Onboarding_Team';
    public static final String QUEUE_DRIVE_MANUAL_ACTIVATIONS = 'Drive_Manual_Activations';
    public static final String QUEUE_ENT_ONBOARDING_UNDER_REVIEW = 'ENT_Onboarding_Under_Review';
    public static final String QUEUE_ONBOARDING_MANAGER = 'Onboarding_Manager_Queue';
    public static final String QUEUE_ONBOARDING_UNDER_REVIEW = 'Onboarding_Under_Review';
    public static final String QUEUE_POS_INTEGRATION_REQUESTS = 'POS_Integration_Requests';
    @testvisible
    private static final String QUEUE_ACTIVATIONS_LAB = 'Activations_Lab';
    @testvisible
    private static final String QUEUE_ONBOARDING_SSMO_SQUARE_POS = 'Onboarding_SSMO_Square_POS';

    public static final Id selfServIntegrationUser = [SELECT Id, Name, alias FROM User WHERE alias = 'selfserv'].Id;
    public static final Id mulesoftIntegrationUser = [SELECT Id, Name, alias FROM User WHERE alias = 'mule'].Id;
    public static Boolean isMarketplaceOnboardingEnabled = !CDdCustomMetadata.isDisabled('CDdOpportunityCaseHelper_marketplaceOnbo');
    private static Map<String, String> tabletKitTypeMap;

    public static Id runningUser;
    // Deprecate businessHoursId as part of class refactoring
    public static Id businessHoursId;
    // Use this business hours going forward
    public static Id defaultBusinessHoursId;
    public static List<String> menuOrderProtocols;
    public static List<String> tabletOrderProtocols;
    public static List<String> excludedBusinessIDs;
    public static Map<String, Id> queueIdByDeveloperName;

    private static Map<Id, Id> marketplaceCasesByOpportunities;

    public static final String DOORDASH_APEXADMIN = Label.User_DoorDash_ApexAdmin;

    public enum Criteria {
            Create_Onboarding_Manager_Case,
            Marketplace_Onboarding,
            Non_Tablet_Non_Return_Kits,
            Tablet_Requests,
            Drive_Activation_Case,
            Corporate_Drive_Products,
            Post_Sales_Protocol_Change_POS,
            Caviar_Onboarding_Flow
            }

    static {    // Create the reference data required for processing Opportunities
        runningUser = UserInfo.getUserId();
        Opportunity_Case_Metadata__mdt oppCaseMetadata = [
            SELECT DeveloperName, Id,
            Label, MasterLabel, NamespacePrefix, QualifiedApiName, Excluded_Business_IDs__c,
            Activations_Business_Hours_Id__c, Tablet_Order_Protocols__c, Menu_Order_Protocols__c
            FROM Opportunity_Case_Metadata__mdt
            WHERE DeveloperName = 'Default'
        ][0];
        // Deprecate this as part of class refactoring
        businessHoursId = Id.valueOf(oppCaseMetadata.Activations_Business_Hours_Id__c);
        // Use this one going forward
        defaultBusinessHoursId = CDdGenericTriggerOptimizationHelper.getDefaultBusinessHour() == null ?
                                 null : CDdGenericTriggerOptimizationHelper.getDefaultBusinessHour().Id;
        // create a list of string from ; delimited strings in the custom metadata.
        menuOrderProtocols = oppCaseMetadata.Menu_Order_Protocols__c.split(';');
        tabletOrderProtocols = oppCaseMetadata.Tablet_Order_Protocols__c.split(';');
        excludedBusinessIDs = oppCaseMetadata.Excluded_Business_IDs__c.split(';');
        queueIdByDeveloperName = new Map<String, Id>();
        List<Id_Metadata__mdt> idMetadataList = [
            SELECT Category__c, DeveloperName, Id, Id__c, Label, Language, MasterLabel, NamespacePrefix, QualifiedApiName
            FROM Id_Metadata__mdt
            WHERE DeveloperName LIKE 'Queue%'
        ];
        for (Id_Metadata__mdt idMetadata : idMetadataList) queueIdByDeveloperName.put(idMetadata.DeveloperName, idMetadata.Id__c);


        List<String> queueNames = new List<String> {
            QUEUE_CAVIAR_ONBOARDING_TEAM,
            QUEUE_DRIVE_MANUAL_ACTIVATIONS,
            QUEUE_ENT_ONBOARDING_UNDER_REVIEW,
            QUEUE_ONBOARDING_MANAGER,
            QUEUE_ONBOARDING_UNDER_REVIEW,
            QUEUE_POS_INTEGRATION_REQUESTS,
            QUEUE_ACTIVATIONS_LAB,
            QUEUE_ONBOARDING_SSMO_SQUARE_POS
        };
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);
    }

    public class DMLtodo {  // Used in order to synchronize the DML required when creating cases
        Case caseToInsert;
        Account accountToUpdate;
        Opportunity opportunityToUpdate;
        public DMLtodo(Case newCase) {  system.debug('CDdOpportunityCaseHelper.DMLtoto: Adding case to DMLtodo list: ' + newCase);
                                      caseToInsert = newCase;
                                      accountToUpdate = null;
                                      opportunityToUpdate = null;
                                     }
    }

    /*
* @Author Knick
* @Date March 2020
* @description Query all of the pertinent data on the opportunity and related records so that we can make a good assessment.
*/
    public static List<Opportunity> queryRelatedData(List<Id> opportunityIdList) {
        return [
            SELECT Id, Name, AccountId, Activation_Date__c, Bulk_Activation__c, Activation_Case_Created__c,GTMI_Initiative_Name__c,
            Caviar_Activation_Fee__c, Caviar_Offer_Document_URL__c, Caviar_Onboarding_Case_Created__c, Caviar_Onboarding_Type__c, Caviar_Order_Protocol__c, Caviar_Service_Region__c,
            Commission__c, Order_Protocol__c, Decision_Maker__c, Decision_Maker__r.FirstName, Decision_Maker__r.LastName, Account.OwnerId,
            DM_Email__c, DM_Email2__c, DM_Phone_Numbers__c, In_App_Pickup_Commission__c,
            Menu_PDF_Attached__c, Menu_URL__c, Merchant_Signed_with_Exclusivity__c, Notes__c, Notes_for_Menu_Team__c, Order_Service_Type__c,
            OwnerId, Owner.FirstName, Owner.LastName, POS_Integration_Type__c, POS_Fallback_Protocol__c, Account.Launch_Deck_Rank__c,
            POS_Integration_Id__c, Previous_Order_Protocol__c, Proposed_Date_of_Activation__c, RecordTypeId, Restaurant_Address__c,
            Store_Id__c, Store_Phone_Number__c, Account.Deck_Rank__c, Tablet_Case_Created__c,
            Tablet_Delivery_Method__c, StageName, Region_Type__c, Needs_Evening_Delivery__c, Lead_Source_Detail__c,
            Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingStreet, Account.BillingCountryCode,
            Account.BillingPostalCode, Account.Caviar_Presale_Tier__c, Account.Caviar_Service_Region__c, Shipping__c, Submarket__c, IsClosed, IsWon, CloseDate,
            Account.ParentId, Account.Parent.PM_transfer_case_created__c, Account.Business_ID_text__c, Account.Parent.Requesting_Account_Management__c,
            Requesting_Account_Management__c, Account.Market_Maker__c, Account.Name,
            Account.Parent.Merchant_Special_Requests__c, Decision_Maker__r.Email, Platform__c,
            Account.Kanji_City__c,Account.Kanji_State__c,Account.Kanji_Street__c,Account.Kanji_Zip__c,Account.Kanji_Country__c,
            Integration__c, Nimda_Setup_Required__c, Mx_Marketing_Request_created__c, Send_Marketing_Kit__c,
            Local_Team_Working_on_Menu__c, Case_Created__c, Type, Account.Lead_Type__c, Account.Phone,
            Account.Account_Type__c, Account.Is_Test_Store__c, Account.RecordTypeId, Account.Parent.Deck_Rank__c,
            Account.Address_Latitude__c, Account.Address_Longitude__c, Account.Address_Time_Zone__c, Account.Address_UTC_Offset__c,
            Photoshoot_Date__c, Photoshoot_Time__c, Account.PhotoshootCaseCreated__c, Account.RealZip__RealZip__c,
            Account.RealZip__RealZip__r.Submarket_lookup__c, Account.RealZip__RealZip__r.Submarket_lookup__r.Region__c,
            Store_Manager__c, CreatedById, Account.Order_Protocol__c, Tablet_Kit_Type__c, Automation_Status__c,
            Account.RealZip__RealZip__r.Submarket_lookup__r.Photoshoot_Vendor__c, Account.Primary_Merchant_Category__c,
            (SELECT Id, Name, OpportunityId, PricebookEntryId, PricebookEntry.Product2.Name, PricebookEntry.Product2.Family
             FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id IN :opportunityIdList
            FOR UPDATE
        ];
    }

    /*
* @Author Knick
* @Date May 2020
* @description Entry point for Batch Process.
*/
    public static void checkCases(List<Id> oppIds) {
        List<Opportunity> Opps = queryRelatedData(oppIds);
        createCases(Opps, null);
    }

    public static Set<Id> createdCases = new Set<Id>();
    public static Boolean processedCaseDMLlist = false;
    /*
* @Author Knick
* @Date March 2020
* @description Main entry point for creating Cases. Calls future method if not already in batch/future/queueable/scheduled context.
*/
    public static void createCases(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.WARN, 'CDdOpportunityCaseHelper.createCases');
        if (CDdCustomMetadata.isDisabled('CDdOpportunityCaseHelper_createCases')) {
            System.debug(LoggingLevel.WARN, 'CDdOpportunityCaseHelper.createCases: isDisabled');
            return;
        }

        if (processedCaseDMLlist) { // Recursion Check (Inserting Cases causes an Update to the Opportunity)
            System.debug(LoggingLevel.WARN, 'CDdOpportunityCaseHelper.createCases: processedCaseDMLlist: ' + processedCaseDMLlist);
            return;
        }
        List<Id> oppIdList = new List<Id>();  for (Opportunity opp : newList)  oppIdList.add(opp.Id);
        List<Opportunity> OppsToProcess = new List<Opportunity>();
        for (Opportunity opp : queryRelatedData(oppIdList)) {
            System.debug('CDdOpportunityCaseHelper.createCases: opp: ' + opp.Id);

            if (opp.Account.Is_Test_Store__c) continue;     // BZAP-8611 Prevent Cases for Test Accounts

            if ((matches(opp, Criteria.Tablet_Requests)) ||
                (matches(opp, Criteria.Non_Tablet_Non_Return_Kits)) ||
                (matches(opp, Criteria.Create_Onboarding_Manager_Case)) ||
                (matches(opp, Criteria.Drive_Activation_Case)) ||
                (matches(opp, Criteria.Corporate_Drive_Products)) ||
                (matches(opp, Criteria.Marketplace_Onboarding)) ||
                (matches(opp, Criteria.Post_Sales_Protocol_Change_POS)) ||
                (matches(opp, Criteria.Caviar_Onboarding_Flow))
                )
            {
                if (!createdCases.contains(opp.Id)) {
                    if (test.isRunningTest()) {
                        if ((opp.Name != 'TEST: <BATCH>') || (System.isBatch())) {  // Test the Batch records in Batch
                            createdCases.add(opp.Id);
                            OppsToProcess.add(opp);
                        }
                    }
                    else {
                        createdCases.add(opp.Id);
                        OppsToProcess.add(opp);
                    }
                }
            }
        }

        System.debug('CDdOpportunityCaseHelper.createCases: OppsToProcess: ' + OppsToProcess.size());

        if (OppsToProcess.size() > 0) {
            // TODO: check Max DailyAsyncApexExecutions using OrgLimits.getMap().get('DailyAsyncApexExecutions').getLimit();
            // TODO: [select count() from AsyncApexJob where CreatedDate >= :Datetime.now().addHours(-24) and JobType = 'Future'];
            // NOTE: In order to compare these, it costs a query = Maybe we should put the result somewhere (platform event) / utility?
            if (System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled()) {
                System.debug('CDdOpportunityCaseHelper.createCases: isAsync = true');
                processOpps(OppsToProcess);
            } else {
                System.debug('CDdOpportunityCaseHelper.createCases: isAsync = false');
                List<Id> opportunityIdList = new List<Id>();
                for (Opportunity o : OppsToProcess) {
                    opportunityIdList.add(o.Id);
                }
                System.debug('CDdOpportunityCaseHelper.createCases: opportunityIdList: ' + opportunityIdList.size());
                if (opportunityIdList.size() > 0) {
                    createCases(opportunityIdList);
                }
            }
        }
    }

    @future(callout=true)
    public static void createCases(List<Id> opportunityIdList) {
        System.debug('CDdOpportunityCaseHelper.createCases (future)');
        if (CDdCustomMetadata.isDisabled('CDdOpportunityCaseHelper_createCases')){
            System.debug(LoggingLevel.WARN, 'CDdOpportunityCaseHelper.createCases: isDisabled');
            return;
        }

        List<Opportunity> opportunitiesToProcess = queryRelatedData(opportunityIdList);
        System.debug('CDdOpportunityCaseHelper.createCases, opportunitiesToProcess: ' + opportunitiesToProcess.size());

        if (opportunitiesToProcess.size() > 0) {
            processOpps(opportunitiesToProcess);
        }
    }

    public static void processOpps(List<Opportunity> opportunitiesToProcess) {
        System.debug('CDdOpportunityCaseHelper.processOpps');
        List<DMLtodo> dmlList = new List<DMLtodo>();
        for(Opportunity currOpp : opportunitiesToProcess) {
            System.debug('CDdOpportunityCaseHelper.processOpps, opp: ' + currOpp.Id);
            if (currOpp.Account.Is_Test_Store__c) continue;     // BZAP-8611 Prevent Cases for Test Accounts

            /* Knick - START Create Tablet Case / Mx Marketing Case for Partners */
            if (matches(currOpp, Criteria.Tablet_Requests)) {
                DMLtodo entry = new DMLtodo(createTabletCase(currOpp, businessHoursId, tabletRequestCaseRTId));
                entry.opportunityToUpdate = new Opportunity(Id = currOpp.Id, Tablet_Case_Created__c = true);
                dmlList.add(entry);
            }
            else if (matches(currOpp, Criteria.Non_Tablet_Non_Return_Kits)) {
                DMLtodo entry = new DMLtodo(createMxMarketingRequestCase(currOpp, businessHoursId, mxMarketingRequestRTID));
                entry.opportunityToUpdate = new Opportunity(Id = currOpp.Id, Mx_Marketing_Request_created__c = true);
                dmlList.add(entry);
            }
            /* Knick -  END  Create Tablet Case / Mx Marketing Case for Partners */

            /* Knick - START Post Sale Handoff Case */
            if (matches(currOpp, Criteria.Create_Onboarding_Manager_Case)) {
                Id queueId = queueIdByDeveloperName.get('Queue_Onboarding_Manager');
                DMLtodo entry = new DMLtodo(createCommonCase(currOpp, businessHoursId, omHandoffCaseRTId, queueId, 'Onboarding Manager Handoff Case'));
                entry.accountToUpdate = new Account(Id = currOpp.Account.ParentId, PM_transfer_case_created__c = true);
                dmlList.add(entry);
            }
            /* Knick -  END  Post Sale Handoff Case */

            /* BEGIN - BZAP-9025 - Create Drive Activation Case */
            if (matches(currOpp, Criteria.Drive_Activation_Case) || matches(currOpp, Criteria.Corporate_Drive_Products)) {
                Id queueId = queueIdByDeveloperName.get('Queue_Drive_Manual_Activations');
                DMLtodo entry = new DMLtodo(createDriveActivationCase(currOpp, businessHoursId, driveActivationCaseRTId, queueId));
                entry.opportunityToUpdate = new Opportunity(Id = currOpp.Id, Activation_Case_Created__c = true);
                dmlList.add(entry);
            }
            /* END - BZAP-9025 - Create Drive Activation Case */

            if (matches(currOpp, Criteria.Marketplace_Onboarding)) {
                DMLtodo entry = new DMLtodo(createMarketplaceOnboardingCase(currOpp));
                entry.opportunityToUpdate = new Opportunity(Id = currOpp.Id, Case_Created__c = true);
                dmlList.add(entry);
            }
            if (matches(currOpp, Criteria.Post_Sales_Protocol_Change_POS)) {
                // Do a one-time retrieval of Marketplace Case Ids by their related Opportunities
                setRelatedMarketplaceOnboardingCaseIdsForOpportunities(opportunitiesToProcess);
                
                Id queueId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_POS_INTEGRATION_REQUESTS);
                DMLtodo entry = new DMLtodo(postSaleProtocolChangePOSCase(currOpp, defaultBusinessHoursId, queueId));
                entry.opportunityToUpdate = new Opportunity(Id = currOpp.Id, Activation_Case_Created__c = true);
                dmlList.add(entry);
            }
            if (matches(currOpp, Criteria.Caviar_Onboarding_Flow)) {
                DMLtodo entry = new DMLtodo(caviarOnboardingFlow(currOpp, defaultBusinessHoursId));
                entry.opportunityToUpdate = new Opportunity(Id = currOpp.Id, Caviar_Onboarding_Case_Created__c = true);
                dmlList.add(entry);
            }
        }

        System.debug('CDdOpportunityCaseHelper.processOpps: DMLtodo (' + dmlList.size() + '): ' + dmlList);
        if (dmlList.size() > 0) {
            Savepoint sp = Database.setSavepoint();
            List<Case> casesToInsert = new List<Case>();
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
            Map<Id, Opportunity> opportunitiesToUpdate = new Map<Id, Opportunity>();
            List<Apex_Log__c> errorsToLog = new List<Apex_Log__c>();
            for (DMLtodo entry : dmlList) casesToInsert.add(entry.caseToInsert);
            system.debug('CDdOpportunityCaseHelper.processOpps: DMLtodo: saving cases: ' + casesToInsert);
            processedCaseDMLlist = true;    // Prevent Recursion
            Database.SaveResult[] results = Database.insert(casesToInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    if (dmlList[i].accountToUpdate != null) {
                        Account existing = accountsToUpdate.get(dmlList[i].accountToUpdate.Id);
                        if (existing == null) existing = dmlList[i].accountToUpdate;
                        else {
                            if (dmlList[i].accountToUpdate.PM_transfer_case_created__c != null)
                                existing.PM_transfer_case_created__c = dmlList[i].accountToUpdate.PM_transfer_case_created__c;
                            if (dmlList[i].accountToUpdate.PhotoshootCaseCreated__c != null)
                                existing.PhotoshootCaseCreated__c = dmlList[i].accountToUpdate.PhotoshootCaseCreated__c;
                        }
                        accountsToUpdate.put(existing.Id, existing);
                    }
                    if (dmlList[i].opportunityToUpdate != null) {
                        Opportunity existing = opportunitiesToUpdate.get(dmlList[i].opportunityToUpdate.Id);
                        if (existing == null) existing = dmlList[i].opportunityToUpdate;
                        else {
                            if (dmlList[i].OpportunityToUpdate.Case_Created__c == true)
                                existing.Case_Created__c = true;
                            if (dmlList[i].OpportunityToUpdate.Activation_Case_Created__c == true)
                                existing.Activation_Case_Created__c = true;
                            if (dmlList[i].OpportunityToUpdate.Tablet_Case_Created__c == true)
                                existing.Tablet_Case_Created__c = true;
                            if (dmlList[i].OpportunityToUpdate.Mx_Marketing_Request_created__c == true)
                                existing.Mx_Marketing_Request_created__c = true;
                            if (dmlList[i].OpportunityToUpdate.Caviar_Onboarding_Case_Created__c == true)
                                existing.Caviar_Onboarding_Case_Created__c = true;
                        }
                        opportunitiesToUpdate.put(existing.Id, existing);
                    }
                }
                else {
                    String logMessage = 'Unable to create case';
                    if (System.isBatch()) logMessage += ' from batch';
                    logMessage += ': ' + casesToInsert[i];
                    for(Database.Error err : results[i].getErrors())
                        logMessage += ' (status code: ' + err.getStatusCode() + ') ' + err.getMessage();
                    errorsToLog.add(new Apex_Log__c(Class_Name__c = 'CDdOpportunityCaseHelper', Method_Name__c = 'createCases',
                                                    Log__c = logMessage, Log_Level__c = 'Error'
                                                   ));
                    System.debug(LoggingLevel.ERROR, 'CDdOpportunityCaseHelper.createCases: ' + logMessage);
                }
            }
            if ((accountsToUpdate.size() > 0) || (opportunitiesToUpdate.size() > 0)) {
                system.debug('CDdOpportunityCaseHelper.processOpps: DMLtodo: updating accounts: ' + accountsToUpdate);
                system.debug('CDdOpportunityCaseHelper.processOpps: DMLtodo: updating opportunities: ' + opportunitiesToUpdate);
                try {
                    if (accountsToUpdate.size() > 0) update accountsToUpdate.values();
                    if (opportunitiesToUpdate.size() > 0) update opportunitiesToUpdate.values();
                }
                catch (Exception eX) {
                    system.debug(LoggingLevel.ERROR, 'CDdOpportunityCaseHelper.processOpps: DMLtodo: Exception: ' + eX);
                    errorsToLog.add(new Apex_Log__c(Class_Name__c = 'CDdOpportunityCaseHelper', Method_Name__c = 'createCases',
                                                    Log__c = 'Rolling Back - Unable to update required records: ' + eX.getMessage(), Log_Level__c = 'Error'
                                                   ));
                    Database.rollback(sp);
                }
            }
            if (errorsToLog.size() > 0) Database.insert(errorsToLog, false);
        }
    }

    public static void handleAsyncPhotoshootCase(List<Generic_Platform_Event__e> rollupEvents) {
        List<Id> opportunityIdList = new List<Id>();
        for (Generic_Platform_Event__e rollupEvent : rollupEvents) {
            opportunityIdList.add(rollupEvent.sObjectId__c);
        }
        List<Opportunity> opportunitiesToProcess = queryRelatedData(opportunityIdList);
        List<DMLtodo> dmlList = new List<DMLtodo>();

        for (Opportunity currOpp: opportunitiesToProcess) {
            // Additional check within the handler to prevent duplciate
            // cases.
            if (!currOpp.Account.PhotoshootCaseCreated__c) {
                DMLtodo entry = new DMLtodo(createPhotoshootCase(currOpp, defaultBusinessHoursId));
                entry.accountToUpdate = new Account(Id = currOpp.AccountId, PhotoshootCaseCreated__c = true);
                dmlList.add(entry);
            }
        }

        Savepoint sp = Database.setSavepoint();
        List<Case> casesToInsert = new List<Case>();
        for (DMLtodo entry : dmlList) casesToInsert.add(entry.caseToInsert);

        System.debug('CDdOpportunityCaseHelper.processOpps: DMLtodo: saving cases: ' + casesToInsert);
        Database.SaveResult[] results = Database.insert(casesToInsert, false);

        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        List<Apex_Log__c> errorsToLog = new List<Apex_Log__c>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                if (dmlList[i].accountToUpdate != null) {
                    Account existing = accountsToUpdate.get(dmlList[i].accountToUpdate.Id);
                    if (existing == null) existing = dmlList[i].accountToUpdate;
                    else {
                        if (dmlList[i].accountToUpdate.PhotoshootCaseCreated__c != null)
                            existing.PhotoshootCaseCreated__c = dmlList[i].accountToUpdate.PhotoshootCaseCreated__c;
                    }
                    accountsToUpdate.put(existing.Id, existing);
                }
                if ((accountsToUpdate.size() > 0)) {
                    system.debug('CDdOpportunityCaseHelper.processOpps: DMLtodo: updating accounts: ' + accountsToUpdate);
                    try {
                        if (accountsToUpdate.size() > 0) update accountsToUpdate.values();
                    }
                    catch (Exception eX) {
                        system.debug(LoggingLevel.ERROR, 'CDdOpportunityCaseHelper.processOpps: DMLtodo: Exception: ' + eX);
                        errorsToLog.add(new Apex_Log__c(Class_Name__c = 'CDdOpportunityCaseHelper', Method_Name__c = 'createCases',
                                                        Log__c = 'Rolling Back - Unable to update required records: ' + eX.getMessage(), Log_Level__c = 'Error'
                                                       ));
                        Database.rollback(sp);
                    }
                }
                if (errorsToLog.size() > 0) Database.insert(errorsToLog, false);
            }
        }
    }

    /*
* @author Knick
* @Date Mar 2020
* @Description: Check Criteria ...
*
*/
    public static Boolean matches(Opportunity opp, Criteria criteria) {
        if (criteria == null) return false;
        Boolean isMatch = false;

        switch on criteria {
            // NOTE: Tablet Requests includes the following Order Protocols:
            //  Tablet (Door Dash Owns), POS and Tablet (DoorDash Owns),
            //  Tablet and Printer (DoorDash Owns), POS and Tablet Return Label
            when Tablet_Requests {
                Set<String> previousOrderProtocols = new Set<String>{'Tablet (DoorDash Owns)',
                                                        'Tablet and Printer (DoorDash Owns)',
                                                        'POS and and Tablet (DoorDash Owns)'};
                if (((opp.RecordTypeId == opptyMarketplaceRTId || opp.RecordTypeId == opptyEnterpriseMarketplaceRTId)
                    && opp.Activation_Date__c == null
                    && opp.Tablet_Case_Created__c == false
                    && opp.Tablet_Delivery_Method__c != 'Local team drop-off'
                    && opp.Tablet_Delivery_Method__c != 'None - Use Existing Tablet'
                    && opp.StageName == 'Closed Won'
                    && opp.Region_Type__c == 'Live Region'
                    && opp.AccountId != null
                    && tabletOrderProtocols.contains(opp.Order_Protocol__c)
                   )
                   ||
                   (opp.RecordTypeId == opptyPostSaleRTId
                    && opp.StageName == 'Closed Won'
                    && String.isNotBlank(opp.Previous_Order_Protocol__c)
                    && opp.Tablet_Delivery_Method__c != 'Local team drop-off'
                    && !opp.Tablet_Case_Created__c
                    && (tabletOrderProtocols.contains(opp.Order_Protocol__c)
                        || previousOrderProtocols.contains(opp.Previous_Order_Protocol__c))
                    )) {
                    isMatch = true;
                   }
            }
            when Non_Tablet_Non_Return_Kits {
                if (opp.Activation_Date__c == null
                    && opp.StageName == 'Closed Won'
                    && opp.Region_Type__c == 'Live Region'
                    && opp.Mx_Marketing_Request_created__c == false
                    && opp.CloseDate >= Date.newInstance(2018, 09, 10)
                    && (opp.RecordTypeId != oppEnterpriseMarketplaceRTId
                        || opp.Send_Marketing_Kit__c == true
                       )
                    && opp.AccountId != null
                    && opp.Order_Protocol__c != null
                    && !tabletOrderProtocols.contains(opp.Order_Protocol__c) // NOT Tablet Requests
                    && (opp.Account.Business_ID_text__c == null || !excludedBusinessIDs.contains(opp.Account.Business_ID_text__c))
                    // && !excludedBusinessIDs.contains(opp.Account.Business_ID_text__c)
                    && opp.Platform__c != 'Caviar'                          // new per Becky
                   )
                    isMatch = true;
            }
            when Create_Onboarding_Manager_Case {
                if (runningUser != selfServIntegrationUser
                    && opp.AccountId != null
                    && opp.Account.ParentId != null
                    && opp.Account.Deck_Rank__c != null
                    && opp.Account.Deck_Rank__c != ''
                    && opp.RecordTypeId == oppMarketPlaceRTId
                    && opp.Account.Parent.PM_transfer_case_created__c == false
                    // && opp.StageName == 'Closed Won' // Omitted per BZAP-7291
                    && opp.Activation_Date__c != null   // Added per BZAP-7291
                    && opp.Requesting_Account_Management__c == 'Onboarding Manager'
                   )
                    isMatch = true;
            }
            when Marketplace_Onboarding {
                Integer bbotCount = 0; // Nathalie Mendezona BZAP-16317
                String bbotProductFamily = 'Bbot';
                for (OpportunityLineItem oli: opp.OpportunityLineItems) {
                    if (oli.PricebookEntry.Product2.Family != null && oli.PricebookEntry.Product2.Family.contains(bbotProductFamily)) {
                        bbotCount++;
                    }
                }
                if ((isMarketplaceOnboardingEnabled
                     && opp.StageName == 'Closed Won'
                     && opp.AccountId != null
                     && opp.Case_Created__c == false
                     && opp.Region_Type__c == 'Live Region'
                     && opp.Platform__c != 'Caviar'
                     && opp.Platform__c != 'Caviar and DoorDash'
                     && opp.Type != 'Old Close Not in SFDC'
                     && opp.Bulk_Activation__c == false)
                     && (opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId()
                        || opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId())
                     && (bbotCount == 0 || (bbotCount > 0 && bbotCount != opp.OpportunityLineItems.size())) ) {
                            isMatch = true;
                        }
            }
            when Drive_Activation_Case {
                if (opp.Activation_Case_Created__c == false
                    && opp.StageName == 'Closed Won'
                    && opp.RecordTypeId == oppDoorDashDriveRTId
                    && 'Manual Activation Case'.equals(opp.Automation_Status__c)){
                        return true;
                    }
            }
            when Corporate_Drive_Products {
                if (opp.Activation_Case_Created__c == false
                    && opp.StageName == 'Closed Won'
                    && (opp.RecordTypeId == oppCorporateRTId || opp.RecordTypeId == opptyCorporateApprovedRTId)){
                        for (OpportunityLineItem oli : opp.OpportunityLineItems){
                            if (new Set<String>{'LOF','SOF'}.contains(oli.PricebookEntry.Product2.Name)){
                                return true;
                            }
                        }
                    }
            }
            when Post_Sales_Protocol_Change_POS {
                if (opp.StageName == 'Closed Won'
                        // Activation_Case_Created__c added per Becky's feedback to prevent duplicate POS cases
                    && opp.Activation_Case_Created__c == false
                    && String.isNotBlank(opp.Previous_Order_Protocol__c)
                    && !opp.Previous_Order_Protocol__c?.contains('POS')
                    && String.isNotBlank(opp.Order_Protocol__c)
                    && opp.Order_Protocol__c?.contains('POS')) {
                        isMatch = true;
                }
            }
            when Caviar_Onboarding_Flow {
                if (( (opp.RecordTypeId == opptyMarketplaceRTId || opp.RecordTypeId == opptyEnterpriseMarketplaceRTId)
                        && opp.AccountId != null
                        && opp.Decision_Maker__c != null
                        && opp.Caviar_Onboarding_Case_Created__c == false
                        && opp.StageName == 'Closed Won'
                        && (opp.Platform__c == 'Caviar' || opp.Platform__c == 'Caviar and DoorDash')
                        && opp.Caviar_Onboarding_Type__c != 'Self-Service Onboard (SSOB)'
                        )) {
                    isMatch = true;
                }
            }
            when else {
                throw new LogicException('Unexpected logic condition for matching criteria.');
            }
        }

        System.debug('CDdOpportunityCaseHelper.matches: ' + isMatch + ': ' + criteria);
        return isMatch;
    }

    /*
* @author Jeegar Brahmakshatriya
* @Date Mar 2020
* @Description: Create a Tablet Request case
*               BZAP-13015 - Nathalie - Migrate PB "Create Cases for Protocol Change for Post-Sale" to Trigger
*/
    public static Case createTabletCase(Opportunity opp, Id businessHoursId, Id caseRecordTypeId) {
        Case tabletRequestCase = new Case();
        tabletRequestCase.AccountId = opp.AccountId;
        tabletRequestCase.BusinessHoursId = businessHoursId;
        tabletRequestCase.ContactId = opp.Decision_Maker__c;
        if(opp.Platform__c == 'Caviar'){
            tabletRequestCase.Needs_Evening_Delivery__c = 'No';
        }else{
            tabletRequestCase.Needs_Evening_Delivery__c = opp.Needs_Evening_Delivery__c;
        }
        tabletRequestCase.Opportunity_Name__c = opp.id;
        if (opp.RecordTypeId == opptyPostSaleRTId) {
            tabletRequestCase.Origin = CDdSupportConstants.ORIGIN_PROTOCOL_CHANGE;
        } else {
            //BZAP-16866 - Case Origin depends on Opportunity created by User
            //If Created by self service => Case Origin = 'New Tablet Request:SSMO' else => 'New Tablet Request'
            tabletRequestCase.Origin = CDdMxSxOpportunityHelper.isSelfServe(opp) ? CDdSupportConstants.ORIGIN_SSMO_CW_TABLETCASE : CDdSupportConstants.ORIGIN_NEW_TABLET_REQUEST;
        }
        tabletRequestCase.OwnerId = opp.GTMI_Initiative_Name__c == null ? opp.OwnerId : CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_ACTIVATIONS_LAB);
        tabletRequestCase.Op_Owner__c = opp.OwnerId;
        tabletRequestCase.RecordTypeId = caseRecordTypeId;
        tabletRequestCase.Activation_Notes__c = opp.Notes__c;
        tabletRequestCase.Description = opp.Notes__c;

        /*
         * @author Mani. BZAP-9616
         * If related Accounts country on Opportunity is Japan, Map the Kanji address fields to case address fields
         * */

        if(opp.Account.BillingCountry == 'Japan'){
            tabletRequestCase.Return_Shipping_Address_City__c = opp.Account.Kanji_City__c;
            tabletRequestCase.Return_Shipping_Address_State__c = opp.Account.Kanji_State__c;
            tabletRequestCase.Return_Shipping_Address_Street__c = opp.Account.Kanji_Street__c;
            tabletRequestCase.Return_Shipping_Address_Zip__c = opp.Account.Kanji_Zip__c;
            tabletRequestCase.Shipping_Address_Country__c = '日本';
            tabletRequestCase.Shipping_Type__c = 'Hikyaku Express (1-2)';
        } else {
            tabletRequestCase.Return_Shipping_Address_City__c = opp.Account.BillingCity;
            tabletRequestCase.Return_Shipping_Address_State__c = opp.Account.BillingState;
            tabletRequestCase.Return_Shipping_Address_Street__c = opp.Account.BillingStreet;
            tabletRequestCase.Return_Shipping_Address_Zip__c = opp.Account.BillingPostalCode;
            tabletRequestCase.Shipping_Address_Country__c = opp.Account.BillingCountry;
            if(opp.Platform__c == 'Caviar'){
                tabletRequestCase.Shipping_Type__c = 'Expedited';
            }else if(opp.Account.BillingCountry == 'Germany'){
                tabletRequestCase.Shipping_Type__c = 'DHL 2 Day Standard';
            }else if(opp.Account.BillingCountry == 'New Zealand'){
                tabletRequestCase.Shipping_Type__c = 'DHL NZ';
            }
            else {
                tabletRequestCase.Shipping_Type__c = opp.Shipping__c;
            }
        }

        tabletRequestCase.Status = 'Open';
        // NOTE: Tablet Requests includes the following Order Protocols:
        //  Tablet (Door Dash Owns), POS and Tablet (DoorDash Owns),
        //  Tablet and Printer (DoorDash Owns), POS and Tablet Return Label
        // NOTE: There is no Order Protocol that leads to the condition
        //  Request_Type__c = Ship to Merchant (New Tablet, Printer, Return Label)

        /* BASD-32946 Update default automation for Tablet Device type to trigger as blank once the tablet cases are created by SFDC Automation
        tabletRequestCase.Tablet_Device_Type__c = 'Samsung Galaxy Tab E LTE'; // Nathalie - applying this regardless of Order Protocol
        */

        switch on opp.Order_Protocol__c {
            when 'Tablet (DoorDash Owns)' {
                tabletRequestCase.Request_Type__c = 'Ship to Merchant (New Tablet)';
            }
            when 'POS and and Tablet (DoorDash Owns)' {
                tabletRequestCase.Request_Type__c = 'Ship to Merchant (New Tablet)';
                /* BASD-45503 Remove picklist values from irrelevant Record Types for POS Integration Type
                tabletRequestCase.POS_Integration_Type__c = opp.POS_Integration_Type__c;
                */
                tabletRequestCase.POS_Integration_ID__c = opp.POS_Integration_ID__c;
                tabletRequestCase.POS_Fallback_Protocol__c = opp.POS_Fallback_Protocol__c;
            }
            when 'Tablet and Printer (DoorDash Owns)' {
                tabletRequestCase.Request_Type__c = 'Ship to Merchant (New Tablet, Printer)';
            }
            when 'POS and Tablet Return Label' {
                tabletRequestCase.Request_Type__c = 'Email to Merchant (Return Label Only)';
            }
        }
        // If Request_Type__c is still not populated based on the above, look at Previous_Order_Protocol__c value
        if (String.isEmpty(tabletRequestCase.Request_Type__c) &&
            (opp.Previous_Order_Protocol__c == 'Tablet (DoorDash Owns)'
              ||
              opp.Previous_Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)'
              ||
              opp.Previous_Order_Protocol__c == 'POS and and Tablet (DoorDash Owns)')) {
            tabletRequestCase.Request_Type__c = 'Email to Merchant (Return Label Only)';
        }

        if (tabletRequestCase.Request_Type__c == 'Ship to Merchant (New Tablet)') {
            if (opp.RecordTypeId == opptyMarketplaceRTId || opp.RecordTypeId == opptyEnterpriseMarketplaceRTId) {
                tabletRequestCase.Required_for_Store_Activation__c = 'Yes';
            }
            Map<String, String> tabletKitTypeMap = getTabletKitTypeMap();
            for (String tabletKitType : tabletKitTypeMap.keySet()) {
                if (tabletKitType == opp.Tablet_Kit_Type__c) {
                    tabletRequestCase.Request_Type__c = tabletKitTypeMap.get(tabletKitType);
                }
            }
        }

        if (test.isRunningTest()) tabletRequestCase.Subject = 'TEST: TabletCase';
        return tabletRequestCase;
    }

    public static Map<String, String> getTabletKitTypeMap() {
        if (tabletKitTypeMap == null) {
            tabletKitTypeMap = new Map<String, String>();
            List<Tablet_Kit_Type__mdt> tabletKitTypes = [select MasterLabel, Request_Type_c__c from Tablet_Kit_Type__mdt];
            for (Tablet_Kit_Type__mdt tabletKitType : tabletKitTypes) {
                tabletKitTypeMap.put(tabletKitType.MasterLabel, tabletKitType.Request_Type_c__c);
            }
        }
        return tabletKitTypeMap;
    }

    /*
* @author Knick
* @Date Mar 2020
* @Description: Create a Common Case
*
*/
    public static Case createMxMarketingRequestCase(Opportunity opp, Id businessHoursId, Id caseRecordTypeId) {
        Case mxCase = new Case();
        mxCase.BusinessHoursId = businessHoursId;
        mxCase.AccountId = opp.AccountId;
        mxCase.Account_Owner__c = opp.Account.OwnerId;
        mxCase.Include_Marketing_Kit__c = true;
        mxCase.Op_Owner__c = opp.OwnerId;
        mxCase.Opportunity_Name__c = opp.id;
        mxCase.Origin = 'Closed Won - New Mx Kit';
        mxCase.Overture_Request_Type__c = 'Mx Marketing';
        mxCase.OwnerId = opp.OwnerId;
        mxCase.RecordTypeId = caseRecordTypeId;
        mxCase.Return_Shipping_Address_City__c = opp.Account.BillingCity;
        mxCase.Return_Shipping_Address_State__c = opp.Account.BillingState;
        mxCase.Return_Shipping_Address_Street__c = opp.Account.BillingStreet;
        mxCase.Return_Shipping_Address_Zip__c = opp.Account.BillingPostalCode;
        mxCase.Shipping_Address_Country__c = opp.Account.BillingCountry;
        mxCase.Status = 'Approved';
        mxCase.Submarket__c = opp.Submarket__c;
        if (test.isRunningTest()) mxCase.Subject = 'TEST: MxMarketingRequestCase';
        return mxCase;
    }

    /*
* @author Knick
* @Date Mar 2020
* @Description: Create a Common Case
*
*/
    public static Case createCommonCase(Opportunity opp, Id businessHoursId, Id caseRecordTypeId, Id caseOwnerId, String subject) {
        Case commonCase = new Case();
        commonCase.BusinessHoursId = businessHoursId;
        commonCase.AccountId = opp.Account.ParentId;
        commonCase.ContactId = opp.Decision_Maker__c;
        commonCase.Merchant_Special_Requests__c = opp.Account.Parent.Merchant_Special_Requests__c;
        commonCase.Op_Owner__c = opp.OwnerId;
        commonCase.Opportunity_Name__c = opp.Id;
        commonCase.Origin = 'Internal';
        commonCase.OwnerId = caseOwnerId;
        /* BASD-45503 Remove picklist values from irrelevant Record Types for POS Integration Type
        commonCase.POS_Integration_Type__c = opp.POS_Integration_Type__c;
        */
        commonCase.RecordTypeId = caseRecordTypeId;
        commonCase.Status = 'New';
        commonCase.Subject = subject;
        if (test.isRunningTest()) commonCase.Subject = 'TEST: ' + subject;
        return commonCase;
    }

    /*
* @Description: BZAP-9025 Create a Drive Activation Case
*/
    public static Case createDriveActivationCase(Opportunity opp, Id businessHoursId, Id caseRecordTypeId, Id caseOwnerId) {
        Case driveActivationCase = new Case();
        driveActivationCase.BusinessHoursId = businessHoursId;
        driveActivationCase.AccountId = opp.AccountId;
        driveActivationCase.Op_Owner__c = opp.OwnerId;
        driveActivationCase.Opportunity_Name__c = opp.Id;
        driveActivationCase.Origin = 'Drive';
        driveActivationCase.OwnerId = caseOwnerId;
        driveActivationCase.RecordTypeId = caseRecordTypeId;
        driveActivationCase.Status = 'New';
        driveActivationCase.Type = 'Failed Automation';
        driveActivationCase.Subject = (!Test.isRunningTest() ? 'Auto-Created Drive Activation Case' : 'TEST: Drive Activation Case');
        driveActivationCase.Description = 'Case Automatically created from Opportunity';
        return driveActivationCase;
    }

    public static Case createMarketplaceOnboardingCase(Opportunity opp) {
        Boolean isEnterprise =
            (opp.Account.RecordTypeId == CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId()
             || opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId()
             || opp.Account.Deck_Rank__c == 'Ace of Spades'
             || opp.Account.Deck_Rank__c == 'King of Spades'
             || opp.Account.Launch_Deck_Rank__c == 'Ace of Spades'
             || opp.Account.Launch_Deck_Rank__c == 'King of Spades'
             || (opp.Account.ParentId != null
                 && opp.Account.Parent != null
                 && opp.Account.Parent.Deck_Rank__c != null
                 && opp.Account.Parent.Deck_Rank__c.contains('of Spades'))
            );

        Case c = new Case();
        c.AccountId = opp.AccountId;
        c.ContactId = opp.Store_Manager__c;
        c.Decision_Maker__c = opp.Decision_Maker__c;
        c.Op_Owner__c = opp.OwnerId;
        c.Opportunity_Name__c = opp.Id;
        //BZAP-16866 - Case Origin depends on Opportunity created by User
        //If Created by self service => Case Origin = 'Closed Won Opportunity - SSMO' else => 'Closed Won Opportunity'
        c.Origin = CDdMxSxOpportunityHelper.isSelfServe(opp)? CDdMxSxConstants.SELF_SERVE_CASE_ORIGIN : CDdMxSxConstants.CASE_ORIGIN_OPP_CLOSED_WON;
        c.OwnerId = opp.GTMI_Initiative_Name__c == null ? getMarketOnboardingCaseOwnerId(opp, c, isEnterprise) : CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_ACTIVATIONS_LAB);

        /*
         * @author Mani. BZAP-9623
         * If related Accounts country on Opportunity is Japan, Map the Kanji address fields to case address fields
         * */

        if(opp.Account.BillingCountry == 'Japan'){
            c.Return_Shipping_Address_City__c = opp.Account.Kanji_City__c;
            c.Return_Shipping_Address_State__c = opp.Account.Kanji_State__c;
            c.Return_Shipping_Address_Street__c = opp.Account.Kanji_Street__c;
            c.Return_Shipping_Address_Zip__c = opp.Account.Kanji_Zip__c;
            c.Shipping_Address_Country__c = '日本';
        } else {
            c.Return_Shipping_Address_City__c = opp.Account.BillingCity;
            c.Return_Shipping_Address_State__c = opp.Account.BillingState;
            c.Return_Shipping_Address_Street__c = opp.Account.BillingStreet;
            c.Return_Shipping_Address_Zip__c = opp.Account.BillingPostalCode;
            c.Shipping_Address_Country__c = opp.Account.BillingCountry;
        }
        c.Platform__c = opp.Platform__c;
        c.RecordTypeId = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
        c.Segment__c = isEnterprise ? 'Enterprise': 'Local';
        c.Stage__c = 'Not Started';
        c.Status = 'Open';
        if (opp.Order_Protocol__c != null && opp.Order_Protocol__c.contains('POS')) {
            c.POS_Fallback_Protocol__c = opp.POS_Fallback_Protocol__c;
            c.POS_Integration_Type__c = opp.POS_Integration_Type__c;
            c.POS_Integration_ID__c = opp.POS_Integration_ID__c;
        }
        if (test.isRunningTest()) c.Subject = 'TEST: Marketplace Onboarding';
        return c;
    }

        /**
         * @author Nathalie Mendezona
         * @date 2022-01-05
         * @description BZAP-13015 - Migrate PB "Create Cases for Protocol Change for Post-Sale" to Trigger
         * @param Opportunity new Opportunity record
         * @param Id businessHoursId - "Default" BusinessHour record
         * @return Case record created - could be a Tablet Case, or a POS Case
         */
        public static Case postSaleProtocolChangePOSCase(Opportunity opp, Id businessHoursId, Id queueId) {
            Case posCase = createPostSaleCase(opp, businessHoursId);
            posCase.Account_Owner__c = opp.Account?.OwnerId;
            posCase.Due_Date__c = opp.Proposed_Date_of_Activation__c;
            posCase.Go_Live_Date__c = opp.Proposed_Date_of_Activation__c;
            posCase.OwnerId = queueId;
            posCase.POS_Fallback_Protocol__c = opp.POS_Fallback_Protocol__c;
            posCase.POS_Integration_ID__c = opp.POS_Integration_ID__c;
            posCase.POS_Integration_Type__c = opp.POS_Integration_Type__c;
            posCase.Pre_Work_Deadline__c = opp.Proposed_Date_of_Activation__c != null ?
                                        opp.Proposed_Date_of_Activation__c.addDays(-2) : null;
            posCase.RecordTypeId = casePosIntegrationsRTId;
            posCase.ParentId = marketplaceCasesByOpportunities.get(opp.Id);
            posCase.Requested_Due_Date__c = opp.Proposed_Date_of_Activation__c;
            posCase.Status = CDdSupportConstants.OPEN_STATUS;
            return posCase;

        }

        /**
         * @author Nathalie Mendezona
         * @date 2022-01-05
         * @description BZAP-13015 - called by postSaleProtocolChangeCase()
         *      Migrate PB "Create Cases for Protocol Change for Post-Sale" to Trigger
         */
        public static Case createPostSaleCase(Opportunity opp, Id businessHoursId) {
            Case postSaleCase = new Case();
            postSaleCase.AccountId = opp.AccountId;
            postSaleCase.Opportunity_Name__c = opp.Id;
            postSaleCase.Activation_Notes__c = opp.Notes__c;
            postSaleCase.BusinessHoursId = businessHoursId;
            postSaleCase.ContactId = opp.Decision_Maker__c;
            postSaleCase.Description = opp.Notes__c;
            postSaleCase.Op_Owner__c = opp.OwnerId;
            postSaleCase.Origin = CDdSupportConstants.ORIGIN_PROTOCOL_CHANGE;
            return postSaleCase;
        }

        /**
         * @author Nathalie Mendezona
         * @date 2022-01-13
         * @description BZAP-13015 - Migrate PB "Caviar Onboarding Flow" to Trigger
         * @param Opportunity new Opportunity record
         * @param Id businessHoursId - "Default" BusinessHour record
         * @return Case record created - could be a Merchant Catering Onboarding Case, or a Caviar Onboarding Case
         */
        public static Case caviarOnboardingFlow(Opportunity opp, Id businessHoursId) {
            if (opp.RecordTypeId == opptyMarketplaceRTId || opp.RecordTypeId == opptyEnterpriseMarketplaceRTId) {
                Case caviarOnboardingCase = caviarCase(opp, businessHoursId);
                caviarOnboardingCase.Account_Owner__c = opp.Account.OwnerId;
                caviarOnboardingCase.Caviar_Service_Region__c = opp.Account.Caviar_Service_Region__c;
                caviarOnboardingCase.Description = getCaviarCaseDescription(opp);
                caviarOnboardingCase.Origin = CDdSupportConstants.ORIGIN_CLOSED_WON_OPPORTUNITY;
                caviarOnboardingCase.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_CAVIAR_ONBOARDING_TEAM);
                caviarOnboardingCase.RecordTypeId = caseCaviarOnboardingRTID;
                caviarOnboardingCase.Subject = 'Caviar Onboarding - ' + opp.Account.Name;

                return caviarOnboardingCase;
            }
            return null;
        }

        /**
         * @author Nathalie Mendezona
         * @date 2022-01-24
         * @description BZAP-13015 - called by caviarOnboardingFlow()
         *      Migrate PB "Caviar Onboarding Flow" to Trigger
         */
        private static String getCaviarCaseDescription(Opportunity opp) {
            String description = 'Opportunity Details' + CDdCoreConstants.NEW_LINE;
            description += 'Opportunity Name: ' + opp.Name + CDdCoreConstants.NEW_LINE;
            description += 'Opportunity Owner: ' + opp.Owner.FirstName + ' ' + opp.Owner.LastName + CDdCoreConstants.NEW_LINE;
            description += 'Caviar Presale Tier: ' + opp.Account.Caviar_Presale_Tier__c + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE;
            description += 'DM Details' + CDdCoreConstants.NEW_LINE;
            description += 'Decision Maker: ' + opp.Decision_Maker__r.FirstName + ' ' + opp.Decision_Maker__r.LastName + CDdCoreConstants.NEW_LINE;
            description += 'Decision Maker Phone Numbers: ' + opp.DM_Phone_Numbers__c + CDdCoreConstants.NEW_LINE;
            description += 'Decision Maker Email: ' + opp.Decision_Maker__r.Email + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE;
            description += 'Pre-Sale Menu Details' + CDdCoreConstants.NEW_LINE;
            description += 'Menu URL: ' + opp.Menu_URL__c + CDdCoreConstants.NEW_LINE;
            description += 'Menu PDF Attached?: ' + (opp.Menu_PDF_Attached__c ? true : false) + CDdCoreConstants.NEW_LINE;
            description += 'Sales Notes for Menu Team: ' + opp.Notes_for_Menu_Team__c + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE;
            description += 'Location Details' + CDdCoreConstants.NEW_LINE;
            description += 'Store Phone Number: ' + opp.Store_Phone_Number__c + CDdCoreConstants.NEW_LINE;
            description += 'Restaurant Address: ' + opp.Restaurant_Address__c  + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE;
            description += 'Order Protocol Details' + CDdCoreConstants.NEW_LINE;
            description += 'Caviar Order Protocol: ' + opp.Caviar_Order_Protocol__c + CDdCoreConstants.NEW_LINE;
            description += 'POS Integration ID: ' + opp.POS_Integration_ID__c + CDdCoreConstants.NEW_LINE;
            description += 'POS Integration Type: ' + opp.POS_Integration_Type__c + CDdCoreConstants.NEW_LINE;
            description += 'POS Service Type: ' + opp.Order_Service_Type__c + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE;
            description += 'Commission Details' + CDdCoreConstants.NEW_LINE;
            description += 'Commission: ' + opp.Commission__c + CDdCoreConstants.NEW_LINE;
            description += 'In-App Pickup Commission: ' + opp.In_App_Pickup_Commission__c + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE;
            description += 'Pre-Sale Exclusivity Details' + CDdCoreConstants.NEW_LINE;
            description += 'Exclusivity?: ' + opp.Merchant_Signed_with_Exclusivity__c + CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE;
            description += 'Caviar Activation Details' + CDdCoreConstants.NEW_LINE;
            description += 'Caviar Activation Fee: ' + opp.Caviar_Activation_Fee__c + CDdCoreConstants.NEW_LINE;
            description += 'Caviar Offer Document URL: ' + opp.Caviar_Offer_Document_URL__c;

            return description;
        }

        /**
         * @author Nathalie Mendezona
         * @date 2022-01-13
         * @description BZAP-13015 - called by caviarOnboardingFlow()
         *      Migrate PB "Caviar Onboarding Flow" to Trigger
         */
        private static Case caviarCase(Opportunity opp, Id businessHoursId) {
            Case caviarCase = new Case();
            caviarCase.BusinessHoursId = businessHoursId; // make sure to move to a utility class similar to Raju's
            caviarCase.AccountId = opp.AccountId;
            caviarCase.ContactId = opp.Decision_Maker__c;
            caviarCase.Opportunity_Name__c = opp.Id;
            caviarCase.Status = CDdSupportConstants.NEW_STATUS;
            if (opp.Decision_Maker__r.Email != null) {
                caviarCase.SuppliedEmail = opp.Decision_Maker__r.Email;
            }

            return caviarCase;
        }

    /**
    * @description Create Photoshoot Case once Opportunity Close Won.
    * @author Jose Vega | 02-15-2022
    * @param Opportunity opp
    * @param Id businessHoursId
    * @return Case
    **/
    private static Case createPhotoshootCase(Opportunity opp, Id businessHoursId) {
        Case photoshootCase = new Case();
        photoshootCase.BusinessHoursId = businessHoursId;
        photoshootCase.AccountId = opp.AccountId;
        photoshootCase.Address_Latitude__c = opp.Account.Address_Latitude__c;
        photoshootCase.Address_Longitude__c = opp.Account.Address_Longitude__c;
        photoshootCase.Address_Time_Zone__c = opp.Account.Address_Time_Zone__c;
        photoshootCase.Address_UTC_Offset__c = opp.Account.Address_UTC_Offset__c;
        photoshootCase.ContactId = opp.Decision_Maker__c;
        photoshootCase.Opportunity_Name__c = opp.Id;
        photoshootCase.Origin = 'Photoshoot Request';
        photoshootCase.OwnerId = DOORDASH_APEXADMIN;
        photoshootCase.Photo_Provider__c = 'Snappr';
        photoshootCase.Photoshoot_Date__c = opp.Photoshoot_Date__c;
        photoshootCase.Photoshoot_Time__c = opp.Photoshoot_Time__c;
        photoshootCase.RecordTypeId = casePhotoshootProcessingRTId;
        photoshootCase.Return_Shipping_Address_City__c = opp.Account.BillingCity;
        photoshootCase.Return_Shipping_Address_State__c = opp.Account.BillingState;
        photoshootCase.Return_Shipping_Address_Street__c = opp.Account.BillingStreet;
        photoshootCase.Return_Shipping_Address_Zip__c = opp.Account.BillingPostalCode;
        photoshootCase.Shipping_Address_Country__c = opp.Account.BillingCountry;
        photoshootCase.Status = 'Open';
        return photoshootCase;
    }

    private static Id getMarketOnboardingCaseOwnerId(Opportunity opp, case c, Boolean isEnterprise){
        return  ('Closed Won Opportunity - SSMO'.equals(c.Origin) && ('square'.equalsIgnoreCase(opp.POS_Integration_Type__c) || 'toast'.equalsIgnoreCase(opp.POS_Integration_Type__c)))?
        CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_ONBOARDING_SSMO_SQUARE_POS) :
        (isEnterprise ? CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_ENT_ONBOARDING_UNDER_REVIEW) : CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_ONBOARDING_UNDER_REVIEW));
    }

    /**
        @author: Dan Thoreson
        @date: 26-May-2023
        @description: Performs a one-time set of Marketplace Case Ids by their related Opportunities, mainly so 
                      they can be connected to sibling POS Cases
    **/ 
    private static void setRelatedMarketplaceOnboardingCaseIdsForOpportunities(List<Opportunity> allOpportunities) {
        allOpportunities = (allOpportunities != null) ? allOpportunities : new List<Opportunity>();
        
        if(marketplaceCasesByOpportunities == null) {
            marketplaceCasesByOpportunities = new Map<Id, Id>();

            CDdMxSxPOSRequestWrappers.setMarketplaceOpportunityIdsForCaseRetrieval(new Map<Id, Opportunity>(allOpportunities).keySet());
            Map<Id, Case> marketplaceCasesByOpportunityIds = CDdMxSxPOSRequestWrappers.marketplaceCasesByOpportunityIds;
            
            for(Id thisOpportunityId : marketplaceCasesByOpportunityIds.keySet()) {
                Case marketplaceCase = marketplaceCasesByOpportunityIds.get(thisOpportunityId);
                Id marketplaceCaseId = marketplaceCase?.Id;
                
                marketplaceCasesByOpportunities.put(thisOpportunityId, marketplaceCaseId);
            }
        }
    }
}