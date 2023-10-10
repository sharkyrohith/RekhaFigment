/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import { stringIsBlank,stringIsNotBlank,isUndefinedOrNull } from 'c/lwcDdUtils'; // import any other method from Util as needed
import { BLANK_STRING,CLASS_SLDS_HIDE } from 'c/lwcDdConst';

/*****************************************************************************************************************************
*
* CSS Class Consts
*
*****************************************************************************************************************************/

const MAINDIV_CLASS = 'dd-notify slds-notify slds-notify_toast slds-theme_';
const CUSTOM_BUTTON_CLASS = 'slds-m-right_small slds-align_absolute-center ';
const ICON_CONTAINER_CLASS = 'slds-icon_container slds-m-right_large slds-no-flex slds-align_absolute-center slds-icon-utility-';
/*****************************************************************************************************************************
*
* Functional Consts
*
*****************************************************************************************************************************/
const INFO = 'info';
const SUCCESS = 'success';
const WARNING = 'warning';
const ERROR = 'error';
const ALLOWED_VARIANTS = new Set([INFO,SUCCESS,WARNING,ERROR])

const SHOW = 'show';
const HIDE = 'hide';
const SHOWHIDE_OPTIONS = new Set([SHOW,HIDE]);

const ICON_PREFIX = 'utility:';

export default class DdNotice extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
    @api name; // Required
    @api showNotice = false;
    @api title;
    @api message;
    @api messageList;

    _variant = INFO;
    get variant() {
        return this._variant;
    }
    @api
    set variant(value) {
        value = (stringIsNotBlank(value) && ALLOWED_VARIANTS.has(value.toLowerCase())) ?
            value.toLowerCase() : INFO;
        this._variant = value;
    }

    _showClose = true;
    get showClose() {
        return this._showClose;
    }
    @api
    set showClose(value) {
        value = isUndefinedOrNull(value) ? true : value;
        this._showClose = value;
    }

    _autoHideInterval;
    get autoHideInterval() {
        return this._autoHideInterval;
    }
    @api
    set autoHideInterval(value) {
        value = value ? parseInt(value) : null;
        this._autoHideInterval = value;
        if (value) {
            this.timeoutHelper();
        }
    }

    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
    @api
    show(title,message,variant,autoHideInterval,showClose) {
        this.title = title;
        if (message && Array.isArray(message)) {
            this.messageList = message;
            this.message = null;
        } else {
            this.messageList = null;
            this.message = message;
        }
        this.variant = (stringIsNotBlank(variant) && ALLOWED_VARIANTS.has(variant.toLowerCase())) ?
            variant.toLowerCase() : INFO;

        this.autoHideInterval = autoHideInterval;
        this.showClose = showClose;
        this.showNotice = true;
        this.timeoutHelper();
    }

    @api
    hide() {
        this.showNotice = false;
        if (this.timeout) {
            clearTimeout(this.timeout);
            this.timeout = null;
        }
    }

    /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/
    timeout;
    hasCustomBody = false;
    hasCustomButton = false;

    /*****************************************************************************************************************************
    *
    * LifeCycle Hooks (renderedCallback,connectedCallback,disconnectedCallback)
    *
    *****************************************************************************************************************************/

    /*****************************************************************************************************************************
    *
    * UI Getters - Custom getters for variables in the HTML
    *
    *****************************************************************************************************************************/
    get mainDivClass() {
        return MAINDIV_CLASS + this.variant;
    }

    get iconContainerClass() {
        return ICON_CONTAINER_CLASS + this.variant;
    }

    get iconName() {
        return ICON_PREFIX + this.variant;
    }

    get showMessageList() {
        return this.messageList && this.messageList.length;
    }

    get customBodyClass() {
        return this.hasCustomBody ? BLANK_STRING : CLASS_SLDS_HIDE;
    }

    get contentClass() {
        return this.hasCustomBody ? CLASS_SLDS_HIDE : BLANK_STRING;
    }

    get customButtonClass() {
        return CUSTOM_BUTTON_CLASS + (this.hasCustomButton ? '' : CLASS_SLDS_HIDE);
    }

    /*****************************************************************************************************************************
    *
    * Wire
    *
    *****************************************************************************************************************************/

    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/

    handleCloseClick(event) {
        this.showNotice = false;
    }

    handleCustomBodySlotChange(event) {
        event.stopPropagation();
        this.hasCustomBody = true;
    }

    handleCustomButtonSlotChange(event) {
        event.stopPropagation();
        this.hasCustomButton = true;
    }

    /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/

    timeoutHelper() {
        if (this.autoHideInterval) {
            this.timeout = setTimeout(() => {
                this.hide();
                this.timeout = null;
            },this.autoHideInterval);
        } else if (this.timeout) {
            clearTimeout(this.timeout);
            this.timeout = null;
        }
    }
}