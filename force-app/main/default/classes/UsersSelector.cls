/**
 * @description Selector Class for User SObject
 * @author Scott McClung
 * @date 2022/09/07
 */

public virtual inherited sharing class UsersSelector
    extends SObjectsSelector
    implements IUsersSelector {

    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     * @return A concrete or mock implementation of the IUsersSelector
     */
    public static IUsersSelector newInstance() {
        return (IUsersSelector) Application.Selector.newInstance( User.SObjectType );
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            User.Id,
            User.Name,
            User.ADR__c,
            User.Email,
            User.UserProfile__c,
            User.UserRole__c,
            User.Photo_Document_URL__c
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return User.SObjectType;
    }

    /**
     * @description Method for querying User records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of User records
     */
    public List<User> selectById( Set<Id> ids ) {
        return (List<User>) selectSObjectsById( ids );
    }

    /**
     * @description It is used for getting User Ids based on the EmailAddress
     * @param emailids
     * @return List<User>
     */
    public List<User> selectUserIdsByEmailAddress(Set<String> emailIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Email IN: emailIds AND IsActive = true');
        return (List<User>) Database.query(query.toSOQL());
    }
    /**
     * @description Method for querying User records by Name, Email, Profile Name and Role Name
     * @param nameSerchVal Name Search string
     * @param emailSearchVal Email Search String
     * @param profileSearchVal Profile Search String
     * @param roleSeachVal UserRole Search String
     * @param limitCount max number of User records to be returned
     * @return A list of User records
     */
    public List<User> selectByNameEmailProfileRole(String nameSerchVal, String emailSearchVal, String profileSearchVal, String roleSeachVal, Integer limitCount) {
        List<String> filters = new List<String>();
        if(String.isNotBlank(nameSerchVal)){
            filters.add(' Name LIKE '+'\'%'+ String.escapeSingleQuotes(nameSerchVal) +'%\'');
        }
        if(String.isNotBlank(emailSearchVal)){
            filters.add(' Email LIKE '+'\'%'+ String.escapeSingleQuotes(emailSearchVal)+'%\'');
        }
        if(String.isNotBlank(profileSearchVal)){
            filters.add(' Profile.Name LIKE '+'\'%'+ String.escapeSingleQuotes(profileSearchVal)+'%\'');
        }
        if(String.isNotBlank(roleSeachVal)){
            filters.add(' UserRole.Name LIKE '+'\'%'+String.escapeSingleQuotes(roleSeachVal)+'%\''); 
        }

        String whereClause = String.join(filters, 'AND');
        fflib_QueryFactory query = newQueryFactory()
        .setCondition(whereClause)
        .setLimit(limitCount);
        
        return Database.query(query.toSOQL());
    }
}