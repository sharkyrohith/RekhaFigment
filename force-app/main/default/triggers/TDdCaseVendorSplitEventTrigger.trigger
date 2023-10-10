/**
 * TDdCaseVendorSplitEventTrigger
 *
 * @author      Sahil (sahil.chaudhry@doordash.com)
 * @date        08/10/2021
 * @decription  trigger for case vendor split platform event
 */
trigger TDdCaseVendorSplitEventTrigger on Case_Vendor_Split__e (after insert) {
    CDdCaseVendorSplitEventHelper.handleEvents(trigger.new);
}