/**
  * @author:Shiva Pochamalla
  * @date  05/09/2022
  * @decription: Test class for CddMenuUploader
  */
  @IsTest
  public class CddMenuUploaderTest {
      @IsTest
      static void testUpdateMenuName() {
          String filename = 'testmenu.pdf';
          String title = 'testmenu';
          String content = 'test menu';
  
          ContentVersion conVer = new ContentVersion();
          conVer.ContentLocation = 'S'; 
          conVer.PathOnClient = filename;
          conVer.Title = title;
          conVer.VersionData = Blob.valueOf(content);
          insert conVer;
          
          Test.startTest();
              //prefixes the file name to Menu_[filename]
              CddMenuUploader.updateCVDescOnMenuFiles(new List<Id>{conver.Id});
          Test.stopTest();
      }
  }