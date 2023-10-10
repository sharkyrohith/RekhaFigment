import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import readCSV from '@salesforce/apex/CDdUserNestingCtrl.readCSVFile';
import getChannelNames from '@salesforce/apex/CDdUserNestingCtrl.getChannelNames';
import getUsers from '@salesforce/apex/CDdUserNestingCtrl.getUsers';
import addUserToChannel from '@salesforce/apex/CDdUserNestingCtrl.addUserToChannel';
import getPresUserConfigUser from '@salesforce/apex/CDdUserNestingCtrl.getPresUserConfigUser';
import removeUserFromChannel from '@salesforce/apex/CDdUserNestingCtrl.removeUserFromChannel';
import getUserPerm from '@salesforce/apex/CDdUserNestingCtrl.getUserPerm';


const pciTableClmns = [
    { label: 'Channel Name', fieldName: 'MasterLabel', type: "Text", editable: false, },
    { label: 'User Name', fieldName: 'UserName', type: "Text", editable: false, },
    { label: 'Profile', fieldName: 'UserProfile__c', type: "Text", editable: false, },
    { label: 'Role', fieldName: 'UserRole__c', type: "Text", editable: false, },
];

const UserTblColumns = [
    { label: 'User Name', fieldName: 'Name', type: 'text', sortable: true, },
    { label: 'Email', fieldName: 'Email', },
    { label: 'Profile', fieldName: 'UserProfile__c', type: "Text", editable: false, },
    { label: 'Role', fieldName: 'UserRole__c', type: "Text", editable: false, },
];
export default class LwcDdUserNesting extends LightningElement {
    hasUserAccess = false;
    @track showModal = false;
    @api recordId;
    @track error;
    loaded = true;
    //  @track columns = columns;
    @track data;
    channelOptions = [];
    channelSelected = '';
    channelValue = [];
    UserTableColumns = UserTblColumns;
    userData = [];
    nameSearchTerm = '';
    emailSearchTerm = '';
    profileSearchTerm = '';
    roleSearchTerm = '';
    isSearchButtonDisabled = true;
    isShowAddSaveBtnDisabled = true;
    // selectedRowsForAdd=[];
    selectedUsersForAdd = [];
    setSelectedUsersForAdd = [];
    pciTableColumns = pciTableClmns;
    pciData = [];
    selectedPciRows = [];
    setSelectedPicRows = [];
    isShowRemoveSaveBtnDisabled = true;
    ShowPciSearchBtnDisabled = true;
    channelValueRemove = '';
    errorListFromBulkUplaod;
    iserrorinBulkLoad = false;


    connectedCallback() {
        getUserPerm()
            .then(result => {
                this.hasUserAccess = result;
            })
            .catch(error => {
                this.Error = error;
                this.hasUserAccess = false;
            })
        console.log('user permission' + JSON.stringify(this.hasUserAccess));
    }
    // accepted parameters
    get acceptedFormats() {
        return ['.csv'];
    }

    handleShowModal() {
        this.showModal = true;
        this.iserrorinBulkLoad = false;
        this.errorListFromBulkUplaod = [];
    }
    handleCloseModal() {
        this.showModal = false;
    }

    handleUploadFinished(event) { // Get the list of uploaded files
        this.loaded = false;
        this.iserrorinBulkLoad = false;
        this.errorListFromBulkUplaod = [];
        const uploadedFiles = event.detail.files;
        console.log('@@content doc id in lwc' + uploadedFiles[0].documentId);
        // calling apex class
        readCSV({ idContentDocument: uploadedFiles[0].documentId }).then(result => {
            window.console.log('result ===> ' + result);
            console.log('result from bulkuplaod call' + JSON.stringify(result));
            if ('Error' in result) {
                let errorMap = [];
                this.iserrorinBulkLoad = true;
                result.Error.forEach((ele) => {
                    errorMap.push({ "Label": ele, "Id": ele.index });
                    console.log('element' + ele);
                });
                this.errorListFromBulkUplaod = errorMap;
                console.log('this.errorListFromBulkUplaod' + this.errorListFromBulkUplaod);
                //  this.dispatchEvent(new ShowToastEvent({ title: 'Error!!', message: 'Error in uploaded csv file', variant: 'error' }),);
                this.showToaster('error', 'Error in uploaded csv file', 'error');
                this.loaded = true;
            } else {
                //       this.dispatchEvent(new ShowToastEvent({ title: 'Success!!', message: 'Records queued for processing based on CSV file.', variant: 'success' }),);
                this.showToaster('Success', 'Records queued for processing based on CSV file.', 'Success');
                this.loaded = true;
            }
        }).catch(error => {
            this.error = error;
            this.loaded = true;
            console.log('@error uplaoding PUC' + JSON.stringify(error));
            //     this.dispatchEvent(new ShowToastEvent({ title: 'Error!!', message: JSON.stringify(error), variant: 'error' }),);
            this.showToaster('error', JSON.stringify(error), 'error');
        })

    }

    // fetch presenceuserConfig developername and id  when user clicks on Add tab of Manual Tab
    handleMenuAddTabActive(event) {
        console.log('in add tab');
        this.emptyValuesOnTabChange();
        this.channelValue = [];
        this.channelValueRemove = [];
        let tabSelected = event.target.value;
        this.fetchUsers();

    }

    @wire(getChannelNames)
    channelNames({error,data}) {
        if (data) {
            this.channelOptions = data.map(chVal => {
                return { label: chVal.MasterLabel, value: chVal.DeveloperName }
            });
        } else if (error) {
            this.error = error;
            console.log('error fetching Channel-PresenceUSerConfig' + JSON.stringify(error));
            if(this.hasUserAccess) {
                this.showToaster('error', 'error fetching Channel Names' + JSON.stringify(error), 'error');
            }
        }
    }

    handleChangeOfChannelValue(event) {
        //    this.channelValue = event.detail.value;
        this.channelSelected = event.detail.value;
        console.log('selcted channel value' + this.channelSelected);

    }
    getSelectedUsersForAdd(event) {
        this.selectedUsersForAdd = event.detail.selectedRows;

    }

    getSelectedPciRows(event) {
        this.selectedPciRows = event.detail.selectedRows;
        console.log('selected pci row' + event.detail.selectedRows);
        if (this.selectedPciRows.length > 0) {
            this.isShowRemoveSaveBtnDisabled = false;
        } else {
            this.isShowRemoveSaveBtnDisabled = true;
        }
    }

    handleMenuRemoveTabActive(event) {
        console.log('in remove tab');
        this.emptyValuesOnTabChange();
        let tabSelected = event.target.value;
        this.handleSearchPciUsers();
    }

    get isShowSearchButton() {
        return this.isSearchButtonDisabled;
    }

    get isShowAddSaveButton() {
        if (this.selectedUsersForAdd.length > 0 && ((this.channelSelected.trim()).length > 0)) {
            this.isShowAddSaveBtnDisabled = false;
        } else {
            this.isShowAddSaveBtnDisabled = true;
        }
        return this.isShowAddSaveBtnDisabled;
    }

    get isShowRemoveSaveButton() {
        return this.isShowRemoveSaveBtnDisabled;
    }

    get isShowPciSearchButton() {
        return this.ShowPciSearchBtnDisabled;
    }

    handleUserSearchTerm(event) {
        /*  // let eventDetails = event.detail;
         //  console.log('eventDetails'+eventDetails);
           console.log('event from child '+JSON.stringify(event.detail));
          console.log('event.detail.type in parent'+event.detail[0].type);
          console.log('event.detail.stringVal in parent'+event.detail[0].stringVal); */
        this.loaded = false;
        if (event.detail[0].type == 'nameSearchTerm') {
            this.nameSearchTerm = event.detail[0].stringVal;
        } else if (event.detail[0].type == 'emailSearchTerm') {
            this.emailSearchTerm = event.detail[0].stringVal;
        } else if (event.detail[0].type == 'profileSearchTerm') {
            this.profileSearchTerm = event.detail[0].stringVal;
        } else if (event.detail[0].type == 'roleSearchTerm') {
            this.roleSearchTerm = event.detail[0].stringVal;
        }
        if (this.nameSearchTerm.length > 0 || this.emailSearchTerm.length > 0 || this.profileSearchTerm.length > 0 || this.roleSearchTerm.length) {
            this.isSearchButtonDisabled = false;
            this.ShowPciSearchBtnDisabled = false;
        } else {
            this.isSearchButtonDisabled = true;
            this.ShowPciSearchBtnDisabled = true;
            if (this.template.querySelector('lightning-tabset').activeTabValue == 'manual') {
                this.fetchUsers();
                this.handleSearchPciUsers();
            }

        }
        this.loaded = true;

    }

    handleChangeOfChannelValueRemove(event) {
        this.channelSelRemove = event.target.value;
        this.ShowPciSearchBtnDisabled = event.target.value ? false : true;
    }
    handleSearchUsers() {
        console.log('search tearm for Name' + this.nameSearchTerm);
        console.log('search term email' + this.emailSearchTerm);
        console.log('search term profile' + this.profileSearchTerm);
        console.log('search term role' + this.roleSearchTerm);
        this.fetchUsers();
    }
    fetchUsers() {
        this.loaded = false;
        console.log('in fetch users');
        getUsers({ nameSerchVal: this.nameSearchTerm, emailSearchVal: this.emailSearchTerm, profileSearchVal: this.profileSearchTerm, roleSeachVal: this.roleSearchTerm })
            .then(result => {
                console.log('userserach results' + JSON.stringify(result));
                this.userData = result;
                this.loaded = true;
            })
            .catch((error) => {
                this.error = error;
                // error getting channel presenceuserConfig
                console.log('erro msg'+JSON.stringify(error.body.message));
                this.loaded = true;
                this.showToaster('error', error.body.message , 'error');

            });

    }

    handleAddSave() {
        // add users to presenceuserconfig
        this.loaded = false;
        addUserToChannel({ userList: this.selectedUsersForAdd, channelIdStr: this.channelSelected })
            .then(result => {
                console.log('result from user add-' + JSON.stringify(result));
                if (result == true) {
                    //show success toaster
                    this.loaded = true;
                    this.showToaster('success', 'Adding user to channel job enqueued and will processed asper system resource availability', 'success');

                } else {
                    //   show error toaster
                    this.loaded = true;
                }

            })
            .catch((error) => {
                this.error = error;
                this.loaded = true;
                console.log('error adding users to selcted nesting' + JSON.stringify(error));
                this.showToaster('error', 'Error adding users to channel' + error, 'error');
            })

        // make save button disabled by making slected channel value and user list empty 
        this.emptyValuesOnTabChange();
        console.log('@@@@ save done');
    }

    handleRemove() {
        this.loaded = false;
        console.log('this.selectedPciRows in remove' + JSON.stringify(this.selectedPciRows));
        removeUserFromChannel({ presUserConUserList: this.selectedPciRows })
            .then(result => {
                console.log('removeUserfromChannel result ' + JSON.stringify(result));
                this.showToaster('Success', 'Removing User from Channel job enqueued and will processed asper system resource availability' , 'Success');
                this.loaded = true;
            })
            .catch((error) => {
                this.error = error;
                this.loaded = true;
                console.log('error remvoing user from presenceUSerConfigUser' + JSON.stringify(error));
                this.showToaster('error', 'Error fetching presenceUSerConfigUser' + error, 'error');
            })
        this.emptyValuesOnTabChange();
        console.log('@@@remove done');
    }

    handleSearchPciUsers() {
        // call search for pic users apex method imperatively 
        this.loaded = false;
        console.log('search pciUsers');
        getPresUserConfigUser({ nameSerchVal: this.nameSearchTerm, emailSearchVal: this.emailSearchTerm, profileSearchVal: this.profileSearchTerm, roleSeachVal: this.roleSearchTerm, channelNameVal: this.channelSelRemove })
            .then(result => {
                console.log('getPresUserConfigUser' + JSON.stringify(result));
                let currentData = [];
                if (result.length > 0) {
                    result.forEach(row => {
                        console.log('row' + JSON.stringify(row));
                        console.log('row userName' + JSON.stringify(row.User.Name));
                        console.log('row channel Name' + JSON.stringify(row.PresenceUserConfig.MasterLabel));
                        let rowData = {};
                        rowData.Id = row.Id;
                        rowData.PresenceUserConfigId = row.PresenceUserConfigId;
                        console.log('row.UserId' + row.UserId);
                        rowData.userId = row.UserId;
                        rowData.UserName = row.User.Name;
                        rowData.MasterLabel = row.PresenceUserConfig.MasterLabel;
                        rowData.UserProfile__c = row.User.UserProfile__c;
                        rowData.UserRole__c = row.User.UserRole__c;
                        currentData.push(rowData);
                    })
                }
                this.pciData = currentData;
                this.loaded = true;
            })
            .catch((error) => {
                this.error = error;
                this.loaded = true;
                console.error('error fetching presenceUSerConfigUser' + JSON.stringify(error));
                this.showToaster('error', error.body.message, 'error');
            })

        console.log('@@@ end of getPresUserConfigUser');
    }

    emptyValuesOnTabChange() {
        this.selectedPciRows = [];
        this.setSelectedPicRows = [];
        this.setSelectedUsersForAdd = [];
        this.selectedUsersForAdd = [];
        this.nameSearchTerm = '';
        this.emailSearchTerm = '';
        this.profileSearchTerm = '';
        this.roleSearchTerm = '';
        this.channelSelected = '';
        this.isSearchButtonDisabled = true;
        this.channelValue = [];
        this.channelValueRemove = [];
        this.isShowAddSaveBtnDisabled = true;
        this.isShowRemoveSaveBtnDisabled = true;
        this.iserrorinBulkLoad = false;
        this.errorListFromBulkUplaod = [];

    }

    showToaster(titleValue, messageValue, variantValue) {
        this.dispatchEvent(new ShowToastEvent({ title: titleValue, message: messageValue, variant: variantValue }));
    }
}