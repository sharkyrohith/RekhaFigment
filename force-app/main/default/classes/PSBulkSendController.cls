public with sharing class PSBulkSendController {

    // The entire payload that gets serialized as JSON to send
    // to the PactSafe API.
    public class PSBulkSendPayload {
        public List<String> contracts = new List<String>();
        public List<PSRequestData> requestData = new List<PSRequestData>();
        public PSRequest request = new PSRequest();
        // 8/5/20 - Rather than doing a look up on the user's email,
        // we will create a dedicated bulk send PS user account
        // with a custom reply_to email address (provided in the PSRequest).
        // public String senderEmail = '';
    }

    // The base request of each child request, which holds the primary settings.
    public class PSRequest {
        public String name = '';
        public Boolean signing_order = true;
        public Map<String, String> custom_data = new Map<String, String>();
        public String expiration_time = '';
        public String reply_to = '';
        public Boolean automated_request_reminders = true;
    }

    // The custom_data that will be added to the request.
    public class PSCustomData {
        public Map<String, String> custom_data = new Map<String, String>();
    }

    // The request data for each opportunity.
    public class PSRequestData {
        public String opportunityId;
        public String name;
        public List<PSRequestSigner> signers;
        public PSRequestData(String opportunityId, String name, List<PSRequestSigner> signers) {
            this.opportunityId = opportunityId;
            this.name = name;
            this.signers = signers;
        }
    }

    // The data for a single signer.
    public class PSRequestSigner {
        public String signer_id;
        public List<String> personas;
        public Boolean supporting_files_access;
        public PSSignerAttributes signer;
        public PSSignerSendingOptions send_to;
        public PSRequestSigner(String signer_id, List<String> personas, PSSignerAttributes signer, PSSignerSendingOptions send_to) {
            this.signer_id = signer_id;
            this.personas = personas;
            this.supporting_files_access = true;
            this.signer = signer;
            this.send_to = send_to;
        }
    }

    // The attributes that get tied to a single signer.
    public class PSSignerAttributes {
        public String company_name;
        public String title;
        public String email;
        public PSAdditionalSignerAttributes additional_attributes;
        public PSSignerAttributes(String company_name, String title, String email, PSAdditionalSignerAttributes additional_attributes) {
            this.company_name = company_name;
            this.title = title;
            this.email = email;
            this.additional_attributes = additional_attributes;
        }
    }

    // The additional attributes that will get added to
    // a single signer's signer attributes.
    public class PSAdditionalSignerAttributes {
        public String first_name;
        public String last_name;
        public String mobile_number;
        public PSAdditionalSignerAttributes(String first_name, String last_name, String mobile_number) {
            this.first_name = first_name;
            this.last_name = last_name;
            this.mobile_number = mobile_number;
        }
    }

    // The sending options for a signer.
    public class PSSignerSendingOptions {
        public Boolean mobile_number = true;
        public Boolean email = true;
    }

    // The PactSafe API response held in a class
    // to serialize as data to return to the Lightning Web Component.
    public class PSAPIResponse {
        public String message;
        public Boolean success;
    }

    public static String getExpirationGmtTime() {
        Datetime now = Datetime.now().addDays(14);
        return now.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    // PactSafe contracts are stored in custom metadata type for easier
    // management by DoorDash internally and PactSafe employees
    @AuraEnabled(cacheable=true)
    public static List<PactSafe_Bulk_Send_Contract__mdt> getBulkSendcontracts() {
        return [
            SELECT Label, Contract_ID__c, Auto_Expires__c, Automated_Reminders__c
            FROM PactSafe_Bulk_Send_Contract__mdt
        ];
    }

    // Gridbuddy will return provide us a list of opportunity IDs that
    // we'll use to retrieve specific opportunities data.
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(String oppIds) {
        List<String> listOpIds = oppIds.split(',');
        return [
            SELECT Id, Name, StageName, Account.Name, Decision_Maker__r.Email, Decision_Maker__r.FirstName, Decision_Maker__r.LastName, Decision_Maker__r.Title, Decision_Maker__r.MobilePhone, Owner.Email, Owner.CompanyName, Owner.FirstName, Owner.LastName, Owner.Title, Owner.DID_Phone_Number__c, Parent_Opportunity__r.Name
            FROM Opportunity
            WHERE Id IN :listOpIds AND Parent_Opportunity__r.Name != null
        ];
    }

    // This could technically be consolidated into the method above
    // but we keep them separated to prevent stale data from being used.
    // Gridbuddy will return provide us a list of opportunity IDs that
    // we'll use to retrieve specific opportunities data.
    public static List<Opportunity> getOpportunitiesData(String oppIds) {
        List<String> listOpIds = oppIds.split(',');
        return [
            SELECT Id, Name, Account.Name, StageName, Decision_Maker__r.Email, Decision_Maker__r.FirstName, Decision_Maker__r.LastName, Decision_Maker__r.Title, Decision_Maker__r.MobilePhone, Owner.Email, Owner.CompanyName, Owner.FirstName, Owner.LastName, Owner.Title, Owner.DID_Phone_Number__c, Parent_Opportunity__r.Name
            FROM Opportunity
            WHERE Id IN :listOpIds
        ];
    }

    // The custom_data that will be stored on the PactSafe activity
    // comes from a custom metadata type that is managed within
    // Salesforce rather than code.
    public static PSCustomData getCustomDataObjects() {
        PSCustomData psCustomData = new PSCustomData();
        for (PactSafe_Bulk_Send_Data_Mapping__mdt customDataObj : [SELECT Label, DeveloperName, Render_Data_Relationship__c FROM PactSafe_Bulk_Send_Data_Mapping__mdt] ) {
            psCustomData.custom_data.put(customDataObj.DeveloperName, customDataObj.Render_Data_Relationship__c);
        }
        return psCustomData;
    }

    // The PactSafe access token is encrypted and stored within
    // a Salesforce custom metadata type.
    public static String getPsAccessToken() {
        List<PactSafe_Bulk_Send_Settings__mdt> customMetadata = [SELECT Label, Bulk_Send_API_Key__c FROM PactSafe_Bulk_Send_Settings__mdt WHERE Bulk_Send_API_Key__c != null LIMIT 1];
        if (customMetadata.size() > 0) {
            return customMetadata[0].Bulk_Send_API_Key__c;
        } else {
            return '';
        }
    }

    // The PactSafe API endpoint is stored in a custom metadata
    // to allow for testing across environments and managability
    // outside of the code.
    public static String getPsAPIEndpoint() {
        List<PactSafe_Bulk_Send_Settings__mdt> endpointMetaData = [SELECT Label, Endpoint__c FROM PactSafe_Bulk_Send_Settings__mdt WHERE Endpoint__c != null LIMIT 1];
        if (endpointMetaData.size() > 0) {
            return endpointMetaData[0].Endpoint__c;
        } else {
            return '';
        }
    }

    // The PactSafe payload is generated with the data from the opportunities
    // along with any other necessary information. This requires opportunity ids
    // and contract IDs to work correctly.
    public static String pactSafeJSONPayload(String oppIds, String contractIds, Boolean contractExpires, Boolean automatedRequestReminders) {
        List<Opportunity> opportunityData = getOpportunitiesData(oppIds);
        if (opportunityData.isEmpty()) {
            return null;
        }

        PSCustomData psCustomData = getCustomDataObjects();

        PSRequest request = new PSRequest();
        request.custom_data = psCustomData.custom_data;
        request.automated_request_reminders = automatedRequestReminders;

        if (contractExpires) {
            request.expiration_time = getExpirationGmtTime();
        }

        PSBulkSendPayload payloadRoot = new PSBulkSendPayload();
        payloadRoot.contracts.add(contractIds);
        payloadRoot.request = request;

        for (Opportunity opty : opportunityData) {
            PSSignerSendingOptions sending_options = new PSSignerSendingOptions();

            // Merchant signer
            List<String> merchantPersona = new List<String>();
            merchantPersona.add('Merchant');
            PSAdditionalSignerAttributes merchantAdditionalAttributes = new PSAdditionalSignerAttributes(opty.Decision_Maker__r.FirstName, opty.Decision_Maker__r.LastName, opty.Decision_Maker__r.MobilePhone);
            PSSignerAttributes merchantSignerAttributes = new PSSignerAttributes(opty.Account.Name, opty.Decision_Maker__r.Title, opty.Decision_Maker__r.Email, merchantAdditionalAttributes);
            PSRequestSigner merchantSigner = new PSRequestSigner(opty.Decision_Maker__r.Email, merchantPersona, merchantSignerAttributes, sending_options);

            // DoorDash opty owner signer
            // List<String> doordashPersona = new List<String>();
            // doordashPersona.add('DoorDash');
            // PSAdditionalSignerAttributes ownerAdditionalAttributes = new PSAdditionalSignerAttributes(opty.Owner.FirstName, opty.Owner.LastName, opty.Owner.DID_Phone_Number__c);
            // PSSignerAttributes ownerSignerAttributes = new PSSignerAttributes(opty.Owner.CompanyName, opty.Owner.Title, opty.Owner.Email, ownerAdditionalAttributes);
            // PSRequestSigner doorDashSigner = new PSRequestSigner(opty.Owner.Email, doordashPersona, ownerSignerAttributes, sending_options);

            // payloadRoot.senderEmail = opty.Owner.Email;
            payloadRoot.request.reply_to = Opty.Owner.Email;

            // Create a list of all signers for the opportunity
            List<PSRequestSigner> allSigners = new List<PSRequestSigner>();
            allSigners.add(merchantSigner);
            // allSigners.add(doorDashSigner);

            // Create request data for the opportunity and add to the payload
            PSRequestData optyRequestData = new PSRequestData(opty.id, opty.Name, allSigners);
            payloadRoot.requestData.add(optyRequestData);
        }

        String jsonOutput = JSON.serialize(payloadRoot);
        return jsonOutput;
    }

    @future
    public static void updateParentSentDate(String oppIds) {
        try {
            List<String> listOpIds = oppIds.split(',');
            Date now = Date.today();
            String firstId = listOpIds[0];
            if (listOpIds.size() > 0) {
                Opportunity childRecord = [SELECT Id, Parent_Opportunity__r.Id FROM Opportunity WHERE Id = :firstId LIMIT 1];
                Opportunity parentRecord = [SELECT Id, Docusign_Sent__c FROM Opportunity WHERE Id = :childRecord.Parent_Opportunity__r.Id LIMIT 1];
                parentRecord.Docusign_Sent__c = now;
                update parentRecord;
            }
        } catch(DMLException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
    }

    // The processRequest method is invoked by the Lightning Web component
    // with the associated information to handle getting the access token,
    // generating the payload, and then sending to the PactSafe API.
    @AuraEnabled
    public static string processRequest(String oppIds, String contractIds, Boolean selectedContractExpires, Boolean automatedRequestReminders) {
        // Retrieve the access token from custom metadata.
        String accessToken = getPsAccessToken();

        // Generated the JSON payload to send to PactSafe.
        String optyPayload = pactSafeJSONPayload(oppIds, contractIds, selectedContractExpires, automatedRequestReminders);

        String psEndpoint = getPsAPIEndpoint();

        // Handle the HTTP request.
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(psEndpoint + '/v1.1/tasks/bulk/send');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setBody(optyPayload);

        // Intialize the response from the PactSafe API.
        PSAPIResponse psApiResponse = new PSAPIResponse();

        // Handle sending to the API and the response.
        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 202) {
            psApiResponse.message = 'Error processing with code ' + response.getStatusCode() + ' and error message ' + response.getBody() + '.';
            psApiResponse.success = false;
            String jsonOutput = JSON.serialize(psApiResponse);
            return jsonOutput;
        } else {
            // Update the parent opportunity with the contract sent date.
            updateParentSentDate(oppIds);
            psApiResponse.message = 'Successful in sending to PactSafe.';
            psApiResponse.success = true;
            String jsonOutput = JSON.serialize(psApiResponse);
            return jsonOutput;
        }
    }
}