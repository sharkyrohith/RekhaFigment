trigger TDdExceptionLogTrigger on Exception_Log__e (after insert) {
    CDdErrorUtilities.createLogFromPE(trigger.new);
}