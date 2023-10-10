/**
 * @description Test Class for FeedItemSelector class
 * @author Mahesh Chouhan
 * @date June 2023
 */
@isTest
public class FeedItemSelectorTest {

    /**
     * @description test method for selectById method
     */
    @isTest
    static void testSelectById(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        insert caseList;

        FeedItem cFeed = new FeedItem();
        cFeed.Title = 'Feed Title';
        cFeed.ParentId = caseList[0].Id;
        cFeed.Body = 'Feed Body';

        insert cFeed;

        List<FeedItem> retrievedFeedItems = FeedItemSelector.newInstance().selectById(new Set<Id>{cFeed.Id});
        System.assert(retrievedFeedItems.size() > 0, 'No Feed Item found for Parent Case');
        System.assertEquals('Feed Title', retrievedFeedItems[0].Title, 'Title of Feed Item is not same as expected.');
    }

    /**
     * @description test method for selectTextPostByParentId method
     */
    @isTest
    static void testSelectTextPostByParentId(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        insert caseList;

        FeedItem cFeed = new FeedItem();
        cFeed.Title = 'Feed Title';
        cFeed.ParentId = caseList[0].Id;
        cFeed.Body = 'Feed Body';

        insert cFeed;

        List<FeedItem> retrievedFeedItems = FeedItemSelector.newInstance().selectTextPostByParentId(new Set<Id>{caseList[0].Id});
        System.assert(retrievedFeedItems.size() > 0, 'No Feed Item found for Parent Case');
        System.assertEquals('Feed Title', retrievedFeedItems[0].Title, 'Title of Feed Item is not same as expected.');
    }
}