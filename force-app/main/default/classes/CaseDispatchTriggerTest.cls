@isTest
private class CaseDispatchTriggerTest {

    @isTest
    static void testSuccessCallout() {
        Case testCase = new Case(Subject = 'Test Case', Status = 'New');
        insert testCase;

        String mockResponseBody = '{"id": 151, "title": "Dispatch Test", "body": "Details payload", "userId": 5}';
        Test.setMock(HttpCalloutMock.class, new CaseDispatchHttpCalloutMock(201, mockResponseBody));

        Case_Dispatch__c dispatch = new Case_Dispatch__c(
            Case__c = testCase.Id,
            Title__c = 'Dispatch Test',
            Body__c = 'Details payload'
        );

        Test.startTest();
        insert dispatch;
        Test.stopTest(); 

        Case_Dispatch__c updatedDispatch = [
            SELECT Status__c, Vendor_Response_Code__c, External_Resource_Id__c 
            FROM Case_Dispatch__c 
            WHERE Id = :dispatch.Id
        ];

        System.assertEquals('Synced', updatedDispatch.Status__c, 'El estado debe ser Synced');
        System.assertEquals('201', updatedDispatch.Vendor_Response_Code__c, 'El código debe ser 201');
        System.assertEquals('151', updatedDispatch.External_Resource_Id__c, 'El ID de recurso debe ser 151');
    }

    @isTest
    static void testFailureCallout() {
        Case testCase = new Case(Subject = 'Test Case Failure', Status = 'New');
        insert testCase;

        String mockResponseBody = '{"error": "Internal Server Error"}';
        Test.setMock(HttpCalloutMock.class, new CaseDispatchHttpCalloutMock(500, mockResponseBody));

        Case_Dispatch__c dispatch = new Case_Dispatch__c(
            Case__c = testCase.Id,
            Title__c = 'Dispatch Fail Test',
            Body__c = 'Error test'
        );

        Test.startTest();
        insert dispatch;
        Test.stopTest(); 

        Case_Dispatch__c updatedDispatch = [
            SELECT Status__c, Vendor_Response_Code__c, External_Resource_Id__c 
            FROM Case_Dispatch__c 
            WHERE Id = :dispatch.Id
        ];

        System.assertEquals('Failed', updatedDispatch.Status__c, 'El estado debe ser Failed');
        System.assertEquals('500', updatedDispatch.Vendor_Response_Code__c, 'El código debe ser 500');
        System.assertEquals(null, updatedDispatch.External_Resource_Id__c, 'El ID externo debe ser nulo');
    }
}