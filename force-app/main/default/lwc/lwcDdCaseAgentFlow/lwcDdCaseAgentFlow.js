import { LightningElement, track  } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';

import getFlow from "@salesforce/apex/CDdCaseAgentFlowController.getCaseAgentFlow";
import lwcHelper from '@salesforce/resourceUrl/SRDdCommunityLWC_HelperCSS';

export default class LwcDdCaseAgentFlow extends LightningElement {
    @track obj;
    @track isLoaded = false;

    connectedCallback() {
        var caseId = this.getURLParam("id");
        getFlow({caseId: caseId})
        .then(result => {
            this.isLoaded = true;
            this.obj = result;
        })
        .catch(e => {
            this.isLoaded = true;
        })
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, lwcHelper),
        ])
        .catch(error => {
            console.log(error.body.message);
        });
    }

    getURLParam(parameterName) {
        var result = null,
            tmp = [];
        location.search
            .substr(1)
            .split("&")
            .forEach(function (item) {
              tmp = item.split("=");
              if (tmp[0] === parameterName) result = decodeURIComponent(tmp[1]);
            });
        return result;
    }
}