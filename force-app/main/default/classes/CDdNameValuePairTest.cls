@isTest
public class CDdNameValuePairTest {
    private static string TEXT_CMT = 'Test_Class_Text';
    private static string TEXT_LONG_CMT = 'Test_Class_Text_Long';
    private static string NUMBER_CMT = 'Test_Class_Number';
    private static string BOOLEAN_CMT = 'Test_Class_Boolean';
    private static string DATETIME_CMT = 'Test_Class_DateTime';
    private static string DATE_CMT = 'Test_Class_Date';

    private static string DNE = '_DOES_NOT_EXIST';

    @IsTest
    static void testMethod1(){
        system.assert(CDdNameValuePairHelper.getLongTextValue(TEXT_LONG_CMT,'DEFAULT').length() > 255,'Invalid CMT selected');
        system.assertEquals('DEFAULT',CDdNameValuePairHelper.getLongTextValue(TEXT_LONG_CMT + DNE,'DEFAULT'));
        system.assert(CDdNameValuePairHelper.getLongTextValue(TEXT_LONG_CMT,'DEFAULT').length() > 255,'Invalid CMT selected'); // Testing Cache

        system.assertEquals('Hello!',CDdNameValuePairHelper.getTextValue(TEXT_CMT,'DEFAULT'));
        system.assertEquals('DEFAULT',CDdNameValuePairHelper.getTextValue(TEXT_CMT + DNE,'DEFAULT'));
        system.assertEquals('Hello!',CDdNameValuePairHelper.getTextValue(TEXT_CMT,'DEFAULT')); // Testing Cache

        Integer intHundred = 100;
        Decimal decHundred = 100.0;
        Integer intThousand = 1000;
        Decimal decThousand = 1000.0;

        system.assertEquals(intHundred,CDdNameValuePairHelper.getIntegerValue(NUMBER_CMT));
        system.assertEquals(intHundred,CDdNameValuePairHelper.getIntegerValue(NUMBER_CMT,intThousand));
        system.assertEquals(intThousand,CDdNameValuePairHelper.getIntegerValue(NUMBER_CMT + DNE,intThousand));

        system.assertEquals(decHundred,(Decimal)CDdNameValuePairHelper.getValue(NUMBER_CMT));
        system.assertEquals(decHundred,CDdNameValuePairHelper.getDecimalValue(NUMBER_CMT));
        system.assertEquals(decHundred,CDdNameValuePairHelper.getDecimalValue(NUMBER_CMT,decThousand));
        system.assertEquals(decThousand,CDdNameValuePairHelper.getDecimalValue(NUMBER_CMT + DNE,decThousand));

        system.assertEquals(true,(Boolean)CDdNameValuePairHelper.getValue(BOOLEAN_CMT));
        system.assertEquals(true,CDdNameValuePairHelper.getBooleanValue(BOOLEAN_CMT));
        system.assertEquals(true,CDdNameValuePairHelper.getBooleanValue(BOOLEAN_CMT,false));
        system.assertEquals(false,CDdNameValuePairHelper.getBooleanValue(BOOLEAN_CMT + DNE,false));

        Name_Value_Pair__mdt dtMdt = Name_Value_Pair__mdt.getInstance(DATETIME_CMT);
        DateTime dtNew = Datetime.newInstanceGmt(2022, 12, 31, 0, 0, 0);

        system.assertEquals(dtMdt.Date_Time_Value__c,(DateTime)CDdNameValuePairHelper.getValue(DATETIME_CMT));
        system.assertEquals(dtMdt.Date_Time_Value__c,CDdNameValuePairHelper.getDateTimeValue(DATETIME_CMT));
        system.assertEquals(dtMdt.Date_Time_Value__c,CDdNameValuePairHelper.getDateTimeValue(DATETIME_CMT,dtNew));
        system.assertEquals(dtNew,CDdNameValuePairHelper.getDateTimeValue(DATETIME_CMT + DNE,dtNew));

        Date d = Date.newInstance(2022, 3, 10);
        Date dNew = Date.newInstance(2022, 12, 31);

        system.assertEquals(d,(Date)CDdNameValuePairHelper.getValue(DATE_CMT));
        system.assertEquals(d,CDdNameValuePairHelper.getDateValue(DATE_CMT));
        system.assertEquals(d,CDdNameValuePairHelper.getDateValue(DATE_CMT,dNew));
        system.assertEquals(dNew,CDdNameValuePairHelper.getDateValue(DATE_CMT + DNE,dNew));

        String coverageForNameValuePairConstantsClass1 =
            CDdNameValuePairConstants.CASE_TRIGGER_VALIDATE_DASHER_ESCALATION_QUEUE;
        String coverageForNameValuePairConstantsClass2 =
            CDdNameValuePairConstants.CASE_TRIGGER_VALIDATE_DASHER_ESCALATION_QUEUE_ERROR_MSG;
    }
}