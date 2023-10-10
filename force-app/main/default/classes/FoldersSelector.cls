/**
 * @description Selector Class for Folder SObject
 * @author Mahesh Chouhan
 * @date Oct 2022
 */

public virtual inherited sharing class FoldersSelector
    extends SObjectsSelector
    implements IFoldersSelector {

    /**
     * @description Convenience factory method to resolve an instance of the selector from the
     * Application factory
     * @return A concrete or mock implementation of the IFoldersSelector
     */
    public static IFoldersSelector newInstance() {
        return (IFoldersSelector) Application.Selector.newInstance( Folder.SObjectType );
    }

    /**
     * @description Method for defining the default fields that are included in the query results.
     * @return List of SObjectField tokens
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Folder.Id,
            Folder.Name
        };
    }

    /**
     * @description Defines the SObject to be queried by this selector
     * @return An SObjectType token
     */
    public Schema.SObjectType getSObjectType() {
        return Folder.SObjectType;
    }

    /**
     * @description Method for querying Folder records when you know their ids
     * @param ids The ids of the records to be returned
     * @return A list of Folder records
     */
    public List<Folder> selectById( Set<Id> ids ) {
        return (List<Folder>) selectSObjectsById( ids );
    }

    /**
     * @description Method for querying Folder records with WHERE condition 
     * @return A list of Folder records
     */
    public List<Folder> selectImageFolder() {
        fflib_QueryFactory query = newQueryFactory()
        .setCondition('Name = \'Images\' AND NamespacePrefix = null');
        
        return Database.query(query.toSOQL());
    }
}