import {
    LightningElement,
    api,
    track
} from 'lwc';
import formFactor from '@salesforce/client/formFactor';

export default class LDd_SupportLink extends LightningElement {

    @api linkText = '';
    @api desktopURL = '';
    @api tabletURL = '';
    @api mobileURL = '';
    @api showCarat = false;
    @track URL = '';

    connectedCallback() {
        if (formFactor == 'Large') {
            this.URL = this.desktopURL;
        } else if (formFactor == 'Medium') {
            this.URL = this.tabletURL;
        } else {
            this.URL = this.mobileURL;
        }
    }


}