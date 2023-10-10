/**
    @author: j.johnson
    @date: 14-Jan-2021
    @group: Milestone
    @description: Class for creating/inserting Milestone Templates. Used in unit tests and sandbox refreshes.
**/
public inherited sharing class CDdMilestoneTemplate {
    public static final Id caseMarketPlaceRecordTypeId = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
    public static final Id caseStoreFrontRecordTypeId = CDdSchemaUtils.CASE_RT.storefrontOnboardingId();
    public static final Id milestoneOwnerId = [select Id from Group where DeveloperName = 'Onboarding_Not_Started'].Id;
    public static final Id casePOSIntegrationsRecordTypeId = CDdSchemaUtils.CASE_RT.posIntegrationsId();

    // Query the Milestone RTs upfront to avoid repetitive queries
    public static Map<String, Id> milestoneRecordTypesByDevName { get {
        if(milestoneRecordTypesByDevName == null) {
            milestoneRecordTypesByDevName = new Map<String, Id>();

            for(RecordType thisRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Milestone__c']) {
                milestoneRecordTypesByDevName.put(thisRecordType.DeveloperName, thisRecordType.Id);
            }
        }

        return milestoneRecordTypesByDevName;
    } set;}    

    public static void insertMilestoneTemplates() {
        List<Milestone_Template__c> templates = new List<Milestone_Template__c>();
        //Marketplace Onboarding templates
        templates.add(reviewAndTriage());
        templates.add(setupStore());
        templates.add(setupBanking());
        templates.add(setupCustomDeliveryRadius());
        templates.add(setupBusiness());        
        templates.add(setupMenu());
        templates.add(setupCatalog());
        templates.add(grantPortalAccess());
        templates.add(setupPosIntegrationMarketplaceOnboarding());
        templates.add(deliverTablet());
        templates.add(activationsChecklist());
        templates.add(posTestMethodMarketplaceOnboarding());
        templates.add(activationOutreach());
        templates.add(activateStore());
        templates.add(alcoholLicense());
        templates.add(AdsAndPromos());
        //Storefront Onboarding templates
        templates.add(reviewAndTriageStorefront());
        templates.add(setupStorePricing());
        templates.add(setupStorefrontPage());
        templates.add(implementationCall());
        templates.add(linkImplementation());
        templates.add(linkOptimization());
        
        // Add POS Integration Milestone templates
        templates.add(completePreWorkPOSIntegrations());
        templates.add(configurePosForPOSIntegrations());
        templates.add(ingestMenuPOSIntegrations());
        templates.add(qaMenuPOSIntegrations());
        templates.add(enableIntegrationPOSIntegrations());
        insert templates;
    }

    /**
        @author: Dan Thoreson
        @date: 19-Aug-2022
        @description: Add Milestone Template Versions on top of the created Milestone Templates.
                      This should be the approach taken with Milestones moving forward, but logic
                      was built to minimally interfere with existing architecture.
    **/
    public static void insertMilestoneTemplatesWithVersions() {
        insertMilestoneTemplates();

        insertMilestoneTemplateVersions();
    }

    /**
        @author: Dan Thoreson
        @date: 19-Aug-2022
        @description: Inserts Versioning information for the created Milestone Templates. 
                      Sought to do this in the least-invasive way possible, with no changes required to the 
                      Milestone Template insertion method, so that all existing code that relies on those 
                      Milestone Templates -- but not the versions -- will continue to work. 

                      Method works in four parts:
                        1. Retrieve the Milestone Templates that were just created
                        2. Find the number of unique Parent Object Record Types - this is the number of current versions we need
                        3. Create a Milestone Template Version for each Parent Object Record Type
                        4. Go through the Milestone Templates queried in Step 1, and set the relevant Milestone_Template_Version__c
    **/
    public static void insertMilestoneTemplateVersions() {
        List<Milestone_Template_Version__c> versions = new List<Milestone_Template_Version__c>();
        List<Milestone_Template__c> templateUpdateList = new List<Milestone_Template__c>();

        // Get the Parent Record Types of the Milestones that have been created
        Map<Id, List<Milestone_Template__c>> milestonesByParentRecordTypes = new Map<Id, List<Milestone_Template__c>>();

        for(Milestone_Template__c mt : [SELECT Id, Milestone_Template_Version__c, Parent_Object_Record_Type_ID_18__c FROM Milestone_Template__c]) {
            if(!milestonesByParentRecordTypes.containsKey(mt.Parent_Object_Record_Type_ID_18__c)) {
                milestonesByParentRecordTypes.put(mt.Parent_Object_Record_Type_ID_18__c, new List<Milestone_Template__c>());
            }

            milestonesByParentRecordTypes.get(mt.Parent_Object_Record_Type_ID_18__c).add(mt);
        }

        for(Id parentRecordTypeId : milestonesByParentRecordTypes.keySet()) {
            Milestone_Template_Version__c mtv = new Milestone_Template_Version__c();
            mtv.Record_Type_Id__c = parentRecordTypeId;
            mtv.Version_Number__c = 1;
            mtv.Start_Time__c = Date.newInstance(1970, 01, 01);
            mtv.End_Time__c = null;
            versions.add(mtv);
        }

        insert versions;

        // Update the Milestone Templates with the correct Versions
        for(Milestone_Template_Version__c version : versions) {
            for(Milestone_Template__c mt : milestonesByParentRecordTypes.get(version.Record_Type_Id__c)) {
                mt.Milestone_Template_Version__c = version.Id;
                templateUpdateList.add(mt);
            }
        }

        update templateUpdateList;
    }

    public static Milestone_Template__c reviewAndTriage() {
        String MILESTONE_NAME = 'Review & Triage';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Review_Triage'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 1,
                Active__c = true,
                Completed_by_Stage__c = 'Under Review',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 1,
                Stage_Reviewed_Sort_Order__c = 1
        );
    }

    public static Milestone_Template__c setupStore() {
        String MILESTONE_NAME = 'Setup Store';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Setup_Store'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 2,
                Active__c = true,
                Completed_by_Stage__c = 'Store Configuration',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 2,
                Stage_Reviewed_Sort_Order__c = 2
        );
    }
    public static Milestone_Template__c setupBanking() {
        String MILESTONE_NAME = 'Setup Banking';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,       
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Setup_Banking'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 3,
                Active__c = true,
                Completed_by_Stage__c = 'Onboarding Quality Check',
                Stage_Reviewed_Sort_Order__c = null,
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 2
        );
    }
    
    public static Milestone_Template__c alcoholLicense() {
        return new Milestone_Template__c(
                Milestone_Type__c = 'Alcohol License',
                Milestone_Record_Type_ID_18__c = [select Id from RecordType where DeveloperName = 'Alcohol_License'].Id,
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 4,
                Active__c = true,
                Completed_by_Stage__c = 'Onboarding Quality Check',
                Reviewed_by_Stage__c = 'Store Configuration',
                Stage_Completed_Sort_Order__c = 4,
                Stage_Reviewed_Sort_Order__c = 2
        );
    }

    public static Milestone_Template__c setupCustomDeliveryRadius() {
        String MILESTONE_NAME = 'Setup Custom Delivery Radius';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Setup_Custom_Delivery_Radius'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 4,
                Active__c = true,
                Completed_by_Stage__c = 'Menu Configuration',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 3,
                Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c setupBusiness() {
        String MILESTONE_NAME = 'Setup Business';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('General'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 5,
                Active__c = true,
                Completed_by_Stage__c = 'Store Configuration',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 2,
                Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c setupMenu() {
        String MILESTONE_NAME = 'Setup Menu';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,            
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Setup_Menu'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 6,
                Active__c = true,
                Completed_by_Stage__c = 'Menu Configuration',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 3,
                Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c setupCatalog() {
        String MILESTONE_NAME = 'Setup Catalog';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Setup_Catalog'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 7,
                Active__c = true,
                Completed_by_Stage__c = 'Menu Configuration',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 3,
                Stage_Reviewed_Sort_Order__c = null
        );
    }     

    public static Milestone_Template__c grantPortalAccess() {
        String MILESTONE_NAME = 'Grant Portal Access';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Grant_Portal_Access'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 8,
                Active__c = true,
                Completed_by_Stage__c = 'Store Configuration',
                Reviewed_by_Stage__c = 'Menu Configuration',
                Stage_Completed_Sort_Order__c = 2,
                Stage_Reviewed_Sort_Order__c = 3
        );
    }

    public static Milestone_Template__c setupPosIntegrationMarketplaceOnboarding() {
        return new Milestone_Template__c(
            Name = CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_INTEGRATION,
            Milestone_Type__c = CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_INTEGRATION,
            Milestone_Record_Type_ID_18__c = Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName().get('Setup_POS_Integration').getRecordTypeId(),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
            Milestone_Creation_Type__c = 'Conditional',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 10,
            Active__c = true,
            Completed_by_Stage__c = 'Menu Configuration',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 3,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c deliverTablet() {
        String MILESTONE_NAME = 'Deliver Tablet';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Deliver_Tablet'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 11,
                Active__c = true,
                Completed_by_Stage__c = 'Onboarding Quality Check',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 6,
                Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c activationsChecklist() {
        String MILESTONE_NAME = 'Activations Checklist';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Activations_Checklist'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Default',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 12,
                Active__c = true,
                Completed_by_Stage__c = 'Onboarding Quality Check',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 6,
                Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c posTestMethodMarketplaceOnboarding() {
        String MILESTONE_NAME = 'POS Test Method';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('General_POS'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 13,
                Active__c = true,
                Completed_by_Stage__c = 'Onboarding Quality Check',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 6,
                Stage_Reviewed_Sort_Order__c = null
        );
    }    

    public static Milestone_Template__c activationOutreach() {
        String MILESTONE_NAME = 'Activation Outreach';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Activation_Outreach'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 14,
                Active__c = true,
                Completed_by_Stage__c = 'Contacting Mx',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 7,
                Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c activateStore() {
        String MILESTONE_NAME = 'Activate Store';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Activate_Store'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 15,
                Active__c = true,
                Completed_by_Stage__c = 'Ready for Activation',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 8,
                Stage_Reviewed_Sort_Order__c = null
        );
    }
    
    public static Milestone_Template__c AdsAndPromos() {
        String MILESTONE_NAME = 'Ads & Promos';

        return new Milestone_Template__c(
                Name = MILESTONE_NAME,
                Milestone_Type__c = MILESTONE_NAME,
                Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Ads_Promos'),
                Parent_Object_API_Name__c = 'Case',
                Parent_Object_Record_Type_ID_18__c = caseMarketPlaceRecordTypeId,
                Milestone_Creation_Type__c = 'Conditional',
                Default_Milestone_Status_on_Creation__c = 'Not Started',
                Default_Owner_on_Creation_18__c = milestoneOwnerId,
                Default_Sort_Order__c = 17,
                Active__c = true,
                Completed_by_Stage__c = 'Ready for Activation',
                Reviewed_by_Stage__c = null,
                Stage_Completed_Sort_Order__c = 8,
                Stage_Reviewed_Sort_Order__c = null
        );
    }
    
    public static Milestone_Template__c reviewAndTriageStorefront() {
        String MILESTONE_NAME = 'Review & Triage';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Review_Triage'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = caseStoreFrontRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 1,
            Active__c = true,
            Completed_by_Stage__c = 'Under Review',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 1,
            Stage_Reviewed_Sort_Order__c = 1
        );
    }

    public static Milestone_Template__c setupStorePricing() {
        String MILESTONE_NAME = 'Setup Store Pricing';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Setup_Store_Pricing'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = caseStoreFrontRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 2,
            Active__c = true,
            Completed_by_Stage__c = 'Store Configuration',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 2,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c setupStorefrontPage() {
        String MILESTONE_NAME = 'Setup Storefront Page';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Setup_Storefront_Page'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = caseStoreFrontRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 3,
            Active__c = true,
            Completed_by_Stage__c = 'Setup Storefront Page',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 3,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c implementationCall() {
        String MILESTONE_NAME = 'Implementation Call';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,            
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Implementation_Call'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = caseStoreFrontRecordTypeId,
            Milestone_Creation_Type__c = 'Conditional',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 4,
            Active__c = true,
            Completed_by_Stage__c = 'Implementation Call',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 4,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c linkImplementation() {
        String MILESTONE_NAME = 'Link Implementation';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Link_Implementation'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = caseStoreFrontRecordTypeId,
            Milestone_Creation_Type__c = 'Conditional',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 5,
            Active__c = true,
            Completed_by_Stage__c = 'Link Implementation',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 5,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c linkOptimization() {
        String MILESTONE_NAME = 'Link Optimization';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('Link_Optimization'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = caseStoreFrontRecordTypeId,
            Milestone_Creation_Type__c = 'Conditional',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 6,
            Active__c = true,
            Completed_by_Stage__c = 'Link Optimization',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 6,
            Stage_Reviewed_Sort_Order__c = null
        );
    }
    // POS Milestone Templates
    public static Milestone_Template__c completePreWorkPOSIntegrations() { 
        String MILESTONE_NAME = 'Complete pre-work';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('General_POS'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = casePOSIntegrationsRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 1,
            Active__c = true,
            Completed_by_Stage__c = 'Under Review',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 1,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c configurePosForPOSIntegrations() {
        String MILESTONE_NAME = 'Configure POS';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('General_POS'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = casePOSIntegrationsRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 2,
            Active__c = true,
            Completed_by_Stage__c = 'POS Store Configuration',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 2,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c ingestMenuPOSIntegrations() {
        String MILESTONE_NAME = 'Ingest Menu';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('General_POS'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = casePOSIntegrationsRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 3,
            Active__c = true,
            Completed_by_Stage__c = 'POS Menu Configuration',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 3,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

     public static Milestone_Template__c qaMenuPOSIntegrations() {
        String MILESTONE_NAME = 'QA Menu';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('General_POS'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = casePOSIntegrationsRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 4,
            Active__c = true,
            Completed_by_Stage__c = 'POS Menu Configuration',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 3,
            Stage_Reviewed_Sort_Order__c = null
        );
    }

    public static Milestone_Template__c enableIntegrationPOSIntegrations() {
        String MILESTONE_NAME = 'Enable Integration';

        return new Milestone_Template__c(
            Name = MILESTONE_NAME,
            Milestone_Type__c = MILESTONE_NAME,            
            Milestone_Record_Type_ID_18__c = milestoneRecordTypesByDevName.get('General_POS'),
            Parent_Object_API_Name__c = 'Case',
            Parent_Object_Record_Type_ID_18__c = casePOSIntegrationsRecordTypeId,
            Milestone_Creation_Type__c = 'Default',
            Default_Milestone_Status_on_Creation__c = 'Not Started',
            Default_Owner_on_Creation_18__c = milestoneOwnerId,
            Default_Sort_Order__c = 6,
            Active__c = true,
            Completed_by_Stage__c = 'POS Onboarding Quality Check',
            Reviewed_by_Stage__c = null,
            Stage_Completed_Sort_Order__c = 4,
            Stage_Reviewed_Sort_Order__c = null
        );
    }
}