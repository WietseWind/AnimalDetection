import numpy as np
import torch
import os
import cv2
from PytorchWildlife.models import detection as pw_detection
import sys
import argparse
import time
import logging
from tqdm import tqdm
from statistics import mean

# Suppress Ultralytics logging  
logging.getLogger("ultralytics").setLevel(logging.WARNING)
os.environ['YOLO_VERBOSE'] = 'False'

# clear; python detect.py "somefile.mp4" -c 0.75 -q -p; echo $?

# Set device
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
detection_model = pw_detection.MegaDetectorV6(device=DEVICE, pretrained=True, version="MDV6-yolov9-c")

def process_video_for_detection(video_path, quiet=False, show_progress=False, min_confidence=0.0):
    if not os.path.exists(video_path):
        print(f"Error: Video file not found: {video_path}")
        return 1
        
    cap = cv2.VideoCapture(video_path)
    
    # Get video properties
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    total_seconds = int(total_frames / fps)
    
    if not quiet:
        print(f"Video properties:")
        print(f"FPS: {fps}")
        print(f"Total frames: {total_frames}")
        print(f"Total seconds: {total_seconds}")
        print(f"Minimum confidence threshold: {min_confidence}")
    
    frames_per_second = int(fps)
    detections_found = []
    
    # Create progress bar if requested
    pbar = tqdm(total=total_seconds + 1, disable=not show_progress)
    
    for current_second in range(total_seconds + 1):
        frame_pos = int(current_second * fps)
        
        if frame_pos >= total_frames:
            break
            
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_pos)
        
        ret, frame = cap.read()
        if not ret:
            if not quiet:
                print(f"Failed to read frame at second {current_second} (frame {frame_pos})")
            continue
            
        # Run detection on the frame
        results_det = detection_model.single_image_detection(frame, img_path=current_second)
        
        # Check for detections
        if len(results_det["detections"].xyxy) > 0:
            class_id = results_det["detections"].class_id[0]
            confidence = float(results_det["detections"].confidence[0])
            if confidence >= min_confidence:
                print(f"Detection at second {current_second} (frame {frame_pos}) - class: {class_id} - confidence: {confidence:.2f}")
                if class_id == 0:  # Only store animal detections
                    print(f"Detection seems to be animal, accept")
                    detections_found.append((current_second, frame_pos, confidence))
                if class_id > 0:
                    print(f"Detection seems *NOT* to be animal ({class_id}), reject")
        
        pbar.update(1)
    
    pbar.close()
    
    # Calculate and print mean confidence if detections were found
    if detections_found:
        confidences = [conf for _, _, conf in detections_found]
        mean_confidence = mean(confidences)
        print(f"\nMean confidence of detected frames: {mean_confidence:.2f}")
    
    # Print summary only if not in quiet mode
    if not quiet:
        print("\nProcessing complete!")
        print(f"Processed {current_second + 1} seconds of video out of {total_seconds} total seconds")
        if detections_found:
            print(f"Found animals at {len(detections_found)} timestamps:")
            for second, frame, conf in detections_found:
                print(f"- Second {second} (frame {frame}) - confidence: {conf:.2f}")
        else:
            print("No animals detected in video")
    
    cap.release()
    return 0 if detections_found else 1

def main():
    parser = argparse.ArgumentParser(description='Detect animals in video file')
    parser.add_argument('video_path', help='Path to the video file')
    parser.add_argument('-q', '--quiet', action='store_true',
                      help='Quiet mode - only show frames with detections')
    parser.add_argument('-p', '--progress', action='store_true',
                      help='Show progress bar')
    parser.add_argument('-c', '--confidence', type=float, default=0.0,
                      help='Minimum confidence threshold (0.0 to 1.0)')
    args = parser.parse_args()
    
    # Validate confidence threshold
    if not 0 <= args.confidence <= 1:
        print("Error: Confidence threshold must be between 0.0 and 1.0")
        sys.exit(1)
    
    exit_code = process_video_for_detection(
        args.video_path, 
        args.quiet, 
        args.progress,
        args.confidence
    )
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
