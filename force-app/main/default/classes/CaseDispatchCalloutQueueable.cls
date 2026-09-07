public with sharing class CaseDispatchCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> dispatchIds;

    public CaseDispatchCalloutQueueable(List<Id> dispatchIds) {
        this.dispatchIds = dispatchIds;
    }

    public void execute(QueueableContext context) {
        if (dispatchIds == null || dispatchIds.isEmpty()) {
            return;
        }

        List<Case_Dispatch__c> dispatchesToProcess = [
            SELECT Id, Title__c, Body__c 
            FROM Case_Dispatch__c 
            WHERE Id IN :dispatchIds 
            WITH USER_MODE
        ];

        List<Case_Dispatch__c> dispatchesToUpdate = new List<Case_Dispatch__c>();

        for (Case_Dispatch__c dispatch : dispatchesToProcess) {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            request.setEndpoint('callout:DummyJSON_API/posts/add');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>{
                'title' => dispatch.Title__c != null ? dispatch.Title__c : '',
                'body' => dispatch.Body__c != null ? dispatch.Body__c : '',
                'userId' => 5
            };
            request.setBody(JSON.serialize(payload));

            try {
                HttpResponse response = http.send(request);
                Integer statusCode = response.getStatusCode();
                
                dispatch.Vendor_Response_Code__c = String.valueOf(statusCode);

                if (statusCode == 200 || statusCode == 201) {
                    dispatch.Status__c = 'Synced';
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (jsonResponse.containsKey('id')) {
                        dispatch.External_Resource_Id__c = String.valueOf(jsonResponse.get('id'));
                    }
                } else {
                    dispatch.Status__c = 'Failed';
                }
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
}