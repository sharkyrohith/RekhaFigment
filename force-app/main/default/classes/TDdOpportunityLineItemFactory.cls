/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/19/2020
*
* @group Opportunity Line Item Factory
*
* @description Opportunity Line Item Factory factory for creating test records
**************************************************************************************************************************************/
public class TDdOpportunityLineItemFactory {

	public static final Map<String, String> PRODUCT_NAME_AND_FAMILY = new Map<String, String> {
			'Online Ordering - Delivery' => 'Products',
			'Online Ordering - Pickup' => 'Products',
			'DoorDash Gift Cards' => 'Products',
			'Bulk Individual Ordering' => 'Group Cart',
			'Marketplace Catering' => 'Catering',
			'DDfB Group Cart' => 'Group Cart',
			'DoorDash Deals' => 'Promotions'
	};

	public static final Map<String, Object> DEFAULT_PRODUCT_VALUES = new Map<String, Object> {
			'Billing_Frequency__c' => 'Monthly'
	};

	public static final Map<String, Object> DEFAULT_PRICEBOOK_ENTRY_VALUES = new Map<String, Object> {
			'Commission_Rate__c' => 20.00,
			'Discount_Percentage__c' => 5.00,
			'Flat_Fee__c' => 10.00,
			'Max_Amount_From_Marketing_Percent__c' => 100.00,
			'Max_Delivery_Radius__c' => 5.00,
			'Max_Discount_Amount__c' => 10.00,
			'One_Time_Setup_Fee__c' => 100.00,
			'Order_Cart_Minimum__c' => 10.00,
			'Payment_Processing_Fee__c' => 5.00,
			'Payment_Processing_Rate__c' => 5.00,
			'Service_Fee__c' => 5.00,
			'Service_Rate__c' => 5.00,
			'Subscription_Fee__c' => 10.00
	};

	public static List<PricebookEntry> createProducts() {
		List<Product2> products = new List<Product2>();
		for (String productName : PRODUCT_NAME_AND_FAMILY.keySet()) {
			Product2 product = new Product2(Name = productName, Family = PRODUCT_NAME_AND_FAMILY.get(productName));
			for (String fieldName : DEFAULT_PRODUCT_VALUES.keySet()) {
				product.put(fieldName, DEFAULT_PRODUCT_VALUES.get(fieldName));
			}
			products.add(product);
		}

		insert products;
		return createPricebookEntries(products);
	}

	public static List<PricebookEntry> createPricebookEntries(List<Product2> products) {
		List<PricebookEntry> standardPrices = new List<PricebookEntry>();
		Id pricebookId = Test.getStandardPricebookId();
		for (Product2 currProd : products) {
			PricebookEntry pbe = new PricebookEntry(
					Pricebook2Id = pricebookId,
					Product2Id = currProd.Id,
					UnitPrice = 10000,
					IsActive = true
			);
			for (String fieldName : DEFAULT_PRICEBOOK_ENTRY_VALUES.keySet()) {
				pbe.put(fieldName, DEFAULT_PRICEBOOK_ENTRY_VALUES.get(fieldName));
			}
			standardPrices.add(pbe);
		}

		insert standardPrices;
		return standardPrices;
	}

	public static List<OpportunityLineItem> createOpportunityProducts(Id opportunityId) {
		List<PriceBookEntry> pbes = [
				SELECT Id, IsActive, IsArchived, IsDeleted, Name, Pricebook2Id,
						Product2Id, ProductCode, UnitPrice, UseStandardPrice,
						Product2.Name, Product2.Family
				FROM PricebookEntry
				WHERE Name IN :PRODUCT_NAME_AND_FAMILY.keySet()];

		return createOpportunityProducts(opportunityId, pbes);
	}

	public static List<OpportunityLineItem> createOpportunityProducts(Id opportunityId, List<PricebookEntry> priceBookEntries) {
		List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
		for (PriceBookEntry pbEntry : priceBookEntries ) {
			OpportunityLineItem oli = new OpportunityLineItem();
			oli.OpportunityId = opportunityId;
			oli.PricebookEntryId = pbEntry.Id;
			oli.Product2Id = pbEntry.Product2Id;
			oli.Quantity = 1;
			oli.UnitPrice = 1;
			if ('Promotions'.equals(pbEntry.Product2.Family)) {
				oli.Start_Date__c = System.today();
				oli.End_Date__c = System.today();
				oli.Marketing_Only_Commission__c  = 10.00;
			}
			oppLineItems.add(oli);
		}
		return oppLineItems;
	}
}