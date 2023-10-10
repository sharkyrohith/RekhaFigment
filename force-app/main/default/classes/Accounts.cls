/**
 * @description Domain Class for Account SObject
 * @author Scott McClung
 * @date 2022/08/17
 */
public virtual inherited sharing class Accounts
    extends AccountValidations
    implements IAccounts {

    /**
     * @description Provides a convenient and performant way to access the record types
     * scoped to the domain SObject.
     * @example
     * Id master = Accounts.RecordTypes.getByName('Master').getRecordTypeId();
     */
    public static IRecordTypeInfos RecordTypes {
        get {
            if(RecordTypes == null) {
                RecordTypes = RecordTypeInfos.newInstance(Account.SObjectType);
            }
            return RecordTypes;
        }
        private set;
    }

    /**
     * @description Convenience factory method to resolve an instance of the domain class from the
     * Application factory
     * @param records List of SObjects to be injected into the domain class
     * @return A concrete or mock implementation of IAccounts
     */
    public static IAccounts newInstance( List<Account> records ) {
        return (IAccounts) Application.Domain.newInstance( records, Account.SObjectType );
    }

    /**
     * @description Class constructor
     * @param records Collection of SObjects
     */
    public Accounts( List<Account> records ) {
        super( records );
    }

    /**
     * @description Domain factory class to support dependency injection
     */
    public class Constructor implements fflib_IDomainConstructor {
        /**
         * @description Factory method to provide the Application Factory an api
         * where it can resolve new instances of this domain class and inject the
         * sobject records.
         * @param objectList List of records to be injected into the domain class
         * @return Instance of the domain class
         */
        public SObjects construct( List<Object> objectList ) {
            return new Accounts( (List<SObject>) objectList );
        }
    }
}