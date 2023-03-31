# PowerRenders

PowerRenders is a PowerShell script designed to monitor and restart Maya batch renders in case of crashes or unexpectedly low CPU usage.
Made overnight with the help of Chat GPT.

## Features

- Monitors the Maya rendering process and checks for crashes or low CPU usage
- Restarts the rendering process if necessary, from the last detected frame
- Supports custom input and output paths, idle time, CPU threshold, start frame, and end frame

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

## License
This project is licensed under the [MIT License](LICENSE).
