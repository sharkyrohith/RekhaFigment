global class CDdCoverageCheckCtrl {
    public static final vCS__c SETTINGS = vCS__c.getInstance();
    final ApexPages.StandardController controller;
    public Account acct { get; set; }
    public String result {get;set;}
    String type;
    Lead ld;

    public CDdCoverageCheckCtrl(ApexPages.StandardController controller) {
        this.controller = controller;
        type = controller.getRecord().getSObjectType().getDescribe().getName();
    	if (type == 'Account') {
            this.acct = (Account) controller.getRecord();
        } else if (type == 'Lead') {
            this.ld = (Lead) controller.getRecord();
        }
    }

    public PageReference coverageCheckCallout() {
        //ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.INFO,'Checking Coverage..'));
        if (type == 'Account') {
            if (CDdCoverageCheckSvcV2.checkAcctCoverage(this.acct)) {
                return new PageReference('/' + String.valueOf(this.acct.Id));
            }
        } else if (type == 'Lead') {
            if (CDdCoverageCheckSvcV2.checkLeadCoverage(this.ld)) {
                return new PageReference('/' + String.valueOf(this.ld.Id));
            }
        }
        return null;
    }

    public PageReference cancel() {
        return controller.cancel();
    }

    webService static Id coverageCheck(List<Id> recordIds) {
        String sObjectType = recordIds.get(0).getSObjectType().getDescribe().getName();
        return  ( (sObjectType.equals('Account'))
                ? Database.executeBatch(new CDdAcctCoverageCheckBatch(recordIds), CDdCoverageCheckConstants.DEFAULT_BATCH_SIZE)
                : ( (sObjectType.equals('Lead'))
                        ? Database.executeBatch(new CDdLeadCoverageCheckBatch(recordIds), CDdCoverageCheckConstants.DEFAULT_BATCH_SIZE)
                        : null
                )
            );
    }
}