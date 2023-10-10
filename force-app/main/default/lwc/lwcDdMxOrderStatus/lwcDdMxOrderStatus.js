import { LightningElement, api } from 'lwc';
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';
import hasMxOrderStatusPermission from '@salesforce/customPermission/Mx_Order_Status_Permission';
import hasMxOrderVendorPermission from '@salesforce/customPermission/Mx_Order_Vendor_Permission';
import processMxOrder from '@salesforce/apex/CDdMxOrderProcessController.processMxOrder';
import getMxOrder from '@salesforce/apex/CDdMxOrderProcessController.getMxOrder';

const CHANNEL_MX_ORDER_EVENT = '/event/Mx_Order_Event__e';

const STEP_READY_TO_PROCESS = 'Ready to Process';
const STEP_VERIFY = 'Verify';
const STEP_QUEUED = 'Queued';
const STEP_IN_PROGRESS = 'In Progress';
const STEP_SHIPPED = 'Shipped';
const STEP_DELIVERED = 'Delivered';

const ORDER_STATUS_OPEN = 'open';
const ORDER_STATUS_INVALID = 'invalid';
const ORDER_STATUS_FAILED = 'failed';
const ORDER_STATUS_QUEUED = 'queued';
const ORDER_STATUS_NEW = 'new';
const ORDER_STATUS_VALIDATED = 'validated';
const ORDER_STATUS_PATIALLY_DELIVERED = 'partially_delivered';
const ORDER_STATUS_PICKED = 'picked';
const ORDER_STATUS_CONFIGURED = 'configured';
const ORDER_STATUS_LABELED = 'labeled';
const ORDER_STATUS_SHIPPED = 'shipped';
const ORDER_STATUS_DELIVERED = 'delivered';

export default class LwcDdMxOrderStatus extends LightningElement {
    @api recordId;

    mxOrder;
    mxOrderFromDB;
    error;
    timer;

    channelName = CHANNEL_MX_ORDER_EVENT;
    subscription = {};

    currentStep = ORDER_STATUS_OPEN;
    currentStepFromDB;
    hasError = false;

    showSpinner = hasMxOrderStatusPermission;

    get isMxOrderStatusPermissionEnabled() {
        return hasMxOrderStatusPermission;
    }    

    get isMxOrderVendorPermissionEnabled() {
        return hasMxOrderVendorPermission;
    }     

    connectedCallback() {
        /*if (hasMxOrderStatusPermission){
            let that = this;
            getMxOrder({ caseId: this.recordId })
            .then((result) => {                
                    that.mxOrderFromDB = result;
                    that.error = undefined;
                    that.timer = setInterval(() => {
                        that.handleGetMxOrder();
                    }, 3000);                                
                })
                .catch((error) => {
                    that.error = error;
                    that.showSpinner = false;
                });
        }*/
        let that = this;
        const messageCallback = (response) => {
            console.log('New message received : ', JSON.stringify(response));
            this.payload = JSON.stringify(response);
            console.log('this.payload: ' + this.payload);
            // Response contains the payload of the new message received
            that.handleGetMxOrder();
        };
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
            this.subscription = response;
            that.handleGetMxOrder();
        });
        // Register error listener
        this.registerErrorListener();                        
    }

    disconnectedCallback() {
        if (this.timer){
            clearInterval(this.timer);
        }
        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });        
    }

    handleProcessMxOrder() {
        let that = this;
        processMxOrder({ caseId: this.recordId })
            .then((result) => {
                that.error = undefined;
                that.timer = setInterval(() => {
                    that.handleGetMxOrder();
                }, 3000);                                
            })
            .catch((error) => {
                that.error = error;
            });
    }
    
    handleGetMxOrder() {
        let that = this;
        getMxOrder({ caseId: this.recordId })
            .then((result) => {                
                that.mxOrderFromDB = result;
                that.error = undefined;
                that.showSpinner = false;
                that.setCurrentStep();
                if (that.currentStep != that.currentStepFromDB){
                    that.mxOrder = undefined;
                    that.currentStep = that.currentStepFromDB;                
                    window.clearTimeout(this.delayTimeout);
                    this.delayTimeout = setTimeout(() => {
                        that.mxOrder = that.mxOrderFromDB;
                    }, 100);
                } else {
                    that.currentStep = that.currentStepFromDB;
                    that.mxOrder = that.mxOrderFromDB;
                }                 
            })
            .catch((error) => {
                that.error = error;
                that.showSpinner = false;
            });        
    }
    
    setCurrentStep() {
        switch (this.mxOrderFromDB.orderStatus) {
            case ORDER_STATUS_OPEN:
                this.currentStepFromDB = STEP_READY_TO_PROCESS;
                break;                
            case ORDER_STATUS_INVALID:
            case ORDER_STATUS_FAILED:
                this.currentStepFromDB = STEP_VERIFY;
                this.hasError = true;
                break;            
            case ORDER_STATUS_QUEUED:
                this.currentStepFromDB = STEP_QUEUED;
                break;           
            case ORDER_STATUS_CONFIGURED:
            case ORDER_STATUS_NEW:
            case ORDER_STATUS_PATIALLY_DELIVERED:
            case ORDER_STATUS_PICKED:
            case ORDER_STATUS_VALIDATED:
                this.currentStepFromDB = STEP_IN_PROGRESS;
                break;
            case ORDER_STATUS_LABELED:
            case ORDER_STATUS_SHIPPED:
                this.currentStepFromDB = STEP_SHIPPED;
                break;
            case ORDER_STATUS_DELIVERED:
                this.currentStepFromDB = STEP_DELIVERED;
                break;                                  
            default:
                break;                
        }        
    }

    registerErrorListener() {
        let that = this;
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
            that.showSpinner = false;
        });
    }       
}