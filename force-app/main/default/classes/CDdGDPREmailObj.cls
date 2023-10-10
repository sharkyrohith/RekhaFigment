public class CDdGDPREmailObj {
    /**
     * @description       : 
     * @author            : DAnnapareddy
     * @group             : 
     * @last modified on  : 11-09-2021
     * @last modified by  : Dinesh Annapareddy
    **/
    public class CDdGDPRSubscriptions {
        public String email {
            get; 
            set {   
                if (String.isNotBlank(value)){ 
                    email = value.toLowerCase();
                } else { 
                    email = value;
                }
            }
        }
        public String persona {
            get; 
            set { 
                if (String.isNotBlank(value)){ 
                    persona = value.toUpperCase();
                } else { 
                    persona = '';
                }
            }
        }
        public String cassieID;
        public List<CDdGDPRSubscription> subscriptions;
    }

    public class CDdGDPRSubscription {
        public Integer  channelID;
        public String   channelName;
        public Boolean  optOut;
    }

    public class CDdGDPRSubObject {
        public Map<String, Boolean> emailSubMap;
        public Set<String> emailList;
        public set<String> recordIdsAffected;
        public CDdGDPRSubObject(){
            emailSubMap = new Map<String, Boolean>();
            emailList = new Set<String>();
            recordIdsAffected= new set<String>();

        }
    }

    /**
     *   @description Request Body for getting current preferences
     */
    public class CassieRequest{
        public CassieIdentifiers[] Identifiers;
    }
    public class CassieIdentifiers{
        public String IdentifierID;
        public String Value;
    }
     
    /**
     *   @description Request Body for Inserting contact in Cassie
     */
    public class CassieRequestNewContact{ 
        public string MethodType;
        public CassieRequestLookupProperties LookupParameters;
 
    }
    public class CassieRequestLookupProperties{
        public string Email1;
        public String URN1;
        public String Custom3 = 'true';
        public list<CurrentPreferencesForInsert> Preferences;     
    }
    public class CurrentPreferencesForInsert{
        public Integer ChannelID;
        public Integer PreferenceValue;
        public Integer StatementID;
    }
 
    /**
     *   @description Request Object for holding cassie response.
     */
    public class CassieCurrentPreferencesResponse{
        public CurrentStandDak CurrentStandDak;
        public list<CurrentPreferences> CurrentPreferences;
        public Integer SyrenisID;
    }
    public class CurrentStandDak{
        public String URN1;
        public String Email1;
    } 
    public class CurrentPreferences{
        public String ChannelName;
        public Integer PreferenceValue;
        public Integer ChannelID;
    }

    public class CDdGDPRCreateContactObject {
        public Map<String,CDdGDPREmailObj.CassieRequest> reqList ;
        public Map<String,CDdGDPREmailObj.cassieCurrentPreferencesResponse> respList;
        public GDPR_Email_Action__e evt;
        public CDdGDPRCreateContactObject(){
            System.debug('initializing reqList');
            reqList = new Map<String,CDdGDPREmailObj.CassieRequest>();
            respList = new Map<String,CDdGDPREmailObj.cassieCurrentPreferencesResponse>();
        }
    }

    public class CDdGDPREmailFields {
        public String emailOptOutField;
        public String emailOptOutLogField;
        public Boolean isPersonAccount;
        public String personEmailOptOutField;
        public String personEmailOptOutLogField;


        public CDdGDPREmailFields(){
            emailOptOutField = '';
            emailOptOutLogField = '';
            personEmailOptOutField = '';
            personEmailOptOutLogField = '';
            isPersonAccount= false;
        }
    }
}