# Script found online @ markwragg/Watch-TimePassing.ps1
# https://gist.github.com/markwragg/73addf16504caaf72da1633cdac57e68

Do{
    Write-Progress -Activity "$((get-date).hour) hours" -PercentComplete (((get-date).hour /23) * 100) -Status "$(24 - (get-date).hour) hours remaining"
    Do{
        Write-Progress -Id 1 -Activity "$((get-date).minute) minutes" -PercentComplete (((get-date).minute / 59) * 100) -Status "$(60 - (get-date).minute) minutes remaining" 
        Do{
            Write-Progress -Id 2 -Activity "$((get-date).second) seconds" -PercentComplete (((get-date).second / 59) * 100) -Status "$(60 - (get-date).second) seconds remaining" 
            Do{
                $Second = (Get-Date).second
                Write-Progress -Id 3 -Activity "$((get-date).millisecond) milliseconds" -Status "The time is $(get-date -f "HH:mm:ss")" -PercentComplete (((get-date).millisecond / 1000) * 100) -SecondsRemaining (86400 - (((get-date).hour * 60 * 60) + ((get-date).Minute * 60) + ((get-date).Second)))
                # start-sleep -Milliseconds 100
            }
            Until ((get-date).second -ne $Second)
        }
        Until ((get-date).second -eq 0)
    }
    Until ((get-date).minute -eq 0)
}
Until ((get-date).hour -eq 0)
