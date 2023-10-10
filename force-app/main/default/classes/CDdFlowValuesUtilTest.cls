@isTest
public class CDdFlowValuesUtilTest{    
    @isTest
    static void CDdFlowValuesUtil(){    
        List<string> tempLst = new list<string>();
        tempLst.add('AccidentalCoder');
        tempLst.add('Salesforce');
        CDdFlowValuesUtil.CheckValues(tempLst);
        CDdFlowValuesUtil.CheckValues(new list<string>());
    }
}