// ===========================================================================
// Component: CDdBatchTemplate
// Author: <>
// Purpose: Batch job to update/process <>
// ===========================================================================
global class CDdBatchTemplate implements Database.Batchable<sObject>, Schedulable {
  /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
  public static final String BLANK_STRING = '(blank)';
  private static final Integer MY_INT;
  /*****************************************************************************************************************************
   *
   * Public Variables & Fields
   *
   *****************************************************************************************************************************/
  global Set<Id> caseIdSet = new Set<Id>();
  public String testString = '(blank)';
  public Integer totalCount = 0;

  /**
   * Overriden Constructor
   * This constructor can be called when we want to run a specific list of records
   * @return  None
   */
  global CDdBatchTemplate(Set<Id> idSet) {
    this.caseIdSet = idSet;
  }
  /**
   * Default Constructor
   * @return  None
   */
  global CDdBatchTemplate() {
    this.caseIdSet = new Set<Id>();
  }
  /*****************************************************************************************************************************
   *
   * Query Locator
   *
   ****************************************************************************************************************************/
  global Database.QueryLocator start(Database.BatchableContext bc) {
    String queryString = ' Select Id from Case';

    if (!caseIdSet.isEmpty()) {
      queryString += ' WHERE Id IN:caseIdSet';
    }

    queryString += ' LIMIT 10';

    //Try querying on Cases
    try {
      return Database.getQueryLocator(queryString);
    } catch (QueryException e) {
      //Catch QueryException any
      CDdErrorUtilities.publishException('BatchClass', 'CDdErrorUtilities', e);
      return null;
    }
  }
  /*****************************************************************************************************************************
   *
   * Execute
   *
   ****************************************************************************************************************************/
  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    // Local variables
    // list of cases
    List<Case> caseList = (List<Case>) scope;

    // map of Cases
    Map<Id, Case> caseMap = new Map<Id, Case>();

    // Set of Cases
    Set<Case> caseSet = new Set<Case>();

    // Integer
    Integer caseAmt = 0;

    //Boolean
    Boolean isChecked = false;

    //String
    String accNameStr = '';

    // DO Something???
    // Check if data is there to update...
    if (!caseList.isEmpty()) {
      // update
      List<Database.SaveResult> updResult = Database.update(caseList, false);
      // error record..
      CDdErrorUtilities.publishException(
        'BatchClass',
        'CDdErrorUtilities',
        updResult
      );
    }
  }
  /*****************************************************************************************************************************
   *
   * Finish
   *
   ****************************************************************************************************************************/
  global void finish(Database.BatchableContext bc) {
    // Nothing to do...
    // Send an Email???
  }
  /*****************************************************************************************************************************
   *
   * SCHEDULABLE
   *
   ****************************************************************************************************************************/
  // SCHEDULABLE IMPLEMENTATION
  global void execute(SchedulableContext sc) {
    // for now just 10 at a time...
    Integer batchSize = 10;
    Database.executeBatch(new CDdBatchTemplate(), batchSize);
  }
}