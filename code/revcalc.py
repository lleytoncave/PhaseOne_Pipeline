import os
import shapefile
import pandas as pd
import numpy as np
import cv2
import Metashape

# -----------------------------
# User Inputs
# -----------------------------
SF_PATH = r"C:/Users/uqlcave/OneDrive - The University of Queensland/Documents/!DUMP/m4pro/plots1.shp"
image_u = 1228  # image width in pixels
image_v = 819   # image height in pixels

# -----------------------------
# Setup Metashape Chunk and Output Directory
# -----------------------------
doc = Metashape.app.document
chunk = doc.chunk

doc_dir, doc_file = os.path.split(doc.path)
project_name = os.path.splitext(doc_file)[0]
chunk_name = chunk.label
out_directory = os.path.join(doc_dir, f"{project_name}_{chunk_name}_RevCalc")
os.makedirs(out_directory, exist_ok=True)

# -----------------------------
# Read Shapefile and Export Marker Points
# -----------------------------
sf = shapefile.Reader(SF_PATH)
marker_records = []
plot_id_set = []

for sr in sf.shapeRecords():
    plot_id = sr.record['Plot_ID']
    plot_id_set.append(plot_id)
    points = sr.shape.points
    for i, (x, y) in enumerate(points, start=1):
        marker_records.append({'ID': f"{plot_id}-{i}", 'X': x, 'Y': y, 'Z': 0})

df_markers = pd.DataFrame(marker_records)
points_csv = os.path.join(out_directory, 'points.csv')
df_markers.to_csv(points_csv, index=False)

# Save unique plot IDs (as a simple list)
unique_plot_ids = sorted(list(set(plot_id_set)))
pd.DataFrame(unique_plot_ids).to_csv(os.path.join(out_directory, 'Unique_ID.txt'), index=False, header=False)

# -----------------------------
# Import markers into Metashape
# -----------------------------
chunk.importReference(path=points_csv, format=Metashape.ReferenceFormatCSV,
                      columns='nxyz', delimiter=',', skip_rows=1,
                      ignore_labels=False, create_markers=True)

# -----------------------------
# Transform markers to project CRS and interpolate Z from DEM
# -----------------------------
T = chunk.transform.matrix
dem = chunk.elevation

marker_xyz_list = []
for marker in chunk.markers:
    coord = marker.position
    proj_coord = chunk.crs.project(T.mulp(coord))
    x, y = proj_coord[0], proj_coord[1]
    try:
        z = dem.altitude((x, y))
    except Exception:
        z = 0.0
    marker_xyz_list.append((x, y, z, marker.label))

# -----------------------------
# Reverse Project Markers into Cameras
# -----------------------------
error_cameras = []
for x, y, z, marker_id in marker_xyz_list:
    out_rows = []
    point = Metashape.Vector((x, y, z))
    # world_point is in camera coordinate system for projection
    world_point = T.inv().mulp(chunk.orthomosaic.crs.unproject(point))
    
    for camera in chunk.cameras:
        try:
            proj = camera.project(world_point)
            u, v = proj.x, proj.y
        except Exception:
            # collect camera label to log later
            if camera not in error_cameras:
                error_cameras.append(camera)
            continue
        # check bounds
        try:
            w = camera.sensor.width
            h = camera.sensor.height
        except Exception:
            # fallback if camera has no sensor info
            continue
        if u < 0 or u > w or v < 0 or v > h:
            continue
        # keep camera.photo.path even if it's long or uses different separators
        cam_path = camera.photo.path if hasattr(camera, 'photo') and camera.photo is not None else ''
        out_rows.append((marker_id, camera.label, u, v, cam_path))
    
    if out_rows:
        df_out = pd.DataFrame(out_rows, columns=['Marker_ID', 'Camera_ID', 'u', 'v', 'Camera_Path'])
        safe_name = f"{marker_id}.csv"
        df_out.to_csv(os.path.join(out_directory, safe_name), index=False)

# Save error cameras (labels)
if error_cameras:
    unique_error_labels = sorted(list({cam.label for cam in error_cameras}))
    pd.DataFrame(unique_error_labels, columns=['ErrorCam']).to_csv(os.path.join(out_directory, 'Projection_Error.txt'), index=False)

# -----------------------------
# Merge Marker CSVs per Plot and Find Closest Camera (safe)
# -----------------------------
merged_dir = os.path.join(out_directory, 'MergedFiles')
coord_dir = os.path.join(out_directory, 'CoordinateFile')
os.makedirs(merged_dir, exist_ok=True)
os.makedirs(coord_dir, exist_ok=True)

centroid = np.array([image_u/2, image_v/2], dtype=float)
closest_camera_rows = []
skipped_plots = []

for plot_id in unique_plot_ids:
    marker_csvs = []
    complete = True

    # Collect 4 marker CSVs (fail-safe)
    for i in range(1, 5):
        path = os.path.join(out_directory, f"{plot_id}-{i}.csv")
        if not os.path.exists(path):
            print(f"⚠️ Missing marker file for plot {plot_id}: {path}")
            complete = False
            break
        try:
            df = pd.read_csv(path)
        except Exception as e:
            print(f"⚠️ Could not read {path}: {e}")
            complete = False
            break

        # rename and prepare columns for merging
        df.rename(columns={'u': f'u{i}', 'v': f'v{i}'}, inplace=True)
        df['POI'] = plot_id
        # drop columns that would conflict during merge
        df.drop(columns=['Marker_ID', 'Camera_Path'], inplace=True, errors='ignore')
        marker_csvs.append(df)

    if not complete:
        skipped_plots.append(plot_id)
        continue  # skip this plot

    # Merge on Camera_ID and POI so we only keep cameras that see all 4 markers
    merged = marker_csvs[0]
    for df in marker_csvs[1:]:
        merged = pd.merge(merged, df, on=['Camera_ID', 'POI'])

    if merged.empty:
        skipped_plots.append(plot_id)
        continue

    merged = merged[['POI', 'Camera_ID', 'u1', 'v1', 'u2', 'v2', 'u3', 'v3', 'u4', 'v4']]
    merged.to_csv(os.path.join(merged_dir, f"{plot_id}.csv"), index=False)

    # compute summed distance to image center for each candidate camera
    distances = []
    for idx, row in merged.iterrows():
        # sum of distances from each corner to image centroid
        d_sum = (
            np.hypot(row['u1'] - centroid[0], row['v1'] - centroid[1]) +
            np.hypot(row['u2'] - centroid[0], row['v2'] - centroid[1]) +
            np.hypot(row['u3'] - centroid[0], row['v3'] - centroid[1]) +
            np.hypot(row['u4'] - centroid[0], row['v4'] - centroid[1])
        )
        distances.append(d_sum)

    if distances:
        closest_idx = int(np.argmin(distances))
        chosen = merged.iloc[closest_idx].to_dict()
        # Add Camera_Path back in if available by reading one marker CSV that has Camera_Path
        # We'll search the original per-marker CSVs for the matching Camera_ID
        cam_path = None
        for i in range(1, 5):
            candidate_path = os.path.join(out_directory, f"{plot_id}-{i}.csv")
            try:
                df_candidate = pd.read_csv(candidate_path)
                match = df_candidate[df_candidate['Camera_ID'] == chosen['Camera_ID']]
                if not match.empty and 'Camera_Path' in match.columns:
                    cam_path = match['Camera_Path'].iloc[0]
                    break
            except Exception:
                continue
        chosen['Camera_Path'] = cam_path if cam_path is not None else ''
        closest_camera_rows.append(chosen)

# Save final coordinate file (only valid plots)
if closest_camera_rows:
    coord_file = os.path.join(coord_dir, 'CoordinateFile.csv')
    pd.DataFrame(closest_camera_rows).to_csv(coord_file, index=False)
    print(f"✅ CoordinateFile saved: {coord_file}")
else:
    print("⚠️ No complete plots available to generate CoordinateFile")

if skipped_plots:
    print("⚠️ Skipped plots (incomplete marker files):", skipped_plots)

# -----------------------------
# Marker Check & Plot Cropping (safe)
# -----------------------------
marker_check_dir = os.path.join(out_directory, 'MarkerCheck')
plot_clip_dir = os.path.join(out_directory, 'Plot_Clip')
os.makedirs(marker_check_dir, exist_ok=True)
os.makedirs(plot_clip_dir, exist_ok=True)

coord_path = os.path.join(coord_dir, 'CoordinateFile.csv')
if not os.path.exists(coord_path):
    print("⚠️ CoordinateFile not found; skipping cropping and marker-check generation.")
else:
    coord_df = pd.read_csv(coord_path)
    for idx, row in coord_df.iterrows():
        poi = row['POI']
        cam_id = row['Camera_ID']
        cam_path = row.get('Camera_Path', '')

        # If Camera_Path missing or doesn't exist, try to find it in marker CSVs
        if not cam_path or not os.path.exists(cam_path):
            found = False
            for i in range(1, 5):
                csv_path = os.path.join(out_directory, f"{poi}-{i}.csv")
                if not os.path.exists(csv_path):
                    continue
                try:
                    df_cand = pd.read_csv(csv_path)
                except Exception:
                    continue
                cand = df_cand[df_cand['Camera_ID'] == cam_id]
                if not cand.empty and 'Camera_Path' in cand.columns:
                    cam_path = cand['Camera_Path'].iloc[0]
                    found = True
                    break
            if not found:
                # Last-resort: try to build a path from camera label assuming a JPEG named by camera label exists
                guess = os.path.join(os.path.dirname(out_directory), f"{cam_id}.jpg")
                if os.path.exists(guess):
                    cam_path = guess

        if not cam_path or not os.path.exists(cam_path):
            print(f"⚠️ Image for camera {cam_id} not found. Skipping POI {poi}")
            continue

        img = cv2.imread(cam_path)
        if img is None:
            print(f"⚠️ Failed to read image {cam_path}. Skipping POI {poi}")
            continue

        # Ensure integer pixel coords
        try:
            pts = np.array([
                [int(row['u1']), int(row['v1'])],
                [int(row['u2']), int(row['v2'])],
                [int(row['u3']), int(row['v3'])],
                [int(row['u4']), int(row['v4'])]
            ], dtype=np.int32)
        except Exception as e:
            print(f"⚠️ Invalid corner coordinates for POI {poi}: {e}")
            continue

        # Draw marker-check image
        img_mark = img.copy()
        for (x, y) in pts:
            cv2.drawMarker(img_mark, (x, y), color=(0, 0, 255), markerType=cv2.MARKER_CROSS, thickness=10)
        marker_check_path = os.path.join(marker_check_dir, f"{poi}.jpg")
        cv2.imwrite(marker_check_path, img_mark, [cv2.IMWRITE_JPEG_QUALITY, 75])

        # Use minAreaRect + boxPoints for perspective transform
        rect = cv2.minAreaRect(pts)
        box = cv2.boxPoints(rect)
        box = box.astype(np.int32)
        width, height = int(rect[1][0]), int(rect[1][1])

        if width <= 0 or height <= 0:
            # fallback to axis-aligned bounding rect
            x, y, w, h = cv2.boundingRect(pts)
            if w <= 0 or h <= 0:
                print(f"⚠️ Invalid crop size for POI {poi}, skipping.")
                continue
            crop = img[y:y+h, x:x+w]
            crop_path = os.path.join(plot_clip_dir, f"{poi}.jpg")
            cv2.imwrite(crop_path, crop, [cv2.IMWRITE_JPEG_QUALITY, 100])
            print(f"✅ (fallback) Cropped POI {poi} -> {crop_path}")
            continue

        src_pts = box.astype('float32')
        dst_pts = np.array([[0, height-1], [0, 0], [width-1, 0], [width-1, height-1]], dtype='float32')

        try:
            M = cv2.getPerspectiveTransform(src_pts, dst_pts)
            plot_crop = cv2.warpPerspective(img, M, (width, height))
            crop_path = os.path.join(plot_clip_dir, f"{poi}.jpg")
            cv2.imwrite(crop_path, plot_crop, [cv2.IMWRITE_JPEG_QUALITY, 100])
            print(f"✅ Cropped POI {poi} -> {crop_path}")
        except Exception as e:
            print(f"⚠️ Perspective crop failed for POI {poi}: {e}")
            # fallback to bounding box crop
            x, y, w, h = cv2.boundingRect(pts)
            if w > 0 and h > 0:
                crop = img[y:y+h, x:x+w]
                crop_path = os.path.join(plot_clip_dir, f"{poi}_fallback.jpg")
                cv2.imwrite(crop_path, crop, [cv2.IMWRITE_JPEG_QUALITY, 100])
                print(f"✅ (fallback) Cropped POI {poi} -> {crop_path}")
            else:
                print(f"⚠️ No viable fallback for POI {poi}")

print("Finished processing.")
