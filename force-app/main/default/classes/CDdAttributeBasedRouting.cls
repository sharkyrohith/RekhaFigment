/**
 * CDdAttributeBasedRouting
 *
 * @author     Nayana
 * @date  Aug 2023
 * @decription  https://doordash.atlassian.net/browse/BIZS-3272
 */
public class CDdAttributeBasedRouting {

    //Input class for flow
    public class MissionCallInput {
        @InvocableVariable(required=true)
        public Case caseRec;
    }

     /**
     * @author     Nayana
     * @date  Aug 2023
     * @decription InvocableMethod method for Skill creation.
     * @return  none
    */
    @InvocableMethod(label='Call MissionControl')
    public static void pushSkillRequirements(List<MissionCallInput> inputs) {
        Map <Id,Case> mapCaseIdCase = new Map <Id,Case>();
        for(MissionCallInput mId:inputs){
            mapCaseIdCase.put(mId.caseRec.Id,mId.caseRec);
        }
        if(!mapCaseIdCase.isEmpty()){
            AttributeBasedRoutingService.pushCasesForAttributeBasedRouting(mapCaseIdCase);
        }
    }
}