/**
 * CDdSendbirdChatController
 *
 * @author     Sahil
 * @date  2021-03-30
 * @decription
 */
global class CDdSendbirdChatController {
  /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
  private static final String PATH_AGENT_USER = '/agent_chat_users';
  private static final String PATH_END_CHAT = '/chat_sessions/end';
  private static final String QUICKTEXT_CACHE_KEY = 'local.DoorDash.quickTextSendbird';
  public static Sendbird_Settings__c sendbirdSettings = Sendbird_Settings__c.getInstance();
  /*****************************************************************************************************************************
   *
   * Public/Global Variables
   *
   *****************************************************************************************************************************/
  global Case caseRecord { get; set; }
  global String sendbirdChannelUrl { get; set; }
  global String contactFirstName { get; set; }
  global String orgInstance { get; set; }
  /*****************************************************************************************************************************
   *
   * Constructors
   *
   *****************************************************************************************************************************/
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription VF controller constructor
   * @param   Standard controller
   * @return  None
   */
  global CDdSendbirdChatController(ApexPages.StandardController controller) {
    String caseId = controller.getId();
    if (String.isNotBlank(caseId)) {
      List<Case> caseList = [
        SELECT Id, ContactId, Contact.FirstName, ChatKey__c
        FROM Case
        WHERE Id = :caseId];

      if (!caseList.isEmpty()) {
        caseRecord = caseList[0];
      }

      if (caseRecord != null) {
        sendbirdChannelUrl = caseRecord.ChatKey__c;
        if (caseRecord.Contact != null) {
          contactFirstName = caseRecord.Contact.FirstName;
        }
      }
      orgInstance = 'https://' + ApexPages.currentPage().getHeaders().get('Host');
    }
  }
  /*****************************************************************************************************************************
   *
   * Public Methods
   *
   *****************************************************************************************************************************/
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription hits sendbird API and returns agent info back to lightning component
   * @param   agent's salesforce Id
   * @return  context about agent
   */
  @AuraEnabled(cacheable=true)
  public static String getAgentChatUserAura(String userId, String sendbirdChannelUrl) {
    if (String.isNotBlank(userId) && String.isNotBlank(sendbirdChannelUrl)) {
      return getAgentChatUserCommon(userId, sendbirdChannelUrl);
    } else {
      return null;
    }
  }
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription calls end chat on the sendbird API to end chat session
   * @param   channel URL to end
   * @return  response from sendbird API
   */
  @AuraEnabled
  public static String endChatAura(String channelUrl) {
    if (String.isNotBlank(channelUrl)) {
      return endChatCommon(channelUrl);
    } else {
      return null;
    }
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription gets a greeting message from quicktext object
   * @param   None
   * @return  greeting message
   */
  @AuraEnabled(cacheable=true)
  public static List<QuickText> getQuickTextAura() {
    return getQuickTextCommon();
  }
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription gets customer's details based on contact Id on case, sends back to lightning component
   * @param   contactId
   * @return  Contact object
   */
  @AuraEnabled(cacheable=true)
  public static Contact getContactAura(String contactId) {
    if (String.isNotBlank(contactId)) {
      return [SELECT Id, FirstName, LastName FROM Contact WHERE Id = :contactId LIMIT 1];
    }
    return null;
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription hits sendbird API and returns agent info back to visualforce page
   * @param   None
   * @return  None
   */
  @RemoteAction
  global static String getAgentChatUser(String userId, String sendbirdChannelUrl) {
    if (String.isNotBlank(userId) && String.isNotBlank(sendbirdChannelUrl)) {
      return getAgentChatUserCommon(userId, sendbirdChannelUrl);
    } else {
      return null;
    }
  }
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription calls end chat on the sendbird API to end chat session. response back to visualforce page
   * @param   channel url
   * @return  response from sendbird api
   */
  @RemoteAction
  global static String endChat(String channelUrl) {
    if (String.isNotBlank(channelUrl)) {
      return endChatCommon(channelUrl);
    } else {
      return null;
    }
  }
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription gets a greeting message from quicktext object. sends back to visualforce page
   * @param   None
   * @return  list of quicktext records
   */
  @RemoteAction
  global static List<QuickText> getQuickText() {
    return getQuickTextCommon();
  }

  /**
   * @author     Sahil
   * @date  2021-05-05
   * @decription checks case status and if agent is the case owner
   * @param   agent user id, case id
   * @return  boolean
   */
  @RemoteAction
  global static Boolean shouldConnectToChat(String caseId, String agentUserId) {
    Boolean retVal = false;
    if (String.isNotBlank(caseId) && String.isNotBlank(agentUserId)
        && !sendbirdSettings.Disable_SG_API__c) {
      List<Case> caseRecordList = [SELECT Id, Status, OwnerId, Origin, Channel__c, RecordTypeId
                         FROM Case WHERE Id =:caseId AND OwnerId =:agentUserId];
      if (!caseRecordList.isEmpty()) {
        Case caseRecord = caseRecordList[0];
        if (caseRecord.Status != CDdSupportConstants.CLOSED_STATUS
          && caseRecord.Status != CDdSupportConstants.SOLVED_STATUS
          && CDdCaseTriggerHelperV2.isSendbirdCase(caseRecord.Origin,
                                                  caseRecord.Channel__c,
                                                  caseRecord.RecordTypeId)) {
          retVal = true;
        }
      }
    }
    return retVal;
  }

/**
 * @author     Sahil
 * @date  2021-03-30
 * @decription common method used by both lightning and visualforce methods to get agent details
 * @param   user id of agent
 * @return  agent details
 */
global static String getAgentChatUserCommon(String userId, String sendbirdChannelUrl) {
    String body = JSON.serialize(
      new Map<String, String>{
        'salesforceAgentId' => userId,
        'nickName' => UserInfo.getFirstName(),
        'channelUrl' => sendbirdChannelUrl
      }
    );

    String response = CDdSendBirdAPIHandler.makeRequest(
                                              CDdCoreConstants.HTTP_POST,
                                              PATH_AGENT_USER,
                                              body);
    return response;
  }
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription common method used by both lightning and visualforce methods to end sendbird chat
   * @param   channel url
   * @return  response from sendbird api
   */
  global static String endChatCommon(String channelUrl) {
    String body = JSON.serialize(
      new Map<String, String>{ 'channelUrl' => channelUrl }
    );
    String response = CDdSendBirdAPIHandler.makeRequest(
                                            CDdCoreConstants.HTTP_POST,
                                            PATH_END_CHAT,
                                            body);
    return response;
  }
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription gets a greeting message from quicktext object. sends to visualforce remote action or aura enabled method
   * @param   None
   * @return  list of quicktext records
   */
  global static List<QuickText> getQuickTextCommon() {
    return CDdSendbirdCacheHandler.getCachedQuickText(QUICKTEXT_CACHE_KEY,CDdSupportConstants.LIVEAGENT_CHANNEL);
  }

  /**
   * @author     Sahil
   * @date  2021-10-31
   * @decription gets the sendbird chat queues to the calling client
   * @param   None
   * @return  list of sendbird chat queues
   */
  @RemoteAction
  global static String getChatQueues() {
    return JSON.serialize(CDdSupportHelper.queueBusinessHoursValidation(CDdSupportHelper.sbChatQueues));
  }

  /**
   * @author     Sahil
   * @date  2021-10-31
   * @decription initiates transfer of case from the calling client
   * @param   Case Id and the Id of the new owner the case should be transferred to
   * @return  response from salesforce
   */
  @RemoteAction
  global static String transferChat(String caseId, String newOwnerId) {
    if (String.isNotBlank(caseId) && String.isNotBlank(newOwnerId)) {
      try {
        Case caseObj = new Case(Id = caseId, OwnerId = newOwnerId);
        update caseObj;
        return caseObj.Id;
      } catch (DmlException e) {
        String errorMessage = CDdCoreConstants.BLANK_STRING;
        for (Integer i = 0; i < e.getNumDml(); i++) {
            errorMessage =+ e.getDmlMessage(i) + CDdCoreConstants.NEW_LINE;
        }
        throw new CDdSendbirdChatControllerException(errorMessage);
      } catch (Exception e) {
        throw new CDdSendbirdChatControllerException(e.getMessage());
      }
    }
    return CDdCoreConstants.HTTP_NO_RESP;
  }

  private static Boolean isPayloadKeyValid(Map<String,Object> payload, String key) {
    return payload != null && payload.containsKey(key);
  }

  @RemoteAction
  global static Object processSendbirdAction(String action,Map<String,Object> payload) {
    return processSendbirdAction_Helper(action,payload);
  }

  @AuraEnabled(cacheable=true)
  global static Object processSendbirdActionCacheableAura(String action,Map<String,Object> payload) {
    return processSendbirdAction_Helper(action,payload);
  }

  @AuraEnabled
  global static Object processSendbirdActionNonCacheableAura(String action,Map<String,Object> payload) {
    return processSendbirdAction_Helper(action,payload);
  }

  private static Object processSendbirdAction_Helper(String action,Map<String,Object> payload) {
    switch on action {
      when 'should_connect' {
        if (!isPayloadKeyValid(payload,'agentUserId') || !isPayloadKeyValid(payload,'caseId')) {
          throw new CDdSendbirdChatControllerException('[CDdSendbirdChatController.processSendbirdAction]: should_connect arguments missing');
        }
        String caseId = (String)payload.get('caseId');
        String agentUserId = (String)payload.get('agentUserId');
        return shouldConnectToChat(caseId, agentUserId);
      }
      when 'chat_info' {
        if (!isPayloadKeyValid(payload,'userId') || !isPayloadKeyValid(payload,'sendbirdChannelUrl')) {
          throw new CDdSendbirdChatControllerException('[CDdSendbirdChatController.processSendbirdAction]: chat_info arguments missing');
        }
        String userId = (String)payload.get('userId');
        String sendbirdChannelUrl = (String)payload.get('sendbirdChannelUrl');
        String chatInfo = getAgentChatUserAura(userId, sendbirdChannelUrl);
        if (String.isBlank(chatInfo)) {
          throw new CDdSendbirdChatControllerException('[CDdSendbirdChatController.processSendbirdAction]: chat_info API response is blank');
        }
        Map<String,Object> chatInfoMap = (Map<String,Object>)JSON.deserializeUntyped(chatInfo);
        Map<String,Object> retVal = new Map<String,Object> {
          'sendbirdAppId' => chatInfoMap.get('applicationId'),
          'sendbirdToken' => chatInfoMap.get('chatUserAccessToken'),
          'sendbirdUserId' => chatInfoMap.get('chatUserId'),
          'sendbirdChannelUrl' => sendbirdChannelUrl
        };
        return retVal;
      }
      when 'transfer_queues' {
        List<Sendbird_Chat_Queue__mdt> sendbirdQueues = CDdSupportHelper.queueBusinessHoursValidation(CDdSupportHelper.sbChatQueues);
        List<QueueWrapper> queues = new List<QueueWrapper>();
        for (Sendbird_Chat_Queue__mdt sendbirdQueue : sendbirdQueues) {
          queues.add(new QueueWrapper(sendbirdQueue));
        }
        Map<String,Object> retVal = new Map<String,Object> {
          'items' => queues
        };
        return retVal;
      }
      when 'quick_text' {
        List<QuickTextWrapper> quickTexts = new List<QuickTextWrapper>();
        for (QuickText quickText : getQuickTextCommon()) {
          quickTexts.add(new QuickTextWrapper(quickText));
        }

        Map<String,Object> retVal = new Map<String,Object> {
          'items' => quickTexts
        };

        if (isPayloadKeyValid(payload,'contactId')) {
          String contactId = (String)payload.get('contactId');
          if (String.isNotBlank(contactId)) {
            try{
              Contact con = getContactAura(contactId);
              Map<String,Object> contactRetVal = new Map<String,Object>{
                'Contact' => con,
                'Contact_FirstName' => con.FirstName
              };
              retVal.put('fieldMap',contactRetVal);
            } catch(Exception ex) {
              // If contact not found, then returning just quickText
            }
          }
        }
        return retVal;
      }
      when 'end_chat' {
        if (!isPayloadKeyValid(payload,'channelUrl')) {
          throw new CDdSendbirdChatControllerException('[CDdSendbirdChatController.processSendbirdAction]: end_chat arguments missing');
        }
        String channelUrl = (String)payload.get('channelUrl');
        return endChatCommon(channelUrl);
      }
      when 'transfer_chat' {
        if (!isPayloadKeyValid(payload,'caseId') || !isPayloadKeyValid(payload,'newOwnerId')) {
          throw new CDdSendbirdChatControllerException('[CDdSendbirdChatController.processSendbirdAction]: transfer_chat arguments missing');
        }
        String caseId = (String)payload.get('caseId');
        String newOwnerId = (String)payload.get('newOwnerId');
        return transferChat(caseId,newOwnerId);
      }
    }
    throw new CDdSendbirdChatControllerException('[CDdSendbirdChatController.processSendbirdAction]: Unexpected action - ' + action);
  }

  public class QuickTextWrapper {
    @AuraEnabled public String name {get;set;}
    @AuraEnabled public String message {get;set;}
    public QuickTextWrapper(QuickText qt) {
      this.name = qt.Name;
      this.message = qt.Message;
    }
  }

  public class QueueWrapper {
    @AuraEnabled public String id {get;set;}
    @AuraEnabled public String name {get;set;}
    public QueueWrapper(Sendbird_Chat_Queue__mdt sendbirdQueue) {
      this.id = sendbirdQueue.Queue_ID__c;
      this.name = sendbirdQueue.Label;
    }
  }

  public class CDdSendbirdChatControllerException extends Exception{}
}