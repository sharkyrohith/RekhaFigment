/*
 * @author Knick
 * @Date Mar 2020
 * @Description: Test Class for TDdOpportunityFactory
*/
@isTest
public class TDdOpportunityFactoryTest {

    public static testMethod void testCustomSettings() {
        System.assertNotEquals(null, TDdOpportunityFactory.setCustomSettings());
    }
}