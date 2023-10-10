/****************
* Class Name   : CDdupdateMacroInstructionsBatch
* Created Date : Oct 5th 2022
* Author       : Sugan Karthik
* Description  : One time batch class to update macros based on mapping provided
* Execute anonymous instructions: Set the variables for parent and child picklist
names (Ex: Field.Case.Issue_Type__c), the old to new value maps for both parent and child picklist.
If the child variables (picklist name and map) are blank then the batch job assumes that we are only updating macros
for a single picklist which can be passed through the parent picklist variables. Refer test
class for sample code.
****************/
public class CDdupdateMacroInstructionsBatch implements Database.Batchable<SObject>, Database.Stateful {
    public String parentPicklistName;
    public String childPicklistName;
    public Map<String,String> oldParentValToNewParentVal;
    public Map<String,String> olldChilValToNewChildVal;
    public String ticketNum;
    public String csvBackup = 'Id,MacroId,Target,Value'+'\n';
    public CDdupdateMacroInstructionsBatch(String ticketNum,String parentPicklist, String childpicklist,Map<String,String> parentMap, Map<String,String> childMap){
        this.ticketNum = ticketNum;
        this.parentPicklistName = parentPicklist;
        this.childPicklistName = childpicklist;
        this.oldParentValToNewParentVal = parentMap;
        this.olldChilValToNewChildVal = childMap;
    }
    public Iterable<SObject> start(Database.BatchableContext bc) {
        //collect all the macro Ids corresponding to parent picklist values to be replaced
        List<MacroInstruction> parentMacroInstructions = [Select Id,MacroId,Target,Value from MacroInstruction where Target = :parentPicklistName and Value in :oldParentValToNewParentVal.keyset()];

        //if child picklist name is blank - then we are only updating a single picklist which is captured in the parent picklist variables
        if(String.isBlank(childPicklistName)){
            return parentMacroInstructions;
        }else{
            //code when updating macros for parent and child picklists
            Set<Id> macroIdsOfInterest = new Set<Id>();
            for(MacroInstruction macroIns : parentMacroInstructions){
                macroIdsOfInterest.add(macroIns.macroId);
            }
            List<MacroInstruction> parentAndChildMacroInstructions = [Select Id,MacroId,Target,Value from MacroInstruction where macroid in :macroIdsOfInterest and (Target = :parentPicklistName or Target = :childPicklistName)];
            return parentAndChildMacroInstructions;
        }

     }
     public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<MacroInstruction> macrosToUpdate = new List<MacroInstruction>();
        /*check for any macroInstruction in the macros of interest
        which have one of the old parent or child picklist value */
         for(MacroInstruction macroIns : (List<MacroInstruction>)scope){
            if((macroIns.Target == parentPicklistName && oldParentValToNewParentVal.containsKey(macroIns.Value)) ||
            (String.isNotBlank(childPicklistName) && macroIns.Target == childPicklistName && olldChilValToNewChildVal.containsKey(macroIns.Value))){
                appendMacroRecordToCsv(macroIns);
                macroIns.Value = (macroIns.Target == parentPicklistName) ? oldParentValToNewParentVal.get(macroIns.Value) : olldChilValToNewChildVal.get(macroIns.Value);
                macrosToUpdate.add(macroIns);
            }
         }
         //log errors if any
         List<Database.SaveResult> resList = Database.update(macrosToUpdate,false);
         List<String> errorMessages = CDdErrorUtilities.processSaveResults(resList, new List< String>());
         CDdErrorUtilities.createApexLogs(errorMessages,'CDdupdateMacroInstructionsBatch');
     }

    public void finish(Database.BatchableContext bc) {
        String title = ticketNum+'-MacroUpdate-Backup-'+Datetime.now();
        ContentVersionService.createCSVContentFileSalesforce(title,csvBackup);
    }

    //helper to append records to csv body
    void appendMacroRecordToCsv(MacroInstruction macroIns){
        csvBackup += macroIns.Id + ','+macroIns.MacroId+','+macroIns.Target+',\"' + macroIns.Value + '\"\n';
    }
}