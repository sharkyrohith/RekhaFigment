import { LightningElement,api } from 'lwc';

import SRDdHelpSelectAssets from '@salesforce/resourceUrl/SRDdHelpSelectAssets';

import DdCommunity_Error_Hmm from '@salesforce/label/c.DdCommunity_Error_Hmm';
import DdCommunity_Error_404 from '@salesforce/label/c.DdCommunity_Error_404';
import DdCommunity_ErrorCode_404 from '@salesforce/label/c.DdCommunity_ErrorCode_404';
import DdCommunity_Error_GoBack from '@salesforce/label/c.DdCommunity_Error_GoBack';
import DdCommunity_ErrorCode_BackHome from '@salesforce/label/c.DdCommunity_ErrorCode_BackHome';

const COMMUNITY_NAME_HELP_HUB = 'help';
const COMMUNITY_NAME_DASHERS = 'dashers';
const COMMUNITY_NAME_CONSUMERS = 'consumers';
const COMMUNITY_NAME_MERCHANTS = 'merchants';
const COMMUNITY_NAME_DDFW = 'work';
const COMMUNITY_NAME_SUPPORT = 'support';
const COMMUNITY_NAME_LEGAL = 'legal';

const ALLOWED_VALUES_COMMUNITY_NAME = new Set([COMMUNITY_NAME_HELP_HUB,COMMUNITY_NAME_DASHERS,COMMUNITY_NAME_CONSUMERS,
    COMMUNITY_NAME_MERCHANTS,COMMUNITY_NAME_DDFW,COMMUNITY_NAME_SUPPORT,COMMUNITY_NAME_LEGAL]);

export default class LwcDdCommunityErrorPage extends LightningElement {
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

    @api showDoordashLogo = false;

    image = {
        errorPageTheme: SRDdHelpSelectAssets + '/ErrorPage/404-background.jpg',
        errorPageBackground: SRDdHelpSelectAssets + '/ErrorPage/404-background.jpg',
        errorPageForeground: SRDdHelpSelectAssets + '/ErrorPage/404-foreground.png',
        ddLogo: SRDdHelpSelectAssets + '/ErrorPage/doordash-logo-red@2x.png',
    };

    label = {
        DdCommunity_Error_Hmm,DdCommunity_Error_404,DdCommunity_ErrorCode_404,DdCommunity_Error_GoBack,DdCommunity_ErrorCode_BackHome
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

    get backgroundImage() {
        return `background-image: url("${this.image.errorPageBackground}")`;
    }

    get foregroundImage() {
        return `background-image: url("${this.image.errorPageForeground}")`;
    }
}