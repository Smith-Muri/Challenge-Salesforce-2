public with sharing class CaseDispatchTriggerHandler {
    public static void handleAfterInsert(List<Case_Dispatch__c> newDispatches) {
        List<Id> dispatchIds = new List<Id>();
        for (Case_Dispatch__c dispatch : newDispatches) {
            dispatchIds.add(dispatch.Id);
        }

        if (!dispatchIds.isEmpty()) {
            Database.executeBatch(new CaseDispatchCalloutQueueable(dispatchIds), CaseDispatchCalloutQueueable.BATCH_SIZE);
        }
    }
}