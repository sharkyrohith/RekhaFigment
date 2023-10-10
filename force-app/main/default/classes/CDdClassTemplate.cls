/**
 * CDdClassTemplate
 *
 * @author     <Who>
 * @date  <When>
 * @decription <what does it do>.
 * refer for naming conventions: https://docs.google.com/spreadsheets/d/1i08j3era9CfIr0cBuCbaeao6UNqNxBGj2CcWACGzdsQ/edit?usp=sharing
 */
public with sharing class CDdClassTemplate {
  /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
  private static final String MY_LOCAL_STRING = 'Test';
  private static final String BLANK_STRING = '(blank)';
  private static final Integer MY_INT;
  /*****************************************************************************************************************************
   *
   * Public/Global Variables
   *
   *****************************************************************************************************************************/
  public Set<Id> caseIdSet = new Set<Id>();
  public String testString = '(blank)';
  public Integer totalCount = 0;
  public Map<Id,Case> caseIdtoCaseMap = new Map<Id,Case>();
  public List<Case> caseList = new List<Case>();
  /*****************************************************************************************************************************
   *
   * Constructors
   *
   *****************************************************************************************************************************/
  /**
   * @author     <Who>
   * @date  <When>
   * @decription Default Constructor
   * @param   None
   * @return  None
   */
  public CDdClassTemplate() {
    this.caseIdSet = new Set<Id>();
    //call private methods
    samplePrivateString();
    samplePrivateMethod();
  }
  /*****************************************************************************************************************************
   *
   * Public Methods
   *
   *****************************************************************************************************************************/
  /** 
   * @author     <Who>
   * @date  <When>
   * @decription <what does it do>
   * @param   stringParam          String Parameter
   * @return  None
   */
  public static void sampleMethod(String stringParam) {
  }
  /*****************************************************************************************************************************
   *
   * Private Methods
   *
   *****************************************************************************************************************************/
  /**
   * @author     <Who>
   * @date  <When>
   * @decription <what does it do>
   * @param   None 
   * @return  None
   */
  private static void samplePrivateMethod() {
  }
  /**
   * @author     <Who>
   * @date  <When>
   * @decription <what does it do>
   * @param   None 
   * @return  String
   */
  private String samplePrivateString() {
    return 'test';
  }
}