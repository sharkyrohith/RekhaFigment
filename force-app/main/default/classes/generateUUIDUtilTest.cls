/**
 * @author Nishant
 * @date April 2023
 * @description Test class for generateUUIDUtil
 */
@isTest
public class generateUUIDUtilTest {

    /**
     * @description This is method used to test generateUUIDUtil class
     */
    @isTest
    private static void testWhenClassInstantiatesThenRun() {
      Pattern patrn = Pattern.compile('[\\w]{8}-[\\w]{4}-4[\\w]{3}-[89ab][\\w]{3}-[\\w]{12}');
      for(Integer x = 0; x < 100; x++) {
        Matcher mat = patrn.matcher(generateUUIDUtil.NewGuid());
        System.assert(mat.matches() == true);
      }
    }
  }