/// <summary>
/// This codeunit is used to send telemetry for job queue entries.
/// It sends job queue entry status such as errored or finished to telemetry. 
/// Both messages have information on which server it was executed on and the failed 
/// job queue entry has the error message and stacktrace.
/// This app is described in the blog post https://navfreak.com/2023/12/21/how-to-show-business-central-server-information-in-telemetry/
/// </summary>
codeunit 70100 "Send JobQueue Telemetry"
{
    SingleInstance = true;

    var
        Initilized: Boolean;
        ServerInstanceName: text;
        ServerName: text;


    local procedure GetServerInstanceName(): text
    begin
        if not Initilized then
            initlize();
        exit(ServerInstanceName);
    end;

    local procedure GetServerName(): text
    begin
        if not Initilized then
            initlize();
        exit(ServerName);
    end;

    /// <summary>
    /// Is used to get data from database once and store it in variables.
    /// This is done to avoid calling database multiple times.
    /// Currently it gets the server name and server instance name from the active session table
    /// </summary>
    local procedure Initlize()
    var
        ActiveSession: Record "Active Session";
    begin
        Initilized := true;
        ActiveSession.SetRange("Server Instance ID", Database.ServiceInstanceId());
        ActiveSession.setrange("Session ID", SessionId());
        if ActiveSession.FindFirst() then begin
            ServerName := ActiveSession."Server Computer Name";
            ServerInstanceName := ActiveSession."Server Instance Name";
        end;

    end;


    #region TelemetrySubscribers
    // Copy from codeunit 1351 "Telemetry Subscribers"
    internal procedure SetJobQueueTelemetryDimensions(var JobQueueEntry: Record "Job Queue Entry"; var Dimensions: Dictionary of [Text, Text])
    begin
        JobQueueEntry.CalcFields("Object Caption to Run");
        Dimensions.Add('CompanyPrefixJobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('CompanyPrefixJobQueueObjectName', Format(JobQueueEntry."Object Caption to Run"));
        Dimensions.Add('CompanyPrefixJobQueueObjectDescription', Format(JobQueueEntry.Description));
        Dimensions.Add('CompanyPrefixJobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('CompanyPrefixJobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('CompanyPrefixJobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('CompanyPrefixJobQueueCompanyName', CompanyName);

        //Server specific telemety
        Dimensions.Add('CompanyPrefixServerInstanceId', format(Database.ServiceInstanceId()));
        Dimensions.Add('CompanyPrefixInstanceName', GetServerInstanceName());
        Dimensions.Add('CompanyPrefixServerName', GetServerName());
        Dimensions.add('CompanyPrefixPublicWebBaseUrl', GetUrl(ClientType::Web));
    end;

    /// <summary>
    /// Log failing job queue entries to telemetry with OnPrem information
    /// Original code can be found in codeunit 1351 "Telemetry Subscribers"
    /// </summary>
    /// <param name="JobQueueLogEntry"></param>
    /// <param name="JobQueueEntry"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Error Handler", OnBeforeLogError, '', false, false)]
    local procedure SendTraceOnJobQueueEntryErrored(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
        JobQueueEntryErrorAllTxtTok: Label 'CompanyPrefix Job queue entry errored: %1', Comment = '%1 = Job queue id', Locked = true;
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueStacktrace', JobQueueLogEntry.GetErrorCallStack());
        Dimensions.Add('CompanyPrefixErrorMessage', JobQueueEntry."Error Message");
        Session.LogMessage('CompanyPrefix0000HE7', // CompanyPrefix as prefix before original eventID
                                StrSubstNo(JobQueueEntryErrorAllTxtTok, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Warning,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    /// <summary>
    /// Log finished job queue entries to telemetry with OnPrem information
    /// Original code can be found in codeunit 1351 "Telemetry Subscribers"
    /// </summary>
    /// <param name="JobQueueLogEntry"></param>
    /// <param name="JobQueueEntry"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", OnAfterSuccessHandleRequest, '', false, false)]
    local procedure SendTraceOnJobQueueEntryRequestFinishedSuccessfully(var JobQueueEntry: Record "Job Queue Entry"; JobQueueExecutionTime: Integer; PreviousTaskId: Guid)
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
        JobQueueEntryFinishedAllTxtTok: Label 'CompanyPrefix Job queue entry finished: %1', Comment = '%1 = Job queue id', Locked = true;
    begin
        TranslationHelper.SetGlobalLanguageToDefault();
        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Session.LogMessage('CompanyPrefix0000E26', // CompanyPrefix as prefix before original eventID
                                StrSubstNo(JobQueueEntryFinishedAllTxtTok, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::SystemMetadata,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;
    #endregion


}



