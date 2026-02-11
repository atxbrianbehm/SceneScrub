"""
RunPod Serverless handler for Apple SHARP — single-image to 3DGS PLY.
Accepts a base64-encoded image, returns base64-encoded PLY file.

Uses the `sharp predict` CLI which is the documented/supported interface.
"""
import base64
import glob
import os
import subprocess
import tempfile
import time

import runpod


def handler(event):
    """
    Input:  {"input": {"image_b64": "<base64 JPEG/PNG>"}}
    Output: {"ply_b64": "<base64 PLY>", "num_splats": int, "elapsed_s": float}
    """
    try:
        inp = event.get("input", {})
        image_b64 = inp.get("image_b64")

        if not image_b64:
            return {"error": "Missing image_b64 in input"}

        image_bytes = base64.b64decode(image_b64)

        with tempfile.TemporaryDirectory() as work_dir:
            input_dir = os.path.join(work_dir, "input")
            output_dir = os.path.join(work_dir, "output")
            os.makedirs(input_dir)
            os.makedirs(output_dir)

            # Write input image
            img_path = os.path.join(input_dir, "image.jpg")
            with open(img_path, "wb") as f:
                f.write(image_bytes)

            # Run SHARP CLI
            t0 = time.time()
            result = subprocess.run(
                ["sharp", "predict", "-i", input_dir, "-o", output_dir],
                capture_output=True, text=True, timeout=120,
            )
            elapsed = time.time() - t0

            if result.returncode != 0:
                return {
                    "error": f"sharp predict failed (exit {result.returncode})",
                    "stderr": result.stderr[-2000:],
                }

            # Find the output PLY
            plys = glob.glob(os.path.join(output_dir, "**", "*.ply"), recursive=True)
            if not plys:
                return {"error": "No PLY output found", "stdout": result.stdout[-1000:]}

            ply_path = plys[0]
            with open(ply_path, "rb") as f:
                ply_bytes = f.read()

        # Count splats from header
        num_splats = 0
        header_text = ply_bytes[:2000].decode("ascii", errors="replace")
        for line in header_text.split("\n"):
            if line.startswith("element vertex"):
                num_splats = int(line.split()[-1])
                break

        return {
            "ply_b64": base64.b64encode(ply_bytes).decode("ascii"),
            "num_splats": num_splats,
            "elapsed_s": round(elapsed, 2),
            "ply_size_mb": round(len(ply_bytes) / 1024 / 1024, 1),
        }

    except Exception as e:
        import traceback
        return {"error": str(e), "traceback": traceback.format_exc()}


runpod.serverless.start({"handler": handler})
