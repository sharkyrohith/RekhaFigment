public interface IProcessInstanceSelector extends fflib_ISObjectSelector {
    /**
     * @description This method id for getting object type by parent Id
     * @param idSet
     * @return ListMap<Approval> - List Approval
     */
    List<ProcessInstance> selectByParentId(Set<Id> idSet);

    /**
     * @description This method id for getting object type
     * @param idSet: Parent Id
     * @return ListMap<MXP_BoB_Update_Request__c> - List MXP_BoB_Update_Request__c
     */
    Map<Id,String> getMapParentApprovalEmail(Set<Id> idSet);
}