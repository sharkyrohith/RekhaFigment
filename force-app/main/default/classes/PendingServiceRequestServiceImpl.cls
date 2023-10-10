/**
 * @author  Nayana K
 * @date    August 2023
 * @description This is the service implementation class for Pending Service Request
 */
public inherited sharing class PendingServiceRequestServiceImpl implements IPendingServiceRoutingService {
    /**
    * @description : Method to insert PSR records for Attribute Based routing
    * @param String errorMsg
    */
    public String createSkillBasedPSR(List<PendingServiceRoutingService.PSRSkillBasedWrapper> lstPSRRecordsToInsert){
        String errorMsg = CDdCoreConstants.BLANK_STRING;
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        List<PendingServiceRouting> lstPSRs = new List<PendingServiceRouting>();
        for(PendingServiceRoutingService.PSRSkillBasedWrapper pWrap: lstPSRRecordsToInsert){
            PendingServiceRouting psrRec = new PendingServiceRouting(CapacityWeight=pWrap.capacityWeight,
                            IsReadyForRouting = pWrap.isReadyForRouting,RoutingModel =pWrap.routingModel,
                            RoutingPriority =pWrap.routingPriority,RoutingType=CDdSupportConstants.SKILL_BASED_ROUTING_TYPE,
                            ServiceChannelId = pWrap.serviceChannelId ,WorkItemId= pWrap.workItemId,
                            PushTimeout = pWrap.pushTimeOut);
            //Register PSR records
            uow.registerNew(psrRec);
            lstPSRs.add(psrRec);
            for(PendingServiceRoutingService.PSRSkillRequirementWrapper skillReq : pWrap.lstSkills){
                SkillRequirement objSkill = new SkillRequirement();
                objSkill.SkillId = skillReq.skillId;
                if(skillReq.isAdditionalSkill){
                    objSkill.IsAdditionalSkill = skillReq.isAdditionalSkill;
                    objSkill.SkillPriority = skillReq.skillPriority;
                }
                objSkill.SkillLevel = skillReq.skillLevel;
                //Register PSR record and SKill relationshil
                uow.registerRelationship(objSkill, SkillRequirement.RelatedRecordId, psrRec);
                //Register Skill records
                uow.registerNew(objSkill);
            }
        }
        try {
            //commit the work
            uow.commitWork();
            //Update IsReadyForRouting for PSR records for routing
            fflib_ISObjectUnitOfWork uowUpdate = Application.UnitOfWork.newInstance();
            for(PendingServiceRouting psrRec : lstPSRs){
                psrRec.IsReadyForRouting = true;
                uowUpdate.registerDirty(psrRec);
            }
            //commit the work
            uowUpdate.commitWork();
        }catch (Exception e) {
            errorMsg = CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e);
        }
        return errorMsg;
    }
}