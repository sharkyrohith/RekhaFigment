/**
 * @description       : Trigger subscribes to the Qualtrics Send Survery Event
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 03-30-2022
 * @last modified by  : Jose Vega
**/
trigger TDdQualtricsSendSurveyEventTrigger on Qualtrics_Send_Survery_Event__e (after insert) {
    CDdQualtricsSurveyEventTriggerHandler.afterInsert(Trigger.new); 
}