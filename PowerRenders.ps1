<#
.SYNOPSIS
PowerRenders: A PowerShell script to monitor and restart the Maya render process when crashes occur.

.DESCRIPTION
This script launches Maya's Render.exe to render a scene file. If the process crashes or the CPU usage remains below
a defined threshold for a specified duration, we assume it's a crash and the script will kill and restart the process.

.NOTES
    TL;DR: 
        - $cpuThreshold should be ~30% for an 8 core CPU, ~20% for a 16 core CPU, ~15% for a 32 core CPU.
        - $interval should be twice the time it takes for Maya to load the scene.
        - If the scrip restarts Maya before it has a chance to render, $interval is likely too small and $cpuUsage too high. 
        - If you encounter a crash and it never reboots (hopefully not), $cpuThreshold is likely too low. 

    General guidelines.
    - $cpuThreshold: 
        - When maya crashes, two cores can keep running in the background. 
        - $cpuThreshold should be higher than : 2 cores / total cores * 100 + 5% extra. 
        - For example, on a 32 core CPU, 2 cores will keep running in the background, so $cpuThreshold should be: 2 / 32 * 100 + 5% = 11.25% (rounded to 15%)
        - On an 8 core CPU, this should be: 2 / 8 * 100 + 5% = 30%. 
        - Powershell's CPU counter is not very accurate.
    - $interval: 
        - Maya needs some time to launch the renders during which CPU usage is low (typically single threaded). This will lower the average CPU usage.
        - $interval must be long enough to let Maya launch the render and let the average CPU usage raise during the actual renders. 
        - $interval should be: time_to_boot_render * 2. 
     You may need to adjust them depending on your scene and hardware.

.LIMITATIONS
    - Only tested for the Arnold renderer. 
    - Obvioulusly windows only since this is Powershell.
    - Does not detect holes in the rendered frames.



.PARAMETER ma_file
The path to the input Maya scene file.

.PARAMETER out_dir
The path to the output directory for rendered images.

.PARAMETER interval
The duration in seconds for monitoring average CPU usage.

.PARAMETER cpuThreshold
The CPU usage percentage threshold. If the CPU usage remains below this value for the specified interval, the script will restart the process.

.PARAMETER start
The default start frame for rendering.

.PARAMETER endFrame
The default end frame for rendering.

.PARAMETER renderer
The renderer to use. Defaults to Arnold.

#>

param (
[Parameter(Mandatory=$true)][string]$ma_file,
[Parameter(Mandatory=$true)][string]$out_dir,
[int]$interval = 15,
[int]$cpuThreshold = 15,
[int]$start = 1,
[int]$endFrame = 1600,
[string]$renderer = "arnold",
[string]$executable = "Render.exe"
)

$cpuCounter = "\Processor(_Total)\% Processor Time"
$sep = "=" * 80

# Start the Render CrashFix process
Write-Verbose "Go go PowerRenders" -Verbose
while ($true) {
    # Ensure the output directory exists, if not, create it
    if (-not (Test-Path $out_dir)) {
        Write-Verbose "Creating directory: $out_dir" -Verbose
        New-Item -ItemType Directory -Path $out_dir | Out-Null
    }
    
    # Find the highest number used in the names of the rendered frames
    $ma_file_name = [System.IO.Path]::GetFileNameWithoutExtension($ma_file)
    $lastFrame = Get-ChildItem -Path $out_dir -Filter "$ma_file_name*.exr" -Recurse | 
    Select-Object @{Name="FrameNum";Expression={[int]($PSItem.BaseName -replace "$ma_file_name`_", '')}} | 
    Sort-Object -Property FrameNum -Descending | 
    Select-Object -First 1
    
    # Set the next frame to render based on the last rendered frame
    if ($lastFrame -ne $null) {
        $nextFrame = $lastFrame.FrameNum + 1
        Write-Verbose "Detected existing frames. Starting render at frame $nextFrame" -Verbose
        $args = "-r $renderer -s $nextFrame -e $endFrame -rd $out_dir $ma_file"
    } else {
        Write-Verbose "Starting render at frame $start" -Verbose
        $args = "-r $renderer -s $start -e $endFrame -rd $out_dir $ma_file"
    }
    
    # Launch the Render.exe command with the specified arguments
    
    Write-Verbose $sep -Verbose
    Write-Verbose "Executable $executable" -Verbose
    Write-Verbose "Renderer $renderer" -Verbose
    Write-Verbose "Maya scene file $ma_file" -Verbose
    Write-Verbose "Start frame $start" -Verbose
    Write-Verbose "End frame $endFrame" -Verbose
    Write-Verbose "Output directory $out_dir" -Verbose
    Write-Verbose "CPU threshold $cpuThreshold" -Verbose
    Write-Verbose "Interval $interval" -Verbose
    Write-Verbose "" -Verbose
    Write-Verbose "Full command:"
    Write-Verbose "Start-Process -FilePath $executable -ArgumentList $args -PassThru" -Verbose
    Write-Verbose $sep -Verbose
    $process = Start-Process -FilePath $executable -ArgumentList $args -PassThru
    # Monitor the process and relaunch it if the CPU usage is below the threshold for the specified interval
    while (!$process.HasExited) {
        $cpuUsage = Get-Counter -Counter $cpuCounter -SampleInterval 1 -MaxSamples ($interval * 2) | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
        $averageCpuUsage = ($cpuUsage | Measure-Object -Average).Average
        Write-Verbose "Average CPU usage recorded over the last $interval seconds: $averageCpuUsage%" -Verbose
        if ($cpuUsage.Count -ge ($interval * 2)) { # Check if there are enough values to cover the last $interval seconds (2 samples per second)
            $recentCpuUsage = $cpuUsage[-($interval * 2)..-1] # Get the last $interval seconds of CPU usage samples
            if (!($recentCpuUsage -gt $cpuThreshold)) { # Check if CPU usage is never above the threshold
                Write-Verbose "The process has had CPU usage below $cpuThreshold% for the last $interval seconds. Killing and relaunching..." -Verbose
                $process.Kill()
                break
            }
        }
        Start-Sleep -Milliseconds 500
    }
    
    # Check if the process has exited with an error
    if ($process.ExitCode -ne 0) {
        Write-Verbose "The process has exited with an error code. Restarting..." -Verbose
    } else {
        Write-Verbose "The process has exited without an error code. Exiting..." -Verbose
        break # Break the loop if the process has exited without an error
    }
}