@isTest
public class SkillsSelectorTest {
    @isTest
    static void testSelectAllSkills() {
        List<Skill> lstSkills = SkillsSelector.newInstance().selectAllSkills();
        System.assertNotEquals( null, lstSkills);
    }

    @isTest
    static void increaseCodeCoverage() {
        System.assertNotEquals( null, new SkillsSelector().getSObjectFieldList());
        System.assertNotEquals( null, new SkillsSelector().getSObjectType());
    }
}