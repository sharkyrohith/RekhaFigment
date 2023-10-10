/********************************************************************************************************************
 * @author Praveen
 * @date 07/14/2022
 *
 * @group Merchant Services
 *
 * @description test class for CDdMxEquipmentRequestModel.
 *
 **************************************************************************************************************************************/

public with sharing class CDdMxEquipmentRequestModel {
	public String OppId;
	public String AccountId;
	public String requestType;
	public String requestTypeId;
	public String returnReplaceComponent;
	public String tabletImei;
	public String originalTabletCaseId;
	public String printerImei;
	public String originalPrinterCaseId;
	public String reasonForReplOther;
	public String contactId;
	public String shippingType;
	public String Addressline1;
	public String Addressline2;
	public String City;
	public String State;
	public String Country;
	public String PostalCode;
	public String merchanthasWifi;
	public String IMEIObject;
	public String internalDeployment;
	public String mintOrderProtocol;
	public Boolean isLemonadeAccount;
	//public string reqTypes;
	public List<String> newProducts;
	public List<String> returnProducts;
	public String replacementReason;
}