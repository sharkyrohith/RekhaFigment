({
    doInit : function(component, event, helper) {
        // build the visualforce page url
        var formstackURL = component.get("v.formstackURL");
        var formID = component.get("v.formID");
        var viewKey = component.get("v.viewKey");
        var communityURL = component.get("v.communityURL");
        var url =  communityURL + "/PDdFormstackPrefill";
        url += "?form=" + formID;
        url += "&viewkey=" + viewKey;
        url += location.search.replace('?','&');
        url += "&formstackURL=" + formstackURL;
        component.set("v.finalURL", url);
    }
})