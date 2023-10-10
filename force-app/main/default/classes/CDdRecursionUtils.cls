public class CDdRecursionUtils {

    private static Map<String, Integer> RecursionMap = new Map<String, Integer>();

    public static boolean isRunnable(String key) {

        if (CDdCustomMetadata.isDisabled(key)) {
            System.debug('CDdRecursionUtils: isDisabled: ' + key);
            return false;
        }

        if (!RecursionMap.containsKey(key)) {
            RecursionMap.put(key, CDdCustomMetadata.getRecursion(key));
        }

        Integer remainingRuns = RecursionMap.get(key);
        System.debug('CDdRecursionUtils: remainingRuns (' + key + '): ' + remainingRuns);

        if (remainingRuns > 0) {
            RecursionMap.put(key, remainingRuns-1);
            return true;
        }

        return false;

    }

    public static void resetRecursion(String key) {
        if (RecursionMap.containsKey(key)) {
            RecursionMap.put(key, CDdCustomMetadata.getRecursion(key));
        }
    }
}