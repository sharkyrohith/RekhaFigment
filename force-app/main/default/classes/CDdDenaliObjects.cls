/**
 * 
 * @author: Tia Xuan
 * @date: 2019-09
 * @description Denali objects, used to parse json web service responses
 * 
 */
public class CDdDenaliObjects {

    public class BusinessObject{
        public String busObId {get; set;}
        public List<BusinessObjectField> fieldDefinitions {get; set;}
        public List<BusinessObjectRelationship> relationships {get; set;}
    } 

    public class BusinessObjectField{
        public String fieldId {get; set;}
        public String name {get; set;}
        public String value {get; set;}
        public Boolean dirty {get; set;}
    }

    public class BusinessObjectRelationship {
        public String cardinality {get; set;}
        public String description {get; set;}
        public String displayName {get; set;}
        public String relationshipId {get; set;}
        public String target {get; set;}
        public String errorCode {get; set;}
        public String errorMessage {get; set;}
        public Boolean hasError {get; set;}
    }

    public class BusinessObjectTemplateRequest{
        public String busObId {get; set;}
        public List<String> fieldNames {get; set;}
        public Boolean includeRequired {get; set;}
        public Boolean includeAll {get; set;}
    }

    public class BusinessObjectTemplate{
        public String busObId {get; set;}
        public String busObRecId {get; set;}
        public String cacheScope {get; set;}
        public Boolean persist {get; set;}
        public List<BusinessObjectField> fields {get; set;}
    }

    public class BusinessObjectRelationshipTemplate{
        public String busObId {get; set;}
        public String parentBusObId {get; set;}
        public String parentBusObPublicId {get; set;}
        public String parentBusObRecId {get; set;}
        public String relationshipId {get; set;}
        public String busObRecId {get; set;}
        public String cacheScope {get; set;}
        public Boolean persist {get; set;}
        public List<BusinessObjectField> fields {get; set;}
    }
    
    public class BusinessObjectSaveResult{
        public String busObPublicId {get; set;}
        public String busObRecId {get; set;}
        public String errorCode {get; set;}
        public String errorMessage {get; set;}
        public Boolean hasError {get; set;}   
    }

    public class BusinessObjectRelationshipResult{
        public String parentBusObId {get; set;}
        public String parentBusObPublicId {get; set;}
        public String parentBusObRecId {get; set;}
        public String relationshipId {get; set;}
        public List<BusinessObjectRelationshipResultRelated> relatedBusinessObjects {get; set;}
        public String errorCode {get; set;}
        public String errorMessage {get; set;}
        public Boolean hasError {get; set;}   
    }

    public class BusinessObjectRelationshipResultRelated{
        public String busObId {get; set;}
        public String busObPublicId {get; set;}
        public String busObRecId {get; set;}
    }

    public class BusinessObjectSearch{
        public List<String> busObIds {get; set;}
        public String searchText {get; set;}
    } 

    public class BusinessObjectSearchResult{
        public List<BusinessObjectSearchResultGroup> groups {get; set;}
        public String title {get; set;}
        public String errorCode {get; set;}
        public String errorMessage {get; set;}
        public Boolean hasError {get; set;}
    } 

    public class BusinessObjectSearchResultGroup{
        public Boolean isBusObTarget {get; set;}
        public List<BusinessObjectSearchResultGroupListItem>  simpleResultsListItems {get; set;}
        public String errorCode {get; set;}
        public String errorMessage {get; set;}
        public Boolean hasError {get; set;}    
    }

    public class BusinessObjectSearchResultGroupListItem{
        public String busObId {get; set;}
        public String busObRecId {get; set;}
    }

}