
/**
 * @author Raju Lakshman
 * @date   October 2021
 * @decription BIZS-749 - Copy of the langRedirect.js minus the legal pages redirect.
 *             Keeping both JS in the static resource just in case we need to flip between the two.
 */

 runCookieLogic();

 /**
    * @decription Starts the whole logic workflow
    * @param   None
    * @return  None
    */
function runCookieLogic() {
    // Cookies which is set by our code once we do auto-redirect for language
    const redirectCookie = getCookie('dd_help_iprgn');

    const actions = [];
    if (!redirectCookie) {
        actions.push('redirect');
    }

    // Invoke the GeoIp Service
    if (actions.length > 0)
        callGeoIpService(actions);
}


/**
* @decription Calls the Geo IP service
* @param   None
* @return  None
*/
function callGeoIpService(actions) {
    const deflt = {country_code: "us"};
    if (isProduction()) { // Call the GeoIp Service
        const regionURL = 'https://api.doordash.com/v1/country_code_for_ip/';
        const xhttp_GEO = new XMLHttpRequest();
        xhttp_GEO.open('GET', regionURL);
        try {
            xhttp_GEO.send();
            xhttp_GEO.onreadystatechange = function() {
                if(xhttp_GEO.readyState == 4 && xhttp_GEO.status === 200) {
                    const geoIpResult = JSON.parse(xhttp_GEO.responseText);
                    if (geoIpResult) {
                        processGeoIpLogic(geoIpResult,actions);
                    }
                }
            }
        } catch(err){
            console.log('Call GeoIP Service Error',err);
            processGeoIpLogic(deflt,actions);
        }
    } else {
        // IP Region API has a CORS policy which restricts to calls only from doordash.com source.
        // This is a workaround for sandboxes, while we look at updating the CORS policy.
        let sandboxResult = {country_code: "us"};
        processGeoIpLogic(sandboxResult,actions);
    }
}

/**
 * @decription Processes the result of the GeoIp Service
 * @param   {Object} geoIpResult - Has the return from the GeoIp service
 *          {String[]} actions -  tells the code which actions are needed (redirect/cookieConsent).
 * @return  None
 */

function processGeoIpLogic(geoIpResult,actions) {
    if (actions.indexOf('redirect') !== -1) {
        redirectToUserLocal(geoIpResult);
    }
}

/**
* @decription Redirects user to the language specific site based on the GeoIp country/state
* @param   {Object} geoIpResult - Has the return from the GeoIp service
* @return  None
*/
function redirectToUserLocal(geoIpResult) {
    if (!geoIpResult) {
        return;
    }
    const country  = geoIpResult.country_code;
    const divisionCode = geoIpResult.subnational_division_code;
    if (country !== undefined){
        let newLangCode = getNewLanguageCode(geoIpResult);

        const currLangCode = getCurrentLanguageCodeFromURL();
        if (currLangCode) {
            document.cookie = "dd_help_iprgn=yes"; // Cookie which indicates the Language check logic has happened.
        }

        let url = window.location.href;
        if (!isCommunityBuilder() && currLangCode && newLangCode && currLangCode !== newLangCode) {
            window.location.href = url.replace('language='+currLangCode,'language='+newLangCode);
        }
    }
}