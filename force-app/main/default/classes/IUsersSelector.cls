/**
 * @description Interface for the UsersSelector
 *
 * @author Scott McClung
 */
public interface IUsersSelector extends ISObjectsSelector {
    /**
     * @description Method for querying User records when you know their ids
     * @param userIds The ids of the records to be returned
     * @return A list of User records
     */
    List<User> selectById( Set<Id> userIds );

    /**
     * @description Method for querying User records by Name, Email, Profile Name and Role Name
     * @param nameSerchVal Name Search string
     * @param emailSearchVal Email Search String
     * @param profileSearchVal Profile Search String
     * @param roleSeachVal UserRole Search String
     * @param limitCount max number of User records to be returned
     * @return A list of User records
     */
    List<User> selectByNameEmailProfileRole(String nameSerchVal, String emailSearchVal, String profileSearchVal, String roleSeachVal, Integer limitCount);
    /**
     * @description It is used for getting User Ids based on the EmailAddress
     * @param emailids
     * @return List<User>
     */
    List<User> selectUserIdsByEmailAddress(Set<String> emailIds);
}