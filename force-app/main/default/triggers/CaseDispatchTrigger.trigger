trigger CaseDispatchTrigger on Case_Dispatch__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        CaseDispatchTriggerHandler.handleAfterInsert(Trigger.new);
    }
}