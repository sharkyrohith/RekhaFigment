({
    cloneObject : function(obj) {
        return $A.util.isUndefinedOrNull(obj) ? null : JSON.parse(JSON.stringify(obj));
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
    getVisualforceDomain: function() {
        const host = window.location.host;
        if (host === 'figment.lightning.force.com') {
            return 'figment--c.na90.visual.force.com';
        }

        return window.location.host.replace('.lightning.force.com','--c.visualforce.com');
    },
    getEnhancedVfDomain: function() {
        const host = window.location.host;
        if (host === 'figment.lightning.force.com') {
            return 'figment--c.vf.force.com';
        }

        return window.location.host.replace('.sandbox.lightning.force.com','--c.sandbox.vf.force.com');
    },
    processMessage: function(component,message) {
        const messageType = message.messageType;
        const payload = message.payload;
        /*const caseRecFromMsg = payload.caseId;
        const recId = component.get("v.recordId");
        if (caseRecFromMsg !== recId) {
            console.log('[LDdSendbirdChatVfUI] Ignoring Msg',messageType,`Component Rec Id: ${recId}`,`Message Rec Id: ${caseRecFromMsg}`);
            return;
        }*/
        console.log('[LDdSendbirdChatVfUI] Received message',messageType,this.cloneObject(payload));
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
        if (workspaceAPI) {
            let props = {
                tabId,
                highlighted
            };
            if (highlighted) {
                props.options =  {
                    pulse: true,
                    state: "warning"
                };
            }
            workspaceAPI.setTabHighlighted(props);
        }
    },
    closeTab : function(component, tabId) {
        const workspaceAPI = component.find("workspace");
        if(tabId && workspaceAPI) {
            setTimeout(function () {
                workspaceAPI.closeTab({tabId : tabId});
            }, 5000);
        }
    }
})