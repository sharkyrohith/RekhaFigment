/**
* @author: Jeegar
* @date: 2019-07
* @description BZAP-4238 Custom Sort for Leads. 
    Logic: 
        owner that is not Unassigned Queue or Omni Inbound Queue.
        If owners of leads are users, use the lead with newest Recent_Qualified_Activity_Date__c(Latest Qualified Activity) as the survivor. 
        If Latest Qualified Activity are same, use newest created lead as the survivor. 
*/

global class CDdLeadSortWrapper implements Comparable{
    public Lead currLead;
    
    // Constructor
    public CDdLeadSortWrapper(Lead sLead) {
        currLead = slead;
    }
    
    // Compare leads based on the lead date.
    global Integer compareTo(Object compareTo) {
        // Cast argument to CDdLeadSortWrapper
        CDdLeadSortWrapper compareToLead = (CDdLeadSortWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        // Check if one of the lead's owner is a user or a group. 
        // Prioritize User over Group
        
        if(String.valueOf(currLead.OwnerId).substring(0,3) == '005' && 
            String.valueOf(compareToLead.currLead.OwnerId).substring(0,3) != '005') {
                returnValue = 1;
        } else if (String.valueOf(currLead.OwnerId).substring(0,3) != '005' && 
            String.valueOf(compareToLead.currLead.OwnerId).substring(0,3) == '005') {
                returnValue = -1;
        } else if (currLead.Recent_Qualified_Activity_Date__c > compareToLead.currLead.Recent_Qualified_Activity_Date__c) {
            returnValue = 1;
        } else if (currLead.Recent_Qualified_Activity_Date__c < compareToLead.currLead.Recent_Qualified_Activity_Date__c) {
            returnValue = -1;
        } else if (currLead.createdDate > compareToLead.currLead.createdDate) {
            returnValue = 1;
        } else if (currLead.createdDate < compareToLead.currLead.createdDate) {
            returnValue = -1;
        }
        
        System.debug('><> ' + returnValue); 
        return returnValue;       
    }
}