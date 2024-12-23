# Unifi Protect Animal Detection

This project combines the reliable camera monitoring of unifi-protect-backup with advanced wildlife detection capabilities, creating an automated system for capturing and filtering wildlife footage.

This project builds upon [ep1cman's unifi-protect-backup](https://github.com/ep1cman/unifi-protect-backup) to create an automated pipeline for detecting wildlife in Unifi Protect camera footage. It downloads motion detection clips from specific cameras and analyzes them for the presence of animals using PytorchWildlife's MegaDetectorV6.

## Features

- Syncs motion detection clips from specified Unifi Protect cameras
- Processes downloaded videos through animal detection
- Automatically removes videos where no animals are detected
- Based on a modified version of unifi-protect-backup with:
  - Camera inclusion filtering (instead of exclusion)
  - Post-processing support after downloads

## How It Works

The system consists of two Docker containers that communicate via a Unix domain socket:

1. **Sender Container**: Modified version of unifi-protect-backup that monitors and downloads motion clips
2. **Receiver Container**: Runs animal detection on downloaded clips using PytorchWildlife

For each video:
- One frame per second is extracted
- Each frame is analyzed using MegaDetectorV6
- Videos containing animals (confidence > 0.75) are kept
- Videos without animals are automatically removed

## Prerequisites

- Docker and Docker Compose
- Unifi Protect system with configured motion detection
- Sufficient storage for video processing

## Installation

1. Clone this repository
```bash
git clone https://github.com/WietseWind/Unifi-Wildlife-Detection
```

2. Create a `.env` file with your Unifi Protect credentials:
```env
UFP_USERNAME=xxx
UFP_PASSWORD=xxxx
UFP_ADDRESS=1.2.3.4
UFP_SSL_VERIFY=false
ONLY_CAMERAS=camera-id-1 camera-id-2  # Space-separated list of camera IDs
```

3. Start the system:
```bash
./run.sh
```

Add `-d` flag to run in detached mode:
```bash
./run.sh -d
```

## Configuration

### Camera IDs

To find your camera IDs:
1. Log into your Unifi Protect interface
2. Select a camera
3. Visit the timeline for the camera
4. Check the URL for the camera ID, e.g. `protect/timelapse/64db1adc039b5303e400acc2` = `64db1adc039b5303e400acc2`

### Processing Parameters

The animal detection settings can be modified in `docker/receiver/detect.py`:
- Confidence threshold (default: 0.75)
- Frame sampling rate
- Model parameters

## Credits

- Original unifi-protect-backup by [ep1cman](https://github.com/ep1cman/unifi-protect-backup)
- Animal detection using [PytorchWildlife](https://github.com/PytorchWildlife/PytorchWildlife)

## Docker Images Used

- Sender: Modified unifi-protect-backup image
- Receiver: Python 3.10 with PyTorch, OpenCV, and PytorchWildlife

## Notes

- First run will download the MegaDetectorV6 model (~1GB)
- Processing speed depends on hardware (GPU/CPU)
- Ensure sufficient storage for temporary video processing

## License

Dual license, for non-commercial use: MIT. For commercial use: contact me.

---

# Animal Detection Script

Simple script, detects animals (doesn't trigger on people).

If you want to run the python script manually (needs `requirements.txt`) use the info below. Note that this
script is not supposed to be executed separately, it is automatically xecuted by "receiver" container
in `./docker/receiver/detect.py`. If you want to build your own project, you can use the file separately.

```
python detect.py "somefile.mp4" -c 0.75 -q -p
echo $?
```

### Args
It takes the following args:

- First arg: path + filename
- `-c`: Minimum MEAN confidence level of ONLY THE FRAMES WITH DETECTED ANIMALS between 0 (accept all) and 1 (accept only 100% confidence)
- `-q`: Quiet, skip verbose logging of frames & detection details
- `-p`: Show progress bar (frames)

### Result

The result is simply represented by the script exit code. 

- Exit code 0 = animal found
- Exit code 1 = nothing found
