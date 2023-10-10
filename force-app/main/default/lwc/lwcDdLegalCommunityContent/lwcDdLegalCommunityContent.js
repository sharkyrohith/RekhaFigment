/**
 * @author Raju Lakshman
 * @date  June 2022
 * @decription Component which displayes Legal Content on the legal/document community page.
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import getLegalContent from '@salesforce/apex/CDdLegalCommunityController.getLegalContent';
import { stringIsBlank,stringIsNotBlank,isUndefinedOrNull,cloneObject,reduceErrors,getURLParam,htmlDecode } from 'c/lwcDdUtils';
import { BLANK_STRING } from 'c/lwcDdConst';
import { CurrentPageReference } from 'lightning/navigation';
const audienceAbbreviation = {"Mx" : "Merchant","Cx" : "Customer","Dx" : "Dasher"};

export default class LwcDdLegalCommunityContent extends LightningElement {
    /*****************************************************************************************************************************
     *
     * Private variables
     *
     *****************************************************************************************************************************/
    documentType;
    documentCountry;
    documentLanguage;
    contentName;
    isLoading = true;
    showCurrentVersion = true;
    content = [];
    previousContent = [];
    currentPolicyEffectiveDate;
    currentPolicyPublishedDate;
    audienceType;
    showSelectCountryAndLangMessage = false;

    /*****************************************************************************************************************************
     *
     * Lifecycle hooks
     *
     *****************************************************************************************************************************/


    /*****************************************************************************************************************************
    *
    * Wires
    *
    *****************************************************************************************************************************/
    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        this.documentType = pageRef.state['type'];
        this.documentCountry = isUndefinedOrNull(pageRef.state['region']) ? pageRef.state['country'] : pageRef.state['region'];
        this.documentLanguage = isUndefinedOrNull(pageRef.state['locale']) ? pageRef.state['language'] : pageRef.state['locale'];
        if(pageRef.state['version']){
            this.showCurrentVersion = (pageRef.state['version'] == 'current') ? true : false;
        }
        if (stringIsNotBlank(this.documentType)) {
            if (stringIsBlank(this.documentCountry) || stringIsBlank(this.documentLanguage)) {
                this.isLoading = false;
                this.showSelectCountryAndLangMessage = true;
            } else {
                this.getContent();
            }
        } else {
            this.isLoading = false;
        }
    }
    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/
    toggleVersion(e){
        this.showCurrentVersion = !this.showCurrentVersion;
    }
    /*****************************************************************************************************************************
     *
     * UI Getters
     *
     *****************************************************************************************************************************/

    get showContent() {
        return this.content.length > 0;
    }
    get showPreviousContent() {
        return this.previousContent.length > 0;
    }
    get showBanner() {
        /* we will not be showing the banner unless we have
         current and previous version content */
         return (this.content.length > 0 && this.previousContent.length > 0);
    }

    /*****************************************************************************************************************************
     *
     * Helper Methods
     *
     *****************************************************************************************************************************/
    /**
     * @decription Call Server method to get content
     * @param   None
     * @return  None
     */
    getContent() {
        this.isLoading = true;
        getLegalContent({
            legalType: this.documentType,
            countryFromURL: this.documentCountry,
            langFromURL: this.documentLanguage
        }).then(result => {
            this.isLoading = false;
            this.content = result && stringIsNotBlank(result.currentVersionContent) ? [result.currentVersionContent] : [];
            this.previousContent = result && stringIsNotBlank(result.previousVersionContent) ? [result.previousVersionContent] : [];
            if(result && stringIsNotBlank(result.audienceType)){
                let aud =   result.audienceType;
                //we replace abbreviations of audiences with the actual terminology
                Object.keys(audienceAbbreviation).forEach(key => {
                    aud = aud.replaceAll(key, audienceAbbreviation[key])
                  });
               this.audienceType = aud;
            }else{
                this.audienceType = '';
            }
            this.currentPolicyEffectiveDate = result && stringIsNotBlank(result.currentVersionEffectiveDate) ? result.currentVersionEffectiveDate : '';
            this.currentPolicyPublishedDate = result && stringIsNotBlank(result.currentVersionPublishedDate) ? result.currentVersionPublishedDate : '';
        })
        .catch(error => {
            this.isLoading = false;
            console.log('getContent error',error);
        });
    }
}