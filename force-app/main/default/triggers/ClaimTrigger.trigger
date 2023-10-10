/**
 * @author     Mahesh Chouhan
 * @date       July 2023
 * @decription Trigger for Claim object
 * @jira       https://doordash.atlassian.net/browse/BIZS-3018
 */

trigger ClaimTrigger on Claim__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete)
{
    new CDdMetadataTriggerHandler().run('Claim__c');
}