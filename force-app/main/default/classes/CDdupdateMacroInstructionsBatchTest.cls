/****************
* Class Name   : CDdupdateMacroInstructionsBatchTest
* Created Date : Oct 5th 2022
* Author       : Sugan Karthik
* Description  : Test class for CDdupdateMacroInstructionsBatch and CDdBulkUpdateMacroController
****************/
@isTest
public class CDdupdateMacroInstructionsBatchTest {
    @testSetup
    static void setup() {
        Macro macroRec = new Macro(Name='test macro',description='test');
        insert macroRec;
        List<MacroInstruction> macroIns = new List<MacroInstruction>();
        macroIns.add(new MacroInstruction(SortOrder=1,Target = 'Field.Case.Issue_Type__c',Value = 'old issue category value',macroId=macroRec.Id, Operation='Set'));
        macroIns.add(new MacroInstruction(SortOrder=2,Target = 'Field.Case.Issue__c',Value = 'old issue value',macroId=macroRec.Id, Operation='Set'));
        insert macroIns;
    }
    @isTest
	static void updateMacros(){
        Map<String,String> issueCategMap = new  Map<String,String>{'old issue category value'=>'new issue category value'};
        Map<String,String> issueMap = new  Map<String,String>{'old issue value'=>'new isse value'};
        String parentPicklist = 'Field.Case.Issue_Type__c';
        String childPicklist = 'Field.Case.Issue__c';
        CDdupdateMacroInstructionsBatch macroUpdate = new CDdupdateMacroInstructionsBatch('BIZS-XXXX',parentPicklist,childPicklist,issueCategMap,issueMap);
        Id jobId;
        Test.startTest();
        jobId = Database.executeBatch(macroUpdate);
        Test.stopTest();
        AsyncApexJob a = [Select Id, Status from AsyncApexJob where Id = :jobId];
        System.assertEquals('Completed',a.Status);
        for(MacroInstruction mi : [Select target,value from MacroInstruction where macro.name = 'test macro']){
            if(mi.target == parentPicklist){
                System.assertEquals(mi.Value, 'new issue category value');
            }else if(mi.target == childPicklist){
                System.assertEquals(mi.Value, 'new isse value');
            }
        }
    }

    @isTest
	static void testLWCController(){
        List<CDdupdateMacroInstructionsContext.oldToNewValueMapping> csvData = new  List<CDdupdateMacroInstructionsContext.oldToNewValueMapping>();
        CDdupdateMacroInstructionsContext.oldToNewValueMapping csvRow = new CDdupdateMacroInstructionsContext.oldToNewValueMapping();
        csvRow.oldParentValue = 'old issue category value';
        csvRow.newParentValue = 'new issue category value';
        csvRow.oldChildValue = 'old issue value';
        csvRow.newChildValue = 'new issue value';
        csvData.add(csvRow);
        String csvDataJson = JSON.serialize(csvData);
        Test.startTest();
        CDdBulkUpdateMacroController.runMacroUpdateBatchJob('BIZS-TEST','Case.Issue_Type__c','Case.Issue__c',csvDataJson);
        Test.stopTest();
        for(MacroInstruction mi : [Select target,value from MacroInstruction where macro.name = 'test macro']){
            if(mi.target == 'Field.Case.Issue_Type__c'){
                System.assertEquals(mi.Value, 'new issue category value');
            }else if(mi.target == 'Field.Case.Issue__c'){
                System.assertEquals(mi.Value, 'new issue value');
            }
        }
    }
}