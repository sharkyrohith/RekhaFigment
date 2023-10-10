/*
 * @author: Raju Lakshman
 * @date : October 2021
 * @description: Helper methods for the Grid Report Logic - supports parsing various filters to formulate where clause.
 */
public without sharing class CDdGridReportHelper {

    /*
    * @author: Raju Lakshman
    * @date : October 2021
    * @description: Wrapper which returns record Ids back to the UI. Send total count back to the UI (via a select count query)
    *               so that UI can show that not all records were returned in case of limits issue
    */
    public class CDdGridReportRecordIdWrapper {
        @AuraEnabled public Integer count {get;set;}
        @AuraEnabled public List<Id> recordIds {get;set;}

        //Default Constructor
        public CDdGridReportRecordIdWrapper() {
            this.count = 0;
            this.recordIds = new List<Id>();
        }
    }
    /*****************************************************************************************************************************
     *
     * Constants Variables
     *
     *****************************************************************************************************************************/
    public static final String EQUALS = 'Equals';
    public static final String DOES_NOT_EQUAL = 'Does Not Equal';
    public static final String IS_NULL = ' = null ';
    public static final String IS_NOT_NULL = ' != null ';
    public static final String QUERY_IN = 'In';
    public static final String QUERY_AND = ' AND ';
    public static final String QUERY_OR = ' OR ';
    public static final String OPEN_PARENTHESIS = ' ( ';
    public static final String CLOSE_PARENTHESIS = ' ) ';

    public static final String OP_EQUALS = '=';
    public static final String OP_GREATER_OR_EQUALS = '>=';
    public static final String OP_LESS_OR_EQUALS = '<=';
    public static final String OP_GREATER = '>';
    public static final String OP_LESS = '<';
    public static final String OP_BETWEEN = 'BETWEEN';
    public static final String OP_IS_BLANK = 'IS BLANK';
    public static final String OP_IS_NOT_BLANK = 'IS NOT BLANK';

    public static final String OP_EQUALS_SPACE = ' = ';
    public static final String OP_GREATER_OR_EQUALS_SPACE = ' >= ';
    public static final String OP_LESS_OR_EQUALS_SPACE = ' <= ';
    public static final String OP_GREATER_SPACE = ' > ';
    public static final String OP_LESS_SPACE = ' < ';

    public static final String QUERY_ORDER_BY = ' ORDER BY ';
    public static final String ORDER_ASCENDING = ' asc ';
    public static final String ORDER_DESCENDING = ' desc ';
    public static final String QUERY_LIMIT = ' LIMIT ';
    public static final String QUERY_LIMIT_50K = ' LIMIT 50000';

    private static final String DATE_FORMATTER = 'yyyy-MM-dd';

    /**
    * @description Convert JSON String of filter config into the wrapper.
    * @param String filterConfig - JSON String of filters
    * @return List<CDdGridReportFilterWrapper> - Parsed filter in apex wrapper form
    */
    public static List<CDdGridReportFilterWrapper> getFilterWrapper(String filterConfig) {
        // value is an object which can be of any format, hence JSON.deseralize will not work
        List<Object> wrapperList = (List<Object>)JSON.deserializeUntyped(filterConfig);
        List<CDdGridReportFilterWrapper> retList = new List<CDdGridReportFilterWrapper>();
        for (Integer i = 0; i < wrapperList.size(); i++) {
            Map<String,Object> config = (Map<String,Object>)wrapperList[i];
            CDdGridReportFilterWrapper wrapper = new CDdGridReportFilterWrapper();
            wrapper.name = (String)config.get('name');
            wrapper.definition = (DD_Grid_Report_Filter__mdt)JSON.deserialize(JSON.serialize(config.get('definition')),DD_Grid_Report_Filter__mdt.class);
            wrapper.value = config.get('value');
            retList.add(wrapper);
        }
        return retList;
    }

    /**
    * @description Form the query param from Multiselect selections
    * @param String fieldAPINames - Comma separated list of field api names to add the the query
    * @param List<Object> values - is actually List<CDdMultiSelectPicklistWrapper> - an array of user selections from the filter in the UI.
    * @param String operator - LIKE/IN
    * @return String - deciphered where clause
    */
    public static String getMultiSelectPicklistQuery(String fieldAPINames,List<Object> values,String operator) {
        if (String.isBlank(fieldAPINames) || values == null || values.isEmpty()) {
            return CDdCoreConstants.BLANK_STRING;
        }
        List<CDdMultiSelectPicklistWrapper> wL = (List<CDdMultiSelectPicklistWrapper>)JSON.deserialize(
            JSON.serialize(values), List<CDdMultiSelectPicklistWrapper>.class);

        String query = OPEN_PARENTHESIS;

        // Usually you would have one field name, but this supports if 2+ fields need to be searched with the same values in an OR logic.
        for (String fieldName : fieldAPINames.split(CDdCoreConstants.DELIMITER_COMMA)) {
            fieldName = fieldName.trim();
            query += getMultiSelectPicklistQuery_Helper(fieldName,wL,operator);
        }
        query = query.removeEnd(QUERY_OR) + CLOSE_PARENTHESIS + QUERY_AND;
        return query;
    }

    /**
    * @description Form the query param from Multiselect selections
    * @param String fieldName - Field API Name
    * @param List<CDdMultiSelectPicklistWrapper> wL - An array of user selections from the filter in the UI.
    * @param String operator - LIKE/IN
    * @return String - deciphered where clause
    */
    private static String getMultiSelectPicklistQuery_Helper(String fieldName, List<CDdMultiSelectPicklistWrapper> wL, String operator) {
        // Convert to a map which groups wrappers by operators.
        Map<String,List<CDdMultiSelectPicklistWrapper>> wMap = getMultiSelectPicklistWrapperByOperatorMap(wL);

        String equalsQuery = CDdCoreConstants.BLANK_STRING;
        String doesNotEqualQuery = CDdCoreConstants.BLANK_STRING;
        String isBlankQuery = wMap.containsKey('Is Blank') ? OPEN_PARENTHESIS + fieldName + IS_NULL + CLOSE_PARENTHESIS: CDdCoreConstants.BLANK_STRING;
        String isNotBlankQuery = wMap.containsKey('Is Not Blank') ? OPEN_PARENTHESIS + fieldName + IS_NOT_NULL + CLOSE_PARENTHESIS : CDdCoreConstants.BLANK_STRING;

        // Depending on the operator, form the sub query.
        if (operator == QUERY_IN) {
            if (wMap.containsKey(EQUALS)) {
                equalsQuery = OPEN_PARENTHESIS + fieldName + ' IN (\'';

                for (CDdMultiSelectPicklistWrapper w : wMap.get(EQUALS)) {
                    equalsQuery += w.value + '\',\'';
                }

                equalsQuery = equalsQuery.removeEnd(',\'') + ') ' + CLOSE_PARENTHESIS;
            }
            if (wMap.containsKey(DOES_NOT_EQUAL)) {
                doesNotEqualQuery = OPEN_PARENTHESIS + fieldName + ' NOT IN (\'';

                for (CDdMultiSelectPicklistWrapper w : wMap.get(DOES_NOT_EQUAL)) {
                    doesNotEqualQuery += w.value + '\',\'';
                }

                doesNotEqualQuery = doesNotEqualQuery.removeEnd(',\'') + ') ' + CLOSE_PARENTHESIS;
            }
        } else {
            if (wMap.containsKey(EQUALS)) {
                equalsQuery = OPEN_PARENTHESIS;

                for (CDdMultiSelectPicklistWrapper w : wMap.get(EQUALS)) {
                    equalsQuery += CDdCoreConstants.DELIMITER_SPACE + fieldName + ' LIKE \'%' + w.value + '%\' ' + QUERY_OR;
                }

                equalsQuery = equalsQuery.removeEnd(QUERY_OR) + CLOSE_PARENTHESIS;
            }
            if (wMap.containsKey(DOES_NOT_EQUAL)) {
                doesNotEqualQuery = OPEN_PARENTHESIS;

                for (CDdMultiSelectPicklistWrapper w : wMap.get(DOES_NOT_EQUAL)) {
                    doesNotEqualQuery += ' (NOT ' + fieldName + ' LIKE \'%' + w.value + '%\') ' + QUERY_AND;
                }

                doesNotEqualQuery = doesNotEqualQuery.removeEnd(QUERY_AND) + CLOSE_PARENTHESIS;
            }
        }
        // Join Sub queries to form the main query.
        String query = CDdCoreConstants.BLANK_STRING;
        if (String.isNotBlank(equalsQuery)) {
            query += equalsQuery + QUERY_AND;
        }
        if (String.isNotBlank(doesNotEqualQuery)) {
            query += doesNotEqualQuery + QUERY_AND;
        }
        if (String.isNotBlank(isBlankQuery)) {
            query += isBlankQuery + QUERY_AND;
        }
        if (String.isNotBlank(isNotBlankQuery)) {
            query += isNotBlankQuery + QUERY_AND;
        }

        query = OPEN_PARENTHESIS + query.removeEnd(QUERY_AND) + CLOSE_PARENTHESIS + QUERY_OR;
        return query;
    }

    /**
    * @description Translate the wrapper list into a map<operator,List<wrapper>>
    * @param List<CDdMultiSelectPicklistWrapper> wL - An array of user selections from the filter in the UI.
    * @return Map<String,List<CDdMultiSelectPicklistWrapper>> - Map<Operator,List<Wrapper>>
    */
    private static Map<String,List<CDdMultiSelectPicklistWrapper>> getMultiSelectPicklistWrapperByOperatorMap(List<CDdMultiSelectPicklistWrapper> wL) {
        Map<String,List<CDdMultiSelectPicklistWrapper>> retVal = new Map<String,List<CDdMultiSelectPicklistWrapper>>();

        for (CDdMultiSelectPicklistWrapper w : wL) {
            String operator = String.isBlank(w.operator) ? EQUALS : w.operator;
            if (!retVal.containsKey(operator)) {
                retVal.put(operator,new List<CDdMultiSelectPicklistWrapper>());
            }
            retVal.get(operator).add(w);
        }
        return retVal;
    }

    /**
    * @description Form the query param from NumberFilter selections
    * @param String fieldAPINames - Comma separated list of field api names to add the the query
    * @param List<Object> values - is actually List<CDdNumberFilterWrapper> - an array of user selections from the filter in the UI.
    * @return String - deciphered where clause
    */
    public static String getNumberFilterQuery(String fieldAPINames,List<Object> values) {
        if (String.isBlank(fieldAPINames) || values == null || values.isEmpty()) {
            return CDdCoreConstants.BLANK_STRING;
        }

        List<CDdNumberFilterWrapper> wL = (List<CDdNumberFilterWrapper>)JSON.deserialize(JSON.serialize(values), List<CDdNumberFilterWrapper>.class);

        String query = OPEN_PARENTHESIS;

        for (String fieldName : fieldAPINames.split(CDdCoreConstants.DELIMITER_COMMA)) {
            fieldName = fieldName.trim();
            query += getNumberFilterQuery_Helper(fieldName,wL);
        }
        query = query.removeEnd(QUERY_OR) + CLOSE_PARENTHESIS + QUERY_AND;
        return query;
    }

    /**
    * @description Form the query param from NumberFilter selections
    * @param String fieldName - Field API Name
    * @param List<CDdNumberFilterWrapper> wL - An array of user selections from the filter in the UI.
    * @return String - deciphered where clause
    */
    private static String getNumberFilterQuery_Helper(String fieldName, List<CDdNumberFilterWrapper> wL) {
        String query = OPEN_PARENTHESIS;
        String inQuery = CDdCoreConstants.BLANK_STRING;
        // Depending on the operator, form the query incrementally
        for (CDdNumberFilterWrapper w : wL) {
            if (w.operator == OP_EQUALS) {
                inQuery += w.value + CDdCoreConstants.DELIMITER_COMMA;
            } else if (w.operator == OP_GREATER_OR_EQUALS) {
                query += CDdCoreConstants.DELIMITER_SPACE + fieldName + OP_GREATER_OR_EQUALS_SPACE + w.value + QUERY_OR;
            } else if (w.operator == OP_LESS_OR_EQUALS) {
                query += CDdCoreConstants.DELIMITER_SPACE + fieldName + OP_LESS_OR_EQUALS_SPACE + w.value + QUERY_OR;
            } else if (w.operator == OP_GREATER) {
                query += CDdCoreConstants.DELIMITER_SPACE + fieldName + OP_GREATER_SPACE + w.value + QUERY_OR;
            } else if (w.operator == OP_LESS) {
                query += CDdCoreConstants.DELIMITER_SPACE + fieldName + OP_LESS_SPACE + w.value + QUERY_OR;
            } else if (w.operator == OP_BETWEEN) {
                query += OPEN_PARENTHESIS +
                         fieldName + OP_GREATER_OR_EQUALS_SPACE + w.minValue + QUERY_AND +
                         fieldName + OP_LESS_OR_EQUALS_SPACE + w.maxValue +
                         CLOSE_PARENTHESIS + QUERY_OR;
            } else if (w.operator == OP_IS_BLANK) {
                query += CDdCoreConstants.DELIMITER_SPACE + fieldName + IS_NULL + QUERY_OR;
            } else if (w.operator == OP_IS_NOT_BLANK) {
                query += CDdCoreConstants.DELIMITER_SPACE + fieldName + IS_NOT_NULL + QUERY_OR;
            }
        }

        if (String.isNotBlank(inQuery)) {
            query += CDdCoreConstants.DELIMITER_SPACE + fieldName + ' IN (' + inQuery.removeEnd(CDdCoreConstants.DELIMITER_COMMA) + ') ' + QUERY_OR;
        }

        query = query.removeEnd(QUERY_OR) + CLOSE_PARENTHESIS + QUERY_OR;
        return query;
    }

    /**
    * @description Form the query param from DateFilter selections
    * @param String type - Options: Date/DateTime
    * @param String fieldAPINames - Comma separated list of field api names to add the the query
    * @param List<Object> values - is actually List<CDdDateFilterWrapper> - an array of user selections from the filter in the UI.
    * @return String - deciphered where clause
    */
    public static String getDateFilterQuery(String type,String fieldAPINames,List<Object> values) {
        if (String.isBlank(fieldAPINames) || values == null || values.isEmpty()) {
            return CDdCoreConstants.BLANK_STRING;
        }

        List<CDdDateFilterWrapper> wL = (List<CDdDateFilterWrapper>)JSON.deserialize(JSON.serialize(values), List<CDdDateFilterWrapper>.class);

        String query = OPEN_PARENTHESIS;

        for (String fieldName : fieldAPINames.split(CDdCoreConstants.DELIMITER_COMMA)) {
            fieldName = fieldName.trim();
            query += getDateFilterQuery_Helper(type,fieldName,wL);
        }
        query = query.removeEnd(QUERY_OR) + CLOSE_PARENTHESIS + QUERY_AND;
        return query;
    }

    /**
    * @description Form the query param from DateFilter selections
    * @param String type - Options: Date/DateTime
    * @param String fieldName - API name of field
    * @param List<ObjeCDdDateFilterWrapperct> wL - an array of user selections from the filter in the UI.
    * @return String - deciphered where clause
    */
    private static String getDateFilterQuery_Helper(String type,String fieldName, List<CDdDateFilterWrapper> wL) {
        String query = OPEN_PARENTHESIS;
        String inQuery = CDdCoreConstants.BLANK_STRING;
        // Depending on the operator, form the query incrementally
        for (CDdDateFilterWrapper w : wL) {
            if (w.operator == OP_EQUALS) {
                inQuery += formatDate(w.value) + CDdCoreConstants.DELIMITER_COMMA;
            } else if (w.operator == OP_GREATER_OR_EQUALS) {
                query += getDateFilterField(fieldName,type) + OP_GREATER_OR_EQUALS_SPACE + formatDate(w.value) + QUERY_OR;
            } else if (w.operator == OP_LESS_OR_EQUALS) {
                query += getDateFilterField(fieldName,type) + OP_LESS_OR_EQUALS_SPACE + formatDate(w.value) + QUERY_OR;
            } else if (w.operator == OP_BETWEEN) {
                query += OPEN_PARENTHESIS +
                         getDateFilterField(fieldName,type) + OP_GREATER_OR_EQUALS_SPACE + formatDate(w.minValue) + QUERY_AND +
                         getDateFilterField(fieldName,type) + OP_LESS_OR_EQUALS_SPACE + formatDate(w.maxValue) +
                         CLOSE_PARENTHESIS + QUERY_OR;
            } else if (w.operator == OP_IS_BLANK) {
                query += getDateFilterField(fieldName,type) + IS_NULL + QUERY_OR;
            } else if (w.operator == OP_IS_NOT_BLANK) {
                query += getDateFilterField(fieldName,type) + IS_NOT_NULL + QUERY_OR;
            }
        }

        if (String.isNotBlank(inQuery)) {
            query += getDateFilterField(fieldName,type) + ' IN (' + inQuery.removeEnd(CDdCoreConstants.DELIMITER_COMMA) + CLOSE_PARENTHESIS + QUERY_OR;
        }
        query = query.removeEnd(QUERY_OR) + CLOSE_PARENTHESIS + QUERY_OR;
        return query;
    }

    /**
    * @description Format the Date for SOQL
    * @param Datetime dt - DateTime to be formatted
    * @return String - formatted DateTime
    */
    private static String formatDate(Datetime dt) {
        return dt.formatGMT(DATE_FORMATTER);
    }

    /**
    * @description Get the field part of the query
    * @param String fieldName - API name of field
    * @param String type - Options: Date/DateTime
    * @return String - Add DAY_ONLY to the field if DateTime as UI filter does not accept time param
    */
    private static String getDateFilterField(String fieldName,String type) {
        return type == 'Date' ? CDdCoreConstants.DELIMITER_SPACE + fieldName + CDdCoreConstants.DELIMITER_SPACE : ' DAY_ONLY(' + fieldName + ') ';
    }

    public static String getToggleQuery(String fieldAPINames,Object value) {
        if (String.isBlank(fieldAPINames) || value == null) {
            return CDdCoreConstants.BLANK_STRING;
        }

        Boolean val = (Boolean)value;
        String query = OPEN_PARENTHESIS;

        for (String fieldName : fieldAPINames.split(CDdCoreConstants.DELIMITER_COMMA)) {
            fieldName = fieldName.trim();
            query += fieldName + ' = ' + val + QUERY_OR;
        }

        query = query.removeEnd(QUERY_OR) + CLOSE_PARENTHESIS;
        return query;
    }
}