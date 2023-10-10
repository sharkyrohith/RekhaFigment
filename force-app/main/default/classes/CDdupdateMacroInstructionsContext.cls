/****************
* Class Name   : CDdupdateMacroInstructionsContext
* Created Date : Dec 2022
* Author       : Nayana Kapse
******************/
public with sharing class CDdupdateMacroInstructionsContext {
    public String parentPicklistName { get; set; }
    public String childPicklistName { get; set; }
    public oldToNewValueMapping mappingInstance { get;set; }
    public class oldToNewValueMapping {
        public String oldParentValue { get; set; }
        public String newParentValue { get; set; }
        public String oldChildValue { get; set; }
        public String newChildValue { get; set; }
    }

    public CDdupdateMacroInstructionsContext(String parentPicklist, String childpicklist,String oldPVal,String newPVal,String oldCVal,String newCVal){
        this.parentPicklistName = parentPicklist;
        this.childPicklistName = childpicklist;
        this.mappingInstance = new oldToNewValueMapping();
        this.mappingInstance.oldParentValue = oldPVal;
        this.mappingInstance.newParentValue = newPVal;
        this.mappingInstance.oldChildValue = oldCVal;
        this.mappingInstance.newChildValue = newCVal;
    }

    public CDdupdateMacroInstructionsContext(String singlePicklist,String oldVal,String newVal){
        this.parentPicklistName = singlePicklist;
        this.mappingInstance = new oldToNewValueMapping();
        this.mappingInstance.oldParentValue = oldVal;
        this.mappingInstance.newParentValue = newVal;
    }
}