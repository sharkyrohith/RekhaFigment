import { LightningElement, track } from 'lwc';

export default class LwcCommunityStorefrontTC extends LightningElement {
    @track language = "en_US";
    @track businessName = "";
    @track businessNameRaw = "";
    @track contactInfo = "";
    @track businessNameRaw = "";
    @track privacyPolicyLink = "";

    connectedCallback() {
        this.language = this.getURLParam("language");
        this.businessNameRaw = this.getURLParam("business_name");
        this.businessName = this.b64DecodeUnicode(decodeURIComponent(this.businessNameRaw));
        this.contactInfoRaw = this.getURLParam("contact_info");
        this.contactInfo = this.b64DecodeUnicode(decodeURIComponent(this.contactInfoRaw));
        this.privacyPolicyLink = "/consumers/s/storefront-privacy-policy" 
                                    + "?business_name=" + this.businessNameRaw 
                                    + "&contact_info=" + this.contactInfoRaw;
    }

    getURLParam(parameterName) {
        var result = null,
            tmp = [];
        location.search
            .substr(1)
            .split("&")
            .forEach(function (item) {
              tmp = item.split("=");
              if (tmp[0] === parameterName) result = tmp[1];
            });
        return result;
    }

    b64DecodeUnicode(str) {
        // Going backwards: from bytestream, to percent-encoding, to original string.
        return decodeURIComponent(atob(str).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
    }
}