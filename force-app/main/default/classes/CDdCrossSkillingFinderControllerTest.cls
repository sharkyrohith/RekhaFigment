// ===========================================================================
// Component: CDdCrossSkillingFinderControllerTest
// Author: Nayana Kapse
// Purpose: Test class for CDdCrossSkillingFinderController
// ===========================================================================
@isTest
public with sharing class CDdCrossSkillingFinderControllerTest {
    @testSetup static void testSetup() {
        //Creating Group
        Group testGroup = new Group(Name='QUEUE NAME', Type='Queue');
        insert testGroup;
        QueuesObject testQueue;

        //Inserting user as sandbox/Prod email mismatch(.invalid)
        Id userProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        List<User> lstUser = TDdUserFactory.createUsersWithoutRole(2,null,false);
        lstUser[0].Email = 'newDomain@taskUsNewDomain.com';
        lstUser[0].CompanyName = 'TaskUs';
        lstUser[1].Email = 'user1129959@alorica.com';
        lstUser[1].CompanyName = 'Alorica';
        insert lstUser;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            //Associating queue with group AND to the Case object
            testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert testQueue;

            List<GroupMember> lstGrpMember = new List<GroupMember>();
            for(User u : lstUser){
				lstGrpMember.add(new GroupMember(GroupId = testGroup.Id,UserOrGroupId=u.Id));
            }
            insert lstGrpMember;
        }
        System.runAs(new User(Id=UserInfo.getUserId())) {
            //insert custom settings for mapping routing destination to queue Id
            Support_Assignment_Mapping__c mxSxQMapping = new Support_Assignment_Mapping__c();
            mxSxQMapping.Name = 'Queue Name';
            mxSxQMapping.Queue_Id__c = testGroup.Id;
            mxSxQMapping.Support_Assignment_Name__c = 'Queue Name';
            mxSxQMapping.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
            mxSxQMapping.Preferred_Vendor__c = 'TaskUs';
            insert mxSxQMapping;
        }
    }

    @isTest static void testgetOmniEnabledQueues() {
        CDdCrossSkillingFinderController.PicklistWrapper pickWrap =
        CDdCrossSkillingFinderController.getOmniEnabledQueues();
        System.assertEquals(true, pickWrap.queueOptions.size()>0, 'Should return 1 queue option');
        System.assertEquals(true, pickWrap.vendorOptions.size()>0, 'Should return vendor option');

    }

    @isTest static void testfindCrossSkilling() {
        CDdCrossSkillingFinderController.VendorUserDetailWrapper vWrap =
        CDdCrossSkillingFinderController.findCrossSkilling('Queue_Name','TaskUs');
        System.assertEquals(true, vWrap.lstUserWrapper.size()>0, 'Should return user wrapper');
        System.assertEquals(true, vWrap.mapDiffDomainWithUsers.size()>0, 'Should return 2 users as from different vendor');
    }
}