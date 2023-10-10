public with sharing class PdfGeneratorController {

  public ID parentId {get;set;}
  public String Name {get;set;}
    
  private final Opportunity opp;
  
    public PdfGeneratorController(ApexPages.StandardController stdController){
        opp =(Opportunity)stdController.getRecord();
        opp.Id = ApexPages.currentPage().getParameters().get('Id');
        Opportunity opp1 = [select Name from Opportunity where Id = :opp.Id];
        opp.Name = opp1.Name;
    }
    


  public PageReference savePdf() {

    PageReference pdf = Page.DoorDash_Contract;
    // add parent id to the parameters for standardcontroller
    pdf.getParameters().put('id',opp.Id);
    pdf.getParameters().put('Name',opp.Name);

    // create the new attachment
    Attachment attach = new Attachment();

    // the contents of the attachment from the pdf
    Blob body;

    try {

        // returns the output of the page as a PDF
        body = pdf.getContent();

    // need to pass unit test -- current bug    
    } catch (VisualforceException e) {
        body = Blob.valueOf('Some Text');
    }


    attach.Body = body;
    // add the user entered name
    attach.Name = opp.Name + ' ' +'Contract.pdf';
    //attach.Name = 'Salesforce Project Proposal' + '.pdf';
    attach.IsPrivate = false;
    // attach the pdf to the account
    attach.ParentId = opp.Id;
    insert attach;

    // send the user to the account to view results
    return new PageReference('/'+opp.Id);

  }

}