public with sharing class PSSigner {

  public String name;
  public String email;
  public String mobile_number;
  public String company_name;
  public String title;

  public PSSigner() {}

  public PSSigner(Contact contact) {
    this.name = contact.Name;
    this.email = contact.Email;
    this.mobile_number = contact.MobilePhone;
    this.title = contact.Title;
  }

}