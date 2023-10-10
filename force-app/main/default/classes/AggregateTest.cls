@isTest
public class AggregateTest {

    @IsTest
    static void testAllAggregateWrapperMethods(){
        List<AggregateResult> aggResults = [SELECT ProfileId,count(Id) cnt FROM User WHERE IsActive = true GROUP BY ProfileId];
        List<Aggregate> aggResultWrappers = Aggregate.convertResults(aggResults);

        Map<Id,Aggregate> aggResultWrapperMap1 = Aggregate.mapBy('ProfileId', aggResultWrappers);
        system.assert(!aggResultWrapperMap1.isEmpty(),'Profile Map is empty');

        Map<Id,Aggregate> aggResultWrapperMap2 = Aggregate.mapBy('', aggResultWrappers);
        system.assert(aggResultWrapperMap2.isEmpty(),'Map is not empty');

        Map<String,Object> myMap = new Map<String,Object> {
            'test' => (Object)'Pass'
        };
        Aggregate agg1 = new Aggregate(myMap);
        system.assertEquals(String.valueOf(agg1.get('test')), 'Pass', 'Unexpected value');

        Aggregate agg2 = new Aggregate();
        agg2.put('test',(Object)'Fail');
        system.assertEquals(String.valueOf(agg2.get('test')), 'Fail', 'Unexpected value');
    }
}