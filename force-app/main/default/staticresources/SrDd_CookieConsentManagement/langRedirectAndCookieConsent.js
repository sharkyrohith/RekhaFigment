
/**
 * @author Raju Lakshman
 * @date   Sept 2021
 * @decription BIZS-325 - GeoIp + Auto-Language redirect + Cassie Cookie Consent Management
 *             Note - helper methods are present in helper.js in the same static resource
 *             BIZS-631 - October 2021 - Added methods for Legal pages redirection
 *             BIZS-613 - October 2021 - Prevent Cookie consent banner from showing up in the privact policy pages.
 */

if (isProduction()) {
    loadScript('https://cscript-cdn-use.cassiecloud.com/loader.js',false,runCookieLogic);
} else {
    loadScript('https://cscript-cdn-use-uat.cassiecloud.com/loader.js',false,runCookieLogic);
}

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
    const consentCookie = getCookie('dd_non_essential_opt_in'); // Cookie set by Cassie which indicates Opt-In/Opt-out to Non-essential cookies

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
    if (!consentCookie) {
        const countryFromURL = getURLParam('ct'); // there is code below sets these two URL params if redirect is done. This avoids extra API call to GeoIp after redirect for cookie consent
        const divisionCode = getURLParam('dc');
        if (countryFromURL) {
            let geoIpResult = {country_code: countryFromURL};
            if (divisionCode)
                geoIpResult.subnational_division_code = divisionCode;
            processCookieConsent(geoIpResult);
        } else {
            actions.push('cookieConsent');
        }
    } else if (consentCookie === 'true') {
        loadGoogleAnalyticsAndGTM();
    }

    // Invoke the GeoIp Service
    if (actions.length > 0)
    	callGeoIpService(actions);
}

/**
   * @decription Calls the Geo IP service
   * @param   {String[]} actions - tells the code which actions are needed (redirect/cookieConsent).
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
                    } else {
                        loadGoogleAnalyticsAndGTM();
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
        let sandboxResult = {country_code: "nz"};
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
    let isRedirecting = '';

    if (isPrivacyPolicyPage()) {
        isRedirecting = actions.indexOf('redirectPP') !== -1 ? redirectLegalPage(geoIpResult,'privacy-policy') : 'No';
    } else if (isTermsAndConditionsPage()) {
        isRedirecting = actions.indexOf('redirectTNC') !== -1 ? redirectLegalPage(geoIpResult,'terms-and-conditions') : 'No';
    } else if (isIcaPage()) {
        isRedirecting = actions.indexOf('redirectICA') !== -1  ? redirectLegalPage(geoIpResult,'ica') : 'No';
    } else if (isTermsOfServicePage()) {
        isRedirecting = actions.indexOf('redirectTOS') !== -1 ? redirectLegalPage(geoIpResult,'terms-of-service') : 'No';
    } else if (isStoreFrontTermsOfServicePage()) {
        isRedirecting = actions.indexOf('redirectSFTOS') !== -1 ? redirectLegalPage(geoIpResult,'storefront-services-terms-of-service') : 'No';
    } else if (actions.indexOf('redirect') !== -1) {
        isRedirecting = redirectToUserLocal(geoIpResult);
    } else {
        isRedirecting = 'No';
    }

    // We want to process Cookie consent only after the redirection has taken place. So if the above method is going to redirect, then we dont need to execute anything else
    if (isRedirecting === 'No' && actions.indexOf('cookieConsent') !== -1)
        processCookieConsent(geoIpResult);
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

    let isRedirecting = 'No';
    const country  = geoIpResult.country_code;
    const divisionCode = geoIpResult.subnational_division_code;
    if (country !== undefined){
        let newLangCode = getNewLanguageCode(geoIpResult);

        const currLangCode = getCurrentLanguageCodeFromURL();
        if (currLangCode)
            document.cookie = "dd_help_iprgn=yes"; // Cookie which indicates the Language check logic has happened.

        let url = window.location.href;
        if (!isCommunityBuilder() && currLangCode && newLangCode && currLangCode !== newLangCode) {
            isRedirecting = 'Yes';
            // Add Country and State to the URL so that GeoIP callout does not need to be done again when the next page loads.
            let newURL = url.replace('language='+currLangCode,'language='+newLangCode);
            newURL = newURL + (newURL.indexOf('?') === -1 ? '?' : '&') + 'ct='+country+(divisionCode ? '&dc='+divisionCode : '');
            window.location.href = newURL;
        }
    }
    return isRedirecting;
}

/**
   * @decription Redirects user to the language specific site based on the GeoIp country/state
   * @param   {Object} geoIpResult - Has the return from the GeoIp service
   * @return  None
   */
function processCookieConsent(geoIpResult) {
    // BIZS-613 - Privacy policy page contains the Cookie consent legalese; so dont show cookie banner in privacy policy pages and load them
    // as is, i.e. essential mode if user is interacting with doordash for the first time / consent driven mode if user has interacted before.
    if (isPrivacyPolicyPage()) {
        return;
    }
    if (!geoIpResult) {
        loadGoogleAnalyticsAndGTM();
        return;
    }
    const GDPR_COUNTRIES = new Set([
        "ad","al","at","ax","ba","be","bg","by","ch","cz","de","dk","ee","es","fi","fo","fr","gb","gg","gi","gr","hr","hu","ie","im","is",
        "it","je","li","lt","lu","lv","mc","md","me","mk","mt","nl","no","pl","pt","ro","rs","ru","se","si","sj","sk","sm","ua","va"
    ]);
    const country  = geoIpResult.country_code;
    const divisionCode = geoIpResult.subnational_division_code;

    if (GDPR_COUNTRIES.has(country)) {
        const languageCode = getCassieLanguageCode();
        const cassieSettingsProd = {
            widgetProfileId: 4,
            languageCode: languageCode,
            licenseKey: "696A606A-E529-454E-B689-E784C5AC653B",
            region: "use",
            environment: "production"
        };
        const cassieSettingsSB = {
            widgetProfileId: 5,
            languageCode: languageCode,
            licenseKey: "B2F9FFCB-4E79-4F6A-BBFC-0152A700BDFE",
            region: "use",
            environment: "uat"
        };
        let cassieSettings = isProduction() ? cassieSettingsProd : cassieSettingsSB;
        try {
            // Launch Cassie Modal
            window.CassieWidgetLoader = new CassieWidgetLoaderModule(cassieSettings);
            // This event is fired by cassie after the user's consent has been registered and cassie drops all of its cookies.
            // One of the cookie dropped will be 'dd_non_essential_opt_in', with value 'true' = Opt In, 'false' = Opt out.
            document.addEventListener('CassieSubmittedConsent', function(e){
                if (getCookie('dd_non_essential_opt_in') === 'true') {
                    loadGoogleAnalyticsAndGTM();
                }
            });
        } catch (e) {
            console.log('Cassie Load error',e);
        }
    } else {
        loadGoogleAnalyticsAndGTM();
    }
}

/**
   * @decription Starts Google Analytics and Google Tag Manager
   * @param   None
   * @return  None
   */
 function loadGoogleAnalyticsAndGTM() {
    loadScript("https://www.google-analytics.com/analytics.js",true,initGoogleAnalytics);

    const website = getCurrentWebsite();
    if (website === 'Cx' || website === 'Dx' || website === 'Mx') {
        (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
            new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
            j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
            'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
            })(window,document,'script','dataLayer','GTM-T44F8F');
    }
}

/**
   * @decription Once GA js loads, init GA
   * @param   None
   * @return  None
   */
function initGoogleAnalytics() {
    const website = getCurrentWebsite();
    let gaId = '';
    switch (website) {
        case 'Hub':
            gaId = 'UA-158490366-1';
            break;
        case 'Cx':
            gaId = 'UA-123635444-1';
            break;
        case 'Dx':
            gaId = 'UA-123622275-1';
            break;
        case 'Mx':
            gaId = 'UA-123654562-1';
            break;
        default:
            break;
    }
    if (gaId) {
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', gaId);

        window.ga=window.ga||function(){(ga.q=ga.q||[]).push(arguments)};ga.l=+new Date;
        ga('create', gaId, 'auto');
        ga('send', 'pageview');
    }
}

/**
   * @decription Attach the script to the head element and call callbackFn method once the script loads
   * @param   {String} source
   *          {Boolean} isAsync - Load Script with async tag
   *          {Function} callbackFn - Script to call once the script is loaded
   * @return  None
   */
 function loadScript(source,isAsync,callbackFn) {
    let scrpt = document.createElement("script");
    scrpt.setAttribute("src", source);
    if (isAsync)
        scrpt.setAttribute("async","");
    let head = document.head;
    if (callbackFn)
        scrpt.addEventListener("load", callbackFn , false);
    head.insertBefore(scrpt, head.firstElementChild);
}

/**
   * @decription Translates Salesforce language codes to the standard format in cassie.
   * @param   None
   * @return  {String} - Language code which exists in Cassie
   */
function getCassieLanguageCode() {
    const sfLanguage = getCurrentLanguageCodeFromURL();
    let cassieLang = 'en-US';
    switch (sfLanguage) {
        case 'en_US':
            cassieLang = 'en-US';
            break;
        case 'en_AU':
            cassieLang = 'en-AU';
            break;
        case 'en_NZ':
            cassieLang = 'en-NZ';
            break;
        case 'fr':
        case 'fr_CA':
            cassieLang = 'fr-CA';
            break;
        case 'en_CA':
            cassieLang = 'en-CA';
            break;
        case 'es':
        case 'es_MX':
        case 'es_US':
            cassieLang = 'es-MX';
            break;
        case 'ja':
        case 'ja_JP':
            cassieLang = 'ja-JP';
            break;
        case 'de':
        case 'de_DE':
            cassieLang = 'de-DE';
            break;
        default:
            cassieLang = 'en-US';
            break;
    }
    return cassieLang;
}
