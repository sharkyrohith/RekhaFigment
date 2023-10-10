/***************************************************************************************************
* Class Name   : CDdBooleanExpressionEvaluator
* Created Date : Nov 1, 2021
* Author       : Nayana Kapse
* Description  : Class to evaluate a boolean expression
* Example      : (TRUE AND (FALSE OR TRUE)) is TRUE
****************************************************************************************************/
public class CDdBooleanExpressionEvaluator {

    /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
	private static Pattern isnumbers = Pattern.Compile('(\\d+)');
    private static String AND_OPERATOR = 'AND';
    private static String OR_OPERATOR = 'OR';
    private static String OPENING_BRACES = '(';
    private static String TRUE_BOOLEAN = 'TRUE';
    private static String FALSE_BOOLEAN = 'FALSE';
    private static Integer recursionLimit = CDdNameValuePairHelper.getIntegerValue(CDdNameValuePairConstants.MISSION_CONTROL_RECURSION_LIMIT);
    private static Integer noTimesRecursionCalled = 0;
    private static final String customMessage = 'Maximum stack depth reached.Limit is: '+recursionLimit+
                                                ' Rule is ignored for Expression: ';
    private static String inputExpression ='';
    /*****************************************************************************************************************************
   *
   * Public Methods
   *
   *****************************************************************************************************************************/
   /**
   * @author    Nayana
   * @date  11/01/2021
   * @decription This method accepts the String Expression and creates boolean string expression
   * @param   expression         1 AND (2 OR 3)
   *          mapNumberBoolean   {1=>true,2=>false,3=>true}
   * @return  Boolean            Evaluation of boolean expression.
   */
    public Boolean evaluateExpression(String expression,Map<Integer,Boolean> mapNumberBoolean) {
        noTimesRecursionCalled = 0;
        expression = expression.trim().replaceAll(' +',' ');
        expression = expression.replace('( ', '(');
        expression = expression.replace(' )', ')');
        inputExpression = expression;
        Integer index = 0;
        List<Integer> lstRemainingIndex = new List<Integer>();
        String[] arguments = expression.split(' ');
        try{
            for(String arg : arguments){
                Matcher numberMatch = isnumbers.matcher(arg);
                if(numberMatch.find()){
                    index = Integer.valueOf(arg.replaceAll('[^\\d]+?', ''));
                    //Vimp** this check was added as replaceAll function was replacing any number > 10 with the value with index <10
                    if(index>9){
                        if(mapNumberBoolean.containsKey(index)){
                            expression = expression.replaceAll(String.valueOf(index), String.valueOf(mapNumberBoolean.get(index)));
                        }
                    }else{
                        lstRemainingIndex.add(index);
                    }
                }
            }
            for(Integer i : lstRemainingIndex){
                if(mapNumberBoolean.containsKey(i)){
                    expression = expression.replaceAll(String.valueOf(i), String.valueOf(mapNumberBoolean.get(i)));
                }
            }
        }catch(Exception e){
            throw e;
        }
        return evaluateExpression(expression);
    }

   /**
   * @author    Nayana
   * @date  11/01/2021
   * @decription This method accepts boolean string expression
   * @param   expression         TRUE AND (FALSE OR TRUE) format
   * @return  Boolean            Evaluation of boolean expression.
   */
    public Boolean evaluateExpression(String expression) {
        // If expression contains all TRUE or FALSE
        try{
            //If expression dose not have False at all for AND /OR operator output will be True
            if(expression.containsNone('F') && expression.containsNone('f'))  { return TRUE; }
            //If expression dose not have True at all for AND /OR operator output will be False
            if(expression.containsNone('T') && expression.containsNone('t')) { return FALSE; }
            //If various combination then evaluate the equation
            return Boolean.valueOf(evaluateExpressionRecursively(expression.toUpperCase()));
        }catch(Exception e){
            throw e;
        }
    }

    /**
    * @author    Nayana
    * @date  11/01/2021
    * @decription This method is called recursively to find the final value
    * @param   expression         TRUE AND (FALSE OR TRUE) format
    * @return  Boolean            Evaluation of boolean expression.
    */
    public String evaluateExpressionRecursively(String expression) {
        noTimesRecursionCalled++;
        if(noTimesRecursionCalled>=recursionLimit){
            List<String> messages = new List<String> {customMessage+ inputExpression+'Evaluation failed: '+expression};
            CDdErrorUtilities.createApexLogs(messages,'CDdBooleanExpressionEvaluator', 
            'CDdBooleanExpressionEvaluator.evaluateExpressionRecursively',System.LoggingLevel.Error);
            return FALSE_BOOLEAN;
        }
        for(String operationType : mapExpressionValue.keySet()) {
            if(expression.contains(operationType)) {
                expression = simplifyExpression(expression, operationType);
            }
        }

        if(expression.contains(AND_OPERATOR) || expression.contains(OR_OPERATOR) || expression.contains(OPENING_BRACES)) {
            expression = evaluateExpressionRecursively(expression);
        }

        return expression;
    }


   /**
   * @author    Nayana
   * @date  11/01/2021
   * @decription This method will evaluate the expression and replace with the boolean value
   * @param   expression         TRUE AND (FALSE OR TRUE) format
   * @return  Boolean            Evaluation of boolean expression.
   */
    public string simplifyExpression(String expression, String LogicType){
        for(ExpressionValue key : mapExpressionValue.get(LogicType)) {
            expression = expression.replace(key.expression, key.expressionValue);
        }

        return expression;
    }

    /**
   * @author    Nayana
   * @date  11/01/2021
   * @decription This map has operator/Condition/Final boolean value for that
   * @param   None
   * @return  Map<String, List<ExpressionValue>>  Map of Operator and combination
   */
    public static Map<String, List<ExpressionValue>> mapExpressionValue{
        get{
            if(mapExpressionValue == null){
                mapExpressionValue = new Map<String, List<ExpressionValue>>();
                mapExpressionValue.put(AND_OPERATOR,new List<ExpressionValue>());
                mapExpressionValue.get(AND_OPERATOR).add(new ExpressionValue(AND_OPERATOR,'TRUE AND TRUE', TRUE_BOOLEAN));
                mapExpressionValue.get(AND_OPERATOR).add(new ExpressionValue(AND_OPERATOR,'TRUE AND FALSE', FALSE_BOOLEAN));
                mapExpressionValue.get(AND_OPERATOR).add(new ExpressionValue(AND_OPERATOR,'FALSE AND TRUE', FALSE_BOOLEAN));
                mapExpressionValue.get(AND_OPERATOR).add(new ExpressionValue(AND_OPERATOR,'FALSE AND FALSE', FALSE_BOOLEAN));


                mapExpressionValue.put(OR_OPERATOR,new List<ExpressionValue>());
                mapExpressionValue.get(OR_OPERATOR).add(new ExpressionValue(OR_OPERATOR,'TRUE OR TRUE', TRUE_BOOLEAN));
                mapExpressionValue.get(OR_OPERATOR).add(new ExpressionValue(OR_OPERATOR,'TRUE OR FALSE', TRUE_BOOLEAN));
                mapExpressionValue.get(OR_OPERATOR).add(new ExpressionValue(OR_OPERATOR,'FALSE OR TRUE', TRUE_BOOLEAN));
                mapExpressionValue.get(OR_OPERATOR).add(new ExpressionValue(OR_OPERATOR,'FALSE OR FALSE', FALSE_BOOLEAN));


                mapExpressionValue.put(OPENING_BRACES,new List<ExpressionValue>());
                mapExpressionValue.get(OPENING_BRACES).add(new ExpressionValue(OPENING_BRACES,'(TRUE)', TRUE_BOOLEAN));
                mapExpressionValue.get(OPENING_BRACES).add(new ExpressionValue(OPENING_BRACES,'(FALSE)', FALSE_BOOLEAN));
            }
            return mapExpressionValue;
        }
        set;
    }

    /**
   * @author    Nayana
   * @date  11/01/2021
   * @decription Wrapper class
   * @param   None
   */
    public class ExpressionValue{
        public String operator;
        public String expression;
        public String expressionValue;
        public ExpressionValue(String operation, String exp, String value){
            operator = operation;
            expression = exp;
            expressionValue = value;
        }
    }
}