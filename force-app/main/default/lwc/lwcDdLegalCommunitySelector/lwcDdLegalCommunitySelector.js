/**
 * @author Raju Lakshman
 * @date  June 2022
 * @decription Country / Language selector in legal/document community page
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/

import { LightningElement,wire,api } from 'lwc';
import getPicklistOptions from '@salesforce/apex/CDdLegalCommunityController.getPicklistOptions';
import { stringIsBlank,stringIsNotBlank,isUndefinedOrNull,cloneObject,reduceErrors } from 'c/lwcDdUtils';
import { BLANK_STRING } from 'c/lwcDdConst';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import basePathName from '@salesforce/community/basePath';

// Import Labels
import DdLegalCommunity_Country from '@salesforce/label/c.DdLegalCommunity_Country';
import DdLegalCommunity_Language from '@salesforce/label/c.DdLegalCommunity_Language';

export default class LwcDdLegalCommunitySelector extends NavigationMixin(LightningElement) {
    /*****************************************************************************************************************************
     *
     * Private variables
     *
     *****************************************************************************************************************************/
    documentType;
    documentCountry;
    documentLanguage;
    isLoading = true;
    invalidArguments = false;

    selectedCountry = null;
    countryOptions = [];
    selectedLanguage = null;
    languageOptions = [];
    languageOptionMap = {};

    label = {
        DdLegalCommunity_Country,DdLegalCommunity_Language
    };

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
        if (!this.documentType) {
            this.invalidArguments = true;
            this.isLoading = false;
        } else {
            this.getOptions();
        }
    }

    /*****************************************************************************************************************************
     *
     * UI Getters
     *
     *****************************************************************************************************************************/

    get showLanguageSelector() {
        return stringIsNotBlank(this.selectedCountry) && this.languageOptions && this.languageOptions.length > 0;
    }

    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/
    // Country picklist is changed.
    handleCountryChange(event) {
        this.selectedCountry = event.detail.value;
        if (this.languageOptionMap.hasOwnProperty(this.selectedCountry)) {
            this.setLanguageOptions(this.languageOptionMap[this.selectedCountry]);
        } else {
            this.selectedLanguage = null;
        }
        this.navigateToPage();
    }

    // Language picklist has changed
    handleLanguageChange(event) {
        this.selectedLanguage = event.detail.value;
        this.navigateToPage();
    }

    /*****************************************************************************************************************************
     *
     * Helper Methods
     *
     *****************************************************************************************************************************/

    /**
     * @decription Call Server method to get the picklist options.
     * @param   None
     * @return  None
     */
    getOptions() {
        getPicklistOptions({
            legalType: this.documentType,
            countryFromURL: this.documentCountry,
            langFromURL: this.documentLanguage
        }).then(result => {
            this.isLoading = false;
            this.countryOptions = Object.values(result.countryOptions);
            this.languageOptionMap = result.languageOptions;

            for (let countryOption of this.countryOptions) {
                if (countryOption.selected) {
                    this.selectedCountry = countryOption.value;

                    if (this.languageOptionMap.hasOwnProperty(this.selectedCountry)) {
                        this.setLanguageOptions(this.languageOptionMap[this.selectedCountry]);
                        if (this.documentLanguage !== this.selectedLanguage) {
                            this.navigateToPage();
                        }
                    }
                }
            }
        })
        .catch(error => {
            this.isLoading = false;
            console.log(reduceErrors(error));
        });
    }

    /**
     * @decription Update Language picklist based on parent country picklist
     * @param   langOpts {Map} - Language options to set.
     * @return  None
     */

    setLanguageOptions(langOpts) {
        this.languageOptions = langOpts;
        for (let lang of this.languageOptions) {
            if (lang.selected) {
                this.selectedLanguage = lang.value;
            }
        }
    }

    /**
     * @decription When Country/Language picklist is changed, navigate to that page. Note, window object is not available in lwr, hence use of NavigationMixin.
     * @param   None
     * @return  None
     */
    navigateToPage() {
        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `${basePathName}/document?type=${this.documentType}&region=${this.selectedCountry}&locale=${this.selectedLanguage}`
                }
            }
        );
    }
}