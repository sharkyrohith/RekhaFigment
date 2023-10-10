/**
 * @description Interface for the FolderSelector
 *
 * @author Mahesh Chouhan
 */
public interface IFoldersSelector extends ISObjectsSelector {
    /**
     * @description Method for querying Folder records when you know their ids
     * @param folderIds The ids of the records to be returned
     * @return A list of Folder records
     */
    List<Folder> selectById( Set<Id> folderIds );

    /**
     * @description Method for querying Folder records with WHERE condition 
     * @param whereClause SOQL WHERE condition
     * @return A list of Folder records
     */
    List<Folder> selectImageFolder();
}