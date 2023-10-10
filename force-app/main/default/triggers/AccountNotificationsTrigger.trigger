trigger AccountNotificationsTrigger on Account_Notification__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete)
{
    new CDdMetadataTriggerHandler().run('Account_Notification__c');
}