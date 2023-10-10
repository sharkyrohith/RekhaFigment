public inherited sharing class PendingServiceRoutingService {
    /**
     * @description :  Method to insert PSR records for Attribute Based routing...
    * @param PSRSkillBasedWrapper - PSR and Skill Requirement Wrapper
    * @return String - Error message
    */
    public static String createSkillBasedPSR(List<PSRSkillBasedWrapper> lstPSRRecordsToInsert) {
       return service().createSkillBasedPSR(lstPSRRecordsToInsert);
    }

     /**
     * @description :  PSR record wrapper
    */
    public class PSRSkillBasedWrapper{
        public Integer capacityWeight;
        public Boolean isReadyForRouting;
        public String routingModel;
        public Integer routingPriority;
        public Id serviceChannelId;
        public Id workItemId;
        public Integer pushTimeOut;
        public List<PSRSkillRequirementWrapper> lstSkills = new List<PSRSkillRequirementWrapper>();
        public PSRSkillBasedWrapper(Integer cWeight,Boolean isReady, String rModel,Integer rPriority,
                                Id sChannelId, Id wItemId, Integer pTimeout){
            this.capacityWeight = cWeight;
            this.isReadyForRouting = isReady;
            this.routingModel = rModel;
            this.routingPriority = rPriority;
            this.serviceChannelId = sChannelId;
            this.workItemId = wItemId;
            this.pushTimeOut = pTimeout;
        }
    }

     /**
     * @description : Skill Requirement Wrapper
    */
    public class PSRSkillRequirementWrapper{
        public Id skillId;
        public Decimal skillLevel;
        public Integer skillPriority;
        public Boolean isAdditionalSkill;
        public PSRSkillRequirementWrapper(Id sId,Decimal sLevel,Integer sPriority, Boolean additionalSkill){
            this.skillId = sId;
            this.skillLevel = sLevel;
            this.skillPriority = sPriority;
            this.isAdditionalSkill = additionalSkill;
        }
    }

    /**
     * @description It creates instance of IPendingServiceRoutingServiceImpl class.
     * @return  - return instance of IPendingServiceRoutingService
     */

     private static IPendingServiceRoutingService service() {
        return (IPendingServiceRoutingService) Application.Service.newInstance(
            IPendingServiceRoutingService.class
        );
    }
}