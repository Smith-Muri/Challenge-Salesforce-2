@isTest
private class CaseDispatchTriggerTest {

    @testSetup
    static void createCases() {
        insert new List<Case>{
            new Case(Subject = 'Test Case', Status = 'New'),
            new Case(Subject = 'Test Case Failure', Status = 'New')
        };
    }

    @isTest
    static void testSuccessCallout() {
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];

        String mockResponseBody = '{"id": 151, "title": "Dispatch Test", "body": "Details payload", "userId": 5}';
        Test.setMock(HttpCalloutMock.class, new CaseDispatchHttpCalloutMock(201, mockResponseBody));

        Test.startTest();
        Case_Dispatch__c dispatch = insertDispatch(testCase.Id, 'Dispatch Test', 'Details payload');
        Test.stopTest(); 

        Case_Dispatch__c updatedDispatch = [
            SELECT Status__c, Vendor_Response_Code__c, External_Resource_Id__c 
            FROM Case_Dispatch__c 
            WHERE Id = :dispatch.Id
        ];

        System.assertEquals('Synced', updatedDispatch.Status__c);
        System.assertEquals('201', updatedDispatch.Vendor_Response_Code__c);
        System.assertEquals('151', updatedDispatch.External_Resource_Id__c);
    }

    @isTest
    static void testFailureCallout() {
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case Failure' LIMIT 1];

        String mockResponseBody = '{"error": "Internal Server Error"}';
        Test.setMock(HttpCalloutMock.class, new CaseDispatchHttpCalloutMock(500, mockResponseBody));

        Test.startTest();
        Case_Dispatch__c dispatch = insertDispatch(testCase.Id, 'Dispatch Fail Test', 'Error test');
        Test.stopTest(); 

        Case_Dispatch__c updatedDispatch = [
            SELECT Status__c, Vendor_Response_Code__c, External_Resource_Id__c 
            FROM Case_Dispatch__c 
            WHERE Id = :dispatch.Id
        ];

        System.assertEquals('Failed', updatedDispatch.Status__c);
        System.assertEquals('500', updatedDispatch.Vendor_Response_Code__c);
        System.assertEquals(null, updatedDispatch.External_Resource_Id__c);
    }

    @isTest
    static void testMoreThanOneHundredDispatches() {
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new CaseDispatchHttpCalloutMock(201, '{"id": 151}'));
        List<Case_Dispatch__c> dispatches = new List<Case_Dispatch__c>();
        for (Integer index = 0; index < 101; index++) {
            dispatches.add(new Case_Dispatch__c(
                Case__c = testCase.Id,
                Title__c = 'Bulk dispatch ' + index,
                Body__c = 'Bulk body'
            ));
        }

        Test.startTest();
        insert dispatches;
        Test.stopTest();

        System.assertEquals(101, [
            SELECT COUNT() FROM Case_Dispatch__c WHERE Id IN :dispatches AND Status__c = 'Synced'
        ]);
    }

    private static Case_Dispatch__c insertDispatch(Id caseId, String title, String body) {
        Case_Dispatch__c dispatch = new Case_Dispatch__c(
            Case__c = caseId,
            Title__c = title,
            Body__c = body
        );
        insert dispatch;
        return dispatch;
    }
}