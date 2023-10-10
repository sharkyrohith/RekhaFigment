/**
 * @description Selector for the Feed Item Object
 *
 * @author Mahesh Chouhan
 * @date June 2023
 */
public inherited sharing class FeedItemSelector extends SObjectsSelector implements IFeedItemSelector{
    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     *
     * @return A concrete or mock implementation of the IFeedItemSelector
     */
    public static IFeedItemSelector newInstance() {
        return (IFeedItemSelector) Application.Selector.newInstance(FeedItem.SObjectType);
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     *
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            FeedItem.Id,
            FeedItem.Body,
            FeedItem.Title,
            FeedItem.ParentId
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     *
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return FeedItem.SObjectType;
    }

    /**
     * @description Method for querying Feed Item records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Feed Item records
     */
    public List<FeedItem> selectById(Set<Id> ids) {
        return (List<FeedItem>) selectSObjectsById(ids);
    }

    /**
     * @description Method for querying Feed Item of TextPost type for given Parent Ids
     * @param parentIds Ids of the Parent Record
     * @return A list of Feed Item records
     */
    public List<FeedItem> selectTextPostByParentId(Set<Id> parentIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(getSObjectFieldList())
            .setCondition('ParentId IN :parentIds AND Type = \'TextPost\'');
        return (List<FeedItem>) Database.query(query.toSOQL());
    }
}