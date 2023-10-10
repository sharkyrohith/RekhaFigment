import {
    LightningElement,
    api
} from 'lwc';

export default class LDd_SupportLink extends LightningElement {

    @api linkText = '';
    @api URL = '';
    @api showCarat = '';

}