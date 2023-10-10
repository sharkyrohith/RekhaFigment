public with sharing class PSRequest {

  public List<PSContract> contracts;
  public Boolean signing_order;
  public Boolean smartpact;
  public Boolean deleted;
  public Boolean complete;
  public Boolean expired;
  public String name;
  public Integer created_by;
  public Integer updated_by;
  public Integer account;
  public Integer site;
  public Integer sent_by;
  public String download_url;
  public List<PSRequestSigner> signers;
  public String id;

}