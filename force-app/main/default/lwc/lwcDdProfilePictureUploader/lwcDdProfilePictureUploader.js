/**
 * @author Mahesh Chouhan
 * @date  Dec 2021
 * @decription Component to download CSV File
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, wire } from 'lwc';
import deleteProfilePicture from '@salesforce/apex/CDdProfilePictureUploaderController.deleteProfilePicture';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadProfilePicture from '@salesforce/apex/CDdProfilePictureUploaderController.uploadProfilePicture';
import getUiThemeDisplayed from '@salesforce/apex/CDdLightningUtils.getUiThemeDisplayed';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import croppieResource from '@salesforce/resourceUrl/Croppie';
import getUsers from '@salesforce/apex/CDdProfilePictureUploaderController.getUsers';

const columns = [
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{ label: 'Edit', name: 'edit'}],
            menuAlignment: 'left'
        }
    },
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Email', fieldName: 'Email'},
    { label: 'Profile', fieldName: 'UserProfile__c', type: 'text' },
    { label: 'Role', fieldName: 'UserRole__c', type: 'text' },
    { label: 'Photo Document URL', fieldName: 'Photo_Document_URL__c', type: 'url',
        typeAttributes: {
            label: { fieldName: 'Photo_Document_URL__c' },
            target: '_blank'
        }
    }
];

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const ELE_MODAL = '[data-id="modal"]';
const ELE_IMAGE = '[data-id="image"]';
export default class LwcDdProfilePictureUploader extends LightningElement {

    /*****************************************************************************************************************************
     *
     * Private Variables
     *
     *****************************************************************************************************************************/
    fileReader;
    fileName;
    isClassicInterface;
    editable = false;
    isLoading = false;
    nameSearchTerm = '';
    emailSearchTerm = '';
    profileSearchTerm = '';
    roleSearchTerm = '';
    columns = columns;
    userData;
    user;
    labels = {
        successMessage: 'Success',
        errorMessage: 'Error'
    };
    recordId;

    /*****************************************************************************************************************************
     *
     * Wires
     *
     *****************************************************************************************************************************/
    
    @wire(getUiThemeDisplayed)
    getUiThemeDisplayedWire({ error, data }){
        if(data){
            this.isClassicInterface = (data === 'Theme3');
        } else if(error){
            console.log(JSON.stringify(error));
        }
    }

    /*****************************************************************************************************************************
     *
     * UI Getters
     *
     *****************************************************************************************************************************/
    get photoURL(){
        return this.user.Photo_Document_URL__c ? 
            this.user.Photo_Document_URL__c : croppieResource + '/no-profile-image.png';
    }

    get disableUpload(){
        return this.fileName === undefined;
    }

    get disableDelete(){
        return this.user.Photo_Document_URL__c === undefined || this.user.Photo_Document_URL__c === '';
    }

    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/

    //When an image file is selected
    readUploadedFile(event) {
        if(event.target.files) {
            this.editable = true;
            const file = event.target.files[0];
            var reader = new FileReader();
            reader.onload = () => {
                this.fileReader = new Croppie(this.template.querySelector(ELE_IMAGE), {
                    viewport: {
                        width: 199,
                        height: 199,
                        type: 'circle'
                    },
                    boundary: {
                        width: 200,
                        height: 200
                    },
                    showZoomer: true,
                });
                this.fileReader.bind({
                    url: reader.result
                });
                this.fileName = file.name;
            }
            reader.readAsDataURL(file);
        }
    }

    handleClick(){
        if(this.fileName) {
            this.isLoading = true;
            this.fileReader.result({
                type: 'base64'
            })
            .then(result => {
                let fileData = {
                'filename': this.fileName,
                'base64': result.split(',')[1]
                };
                const {base64, filename} = fileData;
                const userId = this.recordId;
                uploadProfilePicture({ base64, filename, userId}).then(result=>{
                    let title = `${filename} uploaded successfully!!`;
        
                    const toastEvent = new ShowToastEvent({
                        title, 
                        variant:"success"
                    });

                    if(this.isClassicInterface ){
                        this.handleSuccess(title);
                    }
                    else {
                        this.dispatchEvent(toastEvent);
                    }
                    let control = this.template.querySelector(ELE_MODAL);
                    if (control) {
                        control.hide();
                    }
                    let newData = this.userData.map((user) => 
                        Object.assign({}, user)
                    );

                    for (const element of newData) {
                        if(element.Id === this.recordId) {
                            element.Photo_Document_URL__c = result;
                        }
                    }

                    this.userData = [...newData];
                    this.user = undefined;
                    this.recordId = undefined;
                    this.editable = false;
                    this.isLoading = false;
                    this.fileName = undefined;
                });
            })
            .catch(error => {
                this.isLoading = false;
                console.log(JSON.stringify(error));
            });
        }
    }

    handleDelete() {
        this.isLoading = true;
        const userId = this.recordId;
        const photoDocumentURL = this.user.Photo_Document_URL__c;
        const documentId = photoDocumentURL.substring(photoDocumentURL.indexOf('?id=') + 4, photoDocumentURL.indexOf('&oid'));
        deleteProfilePicture({userId, documentId})
                .then(() => {
                    this.isLoading = false;
                    let control = this.template.querySelector(ELE_MODAL);
                    if (control) {
                        control.hide();
                    }

                    let newData = this.userData.map((user) => 
                        Object.assign({}, user)
                    );

                    for (const element of newData) {
                        if(element.Id === this.recordId) {
                            element.Photo_Document_URL__c = '';
                        }
                    }

                    this.userData = [...newData];
                })
                .catch(error => {
                    this.isLoading = false;
                    console.log(JSON.stringify(error));
                    if(this.isClassicInterface ){
                        this.handleError('Error creating record');
                    }
                    else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error creating record',
                                message: error.body.message,
                                variant: 'error'
                            })
                        );
                    }
                });
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, croppieResource + '/croppie.css'),
            loadScript(this, croppieResource + '/croppie.js')
        ]).then(() => {}).catch(error => {
            console.log('Error occurred while loading Croppie Library');
        });
    }

    handleRowAction(event) {
        this.user = event.detail.row;
        this.recordId = this.user.Id;
        let control = this.template.querySelector(ELE_MODAL);
        if (control) {
            control.show();
        }
    }

    handleUserSearchTerm(event) {
        this.isLoading = false;
        if (event.detail[0].type == 'nameSearchTerm') {
            this.nameSearchTerm = event.detail[0].stringVal;
        } else if (event.detail[0].type == 'emailSearchTerm') {
            this.emailSearchTerm = event.detail[0].stringVal;
        } else if (event.detail[0].type == 'profileSearchTerm') {
            this.profileSearchTerm = event.detail[0].stringVal;
        } else if (event.detail[0].type == 'roleSearchTerm') {
            this.roleSearchTerm = event.detail[0].stringVal;
        }
    }

    fetchUsers() {
        this.isLoading = true;

        if(this.nameSearchTerm || this.emailSearchTerm || this.profileSearchTerm || this.roleSearchTerm) {
            let random = Math.random();
            getUsers({ nameSerchVal: this.nameSearchTerm, emailSearchVal: this.emailSearchTerm, profileSearchVal: this.profileSearchTerm, roleSeachVal: this.roleSearchTerm, random: random})
            .then(result => {
                this.userData = [...result];
                this.isLoading = false;

                if(result.length == 0) {
                    if(this.isClassicInterface ){
                        this.handleError('No Users Found');
                    }
                    else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'No Users Found',
                                variant: 'error'
                            })
                        );
                    }
                }
            })
            .catch((error) => {
                console.log('erro msg'+JSON.stringify(error.body.message));
                this.isLoading = false;
                this.showToaster('error', error.body.message , 'error');
            });
        }
        else {
            if(this.isClassicInterface ){
                this.handleError('No Search Filter applied');
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'No Search Filter applied',
                        variant: 'error'
                    })
                );
            }
            this.isLoading = false;
        }
    }

    handleError(title) {
        this.showToast(this.labels.errorMessage, title, 'error', true);
    }

    showToast(title, message, variant, autoClose) {
        this.template.querySelector('c-toast-message').showCustomNotice({
            detail: {
                title: title, message: message, variant: variant, autoClose: autoClose
            }
        });
    }

    handleSuccess(title) {
        this.showToast(this.labels.successMessage, title, 'success', true);
    }
}