/**
* @author: Cory Bartholomew (ATG)
* @date 04/2021
* @description: Helper class for the OrderProduct Trigger Handler.  Logic to support the CPQ Project
*/
public with sharing class CDdOrderProductTriggerHelper {
//TODO:  Placeholder for Q2C-452
     /**
 * @author:      Cory Bartholomew (ATG)
     * @date:        2021-02
     * @description: Utility method to update a list of SObject and handle the errors with logging
     */

     public static Id POST_SALE_OPP_RT = CDdSchemaUtils.OPPORTUNITY_RT.postSaleId();
     public static Id POST_SALE_CASE_RT = CDdSchemaUtils.CASE_RT.postSaleActivationsId();
     public static Id ACCOUNT_MARKETPLACE_RT = CDdSchemaUtils.ACCOUNT_RT.prospectId();
     public static Id ACCOUNT_ENT_MARKETPLACE_RT = CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId();
     public static Id ACCOUNT_DRIVE_RT = CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId();
     public static Id ACCOUNT_ENT_DRIVE_RT = CDdSchemaUtils.ACCOUNT_RT.enterpriseDriveId();
     public static final string PRODUCT_FAMILY_MARKETPLACE_PROMOTION = 'Marketplace Promotion';
     public static final Map<String, String> COUNTRY_CODE_TO_CURRENCY = new Map<String, String> {
              'JP' => 'JPY',
              'DE' => 'EUR'
     };
     
     public static void postSaleCreateCases(List<OrderItem> orderProducts){
          if(!CDdRecursionUtils.isRunnable('CDdOrderProductTrig_CreatePostSaleCase')){
               return;
          }
          Id_Metadata__mdt postSaleQueueIdData = [SELECT Id__c FROM Id_Metadata__mdt WHERE QualifiedAPIName = 'Queue_Post_Sale_Activations'];
          BusinessHours bizHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
          
          Set<Id> orderItemIds = new Set<Id>();
          for(OrderItem orderProduct : orderProducts){
               orderItemIds.add(orderProduct.Id);              
          }
          //Read the related data, only get the rows we need.
          Map<Id, OrderItem> orderItemWithRelatedMap = new Map<Id, OrderItem>([
                    SELECT Id, OrderId, Product2Id, SBQQ__QuoteLine__r.SBQQ__StartDate__c,
                         SBQQ__QuoteLine__r.Trial_Start_Date__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c,
                         Product2.Name, Product2.Create_Post_Sale_Activation_Case__c,
                         Product2.Priority_for_Activation__c, Product2.Family, Order.Opportunity.Account.RecordTypeId, Order.Opportunity.Account.BillingCountryCode, 
                         Order.AccountId, Order.OpportunityId, Order.Opportunity.AccountId, Order.Opportunity.Decision_Maker__c,
                         Order.Opportunity.Notes__c, Order.Opportunity.OwnerId, Order.Opportunity.RecordTypeId,Order.Opportunity.Bulk_Activation__c 
                         FROM OrderItem
                    WHERE Id IN :orderItemIds AND Product2.Create_Post_Sale_Activation_Case__c = true 
                    AND Order.Opportunity.Bulk_Activation__c = false
          ]);
          
          List<Case> postSaleCases = new List<Case>();
          List<OrderItem> orderProductsToUpdate = new List<OrderItem>();
          for(OrderItem orderItemWithRelatedData : orderItemWithRelatedMap.values()){
               if((orderItemWithRelatedData.Product2Id != null ) && 
                    (orderItemWithRelatedData.OrderId != null) && 
                    (orderItemWithRelatedData.Order.OpportunityId != null) &&
                    (orderItemWithRelatedData.Order.Opportunity.AccountId != null)) 
               {
                    //BZAP-11845 on Create Post sale Cases for Accounts with the correct record type
                    Id accountRecordType = orderItemWithRelatedData.Order.Opportunity.Account.RecordTypeId;
                    if (createPostSaleCasesforAccountRT(accountRecordType)) 
                    {
                         if ((orderItemWithRelatedData.Order.Opportunity.RecordTypeId == POST_SALE_OPP_RT) || 
                              (!CDdMxSxConstants.ENABLE_MXSX_FRAMEWORK && orderItemWithRelatedData.Product2.Name.contains('Storefront Package'))) 
                         {
                              postSaleCases.add(createPostSaleCase(orderItemWithRelatedData, postSaleQueueIdData.Id__c, bizHours.Id));
                              orderProductsToUpdate.add(new OrderItem(Id = orderItemWithRelatedData.Id, Post_Sale_Case_Created__c = true));                         
                         }
                    }                  
               }
          }

          if(!postSaleCases.isEmpty()){
               Database.DMLOptions dmo = new Database.DMLOptions();
               dmo.assignmentRuleHeader.useDefaultRule = false;
               Database.insert(postSaleCases, dmo);
               update orderProductsToUpdate;
          }
     }

     public static void postSaleActivateOrders(List<OrderItem> orderProducts,  Map<Id, OrderItem> oldMap){
          Set<Id> orderIds = new Set<Id>();
          for(OrderItem orderProduct : orderProducts){
               if(orderProduct.SBQQ__Status__c == 'Activated' && oldMap.get(orderProduct.Id).SBQQ__Status__c != 'Activated'){
                    orderIds.add(orderProduct.OrderId);
               }
          }
          if(!orderIds.isEmpty()){
               List<Order> orders = [
                    SELECT Id, Status, Opportunity.RecordTypeId,
                         (SELECT Id, Product2.Create_Post_Sale_Activation_Case__c, SBQQ__Status__c FROM OrderItems)
                    FROM Order 
                    WHERE Id IN :orderIds AND Opportunity.RecordTypeId = :POST_SALE_OPP_RT
               ];

               Set<Id> ordersIdsToActivate = new Set<Id>();
               for(Order order : orders){
                    Integer activatedCount = 0;
                    Integer eligibleCount = 0;
                    for(OrderItem orderProduct : order.OrderItems){
                         if(orderProduct.SBQQ__Status__c == 'Activated'){
                              activatedCount ++;
                         }
                         if(orderProduct.Product2.Create_Post_Sale_Activation_Case__c){
                              eligibleCount++;
                         }
                    }
                    
                    if(
                         (activatedCount == eligibleCount) ||
                         (activatedCount == order.OrderItems.size())
                    ){
                         ordersIdsToActivate.add(order.Id);   
                    }
               }

               if(!ordersIdsToActivate.isEmpty()){
                    CDdOrderTriggerHelper.activateOrdersFuture(ordersIdsToActivate);
               }
          }

     }

     public static Case createPostSaleCase(OrderItem orderProduct, Id postSaleQueueId, Id bizHoursId){
          Case postSaleCase = new Case();
          postSaleCase.BusinessHoursId = bizHoursId;
          postSaleCase.AccountId = orderProduct.Order.Opportunity.AccountId;
          postSaleCase.Activation_Notes__c = orderProduct.Order.Opportunity.Notes__c;
          postSaleCase.Order_Product__c =  orderProduct.Id;
          postSaleCase.ContactId = orderProduct.Order.Opportunity.Decision_Maker__c;
          postSaleCase.Decision_Maker__c = orderProduct.Order.Opportunity.Decision_Maker__c;
          postSaleCase.Opportunity_Name__c = orderProduct.Order.OpportunityId;
          postSaleCase.Origin = 'Closed Won Opportunity';
          postSaleCase.OwnerId = postSaleQueueId;
          postSaleCase.Priority = orderProduct.Product2.Priority_for_Activation__c;
          postSaleCase.ProductId = orderProduct.Product2Id;
          postSaleCase.RecordTypeId = POST_SALE_CASE_RT;
          postSaleCase.Op_Owner__c =  orderProduct.Order.Opportunity.OwnerId;
          postSaleCase.Product_Name_Text__c = orderProduct.Product2.Name;
          postSaleCase.Product_Family_Text__c = orderProduct.Product2.Family;
          //Set Due Date BZAP-11886
          //BZAP-13317 new Due Date logic
          if (orderProduct.Product2.Family == PRODUCT_FAMILY_MARKETPLACE_PROMOTION) {
               if (orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c != null) {
                    if (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c != null) {
                        if (orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c <= orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c) {
                              if (orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c > Date.today().addDays(4)) {
                                   postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c.addDays(-2);
                              } else if (orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c >= Date.today()) {
                                   postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c;
                              } else {
                                   postSaleCase.Due_Date__c = Date.today();
                              }
                         } else {
                              if (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c > Date.today().addDays(4)) {
                                   postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c.addDays(-2);
                              } else if (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c >= Date.today()) {
                                   postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c;
                              } else {
                                   postSaleCase.Due_Date__c = Date.today();
                              }
                         }
                    } else {
                         if (orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c > Date.today().addDays(4)) {
                              postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c.addDays(-2);
                         } else if (orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c >= Date.today()) {
                              postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.Trial_Start_Date__c;
                         } else {
                              postSaleCase.Due_Date__c = Date.today();
                         }
                    }
               } else {
                    if (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c != null) {
                         if (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c > Date.today().addDays(4)) {
                              postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c.addDays(-2);
                         } else if (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c >= Date.today()) {
                              postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c;
                         } else {
                              postSaleCase.Due_Date__c = Date.today();
                         }
                    } else {
                         postSaleCase.Due_Date__c = Date.today().addDays(2);   //Both Trial_Start_Date__c and SBQQ__StartDate__c are null               
                    }
               }
          } else {
               if ((orderProduct.SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c != null) && 
                   (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c != null)) 
               {
                    if ((orderProduct.SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c < Date.today()) || 
                        (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c < Date.today())) 
                    {
                         postSaleCase.Due_Date__c = Date.today().addDays(2);
                    } else 
                    {
                         if (orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c <= orderProduct.SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c) {
                              postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.SBQQ__StartDate__c.addDays(2);
                         } else {
                              postSaleCase.Due_Date__c = orderProduct.SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c.addDays(2);
                         }
                    }
               } else {
                    postSaleCase.Due_Date__c = Date.today().addDays(2);   //Both SBQQ__Quote__r.Contract_Signed_Date__c and SBQQ__StartDate__c are null               
               }
          }

          return postSaleCase;
     }     

     private static boolean createPostSaleCasesforAccountRT(Id accountRT) {
          boolean createCase = false;
          if ((accountRT == ACCOUNT_DRIVE_RT) || (accountRT == ACCOUNT_ENT_DRIVE_RT) ||
               (accountRT == ACCOUNT_MARKETPLACE_RT) || (accountRT == ACCOUNT_ENT_MARKETPLACE_RT)) 
          {
               createCase = true;     
          }
          return createCase;
     }
}