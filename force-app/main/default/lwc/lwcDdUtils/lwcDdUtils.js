/**
 * @author Raju Lakshman
 * @date    Sept 16, 2021
 * @decription Useful Javascript functions to import into your LWC component
 */

/**
 * Reduces one or more LDS errors into a string[] of error messages. Copied from Salesforce LWC recipes, upated to do better API DML error parsing.
 * @param {FetchResponse|FetchResponse[]} errors
 * @return {String[]} Error messages
 */
 export function reduceErrors(errors) {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }

    return (
        errors
        // Remove null/undefined items
        .filter((error) => !!error)
        // Extract an error message
        .map((error) => {
            // UI API read errors
            if (Array.isArray(error.body)) {
                return error.body.map((e) => e.message);
            }
            // UI API DML, Apex and network errors
            else if (error.body && typeof error.body.message === 'string') {
                const errs = [error.body.message];
                if (error.body.output && error.body.output.errors) {
                    for (let e of error.body.output.errors) {
                        errs.push(parseUiApiDMLError(e));
                    }
                }
                if (error.body.output && error.body.output.fieldErrors) {
                    for (let fieldError in error.body.output.fieldErrors) {
                        for (let e of error.body.output.fieldErrors[fieldError]) {
                            errs.push(parseUiApiDMLError(e));
                        }
                    }
                }
                return errs;
            }
            // JS errors
            else if (typeof error.message === 'string') {
                return error.message;
            }
            // Unknown error shape so try HTTP status text
            return error.statusText;
        })
        // Flatten
        .reduce((prev, curr) => prev.concat(curr), [])
        // Remove empty strings
        .filter((message) => !!message)
    );
}

/**
* Reads DML error (validation rule etc) and returns formatted string
* @param {Error} error
* @return {String} formatted error
*/
function parseUiApiDMLError(error) {
    return (error.fieldLabel ? error.fieldLabel + ' : ' : '') + error.message;
}

/**
* Method to give if passed value is undefined or null (truthy/falsey JS treats '',0 etc in same category, not using that)
* @param {Object} val
* @return {Boolean}
*/
export function isUndefinedOrNull(val) {
    return val === undefined || val === null;
}

/**
* Method to give if passed string is actually a string and is not blank (truthy/falsey JS treats '',0, etc in same category, not using that)
* @param {String} val
* @return {Boolean}
*/
export function stringIsNotBlank(val) {
    return !stringIsBlank(val) && typeof val === 'string';
}

/**
* Method to give if passed string is actually a string and blank
* @param {String} val
* @return {Boolean}
*/
export function stringIsBlank(val) {
    return (!val || val.length === 0);
}

/**
* Method to give if val is undefined/null or is acutally an array and has no items
* @param {Object[]} val
* @return {Boolean}
*/
export function arrayIsEmpty(val) {
    return isUndefinedOrNull(val) || (Array.isArray(val) && val.length === 0);
}

/**
* IN the UI for dates, you would get the 'milliseconds after Jan 1, 1970' number. this converts that number to a readable string.
* @param {Integer/Long} epochTime
*                {Boolean} toUTC (to convert to UTC/GMT)
* @return {String} Date format of epochTime
*/
export function epochToDate(epochTime, toUTC) {
    if (!epochTime) {
        return '-';
    }

    let epochDate, currDate;
    if (toUTC) {
        epochDate = new Date(epochTime);
        currDate = new Date(epochDate.getTime() + epochDate.getTimezoneOffset() * 60000);
    } else {
        currDate = new Date(epochTime);
    }

    const day = currDate.toLocaleString('en-us', {day: 'numeric'});
    const year = currDate.toLocaleString('en-us', {year: 'numeric'});
    const month = currDate.toLocaleString('en-us', {month: 'short'});

    const datePart = month + ' ' + day + ', ' + year;

    return datePart;
}

/**
* IN the UI for dates, you would get the 'milliseconds after Jan 1, 1970' number. this converts that number to a readable string.
* @param {Integer/Long} epochTime
*                {Boolean} toUTC (to convert to UTC/GMT)
* @return {String} Date-Time format of epochTime
*/
export function epochToDateTime(epochTime, toUTC) {
    if (!epochTime) {
        return '-';
    }

    let epochDate, currDate;
    if (toUTC) {
        epochDate = new Date(epochTime);
        currDate = new Date(epochDate.getTime() + epochDate.getTimezoneOffset() * 60000);
    } else {
        currDate = new Date(epochTime);
    }

    const day = currDate.toLocaleString('en-us', {day: 'numeric'});
    const year = currDate.toLocaleString('en-us', {year: 'numeric'});
    const month = currDate.toLocaleString('en-us', {month: 'short'});

    const datePart = month + ' ' + day + ', ' + year;
    const timePart = currDate.toLocaleTimeString('en-US');

    return datePart + ' ' + timePart;
}

/**
* In certain components, if you want to deep clone an object to enforce 'reactivity' in LWC, use this method.
* Reactivity is enforced as deep clone is a new memory instance.
* @param {Object} obj
* @return {Object} <Deep Cloned obj>
*/
export function cloneObject(obj) {
    if (!obj) {
        return null;
    }
    return JSON.parse(JSON.stringify(obj));
}

/**
* Returns new instance of array, but elements would be the same (i.e. same memory instance)
* If you need completely new array (including cloned elements) use cloneObject
* @param {Object[]} arr
* @return {Object[]} <Cloned array>
*/
export function cloneArray(arr) {
    if (!arr || !Array.isArray(arr)) {
        return null;
    }
    return [...arr];
}

/**
* Commafies a number eg 1000 goes to 1,000
* @param {Object/String} number
*                {Integer} decimalPoints
* @return {String} <Commafied Number>
*/
export function convertToKMBFormat(number,decimalPoints = 2) {
    if (number !== undefined && number !== null) {
        return (parseFloat(number).toFixed(decimalPoints)).toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1,");
    }
    return number;
}

/**
* Used in example apps to generate random legit sounding words
* @param {Integer} count - Number of words needed
*                {Integer} wordLength
* @return {String[]} Array of random legit sounding words :)
*/
export function generateRandomWords(count,wordLength) {
    let words = [],consonants = 'bcdfghjlmnpqrstv',vowels = 'aeiou',
        length = parseInt(wordLength,10);
    consonants = consonants.split('');
    vowels = vowels.split('');
    for (let p = 0; p < count; p++){
        let word='';
        for (let i = 0; i < length/2 ; i++) {
            const rand1 = Math.floor(Math.random()*consonants.length);
            const rand2 = Math.floor(Math.random()*vowels.length);

            const randConsonant = consonants[rand1],randVowel = vowels[rand2];

            word += (i===0) ? randConsonant.toUpperCase() : randConsonant;
            word += i*2<length-1 ? randVowel : '';
        }
        words.push(word);
    }
    return words;
}

/**
* Used in example apps to generate random legit sounding words
* @param {Object[]} array
*                {Integer} size
* @return {Object[]} Array of chunked arrays, each child array max size is 'size'
*/
export function chunkArray(array, size) {
    const chunked_arr = [];
    let index = 0;
    while (index < array.length) {
        chunked_arr.push(array.slice(index, size + index));
        index += size;
    }
    return chunked_arr;
}

/**
* Months - quite self explanatory :)
*/
export const MONTHS = ["January", "February", "March", "April", "May", "June",
                       "July", "August", "September", "October", "November", "December"];

/**
* Sort Month Array. Example ['February','March','January'] => ["January", "February", "March"]
* @param {String[]} arr
* @return {String[]} <Sorted arr>
*/
export function sortMonthArray(arr) {
    arr.sort((a, b) => (MONTHS.indexOf(a) - MONTHS.indexOf(b)));
    return arr;
}

/**
* Converts String Array to a SelectOption Object Array
* @param {String[]} arr
* @return {Object[]} <SelectOption Object Array>
*/
export function arrayToSelectOptions(arr) {
    let retVal = [];
    for (const item of arr) {
        retVal.push({
            label:item,value:item
        });
    }
    return retVal;
}

/**
* Format Date as a readable string
* @param {Date} value
* @return {String} <Formatted Date>
*/
export function formatDate(value) {
    const dt = (typeof(value) === 'string') ? new Date(value) : value;
    const utcDt = new Date(dt.getTime() + dt.getTimezoneOffset() * 60000);

    return utcDt.toLocaleString('en-us', { month: 'short' }) + ' ' +
           utcDt.toLocaleString('en-us', { day: 'numeric' }) + ', ' +
           utcDt.toLocaleString('en-us', { year: 'numeric' });
}

/**
* Copy Text to clipboard
* @param {String} Text to copy
* @return None
*/
export function copyToClipboard(textToCopy) {
    const input = document.createElement("textarea");
    input.innerHTML = textToCopy;

    document.body.appendChild(input);
    input.select();

    if(navigator.clipboard){
        const selection = document.getSelection();
        navigator.clipboard.writeText(selection.toString()).catch(err => console.error(JSON.stringify(err)), err => console.error(JSON.stringify(err)));
    } else {
        // deprecated but still a good fallback because it is supported in most of the browsers
        document.execCommand('copy');
    }
    document.body.removeChild(input);
}

/**
 * Returns Today
 * @return {String} Today in format "YYYY-MM-DD"
 */
export function today() {
    // Get the current date/time in UTC
    let rightNow = new Date();

    // Adjust for the user's time zone
    rightNow.setMinutes(
        new Date().getMinutes() - new Date().getTimezoneOffset()
    );

    // Return the date in "YYYY-MM-DD" format
    return rightNow.toISOString().slice(0,10);
}

/**
 * Format get parameter from URL.
 *
 * Note: This does not work in LWR sites and some LWC, as window object is not available. Use lightning/Navigation in that case.
 *
 * @param {Date} value
 * @return {String} <Formatted Date>
 */
export function getURLParam(param) {
    const queryString = window.location.search;
    if (!queryString) {
        return '';
    }
    let urlParams = new URLSearchParams(queryString);
    return urlParams.get(param);
}

/**
 * Format Apex returned html text into valid html
 * @param {String} Apex Returned HTML text
 * @return {String} Formatted HTML text
 */
export function htmlDecode(input) {
    const doc = new DOMParser().parseFromString(input, "text/html");
    return doc.documentElement.textContent;
}

/**
 * Given an string, returns an array where each element of array has a max size specified in argument
 * @param {String} str - String to be chunked
 * @param {Integer} size - Max size of chunked string
 * @return {[String]} Array of chunked str
 */
export function chunkStringIntoArray(str, size) {
    const numChunks = Math.ceil(str.length / size);
    const chunks = new Array(numChunks);

    for (let i = 0, o = 0; i < numChunks; i++, o+=size) {
        chunks[i] = str.substring(o, o + size);
    }

    return chunks;
}