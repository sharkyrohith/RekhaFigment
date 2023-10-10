/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7352: Scheduled Batch Job for bulk deactivation case
 *
 * Qualified corporate Opps are those that meet filter criteria and have at least one
 * franchise Opp that also meets filter criteria.
 *
 * For each qualified corporate Opp:
 *      1) create a deactivation Case
 *      2) set the Deactivation_Case_Created__c flag on the corporate Opp and all related franchise Opps
 *      3) create a CSV report listing Restaurant_Id__c for child accounts of the franchise Opp Accounts
 *      4) attach the report to the Case
 *
 * Case     -> Corporate Opp <- Franchise Opp
 * Report   -> Corporate Opp <- Franchise Opp -> Parent Account <- Franchise Account
 */
global with sharing class CDdBatchDeactivationCases implements Database.Batchable<Case>, Database.Stateful {
    private Context ctx = new CDdBatchDeactivationCases.Context();

    private class Context {
        public final Map<Id, List<Opportunity>> corporateFranchiseOppMap = new Map<Id, List<Opportunity>>();
        public final Map<Id, Opportunity> corporateOppMap = new Map<Id, Opportunity>();
        public final Map<Id, Set<Id>> corporateOppAccounts = new Map<Id, Set<Id>>();
    }

    /**
    * Get a list of qualified corporate Opps and create a Case for each one.
    *
    * @param bctx
    *
    * @return
    */
    global List<Case> start(Database.BatchableContext bctx) {
        Id bulkRequestRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Bulk_Upload_Request').getRecordTypeId();
        List<Case> cases = new List<Case>();

        initializeOpps();

        for (Opportunity opp : ctx.corporateOppMap.values()) {
            Case cas = new Case();
            cas.AccountId = opp.AccountId;
            cas.Description = caseDescription(opp);
            cas.Due_Date__c = Date.today();
            cas.Opportunity_Name__c = opp.Id;
            cas.Origin = 'Bulk Upload Request - Post Sale - Franchise Opt-In';
            cas.OwnerId = '00G2L000001Wn4K';
            cas.RecordTypeId = bulkRequestRecTypeId;
            cas.Requester__c = opp.OwnerId;
            cas.Subject = 'Bulk Upload Request - Bulk Permanent Deactivation - Franchise Opt-Out';
            cases.add(cas);
        }

        // force error for code coverage
        if (Test.isRunningTest()) { cases.add(new Case(Id='5003K0000000000000')); }

        return cases;
    }

    /**
    * Create Cases, update the corresponding Corporate and related Franchise Opps,
    * create a Store report for each, and attach it to the Case.
    *
    * @param bctx
    * @param cases
    */
    global void execute(Database.BatchableContext bctx, List<Case> cases) {
        List<Database.Error> errors = new List<Database.Error>();
        List<Opportunity> successfulOpps = new List<Opportunity>();
        Map<Id, Id> successfulCorpCaseMap = new Map<Id, Id>();

        // Insert Cases
        List<Database.SaveResult> srsCases = Database.insert(cases, false);

        // Collect Opportunities for successful Cases
        Integer i = 0;
        for (Database.SaveResult srCase : srsCases) {
            Id corporateOppId = cases[i].Opportunity_Name__c;

            if (srCase.getErrors().size() == 0) {
                successfulCorpCaseMap.put(corporateOppId, cases[i].Id);
                successfulOpps.addAll(ctx.corporateFranchiseOppMap.get(corporateOppId));
            } else {
                errors.addAll(srCase.getErrors());
            } i++;
        }

        // Update Opportunities
        for (Opportunity opp : successfulOpps) { opp.Deactivation_Case_Created__c = true; }
        List<Database.SaveResult> oppSaveResults = Database.update(successfulOpps, false);
        for (Database.SaveResult oppSaveResult : oppSaveResults) {
            errors.addAll(oppSaveResult.getErrors());
        }

        // Create ContentVersions (CSV reports) to attach to Cases
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        for (Id corporateOppId : successfulCorpCaseMap.keySet()) {
            Set<Id> parentAccountIds = ctx.corporateOppAccounts.get(corporateOppId);
            contentVersionMap.put(corporateOppId, createContentVersion(parentAccountIds));
        }

        // Insert ContentVersions
        List<Database.SaveResult> cvSaveResults = Database.insert(contentVersionMap.values(), false);
        i = 0;
        Map<Id, Id> successfulContentVersionMap = new Map<Id, Id>();
        for (Database.SaveResult cvSaveResult : cvSaveResults) {
            if (cvSaveResult.getErrors().size() == 0) {
                Id caseId = successfulCorpCaseMap.values()[i];
                Id contentVersionId = cvSaveResult.getId();
                successfulContentVersionMap.put(contentVersionId, caseId);
            } else {
                errors.addAll(cvSaveResult.getErrors());
            } i++;
        }

        // Retrieve ContentDocumentIds for newly created ContentVersions
        Map<Id, ContentVersion> cvs = new Map<Id, ContentVersion>(
            [select Id, ContentDocumentId from ContentVersion
             where Id = :successfulContentVersionMap.keySet()]);

        // Create ContentDocumentLinks
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for (Id id : successfulContentVersionMap.keySet()) {
            Id caseId = successfulContentVersionMap.get(Id);
            Id contentDocumentId = cvs.get(id).ContentDocumentId;
            cdls.add(createContentDocumentLink(contentDocumentId, caseId));
        }

        // Insert ContentDocumentLinks
        List<Database.SaveResult> cdlSaveResults = Database.insert(cdls, false);
        for (Database.SaveResult cdlSaveResult : cdlSaveResults) {
            errors.addAll(cdlSaveResult.getErrors());
        }

        insertApexLogs(errors);
    }

    global void finish(Database.BatchableContext ctx) {}

    /**
    * Identify Corporate Opportunities that qualify for a deactivation Case. These
    * Opportunties must be in a certain state and must also have at least one
    * related Franchise Opportunity in a certain state.
    *
    * One Case is created for each Corporate Opportunity that qualifies, but all
    * qualified Corporate and Franchise Opportunities must be updated as well.
    */
    private void initializeOpps() {
        Date activationDate = System.today().addDays(-Integer.valueOf(Label.DDDeactivationDays));
        // Tia Xuan 09/2020 BZAPSUP-484 Switch references of "Number_of_Stores__c" in apex classes
        Map<Id, Opportunity> corporateOpps = new Map<Id, Opportunity>([
                select
                    AccountId,
                    Id,
                    of_Addressable_Locations__c,
                    OwnerId,
                    PactSafe_Activity_ID__c,
                    PactSafe_Record__c,
                    RecordTypeId
                from Opportunity
                where
                    RecordTypeId = :CDdSchemaUtils.OPPORTUNITY_RT.corporateId()
                        and Deactivation_Case_Created__c = false
                        and Docusign_Sent__c < :activationDate
                        and StageName = 'Closed Won'
        ]);

        // Tia Xuan 09/2020 BZAPSUP-484 Switch references of "Number_of_Stores__c" in apex classes
        Map<Id, Opportunity> franchiseOppsById = new Map<Id, Opportunity> ([
                select
                    AccountId,
                    Id,
                    of_Addressable_Locations__c,
                    PactSafe_Activity_ID__c,
                    PactSafe_Record__c,
                    Parent_Opportunity__c,
                    RecordTypeId
                from Opportunity
                where
                    RecordTypeId = :CDdSchemaUtils.OPPORTUNITY_RT.franchiseOpportunityId()
                        and Deactivation_Case_Created__c = false
                        and Parent_Opportunity__c = :corporateOpps.keySet()
                        and StageName = 'Closed Lost'
        ]);

        // Working "bottom-up" to generate a Map that is "top-down" (franchises -> corporate :: corporate -> franchises
        for (Opportunity franchiseOpp : franchiseOppsById.values()) {
            Opportunity qualifiedCorporateOpp = corporateOpps.get(franchiseOpp.Parent_Opportunity__c);

            if (ctx.corporateFranchiseOppMap.containsKey(qualifiedCorporateOpp.Id)) {
                // add to existing List
                ctx.corporateFranchiseOppMap.get(qualifiedCorporateOpp.Id).add(franchiseOpp);
                ctx.corporateOppAccounts.get(qualifiedCorporateOpp.Id).add(franchiseOpp.AccountId);

            } else {
                // insert new List
                ctx.corporateFranchiseOppMap.put(qualifiedCorporateOpp.Id, new List<Opportunity>{qualifiedCorporateOpp, franchiseOpp});
                ctx.corporateOppAccounts.put(qualifiedCorporateOpp.Id, new Set<Id>{franchiseOpp.AccountId});
                ctx.corporateOppMap.put(qualifiedCorporateOpp.Id, qualifiedCorporateOpp);
            }
        }
    }

    private String caseDescription(Opportunity opp) {
        String baseUrl = Url.getSalesforceBaseUrl().toExternalForm();

        List<Object> args = new List<Object>();
        args.add(baseUrl);
        args.add(opp.Id);
        args.add(opp.PactSafe_Record__c);
        args.add(opp.PactSafe_Activity_ID__c);
        // Tia Xuan 09/2020 BZAPSUP-484 Switch references of "Number_of_Stores__c" in apex classes
        args.add(opp.of_Addressable_Locations__c);

        String description = String.format(
                'Please permanently deactivate all stores included in the attached CSV file\n\n'
                        + 'Parent Opportunity URL:\n'
                        + '{0}/{1}\n\n'
                        + 'PactSafe Record URL:\n'
                        + '{2}\n'
                        + 'PactSafe Activity Id: {3}\n'
                        + 'Estimated Number of Locations: {4}',
                args);

        return description;
    }

    /**
    * Given a set of franchise Opp AccountIds (parentIds), create a CSV containing
    * a list of Restaurant_Id__c for each child account.
    *
    * @param parentIds
    *
    * @return a Map of ContentVersions keyed by Corporate Opp Id
    */
    private ContentVersion createContentVersion(Set<Id> parentIds) {
        //TODO: Bulkify across all corporate Opps
        List<Account> franchises = [select Restaurant_ID__c from Account where ParentId = :parentIds];
        String csv = 'Restaurant_Id__c\n';

        if (franchises.size() > 0) {
            for (Account franchise : franchises) {
                if (franchise.Restaurant_ID__c != null) {
                    csv += franchise.Restaurant_ID__c + '\n';
                }
            }
        } else {
            csv += 'None Active\n';
        }

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.PathOnClient = 'report.csv';
        cv.Title = 'Store Ids for Deactivation';
        cv.VersionData = Blob.valueOf(csv);
        return cv;
    }

    /**
    * Links the csv file to the Case
    *
    * @param contentDocumentId
    * @param caseId
    *
    * @return
    */
    private ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id caseId) {
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = caseId;
        cdl.ContentDocumentId = contentDocumentId;
        cdl.shareType = 'V';
        return cdl;
    }

    private void insertApexLogs(List<Database.Error> errors) {
        List<Apex_Log__c> logs = new List<Apex_Log__c>();
        for (Database.Error error : errors) {
            Apex_Log__c log = new Apex_Log__c();
            log.Class_Name__c = 'CDdBatchDeactivationCases';
            log.Method_Name__c = 'execute';
            log.Log_Level__c = 'Error';
            log.Log__c = error.getMessage();
            logs.add(log);
        }
        insert logs;
    }

}