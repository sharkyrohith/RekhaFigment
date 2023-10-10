/**
 * @description Interface for RecordTypeInfos
 *
 * @author Scott McClung
 * @date 2022/08/18
 */

public interface IRecordTypeInfos extends fflib_IObjects {
    List<RecordTypeInfo> getAll();
    Set<Id> getIds();
    Set<String> getNames();
    Set<String> getDeveloperNames();
    RecordTypeInfo getById(Id id);
    RecordTypeInfo getByName( String name );
    RecordTypeInfo getByDeveloperName( String name );
    IRecordTypeInfos filterById( Id id );
    IRecordTypeInfos filterByIds( Set<Id> ids );
    IRecordTypeInfos filterByIds( List<Id> ids );
    IRecordTypeInfos filterByName( String name );
    IRecordTypeInfos filterByNames( Set<String> names );
    IRecordTypeInfos filterByNames( List<String> names );
    IRecordTypeInfos filterByDeveloperName( String name );
    IRecordTypeInfos filterByDeveloperNames( Set<String> names );
    IRecordTypeInfos filterByDeveloperNames( List<String> names );
    IRecordTypeInfos whereActive();
    IRecordTypeInfos whereNotActive();
    IRecordTypeInfos whereAvailable();
    IRecordTypeInfos whereNotAvailable();
    IRecordTypeInfos whereDefault();
    IRecordTypeInfos whereMaster();
}