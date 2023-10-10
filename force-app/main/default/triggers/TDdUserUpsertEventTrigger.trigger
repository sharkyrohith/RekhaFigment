/**
* @author Knick
* @description BZAP-7117 Add / Remove Permissions and Licenses for Users
* @date 2020-06
*/
trigger TDdUserUpsertEventTrigger on User_Upsert_Event__e (after insert) {

    if (! CDdRecursionUtils.isRunnable('TDdUserUpsertEventTrigger')) return;

    CDdUserTriggerHelper.handleUserUpsertEvents(trigger.new);

}