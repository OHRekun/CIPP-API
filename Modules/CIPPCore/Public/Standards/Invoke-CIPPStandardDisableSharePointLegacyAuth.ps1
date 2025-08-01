function Invoke-CIPPStandardDisableSharePointLegacyAuth {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) DisableSharePointLegacyAuth
    .SYNOPSIS
        (Label) Disable legacy basic authentication for SharePoint
    .DESCRIPTION
        (Helptext) Disables the ability to authenticate with SharePoint using legacy authentication methods. Any applications that use legacy authentication will need to be updated to use modern authentication.
        (DocsDescription) Disables the ability for users and applications to access SharePoint via legacy basic authentication. This will likely not have any user impact, but will block systems/applications depending on basic auth or the SharePointOnlineCredentials class.
    .NOTES
        CAT
            SharePoint Standards
        TAG
            "CIS"
            "spo_legacy_auth"
        ADDEDCOMPONENT
        IMPACT
            Medium Impact
        ADDEDDATE
            2024-02-05
        POWERSHELLEQUIVALENT
            Set-SPOTenant -LegacyAuthProtocolsEnabled \$false
        RECOMMENDEDBY
            "CIS"
            "CIPP"
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

    param($Tenant, $Settings)
    $TestResult = Test-CIPPStandardLicense -StandardName 'DisableSharePointLegacyAuth' -TenantFilter $Tenant -RequiredCapabilities @('SHAREPOINTWAC', 'SHAREPOINTSTANDARD', 'SHAREPOINTENTERPRISE', 'ONEDRIVE_BASIC', 'ONEDRIVE_ENTERPRISE')
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'DisableSharePointLegacyAuth'

    if ($TestResult -eq $false) {
        Write-Host "We're exiting as the correct license is not present for this standard."
        return $true
    } #we're done.

    try {
        $CurrentInfo = New-GraphGetRequest -Uri 'https://graph.microsoft.com/beta/admin/sharepoint/settings?$select=isLegacyAuthProtocolsEnabled' -tenantid $Tenant -AsApp $true
    }
    catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the DisableSharePointLegacyAuth state for $Tenant. Error: $ErrorMessage" -Sev Error
        return
    }

    If ($Settings.remediate -eq $true) {

        if ($CurrentInfo.isLegacyAuthProtocolsEnabled) {
            try {
                $body = '{"isLegacyAuthProtocolsEnabled": "false"}'
                $null = New-GraphPostRequest -tenantid $tenant -Uri 'https://graph.microsoft.com/beta/admin/sharepoint/settings' -AsApp $true -Type patch -Body $body -ContentType 'application/json'
                Write-LogMessage -API 'Standards' -tenant $tenant -message 'Disabled SharePoint basic authentication' -sev Info
                $CurrentInfo.isLegacyAuthProtocolsEnabled = $false
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to disable SharePoint basic authentication. Error: $ErrorMessage" -sev Error
            }
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'SharePoint basic authentication is already disabled' -sev Info
        }
    }
    if ($Settings.alert -eq $true) {

        if ($CurrentInfo.isLegacyAuthProtocolsEnabled) {
            Write-StandardsAlert -message 'SharePoint basic authentication is enabled' -object $CurrentInfo -tenant $tenant -standardName 'DisableSharePointLegacyAuth' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'SharePoint basic authentication is enabled' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'SharePoint basic authentication is disabled' -sev Info
        }
    }
    if ($Settings.report -eq $true) {
        $state = $CurrentInfo.isLegacyAuthProtocolsEnabled ? ($CurrentInfo | Select-Object isLegacyAuthProtocolsEnabled) : $true
        Set-CIPPStandardsCompareField -FieldName 'standards.DisableSharePointLegacyAuth' -FieldValue $state -TenantFilter $Tenant
        Add-CIPPBPAField -FieldName 'SharePointLegacyAuthEnabled' -FieldValue $CurrentInfo.isLegacyAuthProtocolsEnabled -StoreAs bool -Tenant $tenant
    }
}
