/**
 * @author Raju Lakshman
 * @date Sept 16, 2021
 *
 * @description Generic Exception Class
*/
public class CDdException extends Exception {
    public static String formatExceptionMsg(Exception ex) {
        return ex.getTypeName() + ': ' + ex.getMessage() + '; '  + ex.getStackTraceString();
    }
}