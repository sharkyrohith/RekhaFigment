@isTest
public with sharing class VQueueManagementControllerTest {
	@isTest
	static void testGetQueues() {
		System.assertNotEquals(null, VQueueManagementController.getQueues());
	}

	@isTest
	static void testGetUsers() {
		User su = VTestUtil.createSupervisorUserHierarchy();

		Test.startTest();
		System.runAs(su) {
            List<UserRole> urList = VQueueManagementController.getUserRoles();
			System.assertNotEquals(null, VQueueManagementController.getUsers(new List<String>{urList[0].Id}));
		}
		Test.stopTest();
	}

    /*
     * JN-NOTE (09.29.17) - Got rid of the call to getQueueIds because of two reasons
     * 1. We already call this somewhere, so the code is covered
     * 2. Unit tests have no access to existing Queues, so we have to generate a new one
     */
	@isTest
	static void testUpdateQueues() {
		User su = VTestUtil.createSupervisorUserHierarchy();
		User cu = [select Id from User where ManagerId = :su.Id];

		//Set<ID> queueIds = VQueueManagementController.getQueueIds();
		Set<ID> queueIds = new Set<ID>();
        
        Group g1 = new Group(Name='group name', type='Queue');
        insert g1;
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Lead');
        insert q1;
        
        queueIds.add(g1.Id);

		Test.startTest();
		System.runAs(su) {
			
			List<String> userIds = new List<String> { cu.Id };

			VQueueManagementController.updateQueues(userIds, new List<ID>(queueIds));
		}
		Test.stopTest();

		System.assertEquals(queueIds.size(), [select count() from GroupMember where UserOrGroupId = :cu.Id]);
	}
	

	@isTest
	static void testConstructor() {
		// for coverage
		VQueueManagementController controller = new VQueueManagementController();
	}
}