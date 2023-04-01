# PowerRenders

PowerRenders is a PowerShell script designed to monitor and restart Maya batch renders in case of crashes or unexpectedly low CPU usage.
Made overnight with the help of Chat GPT.

## Features

- Monitors the Maya rendering process and checks for crashes or low CPU usage
- Restarts the rendering process if necessary, from the last detected frame
- Go go power renders!

## Installation

1. Clone the repository or download the script file:  
`git clone https://github.com/khaoj/PowerRenders`  
Or download the script directly from the GitHub repository.

2. Open the folder containing the script in PowerShell.

3. Make sure Render.exe is in your system's PATH, or you'll have to give it as an argument:  
Add to path example: `$env:Path += ";C:\Program Files\Autodesk\Maya2024\bin\Render.exe"`

## Usage

Run the script with the required parameters. Here's an example of how to run the script with custom parameters:

```powershell
# minimal version
.\PowerRenders.ps1 -ma_file "C:\path\to\file.ma" -out_dir "C:\path\to\render\folder" -end 100
# verbose
.\PowerRenders.ps1 -ma_file "C:\path\to\file.ma" -out_dir "C:\path\to\render\folder" -interval 15 -cpuThreshold 15 -start 1 -end 100 -renderer "arnold" -executable="C:\Program Files\Autodesk\Maya2024\bin\Render.exe"
```

## Tuning $cpuThreshold and $interval
### TL;DR: 
- Depends on your hardware and Maya scene.
- $cpuThreshold should be ~30% for an 8 core CPU, ~20% for a 16 core CPU, ~15% for a 32 core CPU.
- $interval should be 2x / 3x the time it takes for Maya to load the scene and start to actually render the scene.
- If the script restarts Maya before it has a chance to render, increase $interval. 
- High $interval values are safer, but it takes more time to detect a crash. 
- If you encounter a crash and it never reboots (hopefully not), $cpuThreshold is likely too low.

### $cpuThreshold: 
To detect a crash, we monitor the CPU usage (which isn't very accurate). We assume a crash occurred when CPU usage has been "very low" for a while. $cpuThreshold corresponds to that "very low" CPU usage value (in percent).  
After a Maya crash, two processes can keep running in the background and max out two cores, so we need to raise $cpuThreshold, otherwise we'll never below it and we'll never restart the renders.
So $cpuThreshold should be adapted depending on how many cores you have. 
Example: 
- For example, on a 32 core CPU, 2 cores will keep running in the background, so $cpuThreshold should be: 2 / 32 * 100 + 5% = 11.25% (rounded to 15%)
- On an 8 core CPU, this should be: 2 / 8 * 100 + 5% = 30%. 

### $interval: 
Maya needs some time to launch the renders during which CPU usage is low (typically single threaded). If we check for CPU usage every second, we might falsely detect a crash while Maya is just booting or preparing the scene. That's why we need to average CPU usage over a larger time interval, to smoothen these variations.
If Maya takes 10 seconds to boot and update the scene each time we render a new frame, setting $interval to 20 or 30 seconds should be safe. The only drawback on using larger $interval values is that it'll take more time to detect a crash. 

     
## LIMITATIONS
- Only tested for the Arnold renderer. 
- Obvioulusly Windows-only since this is Powershell.
- Does not detect holes in the rendered frames.

## License
This project is licensed under the [MIT License](LICENSE).
