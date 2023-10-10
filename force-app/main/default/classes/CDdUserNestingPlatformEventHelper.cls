/**
  * @author:Mahesh C
  * @date  08/05/2021
  * @decription: Handler for User Nesting Platform Event.
  */
  public class CDdUserNestingPlatformEventHelper {

    /**
    * @author Mahesh C
    * @description Create Platform Event
    **/
    public static User_Nesting__e createEvent(List<PresenceUserConfigUser> presUserConfigUserList, List<Id> selectedUserIdlst, Id contentDocumentId) {
        User_Nesting__e userNestingEvent;
        UserNestingPayloadWrapper userNestingWrapper;

        if(contentDocumentId != null) {
            userNestingWrapper = new UserNestingPayloadWrapper(contentDocumentId);
        }
        else {
            userNestingWrapper = new UserNestingPayloadWrapper(presUserConfigUserList, selectedUserIdlst);
        }

        String payLoad = JSON.serialize(userNestingWrapper);
        userNestingEvent = new User_Nesting__e(Payload__c=payLoad);
        return userNestingEvent;
    }

    /**
    * @author Mahesh C
    * @description Publish Platform Event
    **/
    public static void publishEvent(User_Nesting__e userNestingEvent) {
        EventBus.publish(userNestingEvent);
    }

    /**
    * @author Mahesh C
    * @description Create and Publish Platform Event from List<PresenceUserConfigUser> and List<Id>
    **/
    public static void publishEvent(List<PresenceUserConfigUser> presUserConfigUserList, List<Id> selectedUserIdlst) {
        publishEvent(createEvent(presUserConfigUserList, selectedUserIdlst, null));
    }

    /**
    * @author Mahesh C
    * @description Create and Publish Platform Event from Content Document Id
    **/
    public static void publishEvent(Id contentDocumentId) {
        publishEvent(createEvent(null, null, contentDocumentId));
    }

    /**
    * @author Mahesh C
    * @description Handles User Nesting Platform Event
    **/
    public static void handleEvents(List<User_Nesting__e> eventList) {
        for(User_Nesting__e userNesting : eventList) {
            UserNestingPayloadWrapper userNestingWrapper = (UserNestingPayloadWrapper) JSON.deserialize(userNesting.Payload__c, UserNestingPayloadWrapper.class);
        
            if(userNestingWrapper.contentId != null) {
                CDdBulkAPIUtility.importBulkdata(userNestingWrapper.contentId, false);
            }
            else {
                System.enqueueJob(new CDdPresenceConfigQueueable(userNestingWrapper.presenceUserConfigUsers, userNestingWrapper.existingUserId));
            }
        }
    }
}