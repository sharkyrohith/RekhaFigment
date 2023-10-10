/**
 * @author Jeegar Brahmakshatriya
 * @date 2020-02
 *
 * @description Class for generic Utilities.
*/

public with sharing class CDdUtilities {
    /*****************************************************************************************************************************
    *
    * Constants
    *
    *****************************************************************************************************************************/
    public static final String  DML_INSERT = 'Insert';
    public static final String  DML_UPDATE = 'Update';
    public static final String  DML_UPSERT = 'Upsert';
    public static final String  DML_DELETE = 'Delete';
    public static final Integer BATCH_SIZE_1 = 1;
    public static final Integer START_INDEX_0 = 0;
    public static final Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /*
     * @description: this method converts string time using format "10:00 AM" to Time variable.
     **/

    public static Time stringAMPMToTime(String strTime){
        Time newTime;
        try {
            if(strTime == null) {
                return null;
            }
            Integer hourValue = 0;
            Integer minuteValue;
            List<String> strTimeSplit = strTime.split(':');
            if(strTime.contains(' PM')) {
                hourValue = 12;
            }
            hourValue += Integer.valueOf(strTimeSplit[0]);
            minuteValue = Integer.valueOf(strTimeSplit[1].split(' ')[0]);
            newTime = Time.newInstance(hourValue, minuteValue, 0, 0);
        } catch (Exception ex) {
            System.debug('Exception = ' + ex.getMessage());
            throw new StringAMPMToTimeException('Exception Thrown While Converting AM PM String to Time', ex);
        }
        return newTime;
    }
    public class StringAMPMToTimeException extends Exception {}

    public static void debug(LoggingLevel logLevel,String debugString, Boolean doDebug){
        if(doDebug){
            system.debug(logLevel, debugString);
        }
    }

    /**
     * @author          Jeegar
     * @date            May 2023
     * @description     subtract hours from time
     */
    public static Datetime addHoursToTime(DateTime givenTime, Integer hours) {

        if(givenTime == null) {
            givenTime = System.now();
        }
        return  givenTime.addHours(hours);


    }
     public Static integer calculateCPUUsage( String clsMethodName, String insideProcess, Integer lastCPUTime,Boolean doCPUCheck) {
        Integer cpuUsage = 0;
        Integer currentCPUUsage = 0;
        if(doCPUCheck) {
            currentCPUUsage = Limits.getCpuTime();
            cpuUsage = currentCPUUsage - lastCPUTime ;
            debug(LoggingLevel.WARN, clsMethodName +'  '+ insideProcess + '  ' +cpuUsage, true);
        }
        return currentCPUUsage;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Returns a Boolean if the org is Sandbox.
     * @param   None
     * @return  Boolean -
     */
    private static boolean isSandbox = null;
    public static Boolean getIsSandbox() {
        if (isSandbox == null) {
            isSandbox = [Select Id,IsSandbox from Organization Limit 1].IsSandbox;
        }
        return isSandbox;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Returns the Object Prefix for an Sobject
     * @param   String objectName - Sobject Name
     * @return  Boolean -
     */
    public static String getObjectPrefix(String objectName) {
        Map<String, Schema.SObjectType> m  = SOBJECT_TYPES;
        if (m.containsKey(objectName))
          return m.get(objectName).getDescribe().getKeyPrefix();
        return CDdCoreConstants.BLANK_STRING;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Gets the organization URL
     * @param   Boolean addTrailingSlash - Adds a string '/' to the end of the return string
     * @return  String - Org URL
     */
    public static String getOrgURL(boolean addTrailingSlash) {
        String trailingSlash = addTrailingSlash ? CDdCoreConstants.DELIMITER_FORWARD_SLASH : CDdCoreConstants.BLANK_STRING;

        return (getIsSandbox() ? URL.getSalesforceBaseURL().toExternalForm() : CDdCoreConstants.PROD_ORG_URL)
                + trailingSlash;
    }

    public enum CREATELINK_PROPS {
        NO_ANCHOR,
        ANCHOR_NO_TARGET,
        ANCHOR_BLANK_TARGET
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Create a link with the URL
     * @param   Boolean trailingString - String after the Org URL
     * @return  String - Org URL Link
     */
    public static String createLink(String trailingString) {
        if (String.isBlank(trailingString))
            trailingString = CDdCoreConstants.BLANK_STRING;

        trailingString = trailingString.startsWith(CDdCoreConstants.DELIMITER_FORWARD_SLASH) ?
            trailingString : CDdCoreConstants.DELIMITER_FORWARD_SLASH + trailingString;

        return getOrgURL(false) + trailingString;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Create a link with the URL
     * @param   Boolean trailingString - String after the Org URL
     *          CREATELINK_PROPS p - Type of return
     * @return  String - Org URL Link
     */
    public static String createLink(String trailingString, CREATELINK_PROPS p) {
        String link = createLink(trailingString);
        switch on p {
            when ANCHOR_NO_TARGET{
                link = '<a href="' + link + '">';
            }
            when ANCHOR_BLANK_TARGET {
                link = '<a href="' + link + '" target="_blank">';
            }
        }
        return link;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Create a link with the URL
     * @param   Boolean trailingString - String after the Org URL
     *          String clickString - Anchor Tag CLick String
     *          CREATELINK_PROPS p - Type of return
     * @return  String - Org URL Link
     */
    public static String createLink(String trailingString, String clickString,CREATELINK_PROPS p) {
        if (p == null)
            p = CREATELINK_PROPS.ANCHOR_NO_TARGET;

        String link = createLink(trailingString, p);
        clickString = (String.isBlank(clickString) ? 'Click Here' : clickString) + '</a> ';

        if (p != CREATELINK_PROPS.NO_ANCHOR)
            link += clickString;

        return link;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Create a link with the URL
     * @param   Boolean trailingString - String after the Org URL
     *          String clickString - Anchor Tag CLick String
     * @return  String - Org URL Link
     */
    public static String createLink(String trailingString, String clickString) {
        return (createLink(trailingString, clickString, null));
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Get the value of an Object's Field
     * @param   Sobject obj - Object record
     *          String fieldName - Field API Name (can be field in the Object (x__c) or a Lookup (y__r.z__c))
     * @return  Object - Field Value
     */
    public static Object getFieldVal(Sobject obj, String fieldName) {
        Object fieldVal = null;
        try {
            if (fieldName.contains(CDdCoreConstants.DELIMITER_DOT)) {
                List<String> fieldPath = fieldName.split('\\.');
                for (Integer i = 0; i < fieldPath.size(); i++) {
                    if (i < (fieldPath.size() - 1))
                        obj = obj.getSobject(fieldPath[i]);
                    else
                        fieldVal = obj.get(fieldPath[i]);
                }
            } else {
                fieldVal = obj.get(fieldName);
            }
        } catch (Exception e) {}
        return fieldVal;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Get the value of an Object's Field as a formatted string
     * @param   Sobject obj - Object record
     *          String fieldName - Field API Name (can be field in the Object (x__c) or a Lookup (y__r.z__c))
     * @return  String - Field Value
     */
     private static final List<String> MONTHS = new List<String>{'','January','February',
        'March','April','May','June','July','August','September','October',
        'November','December'};

    public static String getFieldValAsString(Sobject obj, String fieldName) {
        String retVal = CDdCoreConstants.BLANK_STRING;
        try {
            Object fieldVal = getFieldVal(obj,fieldName);
            retVal = (fieldVal == null) ? CDdCoreConstants.BLANK_STRING : String.valueOf(fieldVal);
        } catch (Exception e) {}
        return retVal;
    }

    public static String getFieldValAsString(Sobject obj, String fieldName, String datatype) {
        String retVal = CDdCoreConstants.BLANK_STRING;
        try {
            Object fieldVal = getFieldVal(obj,fieldName);

            retVal = (fieldVal == null) ? CDdCoreConstants.BLANK_STRING : String.valueOf(fieldVal);

            if (String.isBlank(datatype) || datatype == 'Boolean') {
                if (retVal == 'true') retVal = CDdCoreConstants.STRING_YES;
                if (retVal == 'false') retVal = CDdCoreConstants.STRING_NO;
            }

            if (datatype == 'Date') {
                Date d = Date.valueOf(retVal);
                retVal = MONTHS[d.month()] + CDdCoreConstants.DELIMITER_SPACE + d.day() +
                    CDdCoreConstants.DELIMITER_COMMA + CDdCoreConstants.DELIMITER_SPACE +  d.year();
            }

            if ((String.isBlank(datatype) || datatype == 'Decimal') &&
                    String.isNotBlank(retVal) && isDecimal(retVal))
                retVal = formatDecimal(retVal);
        } catch (Exception e) {}
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Check if a string is a Decimal
     * @param   String val - a string which contains a number, may be commafied
     * @return  Boolean
     */
    public static boolean isDecimal(String val) {
        Boolean isValidDecimal = false;
        val = String.isNotBlank(val) ? val.replaceAll(CDdCoreConstants.DELIMITER_COMMA,CDdCoreConstants.BLANK_STRING) : CDdCoreConstants.BLANK_STRING;
        if (String.isNotBlank(val)){
            try {
                Decimal.valueOf(val);
                isValidDecimal = true;
            } catch(TypeException e) {}
        }
        return isValidDecimal;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Get Decimal value from String
     * @param   String val - a string which contains a number, may be commafied
     * @return  Decimal, 0 if a Decimal
     */
    public static Decimal getDecimalValue(String val) {
        val = String.isNotBlank(val) ? val.replaceAll(CDdCoreConstants.DELIMITER_COMMA,CDdCoreConstants.BLANK_STRING) : CDdCoreConstants.BLANK_STRING;
        return (isDecimal(val) ? Decimal.valueOf(val) : 0);
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Get Decimal value from String
     * @param   String val - a string which contains a number, may be commafied
     * @return  Decimal, Null if not a decimal
     */
    public static Decimal getDecimalValueNull(String val) {
        val = String.isNotBlank(val) ? val.replaceAll(CDdCoreConstants.DELIMITER_COMMA,CDdCoreConstants.BLANK_STRING) : CDdCoreConstants.BLANK_STRING;
        return (isDecimal(val) ? Decimal.valueOf(val) : null);
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Format a Decimal String
     * @param   String val - a string which contains a number
     * @return  String - Commafied and scaled Decimal
     */
    public static String formatDecimal(String val) {
        Decimal d = Decimal.valueOf(val).setScale(2);
        String f = d.format();
        if (f.indexOf(CDdCoreConstants.DELIMITER_DOT) == -1)
            return f + '.00';
        else if (f.substringAfterLast(CDdCoreConstants.DELIMITER_DOT).length() == 1)
            return f + '0';

        return f;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Format a Decimal String
     * @param   Object val - a Decimal
     * @return  String - Commafied and scaled Decimal
     */
    public static String convertDecimalObjectToString(Object val) {
        if (val == null)
            return CDdCoreConstants.BLANK_STRING;
        Decimal d = (Decimal)val;
        String retVal = d.format();
        if (retVal.indexOf(CDdCoreConstants.DELIMITER_DOT) == -1)
            return retVal + '.00';
        else if (retVal.substringAfterLast(CDdCoreConstants.DELIMITER_DOT).length() == 1)
            return retVal + '0';
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Replace merge fields from an Email Template
     * @param   String sObjectName - Object Name
     *          String recordId - Id of the data to merge into the template
     *          String s - the merge string
     * @return  String - Merged String
     */
    public static String replaceMergeFields(String sObjectName,String recordId,String s) {
        String sObjectNameToCollectFields =  '{!' + sObjectName + CDdCoreConstants.DELIMITER_DOT;

        Set<String> fields = new Set<String>{
            'id'
        };
        Integer i = s.indexOf(sObjectNameToCollectFields,0);
        while (i != -1) {
            Integer j = s.indexOf('}', i);
            if (j == -1)
                break;

            String mergeField = s.subString(i,++j);
            if (String.isBlank(mergeField))
                break;

            String field = mergeField.subStringAfter(CDdCoreConstants.DELIMITER_DOT).removeEnd('}');

            if (field != 'Link')
                fields.add(field.toLowerCase());

            i = s.indexOf(sObjectNameToCollectFields, i + 1);
        }

        try {
            List<SObject> objList = Database.query(
                'SELECT ' + String.join(new List<String>(fields),CDdCoreConstants.DELIMITER_COMMA) +
                '  FROM ' + sObjectName +
                ' WHERE Id = :recordId');

            if (objList.isEmpty())
                return CDdCoreConstants.BLANK_STRING;

            return replaceMergeFields(objList[0],sObjectName,s);
        } catch (Exception e) {}
        return '';
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Replace merge fields from an Email Template
     * @param   SObject obj - Object record containing data which needs to merged into email template
     *          String sObjectName - Object Name
     *          String s - the merge string
     * @return  String - Merged String
     */
    public static String replaceMergeFields(SObject obj, String sObjectName,String s) {
        sObjectName = sObjectName.startsWith('{!') ? sObjectName : '{!' + sObjectName;
        sObjectName = sObjectName.endsWith(CDdCoreConstants.DELIMITER_DOT) ? sObjectName : sObjectName + CDdCoreConstants.DELIMITER_DOT;

        // iterate thru the email template looking for the {!ObjectName.FieldName}, get fieldName value and replace
        Integer i = s.indexOf(sObjectName,0);
        while (i != -1) {
            Integer j = s.indexOf('}', i);
            if (j == -1)
                break;

            String mergeField = s.subString(i,++j);
            if (String.isBlank(mergeField))
                break;

            String field = mergeField.subStringAfter(CDdCoreConstants.DELIMITER_DOT).removeEnd('}');

            String fieldVal = (field == 'Link') ?
                createLink(getFieldValAsString(obj,'Id',null),'Click Here') :
                getFieldValAsString(obj,field,null);

            s = s.replace(mergeField, fieldVal);
            i = s.indexOf(sObjectName, 0);
        }
        return (s.replace(']]>',CDdCoreConstants.BLANK_STRING).replace('<![CDATA[',CDdCoreConstants.BLANK_STRING));
    }

    /**
     * @author Mahesh Chouhan
     * @date  July 28, 2022
     * @decription Replace merge fields from given String s
     * @param   SObject obj - Object record containing data which needs to merged into String s
     *          String s - the merge string
     * @return  String - Merged String
     */
    public static String replaceMergeFields(SObject obj, String s) {
        Integer i = s.indexOf('{',0);
        while (i != -1) {
            Integer j = s.indexOf('}', i);
            if (j == -1)
                break;

            String mergeField = s.subString(i,++j);
            if (String.isBlank(mergeField))
                break;

            String field = mergeField.subStringAfter('{').removeEnd('}');
            String fieldVal = getFieldValAsString(obj,field,null);

            s = s.replace(mergeField, fieldVal);
            i = s.indexOf('{', 0);
        }
        return s;
    }

    /**
     * @author Mahesh Chouhan
     * @date  Dec 6, 2022
     * @decription Replace merge fields from given String s
     * @param   SObject obj - Object record containing data which needs to merged into String s
     *          String s - the merge string
     * @return  String - Merged String. This method would return Decimal values without formatting
     */
    public static String replaceMergeFieldsString(SObject obj, String s) {
        Integer i = s.indexOf('{',0);
        while (i != -1) {
            Integer j = s.indexOf('}', i);
            if (j == -1)
                break;

            String mergeField = s.subString(i,++j);
            if (String.isBlank(mergeField))
                break;

            String field = mergeField.subStringAfter('{').removeEnd('}');
            String fieldVal = getFieldValAsString(obj,field,'String');

            if(String.isBlank(fieldVal)){
                return s;
            }
            s = s.replace(mergeField, fieldVal);
            i = s.indexOf('{', 0);
        }
        return s;
    }

    /**
     * @author Sid Agarwal
     * @date  Sept, 2022
     * @decription Replace merge fields from given String s.
     *              This is an extension to other similar methods, and will also handle non-field value merges
     * @param   SObject obj - Object record containing data which needs to merged into String s
     *          String s - the merge string
     * @return  String - Merged String
     */
    public static String replaceMergeFieldsExtension(SObject obj, String s) {
        // null check
        if(String.isBlank(s)) {return CDdCoreConstants.BLANK_STRING;}

        // check for any non-field value merge
        if(s.equals('{CurrentUserId}')) {return UserInfo.getUserId();}

        // default to field value merge
        return CDdUtilities.replaceMergeFields(obj, s);
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 16, 2021
     * @decription Is an Sobject accessible to current logged in user
     * @param   String sObjName - Object Name
     * @return  Boolean - If object is accessible to current logged in user
     */
    public static Boolean objectIsAccessible(String objName) {
        return String.isNotBlank(objName) && SOBJECT_TYPES.get(objName).getDescribe().isAccessible();
    }
    /**
     * @author Ravali Tummala
     * @date  Oct, 2021
     * @decription
     * @param   String val - Value to Mask
     *          Integer numCharToShow - Number of characters to show
     *          Boolean maskBegin - Mask the beginning or end of value
     * @return  String - Masked Value
     */
    public static String maskString(String val,Integer numCharToShow,Boolean maskBegin) {
        String retVal = '';
        if (String.isNotBlank(val)){
            Integer repeatTimes = val.length() - numCharToShow;
            retVal = CDdCoreConstants.MASK_VALUE_STRING.repeat(repeatTimes) + val.subString(repeatTimes,val.length());
            if (maskBegin){
                retVal = val.subString(0,numCharToShow) + CDdCoreConstants.MASK_VALUE_STRING.repeat(repeatTimes);
            }
        }
        return retVal;
    }

    /**
     * @author      Sahil Chaudhry
     * @date        Jan 04, 2022
     * @decription  Indicate whether a record is user
     * @param       record Id
     * @return      Boolean
    */
    public static Boolean idIsUser(String recId) {
        return String.isNotBlank(recId) && recId.startsWith('005');
    }

    /**
     * @author      Sahil Chaudhry
     * @date        Jan 04, 2022
     * @decription  Indicate whether a record is user
     * @param       record Id
     * @return      Boolean
    */
    public static Boolean idIsUser(Object recId) {
        return idIsUser(String.valueOf(recId));
    }

    /**
     * @author      Sahil Chaudhry
     * @date        Jan 04, 2022
     * @decription  Indicate whether a record is a group
     * @param       record Id
     * @return      Boolean
    */
    public static Boolean idIsGroup(String recId) {
        return String.isNotBlank(recId) && recId.startsWith('00G');
    }

    /**
     * @author      Sahil Chaudhry
     * @date        Jan 04, 2022
     * @decription  Indicate whether a record is a group
     * @param       record Id
     * @return      Boolean
    */
    public static Boolean idIsGroup(Object recId) {
        return idIsGroup(String.valueOf(recId));
    }

    /**
     * @author      Raju Lakshman
     * @date        March 4, 2022
     * @decription  Check if current user is an integration user
     * @param       integrationUserType - Identifies what type of user to check in the code, example: Mulesoft
     * @return      Boolean
    */
    public static Boolean isCurrentUserAnIntegrationUser(String integrationUserType) {
        Integration_User__c orgDefault = Integration_User__c.getOrgDefaults();
        Integration_User__c userDefault = Integration_User__c.getInstance();
        if (userDefault == null || userDefault == orgDefault) {
            return false;
        }
        return (String.isNotBlank(userDefault.User_Type__c) && userDefault.User_Type__c.containsIgnoreCase(integrationUserType));
        // Here, one need to be too verbose with the integrationUserType - it can be something like 'Mulesoft'
        // The field can be a semicolon/comma separated type - if one integration user is more than one type
        // Like Mulesoft,LinkedInSN
        // If this complexity for dual role is not needed, it can be single as well.
    }

    public static final Boolean doCPUTimeCheck = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_CPU_Time_Check__c');
    public static final Boolean doHeapSizeCheck = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Heap_Size_Check__c');

    /**
    * @description
    * @author Jose Vega | 04-04-2022
    * @param String triggerContext
    * @param String method
    **/
    public static Integer logCpuUsage(String triggerContext, Integer lastCpuTime, String method) {
        lastCpuTime = CDdUtilities.calculateCPUUsage(triggerContext,(method.endsWith('= ') ? method : method + '= '),lastCpuTime,doCPUTimeCheck);
        if (method == 'End' || method == 'Start') {
            String heapSizeCheckMsg = doHeapSizeCheck ? 'Heap: ' + Limits.getHeapSize() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitHeapSize()
                                        + CDdCoreConstants.NEW_LINE : '';
            String msg = 'CPU: ' + Limits.getCpuTime() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitCpuTime() + CDdCoreConstants.NEW_LINE + heapSizeCheckMsg +
                'SOQL: ' + Limits.getQueries() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitQueries() + CDdCoreConstants.NEW_LINE +
                'DML Row: ' + Limits.getDmlRows() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitDmlRows() + CDdCoreConstants.NEW_LINE +
                'DML Statement: ' + Limits.getDmlStatements() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getDmlStatements();
            CDdUtilities.debug(LoggingLevel.WARN, triggerContext + ' LIMITS LOGGER ' + method + ' = ' + CDdCoreConstants.NEW_LINE + msg, true);
        }
        return lastCpuTime;
    }

    /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  return valid Id from a string
     * @param       String value
     * @return      Id
    */
    public static Id returnValidId(String val) {
        try {
            if (String.isNotBlank(val)) {
                return Id.valueOf(val);
            }
        } catch (Exception e) {}
        return null;
    }

    /**
     * @author      Raju Lakshman
     * @date        August 2022
     * @decription  return number of occurances of a character in a string
     * @param       searchString {String} - to search in
     * @param       characterToSearch {String} - character to get the number of occurances
     * @return      Integer
    */
    public static Integer getNumberOfCharacterInString(String searchString,String characterToSearch) {
        String temp = searchString.replaceAll('[^' + characterToSearch + ']','');
        return temp.length();
    }

    /*
     * @description: Can I call a Queueable. NOTE : Should NOT be used in a trigger context as it's an
     *                  expensive operation.
     **/
    public static Boolean isQueueableAllowed(){
        return System.Limits.getLimitQueueableJobs() - System.Limits.getQueueableJobs() > 0 ? true : false;
    }

    /*
    * @description insert records using queueable chaining. NOTE : Should NOT be used in a trigger context
                    as it's an expensive operation (chaining too many jobs)
    * Queueable - Sobject   Insert - Chaining with size
    * @param   inContext    String  Where is this being called from- for error logging
    * @param   objList      List<SObject> List of records to be inserted
    * @param   batchSize    Integer  How many records per batch
    * @return  None
    -- Usage
        CDdUtilities.insertSobjectQueueable('Insert Cases from Opportunity',caseList,CDdUtilities.BATCH_SIZE_1+9);
    */
    public static void insertSobjectQueueable(String inContext,List<SObject> objList, Integer batchSize) {
        // check if we can call queueable
        if(CDdUtilities.isQueueableAllowed() && objList.size()>0){
            CDdUtilities.sobjectDMLQueueable dmlQueueInstance =
                    new CDdUtilities.sobjectDMLQueueable(inContext,objList,null,CDdUtilities.DML_INSERT,
                                                            batchSize,CDdUtilities.START_INDEX_0);
            Id JobId = System.enqueueJob(dmlQueueInstance);
        } else {
            throw new sobjectDMLQueueableException('Error calling the Queueable');
        }
    }

    /*
    * @description update records using queueable chaining. NOTE : Should NOT be used in a trigger context
                    as it's an expensive operation (chaining too many jobs)
    * Queueable - Sobject Update - Chaining with size
    * @param   inContext   String                      Where is this being called from- for error logging
    * @param   objList     List<SObject>               List of records to be Updated
    * @param   batchSize   Integer                     How many records per batch
    * @return  None
    -- Usage
        CDdUtilities.updateSobjectQueueable('update Cases from Opportunity',caseList,CDdUtilities.BATCH_SIZE_1+9);
    */
    public static void updateSobjectQueueable(String inContext,List<SObject> objList, Integer batchSize) {
        // check if we can call queueable
        if(CDdUtilities.isQueueableAllowed()==true && objList.size()>0){
            CDdUtilities.sobjectDMLQueueable dmlQueueInstance =
                        new CDdUtilities.sobjectDMLQueueable(inContext,objList,null,CDdUtilities.DML_UPDATE,
                                                               batchSize,CDdUtilities.START_INDEX_0);
            Id JobId = System.enqueueJob(dmlQueueInstance);
        } else {
            throw new sobjectDMLQueueableException('Error calling the Queueable');
        }
    }

    /*
    * @description delete records using queueable chaining. NOTE : Should NOT be used in a trigger context
                    as it's an expensive operation (chaining too many jobs)
    * Queueable - Sobject   Delete - Chaining with size
    * @param   inContext    String  Where is this being called from- for error logging
    * @param   objList      List<SObject> List of records to be deleted
    * @param   batchSize    Integer  How many records per batch
    * @return  None
    -- Usage
        CDdUtilities.deleteSobjectQueueable('Delete Cases',caseList,CDdUtilities.BATCH_SIZE_1+9);
    */
    public static void deleteSobjectQueueable(String inContext,List<SObject> objList, Integer batchSize) {
        // check if we can call queueable
        if(CDdUtilities.isQueueableAllowed() && objList.size()>0){
            CDdUtilities.sobjectDMLQueueable dmlQueueInstance =
                    new CDdUtilities.sobjectDMLQueueable(inContext,objList,null,CDdUtilities.DML_DELETE,
                                                            batchSize,CDdUtilities.START_INDEX_0);
            Id JobId = System.enqueueJob(dmlQueueInstance);
        } else {
            throw new sobjectDMLQueueableException('Error calling the Queueable');
        }
    }

    /*
    * @description upsert records using queueable chaining. NOTE : Should NOT be used in a trigger context
                    as it's an expensive operation (chaining too many jobs)
    * Queueable - Sobject Upsert - Chaining with size
    * @param   inContext   String                      Where is this being called from- for error logging
    * @param   objList     List<SObject>               List of records to be Updated
    * @param   batchSize   Integer                     How many records per batch
     * @param  externalIdField   Schema.SObjectField   external Id field on the object. can be used to upsert.
    * @return  None
    -- Usage
        CDdUtilities.upsertSobjectQueueable('upsert Cases from Opportunity',caseList,CDdUtilities.BATCH_SIZE_1+9,UUID__c);
    */
    public static void upsertSobjectQueueable(String inContext,List<SObject> objList,
                                                Integer batchSize, Schema.SObjectField externalIdField) {
        // check if we can call queueable
        if(CDdUtilities.isQueueableAllowed()==true && objList.size()>0) {
            CDdUtilities.sobjectDMLQueueable dmlQueueInstance =
                                                new CDdUtilities.sobjectDMLQueueable(inContext,objList,externalIdField,
                                                                            CDdUtilities.DML_UPSERT,batchSize,CDdUtilities.START_INDEX_0);
            Id JobId = System.enqueueJob(dmlQueueInstance);
        } else {
            throw new sobjectDMLQueueableException('Error calling the Queueable');
        }
    }

    /*
    * Queueable - Sobject Insert/Update - Chaining with size
    * @param   inContext   String           Where is this being called from- for error logging
    * @param   objList     List<SObject>    List of records
    * @param   inAction    String           Insert or Update
    * @param   batchSize   Integer          How many records per batch
    * @param   startIndex  Integer          Default 0
    * @return  None
    -- Usage
        CDdUtilities.sobjectDMLQueueable dmlQueueInstance =
                new CDdUtilities.sobjectDMLQueueable('Update Cases from CloseBacth',caseList,CDdUtilities.DML_Update,
                CDdUtilities.BATCH_SIZE_1+9,CDdUtilities.START_INDEX_0);
        Id JobId = System.enqueueJob(dmlQueueInstance);
    */
    public class sobjectDMLQueueable implements Queueable{
        private List<SObject> objList{get;set;}
        private Integer batchSize {get;set;}
        private Integer startIndex{get;set;}
        private Integer noOfRequests{get;set;}
        private String action {get;set;}
        private String inContext{get;set;}
        private Schema.SObjectField externalIdField {get;set;}

        // for recursive calls
        public sobjectDMLQueueable(String inContext,List<SObject> objList, Schema.SObjectField externalIdField,
                                     String inAction, Integer batchSize, Integer startIndex){
            this.objList = objList;
            this.startIndex = startIndex;
            this.noOfRequests = objList.size();
            this.batchSize = batchSize;
            this.action = inAction;
            this.inContext = inContext;
            this.externalIdField = externalIdField;
        }
        // override the execute method to recursively call until all records are processed
        public void execute (System.QueueableContext qc) {
            Integer endIndex = this.getEndIndex();
            List<Sobject> requestsToBeProcessedNext = new List<Sobject>();
            // extract the records that need to be processed
            for (Integer idx = startIndex; idx <=endIndex; idx++){
                requestsToBeProcessedNext.add(objList.get(idx));
            }
            //DML Action
            if (this.action.equalsIgnoreCase(DML_INSERT)) {
                List<Database.SaveResult> insertResult = Database.insert(requestsToBeProcessedNext, false);
                CDdErrorUtilities.publishException('CDdUtilities', inContext, insertResult);
            } else if (this.action.equalsIgnoreCase(DML_UPDATE)) {
                List<Database.SaveResult> updateResults = Database.update(requestsToBeProcessedNext, false);
                CDdErrorUtilities.publishException('CDdUtilities', inContext, updateResults);
            } else if (this.action.equalsIgnoreCase(DML_DELETE)) {
                List<Database.DeleteResult> updateResults = Database.delete(requestsToBeProcessedNext, false);
                CDdErrorUtilities.publishException('CDdUtilities', inContext, updateResults);
            } else if (this.action.equalsIgnoreCase(DML_UPSERT)) {
                List<Database.UpsertResult> upsertResult = new List<Database.UpsertResult>();
                if (externalIdField != null) {
                    upsertResult = Database.upsert(requestsToBeProcessedNext, externalIdField, false);
                } else {
                    upsertResult = Database.upsert(requestsToBeProcessedNext, false);
                }
                CDdErrorUtilities.publishException('CDdUtilities', inContext, upsertResult);
            }
            // are there requests that need to be processed/left, call the recursive
            if (this.noOfRequests > endIndex + 1) {
                sobjectDMLQueueable queueableInstance = new sobjectDMLQueueable(this.inContext,this.objList,this.externalIdField,
                                                                                    this.action,this.batchSize,endIndex+1);
                Id JobId = System.enqueueJob(queueableInstance);
            }
        }

        // get the last index of the batch to be processed, given the start index and batch size
        public Integer getEndIndex() {
            if (this.noOfRequests > this.startIndex + batchSize - 1){
                return this.startIndex + batchSize - 1;
            }
            else{
                return this.noOfRequests - 1;
            }
        }
    }

    /*
    * @description: Exception class for sobjectDMLQueueable
    **/
    public class sobjectDMLQueueableException extends Exception {}
}