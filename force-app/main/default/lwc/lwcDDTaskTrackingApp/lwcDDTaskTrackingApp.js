/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable vars-on-top */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import currUserId from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retrieveTeamDetails from '@salesforce/apex/CDdTaskTrackingController.retrieveTeamDetails';
import retrieveTaskTemplates from '@salesforce/apex/CDdTaskTrackingController.retrieveTaskTemplates';
import checkForActiveTasks from '@salesforce/apex/CDdTaskTrackingController.checkForActiveTasks';
import RECORDTYPEID_FIELD from '@salesforce/schema/Case.RecordTypeId';
import CASE_FIELD from '@salesforce/schema/Case.Id';
import SERVICE_TASK_OBJECT from '@salesforce/schema/Service_Task__c';
import ST_CASE_FIELD from '@salesforce/schema/Service_Task__c.Case__c';
import ST_EST_HANDLE_TIME_FIELD from '@salesforce/schema/Service_Task__c.Estimated_Handle_Time_Minutes__c';
import ST_NEXT_TASK_FIELD from '@salesforce/schema/Service_Task__c.Next_Task__c';
import ST_START_TIME_FIELD from '@salesforce/schema/Service_Task__c.Start_Date_Time__c';
import ST_OWNER_ID_FIELD from '@salesforce/schema/Service_Task__c.OwnerId';
import ST_NAME_FIELD from '@salesforce/schema/Service_Task__c.Name';
import ST_STATUS_FIELD from '@salesforce/schema/Service_Task__c.Status__c';
import ST_TIME_ENTRY_START_FIELD from '@salesforce/schema/Service_Task__c.Time_Entry_Start__c';
import ST_TASKTYPE_FIELD from '@salesforce/schema/Service_Task__c.Task_Type__c';
import SF_TASK_ID_FIELD from '@salesforce/schema/Service_Task__c.Id';
import ST_NOTES from '@salesforce/schema/Service_Task__c.Notes__c';
import ST_TEAM_NAME from '@salesforce/schema/Service_Task__c.Team_Name__c';
import ServiceTaskStatusInProgress from '@salesforce/label/c.ServiceTaskStatusInProgress';
import ServiceTaskStatusCompleted from '@salesforce/label/c.ServiceTaskStatusCompleted';
import ServiceTaskStatusPaused from '@salesforce/label/c.ServiceTaskStatusPaused';
import ServiceTaskStatusCancelled from '@salesforce/label/c.ServiceTaskStatusCancelled';
const caseFields = [RECORDTYPEID_FIELD, CASE_FIELD];

const TASKTYPEFIELDS = [
    SF_TASK_ID_FIELD,
    ST_CASE_FIELD, 
    ST_EST_HANDLE_TIME_FIELD,
    ST_NEXT_TASK_FIELD,
    ST_START_TIME_FIELD, 
    ST_OWNER_ID_FIELD, 
    ST_NAME_FIELD,
    ST_STATUS_FIELD,
    ST_TIME_ENTRY_START_FIELD,
    ST_TASKTYPE_FIELD,
    ST_NOTES,
    ST_TEAM_NAME, 
]
let i=0;

export default class LwcDDTaskTrackingApp extends LightningElement {
    @api recordId; // Case Id
    @track taskId; // Active Tasktemplate ID
    @track ready = false; 
    @track caseRecordTypeId = ''; 
    @track taskTemplateOptions;
    @track teamTemplateOptions;
    @track items = [];
    @track teamItems = [];
    @track selectedTeam = 'All';
    teamValue = 'All';
    @track isNextTask = false;
    @track disableCreateTaskButton = true;
    @track displayCreateScreen = true; 
    @track caseId; 
    @track taskTypeName = ''; 
    @track status = '';
    @track startDate = '';
    @track nextTask = ''; 
    @track newTaskValue = '';
    @track nextTaskValue = '';
    @track inProgressNextTaskValue = '';
    @track taskPaused = false; 
    @track task; 
    @track popUpCancellationConfirmation = false; 
    @track newNotes = '';
    @track nextTaskOptions = [];
    @track nextTaskScreen = false;
    @track backDisplayCreateScreen = false;
    taskTemplateMap = new Map();
    
    newTaskObject;
    wiredCheckActiveTasks;
    wiredActiveTask; 
    
    @wire(getRecord, { recordId: '$recordId', fields: caseFields }) 
    currCase;
    
    get currCaseRecordTypeId() {
        this.caseRecordTypeId = getFieldValue(this.currCase.data, RECORDTYPEID_FIELD);
        this.caseId = getFieldValue(this.currCase.data, CASE_FIELD);
        return getFieldValue(this.currCase.data, RECORDTYPEID_FIELD);
    }
    
    // Get list of active Task templates for the current case. 
    // and populate the drop downs to select the values. 
    @wire(retrieveTaskTemplates, {caseRecordTypeId: '$caseRecordTypeId', selectedTeam:'$selectedTeam'})
    wiredretrieveTaskTemplates({ error, data }) {
        if (data) {
            this.taskTemplateOptions = data; 
            this.items = [];
            console.log("retrieveTaskTemplates new :: ", JSON.stringify(data));
            for(i=0; i<data.length; i++) {
                this.items = [...this.items ,{value: data[i].Id , label: data[i].Name}];
                this.taskTemplateMap.set(data[i].Id, data[i]);
            }
            
            if(this.nextTaskScreen){
                this.getNextTaskOptions();
            }                
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.taskTemplateOptions = undefined;
        }
    }

    // Get list of active Team details from templates for the current case. 
    // and populate the drop downs to select the values. 
    @wire(retrieveTeamDetails, {caseRecordTypeId: '$caseRecordTypeId'})
    wiredretrieveTeamDetails({ error, data }) {
        if (data) {
            this.teamTemplateOptions = data;
            for(i=0; i<data.length; i++) {
                this.teamItems = [...this.teamItems ,{value: data[i] , label: data[i]}];
            } 
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.teamTemplateOptions = undefined;
        }
    }

    // check if there are any active tasks. If there are active tasks, hide create task div and show the in progress div. 

    @wire(checkForActiveTasks, {caseId: '$caseId'})
    wiredCheckForActiveTasks(value) {
        this.wiredCheckActiveTasks = value;
        const{data,error} = value;
        if (data) {
            if(data !== 'No values available'){
                this.taskId = data; 
                this.displayCreateScreen = false; 
                this.error = undefined;
            } 
        } else if (error) {
            this.taskId = ''; 
            this.displayCreateScreen = true; 
            this.error = error;
            this.taskTemplateOptions = undefined;
        }
        
    }
    
    // get the task that is in progress 
    @wire(getRecord, { recordId: '$taskId', fields: TASKTYPEFIELDS })
    wiredTask(value){
        this.wiredActiveTask = value;
        const{data,error} = value; 
        if(data) {
            this.task = data; 
            this.error = undefined; 
            if(getFieldValue(this.task, ST_TEAM_NAME) !== null && !this.backDisplayCreateScreen){
                this.selectedTeam = getFieldValue(this.task, ST_TEAM_NAME);
                this.nextTaskScreen = true;
            }
            if (getFieldValue(this.task, ST_STATUS_FIELD) === ServiceTaskStatusInProgress) {
                this.taskPaused = true; 
            } else {
                this.taskPaused = false; 
            }
            this.inProgressNextTaskValue = getFieldValue(this.task, ST_NEXT_TASK_FIELD);
            this.newNotes = getFieldValue(this.task,ST_NOTES);
            this.getNextTaskOptions(); 
        } else if (error) {
            this.error = error; 
        }
        this.ready = true;
    }
    

    get disableTeamSelector(){
        return ( this.teamItems.length > 1 ? false: true );
    }
   
    // create next task Options array. Remove the Current Task from the array so that the user is not able to select 
    // the current task. 
    getNextTaskOptions() {
        // this.items = [...this.items, {value: null , label: '-None-'}];
        if(this.taskTemplateOptions !== undefined) {
            this.nextTaskOptions = [];
            this.nextTaskOptions = [...this.nextTaskOptions, {value: null , label: '-None-'}];
            for(i=0; i<this.taskTemplateOptions.length; i++) {
                if(getFieldValue(this.task, ST_NAME_FIELD) !== this.taskTemplateOptions[i].Name) {
                    this.nextTaskOptions = [...this.nextTaskOptions ,{value: this.taskTemplateOptions[i].Id , label: this.taskTemplateOptions[i].Name}];
                }
            } 
        }
    }

    handleTaskTemplateChange(event) {
        this.newTaskObject = this.taskTemplateMap.get(event.detail.value);
        this.disableCreateTaskButton = false;
    }

    handleTeamTemplateChange(event) { console.log("handleTeamTemplateChange :: ", event.detail.value);
        this.selectedTeam = event.detail.value;
    }
    
    handleNextTaskChange(event) {
        this.nextTaskValue = this.taskTemplateMap.get(event.detail.value);
    }
    
    handleInProgressNextTaskChange(event) {
        if(event.detail.value === null) {
            this.inProgressNextTaskValue = null;
        } else {
            this.inProgressNextTaskValue = this.taskTemplateMap.get(event.detail.value).Id;
        }
        
    }
    
    startNewTask() {
        // this method creates a new task based on the current task that is selected. 

        if(!this.disableCreateTaskButton) {
            this.disableCreateTaskButton = true;    
            var date = new Date();
            var isoDate = date.toISOString();
            const fields = {};

            fields[ST_CASE_FIELD.fieldApiName] = this.recordId;
            fields[ST_EST_HANDLE_TIME_FIELD.fieldApiName] = this.newTaskObject.Estimated_Handle_Time_minutes__c;
            fields[ST_START_TIME_FIELD.fieldApiName] = isoDate;
            fields[ST_OWNER_ID_FIELD.fieldApiName] = currUserId;
            fields[ST_NAME_FIELD.fieldApiName] = this.newTaskObject.Name;
            fields[ST_STATUS_FIELD.fieldApiName] = ServiceTaskStatusInProgress;
            fields[ST_TIME_ENTRY_START_FIELD.fieldApiName] = isoDate;
            fields[ST_TASKTYPE_FIELD.fieldApiName] = this.newTaskObject.Id;
            if(this.selectedTeam !== 'All' && this.selectedTeam !== null){
                fields[ST_TEAM_NAME.fieldApiName] = this.selectedTeam;
            }
            if(this.nextTaskValue) {
                fields[ST_NEXT_TASK_FIELD.fieldApiName] = this.nextTaskValue.Id;
            }
            
            const newServicetask = {apiName: SERVICE_TASK_OBJECT.objectApiName, fields};
            
            createRecord(newServicetask)
            .then(newTask => {
                this.newTaskValue = newTask.id;
                this.taskId = newTask.id;
                this.displayCreateScreen = false; 
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'New Task created',
                        variant: 'Success',
                    }),
                );
                refreshApex(this.wiredCheckActiveTasks);
                 // Update the Flag to isNextTask
                this.isNextTask = true;
                
                this.getNextTaskOptions(); 
            })
            .catch(error => {
                // how to propogate error messages to the user? 
                this.disableCreateTaskButton = false; 
                var errorMessage = '';
                if(Array.isArray(error.body.output.errors)) {
                    i = 0;
                    for (i = 0; i < error.body.output.errors.length; i ++) {
                        errorMessage = error.body.output.errors[i].message + "\n";    
                    }
                } else {
                    errorMessage = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Creating record',
                        message: errorMessage,
                        variant: 'error',
                        mode: 'sticky',
                    }),
                );
            });
        }
        
    }
    
    handleNotesChange(evt) {
        this.newNotes = evt.target.value;
    }
    
    pauseTask() {
        this.setNewStatus(ServiceTaskStatusPaused, 'Task Paused', 'Error Updating Record');
    }
    
    resumeTask() {
        this.setNewStatus(ServiceTaskStatusInProgress, 'Task Resumed', 'Error Updating Record');
    }

    completeTask() {  
        this.setNewStatus(ServiceTaskStatusCompleted, 'Task Completed', 'Error Updating Record');
        this.newTaskObject = null;
    }

    cancelTask() {
        this.openmodal();
    }
    
    openmodal() {
        this.popUpCancellationConfirmation = true; 
    }
    
    closeModal() {
        this.popUpCancellationConfirmation = false;
    } 
    
    saveMethod() {
        this.setNewStatus(ServiceTaskStatusCancelled, 'Task Cancelled', 'Error Updating Record');
        this.closeModal();
    }
    
    setNewStatus (newStatus, successMessage, errorTitle) {
        this.successfulUpdate = false; 
        const fields = {}; 
        var nextTask; 
        fields[SF_TASK_ID_FIELD.fieldApiName] = getFieldValue(this.task, SF_TASK_ID_FIELD);
        fields[ST_STATUS_FIELD.fieldApiName] = newStatus;
        fields[ST_NOTES.fieldApiName] = this.newNotes; 
        fields[ST_NEXT_TASK_FIELD.fieldApiName] = this.inProgressNextTaskValue;
        nextTask = this.inProgressNextTaskValue;            
        const updateServiceTask = {apiName: SERVICE_TASK_OBJECT.apiName, fields};
        
        updateRecord(updateServiceTask) 
        // eslint-disable-next-line consistent-return
        .then(() => {
            this.successfulUpdate = true; 
            if(newStatus === ServiceTaskStatusCancelled ) {
                this.displayCreateScreen = true;
                this.backDisplayCreateScreen = true;
                this.selectedTeam = 'All';
            } 
            if (newStatus === ServiceTaskStatusCompleted && nextTask === null) {
                this.displayCreateScreen = true; 
                this.backDisplayCreateScreen = true;
                this.selectedTeam = 'All';
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: successMessage,
                    variant: 'Success',
                }),
            );
            if (newStatus === ServiceTaskStatusCompleted && nextTask !== null) {
                this.displayCreateScreeen = false;
                this.inProgressNextTaskValue = null; 
                refreshApex(this.wiredCheckActiveTasks);    
                return refreshApex(this.wiredActiveTask);
            }

        })
        .catch(error => {
            var errorMessage = '';
            this.successfulUpdate = false;
            if(Array.isArray(error.body.output.errors)) {
                i = 0;
                for (i = 0; i < error.body.output.errors.length; i ++) {
                    errorMessage = error.body.output.errors[i].message + "\n";    
                }
            } else {
                errorMessage = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: errorTitle,
                    message: errorMessage,
                    variant: 'error',
                    mode: 'sticky',
                }),
            );
        });
    }
}