public with sharing class VQueueMonitorController {

	public VQueueMonitorController() {
		
	}

	public String availablePresenceStatusId {
		get {
			vCS__c settings = vCS__c.getInstance();
			return settings.AvailablePresenceStatusId__c;
		}
	}

	public String isLiveAgentUser {
		get {
			User u = [select Id, UserPermissionsLiveAgentUser from  User where ID = :UserInfo.getUserId()];
			return String.valueOf(u.UserPermissionsLiveAgentUser);
		}
	}

	@RemoteAction
	public static List<ID> getCurrentQueueMembership() {
		List<ID> res = new List<ID>();

		Set<ID> queueIds = getQueueIds();

		for(GroupMember m : [select Id 
			from GroupMember
			where UserOrGroupId = :UserInfo.getUserId()
			and GroupId in :queueIds]) {

			res.add(m.Id);
		}

		return res;

		
	}

	@TestVisible
	private static Set<ID> getQueueIds() {
		Set<ID> res = new Set<ID>();

		for(QMQueueSetting__mdt m : [select Id, QueueId__c
			from QMQueueSetting__mdt]) {

			res.add(m.QueueId__c);
		}

		return res;
	}
}