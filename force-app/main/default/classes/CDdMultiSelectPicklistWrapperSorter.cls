/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription - Sorter Class used by the 'Picklist Metadata' type of lwcDdMultiSelectPicklist component
 *               to sort values different from the sort order of the picklist metadata itself.
 */
public without sharing class CDdMultiSelectPicklistWrapperSorter implements Comparable {
    public CDdMultiSelectPicklistWrapper w;
    public String sortBy {get;set;}

    // Default sort is 'dropDownLabel'
    public CDdMultiSelectPicklistWrapperSorter(CDdMultiSelectPicklistWrapper w1) {
        w = w1;
        sortBy = 'dropDownLabel';
    }

    // Custom Sort is available (value)
    public CDdMultiSelectPicklistWrapperSorter(CDdMultiSelectPicklistWrapper w1, String s) {
        w = w1;
        sortBy = s;
    }

    // Implement the sorter
    public Integer compareTo(Object compareTo) {
        CDdMultiSelectPicklistWrapperSorter wS = (CDdMultiSelectPicklistWrapperSorter)compareTo;
        Integer returnValue = 0;

        if (sortBy == 'dropDownLabel') {
            if (w.dropDownLabel < wS.w.dropDownLabel)
                returnValue = -1;
            else if (w.dropDownLabel >= wS.w.dropDownLabel)
                returnValue = 1;
        } else if (sortBy == 'value') {
            if (w.value < wS.w.value)
                returnValue = -1;
            else if (w.value >= wS.w.value)
                returnValue = 1;
        }
        return returnValue;
    }
}