@isTest
public with sharing class VQueueMonitorControllerTest {
	@isTest
	static void testProperties() {
		VQueueMonitorController controller = new VQueueMonitorController();
		System.assertEquals(null, controller.availablePresenceStatusId);
		System.assertNotEquals(null, controller.isLiveAgentUser);
	}

	@isTest
	static void testGetQueueMembership() {
		User su = VTestUtil.createSupervisorUserHierarchy();
		User cu = [select Id from User where ManagerId = :su.Id];

		List<ID> queueIds = new List<ID>(VQueueMonitorController.getQueueIds());

		GroupMember gm = new GroupMember(
			GroupId = queueIds[0],
			UserOrGroupId = cu.Id
		);

		insert gm;

		Test.startTest();
		System.runAs(cu) {
			System.assertNotEquals(null, VQueueMonitorController.getCurrentQueueMembership());
		}
		Test.stopTest();
	}
}