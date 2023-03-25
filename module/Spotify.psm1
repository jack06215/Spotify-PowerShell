# ---------
# DO NOT EDIT THIS FILE. This file is auto-generated by Build.ps1.
# ---------

<#
.SYNOPSIS
Authenticates in Spotify Web API.

.DESCRIPTION
Creates a new spotify token or refreshes the existing one and configures global variables.
For the initial authentication you will need to provide client id, client secret and autherization scopes. 
Put this command at the top of your script. Call this command if you get the "401 token expired" error. 

.PARAMETER StatePath
Path to a file to store client information and authentication token.

.PARAMETER Force
Forces a new authentication.

.PARAMETER ClientId
Predefined client Id (optional).

.PARAMETER Scope
Predefined list of scopes. Full access by default.

.EXAMPLE
Connect-SpotifyApi

.EXAMPLE
Connect-SpotifyApi -Force

.EXAMPLE
Connect-SpotifyApi -Force -ClientId "1995f32ef1a843249ddd581b8371d58f" -Scope "playlist-modify-private", "user-follow-read"

.FUNCTIONALITY
Base

.LINK
https://developer.spotify.com/dashboard/applications

.LINK
https://developer.spotify.com/documentation/general/guides/authorization/scopes
#>
function Connect-SpotifyApi {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Position = 0)]
        # [string] $StatePath = "$HOME/spotify-pwsh-state.xml",
        [string] $StatePath = "C:/Users/jack0/Documents/Mycodespace/spotify-powershell/spotify-pwsh-state.xml",
        [switch] $Force,
        [string] $ClientId = "",
        [string[]] $Scope = @(
            "ugc-image-upload",
            "user-modify-playback-state",
            "user-read-playback-state",
            "user-read-currently-playing",
            "user-follow-modify",
            "user-follow-read",
            "user-read-recently-played",
            "user-read-playback-position",
            "user-top-read",
            "playlist-read-collaborative",
            "playlist-modify-public",
            "playlist-read-private",
            "playlist-modify-private",
            "app-remote-control",
            "streaming",
            "user-read-email",
            "user-read-private",
            "user-library-modify",
            "user-library-read")
    )

    if (!(Test-Path -Path $StatePath) -or $Force) {

        $credentialArgs = @{}
        if ("" -ne $ClientId) { $credentialArgs.UserName = $ClientId }

        $state = [PSCustomObject]@{
            Credential = Get-Credential @credentialArgs -Message "Enter client id as username and client secret as password."
            Scope      = $Scope | Join-String -Separator " "
            Token      = $null
            Date       = Get-Date 
        }

        Start-Process "https://accounts.spotify.com/authorize?client_id=$($state.Credential.UserName)&response_type=code&scope=$($state.Scope)&redirect_uri=https://jwt.ms" | Out-Null
        Write-Host "Proceed in a browser and copy the autorization code ('code' GET paramater) to the clipboard."
        Pause
    
        $state.Token = Invoke-RestMethod `
            -Uri "https://accounts.spotify.com/api/token" `
            -Method Post `
            -Body "grant_type=authorization_code&code=$(Get-Clipboard)&redirect_uri=https://jwt.ms" `
            -Authentication Basic `
            -Credential $state.Credential `
            -ContentType "application/x-www-form-urlencoded"
    
        $global:SpotifyToken = ConvertTo-SecureString $state.Token.access_token -AsPlainText -Force
        $state | Export-Clixml -Path $StatePath -Force
        $file = Get-Item -Path $StatePath -Force
        $file.Attributes = "Hidden"
        $file.Attributes | Out-Null
        $file.Attributes = "Hidden"
    }
    else {
        
        $state = Import-Clixml -Path $StatePath
        $token = Invoke-RestMethod `
            -Uri "https://accounts.spotify.com/api/token" `
            -Method Post `
            -Body "grant_type=refresh_token&refresh_token=$($state.Token.refresh_token)" `
            -ContentType "application/x-www-form-urlencoded" `
            -Authentication Basic `
            -Credential $state.Credential

        $global:SpotifyToken = ConvertTo-SecureString $token.access_token -AsPlainText -Force
    }
}

<#
.SYNOPSIS
Get current user's profile.

.DESCRIPTION
Get detailed profile information about the current user (including the current user's username).

.EXAMPLE
Get-SpotifyUser

.FUNCTIONALITY
User

.LINK
https://developer.spotify.com/documentation/web-api/reference/#/operations/get-current-users-profile
#>
function Get-SpotifyUser {
    Invoke-RestMethod `
        -Uri "https://api.spotify.com/v1/me" `
        -Method Get `
        -Authentication Bearer `
        -Token $global:SpotifyToken `
        -ContentType "application/json" 
}

<#
.SYNOPSIS
Get user's top artists.

.DESCRIPTION
Get the current user's top artists based on calculated affinity.

.PARAMETER Term
Over what time frame the affinities are computed. Valid values: long_term (calculated from several years of data and including all new data as it becomes available), medium_term (approximately last 6 months), short_term (approximately last 4 weeks).

.EXAMPLE
Get-SpotifyUserTopArtists

.EXAMPLE
Get-SpotifyUserTopArtists long_term

.FUNCTIONALITY
User

.LINK
https://developer.spotify.com/documentation/web-api/reference/#/operations/get-users-top-artists-and-tracks
#>
function Get-SpotifyUserTopArtists {
    param (
        [Parameter(Position = 0)]
        [ValidateSet("short_term", "medium_term", "long_term")]
        [string] $Term = "medium_term"
    )

    $r = [pscustomobject]@{ next = "https://api.spotify.com/v1/me/top/artists?time_range=$Term&limit=50" }
    & { while ($r.next) {
            $r = Invoke-RestMethod `
                -Uri $r.next `
                -Method Get `
                -Authentication Bearer `
                -Token $global:SpotifyToken `
                -ContentType "application/json"; $r 
            break
        }
    } 
    | Select-Object -ExpandProperty items
    | ForEach-Object { $_.PSObject.TypeNames.Add("spfy.$($_.type)"); $_ }
}

<#
.SYNOPSIS
Get user's top tracks.

.DESCRIPTION
Get the current user's top tracks based on calculated affinity.

.PARAMETER Term
Over what time frame the affinities are computed. Valid values: long_term (calculated from several years of data and including all new data as it becomes available), medium_term (approximately last 6 months), short_term (approximately last 4 weeks).

.EXAMPLE
Get-SpotifyUserTopTracks

.EXAMPLE
Get-SpotifyUserTopTracks long_term

.FUNCTIONALITY
User

.LINK
https://developer.spotify.com/documentation/web-api/reference/#/operations/get-users-top-artists-and-tracks
#>
function Get-SpotifyUserTopTracks {
    param (
        [Parameter(Position = 0)]
        [ValidateSet("short_term", "medium_term", "long_term")]
        [string] $Term = "medium_term"
    )

    $r = [pscustomobject]@{ next = "https://api.spotify.com/v1/me/top/tracks?time_range=$Term&limit=50" }
    & { while ($r.next) {
            $r = Invoke-RestMethod `
                -Uri $r.next `
                -Method Get `
                -Authentication Bearer `
                -Token $global:SpotifyToken `
                -ContentType "application/json"; $r 
            break
        }
    } 
    | Select-Object -ExpandProperty items
    | ForEach-Object { 
        @() + $_ + $_.artists + $_.album + $_.album.artists 
        | ForEach-Object { $_.PSObject.TypeNames.Add("spfy.$($_.type)") }; $_
    }
}
