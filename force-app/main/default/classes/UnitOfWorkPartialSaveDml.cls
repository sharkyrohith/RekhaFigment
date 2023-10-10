/**
 * @description Implementation of fflib_SObjectUnitOfWork.SimpleDML that allows for a transaction to be
 * partially saved.
 * @author Sanidhya Jain
 * @date 2023/02/02
 */
public inherited sharing class UnitOfWorkPartialSaveDml extends fflib_SObjectUnitOfWork.SimpleDML {

    public IHandleDmlResults resultsHandler = new HandleDmlResults();

    public UnitOfWorkPartialSaveDml() {}

    public UnitOfWorkPartialSaveDml(IHandleDmlResults resultsHandler) {
        this.resultsHandler = resultsHandler;
    }


    /**
     * @description Insert records into the database
     * @param objList - Collection of SObjects to be inserted
     */
    public override void dmlInsert( SObject[] objList ) {
        try {
            if( objList.isEmpty() ){
                return;
            }
            insertRecords( objList );
        } catch( Exception e ) {
            // insert logging behavior here
            throw e;
        }
    }

    /**
     * @description Update existing records in the database
     * @param objList - Collection of SObjects to be updated
     */
    public override void dmlUpdate( SObject[] objList ) {
        try {
            if( objList.isEmpty() ){
                return;
            }
            updateRecords( objList );
        } catch( Exception e ) {
            // Update logging behavior here
            throw e;
        }
    }

    /**
     * @description Delete records from the database
     * @param objList - Collection of SObjects to be deleted
     */
    public override void dmlDelete( SObject[] objList ) {
        try {
            if( objList.isEmpty() ){
                return;
            }
            deleteRecords( objList );
        } catch( Exception e ) {
            // Delete logging behavior here
            throw e;
        }
    }

    /**
     * @description Hard delete records from the Recycle Bin
     * @param objList - Collection of SObjects to be hard deleted
     */
    public override void emptyRecycleBin( List<SObject> objList ) {
        try {
            if( objList.isEmpty() ) {
                return;
            }
            removeFromRecycleBin( objList );
        } catch( Exception e ) {
            // Empty Recycle Bin logging behavior here
            throw e;
        }
    }

    /**
     * @description Publish platform events
     * @param objList - Platform Events objects to be published
     */
    public override void eventPublish( SObject[] objList ) {
        try {
            publishPlatformEvent( objList );
        } catch( Exception e ) {
            // Event Publish logging behavior here
            throw e;
        }
    }


    /**
     * @description In order to test that the EventBus.publish method was successful
     * we need access to the Database.SaveResult that it returns.  Since the IDML interface
     * doesn't support return values from the api we need a different approach to make the
     * process testable.  We're deferring the publish action to this method and making it
     * test visible to give our test the ability to exercise the publish method and assert
     * against the results.
     * @param objList
     * @return The results from the EventBus.publish method
     */
    @TestVisible
    private Database.SaveResult[] publishPlatformEvent( SObject[] objList ) {
        Database.SaveResult[] results = EventBus.publish( objList );
        // Since the EventBus.publish method does not throw an exception when it encounters an error
        // we need to evaluate the response and generate a DMLException for any errors.
        resultsHandler.handle( results );
        return results;
    }

    /**
     * @description In order to test that the insert method was successful
     * we need access to the Database.SaveResult that it returns.  Since the
     * IDML interface doesn't support return values from the api we need a different
     * approach to make the process testable.  We're deferring the dml action to
     * this method and making it test visible to give our test the ability to exercise
     * the insert method and assert against the results.
     * @param objList - Collection of SObjects to be hard deleted
     * @return The results from the Database.insert method
     */
    @TestVisible
    private Database.SaveResult[] insertRecords( SObject[] objList ) {
        Database.SaveResult[] results = Database.insert( objList, false );
        // Since the Database.insert method does not throw an exception when it encounters an error
        // we need to evaluate the response and generate a DMLException for any errors.
        resultsHandler.handle( results );
        return results;
    }

    /**
     * @description In order to test that the update method was successful
     * we need access to the Database.SaveResult that it returns.  Since the
     * IDML interface doesn't support return values from the api we need a different
     * approach to make the process testable.  We're deferring the dml action to
     * this method and making it test visible to give our test the ability to exercise
     * the update method and assert against the results.
     * @param objList - Collection of SObjects to be hard deleted
     * @return The results from the Database.update method
     */
    @TestVisible
    private Database.SaveResult[] updateRecords( SObject[] objList ) {
        Database.SaveResult[] results = Database.update( objList, false );
        // Since the Database.update method does not throw an exception when it encounters an error
        // we need to evaluate the response and generate a DMLException for any errors.
        resultsHandler.handle( results );
        return results;
    }

    /**
     * @description In order to test that the insert method was successful
     * we need access to the Database.DeleteResult that it returns.  Since the
     * IDML interface doesn't support return values from the api we need a different
     * approach to make the process testable.  We're deferring the dml action to
     * this method and making it test visible to give our test the ability to exercise
     * the delete method and assert against the results.
     * @param objList - Collection of SObjects to be hard deleted
     * @return The results from the Database.delete method
     */
    @TestVisible
    private Database.DeleteResult[] deleteRecords( SObject[] objList ) {
        Database.DeleteResult[] results = Database.delete( objList, false );
        // Since the Database.delete method does not throw an exception when it encounters an error
        // we need to evaluate the response and generate a DMLException for any errors.
        resultsHandler.handle( results );
        return results;
    }



    /**
     * @description In order to test that the emptyRecycleBin method was successful
     * we need access to the Database.EmptyRecycleBinResult that it returns.  Since the
     * IDML interface doesn't support return values from the api we need a different
     * approach to make the process testable.  We're deferring the dml action to
     * this method and making it test visible to give our test the ability to exercise
     * the publish method and assert against the results.
     * @param objList - Collection of SObjects to be hard deleted
     * @return The results from the Database.emptyRecycleBin method
     */
    @TestVisible
    private Database.EmptyRecycleBinResult[] removeFromRecycleBin( SObject[] objList ) {
        Database.EmptyRecycleBinResult[] results = Database.emptyRecycleBin( objList );
        // Since the Database.emptyRecycleBin method does not throw an exception when it encounters an error
        // we need to evaluate the response and generate a DMLException for any errors.
        resultsHandler.handle( results );
        return results;
    }


    public class DeveloperException extends Exception {}
}