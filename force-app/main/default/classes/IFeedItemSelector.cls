/**
 * @description Interface for the FeedItemSelector
 *
 * @author Mahesh Chouhan
 * @date May 2023
 */
public interface IFeedItemSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Feed Item records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Feed Item records
     */
    List<FeedItem> selectById(Set<Id> ids);

    /**
     * @description Method for querying Feed Item of TextPost type for given Parent Ids
     * @param parentIds Ids of the Parent Record
     * @return A list of Feed Item records
     */
    List<FeedItem> selectTextPostByParentId(Set<Id> parentIds);
}