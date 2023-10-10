/**
 * @author: Raju Lakshman
 * @date: Feb 2021
 * @description An opinionated trigger handler framework.
 * Originally by Kevin O'Hara github.com/kevinohara80/sfdc-trigger-framework
 * @Source https://github.com/trailheadapps/apex-recipes/blob/main/force-app/main/default/classes/Shared%20Code/TriggerHandler.cls
 */

 public virtual class CDdTriggerHandler {

    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;

    // the current context of the trigger, overridable in tests
    @TestVisible
    protected TriggerContext context;

    // Used to mock the trigger variables.
    private List<SObject> mockTriggerList;
    public void setMockTriggerList(List<SObject> mockTriggerList) {
        this.mockTriggerList = mockTriggerList;
    }
    private Map<Id, SObject> mockTriggerOldMap;
    public void setMockTriggerOldMap(Map<Id, SObject> mockTriggerOldMap) {
        this.mockTriggerOldMap = mockTriggerOldMap;
    }

    // Child class methods can access this variable to either get the mockTriggerList or the actual trigger list
    public List<SObject> triggerList {
        get {
            if (this.mockTriggerList != null) {
                return this.mockTriggerList;
            }

            Boolean isDelete = this.context != null && (this.context == TriggerContext.BEFORE_DELETE || this.context == TriggerContext.AFTER_DELETE);
            return isDelete ? Trigger.old : Trigger.new;
        }
    }

    // Child class methods can access this variable to either get the mockTriggerOldMap or the actual trigger oldMap
    public Map<Id,SObject> triggerOldMap {
        get {
            if (this.mockTriggerOldMap != null) {
                return this.mockTriggerOldMap;
            }
            return Trigger.oldMap;
        }
    }

    /**
     * @description Getter for the trigger context - child classes can always refer to this to get the context (Before/After insert/update/etc).
     */
    public TriggerContext getTriggerContext() {
        return this.context;
    }

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }

    @TestVisible
    protected String customSettingFlagName;

    // constructor
    public CDdTriggerHandler() {
        this.setTriggerContext();
    }

    /***************************************
     * public instance methods
     ***************************************/

    // main method that will be called during execution
    public virtual void run() {
        runHelper();
    }

    // Add a checkbox field for the object in Disable_Trigger_Code__c custom setting. This can basically be the object name.
    // From the .trigger file, this constructor accepts the field api name in that Disable_Trigger_Code__c custom setting
    // Example: new CDdCaseTriggerHandler().run('Case__c');
    // validateRun method will use this flag name to bypass trigger if the flag is checked for the Disable_Trigger_Code__c.getInstance() record.
    public virtual void run(String customSettingFlagName) {
        this.customSettingFlagName = customSettingFlagName;
        runHelper();
    }

    private void runHelper() {
        if (!validateRun()) {
            return;
        }

        // dispatch to the correct handler method
        switch on this.context {
            when BEFORE_INSERT {
                addToLoopCount();
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                addToLoopCount();
                this.beforeUpdate();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when BEFORE_DELETE {
                addToLoopCount();
                this.beforeDelete();
            }
            when AFTER_DELETE {
                addToLoopCount();
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    /**
     * @description Allows developers to prevent trigger loops, or allow
     * a limited number of them by setting the maximum number of times
     * this trigger is called.
     * @param max   A valid number (generally 1) of times you'd like
     * to allow the trigger to run.
     * @example
     * In the context of a TriggerHandler class,
     * this.setMaxLoopCount(5);
     */
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if (!CDdTriggerHandler.loopCountMap.containsKey(handlerName)) {
            CDdTriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            CDdTriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    /**
     * @description Allows developers to turn off the max loop count
     * @example
     * In the context of a TriggerHandler class,
     * this.clearMaxLoopCount();
     */
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    /***************************************
     * public static methods
     ***************************************/
    /**
     * @description       Allows developers to conditionally bypass (disable)
     * other triggers that *also* implement this triggerHandler
     * @param handlerName Class name (String) of the trigger handler to bypass
     * @example
     * TriggerHandler.bypass('AccountTriggerHandler');
     */
    public static void bypass(String handlerName) {
        CDdTriggerHandler.bypassedHandlers.add(handlerName);
    }

    /**
     * @description       Removes a given trigger handler class name from
     * the list of bypassed trigger handlers.
     * @param handlerName Handler class name to remove from the bypass list
     * @example
     * TriggerHandler.clearBypass('AccountTriggerHandler');
     */
    public static void clearBypass(String handlerName) {
        CDdTriggerHandler.bypassedHandlers.remove(handlerName);
    }

    /**
     * @description       Allows developers to check whether a given trigger
     * handler class is currently bypassed.
     * @param handlerName The name of the trigger handler class to check for
     * @return           `Boolean`
     * @example
     * TriggerHandler.isBypassed('AccountTriggerHandler');
     */
    public static Boolean isBypassed(String handlerName) {
        return CDdTriggerHandler.bypassedHandlers.contains(handlerName);
    }

    /**
     * @description removes all classes from the bypass list
     * @example
     * Triggerhandler.clearAllBypasses();
     */
    public static void clearAllBypasses() {
        CDdTriggerHandler.bypassedHandlers.clear();
    }

    /***************************************
     * private instancemethods
     ***************************************/

    /**
     * @description internal method to forcibly set the trigger context
     */
    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    /**
     * @description    Internal method for manually setting the trigger context
     * @param ctx      The current trigger Context
     * @param testMode Is the trigger running in a test context?
     */
    @testVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if (!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if (Trigger.isExecuting && !testMode) {
            switch on Trigger.operationType {
                when BEFORE_INSERT {
                    context = TriggerContext.BEFORE_INSERT;
                }
                when BEFORE_UPDATE {
                    context = TriggerContext.BEFORE_UPDATE;
                }
                when BEFORE_DELETE {
                    context = TriggerContext.BEFORE_DELETE;
                }
                when AFTER_INSERT {
                    context = TriggerContext.AFTER_INSERT;
                }
                when AFTER_UPDATE {
                    context = TriggerContext.AFTER_UPDATE;
                }
                when AFTER_DELETE {
                    context = TriggerContext.AFTER_DELETE;
                }
                when AFTER_UNDELETE {
                    context = TriggerContext.AFTER_UNDELETE;
                }
            }
        } else if (ctx != null && testMode) {
            switch on ctx {
                when 'before insert' {
                    context = TriggerContext.BEFORE_INSERT;
                }
                when 'before update' {
                    context = TriggerContext.BEFORE_UPDATE;
                }
                when 'before delete' {
                    context = TriggerContext.BEFORE_DELETE;
                }
                when 'after insert' {
                    context = TriggerContext.AFTER_INSERT;
                }
                when 'after update' {
                    context = TriggerContext.AFTER_UPDATE;
                }
                when 'after delete' {
                    context = TriggerContext.AFTER_DELETE;
                }
                when 'after undelete' {
                    context = TriggerContext.AFTER_UNDELETE;
                }
                when else {
                    throw new CDdTriggerHandlerException(
                        'Unexpected trigger context set'
                    );
                }
            }
        }
    }

    /**
     * @description increment the loop count
     * @exception   Throws loop count exception if the max loop count is reached
     */
    @TestVisible
    protected void addToLoopCount() {
        String handlerName = getHandlerName();
        if (CDdTriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = CDdTriggerHandler.loopCountMap.get(handlerName).increment();
            if (exceeded) {
                Integer max = CDdTriggerHandler.loopCountMap.get(handlerName).max;
                throw new CDdTriggerHandlerException(
                    'Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }

    /**
     * @description make sure this trigger should continue to run
     * @return     `Boolean`
     * @exception   CDdTriggerHandlerException thrown when executing outside of a trigger
     */
    @TestVisible
    protected Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            throw new CDdTriggerHandlerException('Trigger handler called outside of Trigger execution');
        }

        if (CDdTriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            return false;
        }

        Disable_Trigger_Code__c settings = Disable_Trigger_Code__c.getInstance();
        if (String.isNotBlank(this.customSettingFlagName) && settings != null) {
            Boolean disableTrigger = (Boolean)settings.get(this.customSettingFlagName);
            // Refer Salesforce Case 42759685. When new checkbox custom setting field is created, its not immediately available to the cache - so accessing the field throws an NPE.
            if (disableTrigger != null && disableTrigger) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description Returns the string version of the handler class being
     * invoked
     * @return     `String` Name of the Handler
     */
    private String handlerName;
    @TestVisible
    public String getHandlerName() {
        if (String.isBlank(handlerName)) {
            handlerName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
        }
        return handlerName;
    }

    /***************************************
     * context methods
     ***************************************/

    /**
     * These methods are all intended to be overridden by individual trigger handlers. They exist here only to establish the 'software contract' that they exist.
     */

    @TestVisible
    protected virtual void beforeInsert(){}
    @TestVisible
    protected virtual void beforeUpdate(){}
    @TestVisible
    protected virtual void beforeDelete(){}
    @TestVisible
    protected virtual void afterInsert(){}
    @TestVisible
    protected virtual void afterUpdate(){}
    @TestVisible
    protected virtual void afterDelete(){}
    @TestVisible
    protected virtual void afterUndelete(){}

    /***************************************
     * generic methods for field updated logic, can be overriden if needed
     ***************************************/

    // Dont use with ffLib - this will lead to an anti-pattern
    @TestVisible
    protected virtual Boolean isFieldUpdated(Sobject obj, String fieldName) {
        if (trigger.isUpdate) {
            Map<Id,SObject> triggerOldMap = (Map<Id,SObject>)trigger.OldMap;
            Id objId = (Id)obj.get('Id');
            Sobject oldObj = triggerOldMap.get(objId);
            return obj.get(fieldName) != oldObj.get(fieldName);
        }
        return false;
    }

    // Dont use with ffLib - this will lead to an anti-pattern
    @TestVisible
    protected virtual Boolean isNewOrFieldUpdated(Sobject obj, String fieldName) {
        return trigger.isInsert || trigger.isDelete || trigger.isUndelete ||
            isFieldUpdated(obj,fieldName);
    }

    // To use with ffLib, call the setTriggerContext method and set the test trigger context
    @TestVisible
    protected virtual Boolean isFieldUpdated(Sobject obj, Map<Id,SObject> triggerOldMap, String fieldName) {
        Boolean isUpdate = (context == TriggerContext.BEFORE_UPDATE || context == TriggerContext.AFTER_UPDATE);
        if (isUpdate) {
            Id objId = (Id)obj.get('Id');
            Sobject oldObj = triggerOldMap.get(objId);
            return obj.get(fieldName) != oldObj.get(fieldName);
        }
        return false;
    }

    @TestVisible
    // To use with ffLib, call the setTriggerContext method and set the test trigger context
    protected virtual Boolean isNewOrFieldUpdated(Sobject obj, Map<Id,SObject> triggerOldMap, String fieldName) {
        Boolean isInsert = (context == TriggerContext.BEFORE_INSERT || context == TriggerContext.AFTER_INSERT);
        Boolean isDelete = (context == TriggerContext.BEFORE_DELETE || context == TriggerContext.AFTER_DELETE);
        Boolean isUndelete = (context == TriggerContext.AFTER_UNDELETE);

        return isInsert || isDelete || isUndelete || isFieldUpdated(obj,triggerOldMap,fieldName);
    }

    /***************************************
     * inner classes
     ***************************************/

    /**
     * @description inner class for managing the loop count per handler
     */
    @testVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        /**
         * @description Loop counter method with default of 5.
         */
        public LoopCount() {
            this.setMax(5);
            this.count = 0;
        }

        /**
         * @description Sets loop count based on the param.
         * @param max   Maximum number of loops to allow.
         */
        public LoopCount(Integer max) {
            this.setMax(max);
            this.count = 0;
        }

        /**
         * @description Increment the internal counter returning the results of
         * this.exceeded().
         * @return     `Boolean` true if count will exceed max count or is less
         * than 0.
         */
        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        /**
         * @description Determines if this we're about to exceed the loop count.
         * @return     `Boolean` true if less than 0 or more than max.
         */
        public Boolean exceeded() {
            if (this.getMax() < 0) {
                return false;
            }
            if (this.getCount() > this.getMax()) {
                return true;
            }
            return false;
        }

        /**
         * @description Returns the max loop count.
         * @return     `Integer` max loop count.
         */
        public Integer getMax() {
            return this.max;
        }

        /**
         * @description Returns the current loop count.
         * @return     `Integer` current loop count.
         */
        public Integer getCount() {
            return this.count;
        }

        /**
         * @description Sets the max loop size
         * @param max   The integer to set max to.
         */
        public void setMax(Integer max) {
            this.max = max;
        }
    }

    /**
     * @description possible trigger contexts
     */
    @testVisible
    public enum TriggerContext {
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
    }

    // exception class
    public class CDdTriggerHandlerException extends Exception {}

    public static Boolean TEST_CLASS_USE_METADATA_FRAMEWORK = false;
    public static Integer TEST_CLASS_MAX_LOOP_COUNT = null;
}