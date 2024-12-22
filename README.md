# Animal Detection script

Simple script, detects animals (doesn't trigger on people).

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
