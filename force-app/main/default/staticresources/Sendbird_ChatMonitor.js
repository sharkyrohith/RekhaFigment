// Event Handler that will send message on tab change to sendbird
var sendTabChangedToSendbirdTabEventListener = function (result) {
    if (!(window && window.frames && window.frames.parent && window.frames.parent.length)) {
        console.log('Missing window frame parents or length is 0. Returning.')
        return
    }
    for (var i = 0; i < window.frames.parent.length; i++) {
        try {
            if (typeof window.frames.parent[i] == 'object' &&
                typeof window.frames.parent[i].hasOwnProperty == 'function' &&
                // Ensure this is only sent to components that have the sendbird channel url property.
                window.frames.parent[i].hasOwnProperty('sendbirdChannelUrl')) {
                window.frames.parent[i].postMessage({
                    'type': 'active_tab_changed',
                    payload: {'focusedTabId': result.id}
                })
            }
        } catch (e) {
            // We will ignore this. It is caused as the iframe is in a different origin, so would not be the one that we want.
        }
    }
}
if (typeof (sforce && sforce.console && sforce.console.onFocusedPrimaryTab) == 'function') {
    sforce.console.onFocusedPrimaryTab(sendTabChangedToSendbirdTabEventListener)
}
