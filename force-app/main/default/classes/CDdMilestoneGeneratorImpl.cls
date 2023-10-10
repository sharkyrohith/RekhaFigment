/********************************************************************************************************************
* @author Sriram
* @date 08/02/2021
*
* @group Milestone
*
* @description Implementation class for Milestone generation
*   Majority of the functions/responsibilities w.r.t milestone generation are performed in this common Apex Class. Responsibilities are outlined below.
*   1. Determine if the sObject record has existing milestones associated with it
*   2. Gather the default milestone templates for the specific combination of sObject type and record type as found on the sObject record
*   3. Determine the missing milestone templates for the sObject record, by comparing the collection of default and conditional templates (the sObject is eligible for) against the existing collection of milestones (if any) associated with sObject record currently
*   4. Finally, create the Milestones (missing ones or all from comparison as outlined in prior bullet point) in the Milestone sObject within Salesforce
* 
**************************************************************************************************************************************/
public abstract class CDdMilestoneGeneratorImpl implements CDdMilestoneGenerator {
    /**
     * static variables are defined here
     */
    public static String SOQL_QUERY_MILESTONE = ' SELECT Id, Name, Milestone_Template__c, {0} '
                                                + ' FROM Milestone__c '
                                                + ' WHERE {1} IN :parentSObjectIds ';
    /** 
     * static containers to hold the default and conditional templates, as well as the Version information
     */
    public static Map<Id, Map<Id, Milestone_Template__c>> DEFAULT_MILESTONE_TEMPLATES_BY_VERSION;
    public static Map<Id, Map<Id, Milestone_Template__c>> CONDITIONAL_MILESTONE_TEMPLATES_BY_VERSION;
    public static Map<Id, List<Milestone_Template_Version__c>> VERSIONS_BY_RT;

    /**
     * instance variables are defined here
     */
    /**
     * @description Following are the parent attributes (criteria fields) to determine the apppropriate milestone templates
     */    
    protected String parentSObjectType;
    protected Id parentSObjectRecordTypeId;
    protected Map<Id, Id> milestoneVersionIdByParentId; // key = Parent ID, value = applicable Milestone Version ID
    
    /**
     * @description This the field found on the Milestone object that references the Parent SObject record (configured as Lookup field)
     */
    protected String parentSObjectReferenceField;
    protected Set<Id> parentSObjectIds {
        set;
        get {
            return this.parentSObjectIds!=null ? this.parentSObjectIds : new Set<Id>();
        }
    } 
    
    protected Map<Id, SObject> parentObjectRecords {get {
        if(parentObjectRecords == null) {
            parentObjectRecords = new Map<Id, SObject>();
        }
        
        return parentObjectRecords;
    } set;}

    // This allows testing for scenarios with old copies of Milestone Versions, as opposed to only new copies.
    // There are solutions like Test.setCreatedDate(), but those have some limitations due to the asynchronous
    // nature of the Milestone generation (for example, that method has to be called BEFORE Test.startTest(), but
    // we need to generate Milestones (by creating a Case) between Test.startTest() and Test.stopTest()). It seems
    // like the best we can do is to have an override variable that can be written to in a test context when we want
    // to set the date for something specific. 
    public static DateTime dateOverrideTesting {get; set;}

    protected Map<Id, Set<String>> existingMilestoneTemplates;
    /**
     * Default constructor
     */
    public CDdMilestoneGeneratorImpl() {
    }
    /**
     * @description Return the implementation class name
     * @return String
     */      
    public abstract String getClassName();    
    /**
     * @description Set the parent attributes/characteristics to determine the appropriate milestone templates for milestone generation.
     * Current attributes of the parent record that are computed to determine what the appropriate milestone templates should be, are as follows
     * 1. Parent SObject Type
     * 2. Parent Record Type
     * @param String parentSObjectType - what is the parent sObject Type for which the milestones are being generated?
     * @param Id parentSObjectRecordTypeId - what is the parent sObject Record Type Id or which the milestones are being generated?
     * @param String parentSObjectReferenceField - this the parent reference field found on the Milestone custom object for the specific parent sObject type
     */    
    public void setParentAttributes(String parentSObjectType, Id parentSObjectRecordTypeId, String parentSObjectReferenceField){
        this.parentSObjectType = parentSObjectType;
        this.parentSObjectRecordTypeId = parentSObjectRecordTypeId;
        this.parentSObjectReferenceField = parentSObjectReferenceField;
        this.setMilestoneTemplates();
    }    
    /**
     * @description Set the Parent sObject Record Ids for the milestone generation.
     * @param Set<Id> parentSObjectIds - a Collection of sObjects Ids that will be processed for milestone generation
     * @return  
     */
    public void setParentSObjectRecords(Map<Id, SObject> parentSObjectRecords) {
        this.parentObjectRecords = parentSObjectRecords != null ? parentSObjectRecords : new Map<Id, SObject>();
        this.parentSObjectIds = parentSObjectRecords.keySet(); // Not needed, but easier to work with than calling .keySet() everywhere
        this.setExistingMilestoneTemplates();
        this.setTemplateVersionProperties();

    }
    /**
     * @description Execute milestone generation of relevant default and conditional milestones for all Parent sObject Records
     * @return  
     */    
    public void execute(){
        List<Milestone__c> milestones = new List<Milestone__c>();
        milestones.addAll(this.getDefaultMilestones());
        milestones.addAll(this.getConditionalMilestones());
        List<Database.SaveResult> milestoneSaveResults = Database.insert(milestones, false);
        List<String> errorMessages = CDdErrorUtilities.processSaveResults(milestoneSaveResults);
        if (!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, getClassName(), 'execute', LoggingLevel.ERROR);
        }
    }

    /**
     * @description Add the default and conditional templates to the static collection containers
     * @return  
     */    
    public void setMilestoneTemplates() {
        // The key of each map are the MTV Ids; the values are Milestone_Template__c.Id => Milestone_Template__c
        // This works because there is another map, linking a Case (or parent record) to a specific Template Version
        DEFAULT_MILESTONE_TEMPLATES_BY_VERSION = new Map<Id, Map<Id, Milestone_Template__c>>();
        CONDITIONAL_MILESTONE_TEMPLATES_BY_VERSION = new Map<Id, Map<Id, Milestone_Template__c>>();

        VERSIONS_BY_RT = new Map<Id, List<Milestone_Template_Version__c>>();

        List<Milestone_Template_Version__c> versions = CDdMilestoneSelector.getVersionsByRecordType(parentSObjectRecordTypeId);

        // Split the two types of Milestones -- Default and Conditional -- into separate maps. Access them at the top level by their Version Id. 
        for(Milestone_Template_Version__c mtv : versions) {
            DEFAULT_MILESTONE_TEMPLATES_BY_VERSION.put(mtv.Id, new Map<Id, Milestone_Template__c>());
            CONDITIONAL_MILESTONE_TEMPLATES_BY_VERSION.put(mtv.Id, new Map<Id, Milestone_Template__c>());

            // Put the RecordType Id as a key to the Version/RT map if it does not exist
            if(!VERSIONS_BY_RT.containsKey(mtv.Record_Type_Id__c)) {
                VERSIONS_BY_RT.put(mtv.Record_Type_Id__c, new List<Milestone_Template_Version__c>());
            }

            // Put this version in the map -- we will use this later to determine what Versions match the parent record(s)
            VERSIONS_BY_RT.get(mtv.Record_Type_Id__c).add(mtv);

            partitionMilestonesByCreationType(mtv.Id, mtv.Milestone_Templates__r);
        }

        // No version specified -- this will keep this working through the redesign until the data is fixed.
        // Use null as the Version ID
        if(versions.isEmpty() || !VERSIONS_BY_RT.containsKey(parentSObjectRecordTypeId)) {
            VERSIONS_BY_RT.put(parentSObjectRecordTypeId, new List<Milestone_Template_Version__c>());
            DEFAULT_MILESTONE_TEMPLATES_BY_VERSION.put(null, new Map<Id, Milestone_Template__c>());
            CONDITIONAL_MILESTONE_TEMPLATES_BY_VERSION.put(null, new Map<Id, Milestone_Template__c>());

            partitionMilestonesByCreationType(null, CDdMilestoneSelector.getMilestoneTemplatesByRecordTypeWithoutVersions(parentSObjectType,                
                                                                                                                            parentSObjectRecordTypeId));
        }
    }    

    /**
        @author: Dan Thoreson
        @date: 17-Aug-2022
        @description: Finds the applicable Version record we should use for the Milestone Templates. 
                      Goal is to link each Parent Record ID, on the basis of its CreatedDate, to a Milestone 
                      Template Version ID. 

                      Each parent record will only be associated with the applicable Milestone Templates from the 
                      time it was created!
    **/
    private void setTemplateVersionProperties() {
        milestoneVersionIdByParentId = new Map<Id, Id>();
        
        for(SObject thisParent : parentObjectRecords.values()) {
            // We need three properties from the Parent: Id, RecordTypeId and CreatedDate
            Id parentId = (Id) thisParent.get('Id');
            Id recordTypeId = (Id) thisParent.get('RecordTypeId');
            DateTime createdDate = (Test.isRunningTest() && dateOverrideTesting != null) ? dateOverrideTesting : (DateTime) thisParent.get('CreatedDate');

            // Go through the Versions for this record type
            for(Milestone_Template_Version__c mtv : VERSIONS_BY_RT.get(recordTypeId)) {
                Boolean useThisAsLatestVersion = mtv.Current_Latest_Version__c && createdDate >= mtv.Start_Time__c;
                Boolean useThisAsOlderVersion = createdDate >= mtv.Start_Time__c && (mtv.End_Time__c == null || mtv.End_Time__c >= createdDate);

                if(useThisAsLatestVersion || useThisAsOlderVersion) {
                    milestoneVersionIdByParentId.put(parentId, mtv.Id);
                    break; // Stop looking at other versions (inner loop) for this parent
                }
            }

            // If no versions, put "null" for the Version Type.
            if(!milestoneVersionIdByParentId.containsKey(parentId)) {
                milestoneVersionIdByParentId.put(parentId, null);
            }
        }
    }

    /**
     * @description Retrieve the existing milestone templates that are currently generated for the parent sObject Ids
     * - Set the Collection of template references on the instance variable 'existingMilestoneTemplates'
     * @return  
     */    
    public void setExistingMilestoneTemplates() {
        String query = String.format(SOQL_QUERY_MILESTONE, new List<String>{this.parentSObjectReferenceField, this.parentSObjectReferenceField});
        this.existingMilestoneTemplates = new Map<Id, Set<String>>();
        
        for (Milestone__c m : Database.query(query)){
            Id parentSObjectId = (Id)m.get(this.parentSObjectReferenceField);
            
            if(!this.existingMilestoneTemplates.containsKey(parentSObjectId)) {
                this.existingMilestoneTemplates.put(parentSObjectId, new Set<String>());
            }
            
            // Compare the Name and ID with existing Milestones as versioning might be looking at different Template IDs 
            this.existingMilestoneTemplates.get(parentSObjectId).add(m.Milestone_Template__c);
            this.existingMilestoneTemplates.get(parentSObjectId).add(m.Name);
        }
    }
    /**
     * @description Return the default milestones for the parent sObject Ids
     * 1. Retrieve the default milestone templates
     * 2. For each Parent sObject record
     * a. Run a comparison check of the milestone templates against existing milestone templates
     * b. Prepare a collection of miletone templates that do not already exist for that Parent sObject record
     * c. Prepare and return the Collection of milestone records for the milestone templates from previous step
     * @return List<Milestone__c>  
     */      
    public List<Milestone__c> getDefaultMilestones() {
        List<Milestone__c> milestones = new List<Milestone__c>();

        for (Id parentSObjectId : this.parentSObjectIds) {
            // Get Version ID relating to the Parent Object Record - if one exists
            // If one does not exist, we'll use the orphaned templates
            Id versionIdToUse = milestoneVersionIdByParentId.get(parentSObjectId);

            milestones.addAll(getMilestones(parentSObjectId, DEFAULT_MILESTONE_TEMPLATES_BY_VERSION.get(versionIdToUse).values()));
        }
        return milestones;
    }
    /**
     * @description Return the conditional milestones for the parent sObject Ids
     * 1. Retrieve the eligible conditional milestone templates
     * 2. For each Parent sObject record
     * a. Run a comparison check of the milestone templates against existing milestone templates
     * b. Prepare a collection of miletone templates that do not already exist for that Parent sObject record
     * c. Prepare and return the Collection of milestone records for the milestone templates from previous step
     * @return List<Milestone__c>  
     */      
    public abstract List<Milestone__c> getConditionalMilestones();
    /**
     * a. Run a comparison check of the input collection of  milestone templates against existing milestone templates
     * b. Prepare and return the Collection of milestone records, for the milestone templates, not found on the Parent sObject record
     * @param parentSObjectId Parent sObject record Id for whih the milesones need to be generated
     * @param List<Milestone_Template__c> Input collection of milestone templates
     * @return List<Milestone__c> collection of Milestone records
     */    
    public List<Milestone__c> getMilestones(Id parentSObjectId, List<Milestone_Template__c> templates){
        List<Milestone__c> milestones = new List<Milestone__c>();
        for (Milestone_Template__c template : templates){
            // Process if there are no existing milestones for the parent sobject record
            // Or, if the input template is not found within the existing milestone records for the parent sobject record
            
            if (!this.existingMilestoneTemplates.containsKey(parentSObjectId) || !milestoneAlreadyExists(parentSObjectId, template)) {
                milestones.add(createMilestoneRecord(parentSObjectId, template));
            } 
        }
        return milestones;
    }
    
    public Boolean milestoneAlreadyExists(Id parentSObjectId, Milestone_Template__c template) {
        Set<String> templatesForParent = this.existingMilestoneTemplates.get(parentSObjectId);
        
        return templatesForParent.contains(template.Id) || templatesForParent.contains(template.Name);
    }
    
    /**
     * Create a Milestone record for a parent sObject record Id and a Milestone template
     * @param parentSObjectId Parent sObject record Id of the milestone
     * @param template The template for the new milestone
     * @return Milestone__c record
     */
    public Milestone__c createMilestoneRecord(Id parentSObjectId, Milestone_Template__c template) {
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
        milestone.put(this.parentSObjectReferenceField, parentSObjectId);
        return milestone;
    }

    /**
        @author: Dan Thoreson
        @date: 18-Aug-2022
        @description: Populates the maps for Default and Creational Milestones
    **/
    public void partitionMilestonesByCreationType(Id mtvId, List<Milestone_Template__c> templates) {
        if(templates == null) {
            return;
        }

        for(Milestone_Template__c thisTemplate : templates) {
            switch on thisTemplate.Milestone_Creation_Type__c {
                when 'Default'      { DEFAULT_MILESTONE_TEMPLATES_BY_VERSION.get(mtvId).put(thisTemplate.Id, thisTemplate); }
                when 'Conditional'  { CONDITIONAL_MILESTONE_TEMPLATES_BY_VERSION.get(mtvId).put(thisTemplate.Id, thisTemplate); }
                when else { }
            }  
        }
    }
}