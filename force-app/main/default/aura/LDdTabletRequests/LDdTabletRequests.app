<!--
* Created by Jeremy S. Johnson, Perficient Inc., on 6/13/2020.
*
* Implements: BZAP-6766 Tablet Request Case Grid
*
* Display related tablet cases in a grid that can be used by Classic and Lightning
 -->
<aura:application description="Tablet Requests" access="GLOBAL" extends="ltng:outApp" implements="force:hasRecordId,flexipage:availableForAllPageTypes" >
    <aura:dependency resource="c:LCDdTabletRequestsCmp"/>
    <aura:dependency resource="markup://force:*" type="EVENT"/>
</aura:application>