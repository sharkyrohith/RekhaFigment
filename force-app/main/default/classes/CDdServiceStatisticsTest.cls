/**
 * 
 * @author: Tia Xuan
 * @date: 2019-00
 * @description test class for all Five9 and Live Agent classes
 * 
 */

@isTest
public class CDdServiceStatisticsTest {

    public class LiveAgentMockResp implements HttpCalloutMock{
        
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String result='{"id":"test","affinityToken":"test", "key":"test", "messages": [{"message": {"estimatedWaitTime":60000}}]}';
            res.setBody(result);
            return res;         
        }
    }  

    /**
    * @description test the five 9 and Live Agent scheduler
    **/
   @isTest static void schedulerWS() {
        String liveAgentRecordTypeId = Schema.SObjectType.Service_Statistics__c.getRecordTypeInfosByName().get('Live Agent').getRecordTypeId();
       
        Service_Statistics__c stat = new Service_Statistics__c();
        stat.Live_Agent_Button_ID__c ='5731a00000005i4';
        stat.Live_Agent_Deployment_ID__c ='5721a000000052x';
        stat.Live_Agent_Org_ID__c ='00D1a000000KEiHtest';
        stat.Live_Agent_Community__c = 'dasher';
        stat.Live_Agent_Language__c = 'en';
        stat.RecordTypeId = liveAgentRecordTypeId;
        insert stat;

        test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new LiveAgentMockResp());  
        SchedulableContext sc;
        CDdServiceStatisticsSched tstCls = new CDdServiceStatisticsSched();
        tstCls.execute(sc);
        test.stopTest();  

        Service_Statistics__c statLiveAgents =  [  select Id, Live_Agent_Estimated_Wait_Time__c 
                                                    from Service_Statistics__c 
                                                    where Id=: stat.Id];
        System.assert(statLiveAgents.Live_Agent_Estimated_Wait_Time__c != 0);
    }

    /**
    * @description test for wsdl2apex CDdFive9SupervisorWS
    **/
    @isTest static void supervisorWS() {

        test.startTest();
        CDdFive9SupervisorWS.WsSupervisorPort port = new CDdFive9SupervisorWS.WsSupervisorPort();
        port.acceptChatInvite('test',false);
        port.closeSession();
        port.getMyGroupIds();
        port.getSessionParameters();
        port.getMyPermissions(); 
        port.getDispositionsNames();
        port.loginStation('test',false,'test',2);
        port.setSessionParameters(null);
        port.resetCampaign('test');
        port.sendChatInvite('test',null); 
        port.stopCampaign('test');
        port.getStatisticsUpdate('test',1,1, true);
        port.reconnectStation(); 
        port.getMySkillsIds();
        port.closeChatSession('test');
        port.getColumnNames('test'); 
        port.sendBroadcastMessages('test',1,'test');
        port.sendInfoMessage(null,'test'); 
        port.getStatistics('test',null, true);
        port.removeUserFromChat('test',null);
        port.getLoggedInUsers();
        port.getCallCountersState();
        port.sendMsgToChat('test','test');
        port.getUserLimits();
        port.startCampaign('test');
        port.getMonitoringSupervisors('test');
        port.receiveMessages(1,1);
        port.resetCampaignDispositions('test',new List<String>(),DateTime.Now(),DateTime.Now());
        port.stopMonitoring('test');
        port.forceStopCampaign('test');
        port.startMonitoring('test','test');
        port.getApiVersions();
        port.createChatSession();
        
        CDdFive9SupervisorWS.sendMsgToChatResponse rep1 = new CDdFive9SupervisorWS.sendMsgToChatResponse();
        CDdFive9SupervisorWS.stationParameters rep3 = new CDdFive9SupervisorWS.stationParameters();
        CDdFive9SupervisorWS.sendBroadcastMessages rep4 = new CDdFive9SupervisorWS.sendBroadcastMessages();
        CDdFive9SupervisorWS.ChatFault rep5 = new CDdFive9SupervisorWS.ChatFault();
        CDdFive9SupervisorWS.loginStation rep6 = new CDdFive9SupervisorWS.loginStation();
        CDdFive9SupervisorWS.getStatisticsUpdateResponse rep7 = new CDdFive9SupervisorWS.getStatisticsUpdateResponse();
        CDdFive9SupervisorWS.forceStopCampaignResponse rep8 = new CDdFive9SupervisorWS.forceStopCampaignResponse();
        CDdFive9SupervisorWS.getSessionParameters rep9 = new CDdFive9SupervisorWS.getSessionParameters();
        CDdFive9SupervisorWS.getStatisticsResponse rep10 = new CDdFive9SupervisorWS.getStatisticsResponse();
        CDdFive9SupervisorWS.forceStopCampaign rep11 = new CDdFive9SupervisorWS.forceStopCampaign();
        CDdFive9SupervisorWS.CampaignStateUpdateFault rep12 = new CDdFive9SupervisorWS.CampaignStateUpdateFault();
        CDdFive9SupervisorWS.wsAgentGroup rep13 = new CDdFive9SupervisorWS.wsAgentGroup();
        CDdFive9SupervisorWS.closeChatSessionResponse rep14 = new CDdFive9SupervisorWS.closeChatSessionResponse();
        CDdFive9SupervisorWS.getUserLimitsResponse rep15 = new CDdFive9SupervisorWS.getUserLimitsResponse();
        CDdFive9SupervisorWS.sendInfoMessageResponse rep16 = new CDdFive9SupervisorWS.sendInfoMessageResponse();
        CDdFive9SupervisorWS.getUserLimits rep17 = new CDdFive9SupervisorWS.getUserLimits();
        CDdFive9SupervisorWS.WrongCampaignTypeFault rep18 = new CDdFive9SupervisorWS.WrongCampaignTypeFault();
        CDdFive9SupervisorWS.monitoringSupervisor rep19 = new CDdFive9SupervisorWS.monitoringSupervisor();
        CDdFive9SupervisorWS.getMyGroupIdsResponse rep20 = new CDdFive9SupervisorWS.getMyGroupIdsResponse();
        CDdFive9SupervisorWS.versions rep21 = new CDdFive9SupervisorWS.versions();
        CDdFive9SupervisorWS.StationNotFoundFault rep22 = new CDdFive9SupervisorWS.StationNotFoundFault();
        CDdFive9SupervisorWS.receiveMessagesResponse rep23 = new CDdFive9SupervisorWS.receiveMessagesResponse();
        CDdFive9SupervisorWS.getLoggedInUsers rep24 = new CDdFive9SupervisorWS.getLoggedInUsers();
        CDdFive9SupervisorWS.limitTimeoutState rep25 = new CDdFive9SupervisorWS.limitTimeoutState();
        CDdFive9SupervisorWS.getDispositionsNamesResponse rep26 = new CDdFive9SupervisorWS.getDispositionsNamesResponse();
        CDdFive9SupervisorWS.setSessionParametersResponse rep27 = new CDdFive9SupervisorWS.setSessionParametersResponse();
        CDdFive9SupervisorWS.viewSettings rep28 = new CDdFive9SupervisorWS.viewSettings();
        CDdFive9SupervisorWS.StationNotLoggedInFault rep29 = new CDdFive9SupervisorWS.StationNotLoggedInFault();
        CDdFive9SupervisorWS.closeChatSession rep30 = new CDdFive9SupervisorWS.closeChatSession();
        CDdFive9SupervisorWS.getColumnNames rep31 = new CDdFive9SupervisorWS.getColumnNames();
        CDdFive9SupervisorWS.callCounterState rep32 = new CDdFive9SupervisorWS.callCounterState();
        CDdFive9SupervisorWS.wsChatMessages rep33 = new CDdFive9SupervisorWS.wsChatMessages();
        CDdFive9SupervisorWS.sendInfoMessage rep34 = new CDdFive9SupervisorWS.sendInfoMessage();
        CDdFive9SupervisorWS.codecParameters rep35 = new CDdFive9SupervisorWS.codecParameters();
        CDdFive9SupervisorWS.removeUserFromChat rep36 = new CDdFive9SupervisorWS.removeUserFromChat();
        CDdFive9SupervisorWS.getStatisticsUpdate rep37 = new CDdFive9SupervisorWS.getStatisticsUpdate();
        CDdFive9SupervisorWS.IncorrectArgumentFault rep38 = new CDdFive9SupervisorWS.IncorrectArgumentFault();
        CDdFive9SupervisorWS.resetCampaignDispositionsResponse rep39 = new CDdFive9SupervisorWS.resetCampaignDispositionsResponse();
        CDdFive9SupervisorWS.getDispositionsNames rep40 = new CDdFive9SupervisorWS.getDispositionsNames();
        CDdFive9SupervisorWS.getApiVersionsResponse rep41 = new CDdFive9SupervisorWS.getApiVersionsResponse();
        CDdFive9SupervisorWS.sendChatInvite re42 = new CDdFive9SupervisorWS.sendChatInvite();
        CDdFive9SupervisorWS.OperationsLimitExceededFault rep43 = new CDdFive9SupervisorWS.OperationsLimitExceededFault();
        CDdFive9SupervisorWS.ConcurrentModificationFault rep44 = new CDdFive9SupervisorWS.ConcurrentModificationFault();
        CDdFive9SupervisorWS.closeSession rep45 = new CDdFive9SupervisorWS.closeSession();
        CDdFive9SupervisorWS.resetCampaignResponse rep46 = new CDdFive9SupervisorWS.resetCampaignResponse();
        CDdFive9SupervisorWS.values_element re47 = new CDdFive9SupervisorWS.values_element();
        CDdFive9SupervisorWS.getMySkillsIdsResponse rep48 = new CDdFive9SupervisorWS.getMySkillsIdsResponse();
        CDdFive9SupervisorWS.stopMonitoringResponse rep49 = new CDdFive9SupervisorWS.stopMonitoringResponse();
        CDdFive9SupervisorWS.createChatSession rep50 = new CDdFive9SupervisorWS.createChatSession();
        CDdFive9SupervisorWS.UserAlreadyLoggedInFault rep51 = new CDdFive9SupervisorWS.UserAlreadyLoggedInFault();
        CDdFive9SupervisorWS.getCallCountersState rep54 = new CDdFive9SupervisorWS.getCallCountersState();
        CDdFive9SupervisorWS.SessionClosedFault rep55 = new CDdFive9SupervisorWS.SessionClosedFault();
        CDdFive9SupervisorWS.sendMsgToChat rep56 = new CDdFive9SupervisorWS.sendMsgToChat();
        CDdFive9SupervisorWS.loginStationResponse re57 = new CDdFive9SupervisorWS.loginStationResponse();
        CDdFive9SupervisorWS.WrongCampaignStateFault rep58 = new CDdFive9SupervisorWS.WrongCampaignStateFault();
        CDdFive9SupervisorWS.supervisorPermission rep59 = new CDdFive9SupervisorWS.supervisorPermission();
        CDdFive9SupervisorWS.ReconnectStationFault rep60 = new CDdFive9SupervisorWS.ReconnectStationFault();
        CDdFive9SupervisorWS.statistics rep61 = new CDdFive9SupervisorWS.statistics();
        CDdFive9SupervisorWS.AgentNotFoundFault re62 = new CDdFive9SupervisorWS.AgentNotFoundFault();
        CDdFive9SupervisorWS.getStatistics rep63 = new CDdFive9SupervisorWS.getStatistics();
        CDdFive9SupervisorWS.ConfigurationChangedFault rep64 = new CDdFive9SupervisorWS.ConfigurationChangedFault();
        CDdFive9SupervisorWS.stopCampaign rep65 = new CDdFive9SupervisorWS.stopCampaign();
        CDdFive9SupervisorWS.reconnectStation rep66 = new CDdFive9SupervisorWS.reconnectStation();
        CDdFive9SupervisorWS.getMySkillsIds re67 = new CDdFive9SupervisorWS.getMySkillsIds();
        CDdFive9SupervisorWS.wsUserRoledId rep68 = new CDdFive9SupervisorWS.wsUserRoledId();
        CDdFive9SupervisorWS.InvalidAccountFault rep69 = new CDdFive9SupervisorWS.InvalidAccountFault();
        CDdFive9SupervisorWS.wsChatMessage rep70 = new CDdFive9SupervisorWS.wsChatMessage();
        CDdFive9SupervisorWS.startMonitoringResponse rep71 = new CDdFive9SupervisorWS.startMonitoringResponse();
        CDdFive9SupervisorWS.getMyGroupIds re72 = new CDdFive9SupervisorWS.getMyGroupIds();
        CDdFive9SupervisorWS.getMyPermissions rep73 = new CDdFive9SupervisorWS.getMyPermissions();
        CDdFive9SupervisorWS.MissedArgumentFault rep74 = new CDdFive9SupervisorWS.MissedArgumentFault();
        CDdFive9SupervisorWS.closeSessionResponse rep75 = new CDdFive9SupervisorWS.closeSessionResponse();
        CDdFive9SupervisorWS.receiveMessages rep76 = new CDdFive9SupervisorWS.receiveMessages();
        CDdFive9SupervisorWS.stopMonitoring re77 = new CDdFive9SupervisorWS.stopMonitoring();
        CDdFive9SupervisorWS.StatisticsNotRequestedFault rep78 = new CDdFive9SupervisorWS.StatisticsNotRequestedFault();
        CDdFive9SupervisorWS.getLoggedInUsersResponse rep79 = new CDdFive9SupervisorWS.getLoggedInUsersResponse();
        CDdFive9SupervisorWS.getApiVersions rep80 = new CDdFive9SupervisorWS.getApiVersions();
        CDdFive9SupervisorWS.getMonitoringSupervisorsResponse rep81 = new CDdFive9SupervisorWS.getMonitoringSupervisorsResponse();
        CDdFive9SupervisorWS.wsRoledId re82 = new CDdFive9SupervisorWS.wsRoledId();
        CDdFive9SupervisorWS.startCampaign rep83 = new CDdFive9SupervisorWS.startCampaign();
        CDdFive9SupervisorWS.UnknownTimestampFault rep84 = new CDdFive9SupervisorWS.UnknownTimestampFault();
        CDdFive9SupervisorWS.AccessDisallowedFault rep85 = new CDdFive9SupervisorWS.AccessDisallowedFault();
        CDdFive9SupervisorWS.ServerFault rep86 = new CDdFive9SupervisorWS.ServerFault();
        CDdFive9SupervisorWS.UnknownColumnFault re87 = new CDdFive9SupervisorWS.UnknownColumnFault();
        CDdFive9SupervisorWS.UserLimitReachedFault rep88 = new CDdFive9SupervisorWS.UserLimitReachedFault();
        CDdFive9SupervisorWS.SessionNotInitializedFault rep89 = new CDdFive9SupervisorWS.SessionNotInitializedFault();
        CDdFive9SupervisorWS.stopCampaignResponse rep90 = new CDdFive9SupervisorWS.stopCampaignResponse();
        CDdFive9SupervisorWS.sendBroadcastMessagesResponse rep91= new CDdFive9SupervisorWS.sendBroadcastMessagesResponse();
        CDdFive9SupervisorWS.removeUserFromChatResponse rep92 = new CDdFive9SupervisorWS.removeUserFromChatResponse();
        CDdFive9SupervisorWS.acceptChatInviteResponse rep93 = new CDdFive9SupervisorWS.acceptChatInviteResponse();
        CDdFive9SupervisorWS.wsUserLimits rep94 = new CDdFive9SupervisorWS.wsUserLimits();
        CDdFive9SupervisorWS.startCampaignResponse rep95 = new CDdFive9SupervisorWS.startCampaignResponse();
        CDdFive9SupervisorWS.wsSkill rep96 = new CDdFive9SupervisorWS.wsSkill();
        CDdFive9SupervisorWS.setSessionParameters rep97 = new CDdFive9SupervisorWS.setSessionParameters();
        CDdFive9SupervisorWS.resetCampaign rep98 = new CDdFive9SupervisorWS.resetCampaign();
        CDdFive9SupervisorWS.itemUpdate rep99 = new CDdFive9SupervisorWS.itemUpdate();
        CDdFive9SupervisorWS.ServiceUnavailableFault rep100 = new CDdFive9SupervisorWS.ServiceUnavailableFault();
        CDdFive9SupervisorWS.acceptChatInvite rep101 = new CDdFive9SupervisorWS.acceptChatInvite();
        CDdFive9SupervisorWS.getMyPermissionsResponse rep102 = new CDdFive9SupervisorWS.getMyPermissionsResponse();
        CDdFive9SupervisorWS.row rep103 = new CDdFive9SupervisorWS.row();
        CDdFive9SupervisorWS.AgentMonitorFault rep104 = new CDdFive9SupervisorWS.AgentMonitorFault();
        CDdFive9SupervisorWS.getMonitoringSupervisors rep105 = new CDdFive9SupervisorWS.getMonitoringSupervisors();
        CDdFive9SupervisorWS.resetCampaignDispositions rep106 = new CDdFive9SupervisorWS.resetCampaignDispositions();
        CDdFive9SupervisorWS.createChatSessionResponse rep107 = new CDdFive9SupervisorWS.createChatSessionResponse();
        CDdFive9SupervisorWS.startMonitoring rep108 = new CDdFive9SupervisorWS.startMonitoring();
        CDdFive9SupervisorWS.sendChatInviteResponse rep109 = new CDdFive9SupervisorWS.sendChatInviteResponse();
        CDdFive9SupervisorWS.getSessionParametersResponse rep110 = new CDdFive9SupervisorWS.getSessionParametersResponse();
        CDdFive9SupervisorWS.reconnectStationResponse rep111 = new CDdFive9SupervisorWS.reconnectStationResponse();
        CDdFive9SupervisorWS.CampaignNotFoundFault rep112 = new CDdFive9SupervisorWS.CampaignNotFoundFault();
        CDdFive9SupervisorWS.getColumnNamesResponse rep113 = new CDdFive9SupervisorWS.getColumnNamesResponse();
        CDdFive9SupervisorWS.DispositionNotFoundFault rep114 = new CDdFive9SupervisorWS.DispositionNotFoundFault();
        CDdFive9SupervisorWS.getCallCountersStateResponse rep115 = new CDdFive9SupervisorWS.getCallCountersStateResponse();
        CDdFive9SupervisorWS.statisticsUpdate rep116 = new CDdFive9SupervisorWS.statisticsUpdate();

        test.stopTest();  
    }
}