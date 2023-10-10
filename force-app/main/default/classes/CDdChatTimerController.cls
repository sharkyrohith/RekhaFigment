/**
 * 
 * @author: Tia Xuan
 * @date: 2020-06
 * @description class for CDdChatTimerController - creates a timer for chat transcript
 * 
 */
public class CDdChatTimerController {

    @AuraEnabled
    public static ChatInfo getChatInfo(ID tranId) {
        List<LiveChatTranscript> pRes = [select Id, 
                                                ChatKey,
                                                RequestTime,
                                                EndTime,
                                                Status
                                        from LiveChatTranscript 
                                        where ID = : tranId];
        if(pRes.size() == 1) {
            return new ChatInfo(pRes[0]);
        }

        return null;
    }

    public class ChatInfo{
        @AuraEnabled
        public String id {get; set;}

        @AuraEnabled
        public String chatKey {get; set;}

        @AuraEnabled
        public Long startTime {get; set;}

        @AuraEnabled
        public Long endTime {get; set;}

        @AuraEnabled
        public string status {get; set;}

        public ChatInfo(LiveChatTranscript trans){
            this.id = trans.Id;
            this.chatKey = trans.ChatKey;
            this.startTime = trans.RequestTime.getTime();
            if (trans.endTime != null){
                this.endTime = trans.EndTime.getTime();
            }
            this.status = trans.Status;
        }
       
    }
}