/****************
* Class Name   : CDdupdateMacroInstructionsBatchV2
* Created Date : Dec 2022
* Author       : Nayana Kapse
* Description  : Batch class to update macros based on mapping provided
* Execute anonymous instructions: Set the variables for parent and child picklist
names (Ex: Field.Case.Issue_Type__c), the old value new value .
Use case 1: Both parent and child picklist provided : Update combination of Parent + Child old values to new
Use case 2: Just parent picklist : Update all macros for single picklist from old value to new value
Refer test class for sample code.
****************/

public with sharing class CDdupdateMacroInstructionsBatchV2 implements Database.Batchable<CDdupdateMacroInstructionsContext>, Database.Stateful {
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
    public List<CDdupdateMacroInstructionsContext> lstContextUpdate;
    public String csvBackup = 'Id,MacroId,Target,Value'+'\n';
    public String ticketNumber = '';
    /**
     * Overriden Constructor
     * This constructor called ro assign values
     */

    public CDdupdateMacroInstructionsBatchV2(String tNo,CDdupdateMacroInstructionsContext ctx){
        lstContextUpdate = new List<CDdupdateMacroInstructionsContext>();
        this.ticketNumber = tNo;
        this.lstContextUpdate.add(ctx);
    }

    public CDdupdateMacroInstructionsBatchV2(String tNo, List<CDdupdateMacroInstructionsContext> lstCtx){
        this.lstContextUpdate = lstCtx;
        this.ticketNumber = tNo;
    }
     /*****************************************************************************************************************************
     *
     * Start
     *
     ****************************************************************************************************************************/
    public Iterable<CDdupdateMacroInstructionsContext> start(Database.BatchableContext bc) {
        return lstContextUpdate;
    }

    /*****************************************************************************************************************************
    *
    * Execute
    *
    ****************************************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<CDdupdateMacroInstructionsContext> lstMacroUpdateWrapper) {
        CDdupdateMacroInstructionsContext contextUpdate = lstMacroUpdateWrapper[0];
        String queryStr  = 'Select Id,MacroId,Target,Value from MacroInstruction WHERE ';
        if(String.isNotBlank(contextUpdate.parentPicklistName) && String.isNotBlank(contextUpdate.mappingInstance.oldParentValue)
        && String.isNotBlank(contextUpdate.childPicklistName) && String.isNotBlank(contextUpdate.mappingInstance.oldChildValue)){
            queryStr  +=' (Target = \'' + contextUpdate.parentPicklistName + '\' AND Value =\'' + contextUpdate.mappingInstance.oldParentValue +'\')  OR (Target =\'' + contextUpdate.childPicklistName + '\' AND Value =\'' + contextUpdate.mappingInstance.oldChildValue +'\')';
        }else if(String.isNotBlank(contextUpdate.parentPicklistName) && String.isNotBlank(contextUpdate.mappingInstance.oldParentValue)){
            queryStr += ' Target = \'' + contextUpdate.parentPicklistName + '\' AND Value =\'' + contextUpdate.mappingInstance.oldParentValue+'\'';
        }
        List<MacroInstruction> macrosInScope = Database.query(queryStr);
        List<MacroInstruction> macrosToUpdate = new List<MacroInstruction>();
        Map<Id,List<MacroInstruction>> mapMacroIdMacroInstructions = new Map<Id,List<MacroInstruction>>();
        /*check for any macroInstruction in the macros of interest
        which have one of the old parent or child picklist value */
        //If handles Use case 1
        if(String.isNotBlank(contextUpdate.parentPicklistName) && String.isNotBlank(contextUpdate.mappingInstance.newParentValue)
            && String.isNotBlank(contextUpdate.childPicklistName) && String.isNotBlank(contextUpdate.mappingInstance.newChildValue)){
            //Prepare map to find instructions belonging to same macro
            for(MacroInstruction macroIns : macrosInScope){
                if(!mapMacroIdMacroInstructions.containsKey(macroIns.MacroId)){
                    mapMacroIdMacroInstructions.put(macroIns.MacroId,new List<MacroInstruction>());
                }
                mapMacroIdMacroInstructions.get(macroIns.MacroId).add(macroIns);
            }
            //Loop over macros to process MacroInstructions
            for(Id macroId : mapMacroIdMacroInstructions.keySet()){
                List<MacroInstruction> lstMacroInstructions = mapMacroIdMacroInstructions.get(macroId);
                //This is to make sure we check for combination of Parent and child
                if(lstMacroInstructions.size() == 2){
                    for(MacroInstruction macroIns : lstMacroInstructions){
                        appendMacroRecordToCsv(macroIns);
                        macroIns.Value = (macroIns.Target == contextUpdate.parentPicklistName) ? contextUpdate.mappingInstance.newParentValue : contextUpdate.mappingInstance.newChildValue;
                        macrosToUpdate.add(macroIns);
                    }
                }
            }
        }
        //Use case 2
        else{
            for(MacroInstruction macroIns : macrosInScope){
                if((macroIns.Target == contextUpdate.parentPicklistName && macroIns.Value == contextUpdate.mappingInstance.oldParentValue && String.isNotBlank(contextUpdate.mappingInstance.newParentValue))){
                    appendMacroRecordToCsv(macroIns);
                    macroIns.Value = contextUpdate.mappingInstance.newParentValue;
                    macrosToUpdate.add(macroIns);
                }
            }
        }

         //log errors if any
         List<Database.SaveResult> resList = Database.update(macrosToUpdate,false);
         List<String> errorMessages = CDdErrorUtilities.processSaveResults(resList, new List< String>());
         CDdErrorUtilities.createApexLogs(errorMessages,'CDdupdateMacroInstructionsBatchV2');
    }
    /*****************************************************************************************************************************
    *
    * Finish
    *
    ****************************************************************************************************************************/
    public void finish(Database.BatchableContext bc) {
        String title = ticketNumber+'-MacroUpdate-Backup-'+Datetime.now();
        ContentVersionService.createCSVContentFileSalesforce(title,csvBackup);
    }

    //helper to append records to csv body
    void appendMacroRecordToCsv(MacroInstruction macroIns){
        csvBackup += macroIns.Id + ','+macroIns.MacroId+','+macroIns.Target+',\"' + macroIns.Value + '\"\n';
    }
}