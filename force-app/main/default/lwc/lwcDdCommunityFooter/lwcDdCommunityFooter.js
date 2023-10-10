import { LightningElement,api } from 'lwc';
import { cloneObject } from 'c/lwcDdUtils';

import SRDdHelpSelectAssets from '@salesforce/resourceUrl/SRDdHelpSelectAssets';

// Import custom labels
import DdCommunity_Footer_NotDdCustomer from '@salesforce/label/c.DdCommunity_Footer_NotDdCustomer';
import DdCommunity_Footer_NotDdDasher from '@salesforce/label/c.DdCommunity_Footer_NotDdDasher';
import DdCommunity_Footer_NotDdMerchant from '@salesforce/label/c.DdCommunity_Footer_NotDdMerchant';
import DdCommunity_Footer_NotDdWorkClient from '@salesforce/label/c.DdCommunity_Footer_NotDdWorkClient';

import DdCommunity_Footer_ImaDasher_link from '@salesforce/label/c.DdCommunity_Footer_ImaDasher_link';

import DdCommunity_Footer_ImaDasher from '@salesforce/label/c.DdCommunity_Footer_ImaDasher';
import DdCommunity_Footer_ImaMerchant_Link from '@salesforce/label/c.DdCommunity_Footer_ImaMerchant_Link';
import DdCommunity_Footer_ImaMerchant from '@salesforce/label/c.DdCommunity_Footer_ImaMerchant';
import DdCommunity_Footer_ImaCustomer_Link from '@salesforce/label/c.DdCommunity_Footer_ImaCustomer_Link';
import DdCommunity_Footer_ImaCustomer from '@salesforce/label/c.DdCommunity_Footer_ImaCustomer';

import DdCommunity_Footer_Col1_Title from '@salesforce/label/c.DdCommunity_Footer_Col1_Title';
import DdCommunity_Footer_Col1_Link1 from '@salesforce/label/c.DdCommunity_Footer_Col1_Link1';
import DdCommunity_Footer_Col1_Label1 from '@salesforce/label/c.DdCommunity_Footer_Col1_Label1';
import DdCommunity_Footer_Col1_Link2 from '@salesforce/label/c.DdCommunity_Footer_Col1_Link2';
import DdCommunity_Footer_Col1_Label2 from '@salesforce/label/c.DdCommunity_Footer_Col1_Label2';
import DdCommunity_Footer_Col1_Link3 from '@salesforce/label/c.DdCommunity_Footer_Col1_Link3';
import DdCommunity_Footer_Col1_Label3 from '@salesforce/label/c.DdCommunity_Footer_Col1_Label3';
import DdCommunity_Footer_Col1_Link4 from '@salesforce/label/c.DdCommunity_Footer_Col1_Link4';
import DdCommunity_Footer_Col1_Label4 from '@salesforce/label/c.DdCommunity_Footer_Col1_Label4';
import DdCommunity_Footer_Col1_Link5 from '@salesforce/label/c.DdCommunity_Footer_Col1_Link5';
import DdCommunity_Footer_Col1_Label5 from '@salesforce/label/c.DdCommunity_Footer_Col1_Label5';
import DdCommunity_Footer_Col1_Link6 from '@salesforce/label/c.DdCommunity_Footer_Col1_Link6';
import DdCommunity_Footer_Col1_Label6 from '@salesforce/label/c.DdCommunity_Footer_Col1_Label6';

import DdCommunity_Footer_Col2_Title from '@salesforce/label/c.DdCommunity_Footer_Col2_Title';
import DdCommunity_Footer_Col2_Link1 from '@salesforce/label/c.DdCommunity_Footer_Col2_Link1';
import DdCommunity_Footer_Col2_Label1 from '@salesforce/label/c.DdCommunity_Footer_Col2_Label1';
import DdCommunity_Footer_Col2_Link2 from '@salesforce/label/c.DdCommunity_Footer_Col2_Link2';
import DdCommunity_Footer_Col2_Label2 from '@salesforce/label/c.DdCommunity_Footer_Col2_Label2';
import DdCommunity_Footer_Col2_Link3 from '@salesforce/label/c.DdCommunity_Footer_Col2_Link3';
import DdCommunity_Footer_Col2_Label3 from '@salesforce/label/c.DdCommunity_Footer_Col2_Label3';
import DdCommunity_Footer_Col2_Link4 from '@salesforce/label/c.DdCommunity_Footer_Col2_Link4';
import DdCommunity_Footer_Col2_Label4 from '@salesforce/label/c.DdCommunity_Footer_Col2_Label4';

import DdCommunity_Footer_Col3_Title from '@salesforce/label/c.DdCommunity_Footer_Col3_Title';
import DdCommunity_Footer_Col3_Link1 from '@salesforce/label/c.DdCommunity_Footer_Col3_Link1';
import DdCommunity_Footer_Col3_Label1 from '@salesforce/label/c.DdCommunity_Footer_Col3_Label1';
import DdCommunity_Footer_Col3_Link2 from '@salesforce/label/c.DdCommunity_Footer_Col3_Link2';
import DdCommunity_Footer_Col3_Label2 from '@salesforce/label/c.DdCommunity_Footer_Col3_Label2';
import DdCommunity_Footer_Col3_Link3 from '@salesforce/label/c.DdCommunity_Footer_Col3_Link3';
import DdCommunity_Footer_Col3_Label3 from '@salesforce/label/c.DdCommunity_Footer_Col3_Label3';

import DdCommunity_Footer_Google from '@salesforce/label/c.DdCommunity_Footer_Google';
import DdCommunity_Footer_iTunes from '@salesforce/label/c.DdCommunity_Footer_iTunes';

import DdCommunity_Footer_Merchants_TermsOfService_Link from '@salesforce/label/c.DdCommunity_Footer_Merchants_TermsOfService_Link';
import DdCommunity_Footer_TermsOfService_Link from '@salesforce/label/c.DdCommunity_Footer_TermsOfService_Link';
import DdCommunity_Footer_TermsOfService from '@salesforce/label/c.DdCommunity_Footer_TermsOfService';
import DdCommunity_Footer_Privacy_Link from '@salesforce/label/c.DdCommunity_Footer_Privacy_Link';
import DdCommunity_Footer_Privacy from '@salesforce/label/c.DdCommunity_Footer_Privacy';
import DdCommunity_Footer_DeliveryLocations_Link from '@salesforce/label/c.DdCommunity_Footer_DeliveryLocations_Link';
import DdCommunity_Footer_DeliveryLocations from '@salesforce/label/c.DdCommunity_Footer_DeliveryLocations';
import DdCommunity_Footer_Copyright_Link from '@salesforce/label/c.DdCommunity_Footer_Copyright_Link';
import DdCommunity_Footer_Copyright from '@salesforce/label/c.DdCommunity_Footer_Copyright';

import DdCommunity_Footer_Facebook_Link from '@salesforce/label/c.DdCommunity_Footer_Facebook_Link';
import DdCommunity_Footer_Twitter_Link from '@salesforce/label/c.DdCommunity_Footer_Twitter_Link';
import DdCommunity_Footer_Instagram_Link from '@salesforce/label/c.DdCommunity_Footer_Instagram_Link';
import DdCommunity_Footer_Glassdoor_Link from '@salesforce/label/c.DdCommunity_Footer_Glassdoor_Link';

const COMMUNITY_NAME_HELP_HUB = 'help';
const COMMUNITY_NAME_DASHERS = 'dashers';
const COMMUNITY_NAME_CONSUMERS = 'consumers';
const COMMUNITY_NAME_MERCHANTS = 'merchants';
const COMMUNITY_NAME_DDFW = 'work';
const COMMUNITY_NAME_SUPPORT = 'support';
const COMMUNITY_NAME_LEGAL = 'legal';

const ALLOWED_VALUES_COMMUNITY_NAME = new Set([COMMUNITY_NAME_HELP_HUB,COMMUNITY_NAME_DASHERS,COMMUNITY_NAME_CONSUMERS,
    COMMUNITY_NAME_MERCHANTS,COMMUNITY_NAME_DDFW,COMMUNITY_NAME_SUPPORT,COMMUNITY_NAME_LEGAL]);

export default class LwcDdCommunityFooter extends LightningElement {
    _communityName = COMMUNITY_NAME_HELP_HUB;
    get communityName() {
        return this._communityName;
    }
    @api
    set communityName(value) {
        if (!value || !ALLOWED_VALUES_COMMUNITY_NAME.has(value.toLowerCase())) {
            value = COMMUNITY_NAME_HELP_HUB;
        }
        this._communityName = value.toLowerCase();
    }

    label = {
        DdCommunity_Footer_NotDdCustomer,DdCommunity_Footer_NotDdDasher,DdCommunity_Footer_NotDdMerchant,DdCommunity_Footer_NotDdWorkClient,

        DdCommunity_Footer_ImaDasher_link,DdCommunity_Footer_ImaDasher,DdCommunity_Footer_ImaMerchant_Link,DdCommunity_Footer_ImaMerchant,DdCommunity_Footer_ImaCustomer_Link,DdCommunity_Footer_ImaCustomer,

        DdCommunity_Footer_Col1_Title,DdCommunity_Footer_Col2_Title,DdCommunity_Footer_Col3_Title,

        DdCommunity_Footer_Col1_Link1,DdCommunity_Footer_Col1_Label1,DdCommunity_Footer_Col1_Link2,DdCommunity_Footer_Col1_Label2,DdCommunity_Footer_Col1_Link3,DdCommunity_Footer_Col1_Label3,
        DdCommunity_Footer_Col1_Link4,DdCommunity_Footer_Col1_Label4,DdCommunity_Footer_Col1_Link5,DdCommunity_Footer_Col1_Label5,DdCommunity_Footer_Col1_Link6,DdCommunity_Footer_Col1_Label6,

        DdCommunity_Footer_Col2_Link1,DdCommunity_Footer_Col2_Label1,DdCommunity_Footer_Col2_Link2,DdCommunity_Footer_Col2_Label2,
        DdCommunity_Footer_Col2_Link3,DdCommunity_Footer_Col2_Label3,DdCommunity_Footer_Col2_Link4,DdCommunity_Footer_Col2_Label4,

        DdCommunity_Footer_Col3_Link1,DdCommunity_Footer_Col3_Label1,DdCommunity_Footer_Col3_Link2,DdCommunity_Footer_Col3_Label2,DdCommunity_Footer_Col3_Link3,DdCommunity_Footer_Col3_Label3,

        DdCommunity_Footer_Google,DdCommunity_Footer_iTunes,

        DdCommunity_Footer_Merchants_TermsOfService_Link,
        DdCommunity_Footer_TermsOfService_Link,DdCommunity_Footer_TermsOfService,
        DdCommunity_Footer_Privacy_Link,DdCommunity_Footer_Privacy,
        DdCommunity_Footer_DeliveryLocations_Link,DdCommunity_Footer_DeliveryLocations,
        DdCommunity_Footer_Copyright_Link,DdCommunity_Footer_Copyright,

        DdCommunity_Footer_Facebook_Link,DdCommunity_Footer_Twitter_Link,DdCommunity_Footer_Instagram_Link,DdCommunity_Footer_Glassdoor_Link
    };

    image = {
        Image_Arrow: SRDdHelpSelectAssets + '/arrow-2px.svg',
        Image_DD_Icon: SRDdHelpSelectAssets + '/dd-icon.svg',

        Image_Dasher: SRDdHelpSelectAssets + '/Dasher.svg',
        Image_Customer: SRDdHelpSelectAssets + '/Customer.svg',
        Image_Merchant: SRDdHelpSelectAssets + '/Merchant.svg',

        Image_GooglePlay: SRDdHelpSelectAssets + '/GooglePlay-white-01.svg',
        Image_AppleAppstore: SRDdHelpSelectAssets + '/app-store-white-01.svg',

        Image_Facebook: SRDdHelpSelectAssets + '/facebook.svg',
        Image_Twitter: SRDdHelpSelectAssets + '/twitter.svg',
        Image_Instagram: SRDdHelpSelectAssets + '/instagram.svg',
        Image_Glassdoor: SRDdHelpSelectAssets + '/glassdoor.svg'
    };

    get isHelpHub(){
        return this.communityName === COMMUNITY_NAME_HELP_HUB;
    }

    get isConsumers(){
        return this.communityName === COMMUNITY_NAME_CONSUMERS;
    }

    get isDashers() {
        return this.communityName === COMMUNITY_NAME_DASHERS;
    }

    get isMerchants() {
        return this.communityName === COMMUNITY_NAME_MERCHANTS;
    }

    get isDdfw() {
        return this.communityName === COMMUNITY_NAME_DDFW;
    }

    get isSupport() {
        return this.communityName === COMMUNITY_NAME_SUPPORT;
    }

    get isLegal() {
        return this.communityName === COMMUNITY_NAME_LEGAL;
    }
}