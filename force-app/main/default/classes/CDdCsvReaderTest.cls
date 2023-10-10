/**
 * @author: Mahesh Chouhan
 * @date March 2023
 * @description Test class for CDdCsvReader
 */
@isTest
public class CDdCsvReaderTest {

    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdCsvReader.class
    };

    /**
     * @author Mahesh Chouhan
     * @date March 2023
     * @description: Test method for CDdCSVReader constructor
     */
    @isTest
    static void testInsertObjectPositive(){
        List<StaticResource> resources = [SELECT Id, Name, Body from StaticResource where Name = 'refreshSubmarket'];

        CDdCSVReader csv = new CDdCSVReader(resources[0].Body.toString(), 'Submarket__c');
        insert csv.objects;

        List<Submarket__c> insertedSubmarket = [SELECT ID FROM Submarket__c];
        System.assert(insertedSubmarket.size() > 0, 'No Submarket record found.');
    }

    /**
     * @author Mahesh Chouhan
     * @date March 2023
     * @description: Test method for parseCSVRow
     */
    @isTest
    static void testParseCSVRow() {
        String csvRow = 'First Cell,"Second Cell , with , multiple, commas", Third Cell';
        Test.startTest();
        List<String> cells;
        Boolean exceptionFound = false;
        try{
            cells = CDdCsvReader.parseCSVRow(csvRow);
        }
        catch(Exception ex){
            exceptionFound= true;
        }
        Test.stopTest();

        System.assert(!exceptionFound, 'No Exception should occur.');
        System.assertEquals(3, cells.size(), 'No of cells in row is not same as expected.');
        System.assertEquals('Second Cell , with , multiple, commas', cells[1], 'Second cell data is not same as expected.');
    }
}