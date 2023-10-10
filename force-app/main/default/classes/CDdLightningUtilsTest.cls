/**
 * @author Mahesh Chouhan
 * @date Jan 2022
 * @description Test class for CDdLightningUtils utility class
 */

@isTest
public class CDdLightningUtilsTest {
    /**
     * @description Test method for getUiThemeDisplayed method
     */
    @isTest
    static void testGetUiThemeDisplayed(){
        System.assertEquals('Theme3', CDdLightningUtils.getUiThemeDisplayed(), 'Salesforce UI Interface is not same as expected.');
    }

    @isTest
    static void testGetNavType(){
        String navType = CDdLightningUtils.getNavType();
        System.assert(navType == 'Standard' || navType == 'Console', 'Invalid Nav Type: ' + navType);
    }
}