/**
* @author Veera
* @date 2021-12
* @description test class for CDdI18nUtility class
*/
@isTest
private class CDdI18nUtilityTest {
    
    /*
    * @author Veera
    * @date 2021-12
    * @description BZAP-12548 - To verify isCountryGermany method
    */
    @isTest
    static void testIsCountryGermany(){

        Test.startTest();
        Boolean isCountryGermany_Null = CDdI18nUtility.isCountryGermany(null);
        Boolean isCountryGermany_Blank = CDdI18nUtility.isCountryGermany(' ');
        Boolean isCountryGermany_DE = CDdI18nUtility.isCountryGermany(CDdI18nUtility.COUNTRY_CODE_GERMANY);
        Boolean isCountryGermany_RandomString = CDdI18nUtility.isCountryGermany('Not DE');
        Test.stopTest();

        System.assertEquals(false, isCountryGermany_Null, 'Assertion failure when country code is Null');
        System.assertEquals(false, isCountryGermany_Blank, 'Assertion failure when country code is Blank');
        System.assertEquals(true, isCountryGermany_DE, 'Assertion failure when country code is DE');
        System.assertEquals(false, isCountryGermany_RandomString, 'Assertion failure when country code not DE');
    }

    /*
    * @author Abhijeet
    * @date 2021-12
    * @description BZAP-1411 - To verify isCountryCANADA method
    */
    @isTest
    static void testIsCountryCANADA() {
        Test.startTest();
        Boolean isCountryCANADA_Null = CDdI18nUtility.isCountryCANADA(null);
        Boolean isCountryCANADA_Blank = CDdI18nUtility.isCountryCANADA(' ');
        Boolean isCountryCANADA_DE = CDdI18nUtility.isCountryCANADA(CDdI18nUtility.COUNTRY_CODE_CANADA);
        Boolean isCountryCANADA_RandomString = CDdI18nUtility.isCountryCANADA('Not CA');
        Test.stopTest();

        System.assertEquals(false, isCountryCANADA_Null, 'Assertion failure when country code is Null');
        System.assertEquals(false, isCountryCANADA_Blank, 'Assertion failure when country code is Blank');
        System.assertEquals(true, isCountryCANADA_DE, 'Assertion failure when country code is DE');
        System.assertEquals(false, isCountryCANADA_RandomString, 'Assertion failure when country code not DE');
    }

    /*
    * @author Veera
    * @date 2021-12
    * @description BZAP-12548 - To verify handleSpecialCharsOnLeadChange method
    */
    @isTest
    static void testSpecialCharsOnLeadChangePositiveCase(){
        String oldBillingStreet = 'Rotebühlstraße 121';
        String newBillingStreet = 'Rotebuhlstr. 121';
        String newDifferentBillingStreet = '155 5th St';
        
        Test.startTest();
        Boolean keepOldAddressforDE = CDdI18nUtility.handleSpecialCharsOnLeadChange(CDdI18nUtility.COUNTRY_CODE_GERMANY,oldBillingStreet,newBillingStreet);
        Boolean keepOldAddressforUS = CDdI18nUtility.handleSpecialCharsOnLeadChange('',oldBillingStreet,newBillingStreet);
        Boolean keepOldAddressforNewAddress = CDdI18nUtility.handleSpecialCharsOnLeadChange(CDdI18nUtility.COUNTRY_CODE_GERMANY,oldBillingStreet,newDifferentBillingStreet);
        Boolean keepOldAddressforNullCountry = CDdI18nUtility.handleSpecialCharsOnLeadChange(null,oldBillingStreet,newBillingStreet);
        Test.stopTest();

        System.assertEquals(true, keepOldAddressforDE, 'Assertion failure when country code is DE');
        System.assertEquals(false, keepOldAddressforUS, 'Assertion failure when country code is US');
        System.assertEquals(false, keepOldAddressforNewAddress, 'failure method not allowing to change the address');
        System.assertEquals(false, keepOldAddressforNullCountry, 'failure address not updated when Country is blank');
    }
}