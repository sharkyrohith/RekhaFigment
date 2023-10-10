
/**
 * @author Raju Lakshman
 * @date   Sept 2021
 * @decription BIZS-325 - Common/Helper methods for the Language Redirect/Cassie cookie consent module.
 *             BIZS-631 - October 2021 - Added methods for Legal pages redirection
 *             BIZS-613 - October 2021 - Prevent Cookie consent banner from showing up in the privact policy pages.
 */

/**
   * @decription Gets Language code from URL
   * @param   None
   * @return  {String} - Language code
   */
function getCurrentLanguageCodeFromURL() {
    return getURLParam('language') || 'en_US';
}

/**
 * @decription Gets Language code from URL
 * @param   None
 * @return  {String} - Language code derived from custom lang Param, which might be the IETF format (ex: en-US) rest of doordash uses
 */
function getSourceLocaleFromURL() {
    const customLang = getURLParam('lang');
    let sfLang = '';
    if (customLang) {
        switch (customLang) {
            case 'en-US':
                sfLang = 'en_US';
                break;
            case 'en-AU':
                sfLang = 'en_AU';
                break;
            case 'en-NZ':
                sfLang = 'en_NZ';
                break;
            case 'fr-CA':
                sfLang = 'fr_CA';
                break;
            case 'en-CA':
                sfLang = 'en_US';
                break;
            case 'es-MX':
            case 'es-US':
                sfLang = 'es';
                break;
            case 'ja-JP':
                sfLang = 'ja';
                break;
            case 'de-DE':
                sfLang = 'de';
                break;
            default:
                sfLang = 'en_US';
                break;
        }
    }
    return sfLang;
}
/**
   * @decription Gets value for a cookie
   * @param   {String} - Cookie Name
   * @return  {String} - Cookie Value, "" if cookie is not present.
   */
function getCookie(cookieName) {
    var cookieString = RegExp(""+cookieName+"[^;]+").exec(document.cookie);
    return decodeURIComponent(!!cookieString ? cookieString.toString().replace(/^[^=]+./,"") : "");
}

/**
   * @decription Function to know if we are on the prod help sites or sandbox
   * @param   None
   * @return  {Boolean} - true if prod
   */
function isProduction() {
    return  window.location.href.indexOf('doordash.com') !== -1 ||
            window.location.href.indexOf('trycaviar.com') !== -1;
}

/**
   * @decription Checks if Community builder
   * @param   None
   * @return  {Boolean} - true if community builder
   */
function isCommunityBuilder() {
    return window.location.href.indexOf('sfsites/picasso/core/config') !== -1;
}

/**
   * @decription Parses URL for params
   * @param   {String} param - Gets parameter from URL to extract
   * @return  {String} - URL Parameter value
   */
function getURLParam(param) {
    const queryString = window.location.search;
    if (!queryString)
        return '';
    const urlParams = new URLSearchParams(queryString);
    return urlParams.get(param);
}

/**
   * @decription Checks URL to get current website
   * @param   None
   * @return  {String} - Current Website
   */
 function getCurrentWebsite() {
    const url = window.location.href;
    const urlParams = url.split("/");
    let website = 'unknown';
    if (!urlParams || urlParams.length < 4)
        return website;

    switch (urlParams[3]) {
        case 'consumers':
            website = 'Cx';
            break;
        case 'merchants':
            website = 'Mx';
            break;
        case 'dashers':
            website = 'Dx';
            break;
        case 'help':
        case 's':
            website = url.indexOf('trycaviar.com') !== -1 ? 'CaviarHub' : 'Hub';
            break;
        case 'work':
            website = 'ddfw';
            break;
        case 'caviarhelphub':
            website = 'CaviarHub';
            break;
        case 'diners':
            website = 'CaviarDiners';
            break;
        case 'restaurants':
            website = 'CaviarRestaurants';
            break;
        case 'caviarforcompanies':
            website = 'CaviarCompanies';
            break;
    }
    return website;
}

/**
 * @decription BIZS-613 / BIZS-631 - Checks if the page is one that displays Privacy/Cookie policy to users
 * @param   None
 * @return  {Boolean}
 */
function isPrivacyPolicyPage() {
    return (window.location.href.indexOf('/s/privacy-policy') !== -1);
}

/**
 * @decription BIZS-631 - Checks if the page is one that displays Terms and Conditions to Cx users
 * @param   None
 * @return  {Boolean}
 */
function isTermsAndConditionsPage() {
    return (window.location.href.indexOf('/s/terms-and-conditions') !== -1);
}

/**
 * @decription BIZS-631 - Checks if the page is one that displays Terms of Service to Mx users
 * @param   None
 * @return  {Boolean}
 */
function isTermsOfServicePage() {
    return (window.location.href.indexOf('/s/terms-of-service') !== -1);
}

/**
 * @decription BIZS-631 - Checks if the page is one that displays Storefront Terms of Service to Mx users
 * @param   None
 * @return  {Boolean}
 */
function isStoreFrontTermsOfServicePage() {
    return (window.location.href.indexOf('/s/storefront-services-terms-of-service') !== -1);
}

/**
 * @decription BIZS-631 - Checks if the page is one that displays Independent Contractor Agreement to Dx users
 * @param   None
 * @return  {Boolean}
 */
function isIcaPage() {
    return (window.location.href.indexOf('dashers/s/ica') !== -1);
}


/**
 * @decription BIZS-631 - Checks if the page is any one of the above legal pages
 * @param   None
 * @return  {Boolean}
 */
function isLegalPage() {
    return isPrivacyPolicyPage() || isTermsAndConditionsPage() || isStoreFrontTermsOfServicePage() || isIcaPage() || isTermsOfServicePage();
}


/**
 * @decription BIZS-631 - Returns language based on custom 'lang' param in url or users's geoip
 *             BIZS-1099 - May 2022 - Added calledFrom, Modifed to get country,divisionCode values based on old and new geoIpResult,
 * @param   {Object} geoIpResult - Has the return from the GeoIp service
 * @return  {String}
 */
 function getNewLanguageCode(geoIpResult,calledFrom = 'V2') {
    const sourceLocale = getSourceLocaleFromURL();
    if (sourceLocale) {
        return sourceLocale;
    }
    const country = calledFrom ==='V2' ? geoIpResult.country_code : geoIpResult.country;
    const divisionCode = calledFrom ==='V2' ? geoIpResult.subnational_division_code : geoIpResult.least_specific_subdivision;
    let newLangCode = 'en_US';
    if (country) {
        switch (country) {
            case 'au':
            case 'AU':
                newLangCode = 'en_AU';
                break;
            case 'nz':
            case 'NZ':
                newLangCode = 'en_NZ';
                break;
            case 'ca':
            case 'CA':
                newLangCode = (divisionCode === 'qc' || divisionCode === 'QC') ? 'fr_CA' : 'en_CA';
                break;
            case 'pr':
            case 'PR':
                newLangCode = 'es';
                break;
            case 'jp':
            case 'JP':
                newLangCode = 'ja';
                break;
            case 'de':
            case 'DE':
                newLangCode = 'de';
                break;
        }
    }
    return newLangCode;
}

/**
 * @decription BIZS-631 - If one of the legal pages, then ensure that the correct legal page is displayed based  on user's country/language
 * @param   {Object} geoIpResult - Has the return from the GeoIp service
 * @return  {String} 'Yes' if redirection will take place, 'No' if not
 */
 function redirectLegalPage(geoIpResult,siteName) {
    const url = window.location.href;
    const urlRoot = url.substring(0,url.indexOf(siteName));
    const currentUrlTrail = url.substring(url.indexOf(siteName));
    const currentPage = currentUrlTrail.substring(0,siteName.length+3);
    const currentLangCode = getCurrentLanguageCodeFromURL();

    const country  = geoIpResult.country_code;
    const divisionCode = geoIpResult.subnational_division_code;

    let newPage = siteName;
    if (country) {
        switch (country) {
            case 'au':
            case 'nz':
            case 'ca':
            case 'mx':
            case 'jp':
            case 'de':
                newPage += '-' + country;
                break;
            default:
                newPage += isStoreFrontTermsOfServicePage() ? '' : '-us';
                break;
        }
    } else {
        newPage += isStoreFrontTermsOfServicePage() ? '' : '-us';
    }

    const newLangCode = getNewLanguageCode(geoIpResult) || 'en_US';

    let isRedirecting = 'No';
    document.cookie = `dd_help_${siteName}_viewed=yes`; // Cookie which indicates the routing check logic has happened.
    if (currentPage !== newPage || currentLangCode !== newLangCode) {
        isRedirecting = 'Yes';
        const newUrl = urlRoot + newPage + '?language=' + newLangCode + '&ct=' + country + (divisionCode ? '&dc='+divisionCode : '');
        window.location.href = newUrl;
    }

    return isRedirecting;
}
