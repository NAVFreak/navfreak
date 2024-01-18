// Source: https://navfreak.com/2024/01/18/changecompany-command-is-dangerous/

/// <summary>
/// Table used to test the ChangeCompany command
/// </summary>
table 50100 "Change Company Test"
{
    Caption = 'Change Company Test';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Modify Description"; Text[100])
        {
            Caption = 'Modify Description';
        }
        field(3; "Trigger Description"; Text[100])
        {
            Caption = 'Trigger Description';
        }
        field(4; "Event Description"; Text[100])
        {
            Caption = 'Event Description';
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
    trigger OnModify()
    begin
        rec."Trigger Description" := 'OnInsert ' + rec.CurrentCompany;
        rec.Modify(false);
    end;


}
