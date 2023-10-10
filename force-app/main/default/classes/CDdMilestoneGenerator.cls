/********************************************************************************************************************
* @author Sriram
* @date 08/04/2021
*
* @group Milestone
*
* @description Interface for Milestone generation
*   Majority of the functions/responsibilities w.r.t milestone generation are performed in Apex ClassCDdMilestoneGeneratorImpl. Responsibilities are outlined below.
*   1. Determine if the sObject record has existing milestones associated with it
*   2. Gather the default milestone templates for the specific combination of sObject type and record type as found on the sObject record
*   3. Determine the missing milestone templates for the sObject record, by comparing the collection of default and conditional templates (the sObject is eligible for) against the existing collection of milestones (if any) associated with sObject record currently
*   4. Finally, create the Milestones (missing ones or all from comparison as outlined in prior bullet point) in the Milestone sObject within Salesforce
*   Eligibility of Conditional milestones is determined in the sub-class specific to Parent sObject and Parent sObject record type 
* 
**************************************************************************************************************************************/
public interface CDdMilestoneGenerator {
    /**
     * @description Set the parent attributes/characteristics to determine the appropriate milestone templates for milestone generation.
     * Current attributes of the parent record that are computed to determine what the appropriate milestone templates should be, are as follows
     * 1. Parent SObject Type
     * 2. Parent Record Type
     * @param String parentSObjectType - what is the parent sObject Type for which the milestones are being generated?
     * @param Id parentSObjectRecordTypeId - what is the parent sObject Record Type Id or which the milestones are being generated?
     * @param String parentSObjectReferenceField - this the parent reference field found on the Milestone custom object for the specific parent sObject type
     */    
    void setParentAttributes(String parentSObjectType, Id parentSObjectRecordTypeId, String parentSObjectReferenceField);
    /**
     * @description Set the Parent sObject Record Ids for the milestone generation.
     * @param Map<Id, SObject> parentSObjectRecords - a map of SObjects with their IDs that will be processed for milestone generation
     * @return  
     */
    void setParentSObjectRecords(Map<Id, SObject> parentSObjectRecords);
    /**
     * @description Execute milestone generation of relevant default and conditional milestones for all Parent sObject Records
     * @return  
     */    
    void execute();
}