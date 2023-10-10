/**
 * @description HandleDmlResults class is used to handle IHandleDmlResults framework which allows for a transaction to save records partially.
 * @author Sanidhya Jain
 * @date 2023/02/02
 */
public virtual class HandleDmlResults implements IHandleDmlResults {

    //This will handle the Save & Update of records & will throw exception if there is any failure
    public virtual void handle( Database.SaveResult[] results ) {
        for( Database.SaveResult result : results ) {
            if( !result.isSuccess() ) {
                throwDmlExceptionFromDatabaseErrors( result.getErrors() );
            }
        }
    }

    //This will handle the delete of record & will throw exception if there is any failure
    public virtual void handle( Database.DeleteResult[] results ) {
        for( Database.DeleteResult result : results ) {
            if( !result.isSuccess() ) {
                throwDmlExceptionFromDatabaseErrors( result.getErrors() );
            }
        }
    }

    //This will handle the empty recycle bin of record & will throw exception if there is any failure
    public virtual void handle( Database.EmptyRecycleBinResult[] results ) {
        for( Database.EmptyRecycleBinResult result : results ) {
            if( !result.isSuccess() ) {
                throwDmlExceptionFromDatabaseErrors( result.getErrors() );
            }
        }
    }


    //Process to throw exception
    private void throwDmlExceptionFromDatabaseErrors( Database.Error[] errors ) {
        if( errors.size() == 0 ) {
            return;
        }
        String message = String.format( '{0}: {1}', new String[]{
            errors[0].getStatusCode().name(),
                errors[0].getMessage()
                } );
        throw new DmlException( message );
    }
}