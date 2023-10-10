window._snapinsSnippetSettingsFile = (function() {

    
    embedded_svc.addEventHandler("onChatEndedByChasitor", function(data) {
        var chatKey =  data.liveAgentSessionKey;
        redirectToPostchat("https://help.doordash.com/postchat?chatKey=" + chatKey);
    });
    
    embedded_svc.addEventHandler("onChatEndedByAgent", function(data) {
        var chatKey =  data.liveAgentSessionKey;
        redirectToPostchat("https://help.doordash.com/postchat?chatKey=" + chatKey);
    });

    function redirectToPostchat(url){
        var client_IP;
        var deflt = {country_code: "us"};
        var regionURL = "https://api.doordash.com/v1/country_code_for_ip/";
        var xhttp_GEO = new XMLHttpRequest();
        xhttp_GEO.open('GET', regionURL);
        try {
            xhttp_GEO.send();
            xhttp_GEO.onreadystatechange = function() {
                if(xhttp_GEO.readyState == 4 && xhttp_GEO.status === 200) {
                    var country = JSON.parse(xhttp_GEO.responseText);
                    if (country.subnational_division_code === "ca"){
                        //window.open(url);
                        openWindowWithLink(url);
                    }
                } 
            }
        } catch(err){
            console.log(err);
        }
    }
    
    function openWindowWithLink(url){
    	var link = document.createElement("a");   
        link.target = "_blank"; 
        link.href = url; 
        document.body.appendChild(link);  
        setTimeout(function() { 
        	link.click();  
            document.body.removeChild(link);  
        }, 500); 
    }
})();