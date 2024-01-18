// Source: https://navfreak.com/2024/01/18/changecompany-command-is-dangerous/

/// <summary>
/// This codeunit demonstrates the danger of the ChangeCompany command.
/// </summary>
codeunit 50103 "Test Change Company"
{

    trigger OnRun()
    begin
        If not confirm('Do you want to run the changecompany test?') then
            exit;
        TestChangeCompany();
        Message('Done');
    end;

    local procedure GetResult(var Result: text)
    var
        ChangeCompanyTest: Record "Change Company Test";
    begin
        GetResultFromCompany(Result, ChangeCompanyTest);
        ChangeCompanyTest.ChangeCompany('CronusCopy');
        GetResultFromCompany(result, ChangeCompanyTest);
    end;

    local procedure GetResultFromCompany(var Result: text; var ChangeCompanyTest: Record "Change Company Test")
    begin
        ChangeCompanyTest.get('10000');
        Result += 'Rec.CurrentCompany ' + ChangeCompanyTest.CurrentCompany + '\';
        Result += 'Modify Description: ' + ChangeCompanyTest."Modify Description" + '\';
        result += 'Trigger Description: ' + ChangeCompanyTest."Trigger Description" + '\';
        Result += 'Event Description: ' + ChangeCompanyTest."Event Description" + '\';
        Result += '\';
    end;

    local procedure InitRecord(var ChangeCompanyTest: Record "Change Company Test")
    begin
        ChangeCompanyTest.DeleteAll(false);
        ChangeCompanyTest.Code := '10000';
        ChangeCompanyTest.Insert(false);
    end;

    local procedure InitRecords()
    var
        ChangeCompanyTestCC: Record "Change Company Test";
    begin
        InitRecord(ChangeCompanyTestCC);
        ChangeCompanyTestCC.ChangeCompany('CronusCopy');
        InitRecord(ChangeCompanyTestCC);
    end;

    local procedure ModifyRecord(var ChangeCompanyTest: Record "Change Company Test")
    begin
        ChangeCompanyTest.get(10000);
        ChangeCompanyTest."Modify Description" := 'ChangeCompany Test';
        ChangeCompanyTest.Modify(true);
    end;

    local procedure TestChangeCompany()
    var
        ChangeCompanyTestCC: Record "Change Company Test";
        Result: text;
    //CustomerMsg: label 'Company %1, Customer %2\Field %3 = %4\Field %5 = %6';
    begin
        InitRecords();
        //ModifyRecord(ChangeCompanyTestCC);
        ChangeCompanyTestCC.ChangeCompany('CronusCopy');
        ModifyRecord(ChangeCompanyTestCC);
        GetResult(Result);
        Message(Result);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Company Test", OnAfterModifyEvent, '', false, false)]
    local procedure ChangeCompanyTestOnAfterModify(var Rec: Record "Change Company Test")
    var
        NewValue: Text;
    begin
        NewValue := 'Event Modify Test';
        if rec."Event Description" = newvalue then //prevent recursion
            exit;
        rec."Event Description" := 'Event Modify Test';
        rec.Modify(false);
    end;

}
