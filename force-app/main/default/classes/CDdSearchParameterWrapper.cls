/**
 * CDdSearchParameterWrapper
 *
 * @author     Pranil Nimase
 * @date  15 July 2021
 * @decription Wrapper class containing different parameters for querying records
 * 
 */
public class CDdSearchParameterWrapper {
    @AuraEnabled
    public String usernameSearchKey {get; set;}
    @AuraEnabled
    public String accountnameSearchKey {get; set;}
    @AuraEnabled
    public String statusSearchKey {get; set;}
    @AuraEnabled
    public String businessIdSearchKey {get; set;}
    @AuraEnabled
    public String mxpUserSearchKey {get; set;}
    @AuraEnabled
    public Boolean showSelectedUsers {get; set;}
    @AuraEnabled
    public String emailSearchKey {get; set;}
    @AuraEnabled
    public String profileSearchKey {get; set;}
    @AuraEnabled
    public String roleSearchKey {get; set;}
    @AuraEnabled
    public String objectApiName {get; set;}
    @AuraEnabled
    public Integer offSet {get; set;}
    @AuraEnabled
    public String pageSize {get; set;}
    @AuraEnabled
    public String orderBy {get; set;}
    @AuraEnabled
    public String sortOrder {get; set;}
    @AuraEnabled
    public List<String> selectFields {get; set;}
}