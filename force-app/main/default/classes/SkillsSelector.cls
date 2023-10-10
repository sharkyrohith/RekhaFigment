public inherited sharing class SkillsSelector extends fflib_SObjectSelector implements ISkillSelector {
     /**
     * @description default constructor for the skill Selector class
     * @return  - interface of ISkillSelector
     */
    public static ISkillSelector newInstance() {
        return (ISkillSelector) Application.Selector.newInstance(Skill.SObjectType);
    }

    /**
     * @description This method is for getting the fields Attribute Based Routing
     * @return List of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Skill.Id,
            Skill.DeveloperName,
            Skill.MasterLabel
        };
    }

     /**
     * @description This method is used for getting Object type
     * @return Schema.SObjectType
     */
    public Schema.SObjectType getSObjectType() {
        return Skill.SObjectType;
    }

    /**
     * @description Method for querying skill records
     * @return A list of all skilld records
     */
    public List<Skill> selectAllSkills() {
        return (List<Skill>) Database.query(newQueryFactory().toSOQL());
    }
}