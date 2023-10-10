public interface ISkillSelector extends fflib_ISObjectSelector {
    /**
     * @description Method for querying skill records
     * @return A list of all skilld records
     */
    List<Skill> selectAllSkills();
}