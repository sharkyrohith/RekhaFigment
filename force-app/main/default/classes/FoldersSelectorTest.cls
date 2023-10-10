/**
 * @description Test Class for FoldersSelector class
 * @author Mahesh Chouhan
 * @date Nov 2022
 */

@isTest
public class FoldersSelectorTest {

    /**
     * @description Test method for selectImageFolder method
     */
    @isTest
    static void testSelectImageFolder(){
        List<Folder> result = FoldersSelector.newInstance().selectImageFolder();
        System.assertEquals(1, result.size(), 'No Images Folder found on selecting by where Clause');
    }
    
    /**
     * @description Test method for selectById method
     */
    @isTest
    static void testSelectById(){
        List<Folder> imageFolder = [SELECT Id FROM Folder WHERE Name='Images' AND NamespacePrefix=null];
        List<Folder> result = FoldersSelector.newInstance().selectById(new Set<Id>{imageFolder[0].Id});
        System.assertEquals(1, result.size(), 'No Images Folder found on selecting by folder Id');
    }
}