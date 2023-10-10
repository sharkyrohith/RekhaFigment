@isTest
global class ComparableResponsePayloadAttributeTest implements Comparable{

    global Map<String, Object> obj;

    global ComparableResponsePayloadAttributeTest(Map<String, Object> obj){
        this.obj = obj;
    }

    global Integer compareTo(Object comparedTo) {
        ComparableResponsePayloadAttributeTest tmp = (ComparableResponsePayloadAttributeTest) comparedTo;
        if (((Decimal) obj.get('depth')) < ((Decimal) tmp.obj.get('depth'))) return -1;
        if (((Decimal) obj.get('depth')) == ((Decimal) tmp.obj.get('depth')) && ((Decimal) obj.get('index')) < ((Decimal) tmp.obj.get('depth'))) return -1;
        return 1;
    }
}