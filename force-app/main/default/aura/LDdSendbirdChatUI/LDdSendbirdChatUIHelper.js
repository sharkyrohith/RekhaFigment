/**
     * LDdSendbirdChatUIHelper
     *
     * @author     Chris
     * @date  2021-03-22
     * @decription  helper of LDdSendbirdChatUI aura component
     */
    ({
    /**
     * Handles a "ping" message from the Lightning container. Sends a response message
     * to the container which lets the container know that it can begin sending other messages.
     */
    handlePing: function (component) {
        this._sendMessage(component, "ping");
    },

    handleNonCacheableRequest: function (component,helper,methodName,params) {
        helper._handleRequest(component,helper,'processSendbirdActionNonCacheableAura',methodName,params)
        .then((result) => {
            this.sendSuccessMessage(component, methodName, result);
        })
        .catch((error) => {
            console.log('[LDdSendbirdChatUI] Apex Controller Error',methodName,helper.cloneObject(error));
            this.sendErrorMessage(component,methodName, error);
        });
    },

    handleCacheableRequest: function (component,helper,methodName,params) {
        helper._handleRequest(component,helper,'processSendbirdActionCacheableAura',methodName,params)
        .then((result) => {
            this.sendSuccessMessage(component, methodName, result);
        })
        .catch((error) => {
            console.log('[LDdSendbirdChatUI] Apex Controller Error',methodName,error);
            this.sendErrorMessage(component,methodName, error);
        });
    },

    _handleRequest: function (component,helper,apexMethodName,methodName,params) {
        if (!params) {
            const caseRec = component.get("v.simpleRecord");
            const userId = component.get("v.agentUserId");
            const contactFirstName = caseRec.Contact ? encodeURI(caseRec.Contact.FirstName) : "";
            switch (methodName) {
                case 'chat_info':
                    params = {
                        'userId' : userId,
                        'sendbirdChannelUrl' : caseRec.ChatKey__c
                    }
                    break;
                case 'should_connect':
                    params = {
                        'caseId' : caseRec.Id,
                        'agentUserId' : userId
                    };
                    break;
                case 'end_chat':
                    params = {
                        'channelUrl' : caseRec.ChatKey__c
                    };
                    break;
                default:
                    params = {};
                    break;
            }
        }

        return new Promise((resolve, reject) => {
            const action = component.get("c." + apexMethodName);
            console.log(`[LDdSendbirdChatUI] Calling apex controller ${apexMethodName}`,methodName, params)
            action.setParams({
                action: methodName,
                payload: params
            });
            action.setCallback(this, (response) => {
                const state = response.getState();
                console.log('state ',state);
                console.log('response ',response);
                if (state === "SUCCESS") {
                    console.log('retVal ',response.getReturnValue());
                    return resolve(response.getReturnValue());
                } else {
                   console.log('error ',response.getError());
                    return reject(response.getError()[0]);
                }
            });
            $A.enqueueAction(action);
        });
    },

    /**
     * Helper method to send an error message to the Lightning container.
     * @param {string} messageType - The type of message being sent
     * @param {object} error - Error object
     */
    sendErrorMessage: function (component, messageType, error) {
        this._sendMessage(component, messageType, {
            status: "error",
            message: error.message || "Something went wrong",
        });
    },

    /**
     * Helper method to send a success message to the Lightning container.
     * @param {string} messageType - The type of message being sent
     * @data {object} data - Data to be sent to the Lightning container
     */
    sendSuccessMessage: function (component, messageType, result) {
        this._sendMessage(component, messageType, {
            status: "success",
            data: result,
        }); 
    },

    /**
     * Sends a message to the lightning container
     * @param {string} type - Message type
     * @param {string} payload - Message payload
     */
    _sendMessage: function (component, type, payload) {
        console.log('[LDdSendbirdChatUI] Sending message to SendbirdChatUI',type,payload);
        component.find("SendbirdChatUI").message({ type, payload });
    },

    cloneObject: function(obj) {
        return JSON.parse(JSON.stringify(obj));
    },

    getEnclosingTabId : function(component, event, helper) {
        const workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId()
            .then((tabId) => component.set("v.enclosingTabId",tabId))
            .catch((error) => {
                console.log('[LDdSendbirdChatVfUI] WorkspaceAPI getEnclosingTabId error',this.cloneObject(error));
                component.set("v.enclosingTabId",'unavailable')
            });
    },
    processMessage: function(component,messageType,payload) {
        /*const caseRecFromMsg = payload.caseId;
        const recId = component.get("v.recordId");
        if (caseRecFromMsg !== recId) {
            console.log('[LDdSendbirdChatUI] Ignoring Msg',messageType,`Component Rec Id: ${recId}`,`Message Rec Id: ${caseRecFromMsg}`);
            return;
        }*/
        console.log('[LDdSendbirdChatUI] Received message',messageType,payload);
        switch (messageType) {
            case 'unread_message_count_changed':
                if (payload.unreadMessageCount > 0) {
                    this.setTabHighlighted(component,payload.tabId,true);
                }
                break;
            case 'close_tab':
                this.closeTab(component,payload.tabId);
                break;
            default:
                break;
        }
    },
    setTabHighlighted : function(component, tabId, highlighted) {
        const workspaceAPI = component.find("workspace");
        let props = {
            tabId,
            highlighted
        };
        if (highlighted) {
            props.options =  {
                pulse: true,
                state: "success"
            };
        }
        workspaceAPI.setTabHighlighted(props);
    },
    closeTab : function(component, tabId) {
        const workspaceAPI = component.find("workspace");
        if(tabId) {
            setTimeout(function () {
                workspaceAPI.closeTab({tabId : tabId});
            }, 5000);
        }
    }
});