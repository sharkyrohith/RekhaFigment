/********************************************************************************************************************
* @author Sriram
* @date 12/19/2022
*
* @group Merchant Services
*
* @description Apex test class for Merchant Services Opportunity Trigger Helper
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSxOpportunityTriggerHelperTest {
	@isTest
	private static void testPdomPdoaForCOOMarketplaceOpportunity() {

        MxSxApexMockTestDataFactory oldTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity oldOpportunity = oldTestDataFactory.marketplaceOpportunity;
        oldOpportunity.Platform__c = 'DoorDash';
        oldOpportunity.Type = 'Change of Ownership';
        oldOpportunity.Change_of_Ownership_Effective_Date__c = Date.newInstance(2022, 12, 26);
        oldOpportunity.StageName = 'Meeting Ran / Negotiated';
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE ID = : oldOpportunity.Id]);

        MxSxApexMockTestDataFactory newTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity newOpportunity = newTestDataFactory.marketplaceOpportunity;
        newOpportunity.Id = oldOpportunity.Id;
        newOpportunity.Platform__c = 'DoorDash';
        newOpportunity.Type = 'Change of Ownership';
        newOpportunity.Change_of_Ownership_Effective_Date__c = Date.newInstance(2022, 12, 26);
        newOpportunity.StageName = 'Closed Won';
        newOpportunity.CloseDate = Date.newInstance(2022, 12, 1);
        List<Opportunity> newList = new List<Opportunity>{ newOpportunity };

        new CDdMxSxOpportunityTriggerUpdateHelper().applyUpdates(newList, oldMap,  new Map<Id, Account>{ newOpportunity.AccountId => newTestDataFactory.marketplaceAccount });

        System.assertEquals(newOpportunity.Change_of_Ownership_Effective_Date__c.addDays(-1), newOpportunity.Proposed_Date_of_Menu__c);
        System.assertEquals(newOpportunity.Change_of_Ownership_Effective_Date__c, newOpportunity.Proposed_Date_of_Activation__c);

    }

	@isTest
	private static void testPdomPdoaForCOOCaviarPOSMarketplaceOpportunity() {

        MxSxApexMockTestDataFactory oldTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity oldOpportunity = oldTestDataFactory.marketplaceOpportunity;
        oldOpportunity.Platform__c = 'Caviar and DoorDash';
        oldOpportunity.Type = 'Change of Ownership';
        oldOpportunity.Order_Protocol__c = 'POS';
        oldOpportunity.Change_of_Ownership_Effective_Date__c = Date.newInstance(2022, 12, 26);
        oldOpportunity.StageName = 'Meeting Ran / Negotiated';
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE ID = : oldOpportunity.Id]);

        MxSxApexMockTestDataFactory newTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity newOpportunity = newTestDataFactory.marketplaceOpportunity;
        newOpportunity.Id = oldOpportunity.Id;
        newOpportunity.Platform__c = 'Caviar and DoorDash';
        newOpportunity.Type = 'Change of Ownership';
        newOpportunity.Order_Protocol__c = 'POS';
        newOpportunity.Change_of_Ownership_Effective_Date__c = Date.newInstance(2022, 12, 26);
        newOpportunity.StageName = 'Closed Won';
        newOpportunity.CloseDate = Date.newInstance(2022, 12, 1);
        List<Opportunity> newList = new List<Opportunity>{ newOpportunity };

        new CDdMxSxOpportunityTriggerUpdateHelper().applyUpdates(newList, oldMap,  new Map<Id, Account>{ newOpportunity.AccountId => newTestDataFactory.marketplaceAccount });

        System.assertEquals(newOpportunity.CloseDate.addDays(13), newOpportunity.Proposed_Date_of_Menu__c);
        System.assertEquals(newOpportunity.CloseDate.addDays(14), newOpportunity.Proposed_Date_of_Activation__c);

    }
    
	@isTest
	private static void testPdomPdoaForCOOCaviarTabletMarketplaceOpportunity() {

        MxSxApexMockTestDataFactory oldTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity oldOpportunity = oldTestDataFactory.marketplaceOpportunity;
        oldOpportunity.Platform__c = 'Caviar and DoorDash';
        oldOpportunity.Type = 'Change of Ownership';
        oldOpportunity.Order_Protocol__c = 'Tablet (DoorDash Owns)';
        oldOpportunity.Change_of_Ownership_Effective_Date__c = Date.newInstance(2022, 12, 26);
        oldOpportunity.StageName = 'Meeting Ran / Negotiated';
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE ID = : oldOpportunity.Id]);

        MxSxApexMockTestDataFactory newTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity newOpportunity = newTestDataFactory.marketplaceOpportunity;
        newOpportunity.Id = oldOpportunity.Id;
        newOpportunity.Platform__c = 'Caviar and DoorDash';
        newOpportunity.Type = 'Change of Ownership';
        newOpportunity.Order_Protocol__c = 'Tablet (DoorDash Owns)';
        newOpportunity.Change_of_Ownership_Effective_Date__c = Date.newInstance(2022, 12, 26);
        newOpportunity.StageName = 'Closed Won';
        newOpportunity.CloseDate = Date.newInstance(2022, 12, 1);
        List<Opportunity> newList = new List<Opportunity>{ newOpportunity };

        new CDdMxSxOpportunityTriggerUpdateHelper().applyUpdates(newList, oldMap,  new Map<Id, Account>{ newOpportunity.AccountId => newTestDataFactory.marketplaceAccount });

        System.assertEquals(newOpportunity.CloseDate.addDays(6), newOpportunity.Proposed_Date_of_Menu__c);
        System.assertEquals(newOpportunity.CloseDate.addDays(7), newOpportunity.Proposed_Date_of_Activation__c);

    }     

	@isTest
	private static void testPdoaForPOSMarketplaceOpportunity() {

        MxSxApexMockTestDataFactory oldTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity oldOpportunity = oldTestDataFactory.marketplaceOpportunity;
        oldOpportunity.StageName = 'Meeting Ran / Negotiated';
        oldOpportunity.Proposed_Date_of_Activation__c = null;
        oldOpportunity.Proposed_Date_of_Menu__c = null;
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE ID = : oldOpportunity.Id]);

        MxSxApexMockTestDataFactory newTestDataFactory = new MxSxApexMockTestDataFactory();
        Opportunity newOpportunity = newTestDataFactory.marketplaceOpportunity;
        newOpportunity.Id = oldOpportunity.Id;
        newOpportunity.StageName = 'Closed Won';
        newOpportunity.CloseDate = Date.newInstance(2022, 12, 1);
        newOpportunity.Proposed_Date_of_Activation__c = null;
        newOpportunity.Proposed_Date_of_Menu__c = null;
        List<Opportunity> newList = new List<Opportunity>{ newOpportunity };

        new CDdMxSxOpportunityTriggerUpdateHelper().applyUpdates(newList, oldMap,  new Map<Id, Account>{ newOpportunity.AccountId => newTestDataFactory.marketplaceAccount });
        System.assertEquals(newOpportunity.Proposed_Date_of_Activation__c, Date.newInstance(2022, 12, 1).addDays(14));

    }    
}