({
	doInit : function(component, event, helper) {
		var lang = helper.findGetParameter("language");
        if (lang != null){
            var langParam = lang.replace("_", "-");
            langParam = langParam.toLowerCase();
            var posEnd = location.pathname.length;
            var posRoot = location.pathname.indexOf('-');
            var rootURL = location.pathname;
            var urlLang = "en_US";
            if (posRoot != -1){
                rootURL = location.pathname.substring(0, posRoot);
               	urlLang = location.pathname.substring(posRoot+1, posEnd);
            }
            if (lang != "en_US"){
                if (langParam != urlLang){
                    var url = rootURL + "-" + langParam + location.search;
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": url
                    });
                    urlEvent.fire();
                }
            } else {
                if (location.pathname != rootURL){
                 	var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": rootURL + location.search
                    });
                    urlEvent.fire();  
                }
            }
    	}
	}
})