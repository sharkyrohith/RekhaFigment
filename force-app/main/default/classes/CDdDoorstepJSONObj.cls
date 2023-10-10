public class CDdDoorstepJSONObj {
    
    /*
     * @author: jnguyen
     * All REST API request/response object structure should live in this class
     */
    
    public class RestAPIResponse {
		public String body;
		public Integer statusCode;
	}
    
    public class DoorstepBusinessRequest {
        public String name;
        public String description;
        public String webhook_url;
    }
    
    public class DoorstepBusinessResponse {
        public String name;
        public String description;
        public String webhook_url;
        public Decimal id;
    }
    
    public class DoorstepStoreRequest {
        public String name;
        public String is_active;
		public Decimal business_id;
        public Decimal submarket_id;
        public String payment_protocol;
        public String street_address;
        public String phone_number;
        public String zipcode;
        public String city;
        public String state;
        public Double lat;
        public Double lng;
    }
    
    public class DoorstepUserRequest {
        public String email;
        public String phone_number;
        public String first_name;
        public String last_name;
    }
    
    public class DoorstepUserResponse {
        public String email;
        public Double id;
        public String first_name;
        public String last_name;
    }
    
    public class DoorstepMerchantRequest {
        public Double user;
        public Double store;
    }
    
    public class DoorstepMerchantResponse {
        public String email;
        public Double id;
        public String first_name;
        public String last_name;
    }
}