/** 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Factory to create leads
 */

public class TDdLeadFactory {
    public static List<Lead> createLeads(String lastName, Integer numberOfLeads, boolean doInsert) {
        return createLeads(lastName, numberOfLeads, 'Master Lead', doInsert); 
    }
    
    public static List<lead> createLeads(String lastName, Integer numberOfLeads, String RecordType, boolean doInsert) {

        List<Lead> leadsToBeCreated = new List <Lead>(); 
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        for (Integer count = 0 ; count < numberOfLeads; count++) {
            Lead currLead = new Lead (LastName = lastName + count,
                                        Company = lastName + count, 
                                        Phone = '(123) 234-235' + count, 
                                        Street = '12' + count + ' Mulberry Ln',
                                        City = 'South San Francisco',
                                        State = 'CA',
                                        PostalCode = '9410' + count, 
                                        CountryCode = 'US',
                                        Validation_Bypass__c = false,
                                        Business_ID__c = 1,
                                        RecordTypeId = leadRecordTypeId,
                                        Lead_List__c = System.today(),
                                        Store_ID__c = '12345' + count,
                                        ARR__c = 1000.00,
                                        Amount__c = 1000.00,
                                        Lead_Type__c = 'Net New',
                                        Deck_Rank__c = 'Ace of Spades',
                                        Starting_Point__c = '100',
                                        Starting_Point_ID__c = 100,
                                        Deactivation_Note__c = 'Test Deactivation Note',
                                        Deactivation_Code__c = 'Awaiting activation',
                                        Type__c = 'Franchise', //Team Type
                                        Launch_Deck_Rank__c = 'Ace'); 

            leadsToBeCreated.add(currLead);
        }
        if(doInsert) {
            insert leadsToBeCreated; 
        }
        return leadsToBeCreated; 
    }
    
}