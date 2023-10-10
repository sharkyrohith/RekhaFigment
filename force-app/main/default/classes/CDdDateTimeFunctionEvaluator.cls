/**
 * CDdDateTimeFunctionEvaluator
 *
 * @author      Mahesh Chouhan (mahesh.chouhan@ext.doordash.com)
 * @date        07/27/2022
 * @decription  Class which extends CDdFunctionEvaluator to evaluate functions related to Date and DateTime
 */
public class CDdDateTimeFunctionEvaluator extends CDdFunctionEvaluator {

    public override Object getValue(String functionName) {
        Object returnValue;
        switch on functionName {
            when 'TODAY()' {
                returnValue = System.today();
            }
            when 'NOW()' {
                returnValue = System.now();
            }
        }
        return returnValue;
    }
}