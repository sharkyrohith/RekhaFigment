({
    redirectToUserLocal : function(component, event, locale_res, helper) {
        var CC = "";
        var country  = locale_res.country_code;
        var divisionCode = locale_res.subnational_division_code; 
        if(country !== undefined){ 
            switch(country) {
                case 'au':
                    CC = 'en_AU';
                    break;
                case 'ca':
                    if (divisionCode == 'qc'){
                        CC = 'fr_CA';
                    } else {
                        CC = 'en_CA';
                    }
                    break;
                case 'pr':
                    CC = 'es';
                    break;
                case 'jp':
                    CC = 'ja';
                    break;
            } 

            var url = window.location.href;
            var languageIndex = url.indexOf("language=");
            if (languageIndex != -1 && CC != ""){
                var languageIndexEnd = url.indexOf("&",languageIndex);
                languageIndexEnd = languageIndexEnd == -1 ? url.indexOf("?",languageIndex) : languageIndexEnd;
                languageIndexEnd = languageIndexEnd == -1 ? url.indexOf("%",languageIndex) : languageIndexEnd;
                var noOfChars = languageIndexEnd == -1 ? url.length-languageIndex : languageIndexEnd-languageIndex;
                var language = url.substr(languageIndex+9,noOfChars-9);
                helper.setRegionCookie();
                if(language !== CC){         
                    window.location.href = url.replace('language='+language,'language='+CC);
                }
            }
        }
    },
    getRegionCookie : function () {
    	var cookiename = 'iprgn';
     	var cookiestring = RegExp(""+cookiename+"[^;]+").exec(document.cookie);
        return decodeURIComponent(!!cookiestring ? cookiestring.toString().replace(/^[^=]+./,"") : "");
    },
    setRegionCookie : function () {
  		document.cookie = "iprgn=yes";
	},
    retrieveCountry : function(component, event, helper) {
        var client_IP;
        var deflt = {country_code: "us"};
        var regionURL = $A.get("$Label.c.DDCommunity_IP_Region_URL");
        var xhttp_GEO = new XMLHttpRequest();
        xhttp_GEO.open('GET', regionURL);
        try {
            xhttp_GEO.send();
            xhttp_GEO.onreadystatechange = function() {
                if(xhttp_GEO.readyState == 4 && xhttp_GEO.status === 200) {
                    var country = JSON.parse(xhttp_GEO.responseText);
                    if (country){
                    	helper.redirectToUserLocal(component, event, country, helper);
                	}
                } 
            }
        } catch(err){
            console.log(err);
            helper.redirectToUserLocal(component, event, deflt, helper);
        }
    }

  })