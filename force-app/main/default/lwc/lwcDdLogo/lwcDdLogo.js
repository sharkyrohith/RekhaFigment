import { LightningElement,api } from 'lwc';

import SRDdHelpSelectAssets from '@salesforce/resourceUrl/SRDdHelpSelectAssets';

const LEFT = 'left';
const CENTER = 'center';
const RIGHT = 'right';

const ALLOWED_VALUES_POSITION = new Set([LEFT,CENTER,RIGHT]);
export default class LwcDdLogo extends LightningElement {
    _position = LEFT;
    get position() {
        return this._position;
    }
    @api
    set position(value) {
        if (!value || !ALLOWED_VALUES_POSITION.has(value.toLowerCase())) {
            value = LEFT;
        }
        this._position = value.toLowerCase();
    }

    image = {
        ddLogo: SRDdHelpSelectAssets + '/Logo/DoorDash_logo_RGB-01.svg'
    }

    get mainDivClass() {
        console.log('ddlogo');
        return `ddhs-select-logo-wrap ddhs-select-logo-${this.position}`;
    }

}