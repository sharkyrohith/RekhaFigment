
/**
 * @author Raju Lakshman
 * @date   Sept 2021
 * @decription BIZS-325 - GeoIp + Auto-Language redirect
 *             Note - helper methods are present in helper.js in the same static resource
 *              LDdRedirectOnIP component has been deprecated as of this user story, this JS replaces that code for sites which
 *              dont have cookie consent management yet.
 *             BIZS-631 - October 2021 - Added methods for Legal pages redirection
 *             BIZS-613 - October 2021 - Prevent Cookie consent banner from showing up in the privact policy pages.
 */

 runCookieLogic();

 /**
    * @decription Starts the whole logic workflow
    * @param   None
    * @return  None
    */
function runCookieLogic() {
    // Cookies which is set by our code once we do auto-redirect for language
    const privacyPolicyCookie = getCookie('dd_help_privacy-policy_viewed');
    const termsAndConditionsCookie = getCookie('dd_help_terms-and-conditions_viewed');
    const termsOfServiceCookie = getCookie('dd_help_terms-of-service_viewed');
    const storefrontTermsOfServiceCookie = getCookie('dd_help_storefront-services-terms-of-service_viewed');
    const icaServiceCookie = getCookie('dd_help_ica_viewed');
    const redirectCookie = getCookie('dd_help_iprgn');

    const actions = [];
    if (!privacyPolicyCookie && isPrivacyPolicyPage()) {
        actions.push('redirectPP');
    }
    if (!termsAndConditionsCookie && isTermsAndConditionsPage()) {
        actions.push('redirectTNC');
    }
    if (!termsOfServiceCookie && isTermsOfServicePage()) {
        actions.push('redirectTOS');
    }
    if (!storefrontTermsOfServiceCookie && isStoreFrontTermsOfServicePage()) {
        actions.push('redirectSFTOS');
    }
    if (!icaServiceCookie && isIcaPage()) {
        actions.push('redirectICA');
    }
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
    if (isPrivacyPolicyPage()) {
        if (actions.indexOf('redirectPP') !== -1) {
            redirectLegalPage(geoIpResult,'privacy-policy');
        }
    } else if (isTermsAndConditionsPage()) {
        if ( actions.indexOf('redirectTNC') !== -1 {
            redirectLegalPage(geoIpResult,'terms-and-conditions');
        }
    } else if (isIcaPage()) {
        if (actions.indexOf('redirectICA') !== -1) {
            redirectLegalPage(geoIpResult,'ica');
        }
    } else if (isTermsOfServicePage()) {
        if (actions.indexOf('redirectTOS') !== -1) {
            redirectLegalPage(geoIpResult,'terms-of-service');
        }
    } else if (isStoreFrontTermsOfServicePage()) {
        if (actions.indexOf('redirectSFTOS') !== -1) {
            redirectLegalPage(geoIpResult,'storefront-services-terms-of-service');
        }
    } else if (actions.indexOf('redirect') !== -1) {
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
        if (currLangCode)
            document.cookie = "dd_help_iprgn=yes"; // Cookie which indicates the Language check logic has happened.

        let url = window.location.href;
        if (!isCommunityBuilder() && currLangCode && newLangCode && currLangCode !== newLangCode) {
            window.location.href = url.replace('language='+currLangCode,'language='+newLangCode);
        }
    }
}