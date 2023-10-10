/********************************************************************************************************************
* @author Sriram
* @date 11/08/2021
*
* @group Merchant Services
*
* @description Apex test class for Merchant Services Constants related operations
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSxConstantsTest {
    /**
     * @description Test the add business days method
     */
    @isTest
    public static void testAddBusinessDays() {
        System.assertEquals(Date.newInstance(2022, 12, 16), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 12), 4)); //input date weekday monday
        System.assertEquals(Date.newInstance(2022, 12, 19), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 12), 5)); //input date weekday monday

        System.assertEquals(Date.newInstance(2022, 12, 16), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 13), 3)); //input date weekday tuesday
        System.assertEquals(Date.newInstance(2022, 12, 19), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 13), 4)); //input date weekday tuesday

        System.assertEquals(Date.newInstance(2022, 12, 16), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 14), 2)); //input date weekday wednesday
        System.assertEquals(Date.newInstance(2022, 12, 19), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 14), 3)); //input date weekday wednesday

        System.assertEquals(Date.newInstance(2022, 12, 16), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 15), 1)); //input date weekday thursday
        System.assertEquals(Date.newInstance(2022, 12, 19), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 15), 2)); //input date weekday thursday
        
        System.assertEquals(Date.newInstance(2022, 12, 16), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 16), 0)); //input date weekday friday
        System.assertEquals(Date.newInstance(2022, 12, 19), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 16), 1)); //input date weekday friday
        
        System.assertEquals(Date.newInstance(2022, 12, 19), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 17), 1)); //input date weekday saturday
        System.assertEquals(Date.newInstance(2022, 12, 19), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 18), 1)); //input date weekday sunday

        System.assertEquals(Date.newInstance(2022, 12, 26), CDdMxSxConstants.addBusinessDays(Date.newInstance(2022, 12, 18), 7)); //input date weekday sunday with 7 days input
    }    
}