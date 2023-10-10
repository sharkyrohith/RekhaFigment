import { LightningElement,api } from 'lwc';

import SRDdHelpSelectAssets from '@salesforce/resourceUrl/SRDdHelpSelectAssets';

import DdCommunity_StayTuned from '@salesforce/label/c.DdCommunity_StayTuned';
import DdCommunity_StayTunedMessage from '@salesforce/label/c.DdCommunity_StayTunedMessage';
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

export default class LwcDdCommunityStayTuned extends LightningElement {
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
        backgroundImage: SRDdHelpSelectAssets + '/ErrorPage/500-background.png',
    };

    label = {
        DdCommunity_StayTuned,DdCommunity_StayTunedMessage,DdCommunity_Error_GoBack,DdCommunity_ErrorCode_BackHome
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
        return `background-image: url("${this.image.backgroundImage}")`;
    }
}