/**
 * @description Selector Class for Lead SObject
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
public inherited sharing class LeadsSelector extends SObjectsSelector implements ILeadsSelector {
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the ILeadsSelector
     */
    public static ILeadsSelector newInstance() {
        return (ILeadsSelector) Application.Selector.newInstance(Lead.SObjectType);
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Lead.Id,
            Lead.FirstName,
            Lead.LastName,
            Lead.Street,
            Lead.City,
            Lead.State,
            Lead.Country,
            Lead.PostalCode
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Lead.SObjectType;
    }

    /**
     * @description Method for querying Lead records when you know their ids
     *
     * @param ids The ids of the records to be returned
     * @return A list of Lead records
     */
    public List<Lead> selectById(Set<Id> ids) {
        return (List<Lead>) selectSObjectsById(ids);
    }

    /**
     * @description Method for querying Lead records by Created By Contacts
     *
     * @param ids The ids of the records to be returned
     * @return A list of Lead records
     */
    public List<Lead> selectLeadsByCreatedFromContact(Set<Id> contactIds) {
        return (List<Lead>) Database.query(
            newQueryFactory()
                .selectField('Primary_Merchant_Category__c')
                .selectField('Created_from_Contact__c')
                .setCondition('Created_from_Contact__c =: contactIds AND Created_from_Contact__c != null')
                .toSoql()    
        );
    }
}