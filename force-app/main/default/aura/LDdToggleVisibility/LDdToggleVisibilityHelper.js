({
    shouldConnectToChat: function (component) {
        if(!component.get('v.hideSendbirdUI')) {
            return;
        }
        const caseRecord = component.get('v.caseRecord');
        const agentUserId = component.get('v.agentUserId');
        var visibilityEvent = component.getEvent('handleVisibilityEvent');
        if (!$A.util.isEmpty(caseRecord)) {
            if (!(caseRecord.Status != this.constants.CASE_STATUS_SOLVED
                && caseRecord.Status != this.constants.CASE_STATUS_CLOSED
                && caseRecord.OwnerId == agentUserId
                && this.isSendbirdCase(caseRecord.Origin, caseRecord.Channel__c, caseRecord.RecordType.DeveloperName))) {
                visibilityEvent.setParams({ 'visibility': 'hide', 'region': 'sidebarLeft' });
                visibilityEvent.fire();
            }
            else {
                visibilityEvent.setParams({ 'visibility': 'show', 'region': 'sidebarLeft' });
                visibilityEvent.fire();
            }
        }
        else {
            console.log('error ', component.get('v.recordError'));
        }
    },

    isSendbirdCase: function (origin, channel, recordTypeName) {
        return !$A.util.isEmpty(origin) && !$A.util.isEmpty(channel)
            && channel.toLowerCase() === this.constants.CASE_CHANNEL_SENDBIRD_LOWERCASE
            && origin.toLowerCase() === this.constants.CASE_ORIGIN_CHAT_LOWERCASE
            && recordTypeName === this.constants.CASE_RECORDTYPE_NAME_CUSTOMER;
    },

    constants: {
        CASE_STATUS_SOLVED: 'Solved',
        CASE_STATUS_CLOSED: 'Closed',
        CASE_CHANNEL_SENDBIRD_LOWERCASE: 'doordash app - sendbird',
        CASE_RECORDTYPE_NAME_CUSTOMER: 'Customer', //Label is Support, API name is Customer
        CASE_ORIGIN_CHAT_LOWERCASE: 'chat'
    }
})