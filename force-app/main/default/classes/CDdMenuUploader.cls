public with sharing class CDdMenuUploader {

    /*
   * @method updateCVDescOnMenuFiles() 
   * @desc Updates the description as Menu for the given menu files convent version
   * 
   * @param {list<Id>} contentVersionIds - list of Id of Content Version
   * 
   * @return {list<Id>} - returns the updated list of content version Id if the
   *   update was successful, otherwise returns null
   */
    @AuraEnabled
    public static list<Id> updateCVDescOnMenuFiles(list<Id> contentVersionIds){
        system.debug('contentVersionIds'+contentVersionIds);

        List<ContentVersion> lstVersionsToUpdate = new List<ContentVersion>();
        for (ContentVersion objCntVersion : [SELECT id, Title, Description From ContentVersion WHERE Id IN:  contentVersionIds]) 
        {
            string title = string.valueOf(objCntVersion.Title);
            if(!title.containsIgnoreCase('menu'))
            {
                objCntVersion.Title = 'Menu_'+ objCntVersion.Title;
            }
            objCntVersion.Description = 'Menu';
            lstVersionsToUpdate.add(objCntVersion);
        }
        
        list<Id> lstCntVerIds = new list<Id>();
        if(lstVersionsToUpdate.size() > 0)
        {
            list<Database.saveResult> res = Database.update(lstVersionsToUpdate);
            for (Database.SaveResult saveResult : res) {
                if(saveResult.isSuccess()) {
                    lstCntVerIds.add(saveResult.getId());
                }
            }
        }
        if (lstCntVerIds.size() == 0) 
        { 
            return null; 
        }
        return lstCntVerIds;
    }
}