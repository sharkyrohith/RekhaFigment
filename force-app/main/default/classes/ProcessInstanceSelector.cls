public inherited sharing class ProcessInstanceSelector extends fflib_SObjectSelector implements IProcessInstanceSelector {
      /**
     * @description default constructor for the MXP BoB Update Request Selector class
     * @return  - interface of IApprovalSelector
     */
    public static IProcessInstanceSelector newInstance() {
        return (IProcessInstanceSelector) Application.Selector.newInstance(ProcessInstance.SObjectType);
    }

     /**
     * @description This method is for getting the fields on account object
     * @return List of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            ProcessInstance.Id,
            ProcessInstance.TargetObjectId,
            ProcessInstance.LastActorId,
            ProcessInstance.CompletedDate,
            ProcessInstance.Status
        };
    }

     /**
     * @description This method is used for getting Object type
     * @return Schema.SObjectType
     */
    public Schema.SObjectType getSObjectType() {
        return ProcessInstance.SObjectType;
    }

    /**
     * @description This method is used for getting Sobject type Id
     * @param recordIds
     * @return List<IProcessInstanceSelector>
     */
    public List<ProcessInstance> selectByParentId(Set<Id> idSet) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('TargetObjectId IN :idSet');
        return (List<ProcessInstance>) Database.query(query.toSOQL());
    }

     /**
     * @description This method is used for getting Sobject type Id
     * @param recordIds
     * @return Map<Id,String> : Map of parent id and approver email
     */
    public Map<Id,String> getMapParentApprovalEmail(Set<Id> idSet) {
        Map<Id,String> mapParentApproverEmail = new Map<Id,String>();
        fflib_QueryFactory query = newQueryFactory()
                                   .selectField('LastActor.Email')
                                   .setCondition('LastActor.IsActive = true AND TargetObjectId IN :idSet AND Status = \'Approved\'');
        for(ProcessInstance aRec: (List<ProcessInstance>) Database.query(query.toSOQL())){
            mapParentApproverEmail.put(aRec.TargetObjectId,aRec.LastActor.Email);
        }
        return mapParentApproverEmail;
    }


}