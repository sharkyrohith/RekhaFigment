/**
 * @author:         Raju Lakshman
 * @date:           March 2022
 * @description     BIZS-1117 Fetches data from Name_Value_Pair__mdt and returns it to the calling code.
 *
 *                  Remember to add cmt developer names as public static final constants in CDdNameValuePairConstants
 *
 *                  We are not using getAll() due to heap size considerations.
 */
public without sharing class CDdNameValuePairHelper {
    // Cache to store previously fetched CMT
    // Query as needed and then adding to the cache, to save on heap size. If this cmt gets too large, We would not want to keep all the records in memory for nothing.
    private static Map<String,Name_Value_Pair__mdt> cache = new Map<String,Name_Value_Pair__mdt>();

    private static final String TYPE_TEXT = 'Text';
    private static final String TYPE_BOOLEAN = 'Boolean';
    private static final String TYPE_NUMBER = 'Number';
    private static final String TYPE_DATETIME = 'DateTime';
    private static final String TYPE_DATE = 'Date';

    /**
     * @description Gets CMT record via query - this will be used for long text only (text > 255 char)
     *              Use Case: We need to use SOQL instead of getInstance() because of this statement in documentation of the getInstance() method :
     *                        Only the first 255 characters of any field in a custom metadata type record are returned.
     *                        Therefore, fields such as long text fields can be truncated. If you want all the field data from a custom metadata type record, use a SOQL query.
     *
     * @param   name - {String} - Developer name of CMT to fetch
     * @return  Name_Value_Pair__mdt
     */
    private static Name_Value_Pair__mdt getCmtViaQuery(String name) {
        if (cache.containsKey(name)) {
            return cache.get(name);
        }

        List<Name_Value_Pair__mdt> recList = [
            SELECT DeveloperName,Type__c,
                   Text_Value__c,Number_Value__c,Boolean_Value__c,Date_Time_Value__c,Date_Value__c
              FROM Name_Value_Pair__mdt
             WHERE DeveloperName = :name
        ];
        if (recList.isEmpty()) {
            throw new CDdException('Name_Value_Pair__mdt record not found: ' + name);
        }
        cache.put(name,recList[0]);
        return recList[0];
    }

    /**
     * @description Gets CMT record
     * @param   name - {String} - Developer name of CMT to fetch
     * @return  Name_Value_Pair__mdt
     */
    private static Name_Value_Pair__mdt getCmtViaGetInstance(String name) {
        if (cache.containsKey(name)) {
            return cache.get(name);
        }

        Name_Value_Pair__mdt retVal = Name_Value_Pair__mdt.getInstance(name);
        if (retVal == null) {
            throw new CDdException('Name_Value_Pair__mdt record not found: ' + name);
        }
        cache.put(name,retVal);
        return retVal;
    }

    /**
     * @description Gets value in generic object
     * @param   name - {String} - Developer name of CMT to use
     * @return  {Object} - Value of the name-value pair
     */
    public static Object getValue(String name) {
        Name_Value_Pair__mdt nameValuePair = getCmtViaGetInstance(name);

        switch on nameValuePair.Type__c {
            when 'Text' {
                return nameValuePair.Text_Value__c;
            }
            when 'Number' {
                return nameValuePair.Number_Value__c;
            }
            when 'Boolean' {
                return nameValuePair.Boolean_Value__c;
            }
            when 'DateTime' {
                return nameValuePair.Date_Time_Value__c;
            }
            when 'Date' {
                return nameValuePair.Date_Value__c;
            }
        }
        return null;
    }

    /**
     * @description Gets value in String format - This is for long text where text is >255 characters
     * @param   name - {String} - Developer name of CMT to use
     * @return  {String} - Value of the name-value pair
     */
    public static String getLongTextValue(String name) {
        Name_Value_Pair__mdt nameValuePair = getCmtViaQuery(name);
        return nameValuePair.Text_Value__c;
    }

    /**
     * @description Gets value in String format - This is for long text where text is >255 characters
     * @param   name - {String} - Developer name of CMT to use
     *          defaultval - {String} - Value to return if name-value pair returns null
     * @return  {String} - Value of the name-value pair
     */
    public static String getLongTextValue(String name,String defaultval) {
        try {
            String val = getLongTextValue(name);
            return val == null ? defaultval : val;
        } catch (Exception e) {
            // DO NOTHING;
        }
        return defaultval;
    }

    /**
     * @description Gets value in String format - This is for text where text is <=255 characters
     * @param   name - {String} - Developer name of CMT to use
     * @return  {String} - Value of the name-value pair
     */
    public static String getTextValue(String name) {
        Object val = getValue(name);
        return val == null ? null : String.valueOf(val);
    }

    /**
     * @description Gets value in String format - This is for text where text is <=255 characters
     * @param   name - {String} - Developer name of CMT to use
     *          defaultval - {String} - Value to return if name-value pair returns null
     * @return  {String} - Value of the name-value pair
     */
    public static String getTextValue(String name,String defaultval) {
        try {
            String val = getTextValue(name);
            return val == null ? defaultval : val;
        } catch (Exception e) {
            // DO NOTHING;
        }
        return defaultval;
    }

    /**
     * @description Gets Boolean value --- the type of the CMT should be Boolean
     * @param   name - {String} - Developer name of CMT to use
     * @return  {Boolean} - Value of the name-value pair
     */
    public static Boolean getBooleanValue(String name) {
        Name_Value_Pair__mdt nameValuePair = getCmtViaGetInstance(name);
        return nameValuePair.Type__c == TYPE_BOOLEAN ? nameValuePair.Boolean_Value__c : null;
    }

    /**
     * @description Gets Boolean value --- the type of the CMT should be Boolean
     * @param   name - {String} - Developer name of CMT to use
     *          defaultval - {Boolean} - Value to return if name-value pair returns null
     * @return  {Boolean} - Value of the name-value pair
     */
    public static Boolean getBooleanValue(String name,Boolean defaultval) {
        try {
            Boolean val = getBooleanValue(name);
            return val == null ? defaultval : val;
        } catch (Exception e) {
            // DO NOTHING;
        }
        return defaultval;
    }

    /**
     * @description Gets Integer value --- the type of the CMT should be Number
     * @param   name - {String} - Developer name of CMT to use
     * @return  {Integer} - Value of the name-value pair
     */
    public static Integer getIntegerValue(String name) {
        Name_Value_Pair__mdt nameValuePair = getCmtViaGetInstance(name);
        return nameValuePair.Type__c == TYPE_NUMBER ? Integer.valueOf(nameValuePair.Number_Value__c) : null;
    }

    /**
     * @description Gets Integer value --- the type of the CMT should be Integer
     * @param   name - {String} - Developer name of CMT to use
     *          defaultval - {Integer} - Value to return if name-value pair returns null
     * @return  {Integer} - Value of the name-value pair
     */
    public static Integer getIntegerValue(String name,Integer defaultval) {
        try {
            Integer val = getIntegerValue(name);
            return val == null ? defaultval : val;
        } catch (Exception e) {
            // DO NOTHING;
        }
        return defaultval;
    }

    /**
     * @description Gets Decimal value --- the type of the CMT should be Number
     * @param   name - {String} - Developer name of CMT to use
     * @return  {Decimal} - Value of the name-value pair
     */
    public static Decimal getDecimalValue(String name) {
        Name_Value_Pair__mdt nameValuePair = getCmtViaGetInstance(name);
        return nameValuePair.Type__c == TYPE_NUMBER ? nameValuePair.Number_Value__c : null;
    }

    /**
     * @description Gets Decimal value --- the type of the CMT should be Decimal
     * @param   name - {String} - Developer name of CMT to use
     *          defaultval - {Decimal} - Value to return if name-value pair returns null
     * @return  {Decimal} - Value of the name-value pair
     */
    public static Decimal getDecimalValue(String name,Decimal defaultval) {
        try {
            Decimal val = getDecimalValue(name);
            return val == null ? defaultval : val;
        } catch (Exception e) {
            // DO NOTHING;
        }
        return defaultval;
    }

    /**
     * @description Gets DateTime value --- the type of the CMT should be Datetime
     * @param   name - {String} - Developer name of CMT to use
     * @return  {Datetime} - Value of the name-value pair
     */
    public static Datetime getDateTimeValue(String name) {
        Name_Value_Pair__mdt nameValuePair = getCmtViaGetInstance(name);
        return nameValuePair.Type__c == TYPE_DATETIME ? nameValuePair.Date_Time_Value__c : null;
    }

    /**
     * @description Gets Datetime value --- the type of the CMT should be Datetime
     * @param   name - {String} - Developer name of CMT to use
     *          defaultval - {Datetime} - Value to return if name-value pair returns null
     * @return  {Datetime} - Value of the name-value pair
     */
    public static Datetime getDatetimeValue(String name,Datetime defaultval) {
        try {
            Datetime val = getDatetimeValue(name);
            return val == null ? defaultval : val;
        } catch (Exception e) {
            // DO NOTHING;
        }
        return defaultval;
    }

    /**
     * @description Gets Date value --- the type of the CMT should be Date
     * @param   name - {String} - Developer name of CMT to use
     * @return  {Date} - Value of the name-value pair
     */
    public static Date getDateValue(String name) {
        Name_Value_Pair__mdt nameValuePair = getCmtViaGetInstance(name);
        return nameValuePair.Type__c == TYPE_DATE ? nameValuePair.Date_Value__c : null;
    }

    /**
     * @description Gets Date value --- the type of the CMT should be Date
     * @param   name - {String} - Developer name of CMT to use
     *          defaultval - {Date} - Value to return if name-value pair returns null
     * @return  {Date} - Value of the name-value pair
     */
    public static Date getDateValue(String name,Date defaultval) {
        try {
            Date val = getDateValue(name);
            return val == null ? defaultval : val;
        } catch (Exception e) {
            // DO NOTHING;
        }
        return defaultval;
    }
}