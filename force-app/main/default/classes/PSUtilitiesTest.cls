/**
 * @description Versioned as part of BZAP-13135. Pre-existing code for calling the PactSafeAPI.
 **/
@isTest
private class PSUtilitiesTest {

  @isTest
  static void testSandbox() {
    Boolean sandboxCheck = PSUtilities.isSandbox();
    System.assert(
      sandboxCheck != null,
      'Testing for sandbox instance should always resolve to a true/false value.'
    );
  }
}