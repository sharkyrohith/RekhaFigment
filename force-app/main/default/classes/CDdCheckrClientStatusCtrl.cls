public with sharing class CDdCheckrClientStatusCtrl {
    
    public String email {get; set;}
    
    public CDdCheckrClientStatusCtrl() {
    
    }
    
    public PageReference searchCheckr() {
        String email = Apexpages.currentPage().getParameters().get('email');
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern pattern = Pattern.compile(emailRegex);
        Matcher matcher = pattern.matcher(email);
        if (!matcher.matches()) {
            return null;
        }
      	PageReference pg = Page.PDdCheckrClientStatusResult;
        pg.getParameters().put('email', email);
        //System.debug(LoggingLevel.ERROR, 'pg.url = ' + pg.getUrl());
        pg.setRedirect(true);
        return pg;
    }
    
    
}