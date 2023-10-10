/**
 * @description       : Test class for SurveySitesUtil
 * @author            : Jose Vega
 * @last modified on  : 03-13-2023
 * @last modified by  : Jose Vega
**/
@isTest
public class  SurveySitesUtilTest {

    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    @isTest
    static void testSurveySiteInfo() {
        SurveySitesUtil.SurveySiteInfo info = new SurveySitesUtil.SurveySiteInfo('one', 'two', 'three');
        System.assertEquals(info.name, 'one');
        System.assertEquals(info.prefix, 'two');
        System.assertEquals(info.subdomain, 'three');
    }

    @isTest
    static void testHasSites() {
        SurveySitesUtil util = new SurveySitesUtil();

        if (SOBJECT_TYPES.keySet().contains('site')) {
            System.assert(util.hasSites());
        } else {
            System.assert(!util.hasSites());
        }
    }

    @isTest
    static void testGetInfo() {
        SurveySitesUtil util = new SurveySitesUtil();
        System.assert(util.getSiteList() != null);
        if (util.hasSites()) {
            if (util.getSiteList().size() > 0) {
                SurveySitesUtil.SurveySiteInfo current = util.getSiteList()[0];
                System.assert(current != null);
            }
        }
    }
}