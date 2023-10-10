/****************
* Class Name   : CDdupdateMacroInstructionsBatchV2Test
* Created Date : Dec 2022
* Author       : Nayana Kapse
* Description  : Test class for CDdupdateMacroInstructionsBatchV2
****************/
@isTest
public with sharing class CDdupdateMacroInstructionsBatchV2Test {
    @testSetup
    static void testSetup() {
        List<Macro> lstMacro = new List<Macro>();
        lstMacro.add(new Macro(Name='test macro1',description='test'));
        lstMacro.add(new Macro(Name='test macro2',description='test'));
        insert lstMacro;
        List<MacroInstruction> macroIns = new List<MacroInstruction>();
        macroIns.add(new MacroInstruction(SortOrder=1,Target = 'Field.Case.Issue_Type__c',Value = 'old issue category value',macroId=lstMacro[0].Id, Operation='Set'));
        macroIns.add(new MacroInstruction(SortOrder=2,Target = 'Field.Case.Issue__c',Value = 'old issue value',macroId=lstMacro[0].Id, Operation='Set'));
        macroIns.add(new MacroInstruction(SortOrder=1,Target = 'Field.Case.Issue_Type__c',Value = 'old issue category value',macroId=lstMacro[1].Id, Operation='Set'));
        macroIns.add(new MacroInstruction(SortOrder=2,Target = 'Field.Case.Issue__c',Value = 'old issue value1',macroId=lstMacro[1].Id, Operation='Set'));
        insert macroIns;
    }
    @isTest
	static void updateMacros(){
        CDdupdateMacroInstructionsContext cntx = new CDdupdateMacroInstructionsContext('Field.Case.Issue_Type__c',
        'Field.Case.Issue__c','old issue category value','new issue category value','old issue value','new issue value');
        CDdupdateMacroInstructionsBatchV2 macroUpdate = new CDdupdateMacroInstructionsBatchV2('BIZS-XXXX', cntx);
        Id jobId;
        Test.startTest();
        jobId = Database.executeBatch(macroUpdate);
        Test.stopTest();
        AsyncApexJob a = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed',a.Status);
        List<MacroInstruction> lstMacroInstruction = [SELECT target,value,MacroId FROM MacroInstruction WHERE createdDate = Today AND Target = 'Field.Case.Issue_Type__c' AND Value = 'new issue category value'];
        System.assertEquals(1,lstMacroInstruction.size(),'only 1 macro should get updated');
        List<MacroInstruction> lstMacroInstruction2 = [SELECT target,value,MacroId FROM MacroInstruction WHERE MacroId =: lstMacroInstruction[0].MacroId  AND Target = 'Field.Case.Issue__c'];
        System.assertEquals('new issue value',lstMacroInstruction2[0].value,'Issue should be updated to this value');
    }

    @isTest
	static void updateJustOnePicklistMacros1(){
        CDdupdateMacroInstructionsContext cntx = new CDdupdateMacroInstructionsContext('Field.Case.Issue_Type__c','old issue category value','new issue category value');
        CDdupdateMacroInstructionsBatchV2 macroUpdate = new CDdupdateMacroInstructionsBatchV2('BIZS-XXXX',cntx);
        Id jobId;
        Test.startTest();
        jobId = Database.executeBatch(macroUpdate);
        Test.stopTest();
        AsyncApexJob a = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed',a.Status);
        for(MacroInstruction mi : [SELECT target,value FROM MacroInstruction WHERE createdDate = Today]){
            if(mi.target == 'Field.Case.Issue_Type__c'){
                System.assertEquals(mi.Value, 'new issue category value','both macro parent value should be updated to new value');
            }else if(mi.target == 'Field.Case.Issue__c'){
                System.assertEquals((mi.Value == 'old issue value'  || mi.Value == 'old issue value1'), true ,'No change on child value');
            }
        }
    }

    @isTest
	static void updateJustOnePicklistMacros2(){
        List<CDdupdateMacroInstructionsContext> lstCntxt = new List<CDdupdateMacroInstructionsContext>();
        CDdupdateMacroInstructionsContext cntx = new CDdupdateMacroInstructionsContext('Field.Case.Issue__c','old issue value','new issue value');
        lstCntxt.add(cntx);
        CDdupdateMacroInstructionsBatchV2 macroUpdate = new CDdupdateMacroInstructionsBatchV2('BIZS-XXXX',lstCntxt);
        Id jobId;
        Test.startTest();
        jobId = Database.executeBatch(macroUpdate);
        Test.stopTest();
        AsyncApexJob a = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed',a.Status);
        for(MacroInstruction mi : [SELECT target,value FROM MacroInstruction WHERE createdDate = Today]){
            if(mi.target == 'Field.Case.Issue__c' && mi.Value!='old issue value1'){
                System.assertEquals(mi.Value, 'new issue value','only matching child value should be updated to new value');
            }
        }
    }
}