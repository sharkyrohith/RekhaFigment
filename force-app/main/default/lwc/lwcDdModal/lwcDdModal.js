import { api, LightningElement } from 'lwc';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = 'Escape';
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = 'Tab';

// Import custom labels
import cancelBtnLabel from '@salesforce/label/c.Generic_Cancel_Button';
import saveBtnLabel from '@salesforce/label/c.Generic_Save_Button';

export default class LwcDdModal extends LightningElement {

    label = {
        cancelBtnLabel, saveBtnLabel
    }
    
    isOpen = false;

    outsideClickListener = (e) => {
        e.stopPropagation();
        if (!this.isOpen) {
            return;
        } else {
            this.hideModal();
        }
    };

    connectedCallback() {
        this.template.addEventListener('click', this.outsideClickListener);
    }

    disconnectedCallback() {
        this.template.removeEventListener('click', this.outsideClickListener);
    }

    @api modalHeader;
    @api modalTagline;
    @api modalSaveHandler;
    @api modalSize;

    @api
    hideModal() {
        if (this.isOpen){
            this.isOpen = false;
        }
        const closedialog = new CustomEvent('closemodal');
        this.dispatchEvent(closedialog);                
    }

    @api
    showModal() {
        if (!this.isOpen){
            this.isOpen = true;
            if (this.isOpen) {
                this.focusFirstChild();
            }
        }
    }    

    @api
    get cssClass() {
        const baseClasses = ['slds-modal'];
        baseClasses.push([
            this.isOpen ? 'slds-visible slds-fade-in-open' : 'slds-hidden'
        ]);
        if (this.isOpen && ['small','medium','large'].indexOf(this.modalSize) > -1){
            baseClasses.push(['slds-modal_' + this.modalSize]);
        }
        return baseClasses.join(' ');
    }

    @api
    get modalAriaHidden() {
        return !this.isOpen;
    }

    closeModal(event) {
        event.stopPropagation();
        this.hideModal();
    }

    innerClickHandler(event) {
        event.stopPropagation();
    }

    innerKeyUpHandler(event) {
        if (event.keyCode === ESC_KEY_CODE || event.code === ESC_KEY_STRING) {
            this.hideModal();
        } else if (
            event.keyCode === TAB_KEY_CODE ||
            event.code === TAB_KEY_STRING
        ) {
            const el = this.template.activeElement;
            let focusableElement;
            if (event.shiftKey && el && el.classList.contains('firstlink')) {
                //the save button is only shown
                //for modals with a saveHandler attached
                //fallback to the close button, otherwise
                focusableElement = this.modalSaveHandler
                    ? this.template.querySelector('button.save')
                    : this._getCloseButton();
            } else if (el && el.classList.contains('lastLink')) {
                focusableElement = this._getCloseButton();
            }
            if (focusableElement) {
                focusableElement.focus();
            }
        }
    }

    _getCloseButton() {
        let closeButton = this.template.querySelector('button[title="Close"]');
        if (!closeButton) {
            //if no header is present, the first button is
            //always the cancel button
            closeButton = this.template.querySelector('button');
        }
        return closeButton;
    }

    _getSlotName(element) {
        let slotName = element.slot;
        while (!slotName && element.parentElement) {
            slotName = this._getSlotName(element.parentElement);
        }
        return slotName;
    }

    async focusFirstChild() {
        const children = [...this.querySelectorAll('*')];
        for (let child of children) {
            let hasBeenFocused = false;
            if (this._getSlotName(child) === 'body') {
                continue;
            }
            await this.setFocus(child).then((res) => {
                hasBeenFocused = res;
            });
            if (hasBeenFocused) {
                return;
            }
        }
        //if there is no focusable markup from slots
        //focus the first button
        const closeButton = this._getCloseButton();
        if (closeButton) {
            closeButton.focus();
        }
    }

    setFocus(el) {
        return new Promise((resolve) => {
            const promiseListener = () => resolve(true);
            try {
                el.addEventListener('focus', promiseListener);
                el.focus();
                el.removeEventListener('focus', promiseListener);
                setTimeout(() => resolve(false), 0);
            } catch (ex) {
                resolve(false);
            }
        });
    }
}