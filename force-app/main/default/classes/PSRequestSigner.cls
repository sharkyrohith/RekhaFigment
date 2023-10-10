public with sharing class PSRequestSigner {

  public String signer_id;
  public Boolean supporting_files_access;
  public PSSigner signer;
  public List<String> personas;
  public List<String> role;
  public Map<String, Boolean> send_to;

  public PSRequestSigner() {
    this.supporting_files_access = false;
    this.send_to = new Map<String, Boolean>{'email' => true, 'mobile_number' => false};
  }

  public PSRequestSigner(String signer_id, PSSigner signer) {
    this.signer_id = signer_id;
    this.signer = signer;
    this.supporting_files_access = false;
    this.send_to = new Map<String, Boolean>{'email' => true, 'mobile_number' => false};
  }

}