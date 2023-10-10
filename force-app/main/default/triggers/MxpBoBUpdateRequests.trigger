trigger MxpBoBUpdateRequests on MXP_BoB_Update_Request__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete)
{
    new CDdMetadataTriggerHandler().run('MXP_BoB_Update_Request__c');
}