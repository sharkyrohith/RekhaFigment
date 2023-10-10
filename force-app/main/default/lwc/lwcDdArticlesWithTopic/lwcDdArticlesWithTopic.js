/**
 * @author Mahesh Chouhan
 * @date  April 2023
 * @decription Component to Group Articles into Categories and Sucategories
 */
/*****************************************************************************************************************************
 *
 * Imports
 *
*****************************************************************************************************************************/
import { LightningElement, api, wire } from 'lwc';
import { reduceErrors } from 'c/lwcDdUtils';
import { CurrentPageReference } from 'lightning/navigation';
import noarticlesfound from '@salesforce/label/c.No_Articles_Found';
import getArticles from '@salesforce/apex/CDdArticlesWithTopicController.getArticles';

/*****************************************************************************************************************************
 *
 * CSS Class Consts
 *
 *****************************************************************************************************************************/
const ARTICLE_ITEM_STYLE = 'slds-p-around_small slds-m-left_small';
const SLDS_HIDDEN = 'slds-hidden';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const DEFAULT_LANG = 'en_US';
const ELEMENT_SPINNER = 'lightning-spinner';

export default class LwcDdArticlesWithTopic extends LightningElement {
    /*****************************************************************************************************************************
     *
     * Public Variable
     *
    *****************************************************************************************************************************/
    @api topicId;
    @api limitSize = 10;
    @api community;
    offset = 5;

    /*****************************************************************************************************************************
     *
     * Private Variables
     *
     *****************************************************************************************************************************/
    language;
    groupArticleData;
    articleData;
    label = {
        noarticlesfound
    };

    /*****************************************************************************************************************************
     *
     * Wires
     *
     *****************************************************************************************************************************/
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       this.language = currentPageReference && currentPageReference.state && currentPageReference.state.language ?
        currentPageReference.state.language : DEFAULT_LANG;
    }

    @wire(getArticles, {lang : '$language', topicId : '$topicId', limitSize : '$limitSize', community : '$community'})
    getArticles({data, error}) {
        if(data){
            this.groupArticleData = data.groupedArticles;
            this.articleData = data.ungroupedArticles;
            this.hideSpinner();
        }
        else if(error){
            console.log(reduceErrors(error));
        }
    }

    /*****************************************************************************************************************************
     *
     * UI Getters
     *
     *****************************************************************************************************************************/
    get artcleItemStyle() {
        return ARTICLE_ITEM_STYLE;
    }

    get showGroupedArticles() {
        return  this.groupArticleData && this.groupArticleData.length > 0;
    }

    get showListArticles() {
        return  this.articleData && this.articleData.length > 0;
    }

    get showLoadMoreButton() {
        return this.articleData.length > this.limitSize;
    }

    get articlesToShow() {
        return this.articleData.slice(0, this.limitSize);
    }

    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/
    //Highlight Article Heading on Hover
    handleHover(event){
        let targetUrl = event.target.dataset.url;
        this.template.querySelector(`[data-url="${targetUrl}"]`).classList.toggle('articleItemHover');
    }

    //Show more articles on button click
    handleLoading(event){
        this.limitSize = this.limitSize + this.offset;
    }

    /*****************************************************************************************************************************
    *
    * Helper methods
    *
    *****************************************************************************************************************************/
    hideSpinner() {
        let spinner = this.template.querySelector(ELEMENT_SPINNER);
        if (spinner) {
            spinner.classList.add(SLDS_HIDDEN);
        }
    }
}