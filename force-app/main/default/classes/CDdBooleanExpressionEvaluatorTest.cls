/**
 * CDdBooleanExpressionEvaluatorTest
 *
 * @author     Nayana
 * @date    11/10/2021
 * @decription Test class for CDdBooleanExpressionEvaluator
 */
@isTest
public with sharing class CDdBooleanExpressionEvaluatorTest {
    /**
   * @author    Nayana
   * @date  11/10/2021
   * @decription This method to evaluate most of the combinations
   */
    @isTest static void testEvaluateExpression() {
        CDdBooleanExpressionEvaluator cEval = new CDdBooleanExpressionEvaluator();
        System.assert(cEval.evaluateExpression('TRUE'));
        System.assert(cEval.evaluateExpression('TRUE OR FALSE'));
        System.assert(cEval.evaluateExpression('TRUE OR TRUE'));
        System.assert(cEval.evaluateExpression('TRUE OR (TRUE AND FALSE)'));
        System.assert(cEval.evaluateExpression('TRUE OR (TRUE AND FALSE AND TRUE OR TRUE)'));
        System.assert(cEval.evaluateExpression('TRUE OR (TRUE AND FALSE AND (TRUE OR FALSE))'));
        System.assert(cEval.evaluateExpression('TRUE OR (TRUE OR (FALSE AND (TRUE OR FALSE)))'));
        System.assert(cEval.evaluateExpression('(FALSE OR ((TRUE OR FALSE) AND (TRUE OR FALSE)))'));

        System.assert(!cEval.evaluateExpression('FALSE'));
        System.assert(!cEval.evaluateExpression('TRUE AND FALSE'));
        System.assert(!cEval.evaluateExpression('FALSE AND FALSE'));
        System.assert(!cEval.evaluateExpression('TRUE AND (TRUE AND FALSE)'));
        System.assert(!cEval.evaluateExpression('FALSE AND (TRUE AND FALSE AND TRUE OR TRUE)'));
        System.assert(!cEval.evaluateExpression('TRUE AND (TRUE AND FALSE AND (TRUE OR FALSE))'));
        System.assert(!cEval.evaluateExpression('TRUE AND (TRUE AND (FALSE AND (TRUE OR FALSE)))'));
        System.assert(!cEval.evaluateExpression('(FALSE AND ((TRUE OR FALSE) AND (TRUE OR FALSE)))'));
    }

    /**
   * @author    Nayana
   * @date  11/10/2021
   * @decription This method to evaluate Expression to false
   */
    @isTest static void testEvaluateExpressionMap_1() {
        Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
        mapRuleNoCriterion.put(1, true);
        mapRuleNoCriterion.put(2, false);
        mapRuleNoCriterion.put(3, true);
        mapRuleNoCriterion.put(4, true);
        mapRuleNoCriterion.put(5, true);
        mapRuleNoCriterion.put(6, false);
        mapRuleNoCriterion.put(7, true);
        mapRuleNoCriterion.put(8, false);
        mapRuleNoCriterion.put(9, true);
        mapRuleNoCriterion.put(10, false);
        mapRuleNoCriterion.put(11, true);
        String expression = '((1 AND 2) OR (3 AND 4)) AND 6 AND (7 OR 8) AND 9 AND (10 OR 11)';
        CDdBooleanExpressionEvaluator cEval = new CDdBooleanExpressionEvaluator();
        Test.startTest();
        	Boolean overallExpressionVal = cEval.evaluateExpression(expression,mapRuleNoCriterion);
        Test.stopTest();
        System.assertEquals(false, overallExpressionVal, 'The expression should evaluate as false');
    }

     /**
   * @author    Nayana
   * @date  11/10/2021
   * @decription This method to evaluate Expression to true
   */
    @isTest static void testEvaluateExpressionMap_2() {
        Map<Integer,Boolean> mapRuleNoCriterion = new Map<Integer,Boolean>();
        mapRuleNoCriterion.put(1, true);
        mapRuleNoCriterion.put(2, false);
        mapRuleNoCriterion.put(3, true);
        String expression = '1 AND (2 OR 3)';
        CDdBooleanExpressionEvaluator cEval = new CDdBooleanExpressionEvaluator();
        Test.startTest();
        	Boolean overallExpressionVal = cEval.evaluateExpression(expression,mapRuleNoCriterion);
        Test.stopTest();
        System.assertEquals(true, overallExpressionVal, 'The expression should evaluate as true');
    }

    /**
    * @author    Nayana
    * @date      March 2022
    * @decription This method to test Maximum stack depth reached error
    */
    @isTest static void testMaximumStackReached() {
        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getOrgDefaults();
        loggerSettings.Enable_Logging__c = true; 
        upsert loggerSettings; 
        String expression = 'TRUE AND (2 OR TRUE)';
        CDdBooleanExpressionEvaluator cEval = new CDdBooleanExpressionEvaluator();
        Test.startTest();
        String overallExpressionVal = cEval.evaluateExpressionRecursively(expression);
        Test.stopTest();
        System.assertEquals('FALSE', overallExpressionVal, 'As Maximum Stack reached');
        List<Apex_Log__c> lstLogs = [SELECT Id,CreatedBy.Name,Class_Name__c,Log__c,Method_Name__c,Log_Level__c 
                                    FROM Apex_Log__c WHERE createdDate=today];
        System.assertEquals(true, lstLogs.size()>0, 'Apex log should get created');                            
    }
}