public class VDeliveryTriggerHandler {
	
    public void onBeforeInsert(List<Delivery__c> newList){
        
        List<Decimal> idList = new List<Decimal>();
        List<String> mxIdList = new List<String>();

        
        for (Delivery__c curDelivery : newList){
            if(curDelivery.MerchantNoFF__c!=null){
                mxIdList.add(curDelivery.MerchantNoFF__c);
            }
            if(curDelivery.CustomerNo__c!=null){
                idList.add(curDelivery.CustomerNo__c);                    
            }
           	if(curDelivery.DasherNo__c!=null){
                idList.add(curDelivery.DasherNo__c);                    
            }
        }
        
        List<Account> accountList = new List<Account>();
        if (idList.size() > 0){
            accountList = [SELECT Id, Restaurant_ID__c, CustomerNo__pc, DasherNo__pc
                           FROM Account
                           WHERE Restaurant_ID__c IN :mxIdList
                           OR CustomerNo__pc IN :idList
                           OR DasherNo__pc IN :idList];
        }
        
        if (accountList.size() > 0){
            for (Delivery__c curDelivery : newList){
                if(curDelivery.MerchantNoFF__c!=null){
                    for (Account curAccount : accountList){
                        if (curAccount.Restaurant_ID__c!=null){
                            if (curAccount.Restaurant_ID__c.equals(curDelivery.MerchantNoFF__c)){
                            	curDelivery.Merchant__c = curAccount.Id;
                        	}
                        }
                    }
                }
                if(curDelivery.CustomerNo__c!=null){
                    for (Account curAccount : accountList){
                        if (curAccount.CustomerNo__pc != null){
                            if (curAccount.CustomerNo__pc == curDelivery.CustomerNo__c){
                                curDelivery.Customer__c = curAccount.Id;
                            }
                        } 
                    }
                }
                if(curDelivery.DasherNo__c != null){
                    for (Account curAccount : accountList){
                        if (curAccount.DasherNo__pc != null){
                        	if (curAccount.DasherNo__pc == curDelivery.DasherNo__c){
                            	curDelivery.Dasher__c = curAccount.Id; 
                            }
                        }
                    }
                }
            }
        }
            
    }
    
    public void onBeforeUpdate(Map<Id,Delivery__c> newMap, Map<Id,Delivery__c> oldMap){
        
        List<Delivery__c> deliveryList = new List<Delivery__c>();
        
        for (Id curId : newMap.keySet()){
            
            Delivery__c newDelivery = newMap.get(curId);
            Delivery__c oldDelivery = oldMap.get(curId);
            
            if ((newDelivery.MerchantNo__c != oldDelivery.MerchantNo__c) ||
               (newDelivery.CustomerNo__c != oldDelivery.CustomerNo__c) ||
                (newDelivery.DasherNo__c != oldDelivery.DasherNo__c)) {
                    deliveryList.add(newDelivery);
                }
        }
        
        if (deliveryList.size() > 0){
            
            List<Decimal> idList = new List<Decimal>();
            List<String> mxIdList = new List<String>();
        
            for (Delivery__c curDelivery : deliveryList){
                if(curDelivery.MerchantNoFF__c != null){
                    mxIdList.add(curDelivery.MerchantNoFF__c);
                }
                if(curDelivery.CustomerNo__c != null){
                    idList.add(curDelivery.CustomerNo__c);                    
                }
                if(curDelivery.DasherNo__c != null){
                    idList.add(curDelivery.DasherNo__c);                    
                }
            }
            
            List<Account> accountList = new List<Account>();
            if (idList.size() > 0){
                accountList = [SELECT Id, Restaurant_ID__c, CustomerNo__pc, DasherNo__pc
                               FROM Account
                               WHERE Restaurant_ID__c IN :mxIdList
                               OR CustomerNo__pc IN :idList
                               OR DasherNo__pc IN :idList];
            }
            
            if(accountList.size() > 0){
                for (Delivery__c curDelivery : deliveryList){
                    if(curDelivery.MerchantNoFF__c != null){
                        for (Account curAccount : accountList){
                            if (curAccount.Restaurant_ID__c != null){
                                if (curAccount.Restaurant_ID__c.equals(curDelivery.MerchantNoFF__c)){
                                    curDelivery.Merchant__c = curAccount.Id;
                                }
                            }
                        }
                    }
                    if(curDelivery.CustomerNo__c != null){
                        for (Account curAccount : accountList){
                            if (curAccount.CustomerNo__pc != null){
                                if (curAccount.CustomerNo__pc == curDelivery.CustomerNo__c){
                                    curDelivery.Customer__c = curAccount.Id;
                                }
                            }
                        }
                    }
                    if(curDelivery.DasherNo__c != null){
                        for (Account curAccount : accountList){
                            if (curAccount.DasherNo__pc != null){
                                if (curAccount.DasherNo__pc == curDelivery.DasherNo__c){
                                    curDelivery.Dasher__c = curAccount.Id;
                                }
                            }
                        }
                    }
                }
            }
        
    }
            }
                
    
}