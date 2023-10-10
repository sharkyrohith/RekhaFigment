({
    /**
     * Callback for when an error is encountered.
     */
    handleError: function (component, event, helper) {
        const error = event.getParams();
        console.log('[LDdSendbirdChat] Received error',helper.cloneObject(error));
    },

    /**
     * Handler for incoming messages from the Lightning container.
     */
    handleMessage: function (component, event, helper) {
        const message = event.getParams().payload;
        console.log(`[LDdSendbirdChat] Received message - ${message.type}`,helper.cloneObject(message));
        switch (message.type) {
            case 'ping':
                helper.handlePing(component);
                break;
            case 'unread_message_count_changed': // Add all workspace api handled types heree
            case 'close_tab':
                helper.processMessage(component,message.type,message.payload)
                break;
            case 'transfer_chat': // Add all non cacheable requests types (things which do DML in the apex controller) here
                helper.handleNonCacheableRequest(component,helper,message.type,message.payload);
                break;
            default:
                helper.handleCacheableRequest(component,helper,message.type,message.payload);
                break;
        }
    },

    /**
     * Callback for when the Aura component loads.
     */
    doInit: function (component, event, helper) {
        component.set("v.agentUserId", $A.get("$SObjectType.CurrentUser.Id"));
        helper.getEnclosingTabId(component);
    },

    handleRecordChanged: function (component, event, helper) {
        switch(event.getParams().changeType) {
            case "ERROR":
                break;
            case "LOADED":
                const caseRec = component.get("v.simpleRecord");
                const userId = component.get("v.agentUserId");
                const tabId = component.get("v.enclosingTabId");
                const contactFirstName = caseRec.Contact ? encodeURI(caseRec.Contact.FirstName) : "";
                component.set("v.urlParams",
                    `tabId=${tabId}&caseId=${caseRec.Id}&agentUserId=${userId}&sendbirdChannelUrl=${caseRec.ChatKey__c}&Contact_FirstName=${contactFirstName}&contactId=${caseRec.ContactId}&classic=false`
                )
                setTimeout(function () {
                    helper.handlePing(component);
                }, 1000);
                break;
            case "REMOVED":
                break;
            case "CHANGED":
                break;
        }
    },
    onTabFocused : function(component, event, helper) {
        const focusedTabId = event.getParam('currentTabId');
        const tabId = component.get("v.enclosingTabId");
        if (focusedTabId !== tabId) {
            console.log('[LDdSendbirdChatVfUI] Ignoring onTabFocussed',focusedTabId,tabId);
            return;
        }
        const workspaceAPI = component.find("workspace");
        workspaceAPI.getTabInfo({
            tabId : focusedTabId
        }).then((response) => {
            if (response.highlighted) {
                helper.setTabHighlighted(component,tabId,false);
            }
        });
    }
});