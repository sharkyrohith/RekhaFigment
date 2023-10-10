trigger TDdAttachmentTrigger on Attachment (before insert) {
    CDdAttachmentTriggerHandler handler = new CDdAttachmentTriggerHandler();
    if (Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    }
}