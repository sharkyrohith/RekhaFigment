({
    doInit : function(component, event, helper) {
        if (window.location.href.includes('doordash.com')){
            var ipCookie = helper.getRegionCookie();
      		if(ipCookie === undefined || ipCookie === ''){
                helper.retrieveCountry(component, event, helper);
                
            }
        }
    }
})