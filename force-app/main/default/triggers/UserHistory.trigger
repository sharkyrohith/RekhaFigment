trigger UserHistory on User (after  update) {
   if (Trigger.isUpdate) {
            UserHistoryHelper.UserHistoryRecords(Trigger.new, Trigger.oldMap);
        }
   

}