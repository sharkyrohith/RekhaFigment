/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Wrapper used by lwcDdMultiSelectPicklist lwc/CDdMutliSelectPicklist code -- UI will read this wrapper to render the results
 */
 public class CDdMultiSelectPicklistWrapper {
    @Auraenabled public String dropDownLabel;
    @Auraenabled public String dropDownSubLabel;
    @Auraenabled public String pillLabel;
    @Auraenabled public String value;
    @Auraenabled public String iconSrc;
    @Auraenabled public String obj;
    @Auraenabled public String operator;

    public CDdMultiSelectPicklistWrapper() {}

    public CDdMultiSelectPicklistWrapper(Sobject obj) {
        this.obj = JSON.serialize(obj);
    }
}