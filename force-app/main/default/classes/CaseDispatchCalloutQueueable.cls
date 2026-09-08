public with sharing class CaseDispatchCalloutQueueable implements Database.Batchable<Case_Dispatch__c>, Database.AllowsCallouts {
    public static final Integer BATCH_SIZE = 50;
    private static final Integer VENDOR_USER_ID = 5;
    private Set<Id> dispatchIds;

    public CaseDispatchCalloutQueueable(List<Id> dispatchIds) {
        this.dispatchIds = dispatchIds == null ? new Set<Id>() : new Set<Id>(dispatchIds);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Title__c, Body__c 
            FROM Case_Dispatch__c 
            WHERE Id IN :dispatchIds 
            WITH USER_MODE
        ]);
    }

    public void execute(Database.BatchableContext context, List<Case_Dispatch__c> dispatchesToProcess) {
        List<Case_Dispatch__c> dispatchesToUpdate = new List<Case_Dispatch__c>();
        Http http = new Http();

        for (Case_Dispatch__c dispatch : dispatchesToProcess) {
            try {
                HttpRequest request = buildRequest(dispatch);
                HttpResponse response = http.send(request);
                applyResponse(dispatch, response);
            } catch (Exception e) {
                dispatch.Status__c = 'Failed';
                dispatch.Vendor_Response_Code__c = 'ERR';
            }

            dispatchesToUpdate.add(dispatch);
        }

        if (!dispatchesToUpdate.isEmpty()) {
            Database.update(dispatchesToUpdate, AccessLevel.USER_MODE);
        }
    }

    public void finish(Database.BatchableContext context) {
    }

    private static HttpRequest buildRequest(Case_Dispatch__c dispatch) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:DummyJSON_API/posts/add');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(new Map<String, Object>{
            'title' => dispatch.Title__c != null ? dispatch.Title__c : '',
            'body' => dispatch.Body__c != null ? dispatch.Body__c : '',
            'userId' => VENDOR_USER_ID
        }));
        return request;
    }

    private static void applyResponse(Case_Dispatch__c dispatch, HttpResponse response) {
        Integer statusCode = response.getStatusCode();
        dispatch.Vendor_Response_Code__c = String.valueOf(statusCode);

        if (statusCode == 200 || statusCode == 201) {
            dispatch.Status__c = 'Synced';
            DispatchResponse responseBody = (DispatchResponse) JSON.deserialize(
                response.getBody(), DispatchResponse.class
            );
            if (responseBody.id != null) {
                dispatch.External_Resource_Id__c = String.valueOf(responseBody.id);
            }
        } else {
            dispatch.Status__c = 'Failed';
        }
    }

    private class DispatchResponse {
        public Integer id;
        public String title;
        public String body;
        public Integer userId;
    }
}