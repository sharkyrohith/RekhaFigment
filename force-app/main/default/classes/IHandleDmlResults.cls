/**
 * @description : IHandleDmlResults interface is used to handle the partial save
 * @author Sanidhya Jain
 * @date 2023/02/02
 */
public interface IHandleDmlResults {
    void handle( Database.SaveResult[] results );
    void handle( Database.DeleteResult[] results );
    void handle( Database.EmptyRecycleBinResult[] results );
}