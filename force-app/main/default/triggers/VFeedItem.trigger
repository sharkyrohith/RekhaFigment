trigger VFeedItem on FeedItem (before insert) {
	
    VFeedItemTriggerHandler vHandler = new VFeedItemTriggerHandler();
    
    if (Trigger.isBefore){
        if(Trigger.isInsert) {
            vHandler.onBeforeInsert(Trigger.new);
        }
    }
}