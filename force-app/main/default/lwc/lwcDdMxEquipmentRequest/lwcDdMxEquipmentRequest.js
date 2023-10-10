/**
 * @author Praveen Pandem
 * @date  07/15/2022
 * @decription Equipment request parent component for creating cases for new tablet requests.
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
/** Apex methods from CDdMxEquipmentRequestController */
import search from '@salesforce/apex/CDdMxEquipmentRequestController.search';
import createCases from '@salesforce/apex/CDdMxEquipmentRequestController.CreateCases';
import getOrderRequests from '@salesforce/apex/CDdMxEquipmentRequestController.getOrderRequests';
import validatePrinterRequest from '@salesforce/apex/CDdMxEquipmentRequestController.validatePrinterRequest';
import getAccountDetails from '@salesforce/apex/CDdMxEquipmentRequestController.getAccountDetails';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import REASON_FOR_REPLACEMENT from '@salesforce/schema/Mx_Order__c.Reason_for_Replacement__c';
import getOrderProtocolFromMint from  '@salesforce/apex/CDdMxEquipmentRequestController.getOrderProtocolFromMint';

export default class LwcDdMxEquipmentRequest extends LightningElement {
	/*****************************************************************************************************************************
	 *
	 * Private Variables
	 *
	 *****************************************************************************************************************************/

	returnRaplceOption = 'Yes';
	shippingAddress = {};
	returnReplaceOptions = [
		{ value: 'Yes', label: 'Yes' },
		{ value: 'No', label: 'No' }
	];
	internalDeployment = 'No';
	internalDeploymentOptions = [
		{ value: 'Yes', label: 'Yes' },
		{ value: 'No', label: 'No' }
	];

	shippingTypeOptions = [
		{ value: 'Standard', label: 'Standard' },
		{ value: 'Expedited', label: 'Expedited' }
	];
	MerchanthasWifiOptions = [
		{ value: 'Yes', label: 'Yes' },
		{ value: 'No', label: 'No' }
	];
	merchanthasWifi = 'No';
	shippingType = 'Standard';
	contactFormMode = 'edit';
	createNewContact = false;
	showtableNext = false;
	contacts = [];
	error;
	newRecordOptions = [{ value: 'Contact', label: 'New Contact' }];
	showEditContactForm = false;
	showNewContactForm = false;
	tabletInitialSelection = [];
	printerInitialSelection = [];
	oppInitialSelection = [];
	conactInitialSelection = [];
	items = [];
	requestProducts = [];
	orderRequestTypeData = [];
	currentStep = '1';
	reasonforRequestIfOther;
	mxOrderObject = {};
	showNewProductBox = false;
	isLoaded = false;
	contactTitle = 'New Contact';
	errors = [];
	notifyViaAlerts = false;
	casetableName = 'CaseHistory';
	caseUrlField = 'CaseNumber';
	caseCustomFilterField = 'AccountId';
	objectName = 'Contact';
	showTitle = 'Contact tile';
	strTitle = 'Contact';
	fieldSetConactName = 'Equipment_Request';
	isEditable = 'true';
	opportunityId = '';
	recordId;
	accountId;
	contactId;
	account;
	returnProds = [];
	selectedProducts = [];
	returnSelectedProds = [];
	reasonsForRequest = '';
	hideCheckBox = false;
	reqestType;
	eligibleForPrinterRequest = false;
	smContryCodes = ['US', 'CA'];
	searchTermTabletIMEI;
	searchTermPrinterIMEI;
	mintOrderProtocol;
	hideEquimentRequestUI;
	/*****************************************************************************************************************************
	 *
	 * Public Variables
	 *
	 *****************************************************************************************************************************/

	@api isOpenedConsole;

	/*****************************************************************************************************************************
	 *
	 * UI Getters
	 *
	 *****************************************************************************************************************************/

	get isStepOne() {
		return this.currentStep === '1';
	}
	get isStepTwo() {
		return this.currentStep === '2';
	}
	get isStepThree() {
		return this.currentStep === '3';
	}
	get isStepFour() {
		return this.currentStep === '4';
	}

	get isEnableNext() {
		return this.currentStep !== '4' && this.showtableNext;
	}
	get isEnablePrev() {
		return this.currentStep !== '1';
	}
	get isEnableFinish() {
		return this.currentStep === '4';
	}

	/*****************************************************************************************************************************
	 *
	 * Wires
	 *
	 *****************************************************************************************************************************/
	/**
	 *
	 * wire method to load the object info picklist values.
	 * @param objectApiName
	 */
	@wire(getObjectInfo, { objectApiName: REASON_FOR_REPLACEMENT })
	objectInfo;

	/**
	 *
	 * wire method to load the picklist values.
	 * @param recordTypeId
	 * @param fieldApiName
	 */
	@wire(getPicklistValues, {
		recordTypeId: '$objectInfo.data.defaultRecordTypeId',
		fieldApiName: REASON_FOR_REPLACEMENT
	})
	reasonForReplacementPicklistValues;

	/**
	 *
	 * wire method to load the Account details.Method will fetch the Account and opp details. once the method is laoded next button will display in the UI.
	 * @param recordId
	 */
	@wire(getAccountDetails, { recordId: '$recordId' })
	getAccountDetails({ data, error }) {
		if (data) {
			console.log('Account detials ' + JSON.stringify(data));
			this.account = data;
			this.hideCheckBox = true;
			this.showtableNext = true;
			this.shippingAddress = { ...this.account };
			this.opportunityId = data.opportunityId;
			this.returnRaplceOption = data.isFirstRequest ? 'No' : 'Yes';
		} else if (error) {
			this.notifyUser('error', error.body.message, 'error');
		}
	}

	/**
	 *
	 * wire method to load the order requests for display.
	 */
	@wire(getOrderRequests, {actId: '$accountId'})
	getOrderRequests({ data, error }) {
		if (data) {
			let i = 0;
			console.log(' Order Requests ' + JSON.stringify(data));
			const requests = data.filter((e) => e.requestType !== 'Return Label Only');
			for (i = 0; i < requests.length; i++) {
				this.items = [
					...this.items,
					{
						value: requests[i].requestType,
						label: requests[i].requestType,
						orderId: requests[i].orderId
					}
				];
			}
			this.items = [...this.items,{
				value: 'None',
				label: '-- None --',
				}
			];
			this.orderRequestTypeData = data;
			if (data.find((e) => e.requestType === 'Return Label Only')) {
				this.loadReturnProducts(data.find((e) => e.requestType === 'Return Label Only'));
			}
		} else if (error) {
			this.notifyUser('error', error.body.message, 'error');
		}
	}
	/*****************************************************************************************************************************
	 *
	 * Event Handlers
	 *
	 *****************************************************************************************************************************/
	// When terminate case creation button cliskec close the window.
	closeQuickAction() {
		this.hideEquimentRequestUI =true;
	}

	// method to get query params from URL
	getQueryParameters() {
		var searchParam = window.location.search.substring(1);
		var params = {};
		if (searchParam) {
			params = JSON.parse('{"' + searchParam.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
				return key === '' ? value : decodeURIComponent(value);
			});
		}
		this.accountId = params.AccountId;
		this.recordId = params.Id;
		return params;
	}
	connectedCallback() {
		this.getQueryParameters();
	}

	// load the return product options
	loadReturnProducts(returnProd) {
		this.returnProds = [];
		let i = 0;
		for (i = 0; i < returnProd.mxOrderRequestProduct.length; i++) {
			this.returnProds = [
				...this.returnProds,
				{
					value: returnProd.mxOrderRequestProduct[i].productId,
					label: returnProd.mxOrderRequestProduct[i].productName,
					family: returnProd.mxOrderRequestProduct[i].productFamily
				}
			];
			this.returnSelectedProds.push(returnProd.mxOrderRequestProduct[i].productId);
		}
	}
	// when the request type changes step 2 method will be called and display the related products for selection
	handleRequestTypeChange(event) { 
		this.selectedProducts = [];
		const reqType = event.detail.value;
		if(reqType === 'None'){
			this.mxOrderObject = {
				...this.mxOrderObject,
				requestType: '',
				requestTypeId: ''
			};
			this.showNewProductBox = false;
			this.requestProducts = [];
			return;
		} 
		this.reqestType = reqType;
		const request = this.orderRequestTypeData.find((e) => e.requestType === reqType);
		this.requestProducts = [];
		let i = 0;
		for (i = 0; i < request.mxOrderRequestProduct.length; i++) {
			this.requestProducts = [
				...this.requestProducts,
				{
					value: request.mxOrderRequestProduct[i].productId,
					label: request.mxOrderRequestProduct[i].productName
				}
			];
			this.selectedProducts.push(request.mxOrderRequestProduct[i].productId);
		}

		this.mxOrderObject = {
			...this.mxOrderObject,
			requestType: reqType,
			requestTypeId: request.orderId
		};
		this.showNewProductBox = true;
	}
	handleLookupLoadFromContact() {
		// refreshApex(this.mySendForSplitting);
		this.template.querySelector('c-lwc-dd-mx-lookup').callApexMethood();
	}
	/**
	 * Handles the lookup load event.
	 * Calls the server to load the default and intial selection record from server.
	 * @param {event} event `search` event emmitted by the lookup
	 */
	handleLookupLoad(event) {
		const lookup = this.template.querySelector('c-lwc-dd-mx-lookup');
		if (lookup) {
			const searchTerm = event.detail.searchTerm;
			const searchTermObject = event.detail.searchTermObject;
			search({
				searchTerm: searchTerm,
				recordId: this.accountId,
				searchObject: searchTermObject,
				opportunityId: this.opportunityId
			})
				.then((results) => {
					if (results.length >= 1 && this.opportunityId) {
						if (this.conactInitialSelection.length === 0 && searchTermObject === 'Contact') {
							this.conactInitialSelection = results;
						} else if (this.oppInitialSelection.length === 0 && searchTermObject === 'Opportunity') {
							this.oppInitialSelection = results;
						    this.reorderOpportunitiesListToMakeDefaultOpportunity();
						}
					}
					if (this.tabletInitialSelection.length === 0 && searchTermObject === 'tablet') {
						this.tabletInitialSelection = results;
					} else if (this.printerInitialSelection.length === 0 && searchTermObject === 'printer') {
						this.printerInitialSelection = results;
					}
					lookup.setDefaultResults(results);
				})
				.catch((error) => {
					this.notifyUser('error', 'An error occured while loading lookup field.', 'error');
				});
		}
	}
	/**
	 * If the users opens Equipment request Ui from opportunity reorder the opportunity list to make the opportunity as default selected by moving it to index 0.
	 */
	reorderOpportunitiesListToMakeDefaultOpportunity(){
		const fromIndex = this.oppInitialSelection.findIndex(x => (x.id).slice(0, 15) === this.opportunityId.slice(0, 15));
		this.arrayMove(fromIndex, 0);
	}
	/**
	 * Move the element of the arrey to specified index. 
	 */
	arrayMove(fromIndex, toIndex) {
		var element = this.oppInitialSelection[fromIndex];
		this.oppInitialSelection.splice(fromIndex, 1);
		this.oppInitialSelection.splice(toIndex, 0, element);
	}
	
	/**
	 * Handles the lookup search event.
	 * Calls the server to search the records from server one mothod for all searches.
	 * @param {event} event `search` event emmitted by the lookup
	 */
	handleLookupSearch(event) {
		const lookupElement = event.target;
		const searchTerm = event.detail.searchTerm;
		const searchTermObject = event.detail.searchTermObject;
		console.log('search object ' + searchTermObject + ' search ' + searchTerm);
		this.searchTermTabletIMEI = searchTermObject === 'tablet' ? searchTerm : this.searchTermTabletIMEI;
		this.searchTermPrinterIMEI = searchTermObject === 'printer' ? searchTerm : this.searchTermPrinterIMEI;

		// Call Apex endpoint to search for records and pass results to the lookup
		search({
			searchTerm: searchTerm,
			recordId: this.accountId,
			searchObject: searchTermObject,
			opportunityId: this.opportunityId
		})
			.then((results) => {
				console.log('Search results ' + JSON.stringify(results));
				lookupElement.setSearchResults(results);
			})
			.catch((error) => {
				this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
				// eslint-disable-next-line no-console
				console.error('Lookup error', JSON.stringify(error));
			});
	}
	/**
	 * Handles the lookup selection change
	 * @param {event} event `selectionchange` event emmitted by the lookup.
	 * The event contains the list of selected ids.
	 */
	// eslint-disable-next-line no-unused-vars
	handleLookupSelectionChange(event) {
		console.log('lookup selection ' + JSON.stringify(event.detail));
		if (event.detail.length >= 1) {
			if (event.detail[0].sObjectType === 'Contact') {
				console.log('contact selection ** ' + JSON.stringify(event.detail));
				if (event.detail[0].emailOrPhoneisnull) {
					this.conactInitialSelection = [];
					this.notifyUser('error', 'First Name, Last Name, Email and Phone is required on the contact. please update email and phone', 'error');
				} else {
					this.conactInitialSelection = event.detail;
				}
			} else if (event.detail[0].sObjectType === 'Opportunity') {
				this.oppInitialSelection = event.detail;
			} else if (event.detail[0].sObjectType === 'tablet') {
				this.tabletInitialSelection = event.detail;
			} else if (event.detail[0].sObjectType === 'printer') {
				this.printerInitialSelection = event.detail;
			}
		}
	}
	// products will be added to the arrey when products selected from step 2
	handleProductSelection(e) {
		this.selectedProducts = e.detail.value;
	}
	handleReturnReplaceChange(event) {
		this.returnRaplceOption = event.detail.value;
	}
	handleReturnProductSelection(event) {
		this.returnSelectedProds = event.detail.value;
	}
	handleReasonforRequestChange(event) {
		this.reasonsForRequest = event.detail.value;
	}
	handleReasonChange(event) {
		this.reasonforRequestIfOther = event.target.value;
	}
	handleShipppingTypeChange(event) {
		this.shippingType = event.detail.value;
	}
	handleinternalDeploymentChange(event) {
		this.internalDeployment = event.detail.value;
	}
	handleMerchanthasWifiChange(event) {
		this.merchanthasWifi = event.detail.value;
	}
	handleNewContact() {
		this.showEditContactForm = true;
		this.createNewContact = true;
		this.contactFormMode = 'new';
	}
	handleEditContact(event) {
		this.contactId = event.detail;
		this.showEditContactForm = true;
		this.createNewContact = false;
		this.contactTitle = 'Edit Contact';
	}
	handleCloseModal() {
		///  this.handleLookupLoadFromContact();
		this.showEditContactForm = false;
	}
	HandleUpdateAddress(event) {
		this.shippingAddress = event.detail;
	}

	async validatePrinterRequests() {
		this.eligibleForPrinterRequest = await validatePrinterRequest({ payload: JSON.stringify(this.mxOrderObject) });
	}

	async fetchOrderProtocolFromMint(){
		try{
		this.mintOrderProtocol = await getOrderProtocolFromMint({ storeId: this.account.storeId});
		} catch (error) {
			console.log('error '+JSON.stringify(error));
		}
	}
	//on navigating from each step to next step this method will be called and perform the validation.
	async handleNext() {
		console.log('at next ');
		if (this.currentStep === '1') {
			this.currentStep = '2';
		} else if (this.currentStep === '2') {
			if (this.oppInitialSelection.length === 0) {
				if(this.account.isLemonadeAccount === false){				
					await this.fetchOrderProtocolFromMint();
					if(this.mintOrderProtocol === 'IPAD'){
						this.mxOrderObject = {
							...this.mxOrderObject,
							mintOrderProtocol: this.mintOrderProtocol
						};				
					} else {
						this.notifyUser('error', 'Please select the Opportunity', 'error');
						return;	
					};	
				}		
			}else {
				this.mxOrderObject = {
					...this.mxOrderObject,
					OppId: this.oppInitialSelection[0].id
				}
			}
			this.mxOrderObject = {
				...this.mxOrderObject,
				merchanthasWifi: this.merchanthasWifi,
				newProducts: this.selectedProducts,
				AccountId: this.accountId,
				isLemonadeAccount: this.account.isLemonadeAccount
			};
			await this.validatePrinterRequests();
			if (this.eligibleForPrinterRequest === false) {
				this.notifyUser('error', 'Cannot create printer case due to a shortgage of printers. Please select a different request type', 'error');
				return;
			}
			this.currentStep = '3';
		} else if (this.currentStep === '3') {
			if (this.returnRaplceOption === 'Yes') {
				if (this.smContryCodes.includes(this.account.BillingCountryCode) && this.returnSelectedProds.length === 0) {
					this.notifyUser('error', 'Please select the return products', 'error');
					return;
				}
				if (this.reasonsForRequest.length === 0) {
					this.notifyUser('error', 'Please select the reason for replacement', 'error');
					return;
				}
				if (this.tabletInitialSelection.length >= 1) {
					this.mxOrderObject = {
						...this.mxOrderObject,
						tabletImei: this.tabletInitialSelection[0].title,
						originalTabletCaseId: this.tabletInitialSelection[0].id,
						IMEIObject: this.tabletInitialSelection[0].IMEIObject
					};
				} else if (this.searchTermTabletIMEI) {
					this.mxOrderObject = {
						...this.mxOrderObject,
						tabletImei: this.searchTermTabletIMEI
					};
				}
				if (this.printerInitialSelection.length >= 1) {
					this.mxOrderObject = {
						...this.mxOrderObject,
						printerImei: this.printerInitialSelection[0].title
					};
				} else if (this.searchTermPrinterIMEI) {
					this.mxOrderObject = {
						...this.mxOrderObject,
						printerImei: this.searchTermPrinterIMEI
					};
				}

				this.mxOrderObject = {
					...this.mxOrderObject,
					returnReplaceComponent: this.returnRaplceOption,
					returnProducts: this.returnSelectedProds,
					replacementReason: this.reasonsForRequest,
					reasonForReplOther: this.reasonforRequestIfOther
				};
			}
			this.currentStep = '4';
		}
	}
	//After finishing the step4 this method will be called and run validation before submitting the data to the controller.
	handleFinish(event) {
		if (this.conactInitialSelection.length === 0) {
			this.notifyUser('error', 'Please select the contact', 'error');
			return;
		}
		if(this.conactInitialSelection[0].emailOrPhoneisnull){
			this.notifyUser('error', 'First Name, Last Name, Email and Phone is required on the contact. please update email and phone on selected contact', 'error');
			return;
		}

		this.mxOrderObject = {
			...this.mxOrderObject,
			...this.shippingAddress,
			shippingType: this.shippingType,
			internalDeployment: this.internalDeployment,
			contactId: this.conactInitialSelection[0].id
		};

		console.log('at finish ' + JSON.stringify(this.mxOrderObject));
		this.isLoaded = true;
		createCases({
			payload: JSON.stringify(this.mxOrderObject)
		})
			.then((result) => {
				console.log('result ' + JSON.stringify(result));
				this.notifyUser('success', 'Cases have been created for the request. Case Numbers: '+ result.toString(), 'success');
				this.closeQuickAction();
				//this.isLoaded = false;
			})
			.catch((error) => {
				console.log('error while creating case ' + JSON.stringify(error));
				this.notifyUser('error', 'Failed to create the case ' + error.body.message, 'error');
			});
	}

	handleOnStepClick(event) {
		//this.currentStep = event.target.value;
	}

	handlePrev() {
		if (this.currentStep === '4') {
			this.currentStep = '3';
		} else if (this.currentStep === '3') {
			this.currentStep = '2';
		} else if (this.currentStep === '2') {
			this.currentStep = '1';
		}
	}
	// Method to disply the error messages.
	notifyUser(title, message, variant) {
		console.log('show toast');
		this.template.querySelector('c-lwc-dd-mx-custom-toast-messge').showToast(title, message);
	}
}