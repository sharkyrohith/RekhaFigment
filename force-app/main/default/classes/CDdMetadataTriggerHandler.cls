/**
 * @author: Raju Lakshman
 * @date: Feb 2021
 * @Source: https://github.com/trailheadapps/apex-recipes/blob/main/force-app/main/default/classes/Trigger%20Recipes/MetadataTriggerHandler.cls
 *
 * @description This class exists as a unified, trigger handler class. It uses Custom Metadata, and introspection of the Trigger.new variable to
 * determine what trigger handler classes should be called, and in what order.
 *
 * Metadata_Driven_Trigger__mdt has three fields:
 *  * Object__c - is a metadata entity look up to an sObject ie: Account
 *  * Execution_Order__c - is an integer and determines the order the trigger handlers are executed
 *  * Class__c - is a String holding the name of the Trigger Handler to execute
 *
 * Note: This Trigger framework works like this:
 *
 * An .trigger for a sObject invokes this class via: new MetadataTriggerHandler().run();
 *
 * This trigger handler class extends TriggerHandler - all the trigger handler classes _must_ extend trigger handler. Most classes will only overwrite the
 * context methods like afterUpdate(). This class, however, overrides the run method. This class is responsible for determining which other trigger
 * handler classes to instantiate and run.
 *
 */
public without sharing class CDdMetadataTriggerHandler extends CDdTriggerHandler {
    @testVisible
    private CDdMetadataTriggerService mts;

    @testVisible
    private List<Metadata_Driven_Trigger__mdt> tryggers;

    @testVisible
    private CDdTriggerHandler activeHandler;

    /**
     * @description Constructor used by live triggers.
     */
    public CDdMetadataTriggerHandler() {
        this.mts = new CDdMetadataTriggerService(
            CDdMetadataTriggerService.getSobjectType()
        );
    }

    public CDdMetadataTriggerHandler(CDdMetadataTriggerService mts) {
        this.mts = mts;
    }

    /**
     * @description Overrides the standard Run() method, which allows this metadata based trigger handler can be an incremental update / sit beside
     * other trigger handlers classes that are directly invoked by a trigger
     */
    public override void run() {
        runHelper();
    }

    // Add a checkbox field for the object in Disable_Trigger_Code__c custom setting. This can basically be the object name.
    // From the .trigger file, this constructor accepts the field api name in that Disable_Trigger_Code__c custom setting
    // Example: new CDdMetadataTriggerHandler().run('Case__c');
    // validateRun method will use this flag name to bypass trigger if the flag is checked for the Disable_Trigger_Code__c.getInstance() record.
    public override void run(String customSettingFlagName) {
        this.customSettingFlagName = customSettingFlagName;
        runHelper();
    }

    private void runHelper() {
        /**
         * This is standard validation checking for triggers / triggerhandlers
         */
        if (!validateRun()) {
            return;
        }

        addToLoopCount();

        /**
         * End standard validation
         */

        this.tryggers = this.mts.getMetadataTriggers();

        /**
         * @description This loop is responsible for instantiating the trigger
         * handler classes identified by the query above, and then calling the
         * proper context methods.
         */
        for (Metadata_Driven_Trigger__mdt trygger : tryggers) {
            if (CDdTriggerHandler.isBypassed(trygger.class__c)) {
                continue;
            }
            try {
                activeHandler = (CDdTriggerHandler)Type.forName(trygger.class__c).newInstance();
            } catch (Exception e) {
                continue;
            }

            switch on context {
                when BEFORE_INSERT {
                    activeHandler.beforeInsert();
                }
                when BEFORE_UPDATE {
                    activeHandler.beforeUpdate();
                }
                when AFTER_INSERT {
                    activeHandler.afterInsert();
                }
                when AFTER_UPDATE {
                    activeHandler.afterUpdate();
                }
                when BEFORE_DELETE {
                    activeHandler.beforeDelete();
                }
                when AFTER_DELETE {
                    activeHandler.afterDelete();
                }
                when AFTER_UNDELETE {
                    activeHandler.afterUndelete();
                }
            }
        }
    }
}