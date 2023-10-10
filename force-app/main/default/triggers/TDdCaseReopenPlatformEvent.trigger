trigger TDdCaseReopenPlatformEvent on Case_Reopen_Event__e (after insert) {

    CDdCaseReopenHandler.handleCaseReopens(trigger.new);
    
}