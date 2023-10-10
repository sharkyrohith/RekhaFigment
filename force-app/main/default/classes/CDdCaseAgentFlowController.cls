/**
 * 
 * @author: Tia Xuan
 * @date: 2020-07
 * @description Controller to get the Case Agent flow
 *              BZAPSUP-297 Add Ax Guide atop Case page layout
 */
public class CDdCaseAgentFlowController {
    
    @AuraEnabled
    public static Case_Agent_Flow__c getCaseAgentFlow(String caseId){
        Case c = [  select  Id, 
                            RecordTypeId,
                            Origin,
                            Channel__c,
                            Platform__c,
                            Pre_Chat_Category__c,
                            Pre_Chat_Sub_Category__c,
                            Chat_Issue__c,
                            Chat_Issue_Details__c,
                            Alert_Type__c,
                            Description,
                            DeliveryNo__c,
                            DeliveryUUID__c,
                            DasherID__c,
                            Store_ID__c,
                            Customer_Type__c
                    from Case
                    where Id =: caseId];
        Id supportRTId  = CDdSchemaUtils.CASE_RT.customerId();

        String flowType = '';
        if (c.Origin == 'API'){
            flowType = 'API';
        } else if (c.Origin == 'Chat'){
            flowType = 'Chat';
        } else if (c.Origin == 'Phone'){
            flowType = 'Phone';
        } else if (c.Origin == 'Web'){
            flowType = 'Web';
        }

        Case_Agent_Flow__c retVal = [Select Id,
                                            Listen_Subtitle__c,
                                            Listen_Body__c,
                                            Empathize_Subtitle__c,
                                            Empathize_Body__c,
                                            Resolve_Subtitle__c,
                                            Resolve_Body__c,
                                            Close_Subtitle__c,
                                            Close_Body__c
                                    from Case_Agent_Flow__c
                                    where Type__c = : flowType];

        String listenPrefill = '';
        // fill listen
        if ((c.Origin == 'Chat' || c.Origin == 'Web')
            && String.isNotBlank(c.Channel__c)
            && c.Channel__c.contains('Community')
            && c.Platform__c != 'Caviar'){
            listenPrefill = c.Pre_Chat_Category__c + ' - ' + c.Pre_Chat_Sub_Category__c;
        } else if ( c.Origin == 'Chat'
                    && String.isNotBlank(c.Chat_Issue__c)){
            listenPrefill = c.Chat_Issue__c + ' - ' + c.Chat_Issue_Details__c;
        } 

        if (String.isNotBlank(listenPrefill)){
            retVal.Listen_Body__c = retVal.Listen_Body__c.replace('{dynamic_issue_based_on_pre_chat}', listenPrefill);
            retVal.Listen_Body__c = retVal.Listen_Body__c.replace('{dynamic_description_provided_by_customer}', listenPrefill);
        }
        
        if ( c.Origin == 'API'){
            listenPrefill = c.Alert_Type__c;
        }
        if (String.isNotBlank(listenPrefill)){
            retVal.Listen_Body__c = retVal.Listen_Body__c.replace('{dynamic_name_of_API}', listenPrefill);
        }

        String kbURL = '<a href="';
        if (c.Customer_Type__c == 'Consumer'){
            kbURL += '/articles/en_US/Knowledge/Internal-Tools-Consumer-Issues-and-Use-Cases-Guide';
        
        } else if (c.Customer_Type__c == 'Dasher'){
            kbURL += '/articles/en_US/Knowledge/Internal-Tools-Dasher-Issues-and-Use-Cases-Reference-Guide';
        
        } else if (c.Customer_Type__c == 'Merchant'){
            kbURL += '/articles/en_US/Knowledge/Internal-Tools-Merchant-Issues-and-Use-Cases-Guide';
        
        }
        kbURL += '" target="_blank">KB</a>';
        if (String.isNotBlank(kbURL)){
            retVal.Resolve_Body__c = retVal.Resolve_Body__c.replace('{this_kb}', kbURL);
        }

        String dispatchLink = '<a href="' + Label.DdAgent_Dispatch_Link;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        Dispatch_Settings__c apiSettingInstance = Dispatch_Settings__c.getInstance();
        Boolean useUUID = (apiSettingInstance.Use_UUID__c != null 
                            && apiSettingInstance.Use_UUID__c == true) 
                            ? true : false; 
        if (String.isNotBlank(c.DeliveryUUID__c) && useUUID){
            dispatchLink += c.DeliveryUUID__c;
        } else if (c.DeliveryNo__c != null && c.DeliveryNo__c != 0){
            dispatchLink += String.valueOf(c.DeliveryNo__c);
        }
        dispatchLink += '" target="_blank">Dispatch Link</a>';
        retVal.Resolve_Body__c = retVal.Resolve_Body__c.replace('{Dispatch link}', dispatchLink);

        String dxDispatchLink = '<a href="' + Label.DdAgent_Dx_Dispatch_Link;
        if (c.DasherID__c != null && c.DasherID__c != 0){
            dxDispatchLink += c.DasherID__c;
        }
        dxDispatchLink += '" target="_blank">Dasher Support Link</a>';
        retVal.Resolve_Body__c = retVal.Resolve_Body__c.replace('{Dx Dispatch link}', dxDispatchLink);
        
        String mxPortalLink = '<a href="' + Label.DdAgent_Mx_Portal_Link;
        mxPortalLink += c.Store_ID__c;
        mxPortalLink += '" target="_blank">Merchant Portal Link</a>';
        if (String.isNotBlank(c.Store_ID__c)){
            retVal.Resolve_Body__c = retVal.Resolve_Body__c.replace('{Mx Portal link}', mxPortalLink);
        }

        return retVal;
    }
}