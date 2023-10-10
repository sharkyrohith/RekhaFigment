({
    init: function(component, event, helper) {
        helper.init(component);
    },
    handleStoreSearch: function (component, event, helper) {
        var isEnterKey = event.keyCode === 13;
        var searchStoreId = component.find('enter-search').get('v.value');
        if (isEnterKey) {
            component.set('v.isSearching', true);
            helper.handleGetStoreDetail(component, searchStoreId, function(result){
                component.set('v.isSearching', false);
                console.log('search result ' + result);
            }, function(error){
                component.set('v.isSearching', false);
                console.log('search error ' + error);
            });            
        }
    },
    handleStoreIdChange: function (component, event, helper) {
        helper.fireNimdaSyncEvent(component, component.get("v.STEP_SEARCH_STORE"), component.get("v.storeId"));
    }
})