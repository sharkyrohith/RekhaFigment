/**
  * @author:Mahesh C
  * @date  08/05/2021
  * @decription: This class is used as wrapper class for Payload in User Nesting Platform Event.
  */
public class UserNestingPayloadWrapper {
    
    public List<PresenceUserConfigUser> presenceUserConfigUsers {get; set;}
    public List<Id> existingUserId {get; set;}
    public Id contentId {get; set;}
    
    public UserNestingPayloadWrapper(List<PresenceUserConfigUser> presenceUserConfigUsers, List<Id> existingUserId) {
        this.presenceUserConfigUsers = presenceUserConfigUsers;
        this.existingUserId = existingUserId;
        this.contentId = null;
    }

    public UserNestingPayloadWrapper(Id contentId) {
        this.presenceUserConfigUsers = null;
        this.existingUserId = null;
        this.contentId = contentId;
    }
}