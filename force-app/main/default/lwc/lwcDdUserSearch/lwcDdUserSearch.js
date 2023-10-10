import { LightningElement, api } from 'lwc';

export default class LwcDdUserSearch extends LightningElement {

    @api nameSearchTerm;
    @api emailSearchTerm;
    @api profileSearchTerm;
    @api roleSearchTerm;

    handleNameSearch(event){
        console.log('searchTermVal in child'+event.detail.value);
        this.nameSearchTerm = event.detail.value;
     this.passDataToParent('nameSearchTerm', event.detail.value);
     console.log('event sent from child');
    }

    handleEmailSearch(event){
        this.emailSearchTerm = event.detail.value;
        this.passDataToParent('emailSearchTerm', event.detail.value);
    }

    handleProfileSearch(event){
        this.profileSearchTerm = event.detail.value;
        this.passDataToParent('profileSearchTerm', event.detail.value);
    }
    handleRoleSearch(event){
        this.roleSearchTerm = event.detail.value;
        this.passDataToParent('roleSearchTerm', event.detail.value);
    }

    passDataToParent(searchTerm, searchTermValue){
        console.log('searchTerm in child event'+searchTerm);
        console.log('searchTermValue in child event'+searchTermValue);
        let valueToBePassed =[];
       valueToBePassed.push({type:searchTerm, stringVal:searchTermValue});
        const selectedEvent = new CustomEvent('valueselected',{
            detail: valueToBePassed
        });
        console.log('this.valueToBePassed in child'+JSON.stringify(valueToBePassed));
        this.dispatchEvent(selectedEvent);
    }

}